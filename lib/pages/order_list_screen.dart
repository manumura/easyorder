import 'dart:io';

import 'package:easyorder/bloc/order_bloc.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/pages/order_edit_screen.dart';
import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:easyorder/shared/utils.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/orders/order_list.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:easyorder/widgets/ui_elements/logout_button.dart';
import 'package:easyorder/widgets/ui_elements/side_drawer.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:share/share.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  static const String routeName = '/orders';

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;

  final Logger logger = getLogger();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OrderBloc?> orderBloc$ = ref.watch(orderBlocProvider);
    return orderBloc$.when(
      data: (OrderBloc? orderBloc) {
        if (orderBloc == null) {
          return _buildErrorScreen('No order found');
        }
        return _buildTabController(orderBloc);
      },
      loading: () {
        return _buildLoadingScreen();
      },
      error: (Object err, StackTrace? stack) => Center(
        child: _buildErrorScreen(err),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return SafeArea(
      child: Scaffold(
        drawer: SideDrawer(),
        appBar: AppBar(
          title: const Text('Orders'),
        ),
        body: _buildLoadingIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen(Object err) {
    return SafeArea(
      child: Scaffold(
        drawer: SideDrawer(),
        appBar: AppBar(
          title: const Text('Orders'),
        ),
        body: Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildTabController(OrderBloc orderBloc) {
    final Widget orderEditScreen = OrderEditScreen();
    // Get orders based on status (tab index)
    final Stream<List<OrderModel>> orders$ = _currentIndex == 0
        ? orderBloc.ordersPending$
        : orderBloc.ordersCompleted$;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          drawer: SideDrawer(),
          appBar: AppBar(
            title: const Text('Orders'),
            elevation:
                Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
            actions: <Widget>[
              // TODO test crashlytics
              // IconButton(
              //   icon: const Icon(
              //     FontAwesomeIcons.addressCard,
              //     color: Colors.white,
              //   ),
              //   onPressed: () => throw Exception(),
              // ),
              _buildChip(orders$),
              _buildCsvExportButton(orderBloc),
              LogoutButton(),
            ],
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() => _currentIndex = index);
            },
            children: <Widget>[
              if (_currentIndex == 0)
                _buildOrderList(orders$)
              else
                const OrderList(orders: <OrderModel>[]),
              if (_currentIndex == 1)
                _buildOrderList(orders$)
              else
                const OrderList(orders: <OrderModel>[]),
            ],
          ),
          bottomNavigationBar: NavigationBarTheme(
            data: navigationBarThemeData,
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                _switchTab(index);
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.shopping_basket),
                  label: 'Current Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_time),
                  label: 'Past Orders',
                ),
              ],
              elevation: 10.0,
              // backgroundColor: backgroundColor,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute<String>(
                    settings:
                        const RouteSettings(name: OrderEditScreen.routeName),
                    builder: (BuildContext context) => orderEditScreen),
              )
                  .then((String? value) {
                logger.d('Back to order list: $value');
              });
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(Stream<List<OrderModel>> orders$) {
    return StreamBuilder<List<OrderModel>>(
      stream: orders$,
      builder:
          (BuildContext context, AsyncSnapshot<List<OrderModel>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return _buildLoadingIndicator();
        }

        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No orders found'));
        }

        final List<OrderModel> orders = snapshot.data!;
        return OrderList(
          orders: orders,
        );
      },
    );
  }

  Widget _buildChip(Stream<List<OrderModel>> orders$) {
    return StreamBuilder<List<OrderModel>>(
      stream: orders$,
      builder:
          (BuildContext context, AsyncSnapshot<List<OrderModel>> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return _buildLoadingIndicator();
        }

        final List<OrderModel>? orders = snapshot.data;
        final String count =
            orders == null || orders.isEmpty ? '0' : orders.length.toString();
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

  Widget _buildCsvExportButton(OrderBloc orderBloc) {
    return IconButton(
      icon: _isLoading
          ? const Icon(
              FontAwesomeIcons.fileCsv,
              color: Colors.grey,
            )
          : const Icon(
              FontAwesomeIcons.fileCsv,
              // color: Colors.white,
            ),
      onPressed: _isLoading ? null : () => _exportToCsv(context, orderBloc),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: AdaptiveProgressIndicator(),
    );
  }

  void _switchTab(int tabIndex) {
    _pageController.jumpToPage(tabIndex);
  }

  Future<void> _exportToCsv(BuildContext context, OrderBloc orderBloc) async {
    if (!context.mounted) {
      logger.d('Widget is not mounted');
      return;
    }

    try {
      setState(() => _isLoading = true);
      final List<OrderModel> orders = await orderBloc.find();

      final DateTime now = DateTime.now();
      final String dateTitle = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      final File file = await generateCsv(orders, now);

      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null) {
        logger.d('Cannot find render box');
        return;
      }

      Share.shareFiles(
        <String>[file.path],
        subject: 'Simple Order Manager: orders export $dateTitle',
        text: 'Please find attached the orders export as csv file.',
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      UiHelper.showAlertDialog(context, AlertType.error,
          'Csv creation failed !', 'Please try again later.');
      return;
    }
  }
}
