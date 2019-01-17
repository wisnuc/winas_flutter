// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vEntry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VEntry _$VEntryFromJson(Map<String, dynamic> json) {
  return VEntry()
    ..uuid = json['uuid'] as String
    ..type = json['type'] as String
    ..name = json['name'] as String
    ..mtime = json['mtime'] as num
    ..size = json['size'] as num
    ..hash = json['hash'] as String
    ..metadata = json['metadata'] as Map<String, dynamic>;
}

Map<String, dynamic> _$VEntryToJson(VEntry instance) => <String, dynamic>{
      'uuid': instance.uuid,
      'type': instance.type,
      'name': instance.name,
      'mtime': instance.mtime,
      'size': instance.size,
      'hash': instance.hash,
      'metadata': instance.metadata
    };
