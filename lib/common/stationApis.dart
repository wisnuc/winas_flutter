import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io' show Platform;
import 'package:connectivity/connectivity.dart';

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
  StreamSubscription<ConnectivityResult> sub;
  Dio dio = Dio();

  Apis(this.token, this.lanIp, this.lanToken, this.userUUID, this.isCloud,
      this.deviceSN, this.cookie) {
    this.lanAdrress = 'http://${this.lanIp}:3000';
  }

  Apis.fromMap(Map m) {
    this.token = m['token'];
    this.lanIp = m['lanIp'];
    this.lanToken = m['lanToken'];
    this.userUUID = m['userUUID'];
    // reload from disk, isCloud = null, need to re-test;
    this.isCloud = null;
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
      'deviceSN': deviceSN,
      'cookie': cookie,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();

  /// handle data.data response
  void interceptDio() {
    InterceptorsWrapper interceptorsWrapper = InterceptorsWrapper(
      onResponse: (Response response) {
        if (response.data is Map && response.data['data'] != null) {
          return response.data['data'];
        }
        return response.data;
      },
    );
    if (dio.interceptors.length == 0) {
      dio.interceptors.add(interceptorsWrapper);
    } else {
      dio.interceptors[0] = interceptorsWrapper;
    }
  }

  /// get with token
  tget(String ep, Map<String, dynamic> args) {
    assert(token != null);
    if (isCloud ?? true) return command('GET', ep, args);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    return dio.get('$lanAdrress/$ep', queryParameters: args);
  }

  /// post with token
  tpost(String ep, dynamic args, {CancelToken cancelToken}) {
    assert(token != null);
    if (isCloud ?? true)
      return command('POST', ep, args, cancelToken: cancelToken);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    return dio.post('$lanAdrress/$ep', data: args, cancelToken: cancelToken);
  }

  /// delete with token
  tdel(String ep, dynamic args, {CancelToken cancelToken}) {
    assert(token != null);
    if (isCloud ?? true)
      return command('DELETE', ep, args, cancelToken: cancelToken);
    dio.options.headers['Authorization'] = 'JWT $lanToken';
    return dio.delete('$lanAdrress/$ep', data: args, cancelToken: cancelToken);
  }

  /// request via cloud
  command(String verb, String ep, dynamic data, // qs, body or formdata
      {CancelToken cancelToken}) {
    assert(token != null);
    assert(cookie != null);
    bool isFormData = data is FormData;
    bool isGet = verb == 'GET';
    dio.options.headers['Authorization'] = token;
    dio.options.headers['cookie'] = cookie;

    final url = '$cloudAddress/station/$deviceSN/json';
    final url2 = '$cloudAddress/station/$deviceSN/pipe';

    // handle formdata
    if (isFormData) {
      final qs = {
        'verb': verb,
        'urlPath': '/$ep',
      };
      final qsData = Uri.encodeQueryComponent(jsonEncode(qs));
      final newUrl = '$url2?data=$qsData';
      return dio.post(newUrl, data: data, cancelToken: cancelToken);
    }

    // normal pipe-json
    return dio.post(
      url,
      data: {
        'verb': verb,
        'urlPath': '/$ep',
        'body': isGet ? null : data,
        'params': isGet ? data : null,
      },
      cancelToken: cancelToken,
    );
  }

  ///  handle formdata
  writeDir(String ep, FormData formData, {CancelToken cancelToken}) {
    return (isCloud ?? true)
        ? command('POST', ep, formData, cancelToken: cancelToken)
        : tpost(ep, formData, cancelToken: cancelToken);
  }

  Future<bool> isMobile() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      print('current netwprk status: mobile');
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print('current netwprk status: wifi');
      return false;
    }
    return false;
  }

  monitorStart() {
    sub = Connectivity().onConnectivityChanged.listen((ConnectivityResult res) {
      print('Network Changed to $res');
      if (res == ConnectivityResult.wifi) {
        this.testLAN().catchError(print);
      } else if (res == ConnectivityResult.mobile) {
        this.isCloud = true;
      }
    });
  }

  monitorCancel() {
    try {
      sub?.cancel();
    } catch (e) {
      print(e);
    }
  }

  Future<bool> testLAN() async {
    bool isLAN = false;
    try {
      final res = await dio.get(
        'http://${this.lanIp}:3001/winasd/info',
        options: Options(connectTimeout: 1000, receiveTimeout: 0),
      );
      isLAN = res.data['device']['sn'] == this.deviceSN;
    } catch (error) {
      print(error);
      isLAN = false;
    }
    this.isCloud = !isLAN;
    print('this.lanIp: $lanIp, isCloud: $isCloud');
    return isLAN;
  }

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

      case 'drives':
        r = tget('drives', null);
        break;

      case 'createDrives':
        r = tpost('drives', args);
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
        r = writeDir(
          'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
          FormData.from({
            args['dirname']: jsonEncode({'op': 'mkdir'}),
          }),
        );
        break;

      case 'randomSrc':
        r = tget('media/${args['hash']}', {'alt': 'random'});
        break;

      case 'rename':
        r = writeDir(
          'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
          FormData.from({
            '${args['oldName']}|${args['newName']}':
                jsonEncode({'op': 'rename'}),
          }),
        );
        break;

      case 'deleteDirOrFile':
        r = writeDir(
          'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
          args['formdata'],
        );
        break;

      case 'xcopy':
        r = tpost('tasks', args);
        break;

      case 'task':
        r = tget('tasks/${args['uuid']}', null);
        break;

      case 'tasks':
        r = tget('tasks', null);
        break;

      case 'delTask':
        r = tdel('tasks/${args['uuid']}', null);
        break;

      case 'search':
        r = tget('files', args);
        break;

      case 'winasInfo':
        r = isCloud
            ? command('GET', 'winasd/info', null)
            : dio.get('http://${this.lanIp}:3001/winasd/info');
        break;

      case 'reqLocalAuth':
        r = dio.patch('http://${this.lanIp}:3001/winasd/localAuth');
        break;

      case 'localAuth':
        r = dio.post('http://${this.lanIp}:3001/winasd/localAuth',
            data: {'color': args['color']});
        break;
    }
    return r;
  }

  Future download(String ep, Map<String, dynamic> qs, String downloadPath,
      {Function onProgress, CancelToken cancelToken}) async {
    // remove interceptors
    dio.interceptors.length = 0;

    // download via cloud pipe
    if (isCloud ?? true) {
      final url = '$cloudAddress/station/$deviceSN/pipe';
      final qsData = {
        'data': jsonEncode({
          'verb': 'GET',
          'urlPath': '/$ep',
          'params': qs,
        })
      };
      dio.options.headers['Authorization'] = token;
      dio.options.headers['cookie'] = cookie;
      await dio.download(
        url,
        downloadPath,
        queryParameters: qsData,
        cancelToken: cancelToken,
        onReceiveProgress: (a, b) =>
            onProgress != null ? onProgress(a, b) : null,
      );
    } else {
      // download via lan
      dio.options.headers['Authorization'] = 'JWT $lanToken';
      await dio.download(
        '$lanAdrress/$ep',
        downloadPath,
        queryParameters: qs,
        cancelToken: cancelToken,
        onReceiveProgress: (a, b) =>
            onProgress != null ? onProgress(a, b) : null,
      );
    }
  }

  Future uploadAsync(Map<String, dynamic> args,
      {Function onProgress, CancelToken cancelToken}) async {
    return writeDir(
      'drives/${args['driveUUID']}/dirs/${args['dirUUID']}/entries',
      FormData.from({
        args['fileName']: args['file'],
      }),
      cancelToken: cancelToken,
    );
  }

  upload(Map<String, dynamic> args, callback,
      {Function onProgress, CancelToken cancelToken}) {
    uploadAsync(args, cancelToken: cancelToken, onProgress: onProgress)
        .then((value) => callback(null, value))
        .catchError((error) => callback(error, null));
  }
}
