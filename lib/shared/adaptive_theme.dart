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
  // indicatorColor: Colors.transparent,
  // backgroundColor: Colors.white,
  iconTheme: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
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
  labelTextStyle: MaterialStateProperty.resolveWith(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
            // letterSpacing: 0.8,
          );
        }
        return const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          // letterSpacing: 0.8,
        );
      }),
);
