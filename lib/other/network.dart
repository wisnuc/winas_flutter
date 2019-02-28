import 'package:flutter/material.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

class NetWork extends StatelessWidget {
  final myScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Material(
      child: DraggableScrollbar.semicircle(
        controller: myScrollController,
        child: CustomScrollView(
          controller: myScrollController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            // AppBar，包含一个导航栏
            SliverAppBar(
              pinned: true,
              expandedHeight: 250.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('网络'),
                background: Image.network(
                  "https://picsum.photos/250?image=0",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.all(8.0),
              sliver: SliverGrid(
                // Grid
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Grid按两列显示
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 4.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    //创建子widget
                    return Container(
                      alignment: Alignment.center,
                      color: Colors.cyan[100 * (index % 9)],
                      child: Text('grid item $index'),
                    );
                  },
                  childCount: 20,
                ),
              ),
            ),
            // List
            SliverFixedExtentList(
              itemExtent: 50.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Container(
                    alignment: Alignment.center,
                    color: Colors.lightBlue[100 * (index % 9)],
                    child: Text('list item $index'),
                  );
                },
                childCount: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
