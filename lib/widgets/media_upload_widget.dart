import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';

/// A widget for uploading and previewing media files (images, audio, video)
/// Max file size: 15 MB
/// Supports: jpg, jpeg, png, gif, mp3, wav, mp4, mov, avi
/// Also supports media URLs
class MediaUploadWidget extends StatefulWidget {
  final String label;
  final Function(PlatformFile? file) onFileSelected;
  final Function(String? url)? onUrlChanged;
  final PlatformFile? initialFile;
  final String? initialUrl;

  const MediaUploadWidget({
    super.key,
    required this.label,
    required this.onFileSelected,
    this.onUrlChanged,
    this.initialFile,
    this.initialUrl,
  });

  @override
  State<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends State<MediaUploadWidget> {
  PlatformFile? _selectedFile;
  late TextEditingController _urlController;
  static const int maxFileSizeInBytes = 15 * 1024 * 1024; // 15 MB

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.initialFile;
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Images
          'jpg',
          'jpeg',
          'png',
          'gif',
          // Audio
          'mp3',
          'wav',
          'm4a',
          // Video
          'mp4',
          'mov',
          'avi',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size
        if (file.size > maxFileSizeInBytes) {
          if (mounted) {
            _showErrorDialog(
              'File too large',
              'The selected file is ${_formatFileSize(file.size)}. Maximum allowed size is 15 MB.',
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _urlController.clear(); // Clear URL when file is selected
        });
        widget.onFileSelected(file);
        if (widget.onUrlChanged != null) {
          widget.onUrlChanged!(null); // Notify parent URL is cleared
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Failed to pick file: $e');
      }
    }
  }

  void _onUrlChanged(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isNotEmpty && _selectedFile != null) {
      // Clear file when URL is entered
      setState(() {
        _selectedFile = null;
      });
      widget.onFileSelected(null);
    }
    if (widget.onUrlChanged != null) {
      widget.onUrlChanged!(trimmedUrl.isEmpty ? null : trimmedUrl);
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
    });
    widget.onFileSelected(null);
  }

  void _clearUrl() {
    setState(() {
      _urlController.clear();
    });
    if (widget.onUrlChanged != null) {
      widget.onUrlChanged!(null);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  MediaType _getMediaType() {
    if (_selectedFile != null) {
      final extension = _selectedFile!.extension?.toLowerCase();
      if (extension == null) return MediaType.none;

      if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        return MediaType.image;
      } else if (['mp3', 'wav', 'm4a'].contains(extension)) {
        return MediaType.audio;
      } else if (['mp4', 'mov', 'avi'].contains(extension)) {
        return MediaType.video;
      }
    } else if (_urlController.text.trim().isNotEmpty) {
      final url = _urlController.text.trim().toLowerCase();
      // Check URL extension or common patterns
      if (url.contains(RegExp(r'\.(jpg|jpeg|png|gif)(\?|$)'))) {
        return MediaType.image;
      } else if (url.contains(RegExp(r'\.(mp3|wav|m4a)(\?|$)'))) {
        return MediaType.audio;
      } else if (url.contains(RegExp(r'\.(mp4|mov|avi)(\?|$)'))) {
        return MediaType.video;
      }
      // Default to image for URLs without clear extension
      return MediaType.image;
    }
    return MediaType.none;
  }

  bool get _hasMedia =>
      _selectedFile != null ||
      (_urlController.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.labelSmall.copyWith(
            color: ColorConstants.lightTextColor.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        _hasMedia ? _buildPreviewArea() : _buildUploadArea(),
      ],
    );
  }

  Widget _buildUploadArea() {
    return Row(
      children: [
        // Upload Button (less wide)
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ColorConstants.lightTextColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: ColorConstants.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Upload',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ColorConstants.primaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // OR Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'OR',
            style: AppTextStyles.bodySmall.copyWith(
              color: ColorConstants.lightTextColor.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // URL TextField (takes more space)
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: _urlController,
            onChanged: _onUrlChanged,
            decoration: InputDecoration(
              hintText: 'Enter media URL',
              hintStyle: TextStyle(
                color: ColorConstants.lightTextColor.withValues(alpha: 0.4),
                fontSize: 10,
              ),
              prefixIcon: Icon(
                Icons.link,
                size: 16,
                color: ColorConstants.primaryColor.withValues(alpha: 0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: ColorConstants.lightTextColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: ColorConstants.lightTextColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: ColorConstants.primaryColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              isDense: true,
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: ColorConstants.lightTextColor,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewArea() {
    final mediaType = _getMediaType();
    final isFile = _selectedFile != null;
    final displayName = isFile
        ? _selectedFile!.name
        : _urlController.text.trim().substring(
            0,
            _urlController.text.trim().length > 40
                ? 40
                : _urlController.text.trim().length,
          );
    final displayInfo = isFile
        ? _formatFileSize(_selectedFile!.size)
        : 'URL';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: ColorConstants.primaryColor.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: ColorConstants.primaryColor.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          // Preview thumbnail/icon
          _buildPreviewThumbnail(mediaType),
          const SizedBox(width: 10),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ColorConstants.lightTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayInfo,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ColorConstants.lightTextColor.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: isFile ? _clearFile : _clearUrl,
            icon: Icon(Icons.close, size: 16, color: ColorConstants.errorColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewThumbnail(MediaType type) {
    switch (type) {
      case MediaType.image:
        return _buildImagePreview();
      case MediaType.audio:
        return _buildIconPreview(Icons.audiotrack, Colors.purple);
      case MediaType.video:
        return _buildIconPreview(Icons.videocam, Colors.red);
      case MediaType.none:
        return _buildIconPreview(Icons.insert_drive_file, Colors.grey);
    }
  }

  Widget _buildImagePreview() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: ColorConstants.hintGrey.withValues(alpha: 0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _getImageWidget(),
      ),
    );
  }

  Widget _getImageWidget() {
    // Handle URL-based images
    if (_selectedFile == null && _urlController.text.trim().isNotEmpty) {
      return Image.network(
        _urlController.text.trim(),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildIconPreview(Icons.broken_image, Colors.grey);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    // Handle file-based images
    if (_selectedFile != null) {
      if (kIsWeb) {
        // For web, use bytes
        if (_selectedFile!.bytes != null) {
          return Image.memory(
            _selectedFile!.bytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconPreview(Icons.broken_image, Colors.grey);
            },
          );
        }
      } else {
        // For mobile/desktop, use file path
        if (_selectedFile!.path != null) {
          return Image.file(
            File(_selectedFile!.path!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconPreview(Icons.broken_image, Colors.grey);
            },
          );
        }
      }
    }

    return _buildIconPreview(Icons.image, Colors.blue);
  }

  Widget _buildIconPreview(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

enum MediaType { none, image, audio, video }
