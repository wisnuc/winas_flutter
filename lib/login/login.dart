import 'package:flutter/material.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:flutter_redux/flutter_redux.dart';
import '../common/showSnackBar.dart';
import './registry.dart';
import './accountLogin.dart';
import '../redux/redux.dart';
import '../common/loading.dart';
import '../common/request.dart';
import '../icons/winas_icons.dart';
import '../common/stationApis.dart';
import '../transfer/manager.dart';

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

  accoutLogin(context, store) async {
    // show loading, need `Navigator.pop(context)` to dismiss

    var token = tokenRes['token'];
    var userUUID = tokenRes['id'];
    assert(token != null);
    assert(userUUID != null);

    // update Account
    store.dispatch(LoginAction(Account.fromMap(tokenRes)));

    var stationsRes = await request.req('stations', null);

    var stationLists = stationsRes.data['ownStations'];
    final currentDevice = stationLists.firstWhere(
        (s) =>
            s['online'] == 1 &&
            s['sn'] == 'test_b44-a529-4dcf-aa30-240a151d8e03',
        orElse: () => null);
    assert(currentDevice != null);

    var deviceSN = currentDevice['sn'];
    var lanIp = currentDevice['LANIP'];
    var deviceName = currentDevice['name'];

    List results = await Future.wait([
      request.req('localBoot', {'deviceSN': deviceSN}),
      request.req('localUsers', {'deviceSN': deviceSN}),
      request.req('localToken', {'deviceSN': deviceSN}),
      request.req('localDrives', {'deviceSN': deviceSN})
    ]);

    var lanToken = results[2].data['token'];

    assert(lanToken != null);

    // update StatinData
    store.dispatch(
      DeviceLoginAction(
        Device(
          deviceSN: deviceSN,
          deviceName: deviceName,
          lanIp: lanIp,
          lanToken: lanToken,
        ),
      ),
    );
    assert(results[1].data is List);

    // get current user data
    var user = results[1].data.firstWhere(
          (s) => s['winasUserId'] == userUUID,
          orElse: () => null,
        );
    store.dispatch(
      UpdateUserAction(
        User.fromMap(user),
      ),
    );

    // get current drives data
    List<Drive> drives = List.from(
      results[3].data.map((drive) => Drive.fromMap(drive)),
    );

    store.dispatch(
      UpdateDrivesAction(drives),
    );

    // station apis
    bool isCloud = false;
    String cookie = 'blabla';
    Apis apis =
        Apis(token, lanIp, lanToken, userUUID, isCloud, deviceSN, cookie);

    store.dispatch(
      UpdateApisAction(apis),
    );

    if (user['uuid'] != null) {
      // init TransferManager, load TransferItem
      TransferManager.init(user['uuid']).catchError(print);
    }

    // pop all page
    Navigator.pushNamedAndRemoveUntil(
        context, '/station', (Route<dynamic> route) => false);
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
            converter: (store) =>
                (BuildContext ctx) => accoutLogin(ctx, store).catchError((err) {
                      Navigator.pop(ctx);
                      showSnackBar(ctx, '登录失败');
                    }),
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
                                      style: TextStyle(
                                          color: pColor, fontSize: 16),
                                    ),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(28.0)),
                                    onPressed: () async {
                                      showLoading(context);
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
                                          request
                                              .req('wechatLogin', args)
                                              .then((res) {
                                            print(res);
                                            if (res.data['wechat'] != null &&
                                                res.data['user'] == false) {
                                              // wechat not bind
                                              Navigator.pop(
                                                  ctx); // close loading

                                              // nav to registry
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      Registry(
                                                          wechat: res
                                                              .data['wechat']),
                                                ),
                                              );
                                            } else if (res.data['user'] ==
                                                    true &&
                                                res.data['token'] != null) {
                                              // wechat bound
                                              tokenRes = res.data;
                                              callback(ctx);
                                            }
                                          }).catchError(print);
                                        } else {
                                          print('failed !!!');
                                          print(data);

                                          // close loading
                                          Navigator.pop(ctx);
                                        }
                                      });
                                    })),
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
