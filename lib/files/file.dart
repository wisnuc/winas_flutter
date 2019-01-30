import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './delete.dart';
import './rename.dart';
import './fileRow.dart';
import './newFolder.dart';
import '../redux/redux.dart';
import '../common/loading.dart';
import '../common/cache.dart';

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

Widget _buildRow(
  BuildContext context,
  List<Entry> entries,
  int index,
  Node parentNode,
  List actions,
  Function download,
) {
  final entry = entries[index];
  switch (entry.type) {
    case 'dirTitle':
      return TitleRow(isFirst: true, type: 'directory');
    case 'fileTitle':
      return TitleRow(isFirst: index == 0, type: 'file');
    case 'file':
      return FileRow(
        name: entry.name,
        type: 'file',
        onPress: () => download(entry),
        mtime: entry.hmtime,
        size: entry.hsize,
        metadata: entry.metadata,
        entry: entry,
        actions: actions,
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
        actions: actions,
      );
  }
  return null;
}

Widget _buildGrid(
  BuildContext context,
  List<Entry> entries,
  int index,
  Node parentNode,
  List actions,
  Function download,
) {
  final entry = entries[index];
  switch (entry.type) {
    case 'file':
      return FileGrid(
        name: entry.name,
        type: 'file',
        onPress: () => download(entry),
        mtime: entry.hmtime,
        size: entry.hsize,
        metadata: entry.metadata,
        entry: entry,
        actions: actions,
      );
    case 'directory':
      return FileGrid(
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
        actions: actions,
      );
  }
  return Container();
}

