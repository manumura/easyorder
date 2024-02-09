import 'package:easyorder/shared/utils.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/pages/category_list_screen.dart';
import 'package:easyorder/pages/customer_list_screen.dart';
import 'package:easyorder/pages/order_list_screen.dart';
import 'package:easyorder/pages/product_list_screen.dart';
import 'package:easyorder/shared/about_box_children.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info/package_info.dart';

class SideDrawer extends StatefulWidget {
  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Simple Order Manager'),
            elevation:
                Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Manage Orders'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  settings:
                      const RouteSettings(name: OrderListScreen.routeName),
                  builder: (BuildContext context) => OrderListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shop),
            title: const Text('Manage Products'),
            onTap: () {
//              Navigator.pushReplacementNamed(context, '/');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  settings:
                      const RouteSettings(name: ProductListScreen.routeName),
                  builder: (BuildContext context) => ProductListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  settings:
                      const RouteSettings(name: CategoryListScreen.routeName),
                  builder: (BuildContext context) => const CategoryListScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_sharp),
            title: const Text('Manage Customers'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  settings:
                      const RouteSettings(name: CustomerListScreen.routeName),
                  builder: (BuildContext context) => CustomerListScreen(),
                ),
              );
            },
          ),
          const Divider(
            color: Colors.black,
            thickness: 0.5,
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.comments),
            title: const Text('Give Feedback'),
            onTap: () {
              BetterFeedback.of(context).show((UserFeedback feedback) async {
                final String screenshotFilePath = await writeImageToStorage(
                    feedback.screenshot, 'screenshot.png');

                final Email email = Email(
                  body: feedback.text,
                  subject: 'Simple Order Manager Feedback',
                  recipients: <String>['manumuradev@gmail.com'],
                  attachmentPaths: <String>[screenshotFilePath],
                  isHTML: false,
                );
                await FlutterEmailSender.send(email);
              });
            },
          ),
          const Divider(),
          AboutListTile(
            icon: const Icon(
              Icons.info,
            ),
            applicationIcon: Icon(
              Icons.shopping_cart_rounded,
              size: 65,
              color: Theme.of(context).colorScheme.secondary,
            ),
            applicationName: _packageInfo.appName,
            applicationVersion: _packageInfo.version,
            applicationLegalese: applicationLegalese,
            aboutBoxChildren: buildAboutBoxChildren(context),
            child: const Text('About'),
          ),
        ],
      ),
    );
  }
}
