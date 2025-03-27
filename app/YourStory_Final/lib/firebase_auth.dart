import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Example: Get the user's UID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
