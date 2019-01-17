import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';
@JsonSerializable()
class User {
    User();

    String uuid;
    String username;
    bool isFirstUser;
    bool password;
    bool smbPassword;
    String status;
    String phoneNumber;
    String winasUserId;
    String avatarUrl;
    
    factory User.fromJson(Map<String,dynamic> json) => _$UserFromJson(json);
    Map<String, dynamic> toJson() => _$UserToJson(this);
}
