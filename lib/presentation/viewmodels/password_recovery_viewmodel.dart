// lib/presentation/viewmodels/password_recovery_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';

// O estado pode ser simples, pois não temos mais um fluxo de várias etapas.
class PasswordRecoveryViewModel extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  PasswordRecoveryViewModel(this._authRepository) : super(const AsyncValue.data(null));

// No futuro, podemos adicionar métodos aqui se implementarmos
// a recuperação de senha nativa do Firebase. Por enquanto, fica vazio.
}