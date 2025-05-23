import 'package:easyorder/shared/constants.dart';
import 'package:flutter/material.dart';

class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    this.color,
  });

  final double? price;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final String formattedPrice = currencyFormat.format(price);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Text(
        formattedPrice,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.0,
        ),
      ),
    );
  }
}
