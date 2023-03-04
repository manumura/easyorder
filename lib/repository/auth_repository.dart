import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:easyorder/exceptions/authentication_exception.dart';
import 'package:easyorder/models/user_model.dart';
import 'package:easyorder/widgets/helpers/logger.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

abstract class AuthRepository {
  UserModel? currentUser();

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

class AuthRepositoryFirebaseImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final Logger logger = getLogger();

  @override
  UserModel? currentUser() {
    final User? fbUser = _firebaseAuth.currentUser;
    return fbUser == null ? null : UserModel.fromFirebaseUser(fbUser);
  }

  @override
  Future<UserModel?> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      logger.d('firebase user: $userCredential');

      if (userCredential.user == null) {
        logger.d('user is null');
        return null;
      }

      final UserModel user = UserModel.fromFirebaseUser(userCredential.user!);
      return user;
    } on Exception catch (e, s) {
      logger.e('Login error: $e $s');
      throw AuthenticationException(
          'Please check your username and password', e);
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount == null) {
        logger.e('googleSignInAccount is null');
        return null;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      logger
          .d('google user: $userCredential'); // firebase, google.com, password

      if (userCredential.user == null) {
        logger.d('user is null');
        return null;
      }

      final UserModel user = UserModel.fromFirebaseUser(userCredential.user!);
      return user;
    } on Exception catch (e) {
      logger.e('Login error: $e');
      throw AuthenticationException('Please try again later', e);
    }
  }

  @override
  Future<UserModel?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login();
      if (result.status == LoginStatus.success) {
        // Create a credential from the access token
        final String? token = result.accessToken?.token;

        if (token == null) {
          logger.d('token is null');
          return null;
        }

        final OAuthCredential credential =
            FacebookAuthProvider.credential(token);
        // Once signed in, return the UserCredential
        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user == null) {
          logger.d('user is null');
          return null;
        }

        final UserModel user = UserModel.fromFirebaseUser(userCredential.user!);
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e, s) {
      logger.e('Login error: $e $s');
      if (e.code == 'account-exists-with-different-credential') {
        throw AuthenticationException(
            'Did you already register with this email using a different provider ?',
            e);
      }
      throw AuthenticationException('Please try again later', e);
    } on Exception catch(e) {
      logger.e('Login error: $e');
      throw AuthenticationException('Please try again later', e);
    }
  }

  @override
  Future<UserModel?> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        logger.d('user is null');
        return null;
      }

      await userCredential.user!.sendEmailVerification();
      final UserModel user = UserModel.fromFirebaseUser(userCredential.user!);
      return user;
    } on Exception catch (e, s) {
      logger.e('Create user error: $e $s');
      throw AuthenticationException(
          'Please try again and verify that your email is not already used', e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on Exception catch (e, s) {
      logger.e('Send reset password error: $e $s');
      throw AuthenticationException('Please try again later', e);
    }
  }

  @override
  Future<void> signOut() async {
    await _facebookAuth.logOut();
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  void dispose() {
    logger.d('*** DISPOSE AuthRepository ***');
  }
}
