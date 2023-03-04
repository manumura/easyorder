import 'package:easyorder/models/local_cache_model.dart';
import 'package:easyorder/service/local_storage_service.dart';

class LocalCacheService {
  LocalCacheService({
    required this.localStorageService,
  });

  final LocalStorageService localStorageService;

  Future<Object?> get({required CacheKey key}) async {
    final Map<String, dynamic>? json =
        await localStorageService.getObject(key: key.toString());
    if (json == null) {
      return null;
    }

    final JsonLocalCacheModel jsonLocalCacheModel =
        JsonLocalCacheModel.fromJson(json);
    if (DateTime.now().isAfter(jsonLocalCacheModel.expirationDate)) {
      localStorageService.delete(key: key.toString());
      return null;
    }

    return jsonLocalCacheModel.value;
  }

  Future<void> put(
      {required CacheKey key, required LocalCacheModel localCache}) async {
    final DateTime expirationDate =
        DateTime.now().add(Duration(seconds: localCache.timeToLiveInSeconds));
    final JsonLocalCacheModel jsonLocalCacheModel = JsonLocalCacheModel(
      value: localCache.value,
      expirationDate: expirationDate,
    );
    return localStorageService.saveObject(
        key: key.toString(), jsonObject: jsonLocalCacheModel);
  }

  Future<void> remove({required CacheKey key}) async {
    return localStorageService.delete(key: key.toString());
  }
}

enum CacheKey {
  countryCode,
}
