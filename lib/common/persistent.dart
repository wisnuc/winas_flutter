import 'package:shared_preferences/shared_preferences.dart';

class Persistent {
  getString(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(name);
  }

  setString(String name, String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print('save $name : $data');
    prefs.setString(name, data);
  }
}
