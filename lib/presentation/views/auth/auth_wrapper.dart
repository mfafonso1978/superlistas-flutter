// lib/presentation/views/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/auth/login_screen.dart';
import 'package:superlistas/presentation/views/main/main_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agora o watch retorna um objeto User? diretamente.
    final authUser = ref.watch(authViewModelProvider);

    // Se não há usuário (é nulo), mostramos a tela de login.
    if (authUser == null) {
      return const LoginScreen();
    }
    // Se há um usuário, mostramos a tela principal.
    else {
      return const MainScreen();
    }
    // O estado de loading inicial é gerenciado pela SplashScreen,
    // então não precisamos de um indicador de progresso aqui.
  }
}