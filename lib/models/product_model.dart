import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/json_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel implements JsonObject {
  // extends Equatable {

  ProductModel({
    this.id,
    this.uuid,
    required this.name,
    this.category,
    this.description,
    required this.price,
    this.imageUrl,
    this.userEmail,
    this.userId,
    this.imagePath,
    required this.active,
  }) : assert(description != null);
//      : super([id, title, category, description, price, image, userEmail, userId, imagePath]);

  factory ProductModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final Map<String, dynamic> json = snapshot.data()!;
    json['id'] = snapshot.id;
    final double? price = double.tryParse(json['price'].toString());
    json['price'] = price;
    return ProductModel.fromJson(json);
  }

  factory ProductModel.clone(ProductModel product) {
    return ProductModel(
      id: product.id,
      uuid: product.uuid,
      name: product.name,
      description: product.description,
      category: product.category,
      price: product.price,
      imagePath: product.imagePath,
      imageUrl: product.imageUrl,
      userEmail: product.userEmail,
      userId: product.userId,
      active: product.active,
    );
  }

  @override
  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  String? id;
  String? uuid;
  String name;
  CategoryModel? category;
  String? description;
  double price;
  String? imageUrl;
  String? imagePath;
  String? userEmail;
  String? userId;
  bool active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;
//          && name == other.name;

  @override
  int get hashCode => uuid.hashCode; // ^ name.hashCode;

  @override
  String toString() {
    return 'Product{uuid: $uuid, name: $name}';
  }
}
