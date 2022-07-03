import 'package:flutter/material.dart';
import 'package:easyorder/models/config.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/product_list_state_notifier.dart';
import 'package:easyorder/state/product_paginated_list_state.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/products/product_slidable_list_tile.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sticky_headers/sticky_headers.dart';

class ProductPaginatedList extends ConsumerStatefulWidget {
  @override
  _ProductPaginatedListState createState() => _ProductPaginatedListState();
}

class _ProductPaginatedListState extends ConsumerState<ProductPaginatedList> {
  late ProductListStateNotifier productListStateNotifier;
  late int _pageSize;

  final Logger logger = getLogger();

  @override
  void initState() {
    super.initState();

    final Config? config = ref.read(configProvider);
    _pageSize = config?.pageSize ?? defaultPageSize;

    productListStateNotifier =
        ref.read(productListStateNotifierProvider.notifier);
    // Init products list
    productListStateNotifier.init(pageSize: _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final ProductPaginatedListState state =
        ref.watch(productListStateNotifierProvider);

    return state.when(
      initial: () => _buildLoadingIndicator(),
      // const Center(
      //   child: Text('No product found'),
      // ),
      loading: () => _buildLoadingIndicator(),
      loaded: (List<ProductModel> products, bool hasNoMoreItemToLoad) {
        return _buildList(products, hasNoMoreItemToLoad);
      },
      error: (String message, Object? error) => Center(
        child: Text(message),
      ),
    );
  }

  Widget _buildList(List<ProductModel> products, bool hasNoMoreItemToLoad) {
    if (products.isEmpty) {
      return const Center(
        child: Text('No product found'),
      );
    }

    final int itemCount =
        hasNoMoreItemToLoad ? products.length : products.length + 1;

    return RefreshIndicator(
      onRefresh: () async {
        productListStateNotifier.init(pageSize: _pageSize);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(10.0),
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (index >= products.length && !hasNoMoreItemToLoad) {
            productListStateNotifier.paginate(pageSize: _pageSize);
            return _buildLoadingIndicator();
          }

          return _buildListItem(context, index, products);
        },
      ),
    );
  }

  Widget _buildListItem(
      BuildContext context, int index, List<ProductModel> products) {
    final ProductModel product = products[index];
    final ProductModel? previousProduct =
        index >= 1 ? products[index - 1] : null;
    final bool displayHeader =
        index == 0 || product.category != previousProduct?.category;

    return StickyHeader(
      header: !displayHeader
          ? const SizedBox()
          : Container(
              height: 40.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: backgroundColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                product.category == null
                    ? 'No category'
                    : product.category!.name,
                style: TextStyle(
                    color: Theme.of(context).primaryColor, fontSize: 20.0),
              ),
            ),
      content: ProductSlidableListTile(product: product),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: AdaptiveProgressIndicator(),
    );
  }
}
