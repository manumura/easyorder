import 'dart:io';

import 'package:easyorder/bloc/auth_bloc.dart';
import 'package:easyorder/models/config.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/pages/login_screen.dart';
import 'package:easyorder/pages/order_list_screen.dart';
import 'package:easyorder/shared/adaptive_theme.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/ui_elements/adapative_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:upgrader/upgrader.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const String routeName = '/';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final Logger logger = getLogger();

  @override
  void initState() {
    super.initState();
    final AuthBloc authBloc = ref.read(authBlocProvider);
    final UserModel? loggedInUser = authBloc.autoLogin();
    logger.d('----- Logged in user : $loggedInUser -----');
  }

  @override
  Widget build(BuildContext context) {
    logger.d('----- Building splash screen -----');
    final AsyncValue<UserModel?> user$ = ref.watch(user$Provider);
    return _buildUserStream(context, user$);
  }

  Widget _buildUserStream(BuildContext context, AsyncValue<UserModel?> user$) {
    return user$.when(
      data: (UserModel? user) => _buildUpgradeAlert(context, user),
      loading: () => _buildWaitingScreen(context),
      error: (Object err, StackTrace? stack) => _buildErrorScreen(context, err),
    );
  }

  Widget _buildUpgradeAlert(BuildContext context, UserModel? user) {
    final Config? config = ref.watch(configProvider);
    if (config == null) {
      return _buildWaitingScreen(context);
    }
    logger.d(
        'Remote config minAppVersion: ${config.minAppVersion}, appcastURL: ${config.appcastURL}');

    return UpgradeAlert(
      upgrader: Upgrader(
        storeController: UpgraderStoreController(
          // UpgraderPlayStore(),
          onAndroid: () => UpgraderAppcastStore(
            appcastURL: config.appcastURL,
          ),
          oniOS: () => UpgraderAppcastStore(appcastURL: config.appcastURL),
        ),
        upgraderDevice: UpgraderDevice(),
        // debugLogging: true,
        minAppVersion: config.minAppVersion,
      ),
      barrierDismissible: false,
      dialogStyle: Platform.isAndroid
          ? UpgradeDialogStyle.material
          : UpgradeDialogStyle.cupertino,
      onUpdate: () {
        logger.d('----- Updating app -----');
        return true;
      },
      child: _buildScreen(
        context,
        user,
      ),
    );
  }

  Widget _buildScreen(BuildContext context, UserModel? user) {
    final bool isLoggedIn = user != null;
    logger.d('isLoggedIn? $isLoggedIn');
    return isLoggedIn ? OrderListScreen() : LoginScreen();
  }

  Widget _buildWaitingScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: _buildBackgroundImage(context),
            color: backgroundColor,
//              border: Border.all(color: Colors.red),
          ),
          padding: const EdgeInsets.all(10.0),
          child: _buildLayout(context),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, Object err) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: _buildBackgroundImage(context),
            color: backgroundColor,
//              border: Border.all(color: Colors.red),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Center(
            child: Text('Error: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final double maxHeight = constraints.maxHeight;
      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: maxHeight - 0.95 * maxHeight,
            child: _buildTitle(context, maxHeight),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AdaptiveProgressIndicator(),
          ),
        ],
      );
    });
  }

  Widget _buildTitle(BuildContext context, double maxHeight) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    const double titleFontSize = 40; // deviceHeight > 550 ? 40 : 30;
    final double titlePadding = deviceHeight > 550 ? 30 : 10;
    return Container(
      margin: EdgeInsets.only(top: titlePadding, bottom: titlePadding),
//      child: IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'SIMPLE',
            style: TextStyle(
              fontSize: titleFontSize,
              fontFamily: 'LuckiestGuy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            'ORDER',
            style: TextStyle(
              fontSize: titleFontSize,
              fontFamily: 'LuckiestGuy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            'MANAGER',
            style: TextStyle(
              fontSize: titleFontSize,
              fontFamily: 'LuckiestGuy',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
//      ),
    );
  }

  DecorationImage _buildBackgroundImage(BuildContext context) {
    final Color color = backgroundColor;
    return DecorationImage(
      fit: BoxFit.scaleDown,
      colorFilter: ColorFilter.mode(color.withOpacity(0.5), BlendMode.dstATop),
      image: const AssetImage('assets/background.png'),
    );
  }
}
