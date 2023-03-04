import 'dart:io';

import 'package:easyorder/bloc/category_bloc.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/image_type.dart';
import 'package:easyorder/models/storage_model.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/category_repository.dart';
import 'package:easyorder/service/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'category_bloc_test.mocks.dart';

@GenerateMocks([CategoryRepository, StorageService])
void main() {

  late CategoryBloc categoryBloc;
  late CategoryBloc categoryBlocWithNoUser;
  final MockStorageService mockStorageService = MockStorageService();
  final MockCategoryRepository mockCategoryRepository = MockCategoryRepository();
  final UserModel mockUser = UserModel(id: '1', email: 'test@test.com', isEmailVerified: true, providerIds: []);
  final UserModel mockUserWithNoId = UserModel(id: '', email: 'test@test.com', isEmailVerified: true, providerIds: []);
  final Map<String, dynamic> lastCategoryAsJson = <String, dynamic>{
    'id': 'cat1',
    'uuid': 'uuid1',
    'name': 'last_category',
    'description': 'last_category_description',
    'imageUrl': '',
    'imagePath': '',
    'userEmail': 'test@test.com',
    'userId': '1',
    'active': true,
  };
  final CategoryModel lastCategory = CategoryModel.fromJson(lastCategoryAsJson);
  final CategoryModel mockCategory = CategoryModel(
    id: 'cat2',
    uuid: 'uuid2',
    name: 'test_category',
    description: 'test_category_description',
    imageUrl: 'url',
    imagePath: 'path',
    userEmail: 'test@test.com',
    userId: '1',
    active: true,
  );
  final File file = File('path');
  final StorageModel storage = StorageModel(url: 'storage_url', path: 'storage_path');

  setUp(() async {
    // setupServiceLocator();
    final GetIt getIt = GetIt.instance;
    // Make sure the instance is cleared before each test.
    await getIt.reset();
    getIt.registerSingleton<StorageService>(mockStorageService);

    when(mockStorageService.upload(userId: '1', file: file, imageType: ImageType.category, path: null))
        .thenAnswer((_) => Future<StorageModel>.value(storage));

    when(mockCategoryRepository
        .findActive(userId: '1'))
        .thenAnswer((_) => Stream<List<CategoryModel>>.value(<CategoryModel>[mockCategory]));

    categoryBloc = CategoryBlocImpl(user: mockUser, categoryRepository: mockCategoryRepository);

    when(mockCategoryRepository
        .findActive(userId: ''))
        .thenAnswer((_) => Stream<List<CategoryModel>>.value(<CategoryModel>[]));

    categoryBlocWithNoUser = CategoryBlocImpl(user: mockUserWithNoId, categoryRepository: mockCategoryRepository);
  });

  group('CategoryBloc', () {
    test('should return a list of categories successfully when find', () async {
      when(mockCategoryRepository
          .find(userId: mockUser.id, pageSize: 5, lastCategory: lastCategory))
          .thenAnswer((_) => Future<List<CategoryModel>>.value(<CategoryModel>[mockCategory]));

      final List<CategoryModel> result = await categoryBloc.find(pageSize: 5, lastCategory: lastCategory);
      expect(result, <CategoryModel>[mockCategory]);
    });

    test('return an empty list of categories when find with no user', () async {
      final List<CategoryModel> result = await categoryBlocWithNoUser.find(pageSize: 5, lastCategory: lastCategory);
      expect(result, <CategoryModel>[]);
    });

    test('should return a stream of categories count successfully', () async {
      when(mockCategoryRepository
          .count(userId: mockUser.id))
          .thenAnswer((_) => Stream<int>.periodic(
          const Duration(seconds: 1), (int value) => value).take(5));

      final Stream<int?> result = categoryBloc.count();
      expect(result, emitsInOrder(<int>[0, 1, 2, 3, 4]));
    });

    test('should return a stream of 0 categories count when no user', () async {
      final Stream<int?> result = categoryBlocWithNoUser.count();
      expect(result, emitsInOrder(<int>[0]));
      // result.listen((int? count) {
      //   print(count);
      // });
    });

    test('should return a list of categories successfully when find by name', () async {
      when(mockCategoryRepository
          .findByName(userId: mockUser.id, name: 'test_category'))
          .thenAnswer((_) => Future<List<CategoryModel>>.value(<CategoryModel>[mockCategory]));

      final List<CategoryModel> result = await categoryBloc.findByName(name: 'test_category');
      expect(result, <CategoryModel>[mockCategory]);
    });

    test('should return an empty list of categories when find by name with no user', () async {
      final List<CategoryModel> result = await categoryBlocWithNoUser.findByName(name: 'test_category');
      expect(result, <CategoryModel>[]);
    });

    test('should create a category successfully', () async {
      final CategoryModel categoryToCreate = CategoryModel(
        name: 'test_category',
        description: 'test_category_description',
        userEmail: mockUser.email,
        userId: mockUser.id,
        active: true,
      );

      when(mockCategoryRepository
          .create(userId: mockUser.id, category: captureAnyNamed('category')))
          .thenAnswer((_) => Future<String>.value('cat3'));

      final CategoryModel? result = await categoryBloc.create(category: categoryToCreate, image: file);

      final VerificationResult verification = verify(mockCategoryRepository.create(userId: mockUser.id, category: captureAnyNamed('category')));
      final CategoryModel categoryCreated = CategoryModel.clone(categoryToCreate);
      categoryCreated.id = verification.captured.single.id.toString();
      categoryCreated.uuid = verification.captured.single.uuid.toString();
      categoryCreated.imagePath = verification.captured.single.imagePath.toString();
      categoryCreated.imageUrl = verification.captured.single.imageUrl.toString();

      expect(result, categoryCreated);
      expect(result?.imageUrl, categoryCreated.imageUrl);
      expect(result?.imagePath, categoryCreated.imagePath);
    });

    test('should fail to create a category when no user', () async {
      final CategoryModel categoryToCreate = CategoryModel(
        name: 'test_category',
        description: 'test_category_description',
        userEmail: mockUser.email,
        userId: mockUser.id,
        active: true,
      );

      final CategoryModel? result = await categoryBlocWithNoUser.create(category: categoryToCreate, image: file);
      expect(result, isNull);
    });

    test('should update a category successfully', () async {
      final CategoryModel categoryToUpdate = CategoryModel(
        id: 'cat3',
        uuid: 'uuid3',
        name: 'test_category',
        description: 'test_category_description',
        userEmail: mockUser.email,
        userId: mockUser.id,
        active: true,
      );

      when(mockCategoryRepository
          .update(userId: mockUser.id, categoryId: 'cat3', category: captureAnyNamed('category')))
          .thenAnswer((_) => Future<bool>.value(true));

      final CategoryModel? result = await categoryBloc.update(categoryId: 'cat3', category: categoryToUpdate, image: file);

      final VerificationResult verification = verify(mockCategoryRepository.update(userId: mockUser.id, categoryId: 'cat3', category: captureAnyNamed('category')));
      final CategoryModel categoryUpdated = CategoryModel.clone(categoryToUpdate);
      categoryUpdated.imagePath = verification.captured.single.imagePath.toString();
      categoryUpdated.imageUrl = verification.captured.single.imageUrl.toString();

      expect(result, categoryUpdated);
      expect(result?.imageUrl, categoryUpdated.imageUrl);
      expect(result?.imagePath, categoryUpdated.imagePath);
    });

    test('should fail to update a category when no user', () async {
      final CategoryModel categoryToUpdate = CategoryModel(
        id: 'cat3',
        uuid: 'uuid3',
        name: 'test_category',
        description: 'test_category_description',
        userEmail: mockUser.email,
        userId: mockUser.id,
        active: true,
      );

      final CategoryModel? result = await categoryBlocWithNoUser.update(categoryId: 'cat3', category: categoryToUpdate, image: file);
      expect(result, isNull);
    });

    test('should toggle a category successfully', () async {
      final CategoryModel categoryToToggle = CategoryModel(
        id: 'cat3',
        uuid: 'uuid3',
        name: 'test_category',
        description: 'test_category_description',
        userEmail: mockUser.email,
        userId: mockUser.id,
        active: true,
      );

      final CategoryModel categoryToggled = CategoryModel.clone(categoryToToggle);
      categoryToggled.active = false;

      when(mockCategoryRepository
          .toggleActive(userId: mockUser.id, categoryId: 'cat3', active: false))
          .thenAnswer((_) => Future<CategoryModel>.value(categoryToggled));

      final CategoryModel? result = await categoryBloc.toggleActive(categoryId: 'cat3', active: false);

      verify(mockCategoryRepository.toggleActive(userId: mockUser.id, categoryId: 'cat3', active: false));
      expect(result, categoryToggled);
    });

    test('should fail to toggle a category when no user', () async {
      final CategoryModel? result = await categoryBlocWithNoUser.toggleActive(categoryId: 'cat3', active: false);
      expect(result, isNull);
    });

    test('should delete a category successfully', () async {
      when(mockCategoryRepository
          .delete(userId: mockUser.id, categoryId: 'cat3', categoryUuid: 'uuid3'))
          .thenAnswer((_) => Future<bool>.value(true));

      final bool result = await categoryBloc.delete(categoryId: 'cat3', categoryUuid: 'uuid3', categoryImagePath: 'test_path');

      verify(mockCategoryRepository.delete(userId: mockUser.id, categoryId: 'cat3', categoryUuid: 'uuid3'));
      expect(result, true);
    });

    test('should fail to delete a category when no user', () async {
      final bool result = await categoryBlocWithNoUser.delete(categoryId: 'cat3', categoryUuid: 'uuid3');
      expect(result, false);
    });

  });
}
