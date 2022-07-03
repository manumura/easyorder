import 'package:flutter/material.dart';
import 'package:easyorder/models/about_route_arguments.dart';
import 'package:easyorder/pages/privacy_policy_screen.dart';
import 'package:easyorder/pages/terms_and_conditions_screen.dart';

List<Widget> buildAboutBoxChildren(BuildContext context) {
  return <Widget>[
    const SizedBox(
      height: 20,
    ),
    RichText(
      text: const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text:
                'Simple Order Manager is your Back Office for all your order management.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    RichText(
      text: const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text:
                'You can easily create categories and products by category. Then just simply add your products to the order.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    RichText(
      text: const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text:
                'Mark the order completed to keep track of all your past orders.',
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    ),
    RichText(
      text: const TextSpan(
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
        foregroundColor: MaterialStateProperty.resolveWith(
            (Set<MaterialState> states) => Theme.of(context).primaryColor),
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
        foregroundColor: MaterialStateProperty.resolveWith(
            (Set<MaterialState> states) => Theme.of(context).primaryColor),
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
