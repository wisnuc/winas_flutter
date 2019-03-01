import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './stationLogin.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import '../common/request.dart';

class Registry extends StatefulWidget {
  Registry({Key key, this.wechat}) : super(key: key);

  /// Wechat token for binding
  final String wechat;
  @override
  _RegistryState createState() => _RegistryState();
}

class _RegistryState extends State<Registry> {
  String _status = 'phoneNumber';
  bool showPwd = true;

  ///  used in bind wechat
  ///
  ///  if (_userExist) -> login and bind
  ///
  ///  else -> registry and bind
  bool _userExist = false;

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
    _count = -1;

    super.dispose();
  }

  String _phoneNumber = '18817301665';

  String _code = '';

  String _password = '12345678';

  String _error;

  String _ticket;

  Future<void> accoutLogin(context, store, args) async {
    // dismiss keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    // show loading, need `Navigator.pop(context)` to dismiss
    showLoading(context);
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

    var future = Future.delayed(const Duration(milliseconds: 100),
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

  /// nextStep for normal register
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
          'type': 'register',
          'phone': _phoneNumber,
        });
      } catch (error) {
        if (error.response.data['code'] == 60001) {
          _loadingOff(context);
          showSnackBar(context, '该手机号已经注册');
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
          'type': 'register',
        });

        _ticket = res.data;
        if (_ticket == null) {
          throw Error();
        }
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
        await request.req('registry', {
          'code': _code,
          'phone': _phoneNumber,
          "ticket": _ticket,
          'clientId': 'flutter_Test',
          "password": _password,
        });
      } catch (error) {
        _loadingOff(context);
        setState(() {
          _error = '注册失败';
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

  /// nextStep for wechat
  _wechatNextStep(BuildContext context, store) async {
    if (_status == 'phoneNumber') {
      // check phoneNumber
      if (_phoneNumber.length != 11 || !_phoneNumber.startsWith('1')) {
        setState(() {
          _error = '请输入11位手机号';
        });
        return;
      }

      // get smsCode ->
      // 1. user already exist
      // 2. new user, need register
      _loading(context);
      _userExist = false;
      try {
        await request.req('smsCode', {
          'type': 'register',
          'phone': _phoneNumber,
        });
      } catch (error) {
        if (error.response.data['code'] == 60001) {
          // user already exist
          // request code to login & bind wechat
          try {
            await request.req('smsCode', {
              'type': 'login',
              'phone': _phoneNumber,
            });
          } catch (err) {
            _handleSmsError(context, err);
            return;
          }
          _userExist = true;
          // show next page
          _nextPage(context, 'code', focusNode1);
          return;
        } else {
          // request register smsCode error
          _handleSmsError(context, error);
          return;
        }
      }
      _startCount();
      // _phoneNumber is new, need to register account
      // show next page
      _nextPage(context, 'code', focusNode1);
    } else if (_status == 'code') {
      if (_code.length != 4) {
        setState(() {
          _error = '请输入4位验证码';
        });
        return;
      }

      // _userExist == true, login via code, bind wechat, login station
      if (_userExist) {
        // get token
        var res;
        try {
          res = await request.req('smsToken', {
            'code': _code,
            'phone': _phoneNumber,
            'clientId': 'flutter_Test',
          });
        } catch (err) {
          print(err);
          showSnackBar(context, '验证码错误');
          return;
        }
        // bind wechat with account
        try {
          await request.req('bindWechat', {
            "wechatToken": widget.wechat,
          });
        } catch (err) {
          print(err);
          showSnackBar(context, '绑定失败');
          return;
        }

        // update Account
        Account account = Account.fromMap(res.data);
        store.dispatch(LoginAction(account));

        // device login
        await deviceLogin(context, request, account, store);
      } else {
        // request smsTicket via code
        _ticket = null;
        _loading(context);
        try {
          var res = await request.req('smsTicket', {
            'code': _code,
            'phone': _phoneNumber,
            'type': 'register',
          });

          _ticket = res.data;
        } catch (error) {
          _loadingOff(context);
          print(error);
          showSnackBar(context, '验证码错误');
          return;
        }

        // show next page
        _nextPage(context, 'password', focusNode2);
      }
    } else if (_status == 'password') {
      // register with _code, _phoneNumber, _ticket
      if (_password.length <= 7) {
        setState(() {
          _error = '密码长度不应小于8位';
        });
        return;
      }
      _loading(context);

      try {
        // registry
        await request.req('registry', {
          'code': _code,
          'phone': _phoneNumber,
          "ticket": _ticket,
          'clientId': 'flutter_Test',
          "password": _password,
        });

        // bind wechat with account
        await request.req('bindWechat', {
          "wechatToken": widget.wechat,
        });
      } catch (error) {
        _loadingOff(context);
        print(error);
        showSnackBar(context, '注册失败');
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
            '创建密码',
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
            converter: (store) => () => widget.wechat == null
                ? _nextStep(ctx, store)
                : _wechatNextStep(ctx, store),
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
