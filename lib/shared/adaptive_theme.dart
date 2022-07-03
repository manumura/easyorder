import 'package:flutter/material.dart';
import 'package:easyorder/shared/constants.dart';

final ThemeData _androidTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.indigo,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.indigo,
    accentColor: Colors.blueAccent,
  ),
  inputDecorationTheme: InputDecorationTheme(
    errorStyle: const TextStyle(
      color: Colors.red,
    ),
    hintStyle: TextStyle(
      color: backgroundColor,
    ),
  ),
  textTheme: const TextTheme(
    headline6: TextStyle(
      color: Colors.white,
    ),
  ),
  fontFamily: 'Raleway',
);

final ThemeData _iOSTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.grey,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.grey,
    accentColor: Colors.blue,
  ),
  inputDecorationTheme: InputDecorationTheme(
    errorStyle: const TextStyle(
      color: Colors.red,
    ),
    hintStyle: TextStyle(
      color: backgroundColor,
    ),
  ),
  textTheme: const TextTheme(
    headline6: TextStyle(
      color: Colors.white,
    ),
  ),
  fontFamily: 'Raleway',
);

ThemeData getAdaptiveThemeData(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.android
      ? _androidTheme
      : _iOSTheme;
}
