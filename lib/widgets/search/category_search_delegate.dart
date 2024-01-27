import 'package:flutter/material.dart';
import 'package:easyorder/bloc/category_bloc.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/widgets/categories/category_list.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';

class CategorySearchDelegate extends SearchDelegate<List<Widget>?> {
  CategorySearchDelegate({required this.categoryBloc});

  final CategoryBloc categoryBloc;

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
    final Future<List<CategoryModel>> categoriesFuture =
        _findCategoriesByName(query);
    return FutureBuilder<List<CategoryModel>>(
      future: categoriesFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<CategoryModel>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(
            child: AdaptiveProgressIndicator(),
          );
        }

        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No category found !'));
        }

        return CategoryList(categories: snapshot.data!);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Future<List<CategoryModel>> _findCategoriesByName(String query) async {
    return categoryBloc.findByName(name: query);
  }
}
