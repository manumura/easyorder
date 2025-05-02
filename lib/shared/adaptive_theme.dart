import 'dart:io';

import 'package:flutter/material.dart';

final Color backgroundColor =
    Platform.isAndroid ? Colors.indigo.shade100 : Colors.grey.shade50;
final Color titleColor =
    Platform.isAndroid ? Colors.indigo.shade700 : Colors.blueGrey.shade700;

final ThemeData _androidTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.indigo,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.indigo,
    accentColor: Colors.indigoAccent,
  ),
  canvasColor: Colors.indigo.shade100,
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.indigo.shade100,
  ),
  // highlightColor: Colors.indigo.shade700,
  inputDecorationTheme: InputDecorationTheme(
    errorStyle: const TextStyle(
      color: Colors.red,
    ),
    hintStyle: TextStyle(
      color: backgroundColor,
    ),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
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
    accentColor: Colors.blueGrey.shade600,
  ),
  canvasColor: Colors.grey.shade50,
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.grey.shade50,
  ),
  // highlightColor: Colors.blueGrey.shade700,
  inputDecorationTheme: InputDecorationTheme(
    errorStyle: const TextStyle(
      color: Colors.red,
    ),
    hintStyle: TextStyle(
      color: backgroundColor,
    ),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
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

final NavigationBarThemeData navigationBarThemeData = NavigationBarThemeData(
  height: 62,
  indicatorColor: Colors.indigo.shade100,
  // backgroundColor: Colors.white,
  iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return const IconThemeData(
        size: 30.0,
        color: Colors.indigo,
      );
    }
    return const IconThemeData(
      size: 24.0,
      opacity: 0.8,
    );
  }),
  labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return const TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
        // letterSpacing: 0.8,
      );
    }
    return const TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w900,
      color: Colors.grey,
      // letterSpacing: 0.8,
    );
  }),
);
