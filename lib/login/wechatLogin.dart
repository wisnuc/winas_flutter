import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;

class SendAuthPage extends StatefulWidget {
  @override
  _SendAuthPageState createState() => _SendAuthPageState();
}

class _SendAuthPageState extends State<SendAuthPage> {
  String _result = "无";

  @override
  void initState() {
    super.initState();
    _initFluwx().then((data) {});
    fluwx.responseFromAuth.listen((data) {
      setState(() {
        _result = "${data.errCode}";
      });
      print(122221212);
    });
  }

  _initFluwx() async {
    await fluwx.register(
        appId: "wx99b54eb728323fe8",
        doOnAndroid: true,
        doOnIOS: true,
        enableMTA: false);
    var result = await fluwx.isWeChatInstalled();
    print("is installed $result");
  }

  @override
  void dispose() {
    super.dispose();
    _result = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Auth"),
      ),
      body: Column(
        children: <Widget>[
          OutlineButton(
            onPressed: () {
              fluwx
                  .sendAuth(
                      scope: "snsapi_userinfo", state: "wechat_sdk_demo_test")
                  .then((data) {});
            },
            child: const Text("send auth"),
          ),
          const Text("响应结果;"),
          Text(_result)
        ],
      ),
    );
  }
}
