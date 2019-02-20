import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:path_provider/path_provider.dart';

import '../redux/redux.dart';

class Task {
  final AsyncMemoizer lock = AsyncMemoizer();
  final String name;
  Task(this.name);
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
      transferList = await _instance._load(uuid);
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
    return _rootDir + '/download/';
  }

  _load(uuid) async {
    List<TransferItem> list = [];
    return list;
  }

  _deleteDir(String path) {
    File file = File(path);
    file
        .delete(recursive: true)
        .catchError((onError) => print('delete file failed: $onError'));
  }

  Future<void> _downloadFile(TransferItem item, AppState state) async {
    Entry entry = item.entry;

    // use unique transferItem uuid
    String entryDir = _downloadDir() + item.uuid + '/';
    String entryPath = entryDir + entry.name;
    String transPath = _transDir() + '/' + Uuid().v4();
    item.setFilePath(entryPath);
    CancelToken cancelToken = CancelToken();
    item.start(cancelToken, () => _deleteDir(entryDir));

    final ep = 'drives/${entry.pdrv}/dirs/${entry.pdir}/entries/${entry.uuid}';
    final qs = {'name': entry.name, 'hash': entry.hash};
    try {
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
    } catch (error) {
      print(error);
      // DioErrorType.CANCEL is not error
      if (error?.type != DioErrorType.CANCEL) {
        item.fail();
      }
    }
  }

  /// creat a new download task, TODO: persist
  newDownload(Entry entry, AppState state) {
    TransferItem item = TransferItem(entry: entry);
    transferList.add(item);
    _downloadFile(item, state).catchError((onError) => item.fail());
  }
}
