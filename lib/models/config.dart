const String pageSizeConfigKey = 'page_size';
const int defaultPageSize = 20;
const String minAppVersionConfigKey = 'min_app_version';
const String defaultMinAppVersion = '1.2.3';
const String latestAppVersionConfigKey = 'latest_app_version';
const String defaultLatestAppVersion = '1.2.3';
const String appcastURLConfigKey = 'appcast_url';
const String defaultAppcastURL =
    'https://raw.githubusercontent.com/manumura/flutter-easy-order-appcast/main/appcast.xml';
const String countryCodeCacheTtlInSecondsConfigKey =
    'country_code_cache_ttl_in_seconds';
const int defaultCountryCodeCacheTtlInSeconds = 1209600; // 1209600

class Config {
  Config({
    required this.pageSize,
    required this.minAppVersion,
    required this.latestAppVersion,
    required this.appcastURL,
    required this.countryCodeCacheTtlInSeconds,
  });

  final int pageSize;
  final String minAppVersion;
  final String latestAppVersion;
  final String appcastURL;
  final int countryCodeCacheTtlInSeconds;

  @override
  String toString() {
    return 'Config{pageSize: $pageSize, minAppVersion: $minAppVersion, '
        'latestAppVersion: $latestAppVersion, appcastURL: $appcastURL, '
        'countryCodeCacheTtlInSeconds: $countryCodeCacheTtlInSeconds}';
  }
}
