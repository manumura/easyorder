import 'package:easyorder/shared/adaptive_theme.dart';
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
    final String addressAsString = customer.address?.trim() ?? 'N/A';
    final String addressAsStringWithComma =
        addressAsString.replaceAll(RegExp(r'\n'), ', ');

    return Text.rich(
      // softWrap: false,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            child: Icon(
              Icons.mail_outline,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          WidgetSpan(
            child: SizedBox(
              width: 5,
            ),
          ),
          TextSpan(
            text: addressAsStringWithComma,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget buildPhoneNumber(BuildContext context, CustomerModel customer) {
    return Text.rich(
      // softWrap: false,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            child: Icon(
              Icons.phone,
              color: Theme.of(context).primaryColor,
              size: 18,
            ),
          ),
          WidgetSpan(
            child: SizedBox(
              width: 5,
            ),
          ),
          TextSpan(
            text: customer.phoneNumber ?? 'N/A',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, CustomerModel customer) {
    final Icon icon = customer.active
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
          );

    return Text.rich(
      // softWrap: false,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            child: icon,
          ),
          WidgetSpan(
            child: SizedBox(
              width: 5,
            ),
          ),
          TextSpan(
            text: customer.name,
            style: TextStyle(
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTitle(BuildContext context, CustomerModel customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildAddress(context, customer),
        const SizedBox(
          height: 5,
        ),
        buildPhoneNumber(context, customer),
      ],
    );
  }

  void openEditScreen(BuildContext context, CustomerModel customer) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
          settings: const RouteSettings(name: CustomerEditScreen.routeName),
          builder: (BuildContext context) => CustomerEditScreen(
                currentCustomer: customer,
              )),
    )
        .then((_) {
      logger.d('Back to customer list');
    });
  }
}

class CustomerListTile extends HookConsumerWidget
    with AbstractCustomerListTile {
  CustomerListTile({super.key, required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget child = InkWell(
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
      {super.key, required this.customer, required this.onToggle});

  final CustomerModel customer;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget child = InkWell(
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
  CustomerLoadingListTile({super.key, required this.customer});

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
  CustomerAutocompleteListTile({super.key, required this.customer});

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
