import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto/src/digest_sink.dart';
import 'package:device_info/device_info.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../redux/redux.dart';
import '../common/cache.dart';
import '../common/stationApis.dart';

enum Status { idle, running, failed, finished }

class BackupWorker {
  Apis apis;
  BackupWorker(this.apis);
  String machineId;
  String deviceName;
  CancelToken cancelToken;
  Status status = Status.idle;
  int total = 0;
  int finished = 0;

  /// get all local photos and videos
  Future<List<AssetEntity>> getAssetList() async {
    List<AssetPathEntity> pathList = await PhotoManager.getAssetPathList();
    List<AssetEntity> localAssetList = await pathList[0].assetList;
    localAssetList = List.from(localAssetList.reversed);
    return localAssetList;
  }

  /// read photo as bytes
  Future<List<int>> readFile(String path) async {
    final file = File(path);
    return file.readAsBytes();
  }

  /// hash file with throttle
  Future<String> hashWithThrottle(File file, List<int> bytes) async {
    final chunkSize = 1024;
    final ds = DigestSink();
    ByteConversionSink value = sha256.startChunkedConversion(ds);
    print('size ${bytes.length}');
    for (int i = 0; i < bytes.length; i += chunkSize) {
      await Future.delayed(Duration.zero);
      final end = i + chunkSize <= bytes.length ? i + chunkSize : bytes.length;
      value.add(bytes.sublist(i, end));
    }
    value.close();
    Digest digest = ds.value;
    return digest.toString();
  }

  /// calc sha256 of file, callback version
  hash(File file, Function callback) {
    final ds = DigestSink();
    ByteConversionSink value = sha256.startChunkedConversion(ds);

    Stream<List<int>> inputStream = file.openRead();

    inputStream.listen((List<int> bytes) {
      print('value.add ${bytes.length}');
      value.add(bytes);
    }, onDone: () {
      value.close();
      Digest digest = ds.value;
      callback(null, digest.toString());
    }, onError: (e) {
      callback(e, null);
    });
  }

  /// async version of hash file
  hashAsync(File file) async {
    Completer c = Completer();
    hash(file, (error, value) {
      if (error != null) {
        c.completeError(error);
      } else {
        c.complete(value);
      }
    });
    return c.future;
  }

  Future getMachineId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      machineId = iosInfo.identifierForVendor;
    } else {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
      machineId = androidInfo.androidId;
    }
    print('deviceName:$deviceName\n machineId:$machineId');
  }

  Future<Drive> getBackupDrive() async {
    final res = await apis.req('drives', null);
    // get current drives data
    List<Drive> drives = List.from(
      res.data.map((drive) => Drive.fromMap(drive)),
    );

    Drive backupDrive = drives.firstWhere(
      (d) => d?.client?.id == machineId,
      orElse: () => null,
    );

    return backupDrive;
  }

  Future<Entry> getPhotosDir(Drive backupDrive) async {
    final uuid = backupDrive.uuid;
    final listNav = await apis.req('listNavDir', {
      'driveUUID': uuid,
      'dirUUID': uuid,
    });
    final currentNode = Node(
      name: 'Backup',
      driveUUID: uuid,
      dirUUID: uuid,
      tag: 'backup',
      location: 'backup',
    );
    List<Entry> rawEntries = List.from(listNav.data['entries']
        .map((entry) => Entry.mixNode(entry, currentNode)));

    final photosDir =
        rawEntries.firstWhere((e) => e.name == '照片', orElse: () => null);
    return photosDir;
  }

  Future<Entry> getDir() async {
    Drive backupDrive = await getBackupDrive();

    if (backupDrive == null) {
      // create backupDrive
      final args = {
        'op': 'backup',
        'label': deviceName,
        'client': {
          'id': machineId,
          'status': 'Idle',
          'disabled': false,
          'lastBackupTime': 0,
          'type': Platform.isIOS ? 'Mobile-iOS' : 'Mobile-Android',
        }
      };

      await apis.req('createDrives', args);

      // retry get backupDrive
      backupDrive = await getBackupDrive();
    }

    assert(backupDrive is Drive);

    Entry photosDir = await getPhotosDir(backupDrive);

    if (photosDir == null) {
      // make backup root directory
      await apis.req('mkdir', {
        'dirname': '照片',
        'dirUUID': backupDrive.uuid,
        'driveUUID': backupDrive.uuid,
      });

      // retry getPhotosDir
      photosDir = await getPhotosDir(backupDrive);
    }

    return photosDir;
  }

  /// upload single photo to target dir
  Future upload(Entry dir, File photo) async {
    final fileName = photo.path.split('/').last;
    List<int> bytes = await photo.readAsBytes();
    final time = DateTime.now().millisecondsSinceEpoch;
    print('${photo.path} hash start');
    final sha256Value = await hashWithThrottle(photo, bytes);
    print(
        '${photo.path} hash finished ${DateTime.now().millisecondsSinceEpoch - time}');

    final FileStat stat = await photo.stat();

    final formDataOptions = {
      'op': 'newfile',
      'size': stat.size,
      'sha256': sha256Value,
      'bctime': stat.modified.millisecondsSinceEpoch,
      'bmtime': stat.modified.millisecondsSinceEpoch,
    };
    final args = {
      'driveUUID': dir.pdrv,
      'dirUUID': dir.uuid,
      'fileName': fileName,
      'file': UploadFileInfo.fromBytes(bytes, jsonEncode(formDataOptions)),
    };

    print(photo.path);

    print(args);
    cancelToken = CancelToken();
    await apis.upload(args, cancelToken: cancelToken);
  }

  Future<void> start() async {
    status = Status.running;
    await getMachineId();

    final Entry entry = await getDir();

    assert(entry is Entry);
    List<AssetEntity> assetList = await getAssetList();
    total = assetList.length;

    for (AssetEntity entity in assetList) {
      if (status == Status.running) {
        File file = await entity.file;
        await upload(entry, file);
        print('backup photo: ${file.path}');
        finished += 1;
      }
    }

    status = Status.finished;
  }

  void abort() {
    if (status != Status.finished) {
      cancelToken?.cancel();
      status = Status.failed;
    }
  }
}
