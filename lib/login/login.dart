import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../redux/redux.dart';
import '../common/request.dart';
import '../common/persistent.dart';
import '../common/loading.dart';
import '../common/stationApis.dart';

class LoginPage extends StatelessWidget {
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
              }),
        ],
      ),
      body: Center(
        child: Container(
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
              SizedBox(
                width: double.infinity,
                height: 40,
                child: Stack(
                  children: [
                    SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FlatButton(
                          color: Colors.white,
                          // icon: Icon(Icons.album, color: Colors.teal[700]),
                          child: Text(
                            "使用微信登录注册",
                            style: TextStyle(
                                color: Colors.teal[700], fontSize: 16),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          onPressed: () => {},
                        )),
                    Positioned(
                      child: Icon(Icons.album, color: Colors.teal[700]),
                      left: 16,
                      top: 8,
                    )
                  ],
                ),
              ),
              Container(height: 16.0),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlineButton(
                  color: Colors.teal[700],
                  child: Text(
                    "创建账号",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  onPressed: () => {},
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
      ),
    );
  }
}

class Login extends StatefulWidget {
  Login({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _status = 'account';

  // Focus action
  FocusNode myFocusNode;

  var request = Request();

  var persistent = Persistent();

  @override
  void initState() {
    super.initState();

    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed
    myFocusNode.dispose();

    super.dispose();
  }

  String _phoneNumber = '18817301665';

  String _password = '12345678';

  String _error;

  _currentTextField() {
    if (_status == 'account') {
      return TextField(
        key: Key('account'),
        onChanged: (text) {
          setState(() => _error = null);
          _phoneNumber = text;
        },
        controller: TextEditingController(text: _phoneNumber),
        autofocus: true,
        decoration: InputDecoration(
            labelText: "手机号",
            prefixIcon: Icon(Icons.person),
            errorText: _error),
        style: TextStyle(color: Colors.white, fontSize: 24),
        maxLength: 11,
        keyboardType: TextInputType.number,
      );
    }
    return TextField(
      key: Key('password'),
      onChanged: (text) {
        setState(() => _error = null);
        _password = text;
      },
      controller: TextEditingController(text: _password),
      focusNode: myFocusNode,
      decoration: InputDecoration(
          labelText: "密码", prefixIcon: Icon(Icons.lock), errorText: _error),
      style: TextStyle(color: Colors.white, fontSize: 24),
      obscureText: true,
    );
  }

  accoutLogin(context, store, args) async {
    // dismiss keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    // show loading, need `Navigator.pop(context)` to dismiss
    showLoading(
      barrierDismissible: false,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints.expand(),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      context: context,
    );

    var res = await request.req('token', args);
    var token = res.data['token'];
    var userUUID = res.data['id'];
    assert(token != null);
    assert(userUUID != null);

    // update Account
    store.dispatch(LoginAction(Account.fromMap(res.data)));

    await persistent.setString('token', token);
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
    return results;
  }

  void _nextStep(BuildContext context, store) {
    if (_status == 'account') {
      if (_phoneNumber.length != 11) {
        setState(() {
          _error = '请输入11位手机号';
        });
        return;
      }
      setState(() {
        _status = 'password';
      });
      var future = Future.delayed(const Duration(milliseconds: 100),
          () => FocusScope.of(context).requestFocus(myFocusNode));
      future.then((res) => print('100ms later'));
    } else {
      // login
      if (_password.length == 0) {
        return;
      }
      final args = {
        'clientId': 'flutter_Test',
        'username': _phoneNumber,
        'password': _password
      };
      // login to account and device
      accoutLogin(context, store, args).then((res) {
        // pop loading
        Navigator.pop(context);
        // pop login account page
        Navigator.pop(context);
        // replace first page
        Navigator.pushReplacementNamed(context, '/station');
      }).catchError((err) {
        // pop loading
        Navigator.pop(context);
        print(err);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        actions: <Widget>[
          FlatButton(
              child: Text("忘记密码"),
              textColor: Colors.white,
              onPressed: () {
                var a = Theme.of(context);
                print(a);
                // Navigator to Login
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return ForgetPassword();
                  }),
                );
              }),
        ],
      ),
      floatingActionButton: StoreConnector<AppState, VoidCallback>(
        converter: (store) {
          return () => _nextStep(context, store);
        },
        builder: (context, callback) {
          return FloatingActionButton(
            // Attach the `callback` to the `onPressed` attribute
            onPressed: callback,
            tooltip: '下一步',
            backgroundColor: Colors.white70,
            elevation: 0.0,
            child: Icon(
              Icons.chevron_right,
              color: Colors.teal,
              size: 48,
            ),
          );
        },
      ),
      body: Theme(
        data: Theme.of(context).copyWith(primaryColor: Colors.white),
        child: Center(
          child: Container(
            constraints: BoxConstraints.expand(),
            padding: EdgeInsets.all(16),
            color: Colors.teal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  child: Text(
                    '登录',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 28.0, color: Colors.white),
                  ),
                  width: double.infinity,
                ),
                Container(height: 48.0),
                _currentTextField(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgetPassword extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        title: Text('忘记密码'),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints.expand(),
          padding: EdgeInsets.all(16),
          color: Colors.teal,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('忘记密码',
                  style: TextStyle(fontSize: 28.0), textAlign: TextAlign.left),
              Container(height: 16.0),
              Text('请输入您的手机号码来查找账号',
                  style: TextStyle(fontSize: 12.0), textAlign: TextAlign.left),
              Container(height: 48.0),
            ],
          ),
        ),
      ),
    );
  }
}
