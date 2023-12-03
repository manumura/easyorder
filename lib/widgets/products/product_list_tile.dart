import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/models/product_model.dart';
import 'package:easyorder/pages/product_edit_screen.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/orders/price_tag.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:logger/logger.dart';

abstract class AbstractProductListTile {
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
      BuildContext context, ProductModel product, Widget trailingWidget) {
    final Widget circleAvatar = _buildAvatar(product);

    return ListTile(
      leading: circleAvatar,
      title: _buildTitle(context, product),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            height: 2.0,
          ),
          PriceTag(price: product.price),
        ],
      ),
      trailing: trailingWidget,
    );
  }

  Widget _buildAvatar(ProductModel product) {
    final Widget circleAvatar = product.imageUrl == null
        ? const CircleAvatar(
            backgroundImage: AssetImage('assets/placeholder.jpg'),
          )
        : CachedNetworkImage(
            imageUrl: product.imageUrl!,
            imageBuilder:
                (BuildContext context, ImageProvider<Object> imageProvider) =>
                    CircleAvatar(
              backgroundImage: imageProvider,
            ),
            progressIndicatorBuilder: (BuildContext context, String url,
                    DownloadProgress downloadProgress) =>
                CircularProgressIndicator(value: downloadProgress.progress),
            errorWidget: (BuildContext context, String url, Object? error) =>
                const Icon(Icons.error),
          );

    return circleAvatar;
  }

  Widget _buildTitle(BuildContext context, ProductModel product) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        product.active
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
              ),
        Text(
          product.name,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  void openEditScreen(BuildContext context, ProductModel product) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
          settings: const RouteSettings(name: ProductEditScreen.routeName),
          builder: (BuildContext context) => ProductEditScreen(product)),
    )
        .then((_) {
      logger.d('Back to product list');
    });
  }
}

class ProductListTile extends StatelessWidget with AbstractProductListTile {
  ProductListTile({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final Widget child = InkWell(
      splashColor: Theme.of(context).primaryColor,
      onTap: () => openEditScreen(context, product),
      child:
          buildListTile(context, product, _buildEditButton(context, product)),
    );

    return buildCard(child);
  }

  Widget _buildEditButton(BuildContext context, ProductModel product) {
    return IconButton(
      icon: Icon(
        Icons.edit,
        color: Theme.of(context).primaryColor,
      ),
      onPressed: () => openEditScreen(context, product),
    );
  }
}

class ProductSwitchListTile extends StatelessWidget
    with AbstractProductListTile {
  ProductSwitchListTile(
      {required this.key, required this.product, required this.onToggle});

  final Key key;
  final ProductModel product;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final Widget child = InkWell(
      splashColor: Theme.of(context).primaryColor,
      onTap: () => openEditScreen(context, product),
      child:
          buildListTile(context, product, _buildActiveSwitch(context, product)),
    );

    return buildCard(child);
  }

  Widget _buildActiveSwitch(BuildContext context, ProductModel product) {
    return SizedBox(
      width: AbstractProductListTile.switchWidth,
      child: FlutterSwitch(
        width: AbstractProductListTile.switchWidth,
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
        value: product.active,
        onToggle: onToggle,
      ),
    );
  }
}

class ProductLoadingListTile extends StatelessWidget
    with AbstractProductListTile {
  ProductLoadingListTile({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final Widget child = buildListTile(
        context,
        product,
        SizedBox(
          width: AbstractProductListTile.switchWidth,
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
