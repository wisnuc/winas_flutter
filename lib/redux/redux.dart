import 'package:redux/redux.dart';
import '../common/format.dart';
import '../common/stationApis.dart';

// structure of xxData
class Account {
  String token;
  String nickName;
  String username;
  String avatarUrl;
  String id;
  String mail;
  Account(
      {this.token,
      this.nickName,
      this.username,
      this.avatarUrl,
      this.id,
      this.mail});
  Account.fromMap(Map m) {
    this.token = m['token'];
    this.nickName = m['nickName'];
    this.username = m['username'];
    this.avatarUrl = m['avatarUrl'];
    this.id = m['id'];
    this.mail = m['mail'];
  }
}

class Device {
  String deviceSN;
  String deviceName;
  String lanIp;
  String lanToken;
  Device({this.deviceSN, this.deviceName, this.lanIp, this.lanToken});
}

class User {
  String uuid;
  String username;
  bool isFirstUser;
  String status;
  String phoneNumber;
  String winasUserId;
  String avatarUrl;

  User.fromMap(Map m) {
    this.uuid = m['uuid'];
    this.username = m['username'];
    this.isFirstUser = m['isFirstUser'];
    this.status = m['status'];
    this.phoneNumber = m['phoneNumber'];
    this.winasUserId = m['winasUserId'];
    this.avatarUrl = m['avatarUrl'];
  }
}

class Drive {
  String uuid;
  String type;
  bool privacy;
  String owner;
  String tag;
  String label;
  bool isDeleted;
  bool smb;
  int ctime;
  int mtime;
  Map<String, dynamic> client;
  Drive({this.uuid, this.tag});
  Drive.fromMap(Map m) {
    this.uuid = m['uuid'];
    this.type = m['type'];
    this.privacy = m['privacy'];
    this.owner = m['owner'];
    this.tag = m['tag'];
    this.label = m['label'];
    this.isDeleted = m['isDeleted'];
    this.smb = m['smb'];
    this.ctime = m['ctime'];
    this.mtime = m['mtime'];
    this.client = m['client'];
  }
}

class Metadata {
  String type;
  Metadata.fromMap(Map m) {
    this.type = m['type'];
  }
}

class Entry {
  int size;
  int ctime;
  int mtime;
  String name;
  String uuid;
  String type;
  String hash;
  String hsize;
  String hmtime;
  String pdir;
  String pdrv;
  List namepath;
  Metadata metadata;

  Entry.fromMap(Map m) {
    this.size = m['size'];
    this.ctime = m['ctime'];
    this.mtime = m['mtime'];
    this.name = m['name'];
    this.uuid = m['uuid'];
    this.type = m['type'];
    this.hash = m['hash'];
    this.hsize = prettySize(this.size);
    this.hmtime = prettyDate(this.mtime);
    this.metadata =
        m['metadata'] == null ? null : Metadata.fromMap(m['metadata']);
  }

  Entry.fromSearch(Map m, List<String> d) {
    this.size = m['size'];
    this.ctime = m['ctime'];
    this.mtime = m['mtime'];
    this.name = m['name'];
    this.uuid = m['uuid'];
    this.type = m['type'];
    this.hash = m['hash'];
    this.hsize = prettySize(this.size);
    this.hmtime = prettyDate(this.mtime);
    this.metadata =
        m['metadata'] == null ? null : Metadata.fromMap(m['metadata']);
    this.pdir = m['pdir'];
    this.pdrv = d[m['place']];
    this.namepath = m['namepath'];
  }

  Entry.mixNode(Map m, Node n) {
    this.size = m['size'];
    this.ctime = m['ctime'];
    this.mtime = m['mtime'];
    this.name = m['name'];
    this.uuid = m['uuid'];
    this.type = m['type'];
    this.hash = m['hash'];
    this.hsize = prettySize(this.size);
    this.hmtime = prettyDate(this.mtime);
    this.metadata =
        m['metadata'] == null ? null : Metadata.fromMap(m['metadata']);
    this.pdir = n.dirUUID;
    this.pdrv = n.driveUUID;
  }
}

class DirPath {
  String uuid;
  String name;
  int mtime;
  DirPath(this.uuid, this.name, this.mtime);
  DirPath.fromMap(Map m) {
    this.mtime = m['mtime'];
    this.name = m['name'];
    this.uuid = m['uuid'];
  }
}

class Node {
  String name;
  String driveUUID;
  String dirUUID;
  String tag;
  Node({this.name, this.driveUUID, this.dirUUID, this.tag});
}

