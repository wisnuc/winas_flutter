import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './photoItems.dart';
import '../redux/redux.dart';

class PhotoList extends StatefulWidget {
  final Album album;
  PhotoList({Key key, this.album}) : super(key: key);
  @override
  _PhotoListState createState() => _PhotoListState();
}

class _PhotoListState extends State<PhotoList> {
  ScrollController myScrollController = ScrollController();

  /// crossAxisCount in Gird
  int lineCount = 4;

  /// mainAxisSpacing and crossAxisSpacing in Grid
  final double spacing = 4.0;

  ///  height of header
  final double headerHeight = 32;

  getList(Album album, BuildContext ctx) {
    final items = album.items;
    if (items.length == 0) return [];
    items.sort((a, b) => b.hdate.compareTo(a.hdate));

    /// String headers '2019-03-06' or List of Entry
    final List photoMapDates = [
      items[0].hdate,
      [items[0]],
    ];

    final width = MediaQuery.of(ctx).size.width;

    items.forEach((entry) {
      final last = photoMapDates.last;
      if (last[0].hdate == entry.hdate) {
        last.add(entry);
      } else if (last[0].hdate != entry.hdate) {
        photoMapDates.add(entry.hdate);
        photoMapDates.add([entry]);
      }
    });

    final List mapHeight = [];
    double acc = 0;
    photoMapDates.forEach((line) {
      if (line is String) {
        acc += headerHeight;
        mapHeight.add([acc, line]);
      } else if (line is List<Entry>) {
        final int count = (line.length / lineCount).ceil();
        // (count -1) * spacings + height * count
        acc += (count - 1) * spacing +
            (width - spacing * lineCount + spacing) / lineCount * count;
        mapHeight.last[0] = acc;
      }
    });

    return {'photoMapDates': photoMapDates, 'mapHeight': mapHeight};
  }

  /// getDate via Offset
  ///
  /// mapHeight is List of [offset, hdate]
  Widget getDate(double offset, List mapHeight) {
    final List current =
        mapHeight.firstWhere((e) => e[0] >= offset, orElse: () => [0, '']);
    return Text(current[1]);
  }

  @override
  Widget build(BuildContext context) {
    final res = getList(widget.album, context);
    final List list = res['photoMapDates'];
    final List mapHeight = res['mapHeight'];

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
                            return PhotoItem(
                              item: line[index],
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
