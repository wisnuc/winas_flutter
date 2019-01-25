import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import '../redux/redux.dart';
import '../common/renderIcon.dart';
import './newFolder.dart';
import './delete.dart';

class FileNavView {
  final Widget _icon;
  final String _title;
  final String _nav;
  final Color _color;
  final Function _onTap;

  FileNavView({
    Widget icon,
    String title,
    String nav,
    Color color,
    Function onTap,
    TickerProvider vsync,
  })  : _icon = icon,
        _title = title,
        _nav = nav,
        _color = color,
        _onTap = onTap;

  Widget navButton(context) {
    return Container(
      width: 63,
      height: 63,
      margin: EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
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
    this.entry,
    this.metadata,
  });

  final name;
  final type;
  final size;
  final mtime;
  final Entry entry;
  final Function onPress;
  final Metadata metadata;

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
      'action': (BuildContext ctx, List<Entry> entries) {
        Navigator.pop(ctx);
        showDialog(
          context: ctx,
          builder: (BuildContext context) => DeleteDialog(entries: entries),
        ).then((success) => {});
      }
    },
  ];

  Widget actionItem(
      BuildContext ctx, IconData icon, String title, Function action) {
    return Container(
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => action(ctx, [entry]),
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
                  type == 'file'
                      ? renderIcon(name, metadata)
                      : Icon(Icons.folder, color: Colors.orange),
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
                          context,
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
              type == 'file'
                  ? renderIcon(name, metadata)
                  : Icon(Icons.folder, color: Colors.orange),
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
    onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Files(
                node: Node(
                  name: '共享空间',
                  tag: 'built-in',
                ),
              );
            },
          ),
        ),
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
              .map<Widget>(
                  (FileNavView fileNavView) => fileNavView.navButton(context))
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
        metadata: entry.metadata,
        entry: entry,
      );
    case 'directory':
      return FileRow(
        name: entry.name,
        type: 'directory',
        onPress: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return Files(
                    node: Node(
                      name: entry.name,
                      driveUUID: parentNode.driveUUID,
                      dirUUID: entry.uuid,
                      tag: 'dir',
                    ),
                  );
                },
              ),
            ),
        mtime: entry.hmtime,
        entry: entry,
      );
  }
  return null;
}

class Files extends StatefulWidget {
  Files({Key key, this.node}) : super(key: key);

  final Node node;
  @override
  _FilesState createState() => _FilesState(node);
}

class _FilesState extends State<Files> {
  _FilesState(this.node);

  final Node node;
  Node currentNode;
  bool loading = true;
  List<Entry> entries = [];
  List<DirPath> paths = [];
  ScrollController myScrollController = ScrollController();

  Future refresh(state) async {
    String driveUUID;
    String dirUUID;
    if (node.tag == 'home') {
      Drive homeDrive = state.drives
          .firstWhere((drive) => drive.tag == 'home', orElse: () => null);

      driveUUID = homeDrive?.uuid;
      dirUUID = driveUUID;
      currentNode = Node(
        name: '云盘',
        driveUUID: driveUUID,
        dirUUID: driveUUID,
        tag: 'home',
      );
    } else if (node.tag == 'dir') {
      driveUUID = node.driveUUID;
      dirUUID = node.dirUUID;
      currentNode = node;
    } else if (node.tag == 'built-in') {
      Drive homeDrive = state.drives
          .firstWhere((drive) => drive.tag == 'built-in', orElse: () => null);

      driveUUID = homeDrive?.uuid;
      dirUUID = driveUUID;
      currentNode = Node(
        name: '共享空间',
        driveUUID: driveUUID,
        dirUUID: driveUUID,
        tag: 'built-in',
      );
    }

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

    // assert(listNav.data is Map<String, List>);

    List<Entry> rawEntries = List.from(listNav.data['entries']
        .map((entry) => Entry.mixNode(entry, currentNode)));
    List<DirPath> rawPath =
        List.from(listNav.data['path'].map((path) => DirPath.fromMap(path)));

    // sort by type
    rawEntries.sort((a, b) => a.type.compareTo(b.type));

    Entry navEntry = Entry.fromMap({'type': 'nav'});
    Entry fileTitleEntry = Entry.fromMap({'type': 'fileTitle'});
    Entry dirTitleEntry = Entry.fromMap({'type': 'dirTitle'});

    // insert FileNavView
    List<Entry> newEntries = node.tag == 'home' ? [navEntry] : [];

    // insert DirectoryTitle, or FileTitle
    if (rawEntries.length == 0) {
      print('empty entries or some error');
    } else if (rawEntries[0]?.type == 'directory') {
      newEntries.add(dirTitleEntry);
      int index = rawEntries.indexWhere((entry) => entry.type == 'file');
      if (index > -1) rawEntries.insert(index, fileTitleEntry);
    } else if (rawEntries[0]?.type == 'file') {
      newEntries.add(fileTitleEntry);
    } else {
      print('other entries!!!!');
    }
    newEntries.addAll(rawEntries);

    if (this.mounted) {
      // avoid calling setState after dispose()
      setState(() {
        entries = newEntries;
        paths = rawPath;
      });
    }
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

  Widget directoryView() {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => refreshAsync(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(node.name),
            actions: [
              IconButton(
                icon: Icon(Icons.create_new_folder),
                onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          NewFolder(node: currentNode),
                    ).then((success) => success ? refresh(state) : null),
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
            ],
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
                              buildRow(context, entries, index, currentNode),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget homeView() {
    return StoreConnector<AppState, AppState>(
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
                              buildRow(context, entries, index, currentNode),
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
                                    fileNavView.navButton(context))
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

  @override
  Widget build(BuildContext context) {
    if (node.tag == 'home') return homeView();
    if (node.tag == 'dir' || node.tag == 'built-in') return directoryView();
    return Center(child: Text('Error !'));
  }
}
