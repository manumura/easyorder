import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/models/time_difference.dart';
import 'package:easyorder/pages/order_edit_screen.dart';
import 'package:easyorder/shared/utils.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/orders/price_tag.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

mixin AbstractOrderListTile {
  Widget buildCard(Widget child) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
      child: child,
    );
  }

  Widget buildListTile(
      BuildContext context, OrderModel order, Widget trailingWidget) {
    return ListTile(
      title: Text(
        'No. ${order.number}',
        style: TextStyle(color: titleColor),
      ),
      subtitle: _buildCardSubtitle(context, order),
      trailing: trailingWidget,
      // leading: trailingWidget,
    );
  }

  Widget _buildCardSubtitle(BuildContext context, OrderModel order) {
    final DateFormat format = DateFormat("MMMM d, yyyy 'at' h:mm a");
    final String dateAsString = format.format(order.date);
    final bool isCompleted = order.status == OrderStatus.completed;
    final DateTime? dueDate = order.dueDate;

    final Widget phoneNumberWidget = Wrap(
      children: <Widget>[
        Icon(
          Icons.phone,
          color: Theme.of(context).colorScheme.secondary,
          size: 18,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Text(
            order.customer.phoneNumber ?? 'N/A',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(
          height: 2.0,
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Icon(
              Icons.perm_identity_rounded,
              color: Theme.of(context).colorScheme.secondary,
              size: 18,
            ),
            Text(
              order.customer.name,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
        phoneNumberWidget,
        const SizedBox(
          height: 2.0,
        ),
        Text(
          dateAsString,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
        const SizedBox(
          height: 2.0,
        ),
        _buildDueDate(dueDate, isCompleted),
      ],
    );
  }

  Text _buildDueDate(DateTime? dueDate, bool isCompleted) {
    if (dueDate == null) {
      return const Text(
        'No Due Date',
        style: TextStyle(color: Colors.black),
      );
    }

    if (isCompleted) {
      final DateFormat format = DateFormat('EEEE MMMM d, yyyy');
      final String dueDateAsString = format.format(dueDate);
      return Text(
        'Due on $dueDateAsString',
        style: const TextStyle(color: Colors.black),
      );
    }

    final DateTime now = DateTime.now();
    if (now.compareTo(dueDate) < 0) {
      final int diffInMinutes = minutesBetween(dueDate, now);
      final TimeDifference timeDifference =
          calculateTimeDifference(diffInMinutes);
      final String dueDateAsString = 'Due in ${timeDifference.days} days';
      return Text(
        dueDateAsString,
        style: const TextStyle(color: Colors.green),
      );
    } else {
      final int diffInMinutes = minutesBetween(now, dueDate);
      final TimeDifference timeDifference =
          calculateTimeDifference(diffInMinutes);
      final String dueDateAsString = 'Overdue by ${timeDifference.days} days';
      return Text(
        dueDateAsString,
        style: const TextStyle(color: Colors.red),
      );
    }
  }
}

class OrderListTile extends StatelessWidget with AbstractOrderListTile {
  OrderListTile({super.key, required this.order});

  final OrderModel order;

  final Logger logger = getLogger();

  @override
  Widget build(BuildContext context) {
    final Widget trailingWidget = _buildPriceTag(context, order);
    final Widget child = InkWell(
      onTap: () => _openOrderEditScreen(context, order),
      child: buildListTile(context, order, trailingWidget),
    );
    return buildCard(child);
  }

  Widget _buildPriceTag(BuildContext context, OrderModel order) {
    final bool isCompleted = order.status == OrderStatus.completed;
    final Color color = isCompleted ? Colors.red : Colors.green;
    final double price = order.cart == null ? 0.00 : order.cart!.price;

    return PriceTag(
      price: price,
      color: color,
    );
  }

  void _openOrderEditScreen(BuildContext context, OrderModel order) {
    // final variable to avoid recreation of the screen every time when
    // the keyboard is opened or closed in this screen.
    final Widget orderEditScreen = OrderEditScreen(
      currentOrder: order,
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute<String>(
        settings: const RouteSettings(name: OrderEditScreen.routeName),
        builder: (BuildContext context) {
          return orderEditScreen;
        },
      ),
    )
        .then((String? value) {
      logger.d('Back to order list: $value');
    });
  }
}

class OrderLoadingListTile extends StatelessWidget with AbstractOrderListTile {
  OrderLoadingListTile({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final Widget child = buildListTile(
      context,
      order,
      AdaptiveProgressIndicator(),
    );
    return Opacity(
      opacity: 0.5,
      child: buildCard(child),
    );
  }
}

class OrderErrorListTile extends StatelessWidget with AbstractOrderListTile {
  OrderErrorListTile({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 8.0,
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Center(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
