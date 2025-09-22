// lib/data/repositories/firebase_auth_repository_impl.dart
import 'package:superlistas/data/datasources/firebase_auth_service.dart';
import 'package:superlistas/domain/entities/user.dart';
import 'package:superlistas/domain/repositories/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _service;

  FirebaseAuthRepositoryImpl(this._service);

  @override
  Stream<User?> get onAuthStateChanged => _service.onAuthStateChanged;

  @override
  User? get currentUser => _service.currentUser;

  @override
  Future<User?> signInWithGoogle() => _service.signInWithGoogle();

  @override
  Future<void> signOut() => _service.signOut();
}