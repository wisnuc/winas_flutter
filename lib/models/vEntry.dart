import 'package:json_annotation/json_annotation.dart';

part 'vEntry.g.dart';
@JsonSerializable()
class VEntry {
    VEntry();

    String uuid;
    String type;
    String name;
    num mtime;
    num size;
    String hash;
    Map<String,dynamic> metadata;
    
    factory VEntry.fromJson(Map<String,dynamic> json) => _$VEntryFromJson(json);
    Map<String, dynamic> toJson() => _$VEntryToJson(this);
}
