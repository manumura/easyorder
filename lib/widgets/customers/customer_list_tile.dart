import 'package:flutter/material.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/pages/customer_edit_screen.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

mixin AbstractCustomerListTile {
  static const double switchWidth = 55;
  final Logger logger = getLogger();

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
      BuildContext context, CustomerModel customer, Widget trailingWidget) {
    return ListTile(
      title: _buildTitle(context, customer),
      subtitle: _buildSubTitle(context, customer),
      trailing: trailingWidget,
    );
  }

  Widget buildAddress(BuildContext context, CustomerModel customer) {
    return Wrap(
      children: <Widget>[
        Icon(
          Icons.mail_outline,
          color: Theme.of(context).primaryColor,
          size: 18,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Text(
            customer.address ?? '',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }

  Widget buildPhoneNumber(BuildContext context, CustomerModel customer) {
    return Wrap(
      children: <Widget>[
        Icon(
          Icons.phone,
          color: Theme.of(context).primaryColor,
          size: 18,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2.0),
          child: Text(
            customer.phoneNumber ?? '',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context, CustomerModel customer) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        customer.active
            ? const Icon(
                Icons.check,
                size: 20,
                color: Colors.green,
                semanticLabel: 'Active',
              )
            : const Icon(
                Icons.clear,
                size: 20,
                color: Colors.red,
                semanticLabel: 'Inactive',
              ),
        Text(
          customer.name,
          style: TextStyle(color: Theme.of(context).highlightColor),
        ),
      ],
    );
  }

  Widget _buildSubTitle(BuildContext context, CustomerModel customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (customer.address != null) buildAddress(context, customer),
        const SizedBox(
          height: 5,
        ),
        if (customer.phoneNumber != null) buildPhoneNumber(context, customer),
      ],
    );
  }

  void openEditScreen(BuildContext context, CustomerModel customer) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
          settings: const RouteSettings(name: CustomerEditScreen.routeName),
          builder: (BuildContext context) => CustomerEditScreen(customer)),
    )
        .then((_) {
      logger.d('Back to customer list');
    });
  }
}

class CustomerListTile extends HookConsumerWidget
    with AbstractCustomerListTile {
  CustomerListTile({required this.key, required this.customer});

  final Key key;
  final CustomerModel customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget child = InkWell(
      splashColor: Theme.of(context).primaryColor,
      onTap: () => openEditScreen(context, customer),
      child:
          buildListTile(context, customer, _buildEditButton(context, customer)),
    );

    return buildCard(child);
  }

  Widget _buildEditButton(BuildContext context, CustomerModel customer) {
    return IconButton(
      icon: Icon(
        Icons.edit,
        color: Theme.of(context).primaryColor,
      ),
      onPressed: () => openEditScreen(context, customer),
    );
  }
}

class CustomerSwitchListTile extends StatelessWidget
    with AbstractCustomerListTile {
  CustomerSwitchListTile(
      {required this.key, required this.customer, required this.onToggle});

  final Key key;
  final CustomerModel customer;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget child = InkWell(
      splashColor: Theme.of(context).primaryColor,
      onTap: () => openEditScreen(context, customer),
      child: buildListTile(
          context, customer, _buildActiveSwitch(context, customer)),
    );

    return buildCard(child);
  }

  Widget _buildActiveSwitch(BuildContext context, CustomerModel customer) {
    return SizedBox(
      width: AbstractCustomerListTile.switchWidth,
      child: FlutterSwitch(
        width: AbstractCustomerListTile.switchWidth,
        height: 25,
        toggleSize: 20,
        valueFontSize: 12,
        borderRadius: 12,
        padding: 2,
        showOnOff: true,
        activeColor: Colors.green,
        activeText: 'ON',
        inactiveColor: Colors.red,
        inactiveText: 'OFF',
        value: customer.active,
        onToggle: onToggle,
      ),
    );
  }
}

class CustomerLoadingListTile extends StatelessWidget
    with AbstractCustomerListTile {
  CustomerLoadingListTile({required this.key, required this.customer});

  final Key key;
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    final Widget child = buildListTile(
        context,
        customer,
        SizedBox(
          width: AbstractCustomerListTile.switchWidth,
          child: Center(
            child: AdaptiveProgressIndicator(),
          ),
        ));

    return Opacity(
      opacity: 0.5,
      child: buildCard(child),
    );
  }
}

class CustomerAutocompleteListTile extends StatelessWidget
    with AbstractCustomerListTile {
  CustomerAutocompleteListTile({required this.key, required this.customer});

  final Key key;
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            customer.name,
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (customer.address != null) buildAddress(context, customer),
              const SizedBox(
                height: 5,
              ),
              if (customer.phoneNumber != null)
                buildPhoneNumber(context, customer),
            ],
          ),
        ),
        const Divider(
          color: Colors.black,
          height: 5,
          thickness: 0.2,
        ),
      ],
    );
  }
}
