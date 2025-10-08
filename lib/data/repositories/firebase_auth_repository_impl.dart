// lib/data/repositories/firebase_auth_repository_impl.dart
import 'package:superlistas/data/datasources/firebase_auth_service.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _service;

  FirebaseAuthRepositoryImpl(this._service);

  @override
  Stream<User?> get onAuthStateChanged => _service.onAuthStateChanged;

  @override
  User? get currentUser => _service.currentUser;

  @override
  Future<User?> signInWithGoogle() => _service.signInWithGoogle();

  @override
  Future<void> signOut() => _service.signOut();

  @override
  Future<User?> signUpWithEmailAndPassword(String name, String email, String password) {
    return _service.signUpWithEmailAndPassword(name, email, password);
  }

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) {
    return _service.signInWithEmailAndPassword(email, password);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _service.sendPasswordResetEmail(email);
  }

  // --- IMPLEMENTAÇÃO DOS NOVOS MÉTODOS ---
  @override
  bool isPasswordProvider() {
    return _service.isPasswordProvider();
  }

  @override
  Future<void> reauthenticateAndDeleteAccount(String password) {
    return _service.reauthenticateAndDeleteAccount(password);
  }
}