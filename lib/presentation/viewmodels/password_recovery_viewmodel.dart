// lib/presentation/viewmodels/password_recovery_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';

// O ViewModel agora gerencia o estado da operação de envio de e-mail
class PasswordRecoveryViewModel extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  PasswordRecoveryViewModel(this._authRepository) : super(const AsyncValue.data(null));

  // Ação que a UI irá chamar
  Future<void> sendPasswordResetEmail(String email) async {
    // Define o estado como carregando
    state = const AsyncValue.loading();
    try {
      // Chama o método do repositório
      await _authRepository.sendPasswordResetEmail(email);
      // Em caso de sucesso, define o estado como concluído
      state = const AsyncValue.data(null);
    } catch (e, s) {
      // Em caso de erro, atualiza o estado com a informação do erro
      state = AsyncValue.error(e, s);
      // Propaga o erro para que a UI possa exibi-lo (em um SnackBar, por exemplo)
      rethrow;
    }
  }
}