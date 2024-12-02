import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:easyorder/bloc/cart_bloc.dart';
import 'package:easyorder/bloc/customer_bloc.dart';
import 'package:easyorder/bloc/order_bloc.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/cart_model.dart';
import 'package:easyorder/models/customer_model.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/pages/cart_screen.dart';
import 'package:easyorder/pages/customer_edit_screen.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/customers/customer_list_tile.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/helpers/validator.dart';
import 'package:easyorder/widgets/orders/order_items_list_tile.dart';
import 'package:easyorder/widgets/orders/price_total_tag.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:logger/logger.dart';

class OrderEditScreen extends ConsumerStatefulWidget {
  OrderEditScreen([this._currentOrder]);

  static const String routeName = '/order_edit';

  final OrderModel? _currentOrder;

  @override
  ConsumerState<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends ConsumerState<OrderEditScreen> {
  final Logger logger = getLogger();

  bool _isLoading = false;
  bool _isSaveDisabled = false;
  bool _isOrderCompleted = false;

  final _FormData _formData = _FormData();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _clientIdFocusNode = FocusNode();
  final FocusNode _customerFocusNode = FocusNode();
  final FocusNode _creationDateFocusNode = FocusNode();
  final FocusNode _dueDateFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  final TextEditingController _customerTextController = TextEditingController();
  bool _isCustomerClearVisible = false;
  final TextEditingController _descriptionTextController =
      TextEditingController();
  bool _isDescriptionClearVisible = false;

  // Cart items to save
  final List<CartItemModel> _cartItems = <CartItemModel>[];
  // Customer to save
  CustomerModel? _selectedCustomer;

  late CartBloc _cartBloc;
  late OrderBloc _orderBloc;

  @override
  void initState() {
    super.initState();

    _isOrderCompleted = widget._currentOrder?.status == OrderStatus.completed;

    _customerTextController.addListener(_toggleCustomerClearVisible);
    _customerTextController.text = (widget._currentOrder == null)
        ? ''
        : widget._currentOrder!.customer.name;

    _descriptionTextController.addListener(_toggleDescriptionClearVisible);
    _descriptionTextController.text = (widget._currentOrder == null ||
            widget._currentOrder!.description == null)
        ? ''
        : widget._currentOrder!.description!;

    _selectedCustomer = widget._currentOrder?.customer;

    // Add current order items to cart
    _cartBloc = ref.read(cartBlocProvider);
    _cartBloc.removeAllItemsFromCart();
    if (widget._currentOrder != null && widget._currentOrder!.cart != null) {
      _cartBloc.addAllItemsToCart(widget._currentOrder!.cart!);
    }
  }

  @override
  void dispose() {
    _customerTextController.dispose();
    _descriptionTextController.dispose();

    _clientIdFocusNode.dispose();
    _customerFocusNode.dispose();
    _creationDateFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _dueDateFocusNode.dispose();
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
        _orderBloc = orderBloc;

        return _buildCartItemsStreamBuilder();
      },
      loading: () => _buildLoadingScreen(),
      error: (Object err, StackTrace? stack) => _buildErrorScreen(err),
    );
  }

  Widget _buildCartItemsStreamBuilder() {
    return StreamBuilder<CartModel>(
      stream: _cartBloc.cart$,
      builder: (BuildContext context, AsyncSnapshot<CartModel> snapshot) {
        // Reset cart items
        _cartItems.clear();

        if (snapshot.hasError) {
          return _buildErrorScreen(
              snapshot.error ?? 'Error while loading cart items');
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        // Set the cart items list
        final List<CartItemModel> items = snapshot.data!.items;
        _cartItems.addAll(items);

        final double price = snapshot.data?.price ?? 0;
        // return _buildScaffold(items, price);
        return _buildCustomersStreamBuilder(items, price);
      },
    );
  }

  Widget _buildCustomersStreamBuilder(
      List<CartItemModel> cartItems, double price) {
    final AsyncValue<CustomerBloc?> customerBloc$ =
        ref.watch(customerBlocProvider);

    return customerBloc$.when(
      data: (CustomerBloc? customerBloc) {
        if (customerBloc == null) {
          return _buildErrorScreen('No customer found');
        }
        return StreamBuilder<List<CustomerModel>>(
          stream: customerBloc.activeCustomers$,
          builder: (BuildContext context,
              AsyncSnapshot<List<CustomerModel>> snapshot) {
            if (snapshot.hasError) {
              return _buildErrorScreen(
                  snapshot.error ?? 'Error while loading customers');
            }

            if (!snapshot.hasData) {
              return _buildLoadingScreen();
            }

            final List<CustomerModel> customers = snapshot.data!;
            _isSaveDisabled =
                customers.isEmpty && widget._currentOrder?.customer == null;

            return _buildScaffold(cartItems, price, customers);
          },
        );
      },
      loading: () => _buildLoadingScreen(),
      error: (Object err, StackTrace? stack) => _buildErrorScreen(err),
    );
  }

  Widget _buildScaffold(List<CartItemModel> cartItems, double price,
      List<CustomerModel> customers) {
    final OrderModel? currentOrder = widget._currentOrder;
    final Widget body =
        _buildBody(context, currentOrder, cartItems, price, customers);
    final String title = (currentOrder == null) ? 'Create Order' : 'Edit Order';

    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: AdaptiveProgressIndicator(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          actions: <Widget>[
            if (widget._currentOrder != null) _buildDeleteButton(),
            _buildSubmitButton(),
          ],
        ),
        body: body,
        bottomNavigationBar: _buildBottomAppBar(cartItems, price),
      ),
    );
  }

  Widget _buildBottomAppBar(List<CartItemModel> cartItems, double price) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        _buildPriceTotalTag(price),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (!_isOrderCompleted) _buildOpenCartScreenButton(cartItems),
            if (widget._currentOrder != null) _buildCompleteOrReopenButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context,
      OrderModel? order,
      List<CartItemModel> cartItems,
      double price,
      List<CustomerModel> customers) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
          child: Column(
            children: <Widget>[
              _buildForm(order, customers),
              const SizedBox(
                height: 10.0,
              ),
              _buildCartItemsList(cartItems),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(OrderModel? order, List<CustomerModel> customers) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 5,
          ),
          _buildCustomerField(customers),
          const SizedBox(
            height: 5,
          ),
          _buildDateTimeField(order),
          const SizedBox(
            height: 5,
          ),
          _buildDescriptionTextField(),
          const SizedBox(
            height: 5,
          ),
          _buildDueDateTimeField(order),
        ],
      ),
    );
  }

  Widget _buildCustomerField(List<CustomerModel> customers) {
    if (_isOrderCompleted) {
      return _buildDisabledCustomerTextField();
    }

    if (customers.isEmpty) {
      if (widget._currentOrder?.customer != null) {
        const Widget addCustomerTextWidget = Center(
          child: Text(
            '* No active customer found',
            style: TextStyle(color: Colors.red),
          ),
        );
        return Column(
          children: <Widget>[
            _buildCustomerRow(_buildDisabledCustomerTextField()),
            addCustomerTextWidget,
          ],
        );
      } else {
        const Widget addCustomerTextWidget = Center(
          child: Text(
            '* Please add an active customer first',
            style: TextStyle(color: Colors.red),
          ),
        );
        return _buildCustomerRow(addCustomerTextWidget);
      }
    }

    final Widget child = _buildCustomerAutocompleteField(customers);
    return _buildCustomerRow(child);
  }

  Widget _buildCustomerRow(Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 7,
          child: child,
        ),
        Expanded(
          child: IconButton(
            iconSize: 36,
            icon: const Icon(Icons.add_circle),
            // color: Theme.of(context).colorScheme.secondary,
            onPressed: _openEditCustomerScreen,
          ),
        ),
      ],
    );
  }

  // Widget _buildCustomerDropdownMenu(List<CustomerModel> customers) {
  //   final List<DropdownMenuEntry<CustomerModel>> entries = customers
  //       .map((CustomerModel customer) => DropdownMenuEntry<CustomerModel>(
  //           value: customer, label: customer.name))
  //       .toList();
  //   return DropdownMenu<CustomerModel>(
  //     dropdownMenuEntries: entries,
  //     onSelected: (CustomerModel? selected) {
  //       print('selected' + selected.toString());
  //       _selectedCustomer = selected;
  //     },
  //     controller: _customerTextController,
  //     initialSelection: widget._currentOrder?.customer,
  //     enabled: !_isOrderCompleted,
  //     enableFilter: true,
  //     requestFocusOnTap: true,
  //     leadingIcon: const Icon(Icons.search),
  //     label: const Text('Customer *'),
  //     inputDecorationTheme: InputDecorationTheme(
  //       filled: true,
  //       contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
  //       fillColor: Colors.white,
  //     ),
  //     width: 300,
  //   );
  // }

  Widget _buildCustomerAutocompleteField(List<CustomerModel> customers) {
    return TypeAheadField<CustomerModel>(
      builder: (BuildContext context, TextEditingController controller,
          FocusNode focusNode) {
        return TextFormField(
          controller: controller, //_customerTextController,
          enabled: !_isOrderCompleted,
          focusNode: focusNode, // _customerFocusNode,
          validator: (String? value) {
            return Validator.validateCustomer(value);
          },
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: Icon(
                Icons.perm_identity,
              ),
            ),
            suffixIcon: !_isCustomerClearVisible
                ? const SizedBox()
                : IconButton(
                    onPressed: () {
                      controller.clear(); // _customerTextController.clear();
                    },
                    icon: const Icon(
                      Icons.clear,
                    ),
                  ),
            labelText: 'Customer *',
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
            filled: true,
            fillColor: Colors.white,
          ),
        );
      },
      controller: _customerTextController,
      debounceDuration: const Duration(milliseconds: 300),
      itemBuilder: (BuildContext context, CustomerModel customer) {
        return CustomerAutocompleteListTile(
            key: ValueKey<String?>(customer.uuid), customer: customer);
      },
      emptyBuilder: (BuildContext context) {
        return const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: Text(
            'No active customer found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      },
      transitionBuilder:
          (BuildContext context, Animation<double> animation, Widget child) {
        return child;
      },
      suggestionsCallback: (String pattern) {
        return _filterByNameContaining(customers, pattern);
      },
      onSelected: (CustomerModel customer) {
        _selectedCustomer = customer;
        _customerTextController.text = customer.name;
      },
    );
  }

  Widget _buildDisabledCustomerTextField() {
    return TextFormField(
      controller: _customerTextController,
      enabled: false,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Icon(
            Icons.perm_identity,
          ),
        ),
        labelText: 'Customer *',
        contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimeField(OrderModel? order) {
    return DateTimeField(
      enabled: !_isOrderCompleted,
      focusNode: _creationDateFocusNode,
      format: DateFormat('EEEE, MMMM d, yyyy h:mma'),
      initialValue: order?.date ?? DateTime.now(),
      resetIcon: const Icon(Icons.clear),
      onShowPicker: _onShowPickerCreationDate,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Icon(
            Icons.calendar_today,
          ),
        ),
        labelText: 'Date *',
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (DateTime? value) {
        return Validator.validateOrderCreationDate(value);
      },
      onSaved: (DateTime? value) {
        _formData.creationDate = value;
      },
    );
  }

  Widget _buildDueDateTimeField(OrderModel? order) {
    return DateTimeField(
      enabled: !_isOrderCompleted,
      focusNode: _dueDateFocusNode,
      format: DateFormat('EEEE, MMMM d, yyyy h:mma'),
      initialValue: order?.dueDate,
      resetIcon: const Icon(Icons.clear),
      onShowPicker: _onShowPickerDueDate,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Icon(
            Icons.calendar_today,
          ),
        ),
        labelText: 'Due Date',
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      // validator: (DateTime? value) {
      //   return Validator.validateOrderDueDate(value);
      // },
      onSaved: (DateTime? value) {
        _formData.dueDate = value;
      },
    );
  }

  Widget _buildDescriptionTextField() {
    return TextFormField(
      maxLength: Constants.maxOrderDescriptionLength,
      maxLines: 3,
      enabled: !_isOrderCompleted,
      focusNode: _descriptionFocusNode,
      controller: _descriptionTextController,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Icon(
            Icons.description,
          ),
        ),
        suffixIcon: !_isDescriptionClearVisible
            ? const SizedBox()
            : IconButton(
                onPressed: () {
                  _descriptionTextController.clear();
                },
                icon: const Icon(
                  Icons.clear,
                ),
              ),
        labelText: 'Description',
        counterStyle: const TextStyle(
          height: double.minPositive,
        ),
        contentPadding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (String? value) {
        return Validator.validateOrderDescription(value);
      },
      onSaved: (String? value) {
        _formData.description = value;
      },
    );
  }

  Widget _buildCartItemsList(List<CartItemModel> cartItems) {
    if (cartItems.isEmpty) {
      return const Center(child: Text('No item selected'));
    }

    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        final CartItemModel item = cartItems[index];
        return OrderItemsListTile(item: item);
      },
      itemCount: cartItems.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      // https://medium.com/flutterpub/flutter-listview-gridview-inside-scrollview-68b722ae89d4
      // https://stackoverflow.com/questions/45270900/child-listview-within-listview-parent
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
    );
  }

  Widget _buildSubmitButton() {
    return _isOrderCompleted
        ? const SizedBox()
        : IconButton(
            onPressed:
                _isLoading || _isSaveDisabled ? null : () => _submitForm(),
            icon: const Icon(
              Icons.save,
              // color: Colors.white,
              size: 30,
            ),
          );
  }

  Widget _buildDeleteButton() {
    return IconButton(
      onPressed: _isLoading ? null : () => _showConfirmationDialog(),
      icon: const Icon(
        Icons.delete_forever,
        // color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildPriceTotalTag(double price) {
    return PriceTotalTag(price: price);
  }

  Widget _buildOpenCartScreenButton(List<CartItemModel> cartItems) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ElevatedButton.icon(
          style: ButtonStyle(
            shape: WidgetStateProperty.resolveWith(
              (Set<WidgetState> states) => ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => Colors.white),
            backgroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) =>
                    Theme.of(context).colorScheme.secondary),
            elevation: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => 4.0),
          ),
          label: (cartItems.isEmpty)
              ? const Text('ADD TO CART')
              : const Text('MY CART'),
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () => _openCartScreen(cartItems),
        ),
      ),
    );
  }

  Widget _buildCompleteOrReopenButton() {
    final String label = _isOrderCompleted ? 'REOPEN' : 'COMPLETE';
    final Icon icon = _isOrderCompleted
        ? const Icon(Icons.open_in_new)
        : const Icon(Icons.check);
    final Color color = _isOrderCompleted ? Colors.blue : Colors.green;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ElevatedButton.icon(
          style: ButtonStyle(
            shape: WidgetStateProperty.resolveWith(
              (Set<WidgetState> states) => ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => Colors.white),
            backgroundColor: WidgetStateProperty.resolveWith(
                (Set<WidgetState> states) => color),
          ),
          label: Text(label),
          icon: icon,
          onPressed: () => _updateOrderStatus(!_isOrderCompleted),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final String title =
        (widget._currentOrder == null) ? 'Create Order' : 'Edit Order';
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: _buildLoadingIndicator(),
      ),
    );
  }

  Widget _buildErrorScreen(Object err) {
    final String title =
        (widget._currentOrder == null) ? 'Create Order' : 'Edit Order';
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: AdaptiveProgressIndicator(),
    );
  }

  void _submitForm() {
    setState(() => _isLoading = true);
    final CartModel cart = CartModel(cartItems: _cartItems);

    if (_formKey.currentState == null) {
      logger.e('Cannot submit form : formKey currentState is null');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    if (_selectedCustomer == null) {
      setState(() => _isLoading = false);
      return;
    }

    _formKey.currentState!.save();

    if (widget._currentOrder == null) {
      _createOrder(cart);
    } else {
      _updateOrder(cart);
    }
  }

  void _createOrder(CartModel cart) {
    final OrderModel orderToCreate = OrderModel(
      customer: _selectedCustomer!,
      date: _formData.creationDate == null
          ? DateTime.now()
          : _formData.creationDate!,
      dueDate: _formData.dueDate,
      description: _formData.description,
      cart: cart,
    );

    _orderBloc.create(order: orderToCreate).then(
      (bool success) {
        setState(() => _isLoading = false);
        if (mounted && success) {
          Navigator.of(context).pop('CREATE');
        } else {
          _showErrorDialog();
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);
        _showErrorDialog();
      },
    );
  }

  void _updateOrder(CartModel cart) {
    if (widget._currentOrder == null || widget._currentOrder!.id == null) {
      logger.e('Current order or id cannot be null');
      return;
    }

    final OrderModel orderToUpdate = OrderModel.clone(widget._currentOrder!);
    orderToUpdate.customer = _selectedCustomer!;
    orderToUpdate.date = _formData.creationDate == null
        ? widget._currentOrder!.date
        : _formData.creationDate!;
    orderToUpdate.dueDate = _formData.dueDate;
    orderToUpdate.description = _formData.description;
    orderToUpdate.cart = cart;

    _orderBloc
        .update(orderId: widget._currentOrder!.id!, order: orderToUpdate)
        .then(
      (bool success) {
        setState(() => _isLoading = false);
        if (mounted && success) {
          Navigator.of(context).pop('UPDATE');
        } else {
          _showErrorDialog();
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);
        _showErrorDialog();
      },
    );
  }

  void _updateOrderStatus(bool isCompleted) {
    if (widget._currentOrder == null || widget._currentOrder!.id == null) {
      logger.e('Current order or id cannot be null');
      return;
    }

    setState(() => _isLoading = true);

    _orderBloc
        .updateStatus(
            orderId: widget._currentOrder!.id!,
            order: widget._currentOrder!,
            status: isCompleted ? OrderStatus.completed : OrderStatus.pending)
        .then(
      (bool success) {
        setState(() => _isLoading = false);
        if (mounted && success) {
          Navigator.of(context).pop(isCompleted ? 'COMPLETE' : 'REOPEN');
        } else {
          _showErrorDialog();
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);
        _showErrorDialog();
      },
    );
  }

  void _showConfirmationDialog() {
    if (widget._currentOrder == null) {
      return;
    }

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
          Text('Do you want to delete this order ?'),
          Text('It will be removed permanently.')
        ],
      ),
      btnCancelColor: Colors.red,
      btnOkColor: Colors.green,
      btnCancelOnPress: () {
        logger.d('Cancel delete order ${widget._currentOrder!.uuid}');
      },
      btnOkOnPress: () {
        logger.d('Confirm delete order ${widget._currentOrder!.uuid}');
        _deleteOrder();
      },
    ).show();
  }

  void _deleteOrder() {
    if (widget._currentOrder == null) {
      return;
    }

    setState(() => _isLoading = true);

    _orderBloc.delete(orderId: widget._currentOrder!.id!).then(
      (bool success) {
        setState(() => _isLoading = false);
        if (mounted && success) {
          Navigator.pop(context);
        } else {
          _showErrorDialog();
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');
        setState(() => _isLoading = false);
        _showErrorDialog();
      },
    );
  }

  Future<DateTime?> _onShowPickerCreationDate(
      BuildContext context, DateTime? currentValue) async {
    return _onShowPicker(context,
        currentValue: currentValue,
        lastDate: DateTime(2100)); // DateTime.now());
  }

  Future<DateTime?> _onShowPickerDueDate(
      BuildContext context, DateTime? currentValue) async {
    return _onShowPicker(context,
        currentValue: currentValue,
        firstDate: DateTime(2010)); // DateTime.now());
  }

  Future<DateTime?> _onShowPicker(BuildContext context,
      {DateTime? currentValue, DateTime? firstDate, DateTime? lastDate}) async {
    final DateTime? date = await showDatePicker(
        context: context,
        firstDate: firstDate ?? DateTime(2010),
        lastDate: lastDate ?? DateTime(2100),
        initialDate: currentValue ?? DateTime.now());
    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
      );
      return DateTimeField.combine(date, time);
    } else {
      return currentValue;
    }
  }

  List<CustomerModel> _filterByNameContaining(
      List<CustomerModel> initialCustomers, String pattern) {
    if (pattern.isEmpty) {
      return initialCustomers;
    }

    return initialCustomers
        .where((CustomerModel c) =>
            c.name.toUpperCase().contains(pattern.toUpperCase()))
        .toList();
  }

  void _openCartScreen(final List<CartItemModel> cartItems) {
    final Widget cartScreen = CartScreen(cartItems: cartItems);

    Navigator.of(context)
        .push(
      MaterialPageRoute<String>(
        // settings: const RouteSettings(name: CartScreen.routeName),
        builder: (BuildContext context) => cartScreen,
      ),
    )
        .then(
      (String? value) {
        logger.d('Back to order edit screen: $value');
      },
    );
  }

  void _openEditCustomerScreen() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<CustomerModel>(
        settings: const RouteSettings(name: CustomerEditScreen.routeName),
        builder: (BuildContext context) => const CustomerEditScreen(),
      ),
    )
        .then(
      (CustomerModel? value) {
        logger.d('Back to order edit screen: $value');
      },
    );
  }

  void _showErrorDialog() {
    UiHelper.showAlertDialog(
        context, AlertType.error, genericErrorTitle, genericErrorMessage);
  }

  void _toggleCustomerClearVisible() {
    setState(() {
      _isCustomerClearVisible =
          _customerTextController.text.isNotEmpty && !_isOrderCompleted;
    });
  }

  void _toggleDescriptionClearVisible() {
    setState(() {
      _isDescriptionClearVisible =
          _descriptionTextController.text.isNotEmpty && !_isOrderCompleted;
    });
  }
}

class _FormData {
  String? clientId;
  DateTime? creationDate;
  DateTime? dueDate;
  String? description;
}
