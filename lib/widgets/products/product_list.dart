import 'package:flutter/material.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/widgets/products/product_list_tile.dart';

class ProductList extends StatelessWidget {
  ProductList({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(child: Text('No product found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10.0),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        return ProductListTile(product: products[index]);
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(
        height: 8,
      ),
    );
  }
}
