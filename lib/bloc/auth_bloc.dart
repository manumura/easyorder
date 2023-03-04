import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/repository/auth_repository.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

abstract class AuthBloc {
  Stream<UserModel?> get user$;

  void login(UserModel user);

  UserModel? autoLogin();

  Future<UserModel?> signInWithEmailAndPassword(
      {required String email, required String password});

  Future<UserModel?> signInWithGoogle();

  Future<UserModel?> signInWithFacebook();

  Future<UserModel?> createUserWithEmailAndPassword(
      {required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  void dispose();
}

class AuthBlocImpl implements AuthBloc {
  AuthBlocImpl({required this.authRepository}) {
    logger.d('----- Building AuthBlocImpl -----');
  }
  final AuthRepository authRepository;

  static const String userEmail = 'easyOrderUserEmail';
  static const String userId = 'easyOrderUserId';
  static const String userIsEmailVerified = 'easyOrderIsEmailVerified';

  final Logger logger = getLogger();
  // final LocalStorageService? localStorageService = getIt<LocalStorageService>();

  final BehaviorSubject<UserModel?> _userSubject =
      BehaviorSubject<UserModel?>.seeded(null);

  @override
  Stream<UserModel?> get user$ => _userSubject.stream;

  @override
  void login(UserModel user) {
    _userSubject.add(user);
    // if (localStorageService != null) {
    //   logger.e('Store user in local storage');
    //   localStorageService!.save(key: 'currentUser', jsonObject: user);
    // }
  }

  @override
  UserModel? autoLogin() {
    final UserModel? user = authRepository.currentUser();
    if (user != null) {
      _userSubject.add(user);
      // if (localStorageService != null) {
      //   logger.e('Store user in local storage');
      //   localStorageService!.save(key: 'currentUser', jsonObject: user);
      // }
    }
    return user;
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    final UserModel? user = await authRepository.signInWithEmailAndPassword(
        email: email, password: password);
    return user;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final UserModel? user = await authRepository.signInWithGoogle();
    return user;
  }

  // https://medium.com/flutter-community/flutter-facebook-login-77fcd187242
  @override
  Future<UserModel?> signInWithFacebook() async {
    final UserModel? user = await authRepository.signInWithFacebook();
    return user;
  }

  @override
  Future<UserModel?> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    final UserModel? user = await authRepository.createUserWithEmailAndPassword(
        email: email, password: password);
    return user;
  }

  @override
  Future<void> signOut() async {
    await authRepository.signOut();
    _userSubject.add(null);
    // if (localStorageService != null) {
    //   logger.e('Remove user from local storage');
    //   localStorageService!.delete(key: 'currentUser');
    // }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await authRepository.sendPasswordResetEmail(email: email);
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE AuthBloc ***');
  }
}
