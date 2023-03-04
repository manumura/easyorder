import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/models/cart_model.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/models/json_object.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderModel implements JsonObject {
  OrderModel({
    this.id,
    this.uuid,
    this.number,
    required this.customer,
    required this.date,
    this.dueDate,
    this.description,
    this.cart,
    this.status,
    this.userEmail,
    this.userId,
  });

  factory OrderModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final Map<String, dynamic> json = snapshot.data()!;
    json['id'] = snapshot.id;
    json['date'] =
        json['date'] == null ? null : _convertJsonToDateTime(json['date']);
    json['dueDate'] = json['dueDate'] == null
        ? null
        : _convertJsonToDateTime(json['dueDate']);
    return OrderModel.fromJson(json);
  }

  factory OrderModel.clone(OrderModel order) {
    return OrderModel(
      id: order.id,
      uuid: order.uuid,
      number: order.number,
      customer: order.customer,
      date: order.date,
      dueDate: order.dueDate,
      description: order.description,
      cart: order.cart,
      status: order.status,
      userId: order.userId,
      userEmail: order.userEmail,
    );
  }

  @override
  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  String? id;
  String? uuid;
  String? number;
  CustomerModel customer;
  @JsonKey(fromJson: _rawDateTime)
  DateTime date;
  @JsonKey(fromJson: _rawNullableDateTime)
  DateTime? dueDate;
  String? description;
  CartModel? cart;
  @JsonKey(unknownEnumValue: OrderStatus.pending)
  OrderStatus? status;
  String? userEmail;
  String? userId;

  @override
  String toString() {
    return 'Order{id: $id, uuid: $uuid, number: $number, customer: ${customer.name}, '
        'date: $date, dueDate: $dueDate, cart: $cart, status: $status, '
        'userId: $userId, userEmail: $userEmail}';
  }

  static DateTime _rawDateTime(dynamic d) => d as DateTime;

  static DateTime? _rawNullableDateTime(dynamic d) => d as DateTime?;

  static DateTime _convertJsonToDateTime(dynamic d) {
    final Timestamp timestamp = d as Timestamp;
    final DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    return date;
  }
}
