import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/utils.dart';

class TaskFab extends StatefulWidget {
  TaskFab({Key key}) : super(key: key);

  @override
  _TaskFabState createState() => _TaskFabState();
}

class _TaskFabState extends State<TaskFab> {
  bool loading = false;

  void onPressed() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return openView();
        },
      ),
    );
  }

  Widget openView() {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
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
            backgroundColor: Colors.white,
            brightness: Brightness.light,
            elevation: 2.0,
            iconTheme: IconThemeData(color: Colors.black38),
          ),
          body: Container(
            color: Colors.grey[200],
          ),
        );
      },
    );
  }

  Offset _offset = Offset(0, 0);
  Offset prevPosition;

  void _handleOnScaleStart(ScaleStartDetails details) {
    prevPosition = details.focalPoint;
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    print('_handleOnScaleUpdate ${details.focalPoint}');

    Offset delta = details.focalPoint - prevPosition;
    prevPosition = details.focalPoint;
    setState(() {
      _offset += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: _handleOnScaleUpdate,
      onScaleStart: _handleOnScaleStart,
      child: Transform.translate(
        offset: _offset,
        child: FloatingActionButton.extended(
          backgroundColor: Colors.blue[400],
          onPressed: onPressed,
          label: Text('正在复制/剪切'),
          icon: Icon(Icons.swap_horiz),
        ),
      ),
    );
  }
}
