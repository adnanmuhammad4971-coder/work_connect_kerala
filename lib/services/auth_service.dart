import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update password for current logged-in user
  Future<void> updatePassword(String newPassword) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword);
    } else {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No logged in user found.',
      );
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

