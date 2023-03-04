import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageRepository {
  Future<String?> get({required String key});

  Future<void> save({required String key, required String value});

  Future<void> delete({required String key});
}

@Injectable(as: LocalStorageRepository)
@lazySingleton
class LocalStorageRepositoryImpl implements LocalStorageRepository {
  final Logger logger = getLogger();

  @override
  Future<String?> get({required String key}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> save({required String key, required String value}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  @override
  Future<void> delete({required String key}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }
}
