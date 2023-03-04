import 'package:flutter/material.dart';
import 'package:easyorder/bloc/customer_bloc.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/widgets/customers/customer_list.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';

class CustomerSearchDelegate extends SearchDelegate<List<Widget>?> {
  CustomerSearchDelegate({required this.customerBloc});

  final CustomerBloc customerBloc;

  @override
  String get searchFieldLabel => 'Filter by name';

  @override
  TextStyle get searchFieldStyle => const TextStyle(
        color: Colors.white54,
        fontSize: 18.0,
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme:
          theme.appBarTheme.copyWith(backgroundColor: theme.primaryColor),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        query = '';
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final Future<List<CustomerModel>> customersFuture =
        _findCustomerByName(query);
    return FutureBuilder<List<CustomerModel>>(
      future: customersFuture,
      builder:
          (BuildContext context, AsyncSnapshot<List<CustomerModel>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(
            child: AdaptiveProgressIndicator(),
          );
        }

        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No category found !'));
        }

        return CustomerList(customers: snapshot.data!);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  Future<List<CustomerModel>> _findCustomerByName(String query) async {
    return customerBloc.findByName(name: query);
  }
}
