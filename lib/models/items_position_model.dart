class ItemsPositionModel {
  ItemsPositionModel({required this.min, required this.max});

  int? min;
  int? max;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemsPositionModel &&
          runtimeType == other.runtimeType &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => min.hashCode ^ max.hashCode;

  @override
  String toString() {
    return 'ItemsPositionModel {min: $min, max: $max}';
  }
}
