// lib/presentation/viewmodels/auth_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';

class AuthViewModel extends StateNotifier<User?> {
  final AuthRepository _authRepository;
  StreamSubscription? _authStateChangesSubscription;

  AuthViewModel(this._authRepository) : super(_authRepository.currentUser) {
    _authStateChangesSubscription = _authRepository.onAuthStateChanged.listen(
          (user) => state = user,
    );
  }

  User? get currentUser => state;

  Future<void> signInWithGoogle() async {
    await _authRepository.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<void> signUpWithEmailAndPassword(String name, String email, String password) async {
    await _authRepository.signUpWithEmailAndPassword(name, email, password);
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _authRepository.signInWithEmailAndPassword(email, password);
  }

  // --- NOVAS AÇÕES PARA A UI ---
  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  bool isPasswordProvider() {
    return _authRepository.isPasswordProvider();
  }

  Future<void> reauthenticateAndDeleteAccount(String password) async {
    await _authRepository.reauthenticateAndDeleteAccount(password);
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }
}