import 'dart:math';

import 'package:collection/collection.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/json_object.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cart_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CartModel implements JsonObject {
  /// Creates a cart with items.
  CartModel({required this.cartItems});

  /// Creates a Cart from another Cart
  CartModel.clone(CartModel cart) {
    cartItems.addAll(cart.cartItems);
  }

  @override
  factory CartModel.fromJson(Map<String, dynamic> json) =>
      _$CartModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CartModelToJson(this);

  List<CartItemModel> cartItems = <CartItemModel>[];

  double get price => cartItems.fold(
      0,
      (double sum, CartItemModel item) =>
          sum + (item.product.price * item.quantity));

  /// The total count of items in cart, including duplicates of the same item.
  ///
  /// This is in contrast of just doing [items.length], which only counts
  /// each product once, regardless of how many are being bought.
  int get itemCount =>
      cartItems.fold(0, (int sum, CartItemModel item) => sum + item.quantity);

  /// This is the current state of the cart.
  ///
  /// This is a list because users expect their cart items to be in the same
  /// order they bought them.
  ///
  /// It is an unmodifiable view because we don't want a random widget to
  /// put the cart into a bad state. Use [add] and [remove] to modify the state.
  UnmodifiableListView<CartItemModel> get items =>
      UnmodifiableListView<CartItemModel>(cartItems);

  /// Adds [product] to cart. This will either update an existing [CartItemModel]
  /// in [items] or add a one at the end of the list.
  void add(ProductModel? product, [int? count = 1]) {
    _updateCount(product, count);
  }

  /// Removes [product] from cart. This will either update the count of
  /// an existing [CartItemModel] in [items] or remove it entirely (if count reaches
  /// `0`.
  void remove(ProductModel? product, [int count = 1]) {
    _updateCount(product, -count);
  }

  void addAll(List<CartItemModel> cartItems) {
    cartItems.map(
        (CartItemModel cartItem) => add(cartItem.product, cartItem.quantity));
  }

  void _updateCount(ProductModel? product, int? difference) {
    if (difference == 0 || product == null) {
      return;
    }

    for (int i = 0; i < cartItems.length; i++) {
      final CartItemModel item = cartItems[i];
      if (product == item.product) {
        final int newCount = item.quantity + difference!;
        if (newCount <= 0) {
          cartItems.removeAt(i);
          return;
        }
        cartItems[i] = CartItemModel(product: item.product, quantity: newCount);
        return;
      }
    }

    if (difference! < 0) {
      return;
    }

    cartItems
        .add(CartItemModel(product: product, quantity: max(difference, 0)));
  }

  @override
  String toString() => 'items: $cartItems';
}
