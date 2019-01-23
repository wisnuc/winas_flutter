import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import '../icons/winas_icons.dart';
import '../redux/redux.dart';

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
      width: 63,
      height: 63,
      margin: EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => print(_nav),
          onLongPress: () => print('long press: $_nav'),
          child: Column(
            children: <Widget>[
              Container(
                height: 36,
                width: 36,
                child: _icon,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.all(
                    const Radius.circular(24),
                  ),
                ),
              ),
              Container(
                height: 15,
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

class TitleRow extends StatelessWidget {
  TitleRow({
    @required this.type, // directory or file
    @required this.isFirst,
  });

  final type;
  final isFirst;

  @override
  Widget build(BuildContext context) {
    if (!isFirst)
      return Container(
        height: 48,
        padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
        alignment: Alignment.centerLeft,
        child: type == 'file' ? Text('文件') : Text('文件夹'),
      );

    return Container(
      height: 48,
      child: Row(
        children: <Widget>[
          Container(width: 16),
          Container(
            child: type == 'file' ? Text('文件') : Text('文件夹'),
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
                                size != null
                                    ? Text(
                                        size,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54),
                                      )
                                    : Container(),
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

Widget buildRow(
  BuildContext context,
  List<Entry> entries,
  int index,
  Node parentNode,
) {
  final entry = entries[index];
  switch (entry.type) {
    case 'nav':
      return Container(
        height: 64,
        child: Row(
          children: _fileNavViews
              .map<Widget>((FileNavView fileNavView) => fileNavView.navButton())
              .toList(),
        ),
      );
    case 'dirTitle':
      return TitleRow(isFirst: true, type: 'directory');
    case 'fileTitle':
      return TitleRow(isFirst: index == 0, type: 'file');
    case 'file':
      return FileRow(
        name: entry.name,
        type: 'file',
        onPress: () => print(entry.name),
        mtime: entry.hmtime,
        size: entry.hsize,
      );
    case 'directory':
      return FileRow(
        name: entry.name,
        type: 'directory',
        onPress: () => Navigator.push(
              context,
              new MaterialPageRoute(
                builder: (context) {
                  return new DirectoryView(
                    node: Node(entry.name, parentNode.driveUUID, entry.uuid),
                  );
                },
              ),
            ),
        mtime: entry.hmtime,
      );
  }
  return null;
}

class Files extends StatefulWidget {
  Files({Key key, this.tag}) : super(key: key);
  final String tag;

  @override
  _FilesState createState() => new _FilesState();
}

class _FilesState extends State<Files> {
  ScrollController myScrollController = ScrollController();
  bool loading = true;
  List<Entry> entries = [];
  List<DirPath> paths = [];
  Node rootNode;

  Future refresh(state) async {
    Drive homeDrive = state.drives
        .firstWhere((drive) => drive.tag == 'home', orElse: () => null);

    String driveUUID = homeDrive?.uuid;

    // rootNode
    rootNode = Node('云盘', driveUUID, driveUUID);

    // request listNav
    var listNav;
    try {
      listNav = await state.apis
          .req('listNavDir', {'driveUUID': driveUUID, 'dirUUID': driveUUID});
    } catch (error) {
      setState(() {
        loading = false;
      });
      return null;
    }

    // assert(listNav.data is Map<String, List>);

    List<Entry> rawEntries =
        List.from(listNav.data['entries'].map((entry) => Entry.fromMap(entry)));
    List<DirPath> rawPath =
        List.from(listNav.data['path'].map((path) => DirPath.fromMap(path)));

    // sort by type
    rawEntries.sort((a, b) => a.type.compareTo(b.type));

    // insert FileNavView, DirectoryTitle, or FileTitle
    Entry navEntry = Entry.fromMap({'type': 'nav'});
    Entry fileTitleEntry = Entry.fromMap({'type': 'fileTitle'});
    Entry dirTitleEntry = Entry.fromMap({'type': 'dirTitle'});
    List<Entry> newEntries = [navEntry];
    if (rawEntries[0]?.type == 'directory') {
      newEntries.add(dirTitleEntry);
      int index = rawEntries.indexWhere((entry) => entry.type == 'file');
      if (index > -1) rawEntries.insert(index, fileTitleEntry);
    } else if (rawEntries[0]?.type == 'file') {
      newEntries.add(fileTitleEntry);
    } else {
      print('empty entries or some error');
    }
    newEntries.addAll(rawEntries);

    setState(() {
      entries = newEntries;
      paths = rawPath;
    });
    return null;
  }

  void refreshAsync(state) {
    refresh(state).then((data) {
      setState(() {
        loading = false;
      });
      print('refresh success');
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      print(error); // TODO
    });
  }

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, AppState>(
      onInit: (store) => refreshAsync(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Theme(
          data: Theme.of(context).copyWith(primaryColor: Colors.teal),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // File list
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RefreshIndicator(
                    onRefresh: () => refresh(state),
                    child: Container(
                      color: Colors.grey[200],
                      child: DraggableScrollbar.semicircle(
                        controller: myScrollController,
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(), // important for performance
                          controller: myScrollController,
                          padding: EdgeInsets.zero, // important for performance
                          itemCount: entries.length,
                          itemExtent: 64,
                          itemBuilder: (BuildContext context, int index) =>
                              buildRow(context, entries, index, rootNode),
                        ),
                      ),
                    ),
                  ),
                ),

                // FileNav
                loading
                    ? Positioned(
                        top: 48,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.grey[200],
                          height: 64,
                          child: Row(
                            children: _fileNavViews
                                .map<Widget>((FileNavView fileNavView) =>
                                    fileNavView.navButton())
                                .toList(),
                          ),
                        ),
                      )
                    : Container(),

                // Search input
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

                // CircularProgressIndicator
                loading
                    ? Positioned(
                        top: 48,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DirectoryView extends StatefulWidget {
  DirectoryView({Key key, this.node}) : super(key: key);

  final Node node;

  @override
  _DirectoryViewState createState() => new _DirectoryViewState(node);
}

class _DirectoryViewState extends State<DirectoryView> {
  _DirectoryViewState(this.node);

  ScrollController myScrollController = ScrollController();
  final Node node;
  List<Entry> entries = [];
  bool loading = true;

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

  Future refresh(state) async {
    String driveUUID = node.driveUUID;
    String dirUUID = node.dirUUID;

    // request listNav
    var listNav;
    try {
      listNav = await state.apis
          .req('listNavDir', {'driveUUID': driveUUID, 'dirUUID': dirUUID});
    } catch (error) {
      setState(() {
        loading = false;
      });
      return null;
    }
    List<Entry> rawEntries =
        List.from(listNav.data['entries'].map((entry) => Entry.fromMap(entry)));
    // List<DirPath> rawPath =
    //     List.from(listNav.data['path'].map((path) => DirPath.fromMap(path)));

    // sort by type
    rawEntries.sort((a, b) => a.type.compareTo(b.type));

    // insert FileNavView, DirectoryTitle, or FileTitle
    Entry fileTitleEntry = Entry.fromMap({'type': 'fileTitle'});
    Entry dirTitleEntry = Entry.fromMap({'type': 'dirTitle'});
    List<Entry> newEntries = [];
    if (rawEntries[0]?.type == 'directory') {
      newEntries.add(dirTitleEntry);
      int index = rawEntries.indexWhere((entry) => entry.type == 'file');
      if (index > -1) rawEntries.insert(index, fileTitleEntry);
    } else if (rawEntries[0]?.type == 'file') {
      newEntries.add(fileTitleEntry);
    } else {
      print('empty entries or some error');
    }
    newEntries.addAll(rawEntries);

    setState(() {
      entries = newEntries;
    });
    return null;
  }

  void refreshAsync(state) {
    refresh(state).then((data) {
      setState(() {
        loading = false;
      });
      print('refresh success');
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      print(error); // TODO
    });
  }

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<AppState, AppState>(
      onInit: (store) => refreshAsync(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(node.name),
            actions: _actions,
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Theme(
                  data: Theme.of(context).copyWith(primaryColor: Colors.teal),
                  child: RefreshIndicator(
                    onRefresh: () => refresh(state),
                    child: Container(
                      color: Colors.grey[200],
                      child: DraggableScrollbar.semicircle(
                        controller: myScrollController,
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(), // important for performance
                          controller: myScrollController,
                          padding: EdgeInsets.zero,
                          itemExtent: 64, // important for performance
                          itemCount: entries.length,
                          itemBuilder: (BuildContext context, int index) =>
                              buildRow(context, entries, index, node),
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