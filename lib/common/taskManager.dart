import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../redux/redux.dart';
import '../common/cache.dart';

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

    // print("""
    //   queue length:  ${thumbTaskQueue.length}
    //      freeNum:    $freeNum
    //      isPending:  ${thumbTaskQueue.where((t) => t.isPending).length}
    //      isRunning:  ${thumbTaskQueue.where((t) => t.isRunning).length}
    //      isFinished: ${thumbTaskQueue.where((t) => t.isFinished).length}
    //      """);

    // run pending tasks
    if (freeNum > 0) {
      thumbTaskQueue.where((t) => t.isPending).take(freeNum).forEach((t) {
        t.run();
      });
    }
  }
}
