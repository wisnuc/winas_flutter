import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './stationLogin.dart';
import './forgetPassword.dart';

import '../redux/redux.dart';
import '../common/utils.dart';
import '../common/request.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _status = 'account';

  // Focus action
  FocusNode myFocusNode;

  final request = Request();

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
  // String _phoneNumber = '15888524760';

  String _password = '1234567890';

  String _error;

  _currentTextField() {
    if (_status == 'account') {
      return TextField(
        key: Key('account'),
        onChanged: (text) {
          setState(() => _error = null);
          _phoneNumber = text;
        },
        // controller: TextEditingController(text: _phoneNumber),
        autofocus: true,
        decoration: InputDecoration(
            labelText: "手机号",
            labelStyle: TextStyle(
              fontSize: 21,
              color: Colors.white,
              height: 0.8,
            ),
            prefixIcon: Icon(Icons.person, color: Colors.white),
            errorText: _error),
        style: TextStyle(fontSize: 24, color: Colors.white),
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
      // controller: TextEditingController(text: _password),
      focusNode: myFocusNode,
      decoration: InputDecoration(
          labelText: "密码",
          labelStyle: TextStyle(
            fontSize: 21,
            color: Colors.white,
            height: 0.8,
          ),
          prefixIcon: Icon(Icons.lock, color: Colors.white),
          errorText: _error),
      style: TextStyle(fontSize: 24, color: Colors.white),
      obscureText: true,
    );
  }

  void _nextStep(BuildContext context, store) async {
    if (_status == 'account') {
      // check length
      if (_phoneNumber.length != 11 || !_phoneNumber.startsWith('1')) {
        setState(() {
          _error = '请输入11位手机号';
        });
        return;
      }

      // userExist
      showLoading(context);
      bool userExist = false;
      try {
        final res = await request.req('checkUser', {'phone': _phoneNumber});
        userExist = res.data['userExist'];
      } catch (error) {
        print(error);
        Navigator.pop(context);
        showSnackBar(context, '校验手机号失败');
        return;
      }
      Navigator.pop(context);

      if (!userExist) {
        showSnackBar(context, '用户不存在');
      } else {
        // next page
        setState(() {
          _status = 'password';
        });
        final future = Future.delayed(const Duration(milliseconds: 100),
            () => FocusScope.of(context).requestFocus(myFocusNode));
        future.then((res) => print('100ms later'));
      }
    } else {
      // login
      if (_password.length == 0) {
        setState(() {
          _error = '请输入密码';
        });
        return;
      } else if (_password.length < 8) {
        setState(() {
          _error = '密码错误';
        });
        return;
      }

      String clientId = await getClientId();
      final args = {
        'clientId': clientId,
        'username': _phoneNumber,
        'password': _password
      };

      // dismiss keyboard
      FocusScope.of(context).requestFocus(FocusNode());

      // show loading, need `Navigator.pop(context)` to dismiss
      showLoading(context);
      var res;
      try {
        res = await request.req('token', args);
      } catch (error) {
        print(error?.response?.data);
        if (error is DioError && error.response.data['code'] == 60008) {
          Navigator.pop(context);
          setState(() {
            _error = '密码错误';
          });
          return;
        }
        Navigator.pop(context);
        showSnackBar(context, '登录失败');
      }

      // update Account
      Account account = Account.fromMap(res.data);
      store.dispatch(LoginAction(account));

      // device login
      await deviceLogin(context, request, account, store);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        elevation: 0.0, // no shadow
        actions: <Widget>[
          FlatButton(
              child: Text("忘记密码"),
              textColor: Colors.white,
              onPressed: () {
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
          color: Colors.teal,
          constraints: BoxConstraints.expand(),
          child: SingleChildScrollView(
            child: Container(
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
      ),
    );
  }
}
