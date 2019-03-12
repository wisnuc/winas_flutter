import 'dart:convert';
import 'dart:typed_data';
import 'package:redux/redux.dart';
import 'package:photo_manager/photo_manager.dart';

import '../common/utils.dart';
import '../common/request.dart';
import '../common/stationApis.dart';

/// User account data
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
    this.nickName = m['nickName'] ?? m['username'];
    this.username = m['username'];
    this.avatarUrl = m['avatarUrl'];
    this.id = m['id'];
    this.mail = m['mail'];
  }

  void updateNickName(String name) {
    this.nickName = name;
  }

  void updateAvatar(String url) {
    this.avatarUrl = url;
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'token': token,
      'nickName': nickName,
      'username': username,
      'avatarUrl': avatarUrl,
      'id': id,
      'mail': mail,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
}

/// response of station list
class Station {
  String sn;
  String type;
  int online;
  bool isOnline;
  String onlineTime;
  String offlineTime;
  String lanIp;
  String name;
  String time;
  bool isOwner;

  Station.fromMap(Map m, {bool isOwner: true}) {
    this.sn = m['sn'];
    this.type = m['type'];
    this.online = m['online'];
    this.isOnline = m['online'] == 1;
    this.onlineTime = m['onlineTime'];
    this.offlineTime = m['offlineTime'];
    this.lanIp = m['LANIP'];
    this.name = m['name'];
    this.time = m['time'];
    this.isOwner = isOwner;
  }
}

