import 'dart:async';

import 'package:easyorder/repository/user_repository.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';

abstract class UserBloc {
  Future<bool> createCounters({required String? userId});
}

class UserBlocImpl implements UserBloc {
  UserBlocImpl({required this.userRepository}) {
    logger.d('----- Building UserBlocImpl -----');
  }
  final UserRepository userRepository;

  final Logger logger = getLogger();

  @override
  Future<bool> createCounters({required String? userId}) async {
    return userRepository.createCounters(userId: userId);
  }
}
