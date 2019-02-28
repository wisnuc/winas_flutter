import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../icons/winas_icons.dart';
import '../common/showSnackBar.dart';
import '../common/loading.dart';

final pColor = Colors.teal;

class WeChat extends StatefulWidget {
  WeChat({Key key}) : super(key: key);
  @override
  _WeChatState createState() => _WeChatState();
}

class _WeChatState extends State<WeChat> {
  String code;
  bool _loading = true;
  var wechatInfo;
  bool isWeChatInstalled = false;

  StreamSubscription<fluwx.WeChatAuthResponse> _wxlogin;

  _initFluwx() async {
    await fluwx.register(
      appId: "wxb137485b7b2ce4f0",
      doOnAndroid: true,
      doOnIOS: true,
      enableMTA: false,
    );
    isWeChatInstalled = await fluwx.isWeChatInstalled();
    if (this.mounted) {
      setState(() {});
    }
  }

  _refresh(AppState state) async {
    final res = await state.cloud.req('wechat', null);
    wechatInfo = res.data;
    if (this.mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  _bindWeChat(BuildContext ctx, AppState state) async {
    // remove previous listener
    _wxlogin?.cancel();

    if (isWeChatInstalled != true) {
      showSnackBar(ctx, '未检测到微信应用，请先安装微信');
      return;
    }

    await fluwx.sendAuth(
      openId: "wx99b54eb728323fe8",
      scope: "snsapi_userinfo",
      state: "winas_login",
    );

    _wxlogin = fluwx.responseFromAuth.listen((data) {
      print('responseFromAuth>>>>');
      print(data);
      print('<<<<<');
      code = data?.code;
      if (code != null) {
        final args = {
          'clientId': 'flutter_Test',
          'code': code,
        };

        state.cloud.req('wechatLogin', args).then((res) {
          if (res.data['wechat'] != null && res.data['user'] == false) {
            // bind to wechat
            state.cloud.req('bindWechat', {
              'wechatToken': res.data['wechat'],
            }).then((data) {
              showSnackBar(ctx, '绑定成功');
              if (this.mounted) {
                this.setState(() {
                  _loading = true;
                });
              }
              _refresh(state);
            });
          } else if (res.data['user'] == true && res.data['token'] != null) {
            // wechat has bind to other account
            showSnackBar(ctx, '该微信已绑定其它账户');
          } else {
            print(res);
            throw Error();
          }
        }).catchError((err) {
          print(err);
          showSnackBar(ctx, '绑定微信失败');
        });
      } else {
        print(data);
        showSnackBar(ctx, '绑定微信失败');
      }
    });
  }

  _unbindWeChat(BuildContext ctx, AppState state) async {
    // remove previous listener
    _wxlogin?.cancel();
    showLoading(ctx);
    try {
      await state.cloud.req('unbindWechat', {
        'unionid': wechatInfo[0]['unionid'],
      });
      await _refresh(state);
      Navigator.pop(ctx);
      showSnackBar(ctx, '解绑成功');
    } catch (error) {
      print(error);

      if (this.mounted) {
        setState(() {
          _loading = false;
        });
      }
      Navigator.pop(ctx);
      showSnackBar(ctx, '操作失败');
    }
  }

  @override
  void initState() {
    super.initState();
    _initFluwx().catchError(print);
  }

  @override
  void dispose() {
    // remove listener
    _wxlogin?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasWeChat = wechatInfo is List && wechatInfo.length > 0;
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        backgroundColor: Colors.white10,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black38),
      ),
      body: StoreConnector<AppState, AppState>(
        onInit: (store) => _refresh(store.state),
        onDispose: (store) => {},
        converter: (store) => store.state,
        builder: (ctx, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  '绑定微信',
                  style: TextStyle(color: Colors.black87, fontSize: 21),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Text(
                  '绑定微信，便捷登录',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  _loading
                      ? ''
                      : hasWeChat
                          ? '您已绑定微信：${wechatInfo[0]['nickname']}'
                          : '您尚未绑定微信',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              _loading
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container(
                      height: 88,
                      padding: EdgeInsets.all(16),
                      width: double.infinity,
                      child: RaisedButton(
                        color: pColor,
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(48),
                        ),
                        onPressed: () => hasWeChat
                            ? _unbindWeChat(ctx, state)
                            : _bindWeChat(ctx, state),
                        child: Row(
                          children: <Widget>[
                            Icon(Winas.wechat, color: Colors.white),
                            Expanded(child: Container()),
                            Text(
                              hasWeChat ? '解除微信绑定' : '立即绑定微信',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Expanded(child: Container()),
                            Container(width: 24),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
