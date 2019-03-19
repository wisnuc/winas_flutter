import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../redux/redux.dart';
import '../common/utils.dart';
import '../common/stationApis.dart';

enum Status { idle, running, failed, finished }

/// Max file count in single directory
const MAX_FILE = 1000;

class PhotoEntry {
  String id;
  String name;
  String hash;
  int size;
  int date;
  String hdate;

  PhotoEntry(this.id, this.name, this.hash, this.size, this.date) {
    this.hdate = prettyDate(date, showMonth: true);
  }
}

class RemoteList {
  Entry entry;
  List<Entry> items;

  /// initial value is items' length
  int length;

  RemoteList(this.entry, this.items) {
    this.length = items.length;
  }

  /// increace RemoteList's length by one
  fakeAdd() {
    length += 1;
  }
}

void isolateHash(SendPort sendPort) {
  final port = ReceivePort();
  // send current sendPort to caller
  sendPort.send(port.sendPort);

  // listen message from caller
  port.listen((message) {
    final filePath = message[0] as String;
    final answerSend = message[1] as SendPort;
    File file = File(filePath);
    List<int> bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    answerSend.send(digest.toString());
    port.close();
  });
}

Future<String> hashViaIsolate(String filePath) async {
  final response = ReceivePort();
  await Isolate.spawn(isolateHash, response.sendPort);

  // sendPort from isolateHash
  final sendPort = await response.first as SendPort;
  final answer = ReceivePort();

  // send filePath and sendPort(to get answer) to isolateHash
  sendPort.send([filePath, answer.sendPort]);
  final res = await answer.first as String;
  return res;
}

