// lib/presentation/viewmodels/auth_viewmodel.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superlistas/data/datasources/firestore_datasource.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';
import 'package:superlistas/presentation/providers/providers.dart';

class AuthViewModel extends StateNotifier<User?> {
  final AuthRepository _authRepository;
  final RemoteDataSource _remoteDataSource; // <<< NOVA DEPENDÊNCIA
  StreamSubscription? _authStateChangesSubscription;

  // <<< MUDANÇA NO CONSTRUTOR >>>
  AuthViewModel(this._authRepository, this._remoteDataSource) : super(_authRepository.currentUser) {
    // Se já houver um usuário ao iniciar, verifica o documento dele
    if (state != null) {
      _createUserDocumentIfNeeded(state!);
    }

    // Escuta mudanças no estado de autenticação
    _authStateChangesSubscription = _authRepository.onAuthStateChanged.listen(
          (user) {
        state = user;
        // Se um novo usuário logar, verifica/cria o documento dele
        if (user != null) {
          _createUserDocumentIfNeeded(user);
        }
      },
    );
  }

  User? get currentUser => state;

  // <<< NOVO MÉTODO PRIVADO >>>
  Future<void> _createUserDocumentIfNeeded(User user) async {
    try {
      // Tenta buscar o documento do usuário
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.id).get();

      // Se o documento não existir, cria um novo
      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.id).set({
          'name': user.name,
          'email': user.email,
          'photoUrl': user.photoUrl,
        });
      }
    } catch (e) {
      // Tratar o erro se necessário (ex: logar em um serviço de crash reporting)
      // ignore: avoid_print
      print("Erro ao criar documento de usuário no Firestore: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    await _authRepository.signInWithGoogle();
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<void> signUpWithEmailAndPassword(String name, String email, String password) async {
    await _authRepository.signUpWithEmailAndPassword(name, email, password);
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _authRepository.signInWithEmailAndPassword(email, password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authRepository.sendPasswordResetEmail(email);
  }

  bool isPasswordProvider() {
    return _authRepository.isPasswordProvider();
  }

  Future<void> reauthenticateAndDeleteAccount(String password) async {
    await _authRepository.reauthenticateAndDeleteAccount(password);
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    super.dispose();
  }
}