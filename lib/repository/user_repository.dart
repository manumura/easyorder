import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class UserRepository {
  Future<bool> createCounters({required String? userId});
}

class UserRepositoryFirebaseImpl implements UserRepository {
  final FirebaseFirestore _store = FirebaseFirestore.instance;
  final Logger logger = getLogger();

  @override
  Future<bool> createCounters({required String? userId}) async {
    try {
      logger.d('Fetching counters for user ID $userId');
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _store.collection('users').doc(userId).get();
      if (!doc.exists) {
        logger.d('Creating counters for user ID $userId');
        final Map<String, dynamic> countersAsJson = <String, dynamic>{
          'categoriesCount': 0,
          'productsCount': 0,
          'customersCount': 0,
        };

        // Add document by user id
        await _store.collection('users').doc(userId).set(countersAsJson);
        logger.d('Create counters success for user ID $userId');
      }
      return true;
    } catch (error) {
      logger.e('add product error: $error');
      return false;
    }
  }
}
