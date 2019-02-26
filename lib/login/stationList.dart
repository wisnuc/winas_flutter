import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import './stationLogin.dart';
import '../common/loading.dart';
import '../common/request.dart';
import '../icons/winas_icons.dart';
import '../common/showSnackBar.dart';

final pColor = Colors.teal;

class StationList extends StatefulWidget {
  StationList({Key key, this.stationList, this.request}) : super(key: key);

  /// Wechat token for binding
  final List<Station> stationList;
  final Request request;
  @override
  _StationListState createState() => _StationListState();
}

class _StationListState extends State<StationList> {
  ScrollController myScrollController = ScrollController();
  int selected = -1;
  List<Station> stationList;

  String stationStatus(Station s) {
    if (!s.isOnline) {
      return '设备离线';
    } else {
      return '在线';
    }
  }

  Future<void> login(BuildContext ctx, Station station, store) async {
    showLoading(ctx);
    try {
      await stationLogin(
          ctx, widget.request, station, store.state.account, store);
    } catch (error) {
      print(error);
      Navigator.pop(ctx);
      showSnackBar(ctx, '登录设备失败');
      return;
    }
    // pop all page
    Navigator.pushNamedAndRemoveUntil(
        context, '/station', (Route<dynamic> route) => false);
  }

  Future<void> refresh() async {
    try {
      final result = await reqStationList(widget.request);
      stationList = result['stationList'];
      setState(() {});
    } catch (error) {
      print(error);
      stationList = null;
    }
  }

  @override
  void initState() {
    super.initState();
    stationList = widget.stationList;
  }

  renderPadding(double height) {
    return SliverFixedExtentList(
      itemExtent: 16,
      delegate: SliverChildBuilderDelegate(
        (context, index) => Container(height: height),
        childCount: 1,
      ),
    );
  }

  Widget renderNoDevice() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '您还没有闻上云盘',
            style: TextStyle(fontSize: 21),
          ),
          Container(height: 56),
          Container(
            height: 56,
            width: double.infinity,
            child: RaisedButton(
              color: pColor,
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
              onPressed: () {},
              child: Row(
                children: <Widget>[
                  Icon(Icons.add, color: Colors.white),
                  Expanded(child: Container()),
                  Text(
                    '添加新设备',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Expanded(child: Container()),
                  Container(width: 24),
                ],
              ),
            ),
          ),
          Container(height: 24),
          Container(
            height: 56,
            width: double.infinity,
            child: RaisedButton(
              color: Colors.white,
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
              onPressed: () {},
              child: Row(
                children: <Widget>[
                  Icon(Icons.add, color: pColor),
                  Expanded(child: Container()),
                  Text(
                    '扫一扫，添加他人设备',
                    style: TextStyle(color: pColor, fontSize: 16),
                  ),
                  Expanded(child: Container()),
                  Container(width: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> renderFailed() {
    return <Widget>[
      renderPadding(32),
      SliverFixedExtentList(
        itemExtent: 256,
        delegate: SliverChildBuilderDelegate(
          (context, index) => Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(64),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 72,
                    ),
                  ),
                  Text(
                    '加载设备列表失败，请下拉重试',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
          childCount: 1,
        ),
      ),
      renderPadding(32),
    ];
  }

  List<Widget> renderList(BuildContext ctx, Function callback) {
    List<Station> list = List.from(stationList);
    list.sort((a, b) => a.online - b.online);
    return <Widget>[
      SliverFixedExtentList(
        itemExtent: 80,
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  '未能自动登录上次使用的设备，您可以重试或者选择其他设备。',
                  style: TextStyle(fontSize: 21),
                ),
              ),
          childCount: 1,
        ),
      ),
      renderPadding(16),

      // station list
      SliverFixedExtentList(
        itemExtent: 64,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            Station station = list[index];
            bool isSelected = selected == index;
            bool isLast = index == list.length - 1;
            return Material(
              child: InkWell(
                onTap: station.isOnline
                    ? () {
                        setState(() {
                          selected = isSelected ? -1 : index;
                        });
                      }
                    : null,
                child: Opacity(
                  opacity: station.isOnline ? 1 : 0.5,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: isLast
                              ? BorderSide.none
                              : BorderSide(color: Colors.black12),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 32,
                            color: isSelected ? pColor : Colors.black38,
                          ),
                          Container(width: 32),
                          Text(
                            station.name,
                            style: TextStyle(fontSize: 21),
                          ),
                          Expanded(flex: 1, child: Container()),
                          Text(
                            stationStatus(station),
                            style: TextStyle(color: Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: list.length,
        ),
      ),
      renderPadding(16),

      // action button
      SliverFixedExtentList(
        itemExtent: 96,
        delegate: SliverChildBuilderDelegate(
          (context, index) => Container(
                height: 96,
                padding: EdgeInsets.all(16),
                child: RaisedButton(
                  color: pColor,
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48)),
                  onPressed: selected == -1
                      ? null
                      : () => callback(ctx, list[selected]),
                  child: Text(
                    '登录设备',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          childCount: 1,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Function>(
      converter: (store) =>
          (BuildContext ctx, Station s) => login(ctx, s, store),
      builder: (ctx, callback) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            brightness: Brightness.light,
            backgroundColor: Colors.grey[50],
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Material(
              child: InkWell(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (Route<dynamic> route) => false);
                },
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    '注销',
                    style: TextStyle(color: pColor, fontSize: 14),
                  ),
                ),
              ),
            ),
            centerTitle: false,
            actions: stationList != null && stationList.length > 0
                ? <Widget>[
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.black38),
                      onPressed: () {
                        return;
                      },
                    )
                  ]
                : [],
          ),
          body: Builder(
            builder: (BuildContext c) =>
                stationList != null && stationList.length == 0
                    ? renderNoDevice()
                    : RefreshIndicator(
                        onRefresh: refresh,
                        child: CustomScrollView(
                          controller: myScrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          slivers: stationList == null
                              ? renderFailed()
                              : renderList(c, callback),
                        ),
                      ),
          ),
        );
      },
    );
  }
}
