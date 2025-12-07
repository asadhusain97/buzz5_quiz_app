/// Model representing media dimensions (width, height, aspect ratio)
class MediaDimensions {
  final int width;
  final int height;
  final double aspectRatio;

  MediaDimensions({
    required this.width,
    required this.height,
    required this.aspectRatio,
  });

  factory MediaDimensions.fromJson(Map<String, dynamic> json) {
    return MediaDimensions(
      width: json['width'] as int,
      height: json['height'] as int,
      aspectRatio: (json['aspectRatio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'aspectRatio': aspectRatio,
    };
  }
}

/// Model representing media attached to questions/answers
/// Supports images, audio, and video with metadata
class Media {
  final String type; // "image", "audio", "video"
  final String storagePath; // Path in Firebase Storage
  final String downloadURL; // Public URL for downloading
  final String? thumbnailURL; // Optional thumbnail URL
  final String? altText; // Accessibility text
  final MediaDimensions? dimensions; // Only for images/videos
  final int fileSize; // Size in bytes
  final String status; // "uploading", "ready", "failed"

  Media({
    required this.type,
    required this.storagePath,
    required this.downloadURL,
    this.thumbnailURL,
    this.altText,
    this.dimensions,
    required this.fileSize,
    this.status = 'ready',
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      type: json['type'] as String,
      storagePath: json['storagePath'] as String,
      downloadURL: json['downloadURL'] as String,
      thumbnailURL: json['thumbnailURL'] as String?,
      altText: json['altText'] as String?,
      dimensions: json['dimensions'] != null
          ? MediaDimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : null,
      fileSize: json['fileSize'] as int,
      status: json['status'] as String? ?? 'ready',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'storagePath': storagePath,
      'downloadURL': downloadURL,
      'thumbnailURL': thumbnailURL,
      'altText': altText,
      'dimensions': dimensions?.toJson(),
      'fileSize': fileSize,
      'status': status,
    };
  }

  /// Helper to determine media type from file extension
  static String getMediaType(String filename) {
    final extension = filename.toLowerCase().split('.').last;

    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return 'image';
    } else if (['mp3', 'wav', 'ogg', 'aac', 'm4a'].contains(extension)) {
      return 'audio';
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      return 'video';
    }

    return 'unknown';
  }
}
