import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import '../files/fileRow.dart';
import '../redux/redux.dart';
import '../common/format.dart';
import '../common/renderIcon.dart';
import '../common/cache.dart';

class Transfer extends StatefulWidget {
  Transfer({Key key}) : super(key: key);

  @override
  _TransferState createState() => _TransferState();
}

class _TransferState extends State<Transfer> {
  bool loading = false;
  ScrollController myScrollController = ScrollController();
  _TransferState();

  @override
  void initState() {
    super.initState();
  }

  /// refresh per second
  _autoRefresh() async {
    await Future.delayed(Duration(seconds: 1));
    if (this.mounted) {
      setState(() {});
      _autoRefresh();
    }
  }

  Widget renderStatus(TransferItem item) {
    switch (item.status) {
      case 'finished':
        return Center(child: Icon(Icons.check_circle_outline));
      case 'working':
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                value: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[50]),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                value: item.finishedSize / item.entry.size,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          ],
        );
      case 'paused':
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                value: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                value: item.finishedSize / item.entry.size,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(child: Icon(Icons.pause))),
          ],
        );
      case 'failed':
        return Center(child: Icon(Icons.error, color: Colors.pinkAccent));
    }
    return Container();
  }

  Widget renderRow(
      BuildContext ctx, List<TransferItem> items, int index, AppState state) {
    TransferItem item = items[index];
    Entry entry = item.entry;
    return Dismissible(
      key: Key(item.uuid),
      onDismissed: (direction) {
        item.clean();
        items.removeAt(index);
        showSnackBar(ctx, '删除成功');
      },
      background: Container(
          color: Colors.red,
          child: Row(
            children: <Widget>[
              Expanded(flex: 1, child: Container()),
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  '删除',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            ],
          )),
      child: Material(
        child: InkWell(
          onTap: () async {
            if (item.status == 'finished') {
              // open file
              await OpenFile.open(item.filePath);
            } else if (item.status == 'working') {
              // pause task
              item.pause();
            } else if (item.status == 'paused') {
              // resume task
              item.clean();
              items.removeAt(index);
              final cm = await CacheManager.getInstance();
              cm.newDownload(entry, state);
            } else if (item.status == 'failed') {
              // retry
              items.removeAt(index);
              final cm = await CacheManager.getInstance();
              cm.newDownload(entry, state);
            }
          },
          child: Row(
            children: <Widget>[
              Container(
                child: renderIcon(entry.name, entry.metadata, size: 24.0),
                padding: EdgeInsets.all(16),
              ),
              Container(width: 16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(flex: 1, child: Container()),
                            Text(
                              entry.name,
                              textAlign: TextAlign.start,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Container(height: 8),
                            Row(
                              children: <Widget>[
                                Icon(Icons.file_download),
                                Container(width: 8),
                                Text(
                                    item.status == 'finished'
                                        ? prettySize(item.finishedSize)
                                        : '${prettySize(item.finishedSize)} / ${prettySize(item.entry.size)}',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            Expanded(flex: 1, child: Container()),
                          ],
                        ),
                      ),
                      Expanded(flex: 1, child: Container()),
                      Text(
                        item.status == 'working'
                            ? item.speed
                            : item.status == 'paused' ? '已暂停' : '',
                        style: TextStyle(fontSize: 12),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        width: 72,
                        height: 72,
                        child: renderStatus(item),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _autoRefresh(),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        List<TransferItem> list = state.transferList;
        list.sort((a, b) {
          if (a.order == b.order) {
            return b.startTime - a.startTime;
          }
          return b.order - a.order;
        });

        return Scaffold(
          appBar: AppBar(
            elevation: 2.0, // no shadow
            backgroundColor: Colors.white,
            brightness: Brightness.light,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('传输任务', style: TextStyle(color: Colors.black87)),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.more_horiz),
                onPressed: () {
                  showModalBottomSheet(
                    context: ctx,
                    builder: (BuildContext c) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // start all
                          Material(
                            child: InkWell(
                              onTap: () async {
                                Navigator.pop(c);
                                List<Entry> resumeList = [];
                                for (int i = list.length - 1; i >= 0; i--) {
                                  TransferItem item = list[i];
                                  if (item.status == 'paused') {
                                    item.clean();
                                    list.removeAt(i);
                                    resumeList.add(item.entry);
                                  }
                                }
                                final cm = await CacheManager.getInstance();
                                for (Entry entry in resumeList) {
                                  cm.newDownload(entry, state);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                child: Text('全部开始'),
                              ),
                            ),
                          ),
                          // pause all
                          Material(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(c);
                                for (TransferItem item in list) {
                                  if (item.status == 'working') item.pause();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                child: Text('全部暂停'),
                              ),
                            ),
                          ),
                          // clear all
                          Material(
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(c);
                                for (TransferItem item in list) {
                                  item.clean();
                                }
                                list.clear();
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                child: Text('全部清除'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              )
            ],
          ),
          body: Container(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : Container(
                    color: Colors.grey[200],
                    child: DraggableScrollbar.semicircle(
                      controller: myScrollController,
                      child: CustomScrollView(
                        controller: myScrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: <Widget>[
                          SliverFixedExtentList(
                            itemExtent: 72,
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext ctx, int index) =>
                                  renderRow(ctx, list, index, state),
                              childCount: list.length,
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
