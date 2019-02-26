import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../redux/redux.dart';
import '../common/request.dart';
import '../common/loading.dart';
import '../common/showSnackBar.dart';

class ForgetPassword extends StatefulWidget {
  ForgetPassword({Key key}) : super(key: key);
  @override
  _ForgetPasswordState createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  String _status = 'phoneNumber';
  bool showPwd = true;

  // Focus action
  FocusNode focusNode1;
  FocusNode focusNode2;

  Request request = Request();

  String _phoneNumber = '';

  String _code = '';

  String _password = '';

  String _error;

  String _ticket;

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
    _count = -1;
    super.dispose();
  }

  /// show loading
  _loading(BuildContext ctx) {
    showLoading(ctx);
  }

  /// close loading
  _loadingOff(BuildContext ctx) {
    Navigator.pop(ctx);
  }

  /// close loading, setState and focus node
  _nextPage(BuildContext context, String status, FocusNode node) {
    _loadingOff(context);
    setState(() {
      _status = status;
    });

    var future = Future.delayed(Duration(milliseconds: 100),
        () => FocusScope.of(context).requestFocus(node));
    future.then((res) => print('100ms later'));
  }

  /// handle SmsError: close loading, setState
  _handleSmsError(BuildContext context, DioError error) {
    _loadingOff(context);
    print(error.response.data);
    if ([60702, 60003].contains(error.response.data['code'])) {
      showSnackBar(context, '验证码请求过于频繁，请稍后再试');
    } else {
      showSnackBar(context, '获取验证码失败，请稍后再试');
    }
    setState(() {});
  }

  /// nextStep for reset password
  _nextStep(BuildContext context, store) async {
    if (_status == 'phoneNumber') {
      // check phoneNumber
      if (_phoneNumber.length != 11 || !_phoneNumber.startsWith('1')) {
        setState(() {
          _error = '请输入11位手机号';
        });
        return;
      }

      // request smsCode
      _loading(context);

      try {
        await request.req('smsCode', {
          'type': 'password',
          'phone': _phoneNumber,
        });
      } catch (error) {
        if (error.response.data['code'] == 60000) {
          _loadingOff(context);
          showSnackBar(context, '该手机号未注册');
          setState(() {});
          return;
        }
        _handleSmsError(context, error);
        return;
      }
      _startCount();
      // show next page
      _nextPage(context, 'code', focusNode1);
    } else if (_status == 'code') {
      // check code
      if (_code.length != 4) {
        setState(() {
          _error = '请输入4位验证码';
        });
        return;
      }

      // request smsTicket via code
      _ticket = null;
      _loading(context);
      try {
        var res = await request.req('smsTicket', {
          'code': _code,
          'phone': _phoneNumber,
          'type': 'password',
        });

        _ticket = res.data;
      } catch (error) {
        _loadingOff(context);
        setState(() {
          _error = '验证码错误';
        });
        return;
      }

      // show next page
      _nextPage(context, 'password', focusNode2);
    } else if (_status == 'password') {
      // check password
      if (_password.length <= 7) {
        setState(() {
          _error = '密码长度不应小于8位';
        });
        return;
      }

      // register with _code, _phoneNumber, _ticket
      _loading(context);
      try {
        await request.req('resetPwd', {
          'password': _password,
          'phoneTicket': _ticket,
        });
      } catch (error) {
        _loadingOff(context);
        setState(() {
          _error = '重置密码失败';
        });
        return;
      }

      // show next page
      _loadingOff(context);
      setState(() {
        _status = 'success';
      });
    } else {
      // return to login: remove all router, and push '/login'
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (Route<dynamic> route) => false);
    }
  }

  List<Widget> renderPage() {
    switch (_status) {
      case 'phoneNumber':
        return <Widget>[
          Text(
            '忘记密码',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '请输入您的手机号码来查找账号',
            style: TextStyle(color: Colors.white),
          ),
          Container(height: 32.0),
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
          Container(height: 32.0),
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
            '输入新密码',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '您的密码长度至少为8个字符',
            style: TextStyle(color: Colors.white),
          ),
          Container(height: 32.0),
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
            '密码重置成功',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 28.0, color: Colors.white),
          ),
          Container(height: 16.0),
          Text(
            '请使用新密码登录',
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

  int _count = -1;

  _countDown() async {
    if (_count > 0 && this.mounted) {
      await Future.delayed(Duration(seconds: 1));
      if (this.mounted) {
        setState(() {
          _count -= 1;
        });
        await _countDown();
      }
    }
  }

  /// start count down of 60 seconds
  _startCount() {
    _count = 60;
    _countDown().catchError(print);
  }

  /// resendSmg
  _resendSmg(BuildContext ctx) async {
    _loading(ctx);
    try {
      await request.req('smsCode', {
        'type': 'password',
        'phone': _phoneNumber,
      });
    } catch (error) {
      _handleSmsError(ctx, error);
      return;
    }
    _startCount();
    _loadingOff(ctx);
    showSnackBar(ctx, '验证码发送成功');
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
                    child: _count > 0 ? Text('$_count 秒后重新发送') : Text("重新发送"),
                    textColor: Colors.white,
                    onPressed: _count > 0 ? null : () => _resendSmg(ctx),
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
