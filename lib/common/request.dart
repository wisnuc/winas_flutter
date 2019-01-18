import 'dart:io' show Platform;
import 'package:dio/dio.dart';

class Request {
  bool isIOS = !Platform.isAndroid;
  String cloudAddress = 'https://test.nodetribe.com/c/v1';
  String token;
  String cookie;
  String lanToken;
  String lanIp;
  Dio dio = new Dio();
  // handle data.data response
  void interceptDio() {
    dio.interceptor.response.onSuccess = (Response response) {
      var res = response.data['data'];
      if (res is Map && res['token'] != null) {
        token = res['token']; // save cloud token
      }
      if (response.data['url'] == '/c/v1/station') {
        assert(response.headers['set-cookie'][0] != null);
        cookie = response.headers['set-cookie'][0];
      }
      if (res != null) return res;
      return response.data;
    };
  }

  aget(String ep, args) {
    return args == null
        ? dio.get('$cloudAddress/$ep')
        : dio.get('$cloudAddress/$ep', data: args);
  }

  tget(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = token;
    return dio.get('$cloudAddress/$ep', data: args);
  }

  command(deviceSN, data) {
    assert(token != null);
    assert(cookie != null);
    dio.options.headers['Authorization'] = token;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['cookie'] = cookie;
    return dio.post('$cloudAddress/station/$deviceSN/json', data: data);
  }

  req(name, args) {
    Future r;
    interceptDio();
    switch (name) {
      case 'checkUser':
        r = aget('user/phone/check', {"phone": args['phone']});
        break;
      case 'token':
        r = aget('user/password/token', {
          'clientId': args['clientId'],
          'type': isIOS ? 'iOS' : 'Android',
          'username': args['username'],
          'password': args['password']
        });
        break;
      case 'stations':
        r = tget('station', null);
        break;
      case 'localBoot':
        r = command(args['deviceSN'], {'verb': 'GET', 'urlPath': '/boot'});
        break;
      case 'localDrives':
        r = command(args['deviceSN'], {'verb': 'GET', 'urlPath': '/drives'});
        break;
      case 'localToken':
        r = command(args['deviceSN'], {'verb': 'GET', 'urlPath': '/token'});
        break;
      case 'localUsers':
        r = command(args['deviceSN'], {'verb': 'GET', 'urlPath': '/users'});
        break;
    }
    return r;
  }
}
