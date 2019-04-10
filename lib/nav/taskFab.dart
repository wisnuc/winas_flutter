import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './taskView.dart';
import '../redux/redux.dart';

class TaskFab extends StatefulWidget {
  TaskFab({Key key, this.hasBottom}) : super(key: key);
  final bool hasBottom;
  @override
  _TaskFabState createState() => _TaskFabState();
}

class _TaskFabState extends State<TaskFab> with SingleTickerProviderStateMixin {
  bool loading = false;
  bool extend = false;
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
    final newOffset =
        magnitude < 800 ? _offset : _offset + direction * distance;

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

  void onPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return TaskView(
            toggle: toggle,
          );
        },
      ),
    );
  }

  void toggle() {
    setState(() {
      extend = !extend;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Config>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state.config,
      builder: (context, config) {
        bool showFab = config.gridView == true;
        bool isFinished = false;
        return Positioned(
          bottom: getBottom(context),
          right: getRight(context),
          child: showFab
              ? GestureDetector(
                  onScaleUpdate: _handleOnScaleUpdate,
                  onScaleStart: _handleOnScaleStart,
                  onScaleEnd: _handleOnScaleEnd,
                  child: FloatingActionButton.extended(
                    backgroundColor: Colors.grey[600],
                    onPressed: onPressed,
                    label: Text(!isFinished ? '正在复制/剪切' : '任务完成'),
                    icon: Icon(
                        !isFinished ? Icons.swap_horiz : Icons.check_circle),
                  ),
                )
              : Container(),
        );
      },
    );
  }
}
