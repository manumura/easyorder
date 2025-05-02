import 'package:json_annotation/json_annotation.dart';

enum OrderStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.pending:
        return 'pending';
    }
  }
}
