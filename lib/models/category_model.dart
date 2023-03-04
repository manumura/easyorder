import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/models/json_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel implements JsonObject {
  CategoryModel({
    this.id,
    this.uuid,
    required this.name,
    this.description,
    this.imageUrl,
    this.userEmail,
    this.userId,
    this.imagePath,
    required this.active,
  });

  factory CategoryModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final Map<String, dynamic> json = snapshot.data()!;
    json['id'] = snapshot.id;
    return CategoryModel.fromJson(json);
  }

  factory CategoryModel.clone(CategoryModel category) {
    return CategoryModel(
      id: category.id,
      uuid: category.uuid,
      name: category.name,
      description: category.description,
      imagePath: category.imagePath,
      imageUrl: category.imageUrl,
      userEmail: category.userEmail,
      userId: category.userId,
      active: category.active,
    );
  }

  @override
  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  String? id;
  String? uuid;
  String name;
  String? description;
  String? imageUrl;
  String? imagePath;
  String? userEmail;
  String? userId;
  bool active;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;
  // && name == other.name;

  @override
  int get hashCode => uuid.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, uuid: $uuid, name: $name}';
  }
}
