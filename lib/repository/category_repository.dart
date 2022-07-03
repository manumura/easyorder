import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/exceptions/not_unique_exception.dart';
import 'package:easyorder/models/cart_item_model.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/order_model.dart';
import 'package:easyorder/models/order_status.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class CategoryRepository {
  Stream<List<CategoryModel>> findActive({required String userId});

  Future<List<CategoryModel>> find(
      {required String userId, int? pageSize, CategoryModel? lastCategory});

  Stream<int?> count({required String userId});

  Future<List<CategoryModel>> findByName(
      {required String userId, String? name});

  Future<String?> create(
      {required String userId, required CategoryModel category});

  Future<bool> update(
      {required String userId,
      required String categoryId,
      required CategoryModel category});

  Future<CategoryModel?> toggleActive({
    required String userId,
    required String categoryId,
    required bool active,
  });

  Future<bool> delete(
      {required String userId,
      required String categoryId,
      required String categoryUuid});
}

class CategoryRepositoryFirebaseImpl implements CategoryRepository {
  final FirebaseFirestore _store = FirebaseFirestore.instance;
  final Logger logger = getLogger();

  @override
  Future<List<CategoryModel>> find(
      {required String userId,
      int? pageSize,
      CategoryModel? lastCategory}) async {
    logger.d('find categories: pageSize=$pageSize, lastCategory=$lastCategory');

    try {
      // Find documents by user id
      final CollectionReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId).collection('categories');

      Query<Map<String, dynamic>> query = ref.orderBy('name');

      if (lastCategory != null) {
        final List<dynamic> startAt = <dynamic>[lastCategory.name];
        query = query.startAfter(startAt);
      }

      if (pageSize != null) {
        query = query.limit(pageSize);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();

      final List<CategoryModel> categories = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              CategoryModel.fromSnapshot(documentSnapshot))
          .toList();

      return categories;
    } on Exception catch (e) {
      logger.e(e);
      return Future<List<CategoryModel>>.value(<CategoryModel>[]);
    }
  }

  @override
  Stream<int?> count({required String userId}) {
    logger.d('count categories');

    try {
      // Find documents by user id
      final DocumentReference<Map<String, dynamic>> ref =
          _store.collection('users').doc(userId);
      final Stream<DocumentSnapshot<Map<String, dynamic>>> documentSnapshot$ =
          ref.snapshots();
      final Stream<int?> count$ = documentSnapshot$
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
        return documentSnapshot.data() != null
            ? int.tryParse(
                documentSnapshot.data()!['categoriesCount'].toString())
            : 0;
      });

      return count$;
    } on Exception catch (ex) {
      logger.e(ex);
      return Stream<int>.value(0);
    }
  }

  @override
  Stream<List<CategoryModel>> findActive({required String userId}) {
    logger.d('find active categories');

    try {
      // Find documents by user id
      final Stream<List<CategoryModel>> categories$ = _store
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('active', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
        final List<CategoryModel> categories = querySnapshot.docs
            .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
                CategoryModel.fromSnapshot(documentSnapshot))
            .toList();
        return categories;
      });

      return categories$;
    } on Exception catch (ex) {
      logger.e(ex);
      return const Stream<List<CategoryModel>>.empty();
    }
  }

  @override
  Future<List<CategoryModel>> findByName(
      {required String userId, String? name}) async {
    logger.d('find categories by name: $name');

    try {
      // Find documents by user id
      Query<Map<String, dynamic>> query = _store
          .collection('users')
          .doc(userId)
          .collection('categories')
          .orderBy('nameToUpperCase');

      if (name != null) {
        final List<dynamic> startAt = <dynamic>[name.toUpperCase()];
        final List<dynamic> endAt = <dynamic>[name.toUpperCase() + '~'];
        query = query.startAt(startAt).endAt(endAt);
      }

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await query.get();

      final List<CategoryModel> categories = querySnapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> documentSnapshot) =>
              CategoryModel.fromSnapshot(documentSnapshot))
          .toList();
      return categories;
    } on Exception catch (e) {
      logger.e(e);
      return Future<List<CategoryModel>>.value(<CategoryModel>[]);
    }
  }

  @override
  Future<String?> create(
      {required String userId, required CategoryModel category}) async {
    if (category.userId == null ||
        category.userEmail == null ||
        category.uuid == null ||
        category.description == null) {
      logger.e('Invalid parameters');
      return null;
    }

    // Check name is unique
    final bool isNameUnique;
    try {
      isNameUnique =
          await _isNameUnique(userId: userId, categoryName: category.name);
    } catch (error) {
      logger.e('create category error: $error');
      return null;
    }

    if (!isNameUnique) {
      throw NotUniqueException('This category name is already used.');
    }

    try {
      final Map<String, dynamic> categoryData = category.toJson();
      categoryData['nameToUpperCase'] = category.name.toUpperCase();
      categoryData['createdDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      logger.d('categoryData: $categoryData');

      // Add document by user id
      final DocumentReference<Map<String, dynamic>> docRef = await _store
          .collection('users')
          .doc(userId)
          .collection('categories')
          .add(categoryData);
      logger.d('Create success: new category ID= ${docRef.id}');
      return docRef.id;
    } catch (error) {
      logger.e('create category error: $error');
      return null;
    }
  }

  @override
  Future<bool> update(
      {required String userId,
      required String categoryId,
      required CategoryModel category}) async {
    if (category.userId == null ||
        category.userEmail == null ||
        category.uuid == null ||
        category.description == null) {
      logger.e('Invalid parameters: $category');
      return false;
    }

    // Check name is unique
    final bool isNameUnique;
    try {
      isNameUnique = await _isNameUnique(
          userId: userId,
          categoryName: category.name,
          categoryUuid: category.uuid);
    } catch (error) {
      logger.e('updateProduct error: $error');
      return false;
    }

    if (!isNameUnique) {
      throw NotUniqueException('This category name is already used.');
    }

    try {
      final Map<String, dynamic> updatedCategoryAsJson = category.toJson();
      updatedCategoryAsJson['nameToUpperCase'] = category.name.toUpperCase();
      updatedCategoryAsJson['updatedDateTime'] =
          FieldValue.serverTimestamp(); // DateTime.now();
      logger.d('updatedCategory: $updatedCategoryAsJson');

      final Map<String, dynamic> updatedProduct = <String, dynamic>{
        'category': updatedCategoryAsJson,
        'categoryName': category.name,
        'categoryNameToUpperCase': category.name.toUpperCase(),
      };

      logger.d('running batch write');

      // Init batch write
      final WriteBatch batch = _store.batch();

      // Update all products of the category
      await _updateProductsWithCategory(
        batch: batch,
        categoryUuid: category.uuid!,
        userId: userId,
        updatedProduct: updatedProduct,
      );

      // Update all pending orders with products of the category
      await _updatePendingOrdersWithCategory(
        batch: batch,
        categoryUuid: category.uuid!,
        userId: userId,
        updatedCategory: category,
      );

      batch.update(
          _store
              .collection('users')
              .doc(userId)
              .collection('categories')
              .doc(categoryId),
          updatedCategoryAsJson);

      await batch.commit();

      logger.d('Update success');
      return true;
    } catch (error) {
      logger.e('updateCategory error: $error');
      return false;
    }
  }

  @override
  Future<CategoryModel?> toggleActive({
    required String userId,
    required String categoryId,
    required bool active,
  }) async {
    try {
      // Update category
      final Map<String, dynamic> updatedData = <String, dynamic>{
        'active': active,
      };
      final DocumentReference<Map<String, dynamic>> ref = _store
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId);
      await ref.update(updatedData);
      logger.d('Update success');

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc = await ref.get();
      return CategoryModel.fromSnapshot(updatedDoc);
    } catch (error) {
      logger.e('toggleActive error: $error');
      return null;
    }
  }

  @override
  Future<bool> delete(
      {required String userId,
      required String categoryId,
      required String categoryUuid}) async {
    // Check no completed order with cart items of this category
    final bool isCompletedOrderWithCategoryExist;
    try {
      isCompletedOrderWithCategoryExist =
          await _isCompletedOrderWithCategoryExist(
              categoryUuid: categoryUuid, userId: userId);
    } catch (error) {
      logger.e('Delete product error: $error');
      return false;
    }

    if (isCompletedOrderWithCategoryExist) {
      throw AlreadyInUseException(
          'A product of this category is associated with a completed order. Please disable it instead.');
    }

    try {
      final Map<String, dynamic> updatedProduct = <String, dynamic>{
        'category': null,
        'categoryName': null,
        'categoryNameToUpperCase': null,
      };

      logger.d('running batch write');

      // Init batch write
      final WriteBatch batch = _store.batch();

      // Update all pending orders with products of the category
      await _updatePendingOrdersWithCategory(
          batch: batch, categoryUuid: categoryUuid, userId: userId);

      // Update all products of the category
      await _updateProductsWithCategory(
          batch: batch,
          categoryUuid: categoryUuid,
          userId: userId,
          updatedProduct: updatedProduct);

      // Delete category
      batch.delete(_store
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(categoryId));

      await batch.commit();

      logger.d('Delete category success');
      return true;
    } catch (error) {
      logger.e('Delete category error: $error');
      return false;
    }
  }

  Future<bool> _isNameUnique({
    required String userId,
    required String categoryName,
    String? categoryUuid,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> query = await _store
        .collection('users')
        .doc(userId)
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .where('uuid', isNotEqualTo: categoryUuid)
        .limit(1)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        query.docs;
    return documentSnapshots.isEmpty;
  }

  Future<bool> _isCompletedOrderWithCategoryExist(
      {required String categoryUuid, required String userId}) async {
    // Get completed orders with product of this category
    final QuerySnapshot<Map<String, dynamic>> ordersQuerySnapshot = await _store
        .collection('users')
        .doc(userId)
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .where('categoryUuids', arrayContains: categoryUuid)
        .limit(1)
        .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        ordersQuerySnapshot.docs;
    return documentSnapshots.isNotEmpty;
  }

  Future<void> _updateProductsWithCategory({
    required WriteBatch batch,
    required String categoryUuid,
    required String userId,
    required final Map<String, dynamic> updatedProduct,
  }) async {
    logger.d('update product with category');

    // Get all products of the category
    final QuerySnapshot<Map<String, dynamic>> productsQuerySnapshot =
        await _store
            .collection('users')
            .doc(userId)
            .collection('products')
            .where('category.uuid', isEqualTo: categoryUuid)
            .get();

    final List<DocumentSnapshot<Map<String, dynamic>>> documentSnapshots =
        productsQuerySnapshot.docs;
    for (final DocumentSnapshot<Map<String, dynamic>> documentSnapshot
        in documentSnapshots) {
      // Update products with new category
      batch.update(documentSnapshot.reference, updatedProduct);
    }
  }

  Future<void> _updatePendingOrdersWithCategory({
    required WriteBatch batch,
    required String categoryUuid,
    required String userId,
    CategoryModel? updatedCategory,
  }) async {
    logger.d('update orders with category');

    // Get all pending orders with products of this category
    final QuerySnapshot<Map<String, dynamic>> ordersQuerySnapshot = await _store
        .collection('users')
        .doc(userId)
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.name)
        .where('categoryUuids', arrayContains: categoryUuid)
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

      // Find all items with category updated
      final List<CartItemModel> itemsWithCategory = (order.cart == null)
          ? <CartItemModel>[]
          : order.cart!.items
              .where((CartItemModel item) =>
                  item.product.category?.uuid == categoryUuid)
              .toList();

      for (CartItemModel item in itemsWithCategory) {
        if (updatedCategory == null) {
          // Remove products of this category from cart
          order.cart!.remove(item.product, item.quantity);
        } else {
          // Update cart items with updated category
          item.product.category = updatedCategory;
        }
      }

      final List<CartItemModel> cartItems =
          (order.cart == null) ? <CartItemModel>[] : order.cart!.items;
      final List<String?> productUuids = cartItems
          .map((CartItemModel cartItem) => cartItem.product.uuid)
          .where((String? uuid) => uuid != null)
          .toSet() // remove duplicates
          .toList();
      final List<String?> categoryUuids = cartItems
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

      // Update order without updated product
      batch.update(documentSnapshot.reference, updatedOrder);
    }
  }
}
