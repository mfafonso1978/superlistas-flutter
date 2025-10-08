// lib/presentation/views/auth/signup_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/presentation/providers/providers.dart';
import 'package:superlistas/core/ui/widgets/auth_background.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // #############################################################################
  // CORREÇÃO APLICADA: Lógica do _submit foi totalmente refatorada.
  // #############################################################################
  Future<void> _submit() async {
    // Valida o formulário
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        // 1. Tenta criar a conta. Isso também faz o login automático.
        await ref.read(authViewModelProvider.notifier).signUpWithEmailAndPassword(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 2. Se o passo acima deu certo, faz o logout imediatamente.
        await ref.read(authViewModelProvider.notifier).signOut();

        // 3. Garante que a tela ainda existe antes de interagir com ela.
        if (!mounted) return;

        // 4. Mostra a mensagem de sucesso.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Conta cadastrada com sucesso! Por favor, faça o login.'),
          ),
        );

        // 5. Volta para a tela de login.
        Navigator.of(context).pop();

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(e.toString()),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color glassColor = isDark
        ? scheme.surface.withAlpha((255 * 0.5).toInt())
        : Colors.white.withAlpha((255 * 0.4).toInt());

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Image.asset('assets/images/logo.png', height: 120),
                          const SizedBox(height: 16),
                          Text(
                            'Criar Conta',
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
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nome'),
                            validator: (value) => (value?.isEmpty ?? true) ? 'Por favor, insira seu nome' : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'E-mail'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Por favor, insira um e-mail válido' : null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Senha (mínimo 6 caracteres)'),
                            obscureText: true,
                            validator: (value) => (value?.length ?? 0) < 6 ? 'A senha é muito curta' : null,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Cadastrar'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve({}),
                                children: <TextSpan>[
                                  const TextSpan(text: 'Já tem uma conta? '),
                                  TextSpan(
                                      text: 'Entrar',
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