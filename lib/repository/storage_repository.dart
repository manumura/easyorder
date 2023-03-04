import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:easyorder/models/storage_model.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';

abstract class StorageRepository {
  Future<StorageModel?> upload({required File file, required String path});

  Future<void> delete({required String path});
}

@Injectable(as: StorageRepository)
@lazySingleton
class StorageRepositoryImpl implements StorageRepository {
  final Reference _storageReference = FirebaseStorage.instance.ref();
  final Logger logger = getLogger();

  @override
  Future<StorageModel?> upload(
      {required File file, required String path}) async {
    final String? mimeType = lookupMimeType(file.path);

    final UploadTask uploadTask;
    if (mimeType != null) {
      final List<String> mimeTypeData = mimeType.split('/');
      uploadTask = _storageReference.child(path).putFile(
            file,
            SettableMetadata(
              contentType: '${mimeTypeData[0]}/${mimeTypeData[1]}',
            ),
          );
    } else {
      uploadTask = _storageReference.child(path).putFile(file);
    }

    final String url = await uploadTask.then((TaskSnapshot snapshot) async {
      logger.d('upload complete');
      final String url = await snapshot.ref.getDownloadURL();
      return url;
    }).onError((Object e, StackTrace stackTrace) {
      // FirebaseException
      logger.e('uploadImage error: $e');
      return Future<String>.value('');
    });

    final StorageModel? result = (url.isEmpty)
        ? null
        : StorageModel(url: url, path: path);
    logger.d('upload result: $result');
    return result;
  }

  @override
  Future<void> delete({required String path}) async {
    try {
      await _storageReference.child(path).delete();
      logger.d('delete image complete');
    } catch (e) {
      logger.e('delete image error: $e');
    }
  }

///////////////////////////////////////////////////////////////////
//     uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
//       print('percent ${snapshot.bytesTransferred / snapshot.totalBytes * 100}');
//     });
////////////////////////////////////////////////////////////////
}