/// current logged device
class Device {
  String deviceSN;
  String deviceName;
  String lanIp;
  String lanToken;
  Device({this.deviceSN, this.deviceName, this.lanIp, this.lanToken});
  Device.fromMap(Map m) {
    this.deviceSN = m['deviceSN'];
    this.deviceName = m['deviceName'];
    this.lanIp = m['lanIp'];
    this.lanToken = m['lanToken'];
  }
  @override
  String toString() {
    Map<String, dynamic> m = {
      'deviceSN': deviceSN,
      'deviceName': deviceName,
      'lanIp': lanIp,
      'lanToken': lanToken,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
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

  @override
  String toString() {
    Map<String, dynamic> m = {
      'uuid': uuid,
      'username': username,
      'isFirstUser': isFirstUser,
      'status': status,
      'phoneNumber': phoneNumber,
      'winasUserId': winasUserId,
      'avatarUrl': avatarUrl,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
}

class DriveClient {
  String id;

  bool disabled;
  int lastBackupTime;

  /// Idle, Working, Failed
  String status;

  /// Win-PC, Linux-PC, Mac-PC, iOS, Android
  String type;

  DriveClient({this.type});

  DriveClient.fromMap(Map m) {
    this.id = m['id'];
    this.status = m['status'];
    this.disabled = m['disabled'];
    this.lastBackupTime = m['lastBackupTime'];
    this.type = m['type'];
  }
  @override
  String toString() {
    Map<String, dynamic> m = {
      'id': id,
      'status': status,
      'disabled': disabled,
      'lastBackupTime': lastBackupTime,
      'type': type,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
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
  int dirCount = 0;
  int fileCount = 0;
  String fileTotalSize = '';
  DriveClient client;
  Drive({this.uuid, this.tag, this.type, this.label, this.client});
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
    this.client = (m['client'] == 'null' || m['client'] == null)
        ? null
        : DriveClient.fromMap(
            m['client'] is String ? jsonDecode(m['client']) : m['client']);
  }

  void updateStats(Map s) {
    this.dirCount = s['dirCount'];
    this.fileCount = s['fileCount'];
    this.fileTotalSize = prettySize(s['fileTotalSize']);
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'uuid': uuid,
      'type': type,
      'client': client.toString(),
      'label': label,
      'tag': tag,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
}

class Metadata {
  String type;
  String datetime;
  String hdate;
  Metadata.fromMap(Map m) {
    this.type = m['type'];
    this.datetime = m['date'];
    try {
      // only allow format: "2017:06:17 17:31:18", Res: 2017-06-17
      if (this.datetime != null &&
          !this.datetime.startsWith('0') &&
          this.datetime.split(':').length == 5) {
        this.hdate = this.datetime.split(' ')[0].replaceAll(':', '-');
      }
    } catch (err) {
      this.hdate = null;
      print(err);
    }
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'type': type,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
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
  String location;

  /// photo token date
  String hdate;
  List namepath;
  Metadata metadata;
  bool selected = false;
  Entry({this.name, this.uuid, this.type, this.pdir, this.pdrv});
  Entry.fromMap(Map m) {
    this.size = m['size'] ?? 0;
    this.ctime = m['ctime'] ?? 0;
    this.mtime = m['mtime'] ?? 0;
    this.name = m['bname'] ?? m['name'];
    this.uuid = m['uuid'];
    this.type = m['type'];
    this.hash = m['hash'];
    this.hsize = prettySize(this.size);
    this.hmtime = prettyDate(this.mtime);
    this.location = m['location'];
    this.pdir = m['pdir'];
    this.pdrv = m['pdrv'];
    this.metadata = (m['metadata'] == 'null' || m['metadata'] == null)
        ? null
        : Metadata.fromMap(m['metadata'] is String
            ? jsonDecode(m['metadata'])
            : m['metadata']);
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'size': size,
      'ctime': ctime,
      'mtime': mtime,
      'name': name,
      'uuid': uuid,
      'type': type,
      'hash': hash,
      'pdir': pdir,
      'pdrv': pdrv,
      'location': location,
      'namepath': namepath,
      'metadata': metadata,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();

  Entry.fromSearch(Map m, List<Drive> d) {
    this.size = m['size'] ?? 0;
    this.ctime = m['ctime'] ?? 0;
    this.mtime = m['mtime'] ?? 0;
    this.name = m['name'];
    this.uuid = m['uuid'];
    this.type = 'file';
    this.hash = m['hash'];
    this.hsize = prettySize(this.size);
    this.hmtime = prettyDate(this.mtime);
    this.metadata =
        m['metadata'] == null ? null : Metadata.fromMap(m['metadata']);
    this.pdir = m['pdir'];
    this.namepath = m['namepath'];
    Drive drive = d[m['place']];
    this.pdrv = drive.uuid;
    this.location = drive.type ?? drive.tag;

    this.hdate = this.metadata?.hdate ?? prettyDate(this.mtime, date: true);
  }

  Entry.mixNode(Map m, Node n) {
    this.size = m['size'] ?? 0;
    this.ctime = m['ctime'] ?? 0;
    this.mtime = m['mtime'] ?? 0;
    this.name = m['bname'] ?? m['name'];
    this.uuid = m['uuid'];
    this.type = m['type'];
    this.hash = m['hash'];
    this.hsize = prettySize(this.size);
    this.hmtime = prettyDate(this.mtime);
    this.metadata =
        m['metadata'] == null ? null : Metadata.fromMap(m['metadata']);
    this.pdir = n.dirUUID;
    this.pdrv = n.driveUUID;
    this.location = n.location;
  }

  void select() {
    this.selected = true;
  }

  void unSelect() {
    this.selected = false;
  }

  void toggleSelect() {
    this.selected = !this.selected;
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
  String location;
  Node({this.name, this.driveUUID, this.dirUUID, this.tag, this.location});
}

class Album {
  List<Entry> items = [];
  String name;
  String places;

  // thumbData
  Uint8List cover;
  Album(this.items, this.name, this.places);
  get length => items.length;

  void setCover(thumbData) {
    this.cover = thumbData;
  }
}

class LocalAlbum {
  List<AssetEntity> items = [];
  String name;
  String places;

  // thumbData
  Uint8List cover;
  LocalAlbum(this.items, this.name);
  get length => items.length;

  void setCover(thumbData) {
    this.cover = thumbData;
  }
}

/// update Selection, and refresh(setState)
class Select {
  Function update;
  Select(this.update);
  List<Entry> selectedEntry = [];

  void toggleSelect(Entry entry) {
    if (entry.selected) {
      entry.unSelect();
      selectedEntry.remove(entry);
    } else {
      entry.select();
      selectedEntry.add(entry);
    }
    this.update();
  }

  void clearSelect() {
    for (Entry entry in selectedEntry) {
      entry.unSelect();
    }
    selectedEntry.clear();
    this.update();
  }

  void selectAll(List<Entry> entries) {
    for (Entry entry in entries) {
      entry.select();
      selectedEntry.add(entry);
    }
    this.update();
  }

  bool selectMode() => selectedEntry.length != 0;
}

/// Types of sortBy:
enum SortTypes { nameUp, nameDown, sizeUp, sizeDown, mtimeUp, mtimeDown }

class EntrySort {
  SortTypes type = SortTypes.nameUp;
  Function update;
  EntrySort(this.update);

  void changeType(SortTypes newType) {
    this.type = newType;
    print('newType $newType');
    this.update();
  }

  int sort(Entry a, Entry b) {
    if (a.type != b.type) {
      return a.type.compareTo(b.type);
    }

    switch (type) {
      case SortTypes.nameUp:
        return a.name.compareTo(b.name);

      case SortTypes.nameDown:
        return b.name.compareTo(a.name);

      case SortTypes.mtimeUp:
        return a.mtime.compareTo(b.mtime);

      case SortTypes.mtimeDown:
        return b.mtime.compareTo(a.mtime);

      case SortTypes.sizeUp:
        return a.size.compareTo(b.size);

      case SortTypes.sizeDown:
        return b.size.compareTo(a.size);

      default:
        return 0;
    }
  }

  String getName(SortTypes value) {
    switch (value) {
      case SortTypes.sizeDown:
      case SortTypes.sizeUp:
        return '大小';

      case SortTypes.mtimeDown:
      case SortTypes.mtimeUp:
        return '修改时间';

      case SortTypes.nameDown:
      case SortTypes.nameUp:
        return '名称';

      default:
        return '';
    }
  }
}

class Config {
  bool gridView = false;

  Config({this.gridView});
  Config.combine(Config oldConfig, Config newConfig) {
    this.gridView = newConfig.gridView ?? oldConfig.gridView;
  }

  Config.fromMap(Map m) {
    this.gridView = m['gridView'];
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'gridView': gridView,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
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

class UpdateCloudAction {
  final Request data;
  UpdateCloudAction(this.data);
}

class UpdateConfigAction {
  final Config data;
  UpdateConfigAction(this.data);
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

final updateCloudReducer = combineReducers<Request>([
  TypedReducer<Request, UpdateCloudAction>((data, action) => action.data),
]);

// combine config
final updateConfigReducer = combineReducers<Config>([
  TypedReducer<Config, UpdateConfigAction>(
    (oldConfig, action) => Config.combine(oldConfig, action.data),
  ),
]);

AppState appReducer(AppState state, action) {
  return AppState(
    account: accountLoginReducer(state.account, action),
    device: deviceLoginReducer(state.device, action),
    localUser: updateUserReducer(state.localUser, action),
    drives: updateDriveReducer(state.drives, action),
    apis: updateApisReducer(state.apis, action),
    config: updateConfigReducer(state.config, action),
    cloud: updateCloudReducer(state.cloud, action),
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
    Drive(
      type: 'backup',
      uuid: "9e85bff6-1cf4-429f-a2c2-6c11e0913ab4",
      client: DriveClient(type: 'iOS'),
      label: "iPhone 8",
    ),
    Drive(
      type: 'backup',
      uuid: "860688ed-7a83-45b3-9d67-aee517e2b7e2",
      client: DriveClient(type: 'Android'),
      label: "lxw-PC",
    ),
  ],
  apis: Apis(
      '0@eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjY5NDc2NjdhLWY4ZmYtNDk4Yy1iMGNiLWViYzRkOTc3MTVkNyIsInBhc3N3b3JkIjoiKjg0QUFDMTJGNTRBQjY2NkVDRkMyQTgzQzY3NjkwOEM4QkJDMzgxQjEiLCJjbGllbnRJZCI6ImZsdXR0ZXJfVGVzdCIsInR5cGUiOiJBbmRyb2lkIn0.9cwn6OHlNfwQAQR7DciV9E2DPIcl-yWGBfvpdWUluaM',
      "10.10.9.234",
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1dWlkIjoiY2NmMmJlYzQtOTk2ZC00OTUyLTllNmMtZjRmOTBiNjBkODEwIiwid2luYXNVc2VySWQiOiI2OTQ3NjY3YS1mOGZmLTQ5OGMtYjBjYi1lYmM0ZDk3NzE1ZDciLCJ0aW1lc3RhbXAiOjE1NDgyMjU0ODI2NzB9.qYZv8CyLUxxNu0UrMsx7Y-4wkhW64sv1cE5Qu2JYJus',
      "6947667a-f8ff-498c-b0cb-ebc4d97715d7",
      false,
      "test_b44-a529-4dcf-aa30-240a151d8e03",
      'cookie'),
  config: Config(gridView: true),
  cloud: Request(),
);

class AppState {
  final Account account;
  final Device device;
  final User localUser;
  final List<Drive> drives;
  final Apis apis;
  final Config config;
  final Request cloud;
  AppState({
    this.account,
    this.device,
    this.localUser,
    this.drives,
    this.apis,
    this.config,
    this.cloud,
  });

  factory AppState.initial() => AppState(
        account: null,
        device: null,
        localUser: null,
        drives: [],
        apis: null,
        config: Config(gridView: false),
      );

  factory AppState.autologin() => fakeState;

  static AppState fromJson(dynamic json) {
    var m = jsonDecode(json);
    return AppState(
      account: m['account'] == null
          ? null
          : Account.fromMap(jsonDecode(m['account'])),
      device:
          m['device'] == null ? null : Device.fromMap(jsonDecode(m['device'])),
      localUser: m['localUser'] == null
          ? null
          : User.fromMap(jsonDecode(m['localUser'])),
      drives: List.from(
        m['drives'].map((d) => Drive.fromMap(jsonDecode(d))),
      ),
      apis: m['apis'] == null ? null : Apis.fromMap(jsonDecode(m['apis'])),
      config:
          m['config'] == null ? null : Config.fromMap(jsonDecode(m['config'])),
      cloud:
          m['cloud'] == null ? null : Request.fromMap(jsonDecode(m['cloud'])),
    );
  }

  @override
  String toString() {
    Map<String, dynamic> m = {
      'account': account,
      'device': device,
      'localUser': localUser,
      'drives': drives,
      'apis': apis,
      'config': config,
      'cloud': cloud,
    };
    return jsonEncode(m);
  }

  String toJson() => toString();
}
