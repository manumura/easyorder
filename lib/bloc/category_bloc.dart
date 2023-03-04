import 'dart:async';
import 'dart:io';

import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/image_type.dart';
import 'package:easyorder/models/storage_model.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/category_repository.dart';
import 'package:easyorder/service/storage_service.dart';
import 'package:easyorder/state/service_locator.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

abstract class CategoryBloc {
  Stream<List<CategoryModel>> get activeCategories$;

  Future<List<CategoryModel>> find(
      {int? pageSize, CategoryModel? lastCategory});

  Stream<int?> count();

  Future<List<CategoryModel>> findByName({required String name});

  Future<CategoryModel?> create({required CategoryModel category, File? image});

  Future<CategoryModel?> update(
      {required String categoryId,
      required CategoryModel category,
      File? image});

  Future<CategoryModel?> toggleActive({
    required String categoryId,
    required bool active,
  });

  Future<bool> delete(
      {required String categoryId,
      required String categoryUuid,
      String? categoryImagePath});

  void dispose();
}

class CategoryBlocImpl implements CategoryBloc {
  CategoryBlocImpl({
    required this.user,
    required this.categoryRepository,
  }) {
    logger.d('----- Building CategoryBlocImpl -----');
    final Stream<List<CategoryModel>> activeCategories$ =
        categoryRepository.findActive(userId: user.id);
    activeCategories$.listen(
      (List<CategoryModel> categories) {
        _activeCategoriesSubject.add(categories);
      },
      onError: (Object error) =>
          logger.e('active categories listen error: $error'),
      cancelOnError: false,
    );
  }
  final UserModel user;
  final CategoryRepository categoryRepository;

  final StorageService? storageService = getIt<StorageService>();
  final Logger logger = getLogger();

  final BehaviorSubject<List<CategoryModel>> _activeCategoriesSubject =
      BehaviorSubject<List<CategoryModel>>.seeded(<CategoryModel>[]);
  @override
  Stream<List<CategoryModel>> get activeCategories$ =>
      _activeCategoriesSubject.stream;

  @override
  Future<List<CategoryModel>> find(
      {int? pageSize, CategoryModel? lastCategory}) async {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Future<List<CategoryModel>>.value(<CategoryModel>[]);
    }

    return categoryRepository.find(
        userId: user.id, pageSize: pageSize, lastCategory: lastCategory);
  }

  @override
  Stream<int?> count() {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Stream<int>.value(0);
    }
    return categoryRepository.count(userId: user.id);
  }

  @override
  Future<List<CategoryModel>> findByName({required String name}) async {
    if (user.id.isEmpty) {
      logger.e('No user found');
      return Future<List<CategoryModel>>.value(<CategoryModel>[]);
    }
    return categoryRepository.findByName(userId: user.id, name: name);
  }

  @override
  Future<CategoryModel?> create(
      {required CategoryModel category, File? image}) async {
    logger.d('add category, user: $user');

    if (user.id.isEmpty) {
      logger.e('No user found');
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

    final CategoryModel categoryToCreate = CategoryModel.clone(category);
    categoryToCreate.uuid = uuid.v4();
    categoryToCreate.imagePath = imagePath;
    categoryToCreate.imageUrl = imageUrl;
    categoryToCreate.userEmail = user.email;
    categoryToCreate.userId = user.id;

    String? id = await categoryRepository.create(
        userId: user.id, category: categoryToCreate);

    if (id != null) {
      categoryToCreate.id = id;
      return categoryToCreate;
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
            imageType: ImageType.category,
            path: path)
        : await storageService!.upload(
            userId: user.id, file: image, imageType: ImageType.category);

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
  Future<CategoryModel?> update(
      {required String categoryId,
      required CategoryModel category,
      File? image}) async {
    logger.d('update category: $categoryId');

    if (user.id.isEmpty) {
      logger.e('category, categoryId or user is null: $category, $categoryId, '
          '${user.id}');
      return null;
    }

    String? imageUrl = category.imageUrl;
    String? imagePath = category.imagePath;

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

    final CategoryModel categoryToUpdate = CategoryModel.clone(category);
    categoryToUpdate.imagePath = imagePath;
    categoryToUpdate.imageUrl = imageUrl;

    final bool success = await categoryRepository.update(
        userId: user.id, categoryId: categoryId, category: categoryToUpdate);
    return success ? categoryToUpdate : null;
  }

  @override
  Future<CategoryModel?> toggleActive({
    required String categoryId,
    required bool active,
  }) async {
    logger.d('category toggle active: $categoryId');

    if (user.id.isEmpty) {
      logger.e('No user found');
      return null;
    }

    return categoryRepository.toggleActive(
        userId: user.id, categoryId: categoryId, active: active);
  }

  @override
  Future<bool> delete(
      {required String categoryId,
      required String categoryUuid,
      String? categoryImagePath}) async {
    if (user.id.isEmpty) {
      logger.e('User is null');
      return Future<bool>.value(false);
    }

    logger.d('delete category: $categoryId, user: ${user.id}');

    // Delete image
    if (categoryImagePath != null && storageService != null) {
      await storageService!.delete(path: categoryImagePath);
    }

    return categoryRepository.delete(
        userId: user.id, categoryId: categoryId, categoryUuid: categoryUuid);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE CategoryBloc ***');
    _activeCategoriesSubject.close();
  }
}
