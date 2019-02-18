import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import './fileRow.dart';
import './newFolder.dart';
import '../redux/redux.dart';
import '../common/loading.dart';
import '../common/renderIcon.dart';

class XCopyView extends StatefulWidget {
  XCopyView(
      {Key key,
      this.node,
      this.src,
      this.actionType,
      this.preCtx,
      this.callback})
      : super(key: key);
  final Node node;
  final List<Entry> src;
  final Function callback;

  /// [ctx for snackbar, ctx for navigation]
  final List<BuildContext> preCtx;
  final String actionType;
  @override
  _XCopyViewState createState() =>
      _XCopyViewState(node, src, actionType, preCtx, callback);
}

class _XCopyViewState extends State<XCopyView> {
  final Node node;
  final List<Entry> src;
  final Function callback;

  /// [ctx for snackbar, ctx for navigation]
  final List<BuildContext> preCtx;
  final String actionType;
  Error _error;
  bool loading = true;
  List<Entry> entries = [];
  List<Entry> dirs = [];
  List<Entry> files = [];
  ScrollController myScrollController = ScrollController();
  _XCopyViewState(
      this.node, this.src, this.actionType, this.preCtx, this.callback);

  Future _refresh(AppState state) async {
    if (node.tag == 'root') {
      // show root: public and home
      Drive publicDrive = state.drives
          .firstWhere((drive) => drive.tag == 'built-in', orElse: () => null);
      Drive homeDrive = state.drives
          .firstWhere((drive) => drive.tag == 'home', orElse: () => null);
      entries = [
        Entry(
            name: '我的空间',
            uuid: homeDrive.uuid,
            type: 'home',
            pdir: homeDrive.uuid,
            pdrv: homeDrive.uuid),
        Entry(
            name: '共享空间',
            uuid: publicDrive.uuid,
            type: 'public',
            pdir: publicDrive.uuid,
            pdrv: publicDrive.uuid),
      ];
      dirs = List.from(entries);
      loading = false;
      await Future(() => setState(() {}));
    } else if (node.tag == 'dir') {
      // show dir
      String driveUUID = node.driveUUID;
      String dirUUID = node.dirUUID;

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
      // mix currentNode's dirUUID, driveUUID
      List<Entry> rawEntries = List.from(
          listNav.data['entries'].map((entry) => Entry.mixNode(entry, node)));

      // sort by type
      rawEntries.sort((a, b) => a.type.compareTo(b.type));

      List<Entry> newEntries = [];
      List<Entry> newDirs = [];
      List<Entry> newFiles = [];

      if (rawEntries.length == 0) {
        print('empty entries or some error');
      } else if (rawEntries[0]?.type == 'directory') {
        int index = rawEntries.indexWhere((entry) => entry.type == 'file');
        if (index > -1) {
          newDirs = List.from(rawEntries.take(index));

          // filter entry.hash
          newFiles = List.from(
              rawEntries.skip(index).where((entry) => entry.hash != null));
        } else {
          newDirs = rawEntries;
        }
      } else if (rawEntries[0]?.type == 'file') {
        // filter entry.hash
        newFiles = List.from(rawEntries.where((entry) => entry.hash != null));
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
          loading = false;
          _error = null;
        });
      }
      return null;
    }
  }

  bool shouldFire() {
    // root dir
    if (node.tag == 'root') return false;

    // same dir
    for (Entry entry in src) {
      if (entry.pdir == node.dirUUID) return false;
    }
    return true;
  }

  openDir(BuildContext ctx, Entry entry) {
    if (src.any((e) => e.uuid == entry.uuid)) {
      showSnackBar(ctx, '不能选择被操作的文件夹');
    } else if (entry.type != 'file') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return XCopyView(
              node: Node(
                name: entry.name,
                driveUUID: entry.pdrv,
                dirUUID: entry.uuid,
                tag: 'dir',
              ),
              src: src,
              preCtx: preCtx,
              actionType: actionType,
              callback: callback,
            );
          },
        ),
      );
    }
  }

  close(BuildContext ctx) {
    // pop deep xcopy page
    Navigator.popUntil(ctx, ModalRoute.withName('xcopy'));
    // pop root page
    Navigator.pop(preCtx[1]);
  }

  Future fire(BuildContext ctx, AppState state) async {
    var args = {
      'batch': true,
      'type': actionType,
      'entries': src
          .map((e) => ({'name': e.name, 'drive': e.pdrv, 'dir': e.pdir}))
          .toList(),
      'policies': {
        'dir': ['rename', 'rename'],
        'file': ['rename', 'rename'],
      },
      'dst': {'drive': node.driveUUID, 'dir': node.dirUUID},
    };
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
    try {
      await state.apis.req('xcopy', args);
      showSnackBar(preCtx[0], actionType == 'copy' ? '复制成功' : '移动成功');
    } catch (error) {
      showSnackBar(preCtx[0], actionType == 'copy' ? '复制失败' : '移动失败');
    }
    // pop deep xcopy page
    Navigator.popUntil(ctx, ModalRoute.withName('xcopy'));
    // pop root page
    Navigator.pop(preCtx[1]);
    callback();
  }

  Widget renderRows(List<Entry> list) {
    return SliverFixedExtentList(
      itemExtent: 56,
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          Entry entry = list[index];
          return Material(
            child: InkWell(
              onTap: () => openDir(context, entry),
              child: Opacity(
                opacity: entry.type == 'file' ? 0.3 : 1,
                child: Row(
                  children: <Widget>[
                    Container(width: 12),
                    Container(
                      height: 56,
                      width: 56,
                      child: entry.type == 'file'
                          ? renderIcon(entry.name, entry.metadata)
                          : Icon(Icons.folder, color: Colors.orange),
                    ),
                    Container(width: 20),
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 56,
                        padding: EdgeInsets.only(top: 20, right: 8),
                        child: Text(
                          entry.name,
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: Colors.black12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: list.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _refresh(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              node.name,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
            backgroundColor: Colors.white,
            brightness: Brightness.light,
            elevation: 2.0,
            iconTheme: IconThemeData(color: Colors.black38),
            actions: <Widget>[
              Builder(builder: (ctx) {
                return IconButton(
                  icon: Icon(Icons.create_new_folder),
                  disabledColor: Colors.black12,
                  onPressed: node.tag == 'root'
                      ? null
                      : () {
                          showDialog(
                            context: this.context,
                            builder: (BuildContext context) =>
                                NewFolder(node: node),
                          ).then((success) =>
                              success == true ? _refresh(state) : null);
                        },
                );
              }),
            ],
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: () => _refresh(state),
                  child: _error != null
                      ? Center(
                          child: Text('出错啦！'),
                        )
                      : entries.length == 0
                          ? Center(
                              child: Text('空文件夹'),
                            )
                          : Container(
                              padding: node.tag == 'root'
                                  ? EdgeInsets.all(16)
                                  : EdgeInsets.all(0),
                              color: Colors.grey[200],
                              child: DraggableScrollbar.semicircle(
                                controller: myScrollController,
                                child: node.tag == 'root'
                                    ? GridView.builder(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisSpacing: 16.0,
                                          mainAxisSpacing: 16.0,
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.0,
                                        ),
                                        itemCount: entries.length,
                                        itemBuilder: (context, index) {
                                          Entry entry = entries[index];
                                          return Material(
                                            child: InkWell(
                                              onTap: () =>
                                                  openDir(context, entry),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: Icon(
                                                      entry.type == 'public'
                                                          ? Icons.folder_shared
                                                          : Icons.folder,
                                                      size: 72,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 48,
                                                    child: Center(
                                                      child: Text(entry.name),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : CustomScrollView(
                                        key: Key(entries.length.toString()),
                                        controller: myScrollController,
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        slivers: <Widget>[
                                          // dir title
                                          SliverFixedExtentList(
                                            itemExtent: 48,
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (BuildContext context,
                                                  int index) {
                                                return TitleRow(
                                                    isFirst: false,
                                                    type: 'directory');
                                              },
                                              childCount:
                                                  dirs.length > 0 ? 1 : 0,
                                            ),
                                          ),
                                          // dir Grid or Row view

                                          renderRows(dirs),
                                          // file title
                                          SliverFixedExtentList(
                                            itemExtent: 48,
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (BuildContext context,
                                                  int index) {
                                                return TitleRow(
                                                    isFirst: false,
                                                    type: 'file');
                                              },
                                              childCount:
                                                  files.length > 0 ? 1 : 0,
                                            ),
                                          ),
                                          // file Grid or Row view

                                          renderRows(files),
                                          SliverFixedExtentList(
                                            itemExtent: 24,
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (context, index) => Container(),
                                              childCount: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                ),
          bottomNavigationBar: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                    textColor: Colors.teal,
                    child: Text('取消'),
                    onPressed: () => close(ctx)),
                Builder(builder: (scaffoldCtx) {
                  return FlatButton(
                    disabledTextColor: Colors.black12,
                    textColor: Colors.teal,
                    child: actionType == 'copy'
                        ? Text('复制到此文件夹')
                        : Text('移动到此文件夹'),
                    onPressed:
                        shouldFire() ? () => fire(scaffoldCtx, state) : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
