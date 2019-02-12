import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/cache.dart';
import '../common/renderIcon.dart';

const double _kMinFlingVelocity = 800.0;

List<String> photoMagic = ['JPEG', 'GIF', 'PNG', 'BMP'];

showPhoto(BuildContext ctx, Entry entry, String thumbSrc) {
  Navigator.push(
    ctx,
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              entry.name,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
            elevation: 2.0,
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black38),
          ),
          body: SizedBox.expand(
            child: Hero(
              tag: entry.uuid,
              child: GridPhotoViewer(photo: entry, thumbSrc: thumbSrc),
            ),
          ),
        );
      },
    ),
  );
}

class Thumb extends StatefulWidget {
  Thumb({Key key, this.entry, this.size}) : super(key: key);
  final Entry entry;
  final double size;

  @override
  _ThumbState createState() => _ThumbState(entry, size);
}

class _ThumbState extends State<Thumb> {
  _ThumbState(this.entry, this.size);
  final Entry entry;
  final double size;
  String _imgSrc;

  _getThumb(AppState state) async {
    final cm = await CacheManager.getInstance();
    String thumbPath = await cm.getThumb(entry, state);

    if (thumbPath == null) {
      return;
    } else if (this.mounted) {
      setState(() {
        _imgSrc = thumbPath;
      });
    }
  }

  _onPress(BuildContext ctx) async {
    if (photoMagic.indexOf(entry?.metadata?.type) > -1) {
      print(entry.name);
      showPhoto(ctx, entry, _imgSrc);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _getThumb(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        if (_imgSrc == null) {
          return renderIcon(entry.name, entry.metadata, size: size);
        }
        return Hero(
          tag: entry.uuid,
          child: GestureDetector(
            onTap: () => _onPress(context),
            child: Image.file(
              File(_imgSrc),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

class GridPhotoViewer extends StatefulWidget {
  const GridPhotoViewer({Key key, this.photo, this.thumbSrc}) : super(key: key);
  final String thumbSrc;
  final Entry photo;

  @override
  _GridPhotoViewerState createState() => _GridPhotoViewerState();
}

class _GridPhotoViewerState extends State<GridPhotoViewer>
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
    _thumbSrc = widget.thumbSrc;
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
    setState(() {
      _hiddenThumb = true;
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // The fling animation stops if an input gesture starts.
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
      // Ensure that image location under the focal point stays in the same place despite scaling.
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
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

  String _imgSrc;
  String _thumbSrc;

  _getPhoto(AppState state) async {
    final cm = await CacheManager.getInstance();

    // download thumb
    if (_thumbSrc == null) {
      _thumbSrc = await cm.getThumb(widget.photo, state);
    }
    if (this.mounted) {
      setState(() {});
    } else {
      return;
    }

    // download raw photo
    _imgSrc = await cm.getPhoto(widget.photo, state);

    if (_imgSrc != null && this.mounted) {
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
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: _hiddenThumb
                  ? Container()
                  : _thumbSrc == null
                      ? Center(child: CircularProgressIndicator())
                      : Image.file(
                          File(_thumbSrc),
                          fit: BoxFit.contain,
                        ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: _imgSrc == null
                  ? Container(color: Colors.transparent)
                  : GestureDetector(
                      onScaleStart: _handleOnScaleStart,
                      onScaleUpdate: _handleOnScaleUpdate,
                      onScaleEnd: _handleOnScaleEnd,
                      child: ClipRect(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translate(_offset.dx, _offset.dy)
                            ..scale(_scale),
                          child: Image.file(
                            File(_imgSrc),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
