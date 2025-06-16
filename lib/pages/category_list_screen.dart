import 'package:easyorder/bloc/category_bloc.dart';
import 'package:easyorder/pages/category_edit_screen.dart';
import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/categories/category_paginated_list.dart';
import 'package:easyorder/widgets/search/category_search_delegate.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:easyorder/widgets/ui_elements/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CategoryListScreen extends HookConsumerWidget {
  const CategoryListScreen({super.key});

  static const String routeName = '/categories';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String pageTitle = 'Categories';
    final AsyncValue<CategoryBloc?> categoryBloc$ =
        ref.watch(categoryBlocProvider);
    return categoryBloc$.when(
      data: (CategoryBloc? categoryBloc) {
        if (categoryBloc == null) {
          return _buildErrorScreen(pageTitle, 'No category found');
        }
        return _buildScreen(context, pageTitle, categoryBloc);
      },
      loading: () {
        return _buildLoadingScreen(pageTitle);
      },
      error: (Object err, StackTrace? stack) => Center(
        child: _buildErrorScreen(pageTitle, err),
      ),
    );
  }

  Widget _buildLoadingScreen(String pageTitle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(child: AdaptiveProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(String pageTitle, Object err) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildScreen(
      BuildContext context, String pageTitle, CategoryBloc categoryBloc) {
    return SafeArea(
      child: Scaffold(
        drawer: SideDrawer(),
        appBar: AppBar(
          title: Text(pageTitle),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            _buildChip(context, categoryBloc),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => showSearch<List<Widget>?>(
                  context: context,
                  delegate: CategorySearchDelegate(categoryBloc: categoryBloc)),
            ),
          ],
        ),
        body: CategoryPaginatedList(),
        bottomNavigationBar: BottomAppBar(
          elevation: 10.0,
          color: Theme.of(context).secondaryHeaderColor,
          height: navigationBarThemeData.height,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings:
                    const RouteSettings(name: CategoryEditScreen.routeName),
                builder: (BuildContext context) => const CategoryEditScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, CategoryBloc categoryBloc) {
    return StreamBuilder<int?>(
      stream: categoryBloc.count(),
      builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
        if (snapshot.hasError) {
          return Chip(
            label: const Text('0'),
            labelStyle: const TextStyle(
              color: Colors.white,
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: AdaptiveProgressIndicator(),
          );
        }

        final String count = '${snapshot.data}';
        return Chip(
          label: Text(count),
          labelStyle: const TextStyle(
            color: Colors.white,
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        );
      },
    );
  }
}
