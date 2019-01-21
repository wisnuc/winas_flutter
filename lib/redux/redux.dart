import 'package:redux/redux.dart';

// structure of xxData
class AccountData {
  String token;
  String nickName;
  String username;
  String avatarUrl;
  String id;
  String mail;

  AccountData.fromMap(Map m) {
    this.token = m['token'];
    this.nickName = m['nickName'];
    this.username = m['username'];
    this.avatarUrl = m['avatarUrl'];
    this.id = m['id'];
    this.mail = m['mail'];
  }
}

class DeviceData {
  String deviceSN;
  String deviceName;
  String lanIp;
  String lanToken;
  DeviceData(this.deviceSN, this.deviceName, this.lanIp, this.lanToken);
}

// actions
class LoginAction {
  final AccountData data;
  LoginAction(this.data);
}

class DeviceLoginAction {
  final DeviceData data;
  DeviceLoginAction(this.data);
}

final deviceLoginReducer = combineReducers<DeviceData>([
  TypedReducer<DeviceData, DeviceLoginAction>((data, action) => action.data),
]);

final accountLoginReducer = combineReducers<AccountData>([
  TypedReducer<AccountData, LoginAction>((data, action) => action.data),
]);

AppState appReducer(AppState state, action) {
  return AppState(
    accountLogin: accountLoginReducer(state.accountLogin, action),
    deviceData: deviceLoginReducer(state.deviceData, action),
  );
}

class AppState {
  final AccountData accountLogin;
  final DeviceData deviceData;
  AppState({
    this.accountLogin,
    this.deviceData,
  });

  factory AppState.initial() =>
      new AppState(accountLogin: null, deviceData: null);
}
