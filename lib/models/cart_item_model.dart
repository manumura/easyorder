import 'package:easyorder/models/json_object.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cart_item_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItemModel implements JsonObject {
  CartItemModel({required this.product, required this.quantity});

  @override
  factory CartItemModel.fromJson(Map<String, dynamic> json) =>
      _$CartItemModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CartItemModelToJson(this);

  ProductModel product;
  int quantity;

  @override
  String toString() => '${product.name} X $quantity';
}
