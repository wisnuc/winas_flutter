import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class Request {
  bool isIOS = !Platform.isAndroid;
  String cloudAddress = 'https://test.nodetribe.com/c/v1';
  String token;
  String cookie;
  Dio dio = Dio();

  Request({this.token});

  Request.fromMap(Map m) {
    this.token = m['token'];
    this.cookie = m['cookie'];
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'token': token,
      'cookie': cookie,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();

  // handle data.data response
  void interceptDio() {
    InterceptorsWrapper interceptorsWrapper = InterceptorsWrapper(
      onResponse: (Response response) {
        var res = response.data['data'];
        // save cloud token not lanToken
        if (res is Map && res['token'] != null && res['id'] != null) {
          token = res['token'];
        }
        if (response.data['url'] == '/c/v1/station') {
          assert(response.headers['set-cookie'][0] != null);
          cookie = response.headers['set-cookie'][0];
        }
        if (res != null) return res;
        return response.data;
      },
    );

    if (dio.interceptors.length == 0) {
      dio.interceptors.add(interceptorsWrapper);
    } else {
      dio.interceptors[0] = interceptorsWrapper;
    }
  }

  aget(String ep, args) {
    return args == null
        ? dio.get('$cloudAddress/$ep')
        : dio.get('$cloudAddress/$ep', queryParameters: args);
  }

  apost(String ep, args) {
    return args == null
        ? dio.post('$cloudAddress/$ep')
        : dio.post('$cloudAddress/$ep', data: args);
  }

  apatch(String ep, args) {
    return args == null
        ? dio.patch('$cloudAddress/$ep')
        : dio.patch('$cloudAddress/$ep', data: args);
  }

  /// get with token
  tget(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = token;
    return dio.get('$cloudAddress/$ep', queryParameters: args);
  }

  /// post with token
  tpost(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = token;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['cookie'] = cookie;
    return dio.post('$cloudAddress/$ep', data: args);
  }

  /// patch with token
  tpatch(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = token;
    return dio.patch('$cloudAddress/$ep', data: args);
  }

  /// patch with token
  tdel(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = token;
    return dio.delete('$cloudAddress/$ep', data: args);
  }

  /// command via pipe
  command(deviceSN, data) {
    assert(token != null);
    assert(cookie != null);
    dio.options.headers['Authorization'] = token;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['cookie'] = cookie;
    return dio.post('$cloudAddress/station/$deviceSN/json', data: data);
  }

  /// test lanIp
  Future<bool> testLAN(String ip, String deviceSN) async {
    bool isLAN = false;
    try {
      final res = await dio.get(
        'http://$ip:3001/winasd/info',
        options: Options(connectTimeout: 1000),
      );
      isLAN = res.data['device']['sn'] == deviceSN;
    } catch (error) {
      print(error);
      isLAN = false;
    }
    return isLAN;
  }

  Future req(String name, Map<String, dynamic> args) {
    Future r;
    interceptDio();
    switch (name) {
      case 'registry':
        r = apost('user', {
          'type': isIOS ? 'iOS' : 'Android',
          'phone': args['phone'],
          "ticket": args['ticket'],
          'clientId': args['clientId'],
          "password": args['password'],
        });
        break;

      case 'smsTicket':
        r = apost('user/smsCode/ticket', {
          'type': args['type'],
          'code': args['code'],
          'phone': args['phone'],
        });
        break;

      case 'checkUser':
        r = aget('user/phone/check', {"phone": args['phone']});
        break;

      case 'setLastSN':
        r = tpost('user/deviceInfo', {'sn': args['sn']});
        break;

      case 'token':
        r = aget('user/password/token', {
          'clientId': args['clientId'],
          'type': isIOS ? 'iOS' : 'Android',
          'username': args['username'],
          'password': args['password']
        });
        break;

      case 'wechat':
        r = tget('wechat', null);
        break;

      case 'unbindWechat':
        r = tdel('user/wechat', {
          'unionid': args['unionid'],
        });
        break;

      case 'wechatLogin':
        r = aget('wechat/token', {
          'loginType': 'mobile',
          'code': args['code'],
          'type': isIOS ? 'iOS' : 'Android',
          'clientId': args['clientId'],
        });
        break;

      case 'bindWechat':
        r = tpatch('wechat/user', {
          'wechat': args['wechatToken'],
        });
        break;

      case 'smsCode':
        r = apost('user/smsCode', {
          'type': args['type'], // register, password, login, replace
          'phone': args['phone'],
        });
        break;

      case 'smsToken':
        r = aget('user/smsCode/token', {
          'type': isIOS ? 'iOS' : 'Android',
          'phone': args['phone'],
          'code': args['code'],
          'clientId': args['clientId'],
        });
        break;

      case 'resetPwd':
        r = apatch('user/password', {
          'password': args['password'],
          'phoneTicket': args['phoneTicket'],
        });
        break;

      case 'replacePhone':
        r = tpatch('user/phone', {
          'oldTicket': args['oldTicket'],
          'newTicket': args['newTicket'],
        });
        break;

      case 'newNickName':
        r = tpatch('/user/nickname', {
          'nickName': args['nickName'],
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
      case 'renameStation':
        r = command(args['deviceSN'], {
          'verb': 'POST',
          'urlPath': '/winasd/device',
          'body': {
            'name': args['name'],
          },
        });
        break;
    }
    return r;
  }

  Future setAvatar(List<int> imageData, {CancelToken cancelToken}) async {
    assert(token != null);
    dio.options.headers['Authorization'] = token;
    interceptDio();
    return dio.put(
      '$cloudAddress/user/avatar',
      data: imageData,
      options: Options(
        contentType: ContentType.binary,
      ),
      cancelToken: cancelToken,
    );
  }
}
