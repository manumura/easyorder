import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/exceptions/not_unique_exception.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class CustomerRepository {
  Stream<List<CustomerModel>> findActive({required String userId});

  Future<List<CustomerModel>> find({
    required String userId,
    int? pageSize,
    CustomerModel? lastCustomer,
  });

  Stream<int?> count({required String userId});

  Future<List<CustomerModel>> findByName({
    required String userId,
    String? name,
  });

  Future<String?> create({
    required String userId,
    required CustomerModel customer,
  });

  Future<bool> update({
    required String userId,
    required String customerId,
    required CustomerModel customer,
  });

  Future<CustomerModel?> toggleActive({
    required String userId,
    required String customerId,
    required bool active,
  });

  Future<bool> delete({
    required String userId,
    required String customerId,
    required String customerUuid,
  });
}

class CustomerRepositoryFirebaseImpl implements CustomerRepository {
  final FirebaseFirestore _store = FirebaseFirestore.instance;
  final Logger logger = getLogger();

  @override
  Future<List<CustomerModel>> find({
    required String userId,
    int? pageSize,
    CustomerModel? lastCustomer,
  }) async {
    logger.d('find customers: pageSize=$pageSize, lastCustomer=$lastCustomer');

    try {
      // Find documents by user id
      final CollectionReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId).collection('customers');

      Query<Map<String, dynamic>> query = ref.orderBy('name');

      if (lastCustomer != null) {
        final List<dynamic> startAt = <dynamic>[lastCustomer.name];
        query = query.startAfter(startAt);
      }

      if (pageSize != null) {
        query = query.limit(pageSize);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();

      final List<CustomerModel> customers = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              CustomerModel.fromSnapshot(documentSnapshot))
          .toList();

      return customers;
    } on Exception catch (e) {
      logger.e(e);
      return Future<List<CustomerModel>>.value(<CustomerModel>[]);
    }
  }

  @override
  Stream<int?> count({required String userId}) {
    logger.d('count customers');

    try {
      // Find documents by user id
      final DocumentReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId);
      final Stream<DocumentSnapshot<Map<String, dynamic>>> documentSnapshot$ =
          ref.snapshots();
      final Stream<int?> count$ = documentSnapshot$
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
        return documentSnapshot.data() != null
            ? int.tryParse(
                documentSnapshot.data()!['customersCount'].toString())
            : 0;
      });

      return count$;
    } on Exception catch (ex) {
      logger.e(ex);
      return Stream<int>.value(0);
    }
  }

  @override
  Stream<List<CustomerModel>> findActive({required String userId}) {
    logger.d('stream customers');

    try {
      // Find documents by user id
      final Stream<List<CustomerModel>> customers$ = _store
          .collection('users')
          .doc(userId)
          .collection('customers')
          .where('active', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
        final List<CustomerModel> customers = querySnapshot.docs
            .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
                CustomerModel.fromSnapshot(documentSnapshot))
            .toList();
        return customers;
      });

      return customers$;
    } on Exception catch (ex) {
      logger.e(ex);
      return const Stream<List<CustomerModel>>.empty();
    }
  }

  @override
  Future<List<CustomerModel>> findByName({
    required String userId,
    String? name,
  }) async {
    logger.d('find customers by name: $name');

    try {
      // Find documents by user id
      Query<Map<String, dynamic>> query = _store
          .collection('users')
          .doc(userId)
          .collection('customers')
          .orderBy('nameToUpperCase');

      if (name != null) {
        final List<dynamic> startAt = <dynamic>[name.toUpperCase()];
        final List<dynamic> endAt = <dynamic>[name.toUpperCase() + '~'];
        query = query.startAt(startAt).endAt(endAt);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();

      final List<CustomerModel> customers = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              CustomerModel.fromSnapshot(documentSnapshot))
          .toList();
      return customers;
    } on Exception catch (e) {
      logger.e(e);
      return Future<List<CustomerModel>>.value(<CustomerModel>[]);
    }
  }

  @override
  Future<String?> create({
    required String userId,
    required CustomerModel customer,
  }) async {
    if (customer.userId == null ||
        customer.userEmail == null ||
        customer.uuid == null) {
      logger.e('Invalid parameters');
      return null;
    }

    // Check name is unique
    final bool isNameUnique;
    try {
      isNameUnique =
          await _isNameUnique(userId: userId, customerName: customer.name);
    } catch (error) {
      logger.e('create customer error: $error');
      return null;
    }

    if (!isNameUnique) {
      throw NotUniqueException('This customer name is already used.');
    }

    try {
      final Map<String, dynamic> customerData = customer.toJson();
      customerData['nameToUpperCase'] = customer.name.toUpperCase();
      customerData['createdDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      logger.d('customerData: $customerData');

      // Add document by user id
      final DocumentReference<Map<String, dynamic>> docRef = await _store
          .collection('users')
          .doc(userId)
          .collection('customers')
          .add(customerData);
      logger.d('Create success: new customer ID= ${docRef.id}');
      return docRef.id;
    } catch (error) {
      logger.e('create customer error: $error');
      return null;
    }
  }

  @override
  Future<bool> update({
    required String userId,
    required String customerId,
    required CustomerModel customer,
  }) async {
    if (customer.userId == null ||
        customer.userEmail == null ||
        customer.uuid == null) {
      logger.e('Invalid parameters: $customer');
      return false;
    }

    // Check name is unique
    final bool isNameUnique;
    try {
      isNameUnique = await _isNameUnique(
          userId: userId,
          customerName: customer.name,
          customerUuid: customer.uuid);
    } catch (error) {
      logger.e('update customer error: $error');
      return false;
    }

    if (!isNameUnique) {
      throw NotUniqueException('This customer name is already used.');
    }

    // Check no completed order with this customer
    final bool isCompletedOrderWithCustomerExist;
    try {
      isCompletedOrderWithCustomerExist = await _isOrderWithCustomerExist(
          customerUuid: customer.uuid!,
          userId: userId,
          status: OrderStatus.completed);
    } catch (error) {
      logger.e('updateProduct error: $error');
      return false;
    }

    if (isCompletedOrderWithCustomerExist) {
      throw AlreadyInUseException(
          'This customer is associated with a completed order.');
    }

    try {
      final Map<String, dynamic> updatedCustomerAsJson = customer.toJson();
      updatedCustomerAsJson['nameToUpperCase'] = customer.name.toUpperCase();
      updatedCustomerAsJson['updatedDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      logger.d('updatedCustomer: $updatedCustomerAsJson');

      // Init batch write
      logger.d('running batch write');
      final WriteBatch batch = _store.batch();

      // Update order
      await _updatePendingOrdersWithCustomer(
        batch: batch,
        userId: userId,
        customerUuid: customer.uuid!,
        updatedCustomer: customer,
      );

      // Update customer
      batch.update(
          _store
              .collection('users')
              .doc(userId)
              .collection('customers')
              .doc(customerId),
          updatedCustomerAsJson);

      await batch.commit();

      logger.d('Update success');
      return true;
    } catch (error) {
      logger.e('updateCustomer error: $error');
      return false;
    }
  }

  @override
  Future<CustomerModel?> toggleActive({
    required String userId,
    required String customerId,
    required bool active,
  }) async {
    try {
      // Update customer
      final Map<String, dynamic> updatedData = <String, dynamic>{
        'active': active,
      };
      final DocumentReference<Map<String, dynamic>> ref = _store
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(customerId);
      await ref.update(updatedData);
      logger.d('Update success');

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc = await ref.get();
      return CustomerModel.fromSnapshot(updatedDoc);
    } catch (error) {
      logger.e('toggleActive error: $error');
      return null;
    }
  }

  @override
  Future<bool> delete({
    required String userId,
    required String customerId,
    required String customerUuid,
  }) async {
    logger.d('Delete customer $customerUuid');

    // Check no order with this customer
    final bool isOrderWithCustomerExist;
    try {
      isOrderWithCustomerExist = await _isOrderWithCustomerExist(
          customerUuid: customerUuid, userId: userId);
    } catch (error) {
      logger.e('Delete customer error: $error');
      return false;
    }

    if (isOrderWithCustomerExist) {
      throw AlreadyInUseException(
          'This customer is associated with an order. Please disable it instead.');
    }

    try {
      // Delete customer
      final DocumentReference<Map<String, dynamic>> ref = _store
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(customerId);
      await ref.delete();

      logger.d('Delete customer success');
      return true;
    } catch (error) {
      logger.e('Delete customer error: $error');
      return false;
    }
  }

  Future<bool> _isNameUnique({
    required String userId,
    required String customerName,
    String? customerUuid,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _store
        .collection('users')
        .doc(userId)
        .collection('customers')
        .where('name', isEqualTo: customerName)
        .where('uuid', isNotEqualTo: customerUuid)
        .limit(1)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        query.docs;
    return documentSnapshots.isEmpty;
  }

  Future<bool> _isOrderWithCustomerExist({
    required String customerUuid,
    required String userId,
    OrderStatus? status,
  }) async {
    // Get completed orders with this customer
    Query<Map<String, dynamic>> ordersQuery =
        _store.collection('users').doc(userId).collection('orders');

    if (status != null) {
      ordersQuery = ordersQuery.where('status', isEqualTo: status.name);
    }

    ordersQuery =
        ordersQuery.where('customerUuid', isEqualTo: customerUuid).limit(1);

    final QuerySnapshot<Map<String, dynamic>> ordersQuerySnapshot =
        await ordersQuery.get();

    return ordersQuerySnapshot.docs.isNotEmpty;
  }

  Future<void> _updatePendingOrdersWithCustomer({
    required WriteBatch batch,
    required String userId,
    required String customerUuid,
    required CustomerModel updatedCustomer,
  }) async {
    logger.d('update order with customer');

    // Get all pending orders with this customer
    final QuerySnapshot<Map<String, dynamic>> ordersQuerySnapshot = await _store
        .collection('users')
        .doc(userId)
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.name)
        .where('customerUuid', isEqualTo: customerUuid)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        ordersQuerySnapshot.docs;

    for (final DocumentSnapshot<Map<String, dynamic>> documentSnapshot
        in documentSnapshots) {
      final Map<String, dynamic> updatedOrder = <String, dynamic>{
        'customer': updatedCustomer.toJson(),
        'customerName': updatedCustomer.name,
        'customerNameToUpperCase': updatedCustomer.name.toUpperCase(),
        'customerUuid': updatedCustomer.uuid,
        'clientId': updatedCustomer.name,
      };
      logger.d('updatedOrder: $updatedOrder');

      // Update orders with new customer
      batch.update(documentSnapshot.reference, updatedOrder);
    }
  }
}
