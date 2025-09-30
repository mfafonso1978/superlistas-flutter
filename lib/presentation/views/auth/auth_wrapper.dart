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
    final authUser = ref.watch(authViewModelProvider);

    if (authUser == null) {
      return const LoginScreen();
    } else {
      // Assim que o usuário está logado, tentamos processar operações pendentes.
      Future.microtask(() {
        ref.read(shoppingListRepositoryProvider).processSyncQueue(authUser.id);
      });

      return const MainScreen();
    }
  }
}