import 'package:easyorder/models/category_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_paginated_list_state.freezed.dart';

@freezed
sealed class CategoryPaginatedListState with _$CategoryPaginatedListState {
  const factory CategoryPaginatedListState.initial() =
      CategoryPaginatedListStateInitial;
  const factory CategoryPaginatedListState.loading() =
      CategoryPaginatedListStateLoading;
  const factory CategoryPaginatedListState.loaded(
      {required List<CategoryModel> categories,
      required bool hasNoMoreItemToLoad}) = CategoryPaginatedListStateLoaded;
  const factory CategoryPaginatedListState.error(
      {required String message,
      Object? error}) = CategoryPaginatedListStateError;
}
