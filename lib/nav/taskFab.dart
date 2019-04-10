import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/utils.dart';

const double _kMinFlingVelocity = 800.0;

class TaskFab extends StatefulWidget {
  TaskFab({Key key, this.hasBottom}) : super(key: key);
  final bool hasBottom;
  @override
  _TaskFabState createState() => _TaskFabState();
}

class _TaskFabState extends State<TaskFab> with SingleTickerProviderStateMixin {
  bool loading = false;

  Animation<Offset> _flingAnimation;
  AnimationController _controller;

  static Offset _offset = Offset(0.0, 0.0);

  @override
  void initState() {
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation.value;
    });
  }

  Offset prevPosition;
  void _handleOnScaleStart(ScaleStartDetails details) {
    prevPosition = details.focalPoint;
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    Offset delta = details.focalPoint - prevPosition;
    prevPosition = details.focalPoint;
    setState(() {
      _offset += delta;
    });
  }

  final minBottom = 12.0;
  final minRight = 12.0;
  final fabWidth = 188.0;

  void _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    // fling after move
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    final newOffset = _offset + direction * distance;

    // keep minimum padding
    double dx =
        newOffset.dx.clamp(fabWidth - MediaQuery.of(context).size.width, 0.0);
    double dy =
        newOffset.dy.clamp(fabWidth - MediaQuery.of(context).size.height, 0.0);

    // animation of fab
    _flingAnimation =
        _controller.drive(Tween<Offset>(begin: _offset, end: Offset(dx, dy)));

    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  double getBottom(BuildContext ctx) {
    final bottomBarHeight = 58.0;

    final bottomPadding =
        widget.hasBottom ? minBottom : bottomBarHeight + minBottom;
    return bottomPadding - _offset.dy;
  }

  double getRight(BuildContext ctx) {
    return minRight - _offset.dx;
  }

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

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: getBottom(context),
      right: getRight(context),
      child: GestureDetector(
        onScaleUpdate: _handleOnScaleUpdate,
        onScaleStart: _handleOnScaleStart,
        onScaleEnd: _handleOnScaleEnd,
        behavior: HitTestBehavior.translucent,
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
