import 'package:redux/redux.dart';
import 'package:flutter/material.dart';

import '../redux/redux.dart';

/// Status
///
/// idle: all tasks finished, no polling
///
/// polling: polling started

enum Status { idle, polling, requesting }

/// xcopyTask
class Task {
  String name;
  String uuid;
  bool isFinished;
  bool isBatch;
  Widget icon;

  /// description of task
  String text;

  /// copy
  String type;

  Task.fromMap(Map m) {
    this.uuid = m['uuid'];
    this.isFinished = m['allFinished'] == true || m['finished'] == true;

    final current = m['current'] as Map;
    this.isBatch = m['batch'] == true;

    this.name = '';
    if (this.isBatch && current != null) {
      final entries = current['entries'];
      if (entries is List && entries.length > 0) {
        this.name = entries[0];
      }
    } else if (!this.isBatch) {
      final entries = m['entries'];
      if (entries is List && entries.length > 0) {
        this.name = entries[0];
      }
    }

    this.type = m['type'];

    this.text = (this.type == 'copy' ? '复制' : '移动') +
        (this.isFinished ? '完成' : this.name);

    this.icon = Icon(this.type == 'copy' ? Icons.content_copy : Icons.forward);
  }

  @override
  String toString() {
    final map = {
      'name': name,
      'uuid': uuid,
      'type': type,
      'allFinished': isFinished,
    };
    return map.toString();
  }
}

class XCopyTasks {
  List<Task> tasks;
  Status status = Status.idle;
  Store<AppState> myStore;
  // keep singleton
  static XCopyTasks _instance;

  static XCopyTasks getInstance() {
    if (_instance == null) {
      _instance = XCopyTasks._();
    }
    return _instance;
  }

  XCopyTasks._();

  Future<void> reqList(Store<AppState> store, Function onFinished) async {
    if (status != Status.polling) return;

    AppState state = store.state;
    final res = await state.apis.req('tasks', null);
    print('polling res got');
    final list = List.from(res.data.map((task) => Task.fromMap(task)));
    tasks = List.from(list.reversed);
    if (tasks.length > 0 && tasks.any((task) => !task.isFinished)) {
      // request again after 1 seconds
      await Future.delayed(Duration(seconds: 1));
      reqList(store, onFinished).catchError(print);
    } else {
      onFinished();
      status = Status.idle;
    }
  }

  Future<void> refresh() async {
    final res = await myStore.state.apis.req('tasks', null);
    final list = List.from(res.data.map((task) => Task.fromMap(task)));
    tasks = List.from(list.reversed);
  }

  void startPolling(Store<AppState> store, Function onFinished) {
    print('startPolling ${status.toString()}');
    if (status == Status.idle) {
      myStore = store;
      status = Status.polling;
      tasks = null;
      reqList(store, onFinished).catchError(print);
    }
  }

  void stopPolling() {
    status = Status.idle;
  }

  /// cancel given xcopy task
  Future<void> cancelTask(Task task) async {
    await myStore.state.apis.req('delTask', {'uuid': task.uuid});
    await refresh();
  }

  /// clear all finished xcopy task
  void clearAllFinished() {
    tasks?.forEach((task) {
      if (task.isFinished) {
        myStore.state.apis
            .req('delTask', {'uuid': task.uuid}).catchError(print);
      }
    });
  }

  /// clear all finished xcopy task
  Future<void> cancelAllTaskAsync() async {
    if (tasks is! List) return;

    List<Future> futures = List.from(tasks
        .map((task) => myStore.state.apis.req('delTask', {'uuid': task.uuid})));

    await Future.wait(futures);
    await refresh();
  }
}
