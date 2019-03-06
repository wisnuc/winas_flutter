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

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              album.name,
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
              child: Container(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: CustomScrollView(
                  key: Key(album.length.toString()),
                  controller: myScrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverFixedExtentList(
                      itemExtent: 24,
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Container(),
                        childCount: 0,
                      ),
                    ),
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 4.0,
                        crossAxisSpacing: 4.0,
                        childAspectRatio: 1.0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return PhotoItem(
                            item: album.items[index],
                          );
                        },
                        childCount: album.length,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
