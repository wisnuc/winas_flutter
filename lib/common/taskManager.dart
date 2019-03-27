import 'dart:async';
import 'dart:typed_data';

import '../redux/redux.dart';
import '../common/cache.dart';
import 'package:photo_manager/photo_manager.dart';

enum Status { pending, running, finished }

class TaskProps {
  // Nas photo
  Entry entry;
  AppState state;
  // local photo
  AssetEntity entity;

  TaskProps({this.entity, this.entry, this.state});

  bool get isNasPhoto => entry != null && state != null;
  bool get isLocalPhoto => entity != null;
}

Future<Uint8List> getThumbAsync(TaskProps props) async {
  Uint8List thumbData;
  if (props.isNasPhoto) {
    final cm = await CacheManager.getInstance();
    thumbData = await cm.getThumbData(props.entry, props.state);
  } else if (props.isLocalPhoto) {
    thumbData = await props.entity.thumbDataWithSize(200, 200);
  }
  return thumbData;
}

void getThumbCallback(TaskProps props, Function callback) {
  getThumbAsync(props)
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
  TaskProps props;

  ThumbTask(
    this.props,
    Function onFinished,
  ) : super(onFinished);

  Future getSrc() async {}

  @override
  run() {
    super.run();
    getThumbCallback(props, (err, value) {
      if (err != null) {
        this.error(err);
      } else {
        this.finish(value);
      }
    });
  }

  /// only abort pending task
  @override
  abort() {
    if (this.isFinished || this.isRunning) return;
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

  ThumbTask createThumbTask(TaskProps props, Function callback) {
    final Function onFinished = (error, value) {
      callback(error, value);
      // schedule in next event-loop iteration
      Future.delayed(Duration.zero).then((v) => schedule());
    };

    final task = ThumbTask(props, onFinished);
    thumbTaskQueue.insert(0, task);
    schedule();
    return task;
  }

  schedule() {
    // remove finished
    thumbTaskQueue.removeWhere((t) => t.isFinished);

    // calc number of task left to run
    int freeNum =
        thumbTaskLimit - thumbTaskQueue.where((t) => t.isRunning).length;

    // run pending tasks
    if (freeNum > 0) {
      thumbTaskQueue.where((t) => t.isPending).take(freeNum).forEach((t) {
        t.run();
      });
    }
  }
}
