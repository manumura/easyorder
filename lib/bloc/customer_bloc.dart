import 'dart:async';

import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/customer_repository.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

abstract class CustomerBloc {
  Stream<List<CustomerModel>> get activeCustomers$;

  Future<List<CustomerModel>> find({
    int? pageSize,
    CustomerModel? lastCustomer,
  });

  Stream<int?> count();

  Future<List<CustomerModel>> findByName({required String name});

  Future<CustomerModel?> create({required CustomerModel customer});

  Future<CustomerModel?> update({
    required String customerId,
    required CustomerModel customer,
  });

  Future<CustomerModel?> toggleActive({
    required String customerId,
    required bool active,
  });

  Future<bool> delete({
    required String customerId,
    required String customerUuid,
  });

  void dispose();
}

class CustomerBlocImpl implements CustomerBloc {
  CustomerBlocImpl({
    required this.user,
    required this.customerRepository,
  }) {
    logger.d('----- Building CustomerBlocImpl -----');
    final Stream<List<CustomerModel>> activeCustomers$ =
        customerRepository.findActive(userId: user.id);
    activeCustomers$.listen(
      (List<CustomerModel> customers) {
        _activeCustomersSubject.add(customers);
      },
      onError: (Object error) => logger.e('customers listen error: $error'),
      cancelOnError: false,
    );
  }
  final UserModel user;
  final CustomerRepository customerRepository;

  final Logger logger = getLogger();

  final BehaviorSubject<List<CustomerModel>> _activeCustomersSubject =
      BehaviorSubject<List<CustomerModel>>.seeded(<CustomerModel>[]);
  @override
  Stream<List<CustomerModel>> get activeCustomers$ =>
      _activeCustomersSubject.stream;

  @override
  Future<List<CustomerModel>> find({
    int? pageSize,
    CustomerModel? lastCustomer,
  }) async {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Future<List<CustomerModel>>.value(<CustomerModel>[]);
    }

    return customerRepository.find(
        userId: user.id, pageSize: pageSize, lastCustomer: lastCustomer);
  }

  @override
  Stream<int?> count() {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Stream<int>.value(0);
    }
    return customerRepository.count(userId: user.id);
  }

  @override
  Future<List<CustomerModel>> findByName({required String name}) async {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Future<List<CustomerModel>>.value(<CustomerModel>[]);
    }
    return customerRepository.findByName(userId: user.id, name: name);
  }

  @override
  Future<CustomerModel?> create({required CustomerModel customer}) async {
    logger.d('add customer, user: $user');

    if (user.id.isEmpty) {
      logger.e('No user found');
      return null;
    }

    const Uuid uuid = Uuid();

    final CustomerModel customerToCreate = CustomerModel.clone(customer);
    customerToCreate.uuid = uuid.v4();
    customerToCreate.userEmail = user.email;
    customerToCreate.userId = user.id;

    String? id = await customerRepository.create(
        userId: user.id, customer: customerToCreate);

    if (id != null) {
      customerToCreate.id = id;
      return customerToCreate;
    } else {
      return null;
    }
  }

  @override
  Future<CustomerModel?> update({
    required String customerId,
    required CustomerModel customer,
  }) async {
    logger.d('update customer: $customerId');

    if (user.id.isEmpty) {
      logger.e('No user found');
      return null;
    }

    final CustomerModel customerToUpdate = CustomerModel.clone(customer);
    final bool success = await customerRepository.update(
        userId: user.id, customerId: customerId, customer: customerToUpdate);
    return success ? customerToUpdate : null;
  }

  @override
  Future<CustomerModel?> toggleActive({
    required String customerId,
    required bool active,
  }) async {
    logger.d('customer toggle active: $customerId');

    if (user.id.isEmpty) {
      logger.e('No user found');
      return null;
    }

    return customerRepository.toggleActive(
        userId: user.id, customerId: customerId, active: active);
  }

  @override
  Future<bool> delete({
    required String customerId,
    required String customerUuid,
  }) async {
    if (user.id.isEmpty) {
      logger.e('User is null');
      return Future<bool>.value(false);
    }

    logger.d('delete customer: $customerId, user: ${user.id}');
    return customerRepository.delete(
        userId: user.id, customerId: customerId, customerUuid: customerUuid);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE CustomerBloc ***');
    _activeCustomersSubject.close();
  }
}
