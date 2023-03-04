import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:easyorder/models/config.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class ConfigurationRepository {
  String getString({required String key});

  void dispose();
}

class ConfigurationRepositoryImpl implements ConfigurationRepository {
  ConfigurationRepositoryImpl._({required this.remoteConfig}) {
    logger.d('----- Building ConfigurationRepositoryImpl -----');
  }

  static final Logger logger = getLogger();
  FirebaseRemoteConfig remoteConfig;

  static Future<ConfigurationRepositoryImpl> getInstance() async {
    final FirebaseRemoteConfig remoteConfig = await _setupRemoteConfig();
    final ConfigurationRepositoryImpl instance =
        ConfigurationRepositoryImpl._(remoteConfig: remoteConfig);
    return instance;
  }

  static Future<FirebaseRemoteConfig> _setupRemoteConfig() async {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
    // Enable developer mode to relax fetch throttling
    remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 60),
      minimumFetchInterval: const Duration(hours: 12),
    ));
    remoteConfig.setDefaults(<String, dynamic>{
      minAppVersionConfigKey: defaultMinAppVersion,
      latestAppVersionConfigKey: defaultLatestAppVersion,
      pageSizeConfigKey: defaultPageSize,
      appcastURLConfigKey: defaultAppcastURL,
      countryCodeCacheTtlInSecondsConfigKey:
          defaultCountryCodeCacheTtlInSeconds,
    });

    try {
      // Using default duration to force fetching from remote server.
      await remoteConfig.fetch();
      await remoteConfig.activate();
    } on FirebaseException catch (exception) {
      // Fetch throttled.
      logger.e('Remote config fetch throttled', exception);
    } catch (exception) {
      logger.e(
          'Unable to fetch remote config. Cached or default values will be used',
          exception);
    }

    return remoteConfig;
  }

  @override
  String getString({required String key}) {
    return remoteConfig.getString(key);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE ConfigurationRepository ***');
  }
}
