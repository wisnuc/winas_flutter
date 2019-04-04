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

  /// get photo token date from AssetEntity.createTime
  getHdate(AssetEntity item) {
    return prettyDate(item.createTime ?? 0, showDay: true);
  }

  /// calc photoMapDates and mapHeight from given album
  getList(LocalAlbum album, BuildContext ctx) {
    final items = album.items;
    if (items.length == 0) return [];

    /// String headers '2019-03-06' or List of Entry, init with first item
    final List photoMapDates = [
      getHdate(items[0]),
      [items[0]],
    ];

    final width = MediaQuery.of(ctx).size.width;

    items.forEach((entry) {
      final last = photoMapDates.last;
      if (getHdate(last[0]) == getHdate(entry)) {
        last.add(entry);
      } else {
        photoMapDates.add(getHdate(entry));
        photoMapDates.add([entry]);
      }
    });

    // remove the duplicated item
    photoMapDates[1].removeAt(0);

    final List mapHeight = [];
    double acc = 0;
    final cellSize = width - spacing * lineCount + spacing;
    photoMapDates.forEach((line) {
      if (line is String) {
        acc += headerHeight;
        mapHeight.add([acc, line]);
      } else if (line is List) {
        final int count = (line.length / lineCount).ceil();
        // (count -1) * spacings + cellSize * count
        acc += (count - 1) * spacing + cellSize / lineCount * count;
        mapHeight.last[0] = acc;
      }
    });

    return {
      'photoMapDates': photoMapDates,
      'mapHeight': mapHeight,
      'cellSize': cellSize
    };
  }

  /// getDate via Offset
  ///
  /// mapHeight is List of [offset, hdate]
  Widget getDate(double offset, List mapHeight) {
    final List current =
        mapHeight.firstWhere((e) => e[0] >= offset, orElse: () => [0, '']);
    return Text(current[1]);
  }

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
  @override
  Widget build(BuildContext context) {
    final res = getList(widget.album, context);
    final List list = res['photoMapDates'];
    final List mapHeight = res['mapHeight'];
    // final double cellSize = res['cellSize'];

    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
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
              labelTextBuilder: (double offset) => getDate(offset, mapHeight),
              labelConstraints: BoxConstraints.expand(width: 88, height: 36),
              child: CustomScrollView(
                key: Key(list.length.toString()),
                controller: myScrollController,
                physics: AlwaysScrollableScrollPhysics(),
                slivers: List.from(
                  list.map(
                    (line) {
                      if (line is String) {
                        return SliverFixedExtentList(
                          itemExtent: headerHeight,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Container(
                                  padding: EdgeInsets.all(8),
                                  child: Text(line),
                                ),
                            childCount: 1,
                          ),
                        );
                      }
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: lineCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1.0,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            return AssetItem(
                              entity: line[index],
                              showPhoto: showPhoto,
                            );
                          },
                          childCount: line.length,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
