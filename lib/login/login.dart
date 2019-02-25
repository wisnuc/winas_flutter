import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:flutter_redux/flutter_redux.dart';

import './registry.dart';
import './stationLogin.dart';
import './accountLogin.dart';
import '../redux/redux.dart';
import '../common/loading.dart';
import '../common/request.dart';
import '../icons/winas_icons.dart';
import '../common/showSnackBar.dart';

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
    _initFluwx().then((data) {});
  }

  _initFluwx() async {
    await fluwx.register(
      appId: "wx99b54eb728323fe8",
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
    showLoading(ctx);
    await fluwx.sendAuth(
      openId: "wx99b54eb728323fe8",
      scope: "snsapi_userinfo",
      state: "winas_login",
    );

    fluwx.responseFromAuth.listen((data) {
      code = data?.code;
      if (code != null) {
        print(code);
        final args = {
          'clientId': 'flutter_Test',
          'code': code,
        };
        tokenRes = null;
        request.req('wechatLogin', args).then((res) {
          print(res);
          if (res.data['wechat'] != null && res.data['user'] == false) {
            // wechat not bind
            Navigator.pop(ctx); // close loading

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
          }
        }).catchError(print);
      } else {
        print(data);
        // close loading
        Navigator.pop(ctx);
        showSnackBar(ctx, '微信登录失败');
      }
    });
  }

  @override
  void dispose() {
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
              return Center(
                child: Container(
                  constraints: BoxConstraints.expand(),
                  padding: EdgeInsets.all(16),
                  color: Colors.teal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        child: Text('欢迎使用闻上云盘',
                            style:
                                TextStyle(fontSize: 28.0, color: Colors.white),
                            textAlign: TextAlign.left),
                        width: double.infinity,
                      ),
                      Container(height: 48.0),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FlatButton(
                                color: Colors.white,
                                child: Text(
                                  "使用微信登录注册",
                                  style: TextStyle(color: pColor, fontSize: 16),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28.0),
                                ),
                                onPressed: () => wechatAuth(ctx, callback),
                              ),
                            ),
                            Positioned(
                              child: Icon(Winas.wechat, color: pColor),
                              left: 24,
                              top: 16,
                            )
                          ],
                        ),
                      ),
                      Container(height: 16.0),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Material(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Registry(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pColor,
                                  borderRadius: BorderRadius.circular(28),
                                  border:
                                      Border.all(width: 3, color: Colors.white),
                                ),
                                child: Center(
                                  child: Text(
                                    "创建账号",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
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
                ),
              );
            }));
  }
}
