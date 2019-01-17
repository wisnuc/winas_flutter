import 'package:json_annotation/json_annotation.dart';

part 'vPath.g.dart';
@JsonSerializable()
class VPath {
    VPath();

    String uuid;
    String name;
    num mtime;
    
    factory VPath.fromJson(Map<String,dynamic> json) => _$VPathFromJson(json);
    Map<String, dynamic> toJson() => _$VPathToJson(this);
}
