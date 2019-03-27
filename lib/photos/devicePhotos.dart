import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './backup.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import './devicePhotoViewer.dart';
import '../common/taskManager.dart';

class AssetItem extends StatefulWidget {
  AssetItem({Key key, this.entity, this.showPhoto}) : super(key: key);
  final AssetEntity entity;
  final Function showPhoto;
  @override
  _AssetItemState createState() => _AssetItemState();
}

class _AssetItemState extends State<AssetItem> {
  Uint8List thumbData;
  ThumbTask task;

  getThumbData() {
    // check hash
    final tm = TaskManager.getInstance();
    TaskProps props = TaskProps(entity: widget.entity);
    task = tm.createThumbTask(props, (error, value) {
      if (error == null && value is Uint8List && this.mounted) {
        setState(() {
          thumbData = value;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getThumbData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Material(
        child: InkWell(
          onTap: () => widget.showPhoto(context, widget.entity, thumbData),
          child: thumbData == null
              ? Container(
                  color: Colors.grey[200],
                )
              : Image.memory(thumbData, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class DevicePhotos extends StatefulWidget {
  DevicePhotos({Key key, this.album, this.backupWorker}) : super(key: key);
  final LocalAlbum album;
  final BackupWorker backupWorker;
  @override
  _DevicePhotosState createState() => _DevicePhotosState();
}

class _DevicePhotosState extends State<DevicePhotos> {
  ScrollController myScrollController = ScrollController();

  /// crossAxisCount in Gird
  int lineCount = 4;

  /// mainAxisSpacing and crossAxisSpacing in Grid
  final double spacing = 4.0;

  ///  height of header
  final double headerHeight = 32;

  // open photo
  void showPhoto(BuildContext ctx, AssetEntity entity, Uint8List thumbData) {
    Navigator.push(
      ctx,
      TransparentPageRoute(
        builder: (BuildContext context) {
          return DevicePhotoViewer(
            entity: entity,
            list: widget.album.items,
            thumbData: thumbData,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.album.items;
    return StoreConnector<AppState, dynamic>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store,
      builder: (ctx, store) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.album.name,
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
            color: Colors.grey[100],
            child: DraggableScrollbar.semicircle(
              controller: myScrollController,
              // labelTextBuilder: (double offset) => getDate(offset, mapHeight),
              labelConstraints: BoxConstraints.expand(width: 88, height: 36),
              child: CustomScrollView(
                key: Key(list.length.toString()),
                controller: myScrollController,
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: lineCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final entity = list[index];
                        return AssetItem(entity: entity, showPhoto: showPhoto);
                      },
                      childCount: list.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
