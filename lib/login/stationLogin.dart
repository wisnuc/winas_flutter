import 'package:flutter/material.dart';
import './stationList.dart';
import '../redux/redux.dart';
import '../common/request.dart';
import '../transfer/manager.dart';
import '../common/stationApis.dart';

/// Login to device
stationLogin(BuildContext context, Request request, Station currentDevice,
    Account account, store) async {
  assert(currentDevice != null);

  final deviceSN = currentDevice.sn;
  final lanIp = currentDevice.lanIp;
  final deviceName = currentDevice.name;

  List results = await Future.wait([
    request.req('localBoot', {'deviceSN': deviceSN}),
    request.req('localUsers', {'deviceSN': deviceSN}),
    request.req('localToken', {'deviceSN': deviceSN}),
    request.req('localDrives', {'deviceSN': deviceSN})
  ]);

  final lanToken = results[2].data['token'];

  assert(lanToken != null);

  // update StatinData
  store.dispatch(
    DeviceLoginAction(
      Device(
        deviceSN: deviceSN,
        deviceName: deviceName,
        lanIp: lanIp,
        lanToken: lanToken,
      ),
    ),
  );
  assert(results[1].data is List);

  // get current user data
  final user = results[1].data.firstWhere(
        (s) => s['winasUserId'] == account.id,
        orElse: () => null,
      );

  store.dispatch(
    UpdateUserAction(
      User.fromMap(user),
    ),
  );

  // get current drives data
  List<Drive> drives = List.from(
    results[3].data.map((drive) => Drive.fromMap(drive)),
  );

  store.dispatch(
    UpdateDrivesAction(drives),
  );

  // cloud apis
  store.dispatch(
    UpdateCloudAction(request),
  );

  // station apis, TODO: handle cloud
  bool isCloud = true;
  String cookie = request.cookie;
  Apis apis = Apis(
      account.token, lanIp, lanToken, account.id, isCloud, deviceSN, cookie);

  store.dispatch(
    UpdateApisAction(apis),
  );

  if (user['uuid'] != null) {
    // init TransferManager, load TransferItem
    TransferManager.init(user['uuid']).catchError(print);
  }

  // set lastUserDeviceSn
  request.req('setLastSN', {'sn': deviceSN}).catchError(print);
}

/// Request station list
reqStationList(Request request) async {
  final stationsRes = await request.req('stations', null);
  final lastUseDeviceSn = stationsRes.data['lastUseDeviceSn'];
  List<Station> stationList = List.from(
    stationsRes.data['ownStations'].map(
      (s) => Station.fromMap(s, isOwner: true),
    ),
  );
  List<Station> sharedStations = List.from(
    stationsRes.data['sharedStations'].map(
      (s) => Station.fromMap(s, isOwner: false),
    ),
  );
  // add shared device
  stationList.addAll(sharedStations);

  final lastDevice = stationList.firstWhere(
      (s) => s.sn == lastUseDeviceSn && s.sn != null,
      orElse: () => null);

  return ({
    'stationList': stationList,
    'lastDevice': lastDevice,
  });
}

/// Request station list and try login to lastDevice
deviceLogin(
    BuildContext context, Request request, Account account, store) async {
  // request station list
  List<Station> stationList;
  Station lastDevice;
  try {
    final result = await reqStationList(request);
    stationList = result['stationList'];
    lastDevice = result['lastDevice'];
  } catch (error) {
    print(error);
    stationList = null;
    lastDevice = null;
  }

  // find lastDevice and device is online, try login
  bool success = false;
  if (lastDevice != null && lastDevice.isOnline) {
    try {
      await stationLogin(context, request, lastDevice, account, store);
      success = true;
    } catch (error) {
      print(error);
      success = false;
    }
  }

  if (success) {
    // remove all router, and push '/station'
    Navigator.pushNamedAndRemoveUntil(
        context, '/station', (Route<dynamic> route) => false);
    return;
  } else {
    // no availiable last device
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StationList(
            request: request,
            stationList: stationList,
          );
        },
      ),
    );
  }
}
