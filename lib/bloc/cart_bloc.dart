import 'dart:async';

import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/cart_model.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

abstract class CartBloc {
  Stream<CartModel> get cart$;

  void addItemToCart(CartItemModel cartItem);

  void addAllItemsToCart(CartModel cart);

  void removeItemFromCart(CartItemModel cartItem);

  void removeAllItemsFromCart();

  void dispose();
}

class CartBlocImpl implements CartBloc {
  CartBlocImpl() {
    logger.d('----- Building CartBlocImpl -----');
    final CartModel cart = CartModel(cartItems: <CartItemModel>[]);

    // Add cart item
    _cartAddSubject.stream.listen(
      (CartItemModel cartItem) {
        cart.add(cartItem.product, cartItem.quantity);
        _cartSubject.add(cart);
      },
      onError: (Object error) => logger.e('_cartAddSubject listen error: '
          '$error'),
      cancelOnError: false,
    );

    // Remove cart item
    _cartRemoveSubject.stream.listen(
      (CartItemModel cartItem) {
        cart.remove(cartItem.product, cartItem.quantity);
        _cartSubject.add(cart);
      },
      onError: (Object error) => logger.e('_cartRemoveSubject listen error: '
          '$error'),
      cancelOnError: false,
    );

    // Remove all items from cart
    _cartRemoveAllItemsSubject.stream.listen(
      (bool b) {
        cart.cartItems.clear();
        _cartSubject.add(cart);
      },
      onError: (Object error) =>
          logger.e('_cartRemoveAllItemsSubject listen error: '
              '$error'),
      cancelOnError: false,
    );
  }

  final Logger logger = getLogger();

  final BehaviorSubject<CartModel> _cartSubject =
      BehaviorSubject<CartModel>.seeded(
          CartModel(cartItems: <CartItemModel>[]));

  // Add / remove items in cart
  final PublishSubject<CartItemModel> _cartAddSubject =
      PublishSubject<CartItemModel>();
  final PublishSubject<CartItemModel> _cartRemoveSubject =
      PublishSubject<CartItemModel>();
  final PublishSubject<bool> _cartRemoveAllItemsSubject =
      PublishSubject<bool>();

  @override
  Stream<CartModel> get cart$ => _cartSubject.stream;

  @override
  void addItemToCart(CartItemModel cartItem) {
    _cartAddSubject.add(cartItem);
  }

  @override
  void addAllItemsToCart(CartModel cart) {
    for (final CartItemModel cartItem in cart.cartItems) {
      addItemToCart(cartItem);
    }
  }

  @override
  void removeItemFromCart(CartItemModel cartItem) {
    _cartRemoveSubject.add(cartItem);
  }

  @override
  void removeAllItemsFromCart() {
    _cartRemoveAllItemsSubject.add(true);
  }

  // Combine all products with cart items
  // Stream<List<CartItemModel>> findAllItems(
  //     Stream<CartModel> cart$, Stream<List<ProductModel>> products$) {
  //   final Stream<List<CartItemModel>> allItems$ =
  //       Rx.combineLatest2(cart$, products$, _calculateProductsQuantity);
  //   return allItems$;
  // }

  // List<CartItemModel> _calculateProductsQuantity(
  //     CartModel cart, List<ProductModel> products) {
  //   final List<CartItemModel> results = products.map((ProductModel product) {
  //     final CartItemModel? item = cart.items
  //         .firstWhereOrNull((CartItemModel item) => product == item.product);
  //     final int quantity = item == null ? 0 : item.quantity;
  //
  //     final CartItemModel cartItem =
  //         CartItemModel(product: product, quantity: quantity);
  //     return cartItem;
  //   }).toList();
  //   return results;
  // }

  @override
  void dispose() {
    logger.d('*** DISPOSE CartBloc ***');
    _cartSubject.close();
    _cartAddSubject.close();
    _cartRemoveSubject.close();
    _cartRemoveAllItemsSubject.close();
  }
}
