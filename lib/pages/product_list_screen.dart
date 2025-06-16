import 'package:easyorder/bloc/product_bloc.dart';
import 'package:easyorder/pages/product_edit_screen.dart';
import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/products/product_paginated_list.dart';
import 'package:easyorder/widgets/search/product_search_delegate.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:easyorder/widgets/ui_elements/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProductListScreen extends HookConsumerWidget {
  const ProductListScreen({super.key});

  static const String routeName = '/products';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String pageTitle = 'Products';
    final AsyncValue<ProductBloc?> productBloc$ =
        ref.watch(productBlocProvider);
    return productBloc$.when(
      data: (ProductBloc? productBloc) {
        if (productBloc == null) {
          return _buildErrorScreen(pageTitle, 'No product found');
        }
        return _buildScreen(context, pageTitle, productBloc);
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
      BuildContext context, String pageTitle, ProductBloc productBloc) {
    return SafeArea(
      child: Scaffold(
        drawer: SideDrawer(),
        appBar: AppBar(
          title: const Text('Products'),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            _buildChip(context, productBloc),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                await showSearch<List<Widget>?>(
                  context: context,
                  delegate: ProductSearchDelegate(productBloc: productBloc),
                );
              },
            ),
          ],
        ),
        body: ProductPaginatedList(),
        bottomNavigationBar: BottomAppBar(
          elevation: 10.0,
          color: Theme.of(context).secondaryHeaderColor,
          height: navigationBarThemeData.height,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
                settings:
                    const RouteSettings(name: ProductEditScreen.routeName),
                builder: (BuildContext context) => ProductEditScreen()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, ProductBloc productBloc) {
    return StreamBuilder<int?>(
      stream: productBloc.count(),
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
