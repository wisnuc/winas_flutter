import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:flutter_redux/flutter_redux.dart';

import './registry.dart';
import './stationLogin.dart';
import './accountLogin.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import '../common/request.dart';
import '../icons/winas_icons.dart';

final pColor = Colors.teal;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isWeChatInstalled = false;
  var request = Request();
  String code;
  var tokenRes;

  @override
  void initState() {
    super.initState();
    _initFluwx().catchError(print);
  }

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

  accoutLogin(BuildContext context, store) async {
    // show loading, need `Navigator.pop(context)` to dismiss
    showLoading(context);

    // update Account
    Account account = Account.fromMap(tokenRes);
    store.dispatch(LoginAction(account));

    // device login
    await deviceLogin(context, request, account, store);
  }

  wechatAuth(BuildContext ctx, Function callback) async {
    // remove previous listener
    _wxlogin?.cancel();

    if (isWeChatInstalled != true) {
      showSnackBar(ctx, '未检测到微信应用，请先安装微信');
      return;
    }

    String clientId = await getClientId();

    await fluwx.sendAuth(
      openId: "wxb137485b7b2ce4f0",
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
          'clientId': clientId,
          'code': code,
        };
        tokenRes = null;
        request.req('wechatLogin', args).then((res) {
          if (res.data['wechat'] != null && res.data['user'] == false) {
            // nav to registry
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Registry(wechat: res.data['wechat']),
              ),
            );
          } else if (res.data['user'] == true && res.data['token'] != null) {
            // wechat bound
            tokenRes = res.data;
            callback(ctx);
          } else {
            print(res);
            throw Error();
          }
        }).catchError((err) {
          print(err);
          showSnackBar(ctx, '微信登录失败');
        });
      } else {
        print(data);
        showSnackBar(ctx, '微信登录失败');
      }
    });
  }

  @override
  void dispose() {
    // remove listener
    _wxlogin?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        actions: <Widget>[
          FlatButton(
            child: Text("登录"),
            textColor: Colors.white,
            onPressed: () {
              // Navigator to Login
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Login();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: StoreConnector<AppState, Function>(
        converter: (store) => (BuildContext ctx) => accoutLogin(ctx, store),
        builder: (ctx, callback) {
          return Container(
            constraints: BoxConstraints.expand(),
            padding: EdgeInsets.all(16),
            color: Colors.teal,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  child: Text('欢迎使用闻上云盘',
                      style: TextStyle(fontSize: 28.0, color: Colors.white),
                      textAlign: TextAlign.left),
                  width: double.infinity,
                ),
                Container(height: 48.0),
                Container(
                  height: 56,
                  width: double.infinity,
                  child: RaisedButton(
                    color: Colors.white,
                    elevation: 1.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(48),
                    ),
                    onPressed: () => wechatAuth(ctx, callback),
                    child: Row(
                      children: <Widget>[
                        Icon(Winas.wechat, color: pColor),
                        Expanded(child: Container()),
                        Text(
                          '使用微信登录注册',
                          style: TextStyle(color: pColor, fontSize: 16),
                        ),
                        Expanded(child: Container()),
                        Container(width: 24),
                      ],
                    ),
                  ),
                ),
                Container(height: 32.0),
                Container(
                  height: 56,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: RaisedButton(
                      color: pColor,
                      elevation: 1.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Registry(),
                          ),
                        );
                      },
                      child: Text(
                        '创建账号',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                Container(height: 32.0),
                Text('点击继续、创建账号即表明同意闻上云盘的产品使用协议隐私政策',
                    style: TextStyle(fontSize: 12.0, color: Colors.white),
                    textAlign: TextAlign.left),
                Container(height: 48.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
