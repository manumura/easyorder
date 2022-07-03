import 'dart:io';

import 'package:easyorder/models/image_type.dart';
import 'package:easyorder/models/storage_model.dart';
import 'package:easyorder/repository/storage_repository.dart';
import 'package:easyorder/state/service_locator.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';

abstract class StorageService {
  Future<StorageModel?> upload(
      {required String? userId,
      required File file,
      required ImageType imageType,
      String? path});

  Future<void> delete({required String path});

  void dispose();
}

@Injectable(as: StorageService)
@lazySingleton
class StorageServiceImpl implements StorageService {
  final StorageRepository? storageRepository = getIt<StorageRepository>();
  final Logger logger = getLogger();

  @override
  Future<StorageModel?> upload(
      {required String? userId,
      required File file,
      required ImageType imageType,
      String? path}) async {
    logger.d('uploadImage: $file');

    try {
      if (storageRepository == null) {
        logger.e('Storage repository is null');
        return null;
      }

      final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName =
          '${currentTimestamp.toString()}_${basename(file.path)}';
      final String? directory = ImageTypeDirectory.getDirectory(imageType);
      final String filePath = path ?? '/users/$userId/$directory/$fileName';

      final StorageModel? result =
          await storageRepository!.upload(file: file, path: filePath);
      logger.d('upload result: $result');
      return result;
    } catch (error) {
      logger.e('uploadImage error: $error');
      return null;
    }
  }

  @override
  Future<void> delete({required String path}) {
    if (storageRepository == null) {
      logger.e('Storage repository is null');
      return Future<void>.value();
    }

    return storageRepository!.delete(path: path);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE StorageBloc ***');
  }
}
