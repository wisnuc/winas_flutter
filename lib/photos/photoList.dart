import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './photoItem.dart';
import './photoViewer.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import '../files/delete.dart';

class PhotoList extends StatefulWidget {
  final Album album;
  PhotoList({Key key, this.album}) : super(key: key);
  @override
  _PhotoListState createState() => _PhotoListState();
}

class _PhotoListState extends State<PhotoList> {
  ScrollController myScrollController = ScrollController();
  Select select;

  /// crossAxisCount in Gird
  int lineCount = 4;

  /// mainAxisSpacing and crossAxisSpacing in Grid
  final double spacing = 4.0;

  ///  height of header
  final double headerHeight = 32;

  /// calc photoMapDates and mapHeight from given album
  getList(Album album, BuildContext ctx) {
    final items = album.items;
    final width = MediaQuery.of(ctx).size.width;
    final cellSize = width - spacing * lineCount + spacing;
    if (items.length == 0) {
      return {'photoMapDates': [], 'mapHeight': [], 'cellSize': cellSize};
    }

    /// String headers '2019-03-06' or List of Entry, init with first item
    final List photoMapDates = [
      items[0].hdate,
      [items[0]],
    ];

    items.forEach((entry) {
      final last = photoMapDates.last;
      if (last[0].hdate == entry.hdate) {
        last.add(entry);
      } else if (last[0].hdate != entry.hdate) {
        photoMapDates.add(entry.hdate);
        photoMapDates.add([entry]);
      }
    });

    // remove the duplicated item
    photoMapDates[1].removeAt(0);

    final List mapHeight = [];
    double acc = 0;

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

  void updateList() {
    setState(() {});
  }

  void showPhoto(BuildContext ctx, Entry entry, Uint8List thumbData) {
    Navigator.push(
      ctx,
      TransparentPageRoute(
        builder: (BuildContext context) {
          return PhotoViewer(
            photo: entry,
            list: widget.album.items,
            thumbData: thumbData,
            updateList: updateList,
          );
        },
      ),
    );
  }

  /// getDate via Offset
  ///
  /// mapHeight is List of [offset, hdate]
  Widget getDate(double offset, List mapHeight) {
    final List current =
        mapHeight.firstWhere((e) => e[0] >= offset, orElse: () => [0, '']);
    return Text(current[1]);
  }

  AppBar selectAppBar(AppState state) {
    final length = select.selectedEntry.length;
    return AppBar(
      title: Text(
        '选择了$length项',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.white),
        onPressed: () => select.clearSelect(),
      ),
      brightness: Brightness.light,
      elevation: 2.0,
      iconTheme: IconThemeData(color: Colors.white),
      actions: <Widget>[
        // delete selected entry
        Builder(builder: (ctx) {
          return IconButton(
            icon: Icon(Icons.delete),
            onPressed: length == 0
                ? null
                : () async {
                    bool success = await showDialog(
                      context: this.context,
                      builder: (BuildContext context) =>
                          DeleteDialog(entries: select.selectedEntry),
                    );

                    if (success == true) {
                      showSnackBar(ctx, '删除成功');
                      for (Entry entry in select.selectedEntry) {
                        widget.album.items.remove(entry);
                      }
                    } else if (success == false) {
                      showSnackBar(ctx, '删除失败');
                    }
                    select.clearSelect();
                    setState(() {});
                  },
          );
        }),
      ],
    );
  }

  AppBar listAppBar(AppState state) {
    return AppBar(
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
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.more_horiz),
          onPressed: () {
            showModalBottomSheet(
              context: this.context,
              builder: (BuildContext c) {
                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Material(
                        child: InkWell(
                          onTap: () {
                            select.enterSelect();
                            Navigator.pop(c);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            child: Text('选择'),
                          ),
                        ),
                      ),
                      Material(
                        child: InkWell(
                          onTap: () {
                            select.selectAll(widget.album.items);
                            Navigator.pop(c);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            child: Text('选择全部'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    select = Select(() => this.setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final res = getList(widget.album, context);
    final List list = res['photoMapDates'];
    final List mapHeight = res['mapHeight'];
    final double cellSize = res['cellSize'];
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Scaffold(
          key: Key(widget.album.length.toString()),
          appBar: select.selectMode() ? selectAppBar(state) : listAppBar(state),
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
                            return PhotoItem(
                              // key: Key(line[index].uuid +
                              //     line[index].selected.toString()),
                              item: line[index],
                              showPhoto: showPhoto,
                              cellSize: cellSize,
                              select: select,
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
