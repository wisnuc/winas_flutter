import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import './fileRow.dart';
import './delete.dart';
import './xcopyDialog.dart';
import '../redux/redux.dart';
import '../common/renderIcon.dart';

class Search extends StatefulWidget {
  Search({Key key, this.node, this.actions, this.download}) : super(key: key);
  final Node node;
  final actions;
  final download;
  @override
  _SearchState createState() => _SearchState(node, actions, download);
}

class _SearchState extends State<Search> {
  String _types;
  final Node node;
  final actions;
  final download;
  String _searchText;
  bool loading = false;
  List<Entry> _entries;
  ScrollController myScrollController = ScrollController();
  Select select;
  _SearchState(this.node, this.actions, this.download);

  _onSearch(AppState state) async {
    FocusScope.of(this.context).requestFocus(FocusNode());
    print('onSearch $_types $_searchText');
    if (_types == null && _searchText == null) return;
    setState(() {
      loading = true;
    });
    List<String> driveUUIDs = List.from(state.drives.map((d) => d.uuid));
    String places = driveUUIDs.join('.');

    var args = {
      'places': places,
      'order': 'find',
    };

    if (_searchText != null) {
      args.addAll({
        'name': _searchText,
      });
    }

    if (_types != null) {
      args.addAll({
        'types': _types,
        'order': 'newest',
      });
    }
    try {
      var res = await state.apis.req('search', args);
      assert(res != null && res.data != null);
      print('search results\' length: ${res.data.length}');
      _entries =
          List.from(res.data.map((d) => Entry.fromSearch(d, driveUUIDs)));
    } catch (error) {
      print(error);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// [title, icon, types]
  List<List> fileTypes = [
    [
      'PDFs',
      renderIcon('a.pdf', null),
      'PDF',
    ],
    [
      'Word',
      renderIcon('a.docx', null),
      'DOCX.DOC',
    ],
    [
      'Excel',
      renderIcon('a.xlsx', null),
      'XLSX.XLS',
    ],
    [
      'PPT',
      renderIcon('a.ppt', null),
      'PPTX.PPT',
    ],
    [
      '照片与图片',
      renderIcon('a.bmp', null),
      'JPEG.PNG.JPG.GIF.BMP.RAW',
    ],
    [
      '视频',
      renderIcon('a.mkv', null),
      'RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV',
    ],
    [
      '音频',
      renderIcon('a.mp3', null),
      'WAV.MP3.APE.WMA.FLAC',
    ],
  ];
  @override
  void initState() {
    super.initState();

    // init Select
    select = Select(() => this.setState(() {}));
  }

  AppBar searchAppBar(AppState state) {
    return AppBar(
      elevation: 2.0, // no shadow
      backgroundColor: Colors.white,
      brightness: Brightness.light,
      iconTheme: IconThemeData(color: Colors.black38),
      title: TextField(
        // autofocus: true,
        onChanged: (text) {
          _searchText = text;
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '搜索文件',
        ),
        style: TextStyle(color: Colors.black87),
        textInputAction: TextInputAction.search,
        onEditingComplete: () => _onSearch(state),
      ),
    );
  }

  AppBar selectAppBar(AppState state) {
    return AppBar(
      title: Text(
        '选择了${select.selectedEntry.length}项',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.close, color: Colors.white),
        onPressed: () => select.clearSelect(),
      ),
      brightness: Brightness.light,
      elevation: 2.0,
      iconTheme: IconThemeData(color: Colors.white),
      actions: <Widget>[
        // copy selected entry
        Builder(builder: (ctx) {
          return IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: () {
              Navigator.push(
                this.context,
                MaterialPageRoute(
                  settings: RouteSettings(name: 'xcopy'),
                  fullscreenDialog: true,
                  builder: (xcopyCtx) {
                    return XCopyView(
                        node: Node(
                          name: '全部文件',
                          tag: 'root',
                        ),
                        src: select.selectedEntry,
                        preCtx: [ctx, xcopyCtx], // for snackbar and navigation
                        actionType: 'copy',
                        callback: () {
                          select.clearSelect();
                          _onSearch(state);
                        });
                  },
                ),
              );
            },
          );
        }),
        // move selected entry
        Builder(builder: (ctx) {
          return IconButton(
            icon: Icon(Icons.forward),
            onPressed: () {
              Navigator.push(
                this.context,
                MaterialPageRoute(
                  settings: RouteSettings(name: 'xcopy'),
                  fullscreenDialog: true,
                  builder: (xcopyCtx) {
                    return XCopyView(
                        node: Node(
                          name: '全部文件',
                          tag: 'root',
                        ),
                        src: select.selectedEntry,
                        preCtx: [ctx, xcopyCtx], // for snackbar and navigation
                        actionType: 'move',
                        callback: () {
                          select.clearSelect();
                          _onSearch(state);
                        });
                  },
                ),
              );
            },
          );
        }),
        // delete selected entry
        Builder(builder: (ctx) {
          return IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              bool success = await showDialog(
                context: this.context,
                builder: (BuildContext context) =>
                    DeleteDialog(entries: select.selectedEntry),
              );
              select.clearSelect();

              if (success == true) {
                showSnackBar(ctx, '删除成功');
              } else if (success == false) {
                showSnackBar(ctx, '删除失败');
              }
              await _onSearch(state);
            },
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Scaffold(
          appBar:
              select.selectMode() ? selectAppBar(state) : searchAppBar(state),
          body: Container(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : _entries != null
                    ? Container(
                        color: Colors.grey[200],
                        child: DraggableScrollbar.semicircle(
                          controller: myScrollController,
                          child: CustomScrollView(
                            controller: myScrollController,
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: <Widget>[
                              // images, GridView
                              _types != fileTypes[4][2]
                                  ? SliverFixedExtentList(
                                      itemExtent: 64,
                                      delegate: SliverChildBuilderDelegate(
                                        (BuildContext ctx, int index) {
                                          final entry = _entries[index];
                                          return FileRow(
                                            entry: entry,
                                            type: 'file',
                                            actions: actions,
                                            onPress: () =>
                                                download(ctx, entry, state),
                                            isGrid: false,
                                            select: select,
                                          );
                                        },
                                        childCount: _entries.length,
                                      ),
                                    )
                                  : SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 8.0,
                                        crossAxisSpacing: 8.0,
                                        childAspectRatio: 1.0,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (BuildContext ctx, int index) {
                                          final entry = _entries[index];
                                          return FileRow(
                                            entry: entry,
                                            type: 'file',
                                            actions: actions,
                                            onPress: () =>
                                                download(ctx, entry, state),
                                            isGrid: true,
                                            select: select,
                                          );
                                        },
                                        childCount: _entries.length,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      )
                    : Column(children: [
                        Container(
                          height: 56,
                          child: Row(
                            children: <Widget>[
                              Container(width: 16),
                              Text('文件类型'),
                            ],
                          ),
                        ),
                        Column(
                          children: fileTypes
                              .map((a) => InkWell(
                                    onTap: () {
                                      _types = a[2];
                                      _onSearch(state);
                                    },
                                    child: Container(
                                      height: 56,
                                      child: Row(
                                        children: <Widget>[
                                          Container(width: 16),
                                          a[1],
                                          Container(width: 32),
                                          Text(a[0]),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        )
                      ]),
          ),
        );
      },
    );
  }
}
