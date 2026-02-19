import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'usuario_service.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService._();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await UsuarioService.instance.crearUsuario(
          userId: credential.user!.uid,
          email: email,
        );
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing in: ${e.code}');
      rethrow;
    }
  }

  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await UsuarioService.instance.crearUsuario(
          userId: credential.user!.uid,
          email: email,
        );
      }
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error creating user: ${e.code}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  String? getUserId() {
    return currentUser?.uid;
  }

  String? getUserEmail() {
    return currentUser?.email;
  }
}
