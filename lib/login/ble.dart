import 'package:wifi/wifi.dart';

Future<String> getWifiSSID() async {
  String ssid = await Wifi.ssid;
  return ssid;
}
