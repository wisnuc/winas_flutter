// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User()
    ..uuid = json['uuid'] as String
    ..username = json['username'] as String
    ..isFirstUser = json['isFirstUser'] as bool
    ..password = json['password'] as bool
    ..smbPassword = json['smbPassword'] as bool
    ..status = json['status'] as String
    ..phoneNumber = json['phoneNumber'] as String
    ..winasUserId = json['winasUserId'] as String
    ..avatarUrl = json['avatarUrl'] as String;
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'username': instance.username,
      'isFirstUser': instance.isFirstUser,
      'password': instance.password,
      'smbPassword': instance.smbPassword,
      'status': instance.status,
      'phoneNumber': instance.phoneNumber,
      'winasUserId': instance.winasUserId,
      'avatarUrl': instance.avatarUrl
    };
