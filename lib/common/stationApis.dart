import 'dart:convert';
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

  Apis.fromMap(Map m) {
    this.token = m['token'];
    this.lanIp = m['lanIp'];
    this.lanToken = m['lanToken'];
    this.userUUID = m['userUUID'];
    this.isCloud = m['isCloud'];
    this.deviceSN = m['deviceSN'];
    this.cookie = m['cookie'];
    this.lanAdrress = 'http://${this.lanIp}:3000';
  }
  @override
  String toString() {
    Map<String, dynamic> m = {
      'token': token,
      'lanIp': lanIp,
      'lanToken': lanToken,
      'userUUID': userUUID,
      'isCloud': isCloud,
      'deviceSN': deviceSN,
      'cookie': cookie,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();

  // handle data.data response
  void interceptDio() {
    dio.interceptor.response.onSuccess = (Response response) {
      if (response.data is Map && response.data['data'] != null) {
        return response.data['data'];
      }
      return response.data;
    };
  }

  // request with token
  tget(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    return dio.get('$lanAdrress/$ep', data: args);
  }

  tpost(String ep, args) {
    assert(token != null);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    return dio.post('$lanAdrress/$ep', data: args);
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

  Future req(String name, Map<String, dynamic> args) {
    Future r;
    interceptDio();
    switch (name) {
      case 'listNavDir':
        r = tget(
          'drives/${args['driveUUID']}/dirs/${args['dirUUID']}',
          {'metadata': 'true'},
        );
        break;
      case 'space':
        r = tget('boot/space', null);
        break;
      case 'stats':
        r = tget('fruitmix/stats', null);
        break;
      case 'dirStat':
        r = tget(
            'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/stats', null);
        break;
      case 'mkdir':
        r = tpost(
            'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
            FormData.from({
              args['dirname']: jsonEncode({'op': 'mkdir'}),
            }));
        break;

      case 'rename':
        r = tpost(
            'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
            FormData.from({
              '${args['oldName']}|${args['newName']}':
                  jsonEncode({'op': 'rename'}),
            }));
        break;

      case 'deleteDirOrFile':
        r = tpost('drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
            args['formdata']);
        break;

      case 'xcopy':
        r = tpost('tasks', args);
        break;

      case 'search':
        r = tget('files', args);
        break;

      case 'winasInfo':
        r = dio.get('http://${this.lanIp}:3001/winasd/info');
        break;
    }
    return r;
  }

  download(String ep, Map<String, dynamic> qs, String downloadPath,
      {Function onProgress, CancelToken cancelToken}) async {
    assert(token != null);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    await dio.download(
      '$lanAdrress/$ep',
      downloadPath,
      data: qs,
      cancelToken: cancelToken,
      onProgress: (a, b) => onProgress != null ? onProgress(a, b) : null,
    );
  }
}
