import 'package:collection/collection.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/product_model.dart';

class CartHelper {
  static List<CartItemModel> calculateProductsQuantity(
      List<CartItemModel> cartItems, List<ProductModel> products) {
    final List<CartItemModel> results = products.map((ProductModel product) {
      final CartItemModel? item = cartItems
          .firstWhereOrNull((CartItemModel item) => product == item.product);
      final int quantity = item == null ? 0 : item.quantity;

      final CartItemModel cartItem =
          CartItemModel(product: product, quantity: quantity);
      return cartItem;
    }).toList();
    return results;
  }
}
