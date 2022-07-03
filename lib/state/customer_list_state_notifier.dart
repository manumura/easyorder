import 'package:easyorder/bloc/customer_bloc.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/state/customer_paginated_list_state.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class CustomerListStateNotifier
    extends StateNotifier<CustomerPaginatedListState> {
  CustomerListStateNotifier(this.customerBloc,
      [CustomerPaginatedListState? state])
      : super(state ?? const CustomerPaginatedListState.initial());

  final CustomerBloc? customerBloc;

  final Logger logger = getLogger();
  final List<CustomerModel> _customers = <CustomerModel>[];

  void init({required int pageSize}) async {
    if (customerBloc == null) {
      logger.e('customerBloc is null');
      return;
    }

    // state = const CustomerPaginatedListState.loading();

    final List<CustomerModel> customers =
        await customerBloc!.find(pageSize: pageSize);

    _customers.clear();
    _customers.addAll(customers);

    state = CustomerPaginatedListState.loaded(
      customers: customers,
      hasNoMoreItemToLoad: false,
    );
  }

  void paginate({
    required int pageSize,
  }) async {
    if (customerBloc == null) {
      logger.e('customerBloc is null');
      return;
    }

    final List<CustomerModel> customers = <CustomerModel>[];
    if (_customers.isEmpty) {
      final List<CustomerModel> newCustomers = await customerBloc!.find(
        pageSize: pageSize,
      );
      customers.addAll(newCustomers);
    } else {
      final CustomerModel lastCustomer = _customers[_customers.length - 1];
      final List<CustomerModel> newCustomers = await customerBloc!.find(
        pageSize: pageSize,
        lastCustomer: lastCustomer,
      );
      customers.addAll(newCustomers);
    }

    final List<CustomerModel> newCustomers = <CustomerModel>[
      ..._customers,
      ...customers,
    ];

    _customers.clear();
    _customers.addAll(newCustomers);

    state = CustomerPaginatedListState.loaded(
      customers: newCustomers,
      hasNoMoreItemToLoad: customers.isEmpty,
    );
  }

  Future<CustomerModel?> add({required CustomerModel customer}) async {
    if (customerBloc == null) {
      logger.e('customerBloc is null');
      return null;
    }

    final CustomerModel? customerCreated =
        await customerBloc!.create(customer: customer);
    final List<CustomerModel> newCustomers = <CustomerModel>[
      ..._customers,
    ];

    if (customerCreated != null) {
      newCustomers.add(customerCreated);
      newCustomers.sort(_compare());

      _customers.clear();
      _customers.addAll(newCustomers);
    }

    state = CustomerPaginatedListState.loaded(
      customers: newCustomers,
      hasNoMoreItemToLoad: false,
    );

    return customerCreated;
  }

  Future<CustomerModel?> edit({
    required String customerId,
    required CustomerModel customer,
  }) async {
    if (customerBloc == null) {
      logger.e('customerBloc is null');
      return null;
    }

    final CustomerModel? customerUpdated =
        await customerBloc!.update(customerId: customerId, customer: customer);
    final List<CustomerModel> newCustomers = <CustomerModel>[];

    if (customerUpdated != null) {
      newCustomers.addAll(<CustomerModel>[
        for (final CustomerModel c in _customers)
          if (c.uuid == customerUpdated.uuid) customerUpdated else c,
      ]);
    } else {
      newCustomers.addAll(_customers);
    }

    newCustomers.sort(_compare());
    _customers.clear();
    _customers.addAll(newCustomers);

    state = CustomerPaginatedListState.loaded(
      customers: newCustomers,
      hasNoMoreItemToLoad: false,
    );

    return customerUpdated;
  }

  Future<CustomerModel?> toggleActive({
    required String customerId,
    required bool active,
  }) async {
    if (customerBloc == null) {
      logger.e('customerBloc is null');
      return null;
    }

    final CustomerModel? customerUpdated = await customerBloc!
        .toggleActive(customerId: customerId, active: active);
    final List<CustomerModel> newCustomers = <CustomerModel>[];

    if (customerUpdated != null) {
      newCustomers.addAll(<CustomerModel>[
        for (final CustomerModel c in _customers)
          if (c.uuid == customerUpdated.uuid) customerUpdated else c,
      ]);
    } else {
      newCustomers.addAll(_customers);
    }

    newCustomers.sort(_compare());
    _customers.clear();
    _customers.addAll(newCustomers);

    state = CustomerPaginatedListState.loaded(
      customers: newCustomers,
      hasNoMoreItemToLoad: false,
    );

    return customerUpdated;
  }

  Future<bool> remove({required CustomerModel customerToRemove}) async {
    if (customerBloc == null) {
      logger.e('customerBloc is null');
      return false;
    }

    if (customerToRemove.id == null || customerToRemove.uuid == null) {
      logger.e('Customer id or uuid is null');
      return false;
    }

    final bool success = await customerBloc!.delete(
        customerId: customerToRemove.id!, customerUuid: customerToRemove.uuid!);

    final List<CustomerModel> newCustomers = _customers
        .where((CustomerModel c) => c.uuid != customerToRemove.uuid)
        .toList();

    _customers.clear();
    _customers.addAll(newCustomers);

    state = CustomerPaginatedListState.loaded(
      customers: newCustomers,
      hasNoMoreItemToLoad: false,
    );

    return success;
  }

  int Function(CustomerModel a, CustomerModel b) _compare() {
    return (CustomerModel a, CustomerModel b) {
      return a.name.compareTo(b.name);
    };
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE CustomerListStateNotifier ***');
    if (mounted) {
      super.dispose();
    }
  }
}
