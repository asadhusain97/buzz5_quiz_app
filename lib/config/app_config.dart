class AppConfig {
  // All secrets
  static late final String firebaseApiKey;
  static late final String firebaseAppId;
  static late final String firebaseMessagingSenderId;
  static late final String firebaseProjectId;
  static late final String firebaseAuthDomain;
  static late final String firebaseDatabaseUrl;
  static late final String firebaseStorageBucket;
  static late final String recaptchaKey;

  /// Initializes the application configuration.
  ///
  /// This method must be called before accessing any configuration variables.
  /// It loads variables from compile-time environment variables.
  static void initialize() {
    // In release mode, load from compile-time environment variables
    firebaseApiKey = const String.fromEnvironment('FIREBASE_API_KEY');
    firebaseAppId = const String.fromEnvironment('FIREBASE_APP_ID');
    firebaseMessagingSenderId = const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    firebaseProjectId = const String.fromEnvironment('FIREBASE_PROJECT_ID');
    firebaseAuthDomain = const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
    firebaseDatabaseUrl = const String.fromEnvironment('FIREBASE_DATABASE_URL');
    firebaseStorageBucket = const String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
    );
    recaptchaKey = const String.fromEnvironment('RECAPTCHA_SITE_KEY');
  }

  // Firebase-specific validation (core Firebase functionality)
  static bool get isFirebaseConfigValid {
    return firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty &&
        firebaseAuthDomain.isNotEmpty &&
        firebaseDatabaseUrl.isNotEmpty &&
        firebaseStorageBucket.isNotEmpty;
  }

  static List<String> get missingFirebaseVariables {
    final missing = <String>[];

    if (firebaseApiKey.isEmpty) missing.add('FIREBASE_API_KEY');
    if (firebaseAppId.isEmpty) missing.add('FIREBASE_APP_ID');
    if (firebaseMessagingSenderId.isEmpty) {
      missing.add('FIREBASE_MESSAGING_SENDER_ID');
    }
    if (firebaseProjectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    if (firebaseAuthDomain.isEmpty) missing.add('FIREBASE_AUTH_DOMAIN');
    if (firebaseDatabaseUrl.isEmpty) missing.add('FIREBASE_DATABASE_URL');
    if (firebaseStorageBucket.isEmpty) missing.add('FIREBASE_STORAGE_BUCKET');

    return missing;
  }

  // Validation helpers
  static bool get areOtherConfigsValid {
    return recaptchaKey.isNotEmpty;
  }

  static List<String> get missingOtherVariables {
    final missing = <String>[];

    if (recaptchaKey.isEmpty) missing.add('RECAPTCHA_SITE_KEY');

    return missing;
  }
}
