import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const AnimationDuration = Duration(milliseconds: 300);

enum Status { idle, confirm, working }

class Removable extends StatefulWidget {
  /// Creates a widget that can be removed.
  ///
  /// see also [Dissmisable]
  ///
  /// The [key] argument must not be null because [Removable]s are commonly
  /// used in lists and removed from the list when dismissed. Without keys, the
  /// default behavior is to sync widgets based on their index in the list,
  /// which means the item after the dismissed item would be synced with the
  /// state of the dismissed item. Using keys causes the widgets to sync
  /// according to their keys and avoids this pitfall.
  const Removable({
    @required Key key,
    @required this.child,
    this.onDismissed,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// Called when the widget has been dismissed, after finishing resizing.
  final Function onDismissed;

  @override
  _RemovableState createState() => _RemovableState();
}

class _RemovableState extends State<Removable>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  AnimationController _moveController;
  Animation<double> _flingAnimation;

  Status status = Status.idle;
  void _handleFlingAnimation() {
    setState(() {
      dragExtent = _flingAnimation.value;
      if (dragExtent == 0) {
        status = Status.idle;
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  /// moveExtent of child
  double dragExtent = 0;
  double maxExtent() => status == Status.confirm ? -108 : -72;

  void _handleDragStart(DragStartDetails details) {
    // print('_handleDragStart $details');
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // print('_handleDragUpdate $details');

    // only right to left drag
    if (dragExtent >= 0 && details.delta.dx >= 0) return;

    setState(() {
      dragExtent =
          (dragExtent + details.delta.dx).clamp(double.negativeInfinity, 0);
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    // print('_handleDragEnd $details');
    final double magnitude = details.velocity.pixelsPerSecond.distance;

    // Animation end positon
    double end = dragExtent > maxExtent() ? 0 : maxExtent();

    _flingAnimation =
        _moveController.drive(Tween<double>(begin: dragExtent, end: end));

    _moveController
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void _onPressDelete() {
    double end;
    if (status == Status.idle) {
      status = Status.confirm;
      end = maxExtent();
    } else {
      status = Status.working;
      end = -MediaQuery.of(context).size.width;
      Future.delayed(AnimationDuration).then((v) => widget.onDismissed());
    }

    _flingAnimation =
        _moveController.drive(Tween<double>(begin: dragExtent, end: end));

    _moveController
      ..value = 0.0
      ..fling(velocity: 1.0);

    setState(() {});
  }

  String deleteText() =>
      status == Status.idle ? '删除' : status == Status.confirm ? '确认删除' : '删除中';

  Widget background() {
    return Material(
      child: InkWell(
        onTap: _onPressDelete,
        child: Container(
          color: Colors.red,
          child: Row(
            children: <Widget>[
              Expanded(flex: 1, child: Container()),
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  deleteText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    Widget content = ClipRect(
      child: Transform(
        transform: Matrix4.identity()..translate(dragExtent, 0),
        child: widget.child,
      ),
    );

    children.add(Positioned.fill(child: background()));
    children.add(content);
    content = Stack(children: children);

    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
