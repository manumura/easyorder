import 'package:flutter/material.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/models/config.dart';
import 'package:easyorder/state/category_list_state_notifier.dart';
import 'package:easyorder/state/category_paginated_list_state.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/categories/category_slidable_list_tile.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class CategoryPaginatedList extends ConsumerStatefulWidget {
  @override
  ConsumerState<CategoryPaginatedList> createState() =>
      _CategoryPaginatedListState();
}

class _CategoryPaginatedListState extends ConsumerState<CategoryPaginatedList> {
  late CategoryListStateNotifier _categoryListStateNotifier;
  late int _pageSize;

  final Logger logger = getLogger();

  @override
  void initState() {
    super.initState();

    final Config? config = ref.read(configProvider);
    _pageSize = config?.pageSize ?? defaultPageSize;

    _categoryListStateNotifier =
        ref.read(categoryListStateNotifierProvider.notifier);
    // Init categories list
    _categoryListStateNotifier.init(pageSize: _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final CategoryPaginatedListState state =
        ref.watch(categoryListStateNotifierProvider);

    return state.when(
      initial: () => _buildLoadingIndicator(),
      // const Center(
      //   child: Text('No category found'),
      // ),
      loading: () => _buildLoadingIndicator(),
      loaded: (List<CategoryModel> categories, bool hasNoMoreItemToLoad) {
        return _buildList(categories, hasNoMoreItemToLoad);
      },
      error: (String message, Object? error) => Center(
        child: Text(message),
      ),
    );
  }

  Widget _buildList(List<CategoryModel> categories, bool hasNoMoreItemToLoad) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('No category found'),
      );
    }

    final int itemCount =
        hasNoMoreItemToLoad ? categories.length : categories.length + 1;

    return RefreshIndicator(
      onRefresh: () async {
        _categoryListStateNotifier.init(pageSize: _pageSize);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(10.0),
        separatorBuilder: (BuildContext context, int index) => const SizedBox(
          height: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          if (index >= categories.length && !hasNoMoreItemToLoad) {
            _categoryListStateNotifier.paginate(pageSize: _pageSize);
            return _buildLoadingIndicator();
          }

          final CategoryModel category = categories[index];
          return CategorySlidableListTile(
              key: ValueKey<String?>(category.uuid), category: category);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: AdaptiveProgressIndicator(),
    );
  }
}