/// upload single photo to target dir in Isolate
void isolateUpload(SendPort sendPort) {
  final port = ReceivePort();

  // send current sendPort to caller
  sendPort.send(port.sendPort);

  // listen message from caller
  port.listen((message) {
    final entryJson = message[0] as String;
    final filePath = message[1] as String;
    final sha256Value = message[2] as String;
    final apisJson = message[3] as String;
    final isCloud = message[4] as bool;
    final answerSend = message[5] as SendPort;

    final dir = Entry.fromMap(jsonDecode(entryJson));

    final photo = File(filePath);
    final apis = Apis.fromMap(jsonDecode(apisJson));

    // set network status
    apis.isCloud = isCloud;

    // Entry dir, File photo
    final fileName = photo.path.split('/').last;
    List<int> bytes = photo.readAsBytesSync();

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

    apis.upload(args, (error, value) {
      if (error != null) {
        answerSend.send(error.toString());
      } else {
        answerSend.send(null);
      }
    });

    port.close();
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

  Future<void> uploadViaIsolate(Entry dir, String filePath, String hash) async {
    final response = ReceivePort();

    currentWork = await Isolate.spawn(isolateUpload, response.sendPort);

    // sendPort from isolateHash
    final sendPort = await response.first as SendPort;
    final answer = ReceivePort();

    // send filePath and sendPort(to get answer) to isolateHash
    // Object in params need to convert to String
    // final entryJson = message[0] as String;
    // final filePath = message[1] as String;
    // final hash = message[2] as String;
    // final apisJson = message[3] as String;
    // final isCloud = message[4] as bool;
    // final answerSend = message[5] as SendPort;

    sendPort.send([
      dir.toString(),
      filePath,
      hash,
      apis.toString(),
      apis.isCloud,
      answer.sendPort
    ]);
    final error = await answer.first;
    if (error != null) throw error;
  }

  /// Get backup directory's content
  ///
  /// backup directory's structure is
  ///
  /// `backupDrive(device name)/照片/datetime`
  ///
  /// each directory has up to 1000 photos
  ///
  /// such as:
  ///
  /// Nexus 6P/照片/2019-01
  /// Nexus 6P/照片/2019-02
  /// Nexus 6P/照片/2019-02_02
  /// Nexus 6P/照片/2019-02_03
  /// Nexus 6P/照片/2019-03

  Future<List<RemoteList>> getRemoteDirs(Entry rootDir) async {
    final res = await apis.req(
      'listNavDir',
      {'driveUUID': rootDir.pdrv, 'dirUUID': rootDir.uuid},
    );

    final currentNode = Node(
      name: rootDir.name,
      driveUUID: rootDir.pdrv,
      dirUUID: rootDir.uuid,
      location: rootDir.location,
      tag: 'dir',
    );

    List<Entry> photoDirs = List.from(
      (res.data['entries'] as List)
          .map((entry) => Entry.mixNode(entry, currentNode))
          .where((entry) => entry.type == 'directory'),
    );

    final List<Future> reqs = List.from(
      photoDirs.map((dir) => apis.req(
            'listNavDir',
            {'driveUUID': dir.pdrv, 'dirUUID': dir.uuid},
          )),
    );

    final listNavs = await Future.wait(reqs);

    List<RemoteList> remoteDirs = [];
    for (int i = 0; i < listNavs.length; i++) {
      List<Entry> photoItmes = List.from(
        listNavs[i]
            .data['entries']
            .map((entry) => Entry.mixNode(entry, currentNode)),
      );
      remoteDirs.add(RemoteList(photoDirs[i], photoItmes));
    }
    remoteDirs.sort((a, b) => b.entry.name.compareTo(a.entry.name));
    return remoteDirs;
  }

  Future<Entry> getTargetDir(
      List<RemoteList> remoteDirs, PhotoEntry photoEntry, Entry rootDir) async {
    final index = remoteDirs.indexWhere(
      (rl) =>
          rl.entry.name.startsWith(photoEntry.hdate) && rl.length <= MAX_FILE,
    );

    Entry targetDir;
    // found target dir
    if (index > -1) {
      final remoteList = remoteDirs[index];

      // photo already backup
      if (remoteList.items.any((entry) => entry.hash == photoEntry.hash)) {
        return null;
      }

      targetDir = remoteList.entry;

      // increase length
      remoteList.fakeAdd();
      return targetDir;
    }

    // not found, create new dir
    String dirName = photoEntry.hdate;
    int flag = 1;

    // check name, add flag
    while (remoteDirs.any((rl) => rl.entry.name == dirName)) {
      flag += 1;
      dirName = '${photoEntry.hdate}_$flag';
    }

    // create dir
    final mkdirRes = await apis.req('mkdir', {
      'dirname': dirName,
      'dirUUID': rootDir.uuid,
      'driveUUID': rootDir.pdrv,
    });

    final currentNode = Node(
      name: rootDir.name,
      driveUUID: rootDir.pdrv,
      dirUUID: rootDir.uuid,
      location: rootDir.location,
      tag: 'dir',
    );

    targetDir = Entry.mixNode(mkdirRes.data[0]['data'], currentNode);

    final newRemoteList = RemoteList(targetDir, []);
    newRemoteList.fakeAdd();
    remoteDirs.add(newRemoteList);

    return targetDir;
  }

  /// get Hash from hashViaIsolate or shared_preferences
  /// use AssetEntity.id + mtime as the photo's identity
  Future<String> getHash(String id, String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String hash = prefs.getString(id);
    if (hash == null) {
      hash = await hashViaIsolate(filePath);
    }
    await prefs.setString(id, hash);
    return hash;
  }

  Future<void> uploadSingle(
      AssetEntity entity, List<RemoteList> remoteDirs, Entry rootDir) async {
    final time = DateTime.now().millisecondsSinceEpoch;

    File file = await entity.file;

    String filePath = file.path;
    String name = filePath.split('/').last;
    String id = entity.id;
    final stat = await file.stat();
    int mtime = stat.modified.millisecondsSinceEpoch;
    print(
        'before hash: $name, size: ${stat.size} ${DateTime.now().millisecondsSinceEpoch - time}');
    String hash = await getHash('$id+$mtime', filePath);
    print('after hash ${DateTime.now().millisecondsSinceEpoch - time}');
    final photoEntry = PhotoEntry(id, name, hash, stat.size, mtime);

    final targetDir = await getTargetDir(remoteDirs, photoEntry, rootDir);

    // already backuped, continue next
    if (targetDir == null) {
      finished += 1;
      print('backup ignore: ${file.path}');
      return;
    }
    print(
        'before upload: $name, size: ${stat.size} ${DateTime.now().millisecondsSinceEpoch - time}');
    // upload photo
    await uploadViaIsolate(targetDir, filePath, hash);

    print(
        'backup success: ${file.path} in ${DateTime.now().millisecondsSinceEpoch - time} ms');
    finished += 1;
  }

  Future<void> startAsync() async {
    status = Status.running;
    final data = await getMachineId();
    deviceName = data['deviceName'];
    machineId = data['machineId'];
    final Entry rootDir = await getDir();
    final Entry entry = await getDir();

    assert(entry is Entry);
    List<AssetEntity> assetList = await getAssetList();
    total = assetList.length;
    final remoteDirs = await getRemoteDirs(rootDir);

    for (AssetEntity entity in assetList) {
      if (status == Status.running) {
        try {
          await uploadSingle(entity, remoteDirs, rootDir);
        } catch (e) {
          print(e);
        }
      }
    }

    status = Status.finished;
  }

  void start() {
    startAsync().catchError(print);
    print('backup started');
  }

  void abort() {
    if (status != Status.finished) {
      try {
        currentWork?.kill();
      } catch (e) {
        print(e);
      }
      finished = 0;
      status = Status.failed;
    }
    print('backup aborted');
  }

  bool get isIdle => status == Status.idle;
  bool get isRunning => status == Status.running;
  bool get isFinished => status == Status.finished;
  bool get isFailed => status == Status.failed;

  String get progress => '$finished / $total';
}
