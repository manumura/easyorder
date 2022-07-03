import 'dart:io';

import 'package:easyorder/bloc/category_bloc.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/state/category_paginated_list_state.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class CategoryListStateNotifier
    extends StateNotifier<CategoryPaginatedListState> {
  CategoryListStateNotifier(this.categoryBloc,
      [CategoryPaginatedListState? state])
      : super(state ?? const CategoryPaginatedListState.initial());

  final CategoryBloc? categoryBloc;

  final Logger logger = getLogger();
  final List<CategoryModel> _categories = <CategoryModel>[];

  void init({required int pageSize}) async {
    if (categoryBloc == null) {
      logger.e('categoryBloc is null');
      return;
    }

    // state = const CategoryPaginatedListState.loading();

    final List<CategoryModel> categories =
        await categoryBloc!.find(pageSize: pageSize);

    _categories.clear();
    _categories.addAll(categories);

    state = CategoryPaginatedListState.loaded(
      categories: categories,
      hasNoMoreItemToLoad: false,
    );
  }

  void paginate({
    required int pageSize,
  }) async {
    if (categoryBloc == null) {
      logger.e('categoryBloc is null');
      return;
    }

    final List<CategoryModel> categories = <CategoryModel>[];
    if (_categories.isEmpty) {
      final List<CategoryModel> newCategories = await categoryBloc!.find(
        pageSize: pageSize,
      );
      categories.addAll(newCategories);
    } else {
      final CategoryModel lastCategory = _categories[_categories.length - 1];
      final List<CategoryModel> newCategories = await categoryBloc!.find(
        pageSize: pageSize,
        lastCategory: lastCategory,
      );
      categories.addAll(newCategories);
    }

    final List<CategoryModel> newCategories = <CategoryModel>[
      ..._categories,
      ...categories,
    ];

    _categories.clear();
    _categories.addAll(newCategories);

    state = CategoryPaginatedListState.loaded(
      categories: newCategories,
      hasNoMoreItemToLoad: categories.isEmpty,
    );
  }

  Future<CategoryModel?> add(
      {required CategoryModel category, File? image}) async {
    if (categoryBloc == null) {
      logger.e('categoryBloc is null');
      return null;
    }

    final CategoryModel? categoryCreated =
        await categoryBloc!.create(category: category);
    final List<CategoryModel> newCategories = <CategoryModel>[
      ..._categories,
    ];

    if (categoryCreated != null) {
      newCategories.add(categoryCreated);
      newCategories.sort(_compare());

      _categories.clear();
      _categories.addAll(newCategories);
    }

    state = CategoryPaginatedListState.loaded(
      categories: newCategories,
      hasNoMoreItemToLoad: false,
    );

    return categoryCreated;
  }

  Future<CategoryModel?> edit({
    required String categoryId,
    required CategoryModel category,
    File? image,
  }) async {
    if (categoryBloc == null) {
      logger.e('categoryBloc is null');
      return null;
    }

    final CategoryModel? categoryUpdated = await categoryBloc!
        .update(categoryId: categoryId, category: category, image: image);
    final List<CategoryModel> newCategories = <CategoryModel>[];

    if (categoryUpdated != null) {
      newCategories.addAll(<CategoryModel>[
        for (final CategoryModel c in _categories)
          if (c.uuid == categoryUpdated.uuid) categoryUpdated else c,
      ]);
    } else {
      newCategories.addAll(_categories);
    }

    newCategories.sort(_compare());
    _categories.clear();
    _categories.addAll(newCategories);

    state = CategoryPaginatedListState.loaded(
      categories: newCategories,
      hasNoMoreItemToLoad: false,
    );

    return categoryUpdated;
  }

  Future<CategoryModel?> toggleActive({
    required String categoryId,
    required bool active,
  }) async {
    if (categoryBloc == null) {
      logger.e('categoryBloc is null');
      return null;
    }

    final CategoryModel? categoryUpdated = await categoryBloc!
        .toggleActive(categoryId: categoryId, active: active);
    final List<CategoryModel> newCategories = <CategoryModel>[];

    if (categoryUpdated != null) {
      newCategories.addAll(<CategoryModel>[
        for (final CategoryModel c in _categories)
          if (c.uuid == categoryUpdated.uuid) categoryUpdated else c,
      ]);
    } else {
      newCategories.addAll(_categories);
    }

    newCategories.sort(_compare());
    _categories.clear();
    _categories.addAll(newCategories);

    state = CategoryPaginatedListState.loaded(
      categories: newCategories,
      hasNoMoreItemToLoad: false,
    );

    return categoryUpdated;
  }

  Future<bool> remove({required CategoryModel categoryToRemove}) async {
    if (categoryBloc == null) {
      logger.e('categoryBloc is null');
      return false;
    }

    if (categoryToRemove.id == null || categoryToRemove.uuid == null) {
      logger.e('Category id or uuid is null');
      return false;
    }

    final bool success = await categoryBloc!.delete(
        categoryId: categoryToRemove.id!, categoryUuid: categoryToRemove.uuid!);

    final List<CategoryModel> newCategories = _categories
        .where((CategoryModel c) => c.uuid != categoryToRemove.uuid)
        .toList();

    _categories.clear();
    _categories.addAll(newCategories);

    state = CategoryPaginatedListState.loaded(
      categories: newCategories,
      hasNoMoreItemToLoad: false,
    );

    return success;
  }

  int Function(CategoryModel a, CategoryModel b) _compare() {
    return (CategoryModel a, CategoryModel b) => a.name.compareTo(b.name);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE CategoryListStateNotifier ***');
    if (mounted) {
      super.dispose();
    }
  }
}