// actions
class LoginAction {
  final Account data;
  LoginAction(this.data);
}

class DeviceLoginAction {
  final Device data;
  DeviceLoginAction(this.data);
}

class UpdateUserAction {
  final User data;
  UpdateUserAction(this.data);
}

class UpdateDrivesAction {
  final List<Drive> data;
  UpdateDrivesAction(this.data);
}

class UpdateApisAction {
  final Apis data;
  UpdateApisAction(this.data);
}

final deviceLoginReducer = combineReducers<Device>([
  TypedReducer<Device, DeviceLoginAction>((data, action) => action.data),
]);

final accountLoginReducer = combineReducers<Account>([
  TypedReducer<Account, LoginAction>((data, action) => action.data),
]);

final updateUserReducer = combineReducers<User>([
  TypedReducer<User, UpdateUserAction>((data, action) => action.data),
]);

final updateDriveReducer = combineReducers<List<Drive>>([
  TypedReducer<List<Drive>, UpdateDrivesAction>((data, action) => action.data),
]);

final updateApisReducer = combineReducers<Apis>([
  TypedReducer<Apis, UpdateApisAction>((data, action) => action.data),
]);

AppState appReducer(AppState state, action) {
  return AppState(
    account: accountLoginReducer(state.account, action),
    device: deviceLoginReducer(state.device, action),
    localUser: updateUserReducer(state.localUser, action),
    drives: updateDriveReducer(state.drives, action),
    apis: updateApisReducer(state.apis, action),
  );
}

AppState fakeState = AppState(
  account: Account(
    token:
        '1@eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjY5NDc2NjdhLWY4ZmYtNDk4Yy1iMGNiLWViYzRkOTc3MTVkNyIsInBhc3N3b3JkIjoiKjg0QUFDMTJGNTRBQjY2NkVDRkMyQTgzQzY3NjkwOEM4QkJDMzgxQjEiLCJjbGllbnRJZCI6ImZsdXR0ZXJfVGVzdCIsInR5cGUiOiJBbmRyb2lkIn0.kiODgW5nfxnQylcUSgRHChEA8DV8SzL7FCkQ115tDBo',
    nickName: '斯德哥尔摩',
    username: '18817301665',
    avatarUrl:
        "https://wisnuc.s3.cn-north-1.amazonaws.com.cn/avatar/8a35501b-4d99-4830-95b8-649233d59658",
    id: "6947667a-f8ff-498c-b0cb-ebc4d97715d7",
    mail: "xu.kang@winsuntech.cn",
  ),
  device: Device(deviceName: 'Fake winas'),
  localUser: null,
  drives: [
    Drive(tag: 'home', uuid: "15a5b6d7-74da-4a0f-bdd7-64ecad6498aa"),
    Drive(tag: 'built-in', uuid: "6afcf55e-8482-4542-a33d-4791a7277f96"),
  ],
  apis: new Apis(
      '0@eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjY5NDc2NjdhLWY4ZmYtNDk4Yy1iMGNiLWViYzRkOTc3MTVkNyIsInBhc3N3b3JkIjoiKjg0QUFDMTJGNTRBQjY2NkVDRkMyQTgzQzY3NjkwOEM4QkJDMzgxQjEiLCJjbGllbnRJZCI6ImZsdXR0ZXJfVGVzdCIsInR5cGUiOiJBbmRyb2lkIn0.9cwn6OHlNfwQAQR7DciV9E2DPIcl-yWGBfvpdWUluaM',
      "10.10.9.234",
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1dWlkIjoiY2NmMmJlYzQtOTk2ZC00OTUyLTllNmMtZjRmOTBiNjBkODEwIiwid2luYXNVc2VySWQiOiI2OTQ3NjY3YS1mOGZmLTQ5OGMtYjBjYi1lYmM0ZDk3NzE1ZDciLCJ0aW1lc3RhbXAiOjE1NDgyMjU0ODI2NzB9.qYZv8CyLUxxNu0UrMsx7Y-4wkhW64sv1cE5Qu2JYJus',
      "6947667a-f8ff-498c-b0cb-ebc4d97715d7",
      false,
      "test_b44-a529-4dcf-aa30-240a151d8e03",
      'cookie'),
);

class AppState {
  final Account account;
  final Device device;
  final User localUser;
  final List<Drive> drives;
  final Apis apis;
  AppState({
    this.account,
    this.device,
    this.localUser,
    this.drives,
    this.apis,
  });

  factory AppState.initial() => new AppState(
      account: null, device: null, localUser: null, drives: [], apis: null);

  factory AppState.autologin() => fakeState;
}
