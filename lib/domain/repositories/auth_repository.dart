// lib/domain/repositories/auth_repository.dart
import 'package:superlistas/domain/entities/user.dart';

abstract class AuthRepository {
  Stream<User?> get onAuthStateChanged;
  User? get currentUser;
  Future<User?> signInWithGoogle();
  Future<void> signOut();

  Future<User?> signUpWithEmailAndPassword(String name, String email, String password);
  Future<User?> signInWithEmailAndPassword(String email, String password);

  Future<void> sendPasswordResetEmail(String email);

  // --- NOVOS MÉTODOS NO CONTRATO ---
  bool isPasswordProvider();
  Future<void> reauthenticateAndDeleteAccount(String password);
}