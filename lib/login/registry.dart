import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../redux/redux.dart';
import '../common/request.dart';
import '../common/loading.dart';
import '../common/stationApis.dart';
import '../common/showSnackBar.dart';

class Registry extends StatefulWidget {
  Registry({Key key}) : super(key: key);
  @override
  _RegistryState createState() => _RegistryState();
}

class _RegistryState extends State<Registry> {
  String _status = 'phoneNumber';
  bool showPwd = true;

  // Focus action
  FocusNode focusNode1;
  FocusNode focusNode2;

  var request = Request();

  @override
  void initState() {
    super.initState();

    focusNode1 = FocusNode();
    focusNode2 = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed
    focusNode1.dispose();
    focusNode2.dispose();

    super.dispose();
  }

  String _phoneNumber = '18817301665';

  String _code = '';

  String _password = '12345678';

  String _error;

  Future<void> accoutLogin(context, store, args) async {
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
  }

  void _nextStep(BuildContext context, store) {
    if (_status == 'phoneNumber') {
      if (_phoneNumber.length != 11 || !_phoneNumber.startsWith('1')) {
        setState(() {
          _error = '请输入11位手机号';
        });
        return; // TODO: check phone number
      }
      setState(() {
        _status = 'code';
      });
      var future = Future.delayed(const Duration(milliseconds: 100),
          () => FocusScope.of(context).requestFocus(focusNode1));
      future.then((res) => print('100ms later'));
    } else if ((_status == 'code')) {
      setState(() {
        _status = 'password';
      });
      var future = Future.delayed(const Duration(milliseconds: 100),
          () => FocusScope.of(context).requestFocus(focusNode2));
      future.then((res) => print('100ms later'));
    } else if (_status == 'password') {
      if (_password.length <= 7) {
        setState(() {
          _error = '密码长度不应小于8位';
        });
        return;
      }
      setState(() {
        _status = 'success';
      });
    } else {
      //remove all router, and push '/login'
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (Route<dynamic> route) => false);
    }
  }

  List<Widget> renderPage() {
    switch (_status) {
      case 'phoneNumber':
        return <Widget>[
          Text(
            '绑定手机号',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '手机号码是您忘记密码时，找回面的唯一途径请慎重填写',
            style: TextStyle(color: Colors.white),
          ),
          TextField(
            key: Key('phoneNumber'),
            onChanged: (text) {
              setState(() => _error = null);
              _phoneNumber = text;
            },
            // controller: TextEditingController(text: _phoneNumber),
            autofocus: true,
            decoration: InputDecoration(
                labelText: "手机号",
                prefixIcon: Icon(Icons.person, color: Colors.white),
                errorText: _error),
            style: TextStyle(fontSize: 24),
            maxLength: 11,
            keyboardType: TextInputType.number,
          ),
        ];

      case 'code':
        return <Widget>[
          Text(
            '请输入4位验证码',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '我们向 $_phoneNumber 发送了一个验证码请在下面输入',
            style: TextStyle(color: Colors.white),
          ),
          TextField(
            key: Key('code'),
            onChanged: (text) {
              setState(() => _error = null);
              _code = text;
            },
            // controller: TextEditingController(text: _phoneNumber),
            focusNode: focusNode1,
            decoration: InputDecoration(
                labelText: "4位验证码",
                prefixIcon: Icon(Icons.verified_user, color: Colors.white),
                errorText: _error),
            style: TextStyle(fontSize: 24),
            maxLength: 4,
            keyboardType: TextInputType.number,
          ),
        ];

      case 'password':
        return <Widget>[
          Text(
            '创建密码',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '您的密码长度至少为8个字符',
            style: TextStyle(color: Colors.white),
          ),
          TextField(
            key: Key('password'),
            onChanged: (text) {
              setState(() => _error = null);
              _password = text;
            },
            // controller: TextEditingController(text: _password),
            focusNode: focusNode2,
            decoration: InputDecoration(
                labelText: "密码",
                prefixIcon: Icon(Icons.lock, color: Colors.white),
                suffixIcon: IconButton(
                  icon: Icon(showPwd ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white),
                  onPressed: () {
                    setState(() {
                      showPwd = !showPwd;
                    });
                  },
                ),
                errorText: _error),
            style: TextStyle(fontSize: 24),
            obscureText: showPwd,
          ),
        ];

      case 'success':
        return <Widget>[
          Text(
            '账号创建成功',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '欢迎使用闻上云盘',
            style: TextStyle(color: Colors.white),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(Icons.check, color: Colors.white, size: 48),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
        ];

      default:
        return <Widget>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        actions: _status == 'code'
            ? <Widget>[
                Builder(builder: (BuildContext ctx) {
                  return FlatButton(
                    child: Text("重新发送"),
                    textColor: Colors.white,
                    onPressed: () async {
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
                      await Future.delayed(Duration(seconds: 1));
                      Navigator.pop(context);
                    },
                  );
                }),
              ]
            : <Widget>[],
      ),
      floatingActionButton: Builder(
        builder: (ctx) {
          return StoreConnector<AppState, VoidCallback>(
            converter: (store) => () => _nextStep(ctx, store),
            builder: (context, callback) => FloatingActionButton(
                  onPressed: callback,
                  tooltip: '下一步',
                  backgroundColor: Colors.white70,
                  elevation: 0.0,
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.teal,
                    size: 48,
                  ),
                ),
          );
        },
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          primaryColor: Colors.white,
          accentColor: Colors.white,
          hintColor: Colors.white,
          brightness: Brightness.dark,
        ),
        child: Container(
          constraints: BoxConstraints.expand(),
          padding: EdgeInsets.all(16),
          color: Colors.teal,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: renderPage()),
        ),
      ),
    );
  }
}
