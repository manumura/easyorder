import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_performance/firebase_performance.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class OrderRepository {
  Stream<List<OrderModel>> stream(
      {required String userId, OrderStatus? status});

  Future<List<OrderModel>> find(
      {required String userId,
      int? pageSize,
      OrderStatus? status,
      DateTime? lastDate});

  Future<bool> create({required OrderModel order});

  Future<bool> update({required String orderId, required OrderModel order});

  Future<bool> delete({required String orderId, required String userId});

  void dispose();
}

class OrderRepositoryFirebaseImpl implements OrderRepository {
  final FirebaseFirestore _store = FirebaseFirestore.instance;
  final Logger logger = getLogger();

  @override
  Stream<List<OrderModel>> stream(
      {required String userId, OrderStatus? status}) {
    logger.d('stream orders: status=$status');

    try {
      // Find documents by user id
      Query<Map<String, dynamic>> query =
          _store.collection('users').doc(userId).collection('orders');

      if (status != null) {
        final bool isCompleted = status == OrderStatus.completed;
        query = query.where('status', isEqualTo: status.name);
        query = query.orderBy('date', descending: isCompleted);
      } else {
        query = query.orderBy('date');
      }

      final Stream<List<OrderModel>> orders$ = query.snapshots().map(
        (QuerySnapshot<Map<String, dynamic>> querySnapshot) {
          final List<OrderModel> orders = querySnapshot.docs
              .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
                  OrderModel.fromSnapshot(documentSnapshot))
              .toList();
          return orders;
        },
      );

      return orders$;
    } catch (e) {
      logger.e(e);
      return const Stream<List<OrderModel>>.empty();
    }
  }

  @override
  Future<List<OrderModel>> find(
      {required String userId,
      int? pageSize,
      OrderStatus? status,
      DateTime? lastDate}) async {
    logger.d('find orders: pageSize=$pageSize, status=$status, '
        'lastDate=$lastDate');

    // Firebase performance trace
    // final Trace trace = FirebasePerformance.instance.newTrace('orders_fetch');
    // trace.putAttribute('userId', userId);
    // trace.start();

    try {
      // Find documents by user id
      final CollectionReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId).collection('orders');

      final bool isCompleted = status == OrderStatus.completed;
      Query<Map<String, dynamic>> query =
          ref.orderBy('date', descending: isCompleted);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (lastDate != null) {
        // Add/subtract 1ms otherwise last record is duplicated
        final Timestamp timestamp = isCompleted
            ? Timestamp.fromDate(
                lastDate.subtract(const Duration(milliseconds: 1)))
            : Timestamp.fromDate(lastDate.add(const Duration(milliseconds: 1)));
        query = isCompleted
            ? query.where('date', isLessThan: timestamp)
            : query.where('date', isGreaterThan: timestamp);
//        final List<dynamic> params = <dynamic>[timestamp];
//        query = descending ? query.startAt(params) : query.endAt(params);
//        startAfter / endBefore ?
      }

      if (pageSize != null) {
        query = query.limit(pageSize);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();
      final List<OrderModel> orders = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              OrderModel.fromSnapshot(documentSnapshot))
          .toList();

      // trace.stop();

      return orders;
    } on Exception catch (ex) {
      logger.e(ex);
      // trace.stop();
      return Future<List<OrderModel>>.value(<OrderModel>[]);
    }
  }

  @override
  Future<bool> create({required OrderModel order}) async {
    if (order.userId == null ||
        order.userEmail == null ||
        order.status == null ||
        order.number == null ||
        order.uuid == null ||
        order.cart == null) {
      logger.e('Invalid parameters');
      return false;
    }

    try {
      final List<CartItemModel>? items = order.cart?.items;
      final List<String?> categoryUuids = _getCategoryUuids(items);
      final List<String?> productUuids = _getProductUuids(items);

      final Map<String, dynamic> orderData = order.toJson();
      orderData['createdDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      orderData['productUuids'] = productUuids;
      orderData['categoryUuids'] = categoryUuids;
      orderData['completed'] = order.status == OrderStatus.completed;
      orderData['customerName'] = order.customer.name;
      orderData['customerNameToUpperCase'] = order.customer.name.toUpperCase();
      orderData['customerUuid'] = order.customer.uuid;
      orderData['clientId'] = order.customer.name;

      // Save date as Firestore Timestamp
      final Timestamp timestamp = Timestamp.fromDate(order.date);
      orderData['date'] = timestamp;
      if (order.dueDate != null) {
        final Timestamp dueTimestamp = Timestamp.fromDate(order.dueDate!);
        orderData['dueDate'] = dueTimestamp;
      }

      logger.d('orderData: $orderData');

      // Add document by user id
      final DocumentReference<Map<String, dynamic>> docRef = await _store
          .collection('users')
          .doc(order.userId)
          .collection('orders')
          .add(orderData);
      logger.d('Create success: new order ID= ${docRef.id}');
      return true;
    } catch (error) {
      logger.e('addOrder error: $error');
      return false;
    }
  }

  @override
  Future<bool> update(
      {required String orderId, required OrderModel order}) async {
    if (order.userId == null ||
        order.userEmail == null ||
        order.status == null ||
        order.number == null ||
        order.uuid == null ||
        order.cart == null) {
      logger.e('Invalid parameters');
      return false;
    }

    try {
      final List<CartItemModel>? items = order.cart?.items;
      final List<String?> categoryUuids = _getCategoryUuids(items);
      final List<String?> productUuids = _getProductUuids(items);

      final Map<String, dynamic> updatedOrder = order.toJson();
      updatedOrder['updatedDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      updatedOrder['productUuids'] = productUuids;
      updatedOrder['categoryUuids'] = categoryUuids;
      updatedOrder['completed'] = order.status == OrderStatus.completed;
      updatedOrder['customerName'] = order.customer.name;
      updatedOrder['customerNameToUpperCase'] =
          order.customer.name.toUpperCase();
      updatedOrder['customerUuid'] = order.customer.uuid;
      updatedOrder['clientId'] = order.customer.name;

      // Save date as Firestore Timestamp
      final Timestamp timestamp = Timestamp.fromDate(order.date);
      updatedOrder['date'] = timestamp;
      if (order.dueDate != null) {
        final Timestamp dueTimestamp = Timestamp.fromDate(order.dueDate!);
        updatedOrder['dueDate'] = dueTimestamp;
      }

      logger.d('updatedOrder: $updatedOrder');

      await _store.runTransaction((Transaction transaction) async {
        transaction.update(
            // Update document by user id
            _store
                .collection('users')
                .doc(order.userId)
                .collection('orders')
                .doc(orderId),
            updatedOrder);
      });

      logger.d('Update success');
      return true;
    } catch (error) {
      logger.e('updateOrder error: $error');
      return false;
    }
  }

  @override
  Future<bool> delete({required String orderId, required String userId}) async {
    try {
      await _store.runTransaction<bool>((Transaction transaction) async {
        // Delete document by user id
        final DocumentReference<Map<String, dynamic>> ref = _store
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);
        transaction.delete(ref);
        return true;
      });
      logger.d('Delete order success');
      return true;
    } catch (error) {
      logger.e('Delete order error: $error');
      return false;
    }
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE OrderRepository ***');
  }

  List<String?> _getProductUuids(List<CartItemModel>? items) {
    final List<String?> productUuids = <String?>[];

    if (items != null) {
      productUuids.addAll(items
          .map((CartItemModel cartItem) => cartItem.product.uuid)
          .where((String? uuid) => uuid != null)
          .toSet() // remove duplicates
          .toList());
    }

    return productUuids;
  }

  List<String?> _getCategoryUuids(List<CartItemModel>? items) {
    final List<String?> categoryUuids = <String?>[];

    if (items != null) {
      categoryUuids.addAll(items
          .map((CartItemModel cartItem) => cartItem.product.category?.uuid)
          .where((String? uuid) => uuid != null)
          .toSet() // remove duplicates
          .toList());
    }

    return categoryUuids;
  }
}
