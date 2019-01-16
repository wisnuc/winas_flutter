import 'package:flutter/material.dart';
import '../common/request.dart';
import '../common/persistent.dart';
import '../ui/loading.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

class Files extends StatefulWidget {
  Files({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _FilesState createState() => new _FilesState();
}

class _FilesState extends State<Files> {
  ScrollController myScrollController = ScrollController();
  Widget _buildItem(BuildContext context, int index) {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(4.0),
        color: Colors.purple[index % 9 * 100],
        child: Center(
          child: Text(
            index.toString(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(primaryColor: Colors.teal),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              height: 48,
              child: Text('搜索'),
            ),
            Container(
              constraints: BoxConstraints.expand(),
              color: Colors.grey[200],
              child: DraggableScrollbar.semicircle(
                controller: myScrollController,
                child: ListView.builder(
                  controller: myScrollController,
                  padding: EdgeInsets.zero,
                  itemCount: 100000,
                  itemExtent: 100.0,
                  itemBuilder: _buildItem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
