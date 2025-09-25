// lib/data/datasources/remote_config_service.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart'; // Import para o kDebugMode

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService(this._remoteConfig);

  // Valores padrão para o caso de falha na busca ou primeira execução
  final _defaults = <String, dynamic>{
    'min_supported_version_code': 1,
    'latest_version_code': 1,
    'latest_version_name': '1.0.0',
    'update_url': 'https://github.com/mfafonso1978/superlistas-flutter/releases',
    'release_notes': 'Correções de bugs gerais.',
    'premium_stats_enabled': false,
  };

  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Para testes, um valor baixo é bom. Para produção, aumente para horas.
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Usando kDebugMode para garantir que o print só apareça em modo de depuração
      if (kDebugMode) {
        print('Erro ao inicializar o Remote Config: $e');
      }
    }
  }

  // Getters para acessar cada parâmetro de forma segura
  int get minSupportedVersionCode => _remoteConfig.getInt('min_supported_version_code');
  int get latestVersionCode => _remoteConfig.getInt('latest_version_code');
  String get latestVersionName => _remoteConfig.getString('latest_version_name');
  String get updateUrl => _remoteConfig.getString('update_url');
  String get releaseNotes => _remoteConfig.getString('release_notes');
  bool get isPremiumStatsEnabled => _remoteConfig.getBool('premium_stats_enabled');
}