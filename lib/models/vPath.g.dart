// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vPath.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VPath _$VPathFromJson(Map<String, dynamic> json) {
  return VPath()
    ..uuid = json['uuid'] as String
    ..name = json['name'] as String
    ..mtime = json['mtime'] as num;
}

Map<String, dynamic> _$VPathToJson(VPath instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'mtime': instance.mtime
    };
