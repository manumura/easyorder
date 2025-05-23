import 'package:easyorder/models/config.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/state/customer_list_state_notifier.dart';
import 'package:easyorder/state/customer_paginated_list_state.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/customers/customer_slidable_list_tile.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class CustomerPaginatedList extends ConsumerStatefulWidget {
  const CustomerPaginatedList({super.key});

  @override
  ConsumerState<CustomerPaginatedList> createState() =>
      _CustomerPaginatedListState();
}

class _CustomerPaginatedListState extends ConsumerState<CustomerPaginatedList> {
  late CustomerListStateNotifier customerListStateNotifier;
  late int _pageSize;

  final Logger logger = getLogger();

  @override
  void initState() {
    super.initState();

    final Config? config = ref.read(configProvider);
    _pageSize = config?.pageSize ?? defaultPageSize;

    customerListStateNotifier =
        ref.read(customerListStateNotifierProvider.notifier);
    // Init customers list
    customerListStateNotifier.init(pageSize: _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final CustomerPaginatedListState state =
        ref.watch(customerListStateNotifierProvider);

    return switch (state) {
      CustomerPaginatedListStateInitial() => _buildLoadingIndicator(),
      CustomerPaginatedListStateLoading() => _buildLoadingIndicator(),
      CustomerPaginatedListStateLoaded(
        :List<CustomerModel> customers,
        :bool hasNoMoreItemToLoad
      ) =>
        _buildList(customers, hasNoMoreItemToLoad),
      CustomerPaginatedListStateError(:String message, error: Object? _) =>
        Center(
          child: Text(message),
        ),
    };
  }

  Widget _buildList(List<CustomerModel> customers, bool hasNoMoreItemToLoad) {
    if (customers.isEmpty) {
      return const Center(
        child: Text('No customer found'),
      );
    }

    final int itemCount =
        hasNoMoreItemToLoad ? customers.length : customers.length + 1;

    return RefreshIndicator(
      onRefresh: () async {
        customerListStateNotifier.init(pageSize: _pageSize);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(10.0),
        separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (index >= customers.length && !hasNoMoreItemToLoad) {
            customerListStateNotifier.paginate(pageSize: _pageSize);
            return _buildLoadingIndicator();
          }

          final CustomerModel customer = customers[index];
          return CustomerSlidableListTile(
              key: ValueKey<String?>(customer.uuid), customer: customer);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: AdaptiveProgressIndicator(),
    );
  }
}
