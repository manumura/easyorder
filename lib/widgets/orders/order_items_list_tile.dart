import 'package:flutter/material.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/widgets/orders/price_tag.dart';

class OrderItemsListTile extends StatelessWidget {
  const OrderItemsListTile({super.key, required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final ProductModel product = item.product;
    final double itemTotalPrice = product.price * item.quantity;

    return ListTile(
      dense: true,
      title: Text(
        product.name,
        style: const TextStyle(fontSize: 14.0),
      ),
      leading: Text(
        '${item.quantity} x',
        style: const TextStyle(fontSize: 14.0),
      ),
      trailing: PriceTag(
        price: itemTotalPrice,
      ),
      visualDensity: VisualDensity.compact,
    );
//    return Text('$item');
  }
}
