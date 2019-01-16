import 'package:flutter/material.dart';
import '../ui/loading.dart';
import '../common/request.dart';
import '../common/persistent.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

class FileNavView {
  final Widget _icon;
  final String _title;
  final String _nav;
  final Color _color;

  FileNavView({
    Widget icon,
    String title,
    String nav,
    Color color,
    TickerProvider vsync,
  })  : _icon = icon,
        _title = title,
        _nav = nav,
        _color = color;
  Widget navButton() {
    return Container(
      width: 72,
      height: 72,
      child: FlatButton(
        padding: EdgeInsets.zero,
        onPressed: () => print(_nav),
        child: Column(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              child: _icon,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.all(
                  const Radius.circular(24),
                ),
              ),
            ),
            Container(
              height: 24,
              width: 72,
              child: Center(
                child: Text(
                  _title,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Files extends StatefulWidget {
  Files({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _FilesState createState() => new _FilesState();
}

class _FilesState extends State<Files> {
  ScrollController myScrollController = ScrollController();

  List<FileNavView> _fileNavViews = [
    FileNavView(
      icon: Icon(Icons.people, color: Colors.white),
      title: '共享空间',
      nav: 'public',
      color: Colors.orange,
    ),
    FileNavView(
      icon: Icon(Icons.refresh, color: Colors.white),
      title: '备份空间',
      nav: 'backup',
      color: Colors.blue,
    ),
    FileNavView(
      icon: Icon(Icons.swap_vert, color: Colors.white),
      title: '传输任务',
      nav: 'transfer',
      color: Colors.purple,
    ),
  ];
  Widget _buildItem(BuildContext context, int index) {
    if (index == 0) {
      return Container(
        height: 80,
        child: Row(
          children: _fileNavViews
              .map<Widget>((FileNavView fileNavView) => fileNavView.navButton())
              .toList(),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
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
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
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
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: Container(
                color: Colors.grey[200],
                child: Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Container(
                    height: 48,
                    // color: Colors.white,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0.0, 2.0),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('搜索'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
