import 'dart:convert';

import 'package:easyorder/models/json_object.dart';
import 'package:easyorder/repository/local_storage_repository.dart';
import 'package:easyorder/state/service_locator.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

abstract class LocalStorageService {
  Future<Map<String, dynamic>?> getObject({required String key});

  Future<void> saveObject(
      {required String key, required JsonObject jsonObject});

  Future<void> delete({required String key});
}

@Injectable(as: LocalStorageService)
@lazySingleton
class LocalStorageServiceImpl implements LocalStorageService {
  final LocalStorageRepository? localStorageRepository =
      getIt<LocalStorageRepository>();
  final Logger logger = getLogger();

  @override
  Future<Map<String, dynamic>?> getObject({required String key}) async {
    logger.d('get json from key: $key');
    if (localStorageRepository == null) {
      logger.e('Local storage repository is null');
      return null;
    }

    final String? valueAsJsonString =
        await localStorageRepository!.get(key: key);
    logger.d('json value as string fetched: $valueAsJsonString');
    final Map<String, dynamic>? json = valueAsJsonString != null
        ? jsonDecode(valueAsJsonString) as Map<String, dynamic>?
        : null;
    logger.d('json value fetched: $json');
    return json;
  }

  @override
  Future<void> saveObject(
      {required String key, required JsonObject jsonObject}) async {
    logger.d('save object with key $key: $jsonObject');
    if (localStorageRepository == null) {
      logger.e('Local storage repository is null');
      return;
    }

    final String json = jsonEncode(jsonObject.toJson());
    return localStorageRepository!.save(key: key, value: json);
  }

  @override
  Future<void> delete({required String key}) async {
    if (localStorageRepository == null) {
      logger.e('Local storage repository is null');
      return;
    }

    return localStorageRepository!.delete(key: key);
  }

//  test() async {
//    LocalStorageRepository localStorageRepository = LocalStorageRepositoryImpl();
//    await localStorageRepository.save(key: 'test', json: user.toJson());
//    await localStorageRepository.get(key: 'test');
//    await localStorageRepository.delete(key: 'test');
//    await localStorageRepository.get(key: 'test');
//  }
}
