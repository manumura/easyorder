import 'package:easyorder/bloc/customer_bloc.dart';
import 'package:easyorder/pages/customer_edit_screen.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/customers/customer_paginated_list.dart';
import 'package:easyorder/widgets/search/customer_search_delegate.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:easyorder/widgets/ui_elements/logout_button.dart';
import 'package:easyorder/widgets/ui_elements/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CustomerListScreen extends HookConsumerWidget {
  static const String routeName = '/customers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const String pageTitle = 'Customers';
    final AsyncValue<CustomerBloc?> customerBloc$ =
        ref.watch(customerBlocProvider);
    return customerBloc$.when(
      data: (CustomerBloc? customerBloc) {
        if (customerBloc == null) {
          return _buildErrorScreen(pageTitle, 'No customer found');
        }
        return _buildScreen(context, pageTitle, customerBloc);
      },
      loading: () {
        return _buildLoadingScreen(pageTitle);
      },
      error: (Object err, StackTrace? stack) => Center(
        child: _buildErrorScreen(pageTitle, err),
      ),
    );
  }

  Widget _buildLoadingScreen(String pageTitle) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(child: AdaptiveProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(String pageTitle, Object err) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildScreen(
      BuildContext context, String pageTitle, CustomerBloc customerBloc) {
    return Scaffold(
      drawer: SideDrawer(),
      appBar: AppBar(
        title: Text(pageTitle),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        actions: <Widget>[
          _buildChip(context, customerBloc),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch<List<Widget>?>(
                context: context,
                delegate: CustomerSearchDelegate(customerBloc: customerBloc)),
          ),
          LogoutButton(),
        ],
      ),
      body: CustomerPaginatedList(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: CustomerEditScreen.routeName),
              builder: (BuildContext context) => const CustomerEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChip(BuildContext context, CustomerBloc customerBloc) {
    return StreamBuilder<int?>(
      stream: customerBloc.count(),
      builder: (BuildContext context, AsyncSnapshot<int?> snapshot) {
        if (snapshot.hasError) {
          return Chip(
            label: const Text('0'),
            labelStyle: const TextStyle(
              color: Colors.white,
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: AdaptiveProgressIndicator(),
          );
        }

        final String count = '${snapshot.data}';
        return Chip(
          label: Text(count),
          labelStyle: const TextStyle(
            color: Colors.white,
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        );
      },
    );
  }
}
