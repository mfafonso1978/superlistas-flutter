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

    // <<< PRINT DE DEBUG 3: Verificando o mapeamento final >>>
    print('[DEBUG - Mapeamento] Mapeando firebase.User para a entidade User:');
    print('[DEBUG - Mapeamento]   photoURL do Firebase: ${user.photoURL}');

    return User(
      id: user.uid,
      name: user.displayName ?? 'Usuário sem nome',
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

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('[DEBUG - GoogleSignIn] O usuário cancelou o login com o Google.');
        return null;
      }

      // <<< PRINT DE DEBUG 1: Verificando o que o Google nos devolveu >>>
      print('[DEBUG - GoogleSignIn] Informações recebidas DIRETAMENTE do Google:');
      print('[DEBUG - GoogleSignIn]   Display Name: ${googleUser.displayName}');
      print('[DEBUG - GoogleSignIn]   Email: ${googleUser.email}');
      print('[DEBUG - GoogleSignIn]   Photo URL: ${googleUser.photoUrl}');


      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase.AuthCredential credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase.UserCredential userCredential =
      await _firebaseAuth.signInWithCredential(credential);

      // <<< PRINT DE DEBUG 2: Verificando o que o Firebase Auth criou >>>
      print('[DEBUG - FirebaseUser] Informações no objeto firebase.User APÓS login:');
      print('[DEBUG - FirebaseUser]   Display Name: ${userCredential.user?.displayName}');
      print('[DEBUG - FirebaseUser]   Email: ${userCredential.user?.email}');
      print('[DEBUG - FirebaseUser]   Photo URL: ${userCredential.user?.photoURL}');


      return _userFromFirebase(userCredential.user);
    } catch (e) {
      print('Erro durante o login com Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}