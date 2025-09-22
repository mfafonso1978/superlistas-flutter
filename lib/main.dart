// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:superlistas/core/ui/theme/app_theme.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/splash/splash_screen.dart';

// <<< 1. IMPORTS DO FIREBASE >>>
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Arquivo gerado pela FlutterFire CLI

void main() async {
  // <<< 2. GARANTIR A INICIALIZAÇÃO DOS BINDINGS (JÁ EXISTENTE) >>>
  WidgetsFlutterBinding.ensureInitialized();

  // <<< 3. INICIALIZAR O FIREBASE >>>
  // Isso lê o arquivo firebase_options.dart e configura a comunicação.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // <<< 4. O RESTO DO SEU CÓDIGO (JÁ EXISTENTE) >>>
  await initializeDateFormatting('pt_BR', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Superlistas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: const SplashScreen(),
    );
  }
}