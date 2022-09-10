import 'package:flutter/material.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/widgets/orders/order_slidable_list_tile.dart';

class OrderList extends StatelessWidget {
  const OrderList({super.key, required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No order found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10.0),
      itemBuilder: (BuildContext context, int index) {
        final OrderModel order = orders[index];
        return OrderSlidableListTile(order: order);
      },
      itemCount: orders.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}
