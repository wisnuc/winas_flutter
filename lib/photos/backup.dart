import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:photo_manager/photo_manager.dart';

import '../redux/redux.dart';
import '../common/stationApis.dart';

enum Status { idle, running, failed, finished }

/// Hash file in Isolate

/// upload single photo to target dir in Isolate
void isolateUpload(SendPort sendPort) {
  final port = ReceivePort();

  // send current sendPort to caller
  sendPort.send(port.sendPort);

  // listen message from caller
  port.listen((message) {
    final entryJson = message[0] as String;
    final filePath = message[1] as String;
    final apisJson = message[2] as String;
    final isCloud = message[3] as bool;
    final answerSend = message[4] as SendPort;

    final dir = Entry.fromMap(jsonDecode(entryJson));

    final photo = File(filePath);
    final apis = Apis.fromMap(jsonDecode(apisJson));

    // set network status
    apis.isCloud = isCloud;

    // Entry dir, File photo
    final fileName = photo.path.split('/').last;
    List<int> bytes = photo.readAsBytesSync();

    final digest = sha256.convert(bytes);
    final sha256Value = digest.toString();

    final FileStat stat = photo.statSync();

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

    CancelToken cancelToken = CancelToken();

    apis.upload(args, cancelToken, (error, value) {
      if (error != null) {
        answerSend.send(error.toString());
      } else {
        answerSend.send(null);
      }
    });
  });
}

class BackupWorker {
  Apis apis;
  BackupWorker(this.apis);
  String machineId;
  String deviceName;
  CancelToken cancelToken;
  Isolate currentWork;
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

  Future<void> uploadViaIsolate(Entry dir, File photo) async {
    final response = ReceivePort();

    currentWork = await Isolate.spawn(isolateUpload, response.sendPort);

    // sendPort from isolateHash
    final sendPort = await response.first as SendPort;
    final answer = ReceivePort();

    // send filePath and sendPort(to get answer) to isolateHash
    // Object in params need to convert to String
    // final entryJson = message[0] as String;
    // final filePath = message[1] as String;
    // final apisJson = message[2] as String;
    // final isCloud = message[3] as bool;
    // final answerSend = message[4] as SendPort;

    sendPort.send([
      dir.toString(),
      photo.path,
      apis.toString(),
      apis.isCloud,
      answer.sendPort
    ]);
    final error = await answer.first;
    if (error != null) throw error;
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

        await uploadViaIsolate(entry, file);
        print('backup photo: ${file.path}');
        finished += 1;
      }
    }

    status = Status.finished;
  }

  void abort() {
    if (status != Status.finished) {
      try {
        currentWork?.kill();
      } catch (e) {
        print(e);
      }
      status = Status.failed;
    }
  }
}
