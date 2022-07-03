import 'package:firebase_auth/firebase_auth.dart';
import 'package:easyorder/models/json_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel implements JsonObject {
  UserModel({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    required this.providerIds,
  });

  factory UserModel.fromFirebaseUser(User firebaseUser) {
    final List<String> providerIds = firebaseUser.providerData
        .map((final UserInfo userInfo) => userInfo.providerId)
        .toList();
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      isEmailVerified: firebaseUser.emailVerified,
      providerIds: providerIds, // firebase, google.com, password
    );
  }

  @override
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  final String id;
  final String? email;
  final bool isEmailVerified;
  final List<String> providerIds;

  @override
  String toString() {
    return 'User{id: $id, email: $email, isEmailVerified: $isEmailVerified}';
  }

  // bool isValid() {
  //   return !providerIds.contains('password') ||
  //       (providerIds.contains('password') && isEmailVerified);
  // }
}
