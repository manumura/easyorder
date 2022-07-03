import 'dart:io';

import 'package:easyorder/bloc/product_bloc.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/state/product_paginated_list_state.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class ProductListStateNotifier
    extends StateNotifier<ProductPaginatedListState> {
  ProductListStateNotifier(this.productBloc, [ProductPaginatedListState? state])
      : super(state ?? const ProductPaginatedListState.initial());

  final ProductBloc? productBloc;

  final Logger logger = getLogger();
  final List<ProductModel> _products = <ProductModel>[];

  void init({required int pageSize}) async {
    if (productBloc == null) {
      logger.e('productBloc is null');
      return;
    }

    // state = const CategoryPaginatedListState.loading();

    final List<ProductModel> products =
        await productBloc!.find(pageSize: pageSize);

    _products.clear();
    _products.addAll(products);

    state = ProductPaginatedListState.loaded(
      products: products,
      hasNoMoreItemToLoad: false,
    );
  }

  void paginate({
    required int pageSize,
  }) async {
    if (productBloc == null) {
      logger.e('productBloc is null');
      return;
    }

    final List<ProductModel> products = <ProductModel>[];
    if (_products.isEmpty) {
      final List<ProductModel> newProducts = await productBloc!.find(
        pageSize: pageSize,
      );
      products.addAll(newProducts);
    } else {
      final ProductModel lastProduct = _products[_products.length - 1];
      final List<ProductModel> newProducts = await productBloc!.find(
        pageSize: pageSize,
        lastProduct: lastProduct,
      );
      products.addAll(newProducts);
    }

    final List<ProductModel> newProducts = <ProductModel>[
      ..._products,
      ...products,
    ];

    _products.clear();
    _products.addAll(newProducts);

    state = ProductPaginatedListState.loaded(
      products: newProducts,
      hasNoMoreItemToLoad: products.isEmpty,
    );
  }

  Future<ProductModel?> add(
      {required ProductModel product, File? image}) async {
    if (productBloc == null) {
      logger.e('productBloc is null');
      return null;
    }

    final ProductModel? productCreated =
        await productBloc!.create(product: product, image: image);
    final List<ProductModel> newProducts = <ProductModel>[
      ..._products,
    ];

    if (productCreated != null) {
      newProducts.add(productCreated);
      newProducts.sort(_compare());

      _products.clear();
      _products.addAll(newProducts);
    }

    state = ProductPaginatedListState.loaded(
      products: newProducts,
      hasNoMoreItemToLoad: false,
    );

    return productCreated;
  }

  Future<ProductModel?> edit({
    required String productId,
    required ProductModel product,
    File? image,
  }) async {
    if (productBloc == null) {
      logger.e('productBloc is null');
      return null;
    }

    final ProductModel? productUpdated = await productBloc!
        .update(productId: productId, product: product, image: image);
    final List<ProductModel> newProducts = <ProductModel>[];

    if (productUpdated != null) {
      newProducts.addAll(<ProductModel>[
        for (final ProductModel p in _products)
          if (p.uuid == productUpdated.uuid) productUpdated else p,
      ]);
    } else {
      newProducts.addAll(_products);
    }

    newProducts.sort(_compare());
    _products.clear();
    _products.addAll(newProducts);

    state = ProductPaginatedListState.loaded(
      products: newProducts,
      hasNoMoreItemToLoad: false,
    );

    return productUpdated;
  }

  Future<ProductModel?> toggleActive({
    required String productId,
    required String productUuid,
    required bool active,
  }) async {
    if (productBloc == null) {
      logger.e('productBloc is null');
      return null;
    }

    final ProductModel? productUpdated = await productBloc!.toggleActive(
      productId: productId,
      productUuid: productUuid,
      active: active,
    );
    final List<ProductModel> newProducts = <ProductModel>[];

    if (productUpdated != null) {
      newProducts.addAll(<ProductModel>[
        for (final ProductModel c in _products)
          if (c.uuid == productUpdated.uuid) productUpdated else c,
      ]);
    } else {
      newProducts.addAll(_products);
    }

    newProducts.sort(_compare());
    _products.clear();
    _products.addAll(newProducts);

    state = ProductPaginatedListState.loaded(
      products: newProducts,
      hasNoMoreItemToLoad: false,
    );

    return productUpdated;
  }

  Future<bool> remove({required ProductModel productToRemove}) async {
    if (productBloc == null) {
      logger.e('productBloc is null');
      return false;
    }

    if (productToRemove.id == null || productToRemove.uuid == null) {
      logger.e('Category id or uuid is null');
      return false;
    }

    final bool success = await productBloc!.delete(
        productId: productToRemove.id!,
        productUuid: productToRemove.uuid!,
        productImagePath: productToRemove.imagePath);

    final List<ProductModel> newProducts = _products
        .where((ProductModel p) => p.uuid != productToRemove.uuid)
        .toList();

    _products.clear();
    _products.addAll(newProducts);

    state = ProductPaginatedListState.loaded(
      products: newProducts,
      hasNoMoreItemToLoad: false,
    );

    return success;
  }

  int Function(ProductModel a, ProductModel b) _compare() {
    return (ProductModel a, ProductModel b) {
      if (a.category == null) {
        return -1;
      }

      if (b.category == null) {
        return 1;
      }

      final int compByCategory = a.category!.name.compareTo(b.category!.name);
      if (compByCategory != 0) {
        return compByCategory;
      }
      return a.name.compareTo(b.name);
    };
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE ProductListStateNotifier ***');
    if (mounted) {
      super.dispose();
    }
  }
}
