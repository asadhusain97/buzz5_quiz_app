import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

/// Service for checking network connectivity status
/// Uses connectivity_plus package to detect internet availability
class ConnectivityService {
  /// Private constructor to prevent instantiation
  ConnectivityService._();

  /// Singleton instance of Connectivity
  static final Connectivity _connectivity = Connectivity();

  /// Checks if device has active internet connection
  /// Returns true if connected to wifi, mobile, ethernet, vpn, or bluetooth
  /// Returns false if no connection or airplane mode
  static Future<bool> isConnected() async {
    try {
      final List<ConnectivityResult> connectivityResults =
          await _connectivity.checkConnectivity();

      // Check if any of the connectivity results indicate an active connection
      final bool hasConnection = connectivityResults.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn ||
            result == ConnectivityResult.bluetooth,
      );

      if (hasConnection) {
        AppLogger.i(
          'Connectivity check: Connected via ${connectivityResults.join(", ")}',
        );
      } else {
        AppLogger.w(
          'Connectivity check: No connection detected (${connectivityResults.join(", ")})',
        );
      }

      return hasConnection;
    } catch (e) {
      AppLogger.e('Connectivity check failed: $e');
      // Fail open - assume connection exists if check fails
      // This prevents false negatives from blocking legitimate login attempts
      return true;
    }
  }
}
