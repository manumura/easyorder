import 'package:flutter/material.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/widgets/customers/customer_list_tile.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key, required this.customers});

  final List<CustomerModel> customers;

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return const Center(child: Text('No customer found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10.0),
      itemBuilder: (BuildContext context, int index) {
        final CustomerModel customer = customers[index];
        return CustomerListTile(
            key: ValueKey<String?>(customer.uuid), customer: customer);
      },
      itemCount: customers.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(
        height: 8,
      ),
    );
  }
}
