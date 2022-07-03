import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/models/json_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_model.g.dart';

@JsonSerializable()
class CustomerModel implements JsonObject {
  CustomerModel({
    this.id,
    this.uuid,
    required this.name,
    this.address,
    this.phoneNumber,
    this.userEmail,
    this.userId,
    required this.active,
  });

  factory CustomerModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final Map<String, dynamic> json = snapshot.data()!;
    json['id'] = snapshot.id;
    return CustomerModel.fromJson(json);
  }

  factory CustomerModel.clone(CustomerModel customer) {
    return CustomerModel(
      id: customer.id,
      uuid: customer.uuid,
      name: customer.name,
      address: customer.address,
      phoneNumber: customer.phoneNumber,
      userEmail: customer.userEmail,
      userId: customer.userId,
      active: customer.active,
    );
  }

  @override
  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);

  String? id;
  String? uuid;
  String name;
  String? address;
  String? phoneNumber;
  String? userEmail;
  String? userId;
  bool active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModel &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid &&
          name == other.name;

  @override
  int get hashCode => uuid.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Customer{id: $id, uuid: $uuid, name: $name}';
  }
}
