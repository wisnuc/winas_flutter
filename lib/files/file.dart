import 'package:flutter/material.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import '../icons/winas_icons.dart';

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
      margin: EdgeInsets.fromLTRB(8, 12, 0, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => print(_nav),
          onLongPress: () => print('long press: $_nav'),
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
      ),
    );
  }
}

class FileRow extends StatelessWidget {
  FileRow({
    @required this.name,
    @required this.type,
    @required this.onPress,
    this.mtime,
    this.size,
    this.metadata,
  });

  final name;
  final type;
  final size;
  final mtime;
  final Function onPress;
  final metadata;
  final List actions = [
    {
      'icon': Icons.edit,
      'title': '重命名',
      'action': () => print('rename'),
    },
    {
      'icon': Icons.forward,
      'title': '移动到...',
      'action': () => print('move to'),
    },
    {
      'icon': Icons.open_in_browser,
      'title': '使用其它应用打开',
      'action': () => print('rename'),
    },
    {
      'icon': Icons.delete,
      'title': '删除',
      'action': () => print('delete'),
    },
  ];
  Widget actionItem(IconData icon, String title, Function action) {
    return Container(
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => action,
          child: Row(
            children: <Widget>[
              Container(width: 24),
              Icon(icon),
              Container(width: 32),
              Text(
                title,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onPress(ctx) {
    print('context: $ctx');
    showModalBottomSheet(
      context: ctx,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(width: 24),
                  Icon(type == 'file' ? Winas.word : Icons.folder,
                      color: Colors.blue),
                  Container(width: 32),
                  Text(
                    name,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Expanded(
                    child: Container(),
                    flex: 1,
                  ),
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () => print('press info'),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey[300],
              ),
              Container(height: 8),
              Column(
                children: actions
                    .map<Widget>((value) => actionItem(
                          value['icon'],
                          value['title'],
                          value['action'],
                        ))
                    .toList(),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      child: Material(
        child: InkWell(
          onTap: onPress,
          onLongPress: () => print('long press: $name'),
          child: Row(
            children: <Widget>[
              Container(width: 24),
              Icon(type == 'file' ? Winas.word : Icons.folder,
                  color: Colors.blue),
              Container(width: 32),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.grey[300]),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 10,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Container(height: 4),
                            Row(
                              children: <Widget>[
                                Text(
                                  mtime,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                                Container(width: 8),
                                Text(
                                  size,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(),
                        flex: 1,
                      ),
                      IconButton(
                        icon: Icon(Icons.more_horiz),
                        onPressed: () => _onPress(context),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        height: 97,
        child: Row(
          children: _fileNavViews
              .map<Widget>((FileNavView fileNavView) => fileNavView.navButton())
              .toList(),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1.0, color: Colors.grey[300]),
          ),
        ),
      );
    }

    if (index == 1) {
      return Container(
        height: 48,
        child: Row(
          children: <Widget>[
            Container(width: 16),
            Container(
              child: Text('文件夹'),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Container(
              child: Text(
                '名称',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Container(width: 16),
          ],
        ),
      );
    }

    if (index == 10) {
      return Container(
        height: 48,
        child: Row(
          children: <Widget>[
            Container(width: 16),
            Container(
              child: Text('文件'),
            ),
          ],
        ),
      );
    }

    return FileRow(
      name: 'filename-${index.toString()}',
      type: index > 10 ? 'file' : 'directory',
      onPress: () => index > 10
          ? print(index.toString())
          : Navigator.push(
              context,
              new MaterialPageRoute(
                builder: (context) {
                  return new DirectoryView();
                },
              ),
            ),
      mtime: '2019.01.12',
      size: '2.4MB',
    );
  }

  Future _onRefresh() {
    var action = new Future.delayed(
      const Duration(milliseconds: 1000),
      () => print('refresh 1s later'),
    );
    return action;
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
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: Container(
                  color: Colors.grey[200],
                  child: DraggableScrollbar.semicircle(
                    controller: myScrollController,
                    child: ListView.builder(
                      controller: myScrollController,
                      padding: EdgeInsets.zero,
                      itemCount: 100,
                      itemBuilder: _buildItem,
                    ),
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

class DirectoryView extends StatefulWidget {
  DirectoryView({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _DirectoryViewState createState() => new _DirectoryViewState();
}

class _DirectoryViewState extends State<DirectoryView> {
  ScrollController myScrollController = ScrollController();

  Widget _buildItem(BuildContext context, int index) {
    if (index == 0) {
      return Container(
        height: 48,
        child: Row(
          children: <Widget>[
            Container(width: 16),
            Container(
              child: Text('文件夹'),
            ),
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Container(
              child: Text(
                '名称',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Container(width: 16),
          ],
        ),
      );
    }

    if (index == 10) {
      return Container(
        height: 48,
        child: Row(
          children: <Widget>[
            Container(width: 16),
            Container(
              child: Text('文件'),
            ),
          ],
        ),
      );
    }

    return FileRow(
      name: 'filename-${index.toString()}',
      type: index > 10 ? 'file' : 'directory',
      onPress: () => {},
      mtime: '2019.01.12',
      size: '2.4MB',
    );
  }

  List<Widget> _actions = [
    IconButton(
      icon: Icon(Icons.create_new_folder),
      onPressed: () => {},
    ),
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () => {},
    ),
    IconButton(
      icon: Icon(Icons.view_list),
      onPressed: () => {},
    ),
    IconButton(
      icon: Icon(Icons.more_horiz),
      onPressed: () => {},
    ),
  ];

  Future _onRefresh() {
    var action = new Future.delayed(
      const Duration(milliseconds: 1000),
      () => print('refresh 1s later'),
    );
    return action;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件夹xxxxxxxxxx'),
        actions: _actions,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(primaryColor: Colors.teal),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Container(
            color: Colors.grey[200],
            child: DraggableScrollbar.semicircle(
              controller: myScrollController,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: myScrollController,
                padding: EdgeInsets.zero,
                itemCount: 100,
                itemBuilder: _buildItem,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
