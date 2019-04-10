import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';

/// xcopyTask
class Task {
  String name;
  String uuid;
  bool isFinished;
  Widget icon;

  /// copy
  String type;

  Task.fromMap(Map m) {
    this.uuid = m['uuid'];
    this.isFinished = m['allFinished'] == true || m['finished'] == true;
    final entries = m['entries'] as List;
    this.name = entries.length > 0 ? entries[0] : '';
    this.type = m['type'];
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

class TaskView extends StatefulWidget {
  TaskView({Key key, this.toggle}) : super(key: key);
  final Function toggle;
  @override
  _TaskViewState createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  bool loading = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Task> tasks = [];

  Future reqList(Store<AppState> store) async {
    AppState state = store.state;
    final res = await state.apis.req('tasks', null);
    tasks = List.from(res.data.map((task) => Task.fromMap(task)));
    if (this.mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => reqList(store),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '正在进行中的复制/移动任务',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
            // leading: IconButton(
            //   icon: Icon(Icons.close),
            //   onPressed: widget.toggle,
            // ),
            backgroundColor: Colors.white,
            brightness: Brightness.light,
            elevation: 2.0,
            iconTheme: IconThemeData(color: Colors.black38),
          ),
          body: Container(
            color: Colors.grey[200],
            child: ListView.builder(
              itemBuilder: (ctx, index) {
                final task = tasks[index];
                return Container(
                  child: Row(
                    children: <Widget>[
                      Container(
                        child: task.icon,
                        padding: EdgeInsets.all(16),
                      ),
                      Container(width: 16),
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        width: 72,
                        height: 72,
                        child: task.isFinished
                            ? Icon(Icons.check_circle)
                            : Icon(Icons.close),
                      ),
                    ],
                  ),
                );
              },
              itemCount: tasks.length,
              cacheExtent: 64.0,
            ),
          ),
        );
      },
    );
  }
}
