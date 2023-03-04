import 'package:easyorder/models/order_status.dart';

class OrderFilterModel {
  OrderFilterModel({required this.status});

  final OrderStatus status;

  @override
  String toString() {
    return 'OrderFilter{status: $status}';
  }
}
