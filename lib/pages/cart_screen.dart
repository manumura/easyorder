import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:badges/badges.dart' as badges;
import 'package:easyorder/bloc/cart_bloc.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/cart_model.dart';
import 'package:easyorder/models/items_position_model.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/pages/product_edit_screen.dart';
import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:easyorder/shared/cart_helper.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/orders/cart_item_list_tile.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:functional_listener/functional_listener.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, required this.cartItems});

  final List<CartItemModel> cartItems;

  static const String routeName = '/order_cart';

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with TickerProviderStateMixin {
  // SingleTickerProviderStateMixin TickerProviderStateMixin
  final String pageTitle = 'My Cart';
  final Logger logger = getLogger();

  late TabController _tabController;

  /// Controller to scroll or jump to a particular item.
  final ItemScrollController _itemScrollController = ItemScrollController();

  /// Listener that reports the position of items when the list is scrolled.
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  final List<CartItemModel> _initialCartItems = <CartItemModel>[];
  final List<CartItemModel> _cartItemsToDisplay = <CartItemModel>[];
  final Map<String, int> _categoriesMap = <String, int>{};

  @override
  void initState() {
    super.initState();

    _initialCartItems.addAll(widget.cartItems);
    _createTabIndexListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPop: () {
        Navigator.of(context).pop('Back pressed');
      },
      child: _buildScreenStream(),
    );
  }

  Widget _buildScreenStream() {
    final AsyncValue<List<ProductModel>> activeProducts$ =
        ref.watch(activeProducts$Provider);

    return activeProducts$.when(
      data: (List<ProductModel> products) {
        final List<CartItemModel> cartItems =
            CartHelper.calculateProductsQuantity(_initialCartItems, products);

        final List<CartItemModel> cartItemsToDisplay = cartItems
            .where(
                (CartItemModel cartItem) => cartItem.product.category != null)
            .toList();
        final Map<String, int> categoriesMap =
            _getCategoriesMap(cartItemsToDisplay);

        _tabController =
            TabController(length: categoriesMap.keys.length, vsync: this);

        _cartItemsToDisplay.clear();
        _cartItemsToDisplay.addAll(cartItemsToDisplay);
        _categoriesMap.clear();
        _categoriesMap.addAll(categoriesMap);

        return _buildScaffold(_cartItemsToDisplay, _categoriesMap);
      },
      loading: () => _buildLoadingScreen(),
      error: (Object error, StackTrace? stackTrace) => _buildErrorScreen(error),
    );
  }

  Widget _buildLoadingScreen() {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
        ),
        body: Center(
          child: AdaptiveProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object error) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
        ),
        body: Center(
          child: Text('$error'),
        ),
      ),
    );
  }

  Widget _buildScaffold(
      List<CartItemModel> cartItems, Map<String, int> categoriesMap) {
    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
        ),
        body: const Center(child: Text('Please add a product first !')),
        floatingActionButton: _buildAddProductButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );
    }

    return _buildTabController(pageTitle, cartItems, categoriesMap);
  }

  Widget _buildTabController(String pageTitle, List<CartItemModel> cartItems,
      Map<String, int> categoriesMap) {
    return DefaultTabController(
      length: categoriesMap.keys.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: _buildActions(),
          bottom: _buildTabBar(categoriesMap),
        ),
        body: _buildListView(cartItems), //CartItemList(),
        // floatingActionButton: FloatingActionButton.extended(
        //   elevation: 4.0,
        //   icon: const Icon(Icons.add),
        //   label: const Text('DONE'),
        //   onPressed: _onDone,
        // ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(
          right: 12,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.delete_sharp,
            size: 30.0,
          ),
          onPressed: _showConfirmationDialog,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(
          right: 12,
        ),
        child: _buildShoppingCartBadge(),
      ),
    ];
  }

  PreferredSizeWidget _buildTabBar(Map<String, int> categoriesMap) {
    return TabBar(
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      controller: _tabController,
      labelColor: titleColor,
      unselectedLabelColor: Colors.grey,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        color: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
      // indicatorColor: backgroundColor,
      isScrollable: true,
      onTap: (int index) {
        _itemScrollController.scrollTo(
          index: categoriesMap[categoriesMap.keys.elementAt(index)] ?? 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
        );
      },
      tabs: List<Widget>.generate(categoriesMap.keys.length, (int index) {
        final String categoryName = categoriesMap.keys.elementAt(index);
        return Tab(
          text: categoryName.isEmpty ? 'No category' : categoryName,
        );
      }),
    );
  }

  Widget _buildListView(List<CartItemModel> cartItems) {
    if (cartItems.isEmpty) {
      return const Center(child: Text('No product found !'));
    }

    return ScrollablePositionedList.separated(
      padding: const EdgeInsets.all(10.0),
      itemBuilder: (BuildContext context, int index) {
        final ProductModel product = cartItems[index].product;
        final ProductModel? previousProduct =
            index >= 1 ? cartItems[index - 1].product : null;
        final bool displayHeader =
            index == 0 || product.category != previousProduct?.category;
        final String nextCategoryName =
            (product.category != null) ? product.category!.name : 'No category';

        final CartItemModel cartItem = cartItems[index];
        return displayHeader
            ? Column(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    nextCategoryName,
                    style: const TextStyle(
                      // backgroundColor: Colors.red,
                      // color: Theme.of(context).primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CartItemListTile(cartItem: cartItem),
                ],
              )
            : CartItemListTile(cartItem: cartItem);
      },
      itemCount: cartItems.length,
      separatorBuilder: (BuildContext context, int index) {
        final CartItemModel cartItem = cartItems[index];
        final ProductModel product = cartItem.product;
        final ProductModel? nextProduct =
            index < cartItems.length ? cartItems[index + 1].product : null;
        final bool isNewCategory =
            nextProduct != null && product.category != nextProduct.category;

        return isNewCategory
            ? const SizedBox(
                height: 10,
              )
            : const SizedBox(
                height: 5,
              );
      },
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
    );
  }

  Widget _buildShoppingCartBadge() {
    final CartBloc cartBloc = ref.watch(cartBlocProvider);

    return StreamBuilder<CartModel>(
      stream: cartBloc.cart$,
      builder: (BuildContext context, AsyncSnapshot<CartModel> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final String count = snapshot.data?.itemCount.toString() ?? '0';
        return badges.Badge(
          badgeStyle: const badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Colors.red,
          ),
          badgeContent: Text(count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              )),
          position: badges.BadgePosition.topEnd(top: -10, end: -5),
          child: const Icon(
            Icons.shopping_cart,
            size: 30.0,
          ),
        );
      },
    );
  }

  Widget _buildAddProductButton() {
    return FloatingActionButton.extended(
      elevation: 4.0,
      icon: const Icon(Icons.add),
      label: const Text('ADD PRODUCT'),
      onPressed: _openEditProductScreen,
    );
  }

  void _showConfirmationDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      body: const Column(
        children: <Widget>[
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
          Text('Do you want to empty your cart ?'),
        ],
      ),
      btnCancelColor: Colors.red,
      btnOkColor: Colors.green,
      btnCancelOnPress: () {
        logger.d('Cancel empty cart');
      },
      btnOkOnPress: () {
        logger.d('Confirm empty cart');
        _clearCartItems();
      },
    ).show();
  }

  void _clearCartItems() {
    final CartBloc cartBloc = ref.watch(cartBlocProvider);

    cartBloc.removeAllItemsFromCart();

    final List<CartItemModel> cartItems = _initialCartItems
        .map(
            (CartItemModel c) => CartItemModel(product: c.product, quantity: 0))
        .toList();

    setState(() {
      _initialCartItems.clear();
      _initialCartItems.addAll(cartItems);
    });
  }

  void _openEditProductScreen() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<ProductModel>(
        settings: const RouteSettings(name: ProductEditScreen.routeName),
        builder: (BuildContext context) => ProductEditScreen(),
      ),
    )
        .then((ProductModel? productCreated) {
      if (productCreated != null) {
        logger.d('Product created: $productCreated');
        // _onProductCreated(productCreated);
      }
    });
  }

  // Future<bool> _onDone() {
  //   Navigator.of(context).pop('Done');
  //   return Future<bool>.value(true);
  // }

  Map<String, int> _getCategoriesMap(List<CartItemModel> cartItems) {
    final Map<String, int> categoriesMap = <String, int>{};
    String? previousCategoryName;
    for (int i = 0; i < cartItems.length; i++) {
      final String? name = cartItems[i].product.category?.name;

      if (name != null && name != previousCategoryName) {
        categoriesMap[name] = i;
      }
      previousCategoryName = name;
    }
    return categoriesMap;
  }

  void _createTabIndexListener() {
    int previousMin = 0;
    String? previousName;
    _itemPositionsListener.itemPositions
        .listen((Iterable<ItemPosition> positions, _) {
      final ItemsPositionModel itemsPosition = _getItemsPosition(positions);

      if (itemsPosition.min != null) {
        if (itemsPosition.min != previousMin) {
          final ProductModel? product = (itemsPosition.min != null)
              ? _cartItemsToDisplay[itemsPosition.min!].product
              : null;
          final String? categoryName =
              (product != null && product.category != null)
                  ? product.category!.name
                  : null;

          if (categoryName != null && categoryName != previousName) {
            final int index =
                _categoriesMap.keys.toList().indexOf(categoryName);
            _tabController.index = index;
          }

          previousName = categoryName;
        }

        previousMin = itemsPosition.min!;
      }
    });
  }

  ItemsPositionModel _getItemsPosition(Iterable<ItemPosition> positions) {
    int? min;
    int? max;

    if (positions.isNotEmpty) {
      // Determine the first visible item by finding the item with the
      // smallest trailing edge that is greater than 0.  i.e. the first
      // item whose trailing edge in visible in the viewport.
      min = positions
          .where((ItemPosition position) => position.itemTrailingEdge > 0)
          .reduce((ItemPosition min, ItemPosition position) =>
              position.itemTrailingEdge < min.itemTrailingEdge ? position : min)
          .index;
      // Determine the last visible item by finding the item with the
      // greatest leading edge that is less than 1.  i.e. the last
      // item whose leading edge in visible in the viewport.
      max = positions
          .where((ItemPosition position) => position.itemLeadingEdge < 1)
          .reduce((ItemPosition max, ItemPosition position) =>
              position.itemLeadingEdge > max.itemLeadingEdge ? position : max)
          .index;
    }

    return ItemsPositionModel(min: min, max: max);
  }
}
