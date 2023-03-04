import 'package:easyorder/models/json_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'storage_model.g.dart';

@JsonSerializable()
class StorageModel implements JsonObject {
  StorageModel({required this.url, required this.path});

  StorageModel.clone(StorageModel storage)
      : url = storage.url,
        path = storage.path;

  @override
  factory StorageModel.fromJson(Map<String, dynamic> json) =>
      _$StorageModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StorageModelToJson(this);

  String? url;
  String? path;

  @override
  String toString() {
    return 'Storage{url: $url, path: $path}';
  }
}
