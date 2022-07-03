import 'package:another_flushbar/flushbar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/product_list_state_notifier.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:easyorder/widgets/products/product_list_tile.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class ProductSlidableListTile extends ConsumerStatefulWidget {
  ProductSlidableListTile({required this.product});

  final ProductModel product;

  @override
  _ProductSlidableListTileState createState() =>
      _ProductSlidableListTileState();
}

class _ProductSlidableListTileState
    extends ConsumerState<ProductSlidableListTile> {
  bool _isLoading = false;

  final Logger logger = getLogger();

  @override
  Widget build(BuildContext context) {
    final ProductListStateNotifier productListStateNotifier =
        ref.watch(productListStateNotifierProvider.notifier);
    return _buildProductListTile(productListStateNotifier);
  }

  Widget _buildProductListTile(
      ProductListStateNotifier productListStateNotifier) {
    return _isLoading
        ? ProductLoadingListTile(product: widget.product)
        : Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.3,
              children: <Widget>[
                SlidableAction(
                  onPressed: (BuildContext context) =>
                      _showConfirmationDialog(productListStateNotifier),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: ProductSwitchListTile(
              key: ValueKey<String?>(widget.product.uuid),
              product: widget.product,
              onToggle: (bool value) =>
                  _toggleActive(context, productListStateNotifier, value),
            ),
          );
  }

  void _showConfirmationDialog(
      ProductListStateNotifier productListStateNotifier) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.WARNING,
      animType: AnimType.BOTTOMSLIDE,
      body: Column(
        children: const <Widget>[
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
          Text('Do you want to delete this product ?'),
          Text('It will be removed from current orders.'),
        ],
      ),
      btnCancelColor: Colors.red,
      btnOkColor: Colors.green,
      btnCancelOnPress: () {
        logger.d('Cancel delete product ${widget.product.name}');
      },
      btnOkOnPress: () {
        logger.d('Confirm delete product ${widget.product.name}');
        _deleteProduct(productListStateNotifier);
      },
    ).show();
  }

  void _deleteProduct(ProductListStateNotifier productListStateNotifier) {
    setState(() => _isLoading = true);
    productListStateNotifier.remove(productToRemove: widget.product).then(
      (bool success) {
        setState(() => _isLoading = false);
        if (success) {
          final Flushbar<void> flushbar = UiHelper.createSuccessFlushbar(
              message: '${widget.product.name} successfully removed !',
              title: 'Success !');
          flushbar.show(navigatorKey.currentContext ?? context);
        } else {
          final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
              message: 'Failed to remove ${widget.product.name} !',
              title: 'Error !');
          flushbar.show(navigatorKey.currentContext ?? context);
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');

        String title = 'Error !';
        String content = 'Failed to remove ${widget.product.name} !';

        final bool isAlreadyInUse = err is AlreadyInUseException;
        if (isAlreadyInUse) {
          title = 'Cannot delete this product.';
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
    ProductListStateNotifier productListStateNotifier,
    bool active,
  ) {
    if (widget.product.id == null || widget.product.uuid == null) {
      logger.e('Product id is null');
      return;
    }
    setState(() => _isLoading = true);

    productListStateNotifier
        .toggleActive(
      productId: widget.product.id!,
      productUuid: widget.product.uuid!,
      active: active,
    )
        .then(
      (ProductModel? updatedProduct) {
        setState(() => _isLoading = false);
        logger.d('Product active toggle updated: $updatedProduct');
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');
        final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
            message: 'Failed to update ${widget.product.name} !',
            title: 'Error !');
        flushbar.show(navigatorKey.currentContext ?? context);
      },
    );
  }
}
