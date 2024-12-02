import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/customer_list_state_notifier.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/customers/customer_list_tile.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class CustomerSlidableListTile extends ConsumerStatefulWidget {
  const CustomerSlidableListTile({super.key, required this.customer});

  final CustomerModel customer;

  @override
  ConsumerState<CustomerSlidableListTile> createState() =>
      _CustomerSlidableListTileState();
}

class _CustomerSlidableListTileState
    extends ConsumerState<CustomerSlidableListTile> {
  bool _isLoading = false;

  final Logger logger = getLogger();

  // https://proandroiddev.com/flutter-thursday-02-beautiful-list-ui-and-detail-page-a9245f5ceaf0
  @override
  Widget build(BuildContext context) {
    final CustomerListStateNotifier customerListStateNotifier =
        ref.watch(customerListStateNotifierProvider.notifier);
    return _buildCustomerListTile(context, customerListStateNotifier);
  }

  Widget _buildCustomerListTile(BuildContext context,
      CustomerListStateNotifier customerListStateNotifier) {
    return _isLoading
        ? CustomerLoadingListTile(
            key: ValueKey<String?>(widget.customer.uuid),
            customer: widget.customer)
        : Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.3,
              children: <Widget>[
                SlidableAction(
                  onPressed: (BuildContext context) =>
                      _delete(context, customerListStateNotifier),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: CustomerSwitchListTile(
              key: ValueKey<String?>(widget.customer.uuid),
              customer: widget.customer,
              onToggle: (bool value) =>
                  _toggleActive(context, customerListStateNotifier, value),
            ),
          );
  }

  void _delete(BuildContext context,
      CustomerListStateNotifier customerListStateNotifier) {
    setState(() => _isLoading = true);

    customerListStateNotifier.remove(customerToRemove: widget.customer).then(
      (bool success) {
        setState(() => _isLoading = false);
        if (success) {
          final Flushbar<void> flushbar = UiHelper.createSuccessFlushbar(
              message: '${widget.customer.name} successfully removed !',
              title: 'Success !');
          flushbar.show(navigatorKey.currentContext ?? context);
        } else {
          final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
              message: 'Failed to remove ${widget.customer.name} !',
              title: 'Error !');
          flushbar.show(navigatorKey.currentContext ?? context);
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');

        String title = 'Error !';
        String content = 'Failed to remove ${widget.customer.name} !';

        final bool isAlreadyInUse = err is AlreadyInUseException;
        if (isAlreadyInUse) {
          title = 'Cannot delete this customer.';
          content = err.message;
        }

        final Flushbar<void> flushbar =
            UiHelper.createErrorFlushbar(message: content, title: title);
        flushbar.show(navigatorKey.currentContext ?? context);
      },
    );
  }

  void _toggleActive(
    BuildContext context,
    CustomerListStateNotifier customerListStateNotifier,
    bool active,
  ) {
    if (widget.customer.id == null) {
      logger.e('Customer id is null');
      return;
    }
    setState(() => _isLoading = true);

    customerListStateNotifier
        .toggleActive(customerId: widget.customer.id!, active: active)
        .then(
      (CustomerModel? updatedCustomer) {
        setState(() => _isLoading = false);
        logger.d('Customer active toggle updated: $updatedCustomer');
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');
        final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
            message: 'Failed to update ${widget.customer.name} !',
            title: 'Error !');
        flushbar.show(navigatorKey.currentContext ?? context);
      },
    );
  }
}
