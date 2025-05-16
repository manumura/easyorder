import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final int year = DateTime.now().year;
final String applicationLegalese = '© $year Emmanuel Mura';
const String genericErrorTitle = 'Something went wrong!';
const String genericErrorMessage =
    'Please try again later, and make sure the app is up-to-date.';
final NumberFormat currencyFormat = NumberFormat.currency(
    locale: Intl.defaultLocale, symbol: '\$', decimalDigits: 2);

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
