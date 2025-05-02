import 'package:easyorder/models/customer_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_paginated_list_state.freezed.dart';

@freezed
sealed class CustomerPaginatedListState with _$CustomerPaginatedListState {
  const factory CustomerPaginatedListState.initial() =
      CustomerPaginatedListStateInitial;
  const factory CustomerPaginatedListState.loading() =
      CustomerPaginatedListStateLoading;
  const factory CustomerPaginatedListState.loaded(
      {required List<CustomerModel> customers,
      required bool hasNoMoreItemToLoad}) = CustomerPaginatedListStateLoaded;
  const factory CustomerPaginatedListState.error(
      {required String message,
      Object? error}) = CustomerPaginatedListStateError;
}
