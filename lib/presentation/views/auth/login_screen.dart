// lib/presentation/views/auth/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/core/ui/widgets/glass_dialog.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/core/ui/widgets/auth_background.dart';
import 'package:superlistas/presentation/views/auth/signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authViewModelProvider.notifier).signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authViewModelProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPasswordResetDialog() {
    final emailResetController = TextEditingController();

    showGlassDialog(
      context: context,
      title: const Text('Recuperar Senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Digite seu e-mail para receber o link de recuperação.'),
          const SizedBox(height: 16),
          TextField(
            controller: emailResetController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (emailResetController.text.isNotEmpty) {
              final auth = ref.read(authRepositoryProvider);
              try {
                await auth.sendPasswordResetEmail(emailResetController.text.trim());
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link de recuperação enviado! Verifique seu e-mail.')),
                  );
                }
              } catch(e) {
                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: ${e.toString()}')),
                  );
                }
              }
            }
          },
          child: const Text('Enviar'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color glassColor = isDark
        ? scheme.surface.withAlpha((255 * 0.5).toInt())
        : Colors.white.withAlpha((255 * 0.4).toInt());

    final String googleButtonAsset = isDark
        ? 'assets/images/android_dark_rd_ctn@4x.png'
        : 'assets/images/android_light_rd_ctn@4x.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AuthBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: glassColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha((255 * 0.2).toInt()),
                        width: 1.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/images/logo.png', height: 120),
                          const SizedBox(height: 16),
                          Text(
                            'Bem-vindo de volta!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Por favor, insira seu e-mail' : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Senha'),
                            obscureText: true,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Por favor, insira sua senha' : null,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showPasswordResetDialog,
                              child: const Text('Esqueceu sua senha?'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: _signIn,
                                child: const Text('Entrar'),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: scheme.outline)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('OU'),
                                  ),
                                  Expanded(child: Divider(color: scheme.outline)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _signInWithGoogle,
                                    child: Image.asset(googleButtonAsset, height: 48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve({}),
                                children: <TextSpan>[
                                  const TextSpan(text: 'Não tem uma conta? '),
                                  TextSpan(
                                      text: 'Cadastre-se',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: scheme.secondary)),
                                ],
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
          ),
        ],
      ),
    );
  }
}