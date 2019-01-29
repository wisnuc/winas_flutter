import 'dart:io';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';

import '../redux/redux.dart';

class CacheManager {
  static CacheManager _instance;

  static Future<CacheManager> getInstance() async {
    if (_instance == null) {
      await _lock.synchronized(() async {
        if (_instance == null) {
          // keep local instance till it is fully initialized
          var newInstance = new CacheManager._();
          await newInstance._init();
          _instance = newInstance;
        }
      });
    }
    return _instance;
  }

  CacheManager._();

  static Lock _lock = new Lock();

  String _rootDir;

  String _tmpDir() {
    return _rootDir + '/tmp/';
  }

  String _transDir() {
    return _rootDir + '/trans/';
  }

  String _thumnailDir() {
    return _rootDir + '/thumnail/';
  }

  String _imageDir() {
    return _rootDir + '/image/';
  }

  Future _init() async {
    Directory root = await getApplicationDocumentsDirectory();
    _rootDir = root.path;
    await Directory(_tmpDir()).create(recursive: true);
    await Directory(_transDir()).create(recursive: true);
    await Directory(_thumnailDir()).create(recursive: true);
    await Directory(_imageDir()).create(recursive: true);
  }

  Future<String> getTmpFile(Entry entry, AppState state) async {
    String entryDir = _tmpDir() + entry.uuid.substring(24, 36) + '/';
    String entryPath = entryDir + entry.name;
    String transPath = _transDir() + '/' + Uuid().v4();
    File entryFile = new File(entryPath);

    FileStat res = await entryFile.stat();

    // file already downloaded
    if (res.type != FileSystemEntityType.notFound) {
      return entryPath;
    }

    final ep = 'drives/${entry.pdrv}/dirs/${entry.pdir}/entries/${entry.uuid}';
    final qs = {'name': entry.name, 'hash': entry.hash};
    try {
      // mkdir
      await Directory(entryDir).create(recursive: true);
      // download
      await state.apis.download(ep, qs, transPath);
      // rename
      await File(transPath).rename(entryPath);
    } catch (error) {
      print(error);
      return null;
    }
    return entryPath;
  }
}
