import 'package:easyorder/bloc/auth_bloc.dart';
import 'package:easyorder/models/alert_type.dart';
import 'package:easyorder/pages/splash_screen.dart';
import 'package:easyorder/service/local_cache_service.dart';
import 'package:easyorder/state/providers.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:easyorder/widgets/helpers/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class LogoutButton extends HookConsumerWidget {
  final Logger logger = getLogger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthBloc authBloc = ref.watch(authBlocProvider);
    final LocalCacheService? localCacheService =
        ref.watch(localCacheServiceProvider);

    return IconButton(
      icon: const Icon(
        FontAwesomeIcons.rightFromBracket,
        // color: Colors.white,
      ),
      onPressed: () => _onLogout(context, authBloc, localCacheService),
    );
  }

  void _onLogout(BuildContext context, AuthBloc authBloc,
      LocalCacheService? localCacheService) {
    _logout(context, authBloc, localCacheService).then(
      (_) {
        // Redirect to splash screen so that user can be logged out
        // from anywhere in the app
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => SplashScreen(),
          ),
          (_) => false,
        );
      },
    ).catchError(
      (Object err, StackTrace trace) {
        logger.e('Error: $err');

        if (!context.mounted) {
          return;
        }
        _showErrorDialog(context, 'Logout failed !', 'Please try again later');
      },
    );
  }

  Future<void> _logout(BuildContext context, AuthBloc authBloc,
      LocalCacheService? localCacheService) async {
    if (localCacheService != null) {
      await localCacheService.remove(key: CacheKey.countryCode);
    }

    await authBloc.signOut();
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    UiHelper.showAlertDialog(context, AlertType.error, title, content);
  }
}
