import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

import '../redux/redux.dart';
import '../common/format.dart';

class Task {
  final AsyncMemoizer lock = AsyncMemoizer();
  final String name;
  Task(this.name);
}

class TransferItem {
  String uuid;
  Entry entry;
  String speed = '';
  int finishedTime = -1;
  int startTime = -1;
  int finishedSize = 0;
  String filePath = '';
  int previousSize = 0;
  int previousTime = 0;

  CancelToken cancelToken;
  Function deleteFile;

  /// status of TransferItem: init, working, paused, finished, failed;
  String status = 'init';

  TransferItem({this.entry})
      : this.uuid = Uuid().v4(),
        this.previousTime = DateTime.now().millisecondsSinceEpoch;

  TransferItem.fromMap(Map m) {
    this.entry = Entry.fromMap(jsonDecode(m['entry']));
    this.uuid = m['uuid'];
    this.status = m['status'] == 'working' ? 'paused' : m['status'];
    this.finishedTime = m['finishedTime'];
    this.startTime = m['startTime'];
    this.finishedSize = m['finishedSize'] ?? 0;
    this.filePath = m['filePath'];
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'entry': entry,
      'uuid': uuid,
      'status': status,
      'finishedTime': finishedTime,
      'startTime': startTime,
      'finishedSize': finishedSize,
      'filePath': filePath,
    };

    return jsonEncode(m);
  }

  String toJson() => toString();

  void setFilePath(String path) {
    this.filePath = path;
  }

  void update(int size) {
    this.finishedSize = size;
    int now = DateTime.now().millisecondsSinceEpoch;
    int timeSpent = max(now - this.previousTime, 1);

    int speed = ((size - this.previousSize) / timeSpent * 1000).round();
    this.speed = '${prettySize(speed)}/s';
    this.previousSize = size;
    this.previousTime = now;
  }

  void start(CancelToken cancelToken, Function deleteFile) {
    this.deleteFile = deleteFile;
    this.cancelToken = cancelToken;
    this.startTime = DateTime.now().millisecondsSinceEpoch;
    this.status = 'working';
  }

  void reload(Function deleteFile) {
    this.deleteFile = deleteFile;
  }

  void pause() {
    this.cancelToken?.cancel("cancelled");
    this.speed = '';
    this.status = 'paused';
  }

  void clean() {
    this.pause();
    this.deleteFile();
  }

  void resume() {
    this.speed = '';
    this.status = 'working';
  }

  void finish() {
    this.finishedTime = DateTime.now().millisecondsSinceEpoch;
    this.status = 'finished';
  }

  void fail() {
    this.status = 'failed';
  }

  /// sort order
  int get order {
    switch (status) {
      case 'init':
        return 30;
      case 'working':
        return 100;
      case 'paused':
        return 50;
      case 'finished':
        return 10;
      case 'failed':
        return 20;
    }
    return 1000;
  }
}

class TransferManager {
  static TransferManager _instance;
  static TransferManager getInstance() {
    return _instance;
  }

  static List<TransferItem> transferList = [];
  static List<TransferItem> getList() {
    return transferList;
  }

  TransferManager._();

  /// local user uuid
  static String userUUID;

  /// init and load TransferItems
  static Future<void> init(String uuid) async {
    assert(uuid != null);

    TransferManager newInstance = TransferManager._();
    _instance = newInstance;

    // current user
    userUUID = uuid;

    // mkdir
    Directory root = await getApplicationDocumentsDirectory();
    _instance._rootDir = root.path;

    await Directory(_instance._transDir()).create(recursive: true);
    await Directory(_instance._downloadDir()).create(recursive: true);

    try {
      transferList = await _instance._load();

      // reload transferItem
      for (TransferItem item in transferList) {
        item.reload(() => _instance._cleanDir(item.filePath).catchError(print));
      }
    } catch (error) {
      print('load TransferItem error: $error');
      transferList = [];
    }
    return;
  }

  String _rootDir;

  String _transDir() {
    return _rootDir + '/trans/';
  }

  String _downloadDir() {
    return _rootDir + '/download/' + userUUID + '/';
  }

  Future<List<TransferItem>> _load() async {
    String path = _downloadDir() + 'list.json';
    File file = File(path);
    String json = await file.readAsString();
    List<TransferItem> list = List.from(
        jsonDecode(json).map((item) => TransferItem.fromMap(jsonDecode(item))));
    return list;
  }

  static Lock _lock = Lock();

  Future<void> _save() async {
    await _lock.synchronized(() async {
      String json = jsonEncode(transferList);
      String path = _downloadDir() + 'list.json';
      String transPath = _transDir() + '/' + Uuid().v4();
      File file = File(transPath);
      await file.writeAsString(json);
      await file.rename(path);
    });
  }

  Future<void> _cleanDir(String path) async {
    File file = File(path);
    await file.delete(recursive: true);
    await _save();
  }

  Future<void> _downloadFile(TransferItem item, AppState state) async {
    Entry entry = item.entry;

    // use unique transferItem uuid
    String entryDir = _downloadDir() + item.uuid + '/';
    String entryPath = entryDir + entry.name;
    String transPath = _transDir() + '/' + Uuid().v4();
    item.setFilePath(entryPath);
    CancelToken cancelToken = CancelToken();
    item.start(cancelToken, () => _cleanDir(entryDir).catchError(print));

    final ep = 'drives/${entry.pdrv}/dirs/${entry.pdir}/entries/${entry.uuid}';
    final qs = {'name': entry.name, 'hash': entry.hash};
    try {
      await _save();
      // mkdir
      await Directory(entryDir).create(recursive: true);
      // download
      await state.apis.download(ep, qs, transPath, cancelToken: cancelToken,
          onProgress: (int a, int b) {
        item.update(a);
      });
      // rename
      await File(transPath).rename(entryPath);
      item.finish();
      await _save();
    } catch (error) {
      print(error);
      // DioErrorType.CANCEL is not error
      if (error?.type != DioErrorType.CANCEL) {
        item.fail();
      }
    }
  }

  /// creat a new download task
  newDownload(Entry entry, AppState state) {
    TransferItem item = TransferItem(entry: entry);
    transferList.add(item);
    _downloadFile(item, state).catchError((onError) => item.fail());
  }
}
