import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/cache.dart';

const double _kMinFlingVelocity = 800.0;

List<String> photoMagic = ['JPEG', 'GIF', 'PNG', 'BMP'];

List<String> thumbMagic = ['JPEG', 'GIF', 'PNG', 'BMP', 'PDF'];

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({Key key, this.photo, this.thumbData, this.list})
      : super(key: key);
  final Uint8List thumbData;
  final List list;
  final Entry photo;

  @override
  _PhotoViewerState createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  /// current photo, default: widget.photo
  Entry currentItem;
  ScrollController myScrollController = ScrollController();
  @override
  void initState() {
    currentItem = widget.photo;
    super.initState();
  }

  double opacity = 1.0;
  updateOpacity(double value) {
    setState(() {
      opacity = value.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('currentItem ${currentItem.uuid}');
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          currentItem.name,
          style: TextStyle(
            color: Color.fromARGB((opacity * 255 * 0.87).round(), 0, 0, 0),
            fontWeight: FontWeight.normal,
          ),
        ),
        elevation: 0.0,
        brightness: Brightness.light,
        bottomOpacity: opacity,
        toolbarOpacity: opacity,
        backgroundColor: Color.fromARGB((opacity * 255).round(), 255, 255, 255),
        iconTheme: IconThemeData(color: Colors.black38),
      ),
      body: PageView(
        controller:
            PageController(initialPage: widget.list.indexOf(currentItem)),
        children: List.from(
          widget.list
              .map(
                (photo) => Container(
                      child: Hero(
                        tag: photo.uuid,
                        child: GridPhoto(
                          updateOpacity: updateOpacity,
                          photo: photo,
                          thumbData:
                              photo == widget.photo ? widget.thumbData : null,
                        ),
                      ),
                    ),
              )
              .toList(),
        ),
        onPageChanged: (int index) {
          print('current index $index');
          if (mounted) {
            setState(() {
              currentItem = widget.list[index];
            });
          }
        },
      ),
    );
  }
}

class GridPhoto extends StatefulWidget {
  const GridPhoto({Key key, this.photo, this.thumbData, this.updateOpacity})
      : super(key: key);
  final Uint8List thumbData;
  final Entry photo;
  final Function updateOpacity;

  @override
  _GridPhotoState createState() => _GridPhotoState();
}

class _GridPhotoState extends State<GridPhoto>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _flingAnimation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _normalizedOffset;
  double _previousScale;
  bool _hiddenThumb = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
    thumbData = widget.thumbData;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The maximum offset value is 0,0. If the size of this renderer's box is w,h
  // then the minimum offset value is w - _scale * w, h - _scale * h.
  Offset _clampOffset(Offset offset) {
    final Size size = context.size;
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation.value;
    });
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    print('_handleOnScaleStart');
    opacity = 1;
    prevPosition = details.focalPoint;
    updateOpacity();
    setState(() {
      _hiddenThumb = true;
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // The fling animation stops if an input gesture starts.
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    print('_handleOnScaleUpdate');
    if (_scale == 1.0) {
      final rate = 255;

      Offset delta = details.focalPoint - prevPosition;
      prevPosition = details.focalPoint;
      print(delta);
      print(details.focalPoint);

      _offset += delta;

      opacity = (1 - _offset.dy / rate).clamp(0.0, 1.0);

      updateOpacity();
      setState(() {});
    } else {
      setState(() {
        _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
        // Ensure that image location under the focal point stays in the same place despite scaling.
        _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
      });
    }
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    if (opacity <= 0.5) {
      Navigator.pop(context);
      return;
    }

    if (_scale == 1.0) {
      _offset = Offset(0, 0);
    }
    opacity = 1.0;
    updateOpacity();

    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size).shortestSide;
    _flingAnimation = _controller.drive(Tween<Offset>(
        begin: _offset, end: _clampOffset(_offset + direction * distance)));
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void _handleonDoubleTap() {
    Offset focalPoint = Offset(context.size.width / 2, context.size.height / 2);
    double scale = 2;
    setState(() {
      _hiddenThumb = true;
      _scale = (_scale * scale).clamp(1.0, 4.0);
      // // Ensure that image location under the focal point stays in the same place despite scaling.
      _offset = _clampOffset(focalPoint - focalPoint * _scale);
    });
  }

  double opacity = 1;

  updateOpacity() {
    widget.updateOpacity(opacity);
  }

  Offset prevPosition;
  void onDragStart(DragStartDetails details) {
    opacity = 1;
    prevPosition = details.globalPosition;
    updateOpacity();
    setState(() {
      _hiddenThumb = true;
      _controller.stop();
    });
  }

  void onDragUpdate(DragUpdateDetails details) {
    final rate = 255;

    Offset delta = details.globalPosition - prevPosition;
    prevPosition = details.globalPosition;
    print(delta);
    print(details.delta);

    _offset += delta;

    opacity = (1 - _offset.dy / rate).clamp(0.0, 1.0);

    updateOpacity();
    setState(() {});
  }

  void onDragEnd(DragEndDetails event) {
    // final dy = event.velocity.pixelsPerSecond.dy;
    if (opacity <= 0.5) {
      Navigator.pop(context);
      return;
    }

    if (_scale == 1.0) {
      _offset = Offset(0, 0);
    }
    opacity = 1.0;
    updateOpacity();
    setState(() {});
  }

  Uint8List imageData;
  Uint8List thumbData;

  _getPhoto(AppState state) async {
    final cm = await CacheManager.getInstance();

    // download thumb
    if (thumbData == null) {
      thumbData = await cm.getThumbData(widget.photo, state, null);
    }
    if (this.mounted) {
      print('thumbData updated');
      setState(() {});
    } else {
      return;
    }

    // download raw photo
    imageData = await cm.getPhoto(widget.photo, state);

    if (imageData != null && this.mounted) {
      print('imageData updated');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _getPhoto(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Container(
          color: Color.fromARGB((opacity * 255).round(), 255, 255, 255),
          // color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: _hiddenThumb
                    ? Container()
                    : thumbData == null
                        ? Center(child: CircularProgressIndicator())
                        : Image.memory(
                            thumbData,
                            fit: BoxFit.contain,
                          ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: imageData == null
                    ? Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onScaleStart: _handleOnScaleStart,
                        onScaleUpdate: _handleOnScaleUpdate,
                        onScaleEnd: _handleOnScaleEnd,
                        // onDoubleTap: _handleonDoubleTap,
                        // onVerticalDragStart: onDragStart,
                        // onVerticalDragUpdate: onDragUpdate,
                        // onVerticalDragEnd: onDragEnd,
                        child: ClipRect(
                          child: Transform(
                            transform: Matrix4.identity()
                              ..translate(_offset.dx, _offset.dy)
                              ..scale(_scale),
                            child: Image.memory(
                              imageData,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
