import 'package:json_annotation/json_annotation.dart';

part 'drive.g.dart';
@JsonSerializable()
class Drive {
    Drive();

    String uuid;
    String type;
    String tag;
    bool privacy;
    String owner;
    String label;
    bool smb;
    Map<String,dynamic> client;
    num ctime;
    num mtime;
    bool isDeleted;
    
    factory Drive.fromJson(Map<String,dynamic> json) => _$DriveFromJson(json);
    Map<String, dynamic> toJson() => _$DriveToJson(this);
}
