// lib/presentation/viewmodels/auth_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';

// O estado agora é o próprio usuário (ou nulo se deslogado).
class AuthViewModel extends StateNotifier<User?> {
  final AuthRepository _authRepository;
  StreamSubscription? _authStateChangesSubscription;

  AuthViewModel(this._authRepository) : super(_authRepository.currentUser) {
    // No construtor, nós começamos a "ouvir" o stream de autenticação.
    // Sempre que o Firebase notificar uma mudança (login, logout),
    // o nosso 'state' será atualizado automaticamente.
    _authStateChangesSubscription = _authRepository.onAuthStateChanged.listen(
          (user) => state = user,
    );
  }

  // Getter para conveniência.
  User? get currentUser => state;

  // Ações que a UI pode chamar. Elas apenas delegam para o repositório.
  Future<void> signInWithGoogle() async {
    // Não precisamos gerenciar estado de loading aqui,
    // pois o pop-up do Google já serve como indicador.
    await _authRepository.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  // É crucial cancelar a inscrição do stream quando a ViewModel for descartada
  // para evitar vazamentos de memória.
  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }
}