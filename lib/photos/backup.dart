import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../redux/redux.dart';
import '../common/cache.dart';
import '../common/stationApis.dart';

enum Status { pending, running, finished }

Future<Uint8List> getThumbAsync(
    Entry entry, AppState state, CancelToken cancelToken) async {
  final cm = await CacheManager.getInstance();
  final Uint8List thumbData = await cm.getThumbData(entry, state, cancelToken);

  return thumbData;
}

void getThumbCallback(
    Entry entry, AppState state, CancelToken cancelToken, Function callback) {
  getThumbAsync(entry, state, cancelToken)
      .then((value) => callback(null, value))
      .catchError((error) => callback(error, null));
}

class Task {
  Status status = Status.pending;

  final Function onFinished;
  Task(this.onFinished);

  run() {
    status = Status.running;
  }

  abort() {
    status = Status.finished;
    this.onFinished('Abort', null);
  }

  error(error) {
    status = Status.finished;
    this.onFinished(error, null);
  }

  finish(value) {
    if (this.isFinished) return;
    status = Status.finished;
    this.onFinished(null, value);
  }

  bool get isPending => status == Status.pending;
  bool get isRunning => status == Status.running;
  bool get isFinished => status == Status.finished;
}

class ThumbTask extends Task {
  final AppState state;
  final Entry entry;
  final CancelToken cancelToken = CancelToken();

  ThumbTask(
    this.entry,
    this.state,
    Function onFinished,
  ) : super(onFinished);

  Future getSrc() async {}

  @override
  run() {
    super.run();
    getThumbCallback(entry, state, cancelToken, (err, value) {
      if (err != null) {
        this.error(err);
      } else {
        this.finish(value);
      }
    });
  }

  @override
  abort() {
    if (this.isFinished) return;
    cancelToken?.cancel();
    super.abort();
  }
}

class TaskManager {
  final List<ThumbTask> thumbTaskQueue = [];
  final int thumbTaskLimit = 8;

  // keep singleton
  static TaskManager _instance;

  static TaskManager getInstance() {
    if (_instance == null) {
      _instance = TaskManager._();
    }
    return _instance;
  }

  TaskManager._();

  ThumbTask createThumbTask(Entry entry, AppState state, Function callback) {
    final Function onFinished = (error, value) {
      callback(error, value);
      // schedule in next event-loop iteration
      Future.delayed(Duration.zero).then((v) => schedule());
    };

    final task = ThumbTask(entry, state, onFinished);
    thumbTaskQueue.add(task);
    schedule();
    return task;
  }

  schedule() {
    // remove finished
    thumbTaskQueue.removeWhere((t) => t.isFinished);

    // calc number of task left to run
    int freeNum =
        thumbTaskLimit - thumbTaskQueue.where((t) => t.isRunning).length;

    if (freeNum > 0) {
      thumbTaskQueue.where((t) => t.isPending).take(freeNum).forEach((t) {
        t.run();
      });
    }
  }
}

class Backup {
  Apis apis;
  Backup(this.apis);
  String machineId = '';

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

  /// calc sha256 of file
  Future<String> hash(List<int> data) async {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  Future getMachineId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String model;
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      model = iosInfo.name;
    } else {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    }

    return '';
  }

  Future<Drive> getBackupDrive() async {
    final res = await apis.req('drives', null);
    // get current drives data
    List<Drive> drives = List.from(
      res.data.map((drive) => Drive.fromMap(drive)),
    );

    Drive backupDrive = drives.firstWhere((d) => d.client.id == machineId);
    if (backupDrive == null) {
      // create backupDrive
      final args = {
        'op': 'backup',
        'label': machineId,
        'client': {
          'id': machineId,
          'status': 'Idle',
          'disabled': false,
          'lastBackupTime': 0,
          'type': Platform.isIOS ? 'Mobile-iOS' : 'Mobile-Android',
        }
      };

      await apis.req('createDrives', args);
    }

    return backupDrive;
  }

  /// upload file
  upload() async {
    final args = {
      'driveUUID': 'driveUUID',
      'dirUUID': 'driveUUID',
      'fileName': 'driveUUID',
      'formDataOptions': {},
    };
    await apis.upload(args);
  }
}
