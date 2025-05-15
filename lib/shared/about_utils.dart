import 'package:flutter/material.dart';
import 'package:easyorder/models/about_route_arguments.dart';
import 'package:easyorder/pages/privacy_policy_screen.dart';
import 'package:easyorder/pages/terms_and_conditions_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

void openAboutDialog(
    BuildContext context, PackageInfo packageInfo, String applicationLegalese) {
  showAdaptiveDialog(
    context: context,
    builder: (BuildContext context) => buildAboutDialog(
      context,
      packageInfo,
      applicationLegalese,
    ),
    useRootNavigator: false,
  );
}

Widget buildAboutDialog(
    BuildContext context, PackageInfo packageInfo, String applicationLegalese) {
  return Theme(
    data: Theme.of(context).copyWith(
      dialogTheme: DialogThemeData(
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
    ),
    child: AboutDialog(
      applicationIcon: Icon(
        Icons.shopping_cart_rounded,
        size: 65,
        color: Theme.of(context).colorScheme.secondary,
      ),
      applicationName: packageInfo.appName,
      applicationVersion: packageInfo.version,
      applicationLegalese: applicationLegalese,
      children: buildAboutBoxChildren(context),
    ),
  );
}

List<Widget> buildAboutBoxChildren(BuildContext context) {
  return <Widget>[
    const SizedBox(
      height: 20,
    ),
    Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text:
                'Simple Order Manager is your Back Office for all your order management.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text:
                'You can easily create categories and products by category. Then just simply add your products to the order.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text:
                'Mark the order completed to keep track of all your past orders.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'No more pen and paper, everything is in your pocket !',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    const SizedBox(
      height: 20,
    ),
    TextButton(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => Theme.of(context).primaryColor),
      ),
      onPressed: () {
        Navigator.of(context).pushNamed(
          PrivacyPolicyScreen.routeName,
          arguments: AboutRouteArguments(isLoggedIn: true),
        );
      },
      child: const Text('Privacy Policy'),
    ),
    TextButton(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
            (Set<WidgetState> states) => Theme.of(context).primaryColor),
      ),
      onPressed: () {
        Navigator.of(context).pushNamed(
          TermsAndConditionsScreen.routeName,
          arguments: AboutRouteArguments(isLoggedIn: true),
        );
      },
      child: const Text('Terms & Conditions'),
    ),
  ];
}
