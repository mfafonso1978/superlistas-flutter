// lib/domain/repositories/auth_repository.dart
import 'package:superlistas/domain/entities/user.dart';

abstract class AuthRepository {
  // Uma stream que notifica sobre o estado de login (logado/deslogado).
  Stream<User?> get onAuthStateChanged;

  // Obtém o usuário atualmente logado.
  User? get currentUser;

  // Inicia o fluxo de login com o Google.
  Future<User?> signInWithGoogle();

  // Faz o logout do usuário.
  Future<void> signOut();
}