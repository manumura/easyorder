import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/bloc/cart_bloc.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/state/providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CartItemListTile extends ConsumerStatefulWidget {
  CartItemListTile({required this.cartItem});

  final CartItemModel cartItem;

  @override
  ConsumerState<CartItemListTile> createState() => _CartItemListTileState();
}

class _CartItemListTileState extends ConsumerState<CartItemListTile> {
  int _count = 0;
  bool _isMinusButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    _initCount();
  }

  @override
  void didUpdateWidget(CartItemListTile oldWidget) {
    _initCount();
    super.didUpdateWidget(oldWidget);
  }

  void _initCount() {
    _count = widget.cartItem.quantity;
    _isMinusButtonDisabled = _count <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final CartBloc cartBloc = ref.watch(cartBlocProvider);
    return _buildCard(_buildListTile(context, cartBloc));
  }

  Widget _buildCard(Widget child) {
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

  Widget _buildListTile(BuildContext context, CartBloc cartBloc) {
    return ListTile(
      leading: _buildAvatar(),
      title: Text(widget.cartItem.product.name),
      subtitle: Text('\$${widget.cartItem.product.price.toString()}'),
      trailing: _buildAddRemoveButtons(context, cartBloc, widget.cartItem),
    );
  }

  Widget _buildAvatar() {
    final Widget circleAvatar = widget.cartItem.product.imageUrl == null
        ? const CircleAvatar(
            backgroundImage: AssetImage('assets/placeholder.jpg'),
          )
        : CachedNetworkImage(
            imageUrl: widget.cartItem.product.imageUrl!,
            imageBuilder:
                (BuildContext context, ImageProvider<Object> imageProvider) =>
                    CircleAvatar(
              backgroundImage: imageProvider,
            ),
            progressIndicatorBuilder: (BuildContext context, String url,
                    DownloadProgress downloadProgress) =>
                CircularProgressIndicator(value: downloadProgress.progress),
            errorWidget: (BuildContext context, String url, Object? error) =>
                const Icon(Icons.error),
          );

    return circleAvatar;
  }

  Widget _buildAddRemoveButtons(
      BuildContext context, CartBloc cartBloc, CartItemModel cartItem) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: _isMinusButtonDisabled
              ? null
              : () => _decrement(cartBloc, cartItem),
          disabledColor: Colors.grey,
          color: Colors.black,
        ),
        Text('$_count'),
        IconButton(
          icon: const Icon(
            Icons.add,
          ),
          onPressed: () => _increment(cartBloc, cartItem),
          color: Colors.black,
        ),
      ],
    );
  }

  void _increment(CartBloc cartBloc, CartItemModel cartItem) {
    cartBloc
        .addItemToCart(CartItemModel(product: cartItem.product, quantity: 1));
    setState(() {
      _count = _count + 1;
      _isMinusButtonDisabled = _count <= 0;
    });
  }

  void _decrement(CartBloc cartBloc, CartItemModel cartItem) {
    cartBloc.removeItemFromCart(
        CartItemModel(product: cartItem.product, quantity: 1));
    setState(() {
      _count = _count - 1;
      _isMinusButtonDisabled = _count <= 0;
    });
  }
}
