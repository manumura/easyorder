import 'package:flutter/material.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/widgets/categories/category_list_tile.dart';

class CategoryList extends StatelessWidget {
  CategoryList({required this.categories});

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No category found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10.0),
      itemBuilder: (BuildContext context, int index) {
        final CategoryModel category = categories[index];
        return CategoryListTile(
            key: ValueKey<String?>(category.uuid), category: category);
      },
      itemCount: categories.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}
