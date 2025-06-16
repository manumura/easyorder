import 'package:flutter/material.dart';
import 'package:easyorder/bloc/product_bloc.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/widgets/products/product_list.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';

class ProductSearchDelegate extends SearchDelegate<List<Widget>?> {
  ProductSearchDelegate({required this.productBloc});

  final ProductBloc productBloc;

  @override
  String get searchFieldLabel => 'Filter by name';

  @override
  TextStyle get searchFieldStyle => const TextStyle(
        // color: Colors.primaries.first,
        fontSize: 18.0,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        color: theme.secondaryHeaderColor,
        // backgroundColor: theme.secondaryHeaderColor,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        // border: InputBorder.none,
        // Use this change the placeholder's text style
        hintStyle: TextStyle(fontSize: 18.0),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        query = '';
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final Future<List<ProductModel>> productsFuture =
        _findProductsByName(query);
    return FutureBuilder<List<ProductModel>>(
      future: productsFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<ProductModel>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(
            child: AdaptiveProgressIndicator(),
          );
        }

        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No product found !'),
          );
        }

        return ProductList(products: snapshot.data!);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Future<List<ProductModel>> _findProductsByName(String query) async {
    return productBloc.findByName(name: query);
  }
}
