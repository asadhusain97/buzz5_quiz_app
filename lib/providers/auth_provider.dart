import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:buzz5_quiz_app/models/app_user.dart';
import 'package:buzz5_quiz_app/services/auth_service.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user?.isGuest ?? false;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  // Initialize authentication state listener
  void initialize() {
    // Check if Firebase is initialized before setting up auth listener
    try {
      Firebase.app(); // This will throw if not initialized
      _authService.authStateChanges.listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          await _loadUserFromFirestore(firebaseUser);
        } else {
          _user = null;
          notifyListeners();
        }
      });
    } catch (e) {
      AppLogger.e('Firebase not initialized in AuthProvider: $e');
      _setError('Firebase authentication not available');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserFromFirestore(User firebaseUser) async {
    try {
      final userDoc = await _authService.getUserDocument(firebaseUser.uid);

      if (userDoc != null && userDoc.exists) {
        _user = AppUser.fromFirestore(userDoc);
      } else {
        // If no Firestore document exists, create one from Firebase User
        _user = AppUser.fromFirebaseUser(firebaseUser);
      }

      _clearError();
      notifyListeners();
    } catch (e) {
      AppLogger.e('Error loading user from Firestore: $e');
      // Fallback to Firebase User data
      _user = AppUser.fromFirebaseUser(firebaseUser);
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result?.user != null) {
        // User will be loaded automatically via auth state listener
        return true;
      }

      _setError('Sign in failed');
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred during sign in');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result?.user != null) {
        // User will be loaded automatically via auth state listener
        return true;
      }

      _setError('Registration failed');
      return false;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('Firebase Auth registration error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      AppLogger.e('Unexpected registration error: $e');
      _setError(
        'An unexpected error occurred during registration: ${e.toString()}',
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in as guest
  Future<bool> signInAsGuest({required String guestName}) async {
    if (guestName.trim().isEmpty) {
      _setError('Guest name cannot be empty');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _user = AppUser.guest(guestName: guestName.trim());
      AppLogger.i('Guest login successful: ${_user!.displayName}');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.e('Guest login error: $e');
      _setError('Failed to sign in as guest');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update guest name
  Future<bool> updateGuestName({required String newName}) async {
    if (_user == null || !_user!.isGuest) {
      _setError('Can only update guest user names');
      return false;
    }

    if (newName.trim().isEmpty) {
      _setError('Guest name cannot be empty');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _user = _user!.copyWith(
        displayName: newName.trim(),
        updatedAt: DateTime.now(),
      );
      AppLogger.i('Guest name updated to: ${_user!.displayName}');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.e('Failed to update guest name: $e');
      _setError('Failed to update guest name');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      // If guest user, just clear the user data
      if (_user?.isGuest ?? false) {
        _user = null;
        AppLogger.i('Guest user signed out');
      } else {
        // For authenticated users, sign out from Firebase
        await _authService.signOut();
        _user = null;
        AppLogger.i('Authenticated user signed out');
        // Auth state listener will handle the UI update
      }
    } catch (e) {
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update local user data
      _user = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        photoURL: photoURL ?? _user!.photoURL,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update profile');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Failed to send password reset email');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_authService.currentUser != null) {
      await _loadUserFromFirestore(_authService.currentUser!);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    AppLogger.e('Auth error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Convert Firebase Auth errors to user-friendly messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email address is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled in Firebase Console. Please enable it in Authentication → Sign-in method';
      case 'firebase-app-check-token-is-invalid':
        return 'Firebase App Check is blocking requests. Please disable App Check or configure it properly';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'permission-denied':
        return 'Permission denied. Please try again';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again';
      case 'unauthenticated':
        return 'Authentication failed. Please try again';
      case 'internal':
        return 'Internal error occurred. Please try again';
      case 'cancelled':
        return 'Operation was cancelled';
      case 'deadline-exceeded':
        return 'Request timeout. Please try again';
      default:
        AppLogger.e('Unmapped Firebase Auth error: ${e.code} - ${e.message}');
        return e.message ?? 'An authentication error occurred';
    }
  }

  // Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
