import 'package:easyorder/models/json_object.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_cache_model.g.dart';

class LocalCacheModel {
  LocalCacheModel({
    required this.value,
    required this.timeToLiveInSeconds,
  });

  final Object value;

  final int timeToLiveInSeconds;

  @override
  String toString() {
    return 'LocalCacheModel{value: $value, timeToLiveInSeconds: $timeToLiveInSeconds}';
  }
}

@JsonSerializable(explicitToJson: true)
class JsonLocalCacheModel implements JsonObject {
  JsonLocalCacheModel({
    required this.value,
    required this.expirationDate,
  });

  @override
  factory JsonLocalCacheModel.fromJson(Map<String, dynamic> json) =>
      _$JsonLocalCacheModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$JsonLocalCacheModelToJson(this);

  final Object value;

  @JsonKey(fromJson: _parseDateTime)
  final DateTime expirationDate;

  static DateTime _parseDateTime(String d) => DateTime.parse(d);

  @override
  String toString() {
    return 'JsonLocalCacheModel{value: $value, expirationDate: $expirationDate}';
  }
}
