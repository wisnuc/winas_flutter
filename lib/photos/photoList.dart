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

  int lineCount = 4;
  getList(Album album) {
    final items = album.items;
    if (items.length == 0) return [];
    items.sort((a, b) => b.hdate.compareTo(a.hdate));

    /// String headers '2019-03-06' or List of Entry
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

    return photoMapDates;
  }

  @override
  Widget build(BuildContext context) {
    final list = getList(widget.album);

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
              labelTextBuilder: (double offset) => Text("${offset ~/ 100}"),
              child: CustomScrollView(
                key: Key(list.length.toString()),
                controller: myScrollController,
                physics: AlwaysScrollableScrollPhysics(),
                slivers: List.from(
                  list.map(
                    (line) {
                      if (line is String) {
                        return SliverFixedExtentList(
                          itemExtent: 24,
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
                          mainAxisSpacing: 4.0,
                          crossAxisSpacing: 4.0,
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
