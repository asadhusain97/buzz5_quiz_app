import 'package:firebase_database/firebase_database.dart';
import 'package:buzz5_quiz_app/models/room.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';

/// Service responsible for cleaning up expired game room tables from the realtime database.
///
/// This service identifies and removes room tables that are older than 48 hours based on their
/// creation timestamp. It runs on app startup to maintain database hygiene and prevent
/// unnecessary data accumulation.
class DatabaseCleanupService {
  static const int _expirationThresholdMs =
      AppConstants.roomExpirationHours * 60 * 60 * 1000; // hrs in milliseconds
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Performs cleanup of expired room tables on app startup.
  ///
  /// This method:
  /// 1. Fetches all rooms from the database
  /// 2. Identifies rooms that are older than 48 hours based on their createdAt timestamp
  /// 3. Deletes expired rooms and logs the cleanup results
  ///
  /// Returns the number of rooms cleaned up.
  static Future<int> performStartupCleanup() async {
    try {
      AppLogger.i("Starting database cleanup for expired rooms...");

      // Get all rooms from the database
      final snapshot = await _database.child('rooms').get();

      if (!snapshot.exists || snapshot.value == null) {
        AppLogger.i("No rooms found in database - cleanup complete");
        return 0;
      }

      final roomsData = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredRoomIds = <String>[];
      int totalRoomsChecked = 0;

      // Identify expired rooms
      for (final entry in roomsData.entries) {
        final roomId = entry.key;
        final roomData = entry.value;
        totalRoomsChecked++;

        if (roomData is Map && roomData.containsKey('roomInfo')) {
          final roomInfo = Map<String, dynamic>.from(roomData['roomInfo']);
          final createdAt = roomInfo['createdAt'] as int? ?? 0;

          if (createdAt > 0) {
            final age = now - createdAt;
            if (age > _expirationThresholdMs) {
              expiredRoomIds.add(roomId);
              final ageInHours = (age / (60 * 60 * 1000)).round();
              AppLogger.i("Found expired room: $roomId (age: ${ageInHours}h)");
            }
          } else {
            // Room without valid timestamp - treat as expired for safety
            expiredRoomIds.add(roomId);
            AppLogger.w(
              "Found room without valid timestamp: $roomId - marking for deletion",
            );
          }
        } else {
          // Malformed room data - treat as expired for cleanup
          expiredRoomIds.add(roomId);
          AppLogger.w(
            "Found malformed room data: $roomId - marking for deletion",
          );
        }
      }

      AppLogger.i(
        "Checked $totalRoomsChecked rooms, found ${expiredRoomIds.length} expired rooms",
      );

      // Delete expired rooms
      int deletedCount = 0;
      if (expiredRoomIds.isNotEmpty) {
        for (final roomId in expiredRoomIds) {
          try {
            await _database.child('rooms').child(roomId).remove();
            deletedCount++;
            AppLogger.i("Successfully deleted expired room: $roomId");
          } catch (e) {
            AppLogger.e("Failed to delete expired room $roomId: $e");
          }
        }
      }

      final activeRoomsCount = totalRoomsChecked - deletedCount;
      AppLogger.i(
        "Database cleanup complete: $deletedCount expired rooms deleted, $activeRoomsCount active rooms remaining",
      );

      return deletedCount;
    } catch (e) {
      AppLogger.e("Error during database cleanup: $e");
      return 0;
    }
  }

  /// Cleanup a specific room by ID if it's expired.
  ///
  /// This method can be used for targeted cleanup of individual rooms.
  /// Returns true if the room was expired and deleted, false otherwise.
  static Future<bool> cleanupRoomIfExpired(String roomId) async {
    try {
      final snapshot =
          await _database.child('rooms').child(roomId).child('roomInfo').get();

      if (!snapshot.exists || snapshot.value == null) {
        return false; // Room doesn't exist
      }

      final roomInfo = Map<String, dynamic>.from(snapshot.value as Map);
      final room = Room.fromMap(roomInfo, roomId);

      if (room.isExpired) {
        await _database.child('rooms').child(roomId).remove();
        AppLogger.i("Cleaned up expired room: $roomId");
        return true;
      }

      return false; // Room is not expired
    } catch (e) {
      AppLogger.e("Error cleaning up room $roomId: $e");
      return false;
    }
  }

  /// Get statistics about room ages in the database.
  ///
  /// This is useful for monitoring and debugging purposes.
  /// Returns a map with statistics about the database state.
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final snapshot = await _database.child('rooms').get();

      if (!snapshot.exists || snapshot.value == null) {
        return {
          'totalRooms': 0,
          'expiredRooms': 0,
          'activeRooms': 0,
          'averageAgeHours': 0.0,
        };
      }

      final roomsData = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now().millisecondsSinceEpoch;

      int totalRooms = 0;
      int expiredRooms = 0;
      int activeRooms = 0;
      int totalAgeMs = 0;

      for (final entry in roomsData.entries) {
        final roomData = entry.value;
        totalRooms++;

        if (roomData is Map && roomData.containsKey('roomInfo')) {
          final roomInfo = Map<String, dynamic>.from(roomData['roomInfo']);
          final createdAt = roomInfo['createdAt'] as int? ?? 0;

          if (createdAt > 0) {
            final age = now - createdAt;
            totalAgeMs += age;

            if (age > _expirationThresholdMs) {
              expiredRooms++;
            } else {
              activeRooms++;
            }
          } else {
            expiredRooms++; // Count invalid timestamps as expired
          }
        } else {
          expiredRooms++; // Count malformed data as expired
        }
      }

      final averageAgeHours =
          totalRooms > 0 ? (totalAgeMs / totalRooms) / (60 * 60 * 1000) : 0.0;

      return {
        'totalRooms': totalRooms,
        'expiredRooms': expiredRooms,
        'activeRooms': activeRooms,
        'averageAgeHours': averageAgeHours,
      };
    } catch (e) {
      AppLogger.e("Error getting database stats: $e");
      return {'error': e.toString()};
    }
  }

  /// Check if the cleanup service should run based on various conditions.
  ///
  /// This can be extended to include conditions like:
  /// - Time since last cleanup
  /// - Number of rooms in database
  /// - Available memory/performance considerations
  static bool shouldRunCleanup() {
    // For now, always run cleanup on startup
    // This can be enhanced with additional logic if needed
    return true;
  }
}
