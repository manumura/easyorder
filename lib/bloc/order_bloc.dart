import 'dart:async';

import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/order_repository.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

abstract class OrderBloc {
  Stream<List<OrderModel>> get ordersPending$;

  Stream<List<OrderModel>> get ordersCompleted$;

  Future<List<OrderModel>> find(
      {int? pageSize, OrderStatus? status, DateTime? lastDate});

  Future<bool> create({required OrderModel order});

  Future<bool> update({required String orderId, required OrderModel order});

  Future<bool> updateStatus(
      {required String orderId,
      required OrderModel order,
      required OrderStatus status});

  Future<bool> delete({required String orderId});

  void dispose();
}

class OrderBlocImpl implements OrderBloc {
  OrderBlocImpl({required this.user, required this.orderRepository}) {
    logger.d('----- Building OrderBlocImpl -----');
    final Stream<List<OrderModel>> ordersPending$ =
        orderRepository.stream(userId: user.id, status: OrderStatus.pending);

    ordersPending$.listen(
      (List<OrderModel> orders) {
        final List<OrderModel> o = orders
          ..sort((OrderModel a, OrderModel b) =>
              _sortByDueDateThenCreationDate(a, b));
        _ordersPendingSubject.add(o);
      },
      onError: (Object error) =>
          logger.e('orders pending listen error: $error'),
      cancelOnError: false,
    );

    final Stream<List<OrderModel>> ordersCompleted$ =
        orderRepository.stream(userId: user.id, status: OrderStatus.completed);

    ordersCompleted$.listen(
      (List<OrderModel> orders) {
        _ordersCompletedSubject.add(orders);
      },
      onError: (Object error) =>
          logger.e('orders completed listen error: $error'),
      cancelOnError: false,
    );
  }
  final UserModel user;
  final OrderRepository orderRepository;

  final Logger logger = getLogger();

  final BehaviorSubject<List<OrderModel>> _ordersPendingSubject =
      BehaviorSubject<List<OrderModel>>.seeded(<OrderModel>[]);

  final BehaviorSubject<List<OrderModel>> _ordersCompletedSubject =
      BehaviorSubject<List<OrderModel>>.seeded(<OrderModel>[]);

  @override
  Stream<List<OrderModel>> get ordersPending$ => _ordersPendingSubject.stream;

  @override
  Stream<List<OrderModel>> get ordersCompleted$ =>
      _ordersCompletedSubject.stream;

  @override
  Future<List<OrderModel>> find(
      {int? pageSize, OrderStatus? status, DateTime? lastDate}) async {
    if (user.id.isEmpty) {
      logger.e('user is null');
      return <OrderModel>[];
    }

    return orderRepository.find(
        userId: user.id,
        pageSize: pageSize,
        status: status,
        lastDate: lastDate);
  }

  @override
  Future<bool> create({required OrderModel order}) async {
    logger.d('add order');

    if (user.id.isEmpty) {
      logger.e('order or user is null');
      return false;
    }

    const Uuid uuid = Uuid();
    final DateFormat format = DateFormat('yyyyMMddhhMMss');

    final OrderModel orderToCreate = OrderModel.clone(order);
    orderToCreate.uuid = uuid.v4();
//    orderData['number'] = DateTime.now().millisecondsSinceEpoch;
    orderToCreate.number = format.format(DateTime.now());
    orderToCreate.status = OrderStatus.pending;
    orderToCreate.userId = user.id;
    orderToCreate.userEmail = user.email;

    return orderRepository.create(order: orderToCreate);
  }

  @override
  Future<bool> update(
      {required String orderId, required OrderModel order}) async {
    logger.d('update order: $orderId');

    if (user.id.isEmpty) {
      logger.e('order, orderId or user is null');
      return false;
    }

    return orderRepository.update(orderId: orderId, order: order);
  }

  @override
  Future<bool> updateStatus(
      {required String orderId,
      required OrderModel order,
      required OrderStatus status}) async {
    logger.d('complete or reopen order: $orderId - status $status');

    if (user.id.isEmpty) {
      logger.e('User is null');
      return false;
    }

    final OrderModel orderToUpdate = OrderModel.clone(order);
    orderToUpdate.status = status;

    return orderRepository.update(orderId: orderId, order: orderToUpdate);
  }

  @override
  Future<bool> delete({required String orderId}) {
    logger.d('delete order: $orderId');

    if (user.id.isEmpty) {
      logger.e('userId or orderId or user is null');
      return Future<bool>.value(false);
    }

    return orderRepository.delete(orderId: orderId, userId: user.id);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE OrderBloc ***');
    _ordersPendingSubject.close();
    _ordersCompletedSubject.close();
  }

  // int Function(OrderModel a, OrderModel b) _compare(bool completed) {
  //   return !completed
  //       ? (OrderModel a, OrderModel b) => _sortByDueDateThenCreationDate(a, b)
  //       : (OrderModel a, OrderModel b) => _sortByCreationDate(b, a);
  // }

  // int _sortByCreationDate(OrderModel a, OrderModel b) {
  //   return a.date.compareTo(b.date);
  // }

  int _sortByDueDateThenCreationDate(OrderModel a, OrderModel b) {
    if (a.dueDate == null) {
      if (b.dueDate == null) {
        return a.date.compareTo(b.date);
      } else {
        return 1;
      }
    } else {
      if (b.dueDate == null) {
        return -1;
      } else {
        return a.dueDate!.compareTo(b.dueDate!);
      }
    }
  }
}
