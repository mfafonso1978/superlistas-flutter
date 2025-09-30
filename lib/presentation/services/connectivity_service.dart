// lib/presentation/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/presentation/providers/providers.dart';

// Este provider expõe o estado atual da conectividade. Nenhuma mudança aqui.
final connectivityStatusProvider = StreamProvider<ConnectivityResult>((ref) {
  // O Stream do connectivity_plus mudou e agora retorna uma lista.
  // Pegamos o primeiro resultado para simplificar.
  return Connectivity().onConnectivityChanged.map((results) => results.first);
});

// Este serviço ouvinte aciona a sincronização quando a conexão volta.
class ConnectivityListener {
  // <<< MUDANÇA PRINCIPAL: TROCAMOS 'WidgetRef' por 'ProviderRef' >>>
  final ProviderRef ref;

  ConnectivityListener(this.ref) {
    _init();
  }

  void _init() {
    ref.listen<AsyncValue<ConnectivityResult>>(connectivityStatusProvider, (previous, next) {
      // Garantimos que temos um valor válido antes de comparar
      final wasDisconnected = previous?.valueOrNull == ConnectivityResult.none;
      final isNowConnected = next.valueOrNull != null && next.valueOrNull != ConnectivityResult.none;

      // Se estávamos desconectados e agora estamos conectados...
      if (wasDisconnected && isNowConnected) {
        final user = ref.read(authViewModelProvider);
        if (user != null) {
          // ...chama o processamento da fila.
          ref.read(shoppingListRepositoryProvider).processSyncQueue(user.id);
        }
      }
    });
  }
}