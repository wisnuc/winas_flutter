import 'package:flutter/material.dart';

import './delete.dart';
import './xcopyTasks.dart';
import '../common/utils.dart';
import '../common/appBarSlivers.dart';

class TaskView extends StatefulWidget {
  TaskView({Key key}) : super(key: key);

  @override
  _TaskViewState createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  bool loading = true;
  ScrollController myScrollController = ScrollController();

  /// scrollController's listener to get offset
  void listener() {
    setState(() {
      paddingLeft = (myScrollController.offset * 1.25).clamp(16.0, 72.0);
    });
  }

  final instance = XCopyTasks.getInstance();

  @override
  void initState() {
    tasks = instance.tasks;
    reqList().catchError(print);
    myScrollController.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    myScrollController.removeListener(listener);
    instance.clearAllFinished();
    super.dispose();
  }

  List<Task> tasks = [];

  // relist and auto refresh per 500 milliseconds
  Future reqList() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (this.mounted) {
      setState(() {
        tasks = instance.tasks;
      });
      reqList().catchError(print);
    }
  }

  /// left padding of appbar
  double paddingLeft = 16;

  /// slivers
  List<Widget> getSlivers() {
    final String titleName = '复制/移动任务';
    List<Widget> slivers = appBarSlivers(paddingLeft, titleName, action: [
      Builder(
        builder: (ctx) {
          return FlatButton(
            child: Text('全部清除'),
            textColor: Colors.teal,
            onPressed: instance?.tasks?.length != 0
                ? () async {
                    bool success = await showDialog(
                      context: ctx,
                      builder: (BuildContext context) => DeleteDialog(
                            xCopyTasks: instance,
                          ),
                    );
                    if (success == true) {
                      showSnackBar(ctx, '清除成功');
                    } else if (success == false) {
                      showSnackBar(ctx, '清除失败');
                    }
                  }
                : null,
          );
        },
      )
    ]);
    if (tasks == null) {
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            height: 256,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    } else if (tasks.length == 0) {
      slivers.addAll([
        SliverToBoxAdapter(
          child: Icon(
            Icons.web_asset,
            color: Colors.grey[300],
            size: 84,
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 32,
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: Text('当前无传输任务'),
          ),
        ),
      ]);
    } else {
      slivers.add(
        SliverFixedExtentList(
          itemExtent: 64,
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final task = tasks[index];
              return Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.grey[200])),
                child: Row(
                  children: <Widget>[
                    Container(
                      child: task.icon,
                      padding: EdgeInsets.all(16),
                    ),
                    Container(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(flex: 1, child: Container()),
                          Text(
                            task.text,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            maxLines: 1,
                          ),
                          Expanded(flex: 1, child: Container()),
                          task.isFinished
                              ? Container()
                              : LinearProgressIndicator(
                                  backgroundColor: Colors.grey[200],
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.teal[300]),
                                ),
                          Expanded(flex: 1, child: Container()),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      width: 72,
                      height: 72,
                      child: task.isFinished
                          ? Icon(Icons.check_circle)
                          : Builder(
                              builder: (ctx) {
                                return IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () async {
                                    bool success = await showDialog(
                                      context: ctx,
                                      builder: (BuildContext context) =>
                                          DeleteDialog(
                                            task: task,
                                            xCopyTasks: instance,
                                          ),
                                    );

                                    if (success == true) {
                                      showSnackBar(ctx, '取消成功');
                                    } else if (success == false) {
                                      showSnackBar(ctx, '取消失败');
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
            childCount: tasks.length,
          ),
        ),
      );
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: myScrollController,
        slivers: getSlivers(),
      ),
    );
  }
}
