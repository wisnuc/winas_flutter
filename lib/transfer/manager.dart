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
import '../common/utils.dart';
import '../common/isolate.dart';

enum TransType {
  shared,
  upload,
  download,
}

class Task {
  final AsyncMemoizer lock = AsyncMemoizer();
  final String name;
  Task(this.name);
}

class TransferItem {
  String uuid;
  Entry entry;
  TransType transType;
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

  TransferItem({this.entry, this.transType, this.filePath})
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

  bool get isShare => transType == TransType.shared;
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
      if (error is DioError && (error?.type != DioErrorType.CANCEL)) {
        item.fail();
      }
    }
  }

  /// creat a new download task
  newDownload(Entry entry, AppState state) {
    TransferItem item = TransferItem(
      entry: entry,
      transType: TransType.download,
    );
    transferList.add(item);
    _downloadFile(item, state).catchError((onError) => item.fail());
  }

  Future<Entry> getTargetDir(
      AppState state, Drive drive, String dirname) async {
    final uuid = drive.uuid;
    final listNav = await state.apis.req('listNavDir', {
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
        rawEntries.firstWhere((e) => e.name == dirname, orElse: () => null);
    return photosDir;
  }

  /// upload file in Isolate
  Future<void> uploadAsync(AppState state, Entry targetDir, String filePath,
      String hash, CancelToken cancelToken) async {
    final fileName = filePath.split('/').last;
    File file = File(filePath);
    final FileStat stat = await file.stat();

    final formDataOptions = {
      'op': 'newfile',
      'size': stat.size,
      'sha256': hash,
      'bctime': stat.modified.millisecondsSinceEpoch,
      'bmtime': stat.modified.millisecondsSinceEpoch,
      'policy': ['rename', 'rename'],
    };

    final args = {
      'driveUUID': targetDir.pdrv,
      'dirUUID': targetDir.uuid,
      'fileName': fileName,
      'file': UploadFileInfo(file, jsonEncode(formDataOptions)),
    };

    await state.apis.uploadAsync(args, cancelToken: cancelToken);
  }

  Future<void> uploadSharedFile(TransferItem item, AppState state) async {
    final filePath = item.filePath;
    CancelToken cancelToken = CancelToken();
    item.start(cancelToken, () => {});
    try {
      await _save();

      // get target dir
      final targetDirName = '来自手机的文件';

      final Drive drive =
          state.drives.firstWhere((d) => d.tag == 'home', orElse: () => null);
      Entry targetDir = await getTargetDir(state, drive, targetDirName);

      if (targetDir == null) {
        // make backup root directory
        await state.apis.req('mkdir', {
          'dirname': targetDirName,
          'dirUUID': drive.uuid,
          'driveUUID': drive.uuid,
        });

        // retry getPhotosDir
        targetDir = await getTargetDir(state, drive, targetDirName);
      }

      // hash
      final hash = await hashViaIsolate(filePath);

      // upload via isolate
      // await uploadViaIsolate(state.apis, targetDir, filePath, hash);

      // upload async
      await uploadAsync(state, targetDir, filePath, hash, cancelToken);

      item.finish();

      await _save();
    } catch (error) {
      print(error);
      // DioErrorType.CANCEL is not error
      if (error is! DioError || (error?.type != DioErrorType.CANCEL)) {
        item.fail();
      }
    }
  }

  /// creat a new upload task. handle shared file from other app
  newUploadSharedFile(String filePath, AppState state) {
    File(filePath)
      ..stat().then(
        (stat) {
          print('newUploadSharedFile $stat');
          if (stat.type != FileSystemEntityType.notFound) {
            String name = filePath.split('/').last;
            TransferItem item = TransferItem(
              entry: Entry(name: name, size: stat.size),
              transType: TransType.shared,
              filePath: filePath,
            );
            transferList.add(item);
            uploadSharedFile(item, state).catchError((error) {
              print(error);
              // DioErrorType.CANCEL is not error
              if (error is! DioError || (error?.type != DioErrorType.CANCEL)) {
                item.fail();
              }
            });
          }
        },
      ).catchError(print);
  }
}
