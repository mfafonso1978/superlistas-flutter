// lib/presentation/views/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/presentation/views/auth/auth_wrapper.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  static const splashDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Timer(splashDuration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    final LinearGradient overlayGradient = isDark
        ? LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.primary.withAlpha((255 * 0.7).toInt()),
        Colors.black.withAlpha((255 * 0.8).toInt()),
      ],
    )
        : LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.surface.withAlpha((255 * 0.60).toInt()),
        scheme.primaryContainer.withAlpha((255 * 0.70).toInt()),
      ],
    );

    final Color sloganColor = isDark ? Colors.white.withOpacity(0.9) : scheme.onSurfaceVariant;
    final Color shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2);
    final Color progressBackgroundColor = isDark ? Colors.white.withOpacity(0.2) : scheme.primary.withOpacity(0.2);

    final footerTextStyle = TextStyle(
      fontSize: 12,
      color: sloganColor,
      shadows: [
        Shadow(
          color: shadowColor.withOpacity(0.7),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: overlayGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeInAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: size.width * 0.7,
                            height: size.width * 0.7,
                            child: Image.asset('assets/images/logo.png'),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Text(
                            'Suas compras, simplificadas',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: size.width * 0.045,
                              color: sloganColor,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: shadowColor.withOpacity(0.7),
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size.height * 0.08),
                          SizedBox(
                            width: size.width * 0.08,
                            height: size.width * 0.08,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  scheme.secondary),
                              backgroundColor: progressBackgroundColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.03),
                  child: Column(
                    children: [
                      // <<< FORMATO DA VERSÃO CORRIGIDO >>>
                      packageInfoAsync.when(
                        data: (info) => Text(
                          // Usa o novo formato
                          'Versão ${info.version} (Build ${info.buildNumber})',
                          style: footerTextStyle,
                        ),
                        loading: () => Text('Carregando versão...', style: footerTextStyle),
                        error: (e, s) => Text('Versão indisponível', style: footerTextStyle),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2025 Superlistas',
                        style: footerTextStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}