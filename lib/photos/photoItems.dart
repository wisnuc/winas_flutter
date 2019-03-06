import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../files/photo.dart';
import '../redux/redux.dart';
import '../common/cache.dart';
import '../common/renderIcon.dart';

const photoTypes = ['JPEG', 'PNG', 'JPG', 'GIF', 'BMP', 'RAW'];

class PhotoItem extends StatefulWidget {
  PhotoItem({Key key, this.item}) : super(key: key);
  final Entry item;
  @override
  _PhotoItemState createState() => _PhotoItemState(item);
}

class _PhotoItemState extends State<PhotoItem> {
  final Entry entry;
  _PhotoItemState(this.entry);
  String thumbSrc;

  _getThumb(AppState state) async {
    // has hash
    if (entry.hash == null) return;

    final cm = await CacheManager.getInstance();
    thumbSrc = await cm.getThumb(entry, state);

    if (this.mounted && thumbSrc != null) {
      setState(() {});
    }
  }

  _onTap(BuildContext ctx) {
    if (entry.selected) {
      entry.toggleSelect();
    } else if (photoTypes.contains(entry?.metadata?.type)) {
      // is photo
      showPhoto(ctx, entry, thumbSrc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.item;
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _getThumb(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Container(
          child: Material(
            child: InkWell(
              onTap: () => _onTap(ctx),
              onLongPress: () {},
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      child: thumbSrc == null
                          ? renderIcon(entry.name, entry.metadata, size: 72.0)
                          // show thumb
                          : Hero(
                              tag: entry.uuid,
                              child: Image.file(
                                File(thumbSrc),
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: entry.selected
                        ? Container(
                            color: Colors.black12,
                            child: Center(
                              child: Container(
                                height: 48,
                                width: 48,
                                child: entry.selected
                                    ? Icon(Icons.check, color: Colors.white)
                                    : Container(),
                                decoration: BoxDecoration(
                                  color: entry.selected
                                      ? Colors.teal
                                      : Colors.black12,
                                  borderRadius: BorderRadius.all(
                                    const Radius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
