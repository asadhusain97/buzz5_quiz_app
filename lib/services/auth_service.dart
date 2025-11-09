import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fire-and-forget pattern for non-critical lastLogin update
      // This prevents blocking the critical login path with Firestore writes
      if (result.user != null) {
        _updateUserLastLogin(result.user!.uid).catchError((error) {
          // Silent error handling - lastLogin is non-critical
          AppLogger.w(
            'Background lastLogin update failed (non-critical): $error',
          );
          // Do not rethrow - allow login to succeed even if this fails
        });
        AppLogger.i('User signed in: ${result.user!.email}');
      }

      return result;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Sign in error: ${e.message}');
      rethrow;
    } catch (e) {
      AppLogger.e('Unexpected sign in error: $e');
      throw Exception('An unexpected error occurred during sign in');
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Verify Firebase is initialized
      try {
        Firebase.app();
      } catch (e) {
        AppLogger.e('Firebase not initialized during registration: $e');
        throw Exception('Firebase authentication service is not available');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await result.user!.updateDisplayName(displayName);
        }

        // Create user document in Firestore
        await _createUserDocument(result.user!, displayName);
        AppLogger.i('User registered: ${result.user!.email}');
      }

      return result;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Registration error: ${e.message}');
      rethrow;
    } catch (e) {
      AppLogger.e('Unexpected registration error: $e');
      throw Exception('An unexpected error occurred during registration');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.i('User signed out');
    } catch (e) {
      AppLogger.e('Sign out error: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Password reset error: ${e.message}');
      rethrow;
    } catch (e) {
      AppLogger.e('Unexpected password reset error: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String? displayName) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Wait a brief moment to ensure auth token is fully propagated
        if (retryCount > 0) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }

        final userDoc = _firestore.collection('users').doc(user.uid);

        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName ?? user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        AppLogger.i('User document created for: ${user.email}');
        return; // Success, exit retry loop
      } catch (e) {
        retryCount++;
        AppLogger.w('Attempt $retryCount failed to create user document: $e');

        if (retryCount >= maxRetries) {
          AppLogger.e(
            'Failed to create user document after $maxRetries attempts: $e',
          );
          throw Exception(
            'Failed to create user profile after multiple attempts',
          );
        }
      }
    }
  }

  // Now returns Future for error handling, no longer awaited in critical path
  // Update user last login timestamp (non-critical operation)
  Future<void> _updateUserLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      AppLogger.i('Last login timestamp updated for user: $uid');
    } catch (e) {
      // Now throws instead of silent catch - caller handles with catchError
      AppLogger.w('Failed to update last login timestamp: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = currentUser;
      if (user == null) throw Exception('No user signed in');

      // Update Firebase Auth profile
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).update(updates);

      AppLogger.i('User profile updated for: ${user.email}');
    } catch (e) {
      AppLogger.e('Error updating user profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Get user document from Firestore
  Future<DocumentSnapshot?> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      AppLogger.e('Error fetching user document: $e');
      return null;
    }
  }

  // Delete user account (for future use)
  Future<void> deleteAccount() async {
    try {
      User? user = currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete Firestore document first
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      AppLogger.i('User account deleted');
    } catch (e) {
      AppLogger.e('Error deleting account: $e');
      throw Exception('Failed to delete account');
    }
  }
}
