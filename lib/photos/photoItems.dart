import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../files/photo.dart';
import '../redux/redux.dart';
import '../common/taskManager.dart';

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
  Uint8List thumbData;
  ThumbTask task;

  _getThumb(AppState state) {
    // check hash
    if (entry.hash == null) return;
    final tm = TaskManager.getInstance();
    task = tm.createThumbTask(entry, state, (error, value) {
      if (error == null && value is Uint8List && this.mounted) {
        setState(() {
          thumbData = value;
        });
      }
    });
  }

  _onTap(BuildContext ctx) {
    if (entry.selected) {
      entry.toggleSelect();
    } else if (photoTypes.contains(entry?.metadata?.type)) {
      // is photo
      showPhoto(ctx, entry, thumbData);
    }
  }

  @override
  void dispose() {
    task?.abort();
    super.dispose();
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
                    child: thumbData == null
                        ? Container(color: Colors.grey[300])
                        : Hero(
                            tag: entry.uuid,
                            child: Image.memory(
                              thumbData,
                              fit: BoxFit.cover,
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
