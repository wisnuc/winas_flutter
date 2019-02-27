import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import './license.dart';
import '../icons/winas_icons.dart';

class About extends StatefulWidget {
  About({Key key}) : super(key: key);
  @override
  _AboutState createState() => _AboutState();
}

class _AboutState extends State<About> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        backgroundColor: Colors.white10,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black38),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('关于闻上云盘',
                style: TextStyle(color: Colors.black87, fontSize: 21)),
            Container(height: 48),
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(Winas.logo, color: Colors.grey[50], size: 84),
            ),
            Container(height: 16),
            Text(
              '多设备，跨平台，让您随时随地，\n方便快捷地管理您的数据',
              style: TextStyle(color: Colors.black54),
            ),
            Material(
              child: InkWell(
                onTap: () async {
                  bool isIOS = !Platform.isAndroid;
                  String url = isIOS
                      ? 'https://itunes.apple.com/cn/app/wisnuc/id1132191394?mt=8'
                      : 'http://www.wisnuc.com/download';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    print('Could not launch $url');
                  }
                },
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.grey[300]),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text('升级'),
                      Expanded(child: Container()),
                      Text(
                        '查看最新版本',
                        style: TextStyle(color: Colors.black54),
                      ),
                      Icon(Icons.chevron_right, color: Colors.black38)
                    ],
                  ),
                ),
              ),
            ),
            Container(height: 16),
            FlatButton(
              padding: EdgeInsets.all(0),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) {
                        return Scaffold(
                          appBar: AppBar(
                            title: Text('用户使用许可协议'),
                            elevation: 1.0,
                          ),
                          body: ListView(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.fromLTRB(8, 32, 8, 8),
                                child: Text(
                                  '闻上盒子系列产品 用户使用许可协议',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  license,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ));
              },
              child: Text(
                '用户使用协议',
                style: TextStyle(color: Colors.teal),
              ),
            )
          ],
        ),
      ),
    );
  }
}
