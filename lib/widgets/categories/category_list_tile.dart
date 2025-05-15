import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/models/category_model.dart';
import 'package:easyorder/pages/category_edit_screen.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:logger/logger.dart';

mixin AbstractCategoryListTile {
  static const double switchWidth = 55;
  final Logger logger = getLogger();

  Widget buildCard(Widget child) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
      child: child,
    );
  }

  Widget buildListTile(
      BuildContext context, CategoryModel category, Widget trailingWidget) {
    return ListTile(
      title: _buildTitle(context, category),
      trailing: trailingWidget,
    );
  }

  Widget _buildTitle(BuildContext context, CategoryModel category) {
    final Icon icon = category.active
        ? const Icon(
            Icons.check,
            size: 20,
            color: Colors.green,
            semanticLabel: 'Active',
          )
        : const Icon(
            Icons.clear,
            size: 20,
            color: Colors.red,
            semanticLabel: 'Inactive',
          );

    return Text.rich(
      // softWrap: false,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            child: icon,
          ),
          WidgetSpan(
            child: SizedBox(
              width: 5,
            ),
          ),
          TextSpan(
            text: category.name,
            style: TextStyle(
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

  void openEditScreen(BuildContext context, CategoryModel category) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
          settings: const RouteSettings(name: CategoryEditScreen.routeName),
          builder: (BuildContext context) => CategoryEditScreen(
                currentCategory: category,
              )),
    )
        .then((_) {
      logger.d('Back to category list');
    });
  }
}

class CategoryListTile extends StatelessWidget with AbstractCategoryListTile {
  CategoryListTile({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final Widget child = InkWell(
      onTap: () => openEditScreen(context, category),
      child:
          buildListTile(context, category, _buildEditButton(context, category)),
    );

    return buildCard(child);
  }

  Widget _buildEditButton(BuildContext context, CategoryModel category) {
    return IconButton(
      icon: Icon(
        Icons.edit,
        color: Theme.of(context).primaryColor,
      ),
      onPressed: () => openEditScreen(context, category),
    );
  }
}

class CategorySwitchListTile extends StatelessWidget
    with AbstractCategoryListTile {
  CategorySwitchListTile(
      {super.key, required this.category, required this.onToggle});

  final CategoryModel category;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget child = InkWell(
      onTap: () => openEditScreen(context, category),
      child: buildListTile(
          context, category, _buildActiveSwitch(context, category)),
    );

    return buildCard(child);
  }

  Widget _buildActiveSwitch(BuildContext context, CategoryModel category) {
    return SizedBox(
      width: AbstractCategoryListTile.switchWidth,
      child: FlutterSwitch(
        width: AbstractCategoryListTile.switchWidth,
        height: 25,
        toggleSize: 20,
        valueFontSize: 12,
        borderRadius: 12,
        padding: 2,
        showOnOff: true,
        activeColor: Colors.green,
        activeText: 'ON',
        inactiveColor: Colors.red,
        inactiveText: 'OFF',
        value: category.active,
        onToggle: onToggle,
      ),
    );
  }
}

class CategoryLoadingListTile extends StatelessWidget
    with AbstractCategoryListTile {
  CategoryLoadingListTile({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final Widget child = buildListTile(
        context,
        category,
        SizedBox(
          width: AbstractCategoryListTile.switchWidth,
          child: Center(
            child: AdaptiveProgressIndicator(),
          ),
        ));

    return Opacity(
      opacity: 0.5,
      child: buildCard(child),
    );
  }
}
