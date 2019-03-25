import 'package:flutter/material.dart';

import './info.dart';
import '../common/utils.dart';
import '../icons/winas_icons.dart';
import '../common/appBarSlivers.dart';

class Firmware extends StatefulWidget {
  Firmware({Key key}) : super(key: key);
  @override
  _FirmwareState createState() => _FirmwareState();
}

class _FirmwareState extends State<Firmware> {
  Info info;
  bool failed = false;
  bool loading = false;
  bool lastest = true;
  ScrollController myScrollController = ScrollController();

  /// left padding of appbar
  double paddingLeft = 16;

  /// scrollController's listener to get offset
  void listener() {
    setState(() {
      paddingLeft = (myScrollController.offset * 1.25).clamp(16.0, 72.0);
    });
  }

  @override
  void initState() {
    myScrollController.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    myScrollController.removeListener(listener);
    super.dispose();
  }

  Widget renderText(String text) {
    return SliverToBoxAdapter(
      child: Container(
        height: 256,
        child: Center(
          child: Text(text),
        ),
      ),
    );
  }

  List<Widget> getSlivers() {
    final String titleName = '软件更新';
    // title
    List<Widget> slivers = appBarSlivers(paddingLeft, titleName);
    if (loading) {
      // loading
      slivers.add(SliverToBoxAdapter(child: Container(height: 16)));
    } else if (!lastest) {
      // lastest
      slivers.add(renderText('您的软件是最新版本。'));
    } else if (info != null || failed) {
      // failed
      slivers.add(renderText('获取软件版本信息失败'));
    } else {
      // actions
      slivers.addAll([
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Icon(Winas.logo, color: Colors.grey[50], size: 84),
                ),
                Container(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Winas 1.2.1',
                      style: TextStyle(fontSize: 18),
                    ),
                    Container(height: 4),
                    Text('Wisnuc Inc.'),
                    Container(height: 4),
                    Text('2019-03-05'),
                  ],
                )
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(16),
                child: Text(
                  'Winas 1.2.1 更新多个新功能， 提高了设备性能与稳定性，建议所有用户安装。',
                ),
              )
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Builder(builder: (BuildContext ctx) {
                return FlatButton(
                  onPressed: () async {
                    final model = Model();
                    showNormalDialog(
                      context: context,
                      text: '正在安装更新',
                      model: model,
                    );
                    await Future.delayed(Duration(seconds: 3));
                    model.close = true;
                    Navigator.pop(context);
                    // Navigator.pop(ctx);
                  },
                  child: Text(
                    '立即安装更新',
                    style: TextStyle(color: Colors.teal),
                  ),
                );
              }),
            ],
          ),
        ),
      ]);
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: myScrollController,
        slivers: getSlivers(),
      ),
    );
  }
}
