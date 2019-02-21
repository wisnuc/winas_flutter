import 'package:flutter/material.dart';

import './registry.dart';
import './accountLogin.dart';
import '../icons/winas_icons.dart';

final pColor = Colors.teal;

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
            },
          ),
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
                              borderRadius: BorderRadius.circular(28.0)),
                          onPressed: () => {},
                        )),
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
                          border: Border.all(width: 3, color: Colors.white),
                        ),
                        child: Center(
                          child: Text(
                            "创建账号",
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
      ),
    );
  }
}
