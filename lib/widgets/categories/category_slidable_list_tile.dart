import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/exceptions/already_in_use_exception.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/category_list_state_notifier.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/categories/category_list_tile.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class CategorySlidableListTile extends ConsumerStatefulWidget {
  const CategorySlidableListTile({super.key, required this.category});

  final CategoryModel category;

  @override
  ConsumerState<CategorySlidableListTile> createState() =>
      _CategorySlidableListTileState();
}

class _CategorySlidableListTileState
    extends ConsumerState<CategorySlidableListTile> {
  bool _isLoading = false;

  final Logger logger = getLogger();

  // https://proandroiddev.com/flutter-thursday-02-beautiful-list-ui-and-detail-page-a9245f5ceaf0
  @override
  Widget build(BuildContext context) {
    final CategoryListStateNotifier categoryListStateNotifier =
        ref.watch(categoryListStateNotifierProvider.notifier);
    return _buildCategoryListTile(context, categoryListStateNotifier);
  }

  Widget _buildCategoryListTile(BuildContext context,
      CategoryListStateNotifier categoryListStateNotifier) {
    return _isLoading
        ? CategoryLoadingListTile(
            key: ValueKey<String?>(widget.category.uuid),
            category: widget.category)
        : Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.3,
              children: <Widget>[
                SlidableAction(
                  onPressed: (BuildContext context) =>
                      _deleteCategory(context, categoryListStateNotifier),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: CategorySwitchListTile(
              key: ValueKey<String?>(widget.category.uuid),
              category: widget.category,
              onToggle: (bool value) =>
                  _toggleActive(context, categoryListStateNotifier, value),
            ),
          );
  }

  void _deleteCategory(BuildContext context,
      CategoryListStateNotifier categoryListStateNotifier) {
    setState(() => _isLoading = true);

    categoryListStateNotifier.remove(categoryToRemove: widget.category).then(
      (bool success) {
        setState(() => _isLoading = false);
        if (success) {
          final Flushbar<void> flushbar = UiHelper.createSuccessFlushbar(
              message: '${widget.category.name} successfully removed !',
              title: 'Success !');
          flushbar.show(navigatorKey.currentContext ?? context);
        } else {
          final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
              message: 'Failed to remove ${widget.category.name} !',
              title: 'Error !');
          flushbar.show(navigatorKey.currentContext ?? context);
        }
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');

        String title = 'Error !';
        String content = 'Failed to remove ${widget.category.name} !';

        final bool isAlreadyInUse = err is AlreadyInUseException;
        if (isAlreadyInUse) {
          title = 'Cannot delete this category.';
          content = err.message;
        }

        final Flushbar<void> flushbar =
            UiHelper.createErrorFlushbar(message: content, title: title);
        flushbar.show(navigatorKey.currentContext ?? context);
      },
    );
  }

  void _toggleActive(
    BuildContext context,
    CategoryListStateNotifier categoryListStateNotifier,
    bool active,
  ) {
    if (widget.category.id == null) {
      logger.e('Category id is null');
      return;
    }
    setState(() => _isLoading = true);

    categoryListStateNotifier
        .toggleActive(categoryId: widget.category.id!, active: active)
        .then(
      (CategoryModel? updatedCategory) {
        setState(() => _isLoading = false);
        logger.d('Category active toggle updated: $updatedCategory');
      },
    ).catchError(
      (Object err, StackTrace trace) {
        setState(() => _isLoading = false);
        logger.e('Error: $err');
        final Flushbar<void> flushbar = UiHelper.createErrorFlushbar(
            message: 'Failed to update ${widget.category.name} !',
            title: 'Error !');
        flushbar.show(navigatorKey.currentContext ?? context);
      },
    );
  }
}