void showSnackBar(BuildContext ctx, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: 1),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  Scaffold.of(ctx, nullOk: true)?.showSnackBar(snackBar);
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
  Error _error;
  List<Entry> entries = [];
  List<Entry> dirs = [];
  List<Entry> files = [];
  List<DirPath> paths = [];
  bool gridView = false;
  ScrollController myScrollController = ScrollController();
  Function actions;

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
      _error = null;
    } catch (error) {
      setState(() {
        loading = false;
        _error = error;
      });

      print(error);
      return null;
    }

    // assert(listNav.data is Map<String, List>);

    List<Entry> rawEntries = List.from(listNav.data['entries']
        .map((entry) => Entry.mixNode(entry, currentNode)));
    List<DirPath> rawPath =
        List.from(listNav.data['path'].map((path) => DirPath.fromMap(path)));

    // sort by type
    rawEntries.sort((a, b) => a.type.compareTo(b.type));

    // insert FileNavView
    List<Entry> newEntries = [];
    List<Entry> newDirs = [];
    List<Entry> newFiles = [];

    // insert DirectoryTitle, or FileTitle
    if (rawEntries.length == 0) {
      print('empty entries or some error');
    } else if (rawEntries[0]?.type == 'directory') {
      // newEntries.add(dirTitleEntry);
      int index = rawEntries.indexWhere((entry) => entry.type == 'file');
      if (index > -1) {
        // rawEntries.insert(index, fileTitleEntry);
        newDirs = List.from(rawEntries.take(index));
        newFiles = List.from(rawEntries.skip(index));
      } else {
        newDirs = rawEntries;
      }
    } else if (rawEntries[0]?.type == 'file') {
      // newEntries.add(fileTitleEntry);
      newFiles = rawEntries;
    } else {
      print('other entries!!!!');
    }
    newEntries.addAll(rawEntries);

    if (this.mounted) {
      // avoid calling setState after dispose()
      setState(() {
        entries = newEntries;
        dirs = newDirs;
        files = newFiles;
        paths = rawPath;
        loading = false;
        _error = null;
      });
    }
    return null;
  }

  void refreshAsync(state) {
    refresh(state).then((data) {
      print('refresh success');
    }).catchError((error) {
      print('refresh error');
      print(error); // TODO
    });
  }

  void _download(BuildContext ctx, Entry entry, AppState state) async {
    showLoading(
      barrierDismissible: false,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints.expand(),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      context: ctx,
    );
    final cm = await CacheManager.getInstance();
    String entryPath = await cm.getTmpFile(entry, state);
    print(entryPath);
    Navigator.pop(ctx);
    if (entryPath == null) {
      showSnackBar(ctx, '打开失败');
    } else {
      OpenFile.open(entryPath);
    }
  }

  @override
  void initState() {
    super.initState();

    // actions in menu
    actions = (state) => [
          {
            'icon': Icons.edit,
            'title': '重命名',
            'types': ['file', 'directory'],
            'action': (BuildContext ctx, Entry entry) {
              Navigator.pop(ctx);
              showDialog(
                context: ctx,
                builder: (BuildContext context) => RenameDialog(
                      entry: entry,
                      node: currentNode,
                    ),
              ).then((success) => refresh(state));
            },
          },
          {
            'icon': Icons.content_copy,
            'title': '复制到...',
            'types': ['file', 'directory'],
            'action': () => print('copy to'),
          },
          {
            'icon': Icons.forward,
            'title': '移动到...',
            'types': ['file', 'directory'],
            'action': () => print('move to'),
          },
          {
            'icon': Icons.file_download,
            'title': '离线可用',
            'types': ['file'],
            'action': () => print('move to'),
          },
          {
            'icon': Icons.share,
            'title': '分享到共享空间',
            'types': node.tag == 'home' ? ['file', 'directory'] : [],
            'action': (BuildContext ctx, Entry entry) async {
              Navigator.pop(ctx);
              showLoading(
                barrierDismissible: false,
                builder: (ctx) {
                  return Container(
                    constraints: BoxConstraints.expand(),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                context: this.context,
              );

              // get built-in public drive
              Drive publicDrive = state.drives.firstWhere(
                  (drive) => drive.tag == 'built-in',
                  orElse: () => null);

              String driveUUID = publicDrive?.uuid;

              var args = {
                'type': 'copy',
                'entries': [entry.name],
                'policies': {
                  'dir': ['rename', 'rename'],
                  'file': ['rename', 'rename']
                },
                'dst': {'drive': driveUUID, 'dir': driveUUID},
                'src': {
                  'drive': currentNode.driveUUID,
                  'dir': currentNode.dirUUID
                },
              };
              try {
                await state.apis.req('xcopy', args);
                Navigator.pop(this.context);
                showSnackBar(ctx, '分享成功');
              } catch (error) {
                Navigator.pop(this.context);
                showSnackBar(ctx, '分享失败');
              }
            },
          },
          {
            'icon': Icons.open_in_new,
            'title': '使用其它应用打开',
            'types': ['file'],
            'action': () => print('rename'),
          },
          {
            'icon': Icons.delete,
            'title': '删除',
            'types': ['file', 'directory'],
            'action': (BuildContext ctx, Entry entry) async {
              Navigator.pop(ctx);
              bool success = await showDialog(
                context: this.context,
                builder: (BuildContext context) =>
                    DeleteDialog(entries: [entry]),
              );

              if (success) {
                await refresh(state);
                showSnackBar(ctx, '删除成功');
              } else {
                showSnackBar(ctx, '删除失败');
              }
            },
          },
        ];
  }

  Widget searchBar(state) {
    return Material(
      elevation: 2.0,
      child: Row(
        children: <Widget>[
          Container(width: 16),
          Icon(Icons.search),
          Container(width: 32),
          Text('搜索文件', style: TextStyle(color: Colors.black54)),
          Expanded(flex: 1, child: Container()),
          IconButton(
            icon: Icon(Icons.create_new_folder),
            onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      NewFolder(node: currentNode),
                ).then((success) => success == true ? refresh(state) : null),
          ),
          IconButton(
            icon: Icon(gridView ? Icons.view_list : Icons.view_module),
            onPressed: () => setState(() {
                  gridView = !gridView;
                }),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz),
            onPressed: () => {},
          ),
        ],
      ),
    );
  }

  Widget dirTitle() {
    return SliverFixedExtentList(
      itemExtent: 48,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return TitleRow(isFirst: true, type: 'directory');
        },
        childCount: dirs.length > 0 ? 1 : 0,
      ),
    );
  }

  Widget fileTitle() {
    return SliverFixedExtentList(
      itemExtent: 48,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return TitleRow(isFirst: dirs.length == 0, type: 'file');
        },
        childCount: files.length > 0 ? 1 : 0,
      ),
    );
  }

  Widget dirGrid(state) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 4.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return _buildGrid(
            context,
            dirs,
            index,
            currentNode,
            actions(state),
            (entry) => _download(context, entry, state),
          );
        },
        childCount: dirs.length,
      ),
    );
  }

  Widget dirRow(state) {
    return SliverFixedExtentList(
      itemExtent: 64,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return _buildRow(
            context,
            dirs,
            index,
            currentNode,
            actions(state),
            (entry) => _download(context, entry, state),
          );
        },
        childCount: dirs.length,
      ),
    );
  }

  Widget fileGrid(state) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return _buildGrid(
            context,
            files,
            index,
            currentNode,
            actions(state),
            (entry) => _download(context, entry, state),
          );
        },
        childCount: files.length,
      ),
    );
  }

  Widget fileRow(state) {
    return SliverFixedExtentList(
      itemExtent: 64,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return _buildRow(
            context,
            files,
            index,
            currentNode,
            actions(state),
            (entry) => _download(context, entry, state),
          );
        },
        childCount: files.length,
      ),
    );
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
                icon: Icon(Icons.search),
                onPressed: () => {},
              ),
              IconButton(
                icon: Icon(Icons.create_new_folder),
                onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          NewFolder(node: currentNode),
                    ).then((success) => success ? refresh(state) : null),
              ),
              IconButton(
                icon: Icon(gridView ? Icons.view_list : Icons.view_module),
                onPressed: () => setState(() {
                      gridView = !gridView;
                    }),
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
                    child: _error != null
                        ? Center(
                            child: Text('出错啦！'),
                          )
                        : entries.length == 0
                            ? Center(
                                child: Text('空文件夹'),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: DraggableScrollbar.semicircle(
                                  controller: myScrollController,
                                  child: CustomScrollView(
                                    controller: myScrollController,
                                    physics: AlwaysScrollableScrollPhysics(),
                                    slivers: <Widget>[
                                      // dir title
                                      dirTitle(),
                                      // dir Grid or Row view
                                      gridView ? dirGrid(state) : dirRow(state),
                                      // file title
                                      fileTitle(),
                                      // file Grid or Row view
                                      gridView
                                          ? fileGrid(state)
                                          : fileRow(state),
                                    ],
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
                  top: 56,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RefreshIndicator(
                    onRefresh: () => refresh(state),
                    child: _error != null
                        ? Center(
                            child: Text('出错啦！'),
                          )
                        : entries.length == 0 && !loading
                            ? Center(
                                child: Text('空文件夹'),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: DraggableScrollbar.semicircle(
                                  controller: myScrollController,
                                  child: CustomScrollView(
                                    controller: myScrollController,
                                    physics: AlwaysScrollableScrollPhysics(),
                                    slivers: <Widget>[
                                      // file nav view
                                      SliverFixedExtentList(
                                        itemExtent: 96.0,
                                        delegate: SliverChildBuilderDelegate(
                                          (BuildContext context, int index) {
                                            return Container(
                                              color: Colors.grey[200],
                                              height: 96,
                                              child: Row(
                                                children: _fileNavViews
                                                    .map<Widget>((FileNavView
                                                            fileNavView) =>
                                                        fileNavView
                                                            .navButton(context))
                                                    .toList(),
                                              ),
                                            );
                                          },
                                          childCount: 1,
                                        ),
                                      ),
                                      // dir title
                                      dirTitle(),
                                      // dir Grid or Row view
                                      gridView ? dirGrid(state) : dirRow(state),
                                      // file title
                                      fileTitle(),
                                      // file Grid or Row view
                                      gridView
                                          ? fileGrid(state)
                                          : fileRow(state),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),

                // FileNav
                loading
                    ? Positioned(
                        top: 56,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.grey[200],
                          height: 96,
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
                  top: 8,
                  left: 0,
                  right: 0,
                  height: 48,
                  child: Container(
                    color: Colors.grey[200],
                    child: Container(
                      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: searchBar(state),
                    ),
                  ),
                ),

                // CircularProgressIndicator
                loading
                    ? Positioned(
                        top: 56,
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
