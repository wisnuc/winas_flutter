import 'dart:io' show Platform;
import 'package:dio/dio.dart';

class Apis {
  bool isIOS = !Platform.isAndroid;
  bool isCloud;
  final cloudAddress = 'https://test.nodetribe.com/c/v1';
  String token;
  String cookie;
  String lanToken;
  String lanIp;
  String lanAdrress;
  String userUUID;
  String deviceSN;
  Dio dio = new Dio();

  Apis(this.token, this.lanIp, this.lanToken, this.userUUID, this.isCloud,
      this.deviceSN, this.cookie) {
    this.lanAdrress = 'http://${this.lanIp}:3000';
  }

  // handle data.data response
  void interceptDio() {
    dio.interceptor.response.onSuccess = (Response response) {
      var res = response.data['data'];
      if (res != null) return res;
      return response.data;
    };
  }

  // request with token
  tget(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    return dio.get('$lanAdrress/$ep', data: args);
  }

  command(data) {
    assert(token != null);
    assert(cookie != null);
    dio.options.headers['Authorization'] = token;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.headers['cookie'] = cookie;
    return dio.post('$cloudAddress/station/${this.deviceSN}/json', data: data);
  }

  // case 'localBoot':
  //       r = command(args['deviceSN'], {'verb': 'GET', 'urlPath': '/boot'});

  req(String name, Map<String, dynamic> args) {
    Future r;
    interceptDio();
    switch (name) {
      case 'listNavDir':
        r = tget(
          'drives/${args['driveUUID']}/dirs/${args['dirUUID']}',
          {'metadata': 'true'},
        );
        break;
    }
    return r;
  }
}
