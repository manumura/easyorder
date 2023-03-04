import 'dart:async';
import 'dart:io';

import 'package:easyorder/models/image_type.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/models/storage_model.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/product_repository.dart';
import 'package:easyorder/service/storage_service.dart';
import 'package:easyorder/state/service_locator.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

abstract class ProductBloc {
  Stream<List<ProductModel>> get activeProducts$;

  Future<List<ProductModel>> find({int? pageSize, ProductModel? lastProduct});

  Stream<int?> count();

  Future<List<ProductModel>> findByName({required String name});

  Future<ProductModel?> create({required ProductModel product, File? image});

  Future<ProductModel?> update(
      {required String productId, required ProductModel product, File? image});

  Future<ProductModel?> toggleActive({
    required String productId,
    required String productUuid,
    required bool active,
  });

  Future<bool> delete(
      {required String productId,
      required String productUuid,
      String? productImagePath});

  void dispose();
}

class ProductBlocImpl implements ProductBloc {
  ProductBlocImpl({
    required this.user,
    required this.productRepository,
  }) {
    logger.d('----- Building ProductBlocImpl -----');
    final Stream<List<ProductModel>> activeProducts$ =
        productRepository.findActive(userId: user.id);
    activeProducts$.listen(
      (List<ProductModel> products) {
        _activeProductsSubject.add(products);
      },
      onError: (Object error) =>
          logger.e('active products listen error: $error'),
      cancelOnError: false,
    );
  }

  final UserModel user;
  final ProductRepository productRepository;

  final Logger logger = getLogger();
  final StorageService? storageService = getIt<StorageService>();

  final BehaviorSubject<List<ProductModel>> _activeProductsSubject =
      BehaviorSubject<List<ProductModel>>();
  @override
  Stream<List<ProductModel>> get activeProducts$ =>
      _activeProductsSubject.stream;

  @override
  Future<List<ProductModel>> find(
      {int? pageSize, ProductModel? lastProduct}) async {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Future<List<ProductModel>>.value(<ProductModel>[]);
    }
    return productRepository.find(
        userId: user.id, pageSize: pageSize, lastProduct: lastProduct);
  }

  @override
  Stream<int?> count() {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Stream<int>.value(0);
    }
    return productRepository.count(userId: user.id);
  }

  @override
  Future<List<ProductModel>> findByName({required String name}) async {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Future<List<ProductModel>>.value(<ProductModel>[]);
    }
    return productRepository.findByName(userId: user.id, name: name);
  }

  @override
  Future<ProductModel?> create({ProductModel? product, File? image}) async {
    logger.d('add product, user: $user');

    if (product == null || user.id.isEmpty) {
      logger.e('product or user is null');
      return null;
    }

    String? imageUrl;
    String? imagePath;

    if (image != null) {
      logger.d('uploading image');
      final StorageModel? storage = await _upload(image: image);
      imageUrl = storage?.url;
      imagePath = storage?.path;
    }

    const Uuid uuid = Uuid();

    final ProductModel productToCreate = ProductModel.clone(product);
    productToCreate.uuid = uuid.v4();
    productToCreate.imagePath = imagePath;
    productToCreate.imageUrl = imageUrl;
    productToCreate.userEmail = user.email;
    productToCreate.userId = user.id;

    String? id = await productRepository.create(
        userId: user.id, product: productToCreate);
    if (id != null) {
      productToCreate.id = id;
      return productToCreate;
    } else {
      return null;
    }
  }

  Future<StorageModel?> _upload({required File image, String? path}) async {
    if (storageService == null) {
      logger.e('Storage service is null!');
      return null;
    }

    final StorageModel? storage = (path != null)
        ? await storageService!.upload(
            userId: user.id,
            file: image,
            imageType: ImageType.product,
            path: path)
        : await storageService!
            .upload(userId: user.id, file: image, imageType: ImageType.product);

    if (storage == null) {
      logger.e('Upload failed!');
      return null;
    }

    return storage;
  }

  Future<void> _deleteImage({required String path}) async {
    if (storageService == null) {
      logger.e('Storage service is null!');
    }

    await storageService!.delete(path: path);
  }

  @override
  Future<ProductModel?> update(
      {required String productId,
      required ProductModel product,
      File? image}) async {
    logger.d('updateProduct: $productId');

    if (user.id.isEmpty) {
      logger.e('user is null');
      return null;
    }

    String? imageUrl = product.imageUrl;
    String? imagePath = product.imagePath;

    if (image != null) {
      logger.d('uploading image');
      final StorageModel? storage =
          await _upload(image: image, path: imagePath);
      imageUrl = storage?.url;
      imagePath = storage?.path;
    } else if (imagePath != null) {
      logger.d('deleting image');
      await _deleteImage(path: imagePath);
      imageUrl = null;
      imagePath = null;
    }

    final ProductModel productToUpdate = ProductModel.clone(product);
    productToUpdate.imagePath = imagePath;
    productToUpdate.imageUrl = imageUrl;

    final bool success = await productRepository.update(
        userId: user.id, productId: productId, product: productToUpdate);
    return success ? productToUpdate : null;
  }

  @override
  Future<ProductModel?> toggleActive({
    required String productId,
    required String productUuid,
    required bool active,
  }) async {
    logger.d('product toggle active: $productId');

    if (user.id.isEmpty) {
      logger.e('No user found');
      return null;
    }

    return productRepository.toggleActive(
      userId: user.id,
      productId: productId,
      productUuid: productUuid,
      active: active,
    );
  }

  @override
  Future<bool> delete(
      {required String productId,
      required String productUuid,
      String? productImagePath}) async {
    if (user.id.isEmpty) {
      logger.e('product or user is null');
      return Future<bool>.value(false);
    }

    logger.d('deleteProduct: $productId, user: ${user.id}');

    // Delete image
    if (productImagePath != null && storageService != null) {
      await storageService!.delete(path: productImagePath);
    }

    return productRepository.delete(
        userId: user.id, productId: productId, productUuid: productUuid);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE ProductBloc ***');
    _activeProductsSubject.close();
  }
}
