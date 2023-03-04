import 'package:easyorder/models/product_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_paginated_list_state.freezed.dart';

@freezed
class ProductPaginatedListState with _$ProductPaginatedListState {
  const factory ProductPaginatedListState.initial() =
      ProductPaginatedListStateInitial;
  const factory ProductPaginatedListState.loading() =
      ProductPaginatedListStateLoading;
  const factory ProductPaginatedListState.loaded(
      {required List<ProductModel> products,
      required bool hasNoMoreItemToLoad}) = ProductPaginatedListStateLoaded;
  const factory ProductPaginatedListState.error(
      {required String message,
      Object? error}) = ProductPaginatedListStateError;
}
