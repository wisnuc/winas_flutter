// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Drive _$DriveFromJson(Map<String, dynamic> json) {
  return Drive()
    ..uuid = json['uuid'] as String
    ..type = json['type'] as String
    ..tag = json['tag'] as String
    ..privacy = json['privacy'] as bool
    ..owner = json['owner'] as String
    ..label = json['label'] as String
    ..smb = json['smb'] as bool
    ..client = json['client'] as Map<String, dynamic>
    ..ctime = json['ctime'] as num
    ..mtime = json['mtime'] as num
    ..isDeleted = json['isDeleted'] as bool;
}

Map<String, dynamic> _$DriveToJson(Drive instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'type': instance.type,
      'tag': instance.tag,
      'privacy': instance.privacy,
      'owner': instance.owner,
      'label': instance.label,
      'smb': instance.smb,
      'client': instance.client,
      'ctime': instance.ctime,
      'mtime': instance.mtime,
      'isDeleted': instance.isDeleted
    };
