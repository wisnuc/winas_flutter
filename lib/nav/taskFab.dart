import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './taskView.dart';
import './xcopyTasks.dart';
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
  final minLeft = 12.0;
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
        newOffset.dx.clamp(0.0, MediaQuery.of(context).size.width - fabWidth);
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

  double getLeft(BuildContext ctx) {
    return minLeft + _offset.dx;
  }

  void onPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return TaskView();
        },
      ),
    );
  }

  void toggle() {
    setState(() {
      extend = !extend;
    });
  }

  static bool isFinished = false;
  static bool pollingStarted = false;

  void pollingTasks(Store<AppState> store) {
    if (pollingStarted) return;
    pollingStarted = true;
    isFinished = false;
    final instance = XCopyTasks.getInstance();
    instance.startPolling(store, () {
      if (this.mounted) {
        setState(() {
          isFinished = true;
        });
      }

      Future.delayed(Duration(seconds: 2), () {
        store.dispatch(UpdateConfigAction(
          Config.combine(
            store.state.config,
            Config(showTaskFab: false),
          ),
        ));
        pollingStarted = false;
        _offset = Offset(0, 0);
      });
    });
  }

  Widget fabIcon() {
    if (isFinished) {
      return Icon(Icons.check_circle);
    }
    return Container(
      height: 32,
      width: 32,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
              strokeWidth: 2,
            ),
          ),
          Positioned.fill(child: Icon(Icons.swap_horiz))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Store<AppState>>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store,
      builder: (context, store) {
        bool showFab = store.state.config.showTaskFab == true;
        if (showFab) {
          pollingTasks(store);
        }
        return Positioned(
          bottom: getBottom(context),
          left: getLeft(context),
          child: showFab
              ? AnimatedOpacity(
                  opacity: isFinished ? 0 : 1,
                  duration: Duration(seconds: 1),
                  child: GestureDetector(
                    onScaleUpdate: _handleOnScaleUpdate,
                    onScaleStart: _handleOnScaleStart,
                    onScaleEnd: _handleOnScaleEnd,
                    child: FloatingActionButton.extended(
                      backgroundColor: Colors.grey[600],
                      onPressed: onPressed,
                      label: Text(!isFinished ? '正在复制/剪切' : '任务完成'),
                      icon: fabIcon(),
                    ),
                  ),
                )
              : Container(),
        );
      },
    );
  }
}
