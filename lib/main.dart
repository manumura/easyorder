import 'dart:async';

import 'package:easyorder/firebase_options_dev.dart';
import 'package:easyorder/firebase_options_prod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easyorder/models/about_route_arguments.dart';
import 'package:easyorder/pages/category_edit_screen.dart';
import 'package:easyorder/pages/category_list_screen.dart';
import 'package:easyorder/pages/customer_edit_screen.dart';
import 'package:easyorder/pages/customer_list_screen.dart';
import 'package:easyorder/pages/order_edit_screen.dart';
import 'package:easyorder/pages/order_list_screen.dart';
import 'package:easyorder/pages/privacy_policy_screen.dart';
import 'package:easyorder/pages/product_edit_screen.dart';
import 'package:easyorder/pages/product_list_screen.dart';
import 'package:easyorder/pages/splash_screen.dart';
import 'package:easyorder/pages/terms_and_conditions_screen.dart';
import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:easyorder/shared/constants.dart';
import 'package:easyorder/state/service_locator.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

// import 'package:flutter/rendering.dart';
// import 'package:device_preview/device_preview.dart';

// TODO https://pub.dev/packages/firebase_ui_auth
// TODO AppCheck : https://pub.dev/packages/firebase_app_check/example https://firebase.flutter.dev/docs/app-check/usage/
// TODO Missing google_app_id. Firebase Analytics disabled
// TODO MaterialStateProperties https://www.youtube.com/watch?v=CylXr3AF3uU&list=WL&index=29&ab_channel=Flutter
// TODO invoices
// TODO OrderFilterScreen
// TODO noti due date
// https://www.youtube.com/watch?v=JAq9fVn3X7U
// https://stackoverflow.com/questions/65223986/schedule-notification-in-flutter-using-firebase
// https://medium.com/firebase-developers/how-to-schedule-a-cloud-function-to-run-in-the-future-in-order-to-build-a-firestore-document-ttl-754f9bf3214a
// https://sanjog12799.medium.com/notifications-in-flutter-2300ce067ec3
Future<void> main() async {
  //   debugPaintSizeEnabled = true;
  //   debugPaintBaselinesEnabled = true;
  //   debugPaintPointersEnabled = true;
  //   debugPrintMarkNeedsLayoutStacks = true;
  //   debugPrintMarkNeedsPaintStacks = true;

  WidgetsFlutterBinding.ensureInitialized();

  const String env = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
  final FirebaseOptions firebaseOptions = _getFirebaseOptions(environment: env);
  await Firebase.initializeApp(
    options: firebaseOptions,
  );

  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    // If you wish to record a "non-fatal" exception, please use `FirebaseCrashlytics.instance.recordFlutterError` instead
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // If you wish to record a "non-fatal" exception, please remove the "fatal" parameter
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Logger.level = Level.off; // off / debug

  // GetIt
  setupServiceLocator();

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
  //  runApp(
  //    DevicePreview(
  //      builder: (context) => ProviderScope(child: MyApp(),),
  //    ),
  //  );
}

FirebaseOptions _getFirebaseOptions({required String environment}) {
  switch (environment) {
    case 'dev':
      return DevFirebaseOptions.currentPlatform;
    case 'prod':
      return ProdFirebaseOptions.currentPlatform;
    default:
      throw UnsupportedError(
        'FirebaseOptions are not supported for this environment.',
      );
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Logger logger = getLogger();
  final FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics.instance;

  // Set routes to use in Navigator
  final Map<String, Widget> routes = <String, Widget>{
    SplashScreen.routeName: SplashScreen(),
    PrivacyPolicyScreen.routeName: PrivacyPolicyScreen(),
    TermsAndConditionsScreen.routeName: TermsAndConditionsScreen(),
    CustomerListScreen.routeName: CustomerListScreen(),
    CustomerEditScreen.routeName: const CustomerEditScreen(),
    CategoryListScreen.routeName: const CategoryListScreen(),
    CategoryEditScreen.routeName: const CategoryEditScreen(),
    ProductListScreen.routeName: ProductListScreen(),
    ProductEditScreen.routeName: ProductEditScreen(),
    OrderListScreen.routeName: OrderListScreen(),
    OrderEditScreen.routeName: OrderEditScreen(),
    // CartScreen.routeName: const CartScreen(
    // cartItems: <CartItemModel>[],
    // ),
  };

  @override
  Widget build(BuildContext context) {
    logger.d('----- Building main page -----');
    return MaterialApp(
      // debugShowMaterialGrid: true,
      // locale: DevicePreview.of(context).locale,
      // builder: DevicePreview.appBuilder,
      //   CupertinoApp(
      //   localizationsDelegates: [
      //     DefaultMaterialLocalizations.delegate,
      //     DefaultCupertinoLocalizations.delegate,
      //     DefaultWidgetsLocalizations.delegate,
      //   ],
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Simple Order Manager',
      theme: getAdaptiveThemeData(context),
      // TODO dark mode
      // themeMode: ThemeMode.dark,
      // darkTheme: ThemeData.dark(),
      // home: SplashScreen(),
      // routes: routes,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute<void>(
              builder: (BuildContext context) => SplashScreen(),
            );
          default:
            return PageRouteBuilder<Widget>(
              pageBuilder: (BuildContext context, Animation<double> animation,
                  Animation<double> secondaryAnimation) {
                AboutRouteArguments? aboutRouteArguments;
                if (settings.arguments is AboutRouteArguments) {
                  aboutRouteArguments =
                      settings.arguments as AboutRouteArguments?;
                }

                if (routes[settings.name!] is PrivacyPolicyScreen) {
                  return PrivacyPolicyScreen(
                      isLoggedIn: aboutRouteArguments?.isLoggedIn ?? false);
                }

                if (routes[settings.name!] is TermsAndConditionsScreen) {
                  return TermsAndConditionsScreen(
                      isLoggedIn: aboutRouteArguments?.isLoggedIn ?? false);
                }

                return routes[settings.name!]!;
              },
              transitionsBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child) {
                const Offset begin = Offset(0.0, 1.0);
                const Offset end = Offset.zero;
                const Cubic curve = Curves.ease;

                final Animatable<Offset> tween =
                    Tween<Offset>(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );

                // return FadeTransition(
                //   opacity: animation,
                //   child: child,
                // );
              },
            );
        }
      },
      navigatorObservers: <NavigatorObserver>[
        FirebaseAnalyticsObserver(analytics: firebaseAnalytics),
      ],
    );
  }
}
