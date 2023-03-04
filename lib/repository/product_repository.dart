import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/exceptions/not_unique_exception.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class ProductRepository {
  Stream<List<ProductModel>> findActive({required String userId});

  Future<List<ProductModel>> find(
      {required String userId, int? pageSize, ProductModel? lastProduct});

  Stream<int?> count({required String userId});

  Future<List<ProductModel>> findByName({required String userId, String? name});

  Future<List<ProductModel>> findByCategory(
      {required CategoryModel category, required String userId});

  Future<String?> create(
      {required String userId, required ProductModel product});

  Future<bool> update(
      {required String userId,
      required String productId,
      required ProductModel product});

  Future<ProductModel?> toggleActive({
    required String userId,
    required String productId,
    required String productUuid,
    required bool active,
  });

  Future<bool> delete(
      {required String userId,
      required String productId,
      required String productUuid});
}

class ProductRepositoryFirebaseImpl implements ProductRepository {
  final FirebaseFirestore _store = FirebaseFirestore.instance;
  final Logger logger = getLogger();

  @override
  Stream<List<ProductModel>> findActive({required String userId}) {
    logger.d('find active products ordered by category');

    try {
      // Find products with category
      final Stream<List<ProductModel>> products$ = _store
          .collection('users')
          .doc(userId)
          .collection('products')
          .where('active', isEqualTo: true)
          .orderBy('categoryName')
          .orderBy('name')
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
        final List<ProductModel> products = querySnapshot.docs
            .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
                ProductModel.fromSnapshot(documentSnapshot))
            .toList();
        return products;
      });

      return products$;
    } on Exception catch (ex) {
      logger.e(ex);
      return const Stream<List<ProductModel>>.empty();
    }
  }

  @override
  Future<List<ProductModel>> find(
      {required String userId,
      int? pageSize,
      ProductModel? lastProduct}) async {
    logger.d('find products: pageSize=$pageSize, lastProduct=$lastProduct');

    try {
      // Find documents by user id
      Query<Map<String, dynamic>> query = _store
          .collection('users')
          .doc(userId)
          .collection('products')
          .orderBy('categoryName')
          .orderBy('name');

      if (lastProduct != null) {
        final List<dynamic> startAt = <dynamic>[];
        if (lastProduct.category != null) {
          startAt.add(lastProduct.category!.name);
        }
        startAt.add(lastProduct.name);
        query = query.startAfter(startAt);
      }

      if (pageSize != null) {
        query = query.limit(pageSize);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();

      final List<ProductModel> products = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              ProductModel.fromSnapshot(documentSnapshot))
          .toList();

      return products;
    } on Exception catch (ex) {
      logger.e(ex);
      return Future<List<ProductModel>>.value(<ProductModel>[]);
    }
  }

  @override
  Stream<int?> count({required String userId}) {
    logger.d('count products');

    try {
      // Find documents by user id
      final DocumentReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId);
      final Stream<DocumentSnapshot<Map<String, dynamic>>> documentSnapshot$ =
          ref.snapshots();
      final Stream<int?> count$ = documentSnapshot$
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
        return documentSnapshot.data() != null
            ? int.tryParse(documentSnapshot.data()!['productsCount'].toString())
            : 0;
      });

      return count$;
    } on Exception catch (ex) {
      logger.e(ex);
      return Stream<int>.value(0);
    }
  }

  @override
  Future<List<ProductModel>> findByName(
      {required String userId, String? name}) async {
    logger.d('find products by name: $name');

    try {
      // Find documents by user id
      Query<Map<String, dynamic>> query = _store
          .collection('users')
          .doc(userId)
          .collection('products')
          // .orderBy('categoryName')
          .orderBy('nameToUpperCase');

      if (name != null) {
        final List<dynamic> startAt = <dynamic>[name.toUpperCase()];
        final List<dynamic> endAt = <dynamic>[name.toUpperCase() + '~'];
        query = query.startAt(startAt).endAt(endAt);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();

      final List<ProductModel> products = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              ProductModel.fromSnapshot(documentSnapshot))
          .toList();
      return products;
    } on Exception catch (e) {
      logger.e(e);
      return Future<List<ProductModel>>.value(<ProductModel>[]);
    }
  }

  @override
  Future<List<ProductModel>> findByCategory(
      {required CategoryModel category, required String userId}) async {
    logger.d('find products by category: ${category.name}');

    try {
      // Find documents by user id
      final CollectionReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId).collection('products');

      Query<Map<String, dynamic>> query = ref.orderBy('name');
      query = query.where('category.uuid', isEqualTo: category.uuid);

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();
      final List<ProductModel> products = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              ProductModel.fromSnapshot(documentSnapshot))
          .toList();

      return products;
    } on Exception catch (ex) {
      logger.e(ex);
      return Future<List<ProductModel>>.value(<ProductModel>[]);
    }
  }

  @override
  Future<String?> create(
      {required String userId, required ProductModel product}) async {
    if (product.userId == null ||
        product.userEmail == null ||
        product.uuid == null ||
        product.description == null ||
        product.category == null) {
      logger.e('Invalid parameters');
      return null;
    }

    // Check name is unique
    final bool isNameUnique;
    try {
      isNameUnique =
          await _isNameUnique(userId: userId, productName: product.name);
    } catch (error) {
      logger.e('create product error: $error');
      return null;
    }

    if (!isNameUnique) {
      throw NotUniqueException('This product name is already used.');
    }

    try {
      final Map<String, dynamic> productAsJson = product.toJson();
      productAsJson['createdDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      productAsJson['nameToUpperCase'] = product.name.toUpperCase();
      productAsJson['categoryName'] = product.category?.name;
      productAsJson['categoryNameToUpperCase'] =
          product.category?.name.toUpperCase();
      logger.d('productData: $productAsJson');

      // Add document by user id
      final DocumentReference<Map<String, dynamic>> docRef = await _store
          .collection('users')
          .doc(product.userId)
          .collection('products')
          .add(productAsJson);
      logger.d('Create success: new product ID= ${docRef.id}');
      return docRef.id;
    } catch (error) {
      logger.e('create product error: $error');
      return null;
    }
  }

  @override
  Future<bool> update(
      {required String userId,
      required String productId,
      required ProductModel product}) async {
    if (product.userId == null ||
        product.userEmail == null ||
        product.uuid == null ||
        product.description == null ||
        product.category == null) {
      logger.e('Invalid parameters');
      return false;
    }

    // Check name is unique
    final bool isNameUnique;
    try {
      isNameUnique = await _isNameUnique(
          userId: userId, productName: product.name, productUuid: product.uuid);
    } catch (error) {
      logger.e('updateProduct error: $error');
      return false;
    }

    if (!isNameUnique) {
      throw NotUniqueException('This product name is already used.');
    }

    // Check no completed order with this product
    final bool isCompletedOrderWithProductExist;
    try {
      isCompletedOrderWithProductExist =
          await _isCompletedOrderWithProductExist(
              productUuid: product.uuid!, userId: userId);
    } catch (error) {
      logger.e('updateProduct error: $error');
      return false;
    }

    if (isCompletedOrderWithProductExist) {
      throw AlreadyInUseException(
          'This product is associated with a completed order.');
    }

    try {
      final Map<String, dynamic> productAsJson = product.toJson();
      productAsJson['updatedDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      productAsJson['nameToUpperCase'] = product.name.toUpperCase();
      productAsJson['categoryName'] = product.category?.name;
      productAsJson['categoryNameToUpperCase'] =
          product.category?.name.toUpperCase();
      logger.d('updatedProduct: $productAsJson');

      // Init batch write
      logger.d('running batch write');
      final WriteBatch batch = _store.batch();

      // Update order cart
      await _updatePendingOrdersWithProduct(
        batch: batch,
        productUuid: product.uuid!,
        userId: userId,
        updatedProduct: product,
      );

      // Update product
      batch.update(
          _store
              .collection('users')
              .doc(product.userId)
              .collection('products')
              .doc(productId),
          productAsJson);

      await batch.commit();

      logger.d('Update success');
      return true;
    } catch (error) {
      logger.e('updateProduct error: $error');
      return false;
    }
  }

  @override
  Future<ProductModel?> toggleActive({
    required String userId,
    required String productId,
    required String productUuid,
    required bool active,
  }) async {
    try {
      // Init batch write
      final WriteBatch batch = _store.batch();

      if (!active) {
        // Remove product from pending orders cart
        await _updatePendingOrdersWithProduct(
          batch: batch,
          productUuid: productUuid,
          userId: userId,
          updatedProduct: null,
        );
      }

      // Update product
      final Map<String, dynamic> updatedData = <String, dynamic>{
        'active': active,
      };
      final DocumentReference<Map<String, dynamic>> ref = _store
          .collection('users')
          .doc(userId)
          .collection('products')
          .doc(productId);
      batch.update(ref, updatedData);

      await batch.commit();

      logger.d('Update success');

      // Update product
      // final Map<String, dynamic> updatedData = <String, dynamic>{
      //   'active': active,
      // };
      // final DocumentReference<Map<String, dynamic>> ref = _store
      //     .collection('users')
      //     .doc(userId)
      //     .collection('products')
      //     .doc(productId);
      // await ref.update(updatedData);
      // logger.d('Update success');

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc = await ref.get();
      return ProductModel.fromSnapshot(updatedDoc);
    } catch (error) {
      logger.e('toggleActive error: $error');
      return null;
    }
  }

  @override
  Future<bool> delete(
      {required String userId,
      required String productId,
      required String productUuid}) async {
    logger.d('Delete product $productUuid');

    // Check no completed order with this product
    final bool isCompletedOrderWithProductExist;
    try {
      isCompletedOrderWithProductExist =
          await _isCompletedOrderWithProductExist(
              productUuid: productUuid, userId: userId);
    } catch (error) {
      logger.e('Delete product error: $error');
      return false;
    }

    if (isCompletedOrderWithProductExist) {
      throw AlreadyInUseException(
          'This product is associated with a completed order. Please disable it instead.');
    }

    try {
      // Init batch write
      final WriteBatch batch = _store.batch();

      // Remove product from pending orders cart
      await _updatePendingOrdersWithProduct(
        batch: batch,
        productUuid: productUuid,
        userId: userId,
        updatedProduct: null,
      );

      // Delete product
      batch.delete(_store
          .collection('users')
          .doc(userId)
          .collection('products')
          .doc(productId));

      await batch.commit();

      logger.d('Delete product success');
      return true;
    } catch (error) {
      logger.e('Delete product error: $error');
      return false;
    }
  }

  Future<bool> _isNameUnique({
    required String userId,
    required String productName,
    String? productUuid,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _store
        .collection('users')
        .doc(userId)
        .collection('products')
        .where('name', isEqualTo: productName)
        .where('uuid', isNotEqualTo: productUuid)
        .limit(1)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        query.docs;
    return documentSnapshots.isEmpty;
  }

  Future<bool> _isCompletedOrderWithProductExist(
      {required String productUuid, required String userId}) async {
    // Get completed orders with this product
    final QuerySnapshot<Map<String, dynamic>> ordersQuerySnapshot = await _store
        .collection('users')
        .doc(userId)
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .where('productUuids', arrayContains: productUuid)
        .limit(1)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        ordersQuerySnapshot.docs;
    return documentSnapshots.isNotEmpty;
  }

  Future<void> _updatePendingOrdersWithProduct({
    required WriteBatch batch,
    required String productUuid,
    required String userId,
    ProductModel? updatedProduct,
  }) async {
    logger.d('update order with product');

    // Get all pending orders with this product
    final QuerySnapshot<Map<String, dynamic>> ordersQuerySnapshot = await _store
        .collection('users')
        .doc(userId)
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.name)
        .where('productUuids', arrayContains: productUuid)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        ordersQuerySnapshot.docs;

    for (final DocumentSnapshot<Map<String, dynamic>> documentSnapshot
        in documentSnapshots) {
      final OrderModel order = OrderModel.fromSnapshot(documentSnapshot);
      if (order.cart == null) {
        logger.d('Cannot update order ${order.uuid}: cart is null');
        continue;
      }

      // Find item with product updated
      final CartItemModel? itemWithProduct = order.cart?.items.firstWhereOrNull(
          (CartItemModel item) => item.product.uuid == productUuid);

      if (itemWithProduct != null) {
        if (updatedProduct == null) {
          // Remove product from cart
          order.cart?.remove(itemWithProduct.product, itemWithProduct.quantity);
        } else {
          // Update cart with updated product
          itemWithProduct.product = updatedProduct;
        }
      }

      final List<CartItemModel> items =
          (order.cart == null) ? <CartItemModel>[] : order.cart!.items;
      final List<String?> productUuids = items
          .map((CartItemModel cartItem) => cartItem.product.uuid)
          .where((String? uuid) => uuid != null)
          .toSet() // remove duplicates
          .toList();
      final List<String?> categoryUuids = items
          .map((CartItemModel cartItem) => cartItem.product.category?.uuid)
          .where((String? uuid) => uuid != null)
          .toSet() // remove duplicates
          .toList();

      final Map<String, dynamic> updatedOrder = <String, dynamic>{
        'cart': order.cart!.toJson(),
        'productUuids': productUuids,
        'categoryUuids': categoryUuids,
      };
      logger.d('updatedOrder: $updatedOrder');

      // Update orders with new product
      batch.update(documentSnapshot.reference, updatedOrder);
    }
  }
}
