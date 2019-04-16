import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/taskManager.dart';

const photoTypes = ['JPEG', 'PNG', 'JPG', 'GIF', 'BMP', 'RAW', 'MP4', 'MOV'];

class PhotoItem extends StatefulWidget {
  PhotoItem({Key key, this.item, this.showPhoto, this.cellSize, this.select})
      : super(key: key);
  final Entry item;
  final Function showPhoto;
  final double cellSize;
  final Select select;
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
    TaskProps props = TaskProps(entry: entry, state: state);
    task = tm.createThumbTask(props, (error, value) {
      if (error == null && value is Uint8List && this.mounted) {
        setState(() {
          thumbData = value;
        });
      }
    });
  }

  _onTap(BuildContext ctx) {
    print('_onTap: ${widget.item}');
    if (widget.select.selectMode()) {
      widget.select.toggleSelect(entry);
    } else {
      widget.showPhoto(ctx, entry, thumbData);
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
    final h = entry.metadata.height;
    final w = entry.metadata.width;
    final ratio = h > w ? h / w : w / h;
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _getThumb(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Container(
          child: Material(
            child: InkWell(
              onTap: () => _onTap(ctx),
              onLongPress: () => widget.select.toggleSelect(entry),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: thumbData == null
                        ? Container()
                        : Hero(
                            tag: entry.uuid,
                            child: ClipRect(
                              child: Transform.scale(
                                scale: ratio,
                                child: Image.memory(
                                  thumbData,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: thumbData == null
                        ? Container(color: Colors.grey[300])
                        : Image.memory(
                            thumbData,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned.fill(
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
