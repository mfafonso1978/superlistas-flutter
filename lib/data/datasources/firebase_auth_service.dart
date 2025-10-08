// lib/data/datasources/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:superlistas/domain/entities/user.dart';

class FirebaseAuthService {
  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    firebase.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  User? _userFromFirebase(firebase.User? user) {
    if (user == null) return null;

    return User(
      id: user.uid,
      name: user.displayName ?? user.email ?? 'Usuário',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  Stream<User?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }

  User? get currentUser {
    return _userFromFirebase(_firebaseAuth.currentUser);
  }

  // Verifica se o usuário logou com provedor de senha (e-mail)
  bool isPasswordProvider() {
    if (_firebaseAuth.currentUser == null) return false;
    return _firebaseAuth.currentUser!.providerData
        .any((userInfo) => userInfo.providerId == 'password');
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase.AuthCredential credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase.UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      return _userFromFirebase(userCredential.user);
    } catch (e) {
      throw Exception('Erro durante o login com Google: ${e.toString()}');
    }
  }

  Future<User?> signUpWithEmailAndPassword(String name, String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      return _userFromFirebase(_firebaseAuth.currentUser);
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(userCredential.user);
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // --- NOVO MÉTODO PARA REAUTENTICAR E EXCLUIR CONTA ---
  Future<void> reauthenticateAndDeleteAccount(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuário não encontrado para reautenticação.');
      }

      // Cria a credencial para reautenticar
      final cred = firebase.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Reautentica o usuário para confirmar a identidade
      await user.reauthenticateWithCredential(cred);

      // Se a reautenticação for bem-sucedida, exclui a conta
      await user.delete();

    } on firebase.FirebaseAuthException catch (e) {
      // Personaliza mensagens de erro comuns
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('A senha informada está incorreta.');
      }
      throw Exception('Erro ao excluir conta: ${e.message}');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}