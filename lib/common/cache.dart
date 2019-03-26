import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:async/async.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

import '../redux/redux.dart';

class Task {
  final AsyncMemoizer lock = AsyncMemoizer();
  final String name;
  Task(this.name);
}

class CacheManager {
  static CacheManager _instance;

  static Future<CacheManager> getInstance() async {
    if (_instance == null) {
      await _lock.synchronized(() async {
        if (_instance == null) {
          // keep local instance till it is fully initialized
          var newInstance = CacheManager._();
          await newInstance._init();
          _instance = newInstance;
        }
      });
    }
    return _instance;
  }

  CacheManager._();

  static Lock _lock = Lock();

  String _rootDir;

  String _tmpDir() {
    return _rootDir + '/tmp/';
  }

  String _transDir() {
    return _rootDir + '/trans/';
  }

  String _thumbnailDir() {
    return _rootDir + '/thumnail/';
  }

  String _imageDir() {
    return _rootDir + '/image/';
  }

  String _downloadDir() {
    return _rootDir + '/download/';
  }

  Future _init() async {
    Directory root = await getApplicationDocumentsDirectory();
    _rootDir = root.path;
    await Directory(_tmpDir()).create(recursive: true);
    await Directory(_transDir()).create(recursive: true);
    await Directory(_thumbnailDir()).create(recursive: true);
    await Directory(_imageDir()).create(recursive: true);
    await Directory(_downloadDir()).create(recursive: true);
  }

  Future<int> _getDirSize(String dirPath) async {
    int size = 0;
    Stream entries = Directory(dirPath).list(recursive: true);
    await for (var entry in entries) {
      if (entry is File) {
        var stat = await entry.stat();
        size += stat.size;
      }
    }
    return size;
  }

  Future<int> getCacheSize() async {
    var res = await Future.wait([
      _getDirSize(_tmpDir()),
      _getDirSize(_transDir()),
      _getDirSize(_thumbnailDir()),
      _getDirSize(_imageDir()),
      _getDirSize(_downloadDir()),
    ]);
    int size = 0;
    for (int s in res) {
      size += s;
    }
    return size;
  }

  Future clearCache() async {
    await Directory(_tmpDir()).delete(recursive: true);
    await Directory(_transDir()).delete(recursive: true);
    await Directory(_thumbnailDir()).delete(recursive: true);
    await Directory(_imageDir()).delete(recursive: true);
    await Directory(_downloadDir()).delete(recursive: true);
    await _instance._init();
  }

  Future<String> getTmpFile(Entry entry, AppState state, Function onProgress,
      CancelToken cancelToken) async {
    String entryDir = _tmpDir() + entry.uuid.substring(24, 36) + '/';
    String entryPath = entryDir + entry.name;

    File entryFile = File(entryPath);

    FileStat res = await entryFile.stat();

    // file already downloaded
    if (res.type != FileSystemEntityType.notFound) {
      return entryPath;
    }
    String transPath = _transDir() + '/' + Uuid().v4();
    final ep = 'drives/${entry.pdrv}/dirs/${entry.pdir}/entries/${entry.uuid}';
    final qs = {'name': entry.name, 'hash': entry.hash};
    try {
      // mkdir
      await Directory(entryDir).create(recursive: true);
      // download
      await state.apis.download(ep, qs, transPath,
          onProgress: onProgress, cancelToken: cancelToken);
      // rename
      await File(transPath).rename(entryPath);
    } catch (error) {
      return null;
    }
    return entryPath;
  }

  /// download thumb withLimit
  ///
  /// fire cancelToken.cancel() to cancel request
  Future<Uint8List> getThumbData(
    Entry entry,
    AppState state,
    CancelToken cancelToken,
  ) async {
    String entryPath = _thumbnailDir() + entry.hash + '&width=200&height=200';
    File entryFile = File(entryPath);

    FileStat res = await entryFile.stat();
    if (cancelToken?.cancelError != null) return null;

    Uint8List thumbData;

    // file already downloaded
    if (res.type != FileSystemEntityType.notFound) {
      try {
        thumbData = await entryFile.readAsBytes();
      } catch (error) {
        print(error);
        return null;
      }
      return thumbData;
    }

    String transPath = _transDir() + '/' + Uuid().v4();

    final ep = 'media/${entry.hash}';
    final qs = {
      'alt': 'thumbnail',
      'autoOrient': 'true',
      'modifier': 'caret',
      'width': 200,
      'height': 200,
    };

    try {
      print('download ${entry.name}');
      // download
      await state.apis.download(ep, qs, transPath, cancelToken: cancelToken);
      if (cancelToken?.cancelError != null) return null;

      // rename
      await File(transPath).rename(entryPath);
      if (cancelToken?.cancelError != null) return null;

      // read data
      thumbData = await entryFile.readAsBytes();
    } catch (error) {
      print(error);
      return null;
    }
    return thumbData;
  }

  List<Task> tasks = [];

  /// download raw photo, use AsyncMemoizer to memoizer result to fix bug of hero
  Future getPhoto(Entry entry, AppState state) {
    int index = tasks.indexWhere((task) => task.name == entry.hash);
    if (index > -1) {
      return tasks[index].lock.runOnce(() => _getPhoto(entry, state));
    } else {
      Task task = Task(entry.hash);
      tasks.add(task);
      return task.lock.runOnce(() => _getPhoto(entry, state));
    }
  }

  /// get random key, use AsyncMemoizer to memoizer result
  Future getRandomKey(Entry entry, AppState state) {
    final name = 'randomKey+${entry.hash}';
    int index = tasks.indexWhere((task) => task.name == name);
    if (index > -1) {
      return tasks[index].lock.runOnce(() => _getRandomKey(entry, state));
    } else {
      Task task = Task(name);
      tasks.add(task);
      return task.lock.runOnce(() => _getRandomKey(entry, state));
    }
  }

  Future<String> _getRandomKey(Entry entry, AppState state) async {
    String key;
    try {
      final res = await state.apis.req('randomSrc', {'hash': entry.hash});
      print(res);
      key = res.data['random'];
    } catch (e) {
      print(e);
      key = null;
    }

    return key;
  }

  Future<Uint8List> _getPhoto(Entry entry, AppState state) async {
    String entryPath = _imageDir() + entry.hash;
    String transPath = _transDir() + '/' + Uuid().v4();
    File entryFile = File(entryPath);

    FileStat res = await entryFile.stat();

    Uint8List imageData;

    // file already downloaded
    if (res.type != FileSystemEntityType.notFound) {
      try {
        imageData = await entryFile.readAsBytes();
      } catch (error) {
        print(error);
        return null;
      }
      return imageData;
    }

    final ep = 'media/${entry.hash}';
    final qs = {
      'alt': 'data',
    };
    try {
      // download
      await state.apis.download(ep, qs, transPath);

      // rename
      await File(transPath).rename(entryPath);

      // read data
      imageData = await entryFile.readAsBytes();
    } catch (error) {
      print(error);
      return null;
    }
    return imageData;
  }
}
