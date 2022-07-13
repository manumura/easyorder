import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/bloc/order_bloc.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/pages/order_edit_screen.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/orders/order_list.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:easyorder/widgets/ui_elements/logout_button.dart';
import 'package:easyorder/widgets/ui_elements/side_drawer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class OrderListScreen extends ConsumerStatefulWidget {
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
                OrderList(orders: const <OrderModel>[]),
              if (_currentIndex == 1)
                _buildOrderList(orders$)
              else
                OrderList(orders: const <OrderModel>[]),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (int index) {
              _switchTab(index);
            },
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_basket),
                label: 'Current Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time),
                label: 'Past Orders',
              ),
            ],
            elevation: 10.0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: backgroundColor,
            selectedFontSize: 16.0,
            selectedIconTheme: const IconThemeData(size: 30.0),
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
              color: Colors.white,
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
    setState(() => _isLoading = true);
    final List<OrderModel> orders = await orderBloc.find();
    final List<List<dynamic>> rows = <List<dynamic>>[];

    final List<dynamic> header = <dynamic>[];
    header.addAll(<String>[
      'Status',
      'Number',
      'Customer',
      'Date',
      'Due Date',
      'Description',
      'Total Price',
      'Item Quantity',
      'Item Name',
      'Item Price'
    ]);
    rows.add(header);

    for (int i = 0; i < orders.length; i++) {
      final List<dynamic> row = <dynamic>[];

      final OrderModel order = orders[i];
      row.add(order.status == OrderStatus.completed ? 'COMPLETED' : 'PENDING');
      row.add(order.number);
      row.add(order.customer.name);
      row.add(order.date);
      row.add(order.dueDate ?? '');
      row.add(order.description ?? '');

      if (order.cart != null) {
        row.add(order.cart?.price);
        for (final CartItemModel cartItem in order.cart!.cartItems) {
          row.add(cartItem.quantity);
          row.add(cartItem.product.name);
          row.add(cartItem.product.price);
        }
      }

      rows.add(row);
    }

    final DateTime now = DateTime.now();
    final String dateTitle = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final String fileSuffix = DateFormat('yyyyMMddHHmmss').format(now);

    final Directory? directory = await getExternalStorageDirectory();
    if (directory == null) {
      logger.d('Cannot find external storage directory');
      return;
    }

    final File file = File('${directory.path}/orders_$fileSuffix.csv');
    // final File file = MemoryFileSystem().file('tmp.csv');
    final String csv = const ListToCsvConverter().convert(rows);
    file.writeAsString(csv);

    if (!mounted) return;
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
  }
}
