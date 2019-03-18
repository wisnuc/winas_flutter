import 'dart:async';
import 'dart:convert';
import 'package:wifi/wifi.dart';
import 'package:flutter_blue/flutter_blue.dart';

const LOCAL_AUTH_SERVICE = '60000000-0182-406c-9221-0a6680bd0943';
const LOCAL_AUTH_SERVICE_INDICATE = '60000001-0182-406c-9221-0a6680bd0943';
const LOCAL_AUTH_SERVICE_WRITE = '60000002-0182-406c-9221-0a6680bd0943';
const NET_SETTING_SERVICE = '70000000-0182-406c-9221-0a6680bd0943';
const NET_SETTING_SERVICE_INDICATE = '70000001-0182-406c-9221-0a6680bd0943';
const NET_SETTING_SERVICE_WRITE = '70000002-0182-406c-9221-0a6680bd0943';
const CLOUD_SERVICE = '80000000-0182-406c-9221-0a6680bd0943';
const CLOUD_SERVICE_INDICATE = '80000001-0182-406c-9221-0a6680bd0943';
const CLOUD_SERVICE_WRITE = '80000002-0182-406c-9221-0a6680bd0943';

/// get photo's current wifi's ssid
Future<String> getWifiSSID() async {
  String ssid = await Wifi.ssid;
  return ssid;
}

/// GetLocalAuth
///
/// Command to get color code: '{"action":"req","seq":1}';
///
/// Command to get auth token: '{"action":"auth","seq":2}';
Future getLocalAuth(BluetoothDevice device, String command) async {
  List<BluetoothService> services = await device.discoverServices();
  final localAuthService = services.firstWhere(
    (s) => s.uuid.toString() == LOCAL_AUTH_SERVICE,
    orElse: () => null,
  );

  final localAuthNotify = localAuthService.characteristics.firstWhere(
    (c) => c.uuid.toString() == LOCAL_AUTH_SERVICE_INDICATE,
    orElse: () => null,
  );

  final localAuthWrite = localAuthService.characteristics.firstWhere(
    (c) => c.uuid.toString() == LOCAL_AUTH_SERVICE_WRITE,
    orElse: () => null,
  );
  await device.setNotifyValue(localAuthNotify, true);

  final res = await writeDataAsync(
    command,
    device,
    localAuthNotify,
    localAuthWrite,
  );

  return res;
}

/// ConnectWifi
///
/// '{"action":"addAndActive", "seq": 123, "token": "0bf6abac423c54540a713870d54b16446fc8442a65e3a3bd2a1d7126f139b95c04368c83988381627284f7c561809ea2", "body":{"ssid":"Naxian800", "pwd":"vpai1228"}}';
Future connectWifi(BluetoothDevice device, String command) async {
  List<BluetoothService> services = await device.discoverServices();
  final localAuthService = services.firstWhere(
    (s) => s.uuid.toString() == NET_SETTING_SERVICE,
    orElse: () => null,
  );

  final localAuthNotify = localAuthService.characteristics.firstWhere(
    (c) => c.uuid.toString() == NET_SETTING_SERVICE_INDICATE,
    orElse: () => null,
  );

  final localAuthWrite = localAuthService.characteristics.firstWhere(
    (c) => c.uuid.toString() == NET_SETTING_SERVICE_WRITE,
    orElse: () => null,
  );
  await device.setNotifyValue(localAuthNotify, true);

  final json = await writeDataAsync(
    command,
    device,
    localAuthNotify,
    localAuthWrite,
  );

  return json;
}

/// write data to BLE Characteristic
void writeData(
  String data,
  BluetoothDevice device,
  BluetoothCharacteristic notifyCharact,
  BluetoothCharacteristic writeCharact,
  Function callback,
) {
  bool fired = false;

  device.onValueChanged(notifyCharact).first.then((value) {
    if (!fired) {
      fired = true;
      var res;
      try {
        res = jsonDecode(String.fromCharCodes(value));
      } catch (e) {
        callback(e, null);
      }
      callback(null, res);
    }
  });

  device.writeCharacteristic(writeCharact, data.codeUnits).catchError((error) {
    if (!fired) {
      fired = true;
      callback(error, null);
    }
  });
}

/// async funtion of writeData
Future writeDataAsync(
  String data,
  BluetoothDevice device,
  BluetoothCharacteristic notifyCharact,
  BluetoothCharacteristic writeCharact,
) async {
  Completer c = Completer();
  writeData(data, device, notifyCharact, writeCharact, (error, value) {
    if (error != null) {
      c.completeError(error);
    } else {
      c.complete(value);
    }
  });
  return c.future;
}
