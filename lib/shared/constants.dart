import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
const String applicationLegalese = '© 2021 Emmanuel Mura';
const String genericErrorTitle = 'Something went wrong!';
const String genericErrorMessage =
    'Please try again later, and make sure the app is up-to-date.';

class Constants {
  Constants._();

  static int minPasswordLength = 6;
  static int minNameLength = 3;
  static int maxNameLength = 50;
  static int maxDescriptionLength = 100;
  static int maxClientIdLength = 50;
  static int maxOrderDescriptionLength = 500;
  static int minCustomerNameLength = 3;
  static int maxCustomerNameLength = 100;
  static int maxCustomerAddressLength = 500;
}
