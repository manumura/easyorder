import 'package:another_flushbar/flushbar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:easyorder/bloc/order_bloc.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/orders/order_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class OrderSlidableListTile extends ConsumerStatefulWidget {
  const OrderSlidableListTile({super.key, required this.order});

  final OrderModel order;

  @override
  ConsumerState<OrderSlidableListTile> createState() =>
      _OrderSlidableListTileState();
}

class _OrderSlidableListTileState extends ConsumerState<OrderSlidableListTile> {
  bool _isLoading = false;

  final Logger logger = getLogger();

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OrderBloc?> orderBlocProvider$ =
        ref.watch(orderBlocProvider);
    return orderBlocProvider$.when(
      data: (OrderBloc? orderBloc) {
        if (orderBloc == null) {
          return OrderErrorListTile(message: 'No order found');
        }
        return _buildOrderListTile(orderBloc);
      },
      loading: () {
        return OrderLoadingListTile(order: widget.order);
      },
      error: (Object err, StackTrace? stack) => Center(
        child: OrderErrorListTile(message: 'Error: $err'),
      ),
    );
  }

  Widget _buildOrderListTile(OrderBloc orderBloc) {
    // final bool isCompleted = widget.order.status == OrderStatus.completed;

    return _isLoading
        ? OrderLoadingListTile(order: widget.order)
        : Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.3,
              children: <Widget>[
                SlidableAction(
                  onPressed: (BuildContext context) =>
                      _showConfirmationDialog(orderBloc),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: OrderListTile(order: widget.order),
          );
  }

  // void _updateOrderStatus(bool isCompleted, OrderBloc orderBloc) {
  //   if (widget.order.id == null) {
  //     logger.e('Current order id cannot be null');
  //     return;
  //   }
  //
  //   setState(() => _isLoading = true);
  //   orderBloc
  //       .updateStatus(
  //           orderId: widget.order.id!,
  //           order: widget.order,
  //           status: isCompleted ? OrderStatus.completed : OrderStatus.pending)
  //       .then(
  //     (bool success) {
  //       setState(() => _isLoading = false);
  //       if (success) {
  //         final String status = isCompleted ? 'completed' : 'reopened';
  //         final Flushbar<void> flushbar = UiHelper.createSuccessFlushbar(
  //             message: 'Order #${widget.order.number} successfully $status !',
  //             title: 'Success !');
  //         flushbar.show(navigatorKey.currentContext ?? context);
  //       } else {
  //         final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
  //             message: 'Failed to update order #${widget.order.number} !',
  //             title: 'Error !');
  //         flushbar.show(navigatorKey.currentContext ?? context);
  //       }
  //     },
  //   ).catchError(
  //     (Object err, StackTrace trace) {
  //       setState(() => _isLoading = false);
  //       logger.e('Error: $err');
  //       final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
  //           message: 'Failed to update order #${widget.order.number} !',
  //           title: 'Error !');
  //       flushbar.show(navigatorKey.currentContext ?? context);
  //     },
  //   );
  // }

  void _showConfirmationDialog(OrderBloc orderBloc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      body: Column(
        children: const <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'Warning',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text('Do you want to delete this order ?'),
          Text('It will be removed permanently.')
        ],
      ),
      btnCancelColor: Colors.red,
      btnOkColor: Colors.green,
      btnCancelOnPress: () {
        logger.d('Cancel delete order ${widget.order.uuid}');
      },
      btnOkOnPress: () {
        logger.d('Confirm delete order ${widget.order.uuid}');
        _deleteOrder(orderBloc);
      },
    ).show();
  }

  void _deleteOrder(OrderBloc orderBloc) {
    if (widget.order.id == null) {
      logger.e('Order id is null');
      return;
    }
    setState(() => _isLoading = true);

    orderBloc.delete(orderId: widget.order.id!).then(
      (bool success) {
        setState(() => _isLoading = false);
        if (success) {
          final Flushbar<void> flushbar = UiHelper.createSuccessFlushbar(
              message: 'Order #${widget.order.number} successfully removed !',
              title: 'Success !');
          flushbar.show(navigatorKey.currentContext ?? context);
        } else {
          final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
              message: 'Failed to remove ${widget.order.number} !',
              title: 'Error !');
          flushbar.show(navigatorKey.currentContext ?? context);
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');
        final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
            message: 'Failed to remove ${widget.order.number} !',
            title: 'Error !');
        flushbar.show(navigatorKey.currentContext ?? context);
      },
    );
  }
}
