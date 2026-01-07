import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/media_model.dart';
import 'package:path/path.dart' as path;

/// Service for handling Firebase Storage operations
/// Uploads media files and generates Media objects with metadata
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a media file to Firebase Storage and return a Media object
  ///
  /// Parameters:
  /// - file: The PlatformFile to upload
  /// - userId: The user ID for organizing storage paths
  /// - setId: The set ID for organizing storage paths
  /// - questionId: The question ID for organizing storage paths
  /// - mediaType: 'question' or 'answer' to distinguish upload location
  ///
  /// Returns: Media object with download URL and metadata
  Future<Media> uploadMedia({
    required PlatformFile file,
    required String userId,
    required String setId,
    required String questionId,
    required String mediaType, // 'question' or 'answer'
  }) async {
    try {
      AppLogger.i(
        'Starting media upload: ${file.name} for $mediaType in question $questionId',
      );

      // Validate file
      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('File bytes are null on web');
        }
      } else {
        if (file.path == null) {
          throw Exception('File path is null');
        }
      }

      if (file.size == 0) {
        throw Exception('File is empty');
      }

      // Determine media type from extension
      final fileExtension = path.extension(file.name).toLowerCase();
      final detectedMediaType = Media.getMediaType(file.name);

      if (detectedMediaType == 'unknown') {
        throw Exception('Unsupported file type: $fileExtension');
      }

      // Create storage path: sets/{setId}/{questionId}/{mediaType}/original.{ext}
      final storagePath =
          'sets/$setId/$questionId/$mediaType/original$fileExtension';

      AppLogger.d('Storage path: $storagePath');

      // Create reference to Firebase Storage
      final Reference storageRef = _storage.ref().child(storagePath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(detectedMediaType, fileExtension),
        customMetadata: {
          'userId': userId,
          'setId': setId,
          'questionId': questionId,
          'mediaType': mediaType,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final UploadTask uploadTask;
      if (kIsWeb) {
        AppLogger.d('Uploading file bytes (Web)');
        uploadTask = storageRef.putData(file.bytes!, metadata);
      } else {
        final File fileToUpload = File(file.path!);
        AppLogger.d('Uploading file: ${file.path}');
        uploadTask = storageRef.putFile(fileToUpload, metadata);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.d('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      AppLogger.i('Upload completed successfully');

      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();
      AppLogger.i('Download URL obtained: $downloadURL');

      // Get file metadata
      final FullMetadata fullMetadata = await snapshot.ref.getMetadata();

      // Create Media object
      final media = Media(
        type: detectedMediaType,
        storagePath: storagePath,
        downloadURL: downloadURL,
        fileSize: fullMetadata.size ?? file.size,
        status: 'ready',
        altText: null, // Can be added later
        thumbnailURL: null, // Can be added later with Cloud Functions
        dimensions: null, // Can be added later with image processing
      );

      AppLogger.i('Media object created successfully for ${file.name}');
      return media;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error uploading media: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Delete a media file from Firebase Storage
  ///
  /// Parameters:
  /// - storagePath: The storage path of the file to delete
  Future<void> deleteMedia(String storagePath) async {
    try {
      AppLogger.i('Deleting media at: $storagePath');
      final Reference storageRef = _storage.ref().child(storagePath);
      await storageRef.delete();
      AppLogger.i('Media deleted successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting media: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get content type based on media type and file extension
  String _getContentType(String mediaType, String extension) {
    switch (mediaType) {
      case 'image':
        switch (extension) {
          case '.jpg':
          case '.jpeg':
            return 'image/jpeg';
          case '.png':
            return 'image/png';
          case '.gif':
            return 'image/gif';
          case '.webp':
            return 'image/webp';
          case '.bmp':
            return 'image/bmp';
          default:
            return 'image/jpeg';
        }
      case 'audio':
        switch (extension) {
          case '.mp3':
            return 'audio/mpeg';
          case '.wav':
            return 'audio/wav';
          case '.ogg':
            return 'audio/ogg';
          case '.aac':
            return 'audio/aac';
          case '.m4a':
            return 'audio/mp4';
          default:
            return 'audio/mpeg';
        }
      case 'video':
        switch (extension) {
          case '.mp4':
            return 'video/mp4';
          case '.mov':
            return 'video/quicktime';
          case '.avi':
            return 'video/x-msvideo';
          case '.mkv':
            return 'video/x-matroska';
          case '.webm':
            return 'video/webm';
          default:
            return 'video/mp4';
        }
      default:
        return 'application/octet-stream';
    }
  }
}
