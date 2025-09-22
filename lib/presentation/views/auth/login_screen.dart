// lib/presentation/views/auth/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/core/ui/widgets/auth_background.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color glassColor = isDark
        ? scheme.surface.withOpacity(0.5)
        : Colors.white.withOpacity(0.4);

    final String googleButtonAsset = isDark
        ? 'assets/images/android_dark_rd_ctn@4x.png'
        : 'assets/images/android_light_rd_ctn@4x.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AuthBackground(), // <<< CORRIGIDO
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bem-vindo ao Superlistas',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use sua conta Google para continuar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 40),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ref.read(authViewModelProvider.notifier).signInWithGoogle();
                              },
                              child: Image.asset(
                                googleButtonAsset,
                                height: 48,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}