import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/services/import_service.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImportSetPage extends StatefulWidget {
  const ImportSetPage({super.key});

  @override
  State<ImportSetPage> createState() => _ImportSetPageState();
}

class _ImportSetPageState extends State<ImportSetPage> {
  final ImportService _importService = ImportService();
  final SetService _setService = SetService();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  ImportResult? _importResult;
  bool _isSaving = false;

  // ============================================================
  // ACTIONS
  // ============================================================

  /// Pick and parse a file
  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _importResult = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Required for web/parsing immediately
      );

      if (result != null) {
        final platformFile = result.files.first;
        final importData = await _importService.parseFile(platformFile);

        setState(() {
          _importResult = importData;
          _isLoading = false;
        });
      } else {
        // User canceled
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error picking/parsing file: $e');
      setState(() {
        _errorMessage = 'Failed to process file: $e';
        _isLoading = false;
      });
    }
  }

  /// Download the template file
  Future<void> _downloadTemplate() async {
    try {
      final String templateContent = await rootBundle.loadString(
        'assets/templates/set_import_template.csv',
      );
      final bytes = Uint8List.fromList(utf8.encode(templateContent));

      if (kIsWeb) {
        // Web download
        await FileSaver.instance.saveFile(
          name: 'buzz5_import_template.csv', // Include extension in name
          bytes: bytes,
          mimeType: MimeType.csv,
        );
      } else {
        // Mobile/Desktop save
        // file_saver handles the platform specifics (share sheet or file dialog)
        final path = await FileSaver.instance.saveFile(
          name: 'buzz5_import_template.csv', // Include extension in name
          bytes: bytes,
          mimeType: MimeType.csv,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template saved to $path'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // If we reach here for web, it means download started (no path returned on web usually, or it returns null/empty)
      if (kIsWeb && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template download started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error downloading template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving template: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  /// Import the valid sets to Firebase
  Future<void> _importSets() async {
    if (_importResult == null || _importResult!.validSets.isEmpty) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final createdIds = await _setService.importSets(_importResult!.validSets);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text('Import Successful'),
                content: Text(
                  'Successfully imported ${createdIds.length} sets.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(
                        context,
                        true,
                      ); // Go back to CreatePage with success signal
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing sets: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // UI BUILDERS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Sets', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24.0),
            child: _isLoading ? _buildLoading() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: ColorConstants.primaryColor),
        SizedBox(height: 16),
        Text(
          'Processing file...',
          style: TextStyle(color: ColorConstants.lightTextColor, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // 1. Show Result Preview if available
    if (_importResult != null) {
      return _buildResultPreview();
    }

    // 2. Show Upload UI (Default)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null)
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: ColorConstants.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorConstants.errorColor),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: ColorConstants.errorColor),
            ),
          ),

        // Upload Area
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : ColorConstants.cardColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorConstants.primaryColor.withValues(alpha: 0.4),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 64,
                  color: ColorConstants.primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Upload CSV',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Drag and drop or click to browse',
                  style: TextStyle(
                    color: ColorConstants.hintGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 32),

        // Template Link
        Center(
          child: TextButton.icon(
            onPressed: _downloadTemplate,
            icon: Icon(Icons.download, color: ColorConstants.lightTextColor),
            label: Text(
              'Download template file',
              style: TextStyle(
                color: ColorConstants.lightTextColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),

        SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withAlpha(20)
                    : Colors.black.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Instructions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.lightTextColor,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 8),
              _buildInstructionItem(
                'Remove the example set row before adding your own.',
              ),
              _buildInstructionItem('Do not change the column names.'),
              _buildInstructionItem('Each set must have exactly 5 questions.'),
              _buildInstructionItem(
                'Questions and answers must have some text or media.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: ColorConstants.hintGrey)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: ColorConstants.hintGrey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview() {
    final validCount = _importResult!.validSets.length;
    final skippedCount = _importResult!.skippedSets.length;
    final totalRows = _importResult!.totalRowsRead;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use a translucent background that blends with the app background
    final cardBgColor =
        isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Header - Compact
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 24, color: Colors.green),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Processed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: ColorConstants.lightTextColor,
                    ),
                  ),
                  Text(
                    'Read $totalRows questions',
                    style: TextStyle(
                      color: ColorConstants.hintGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Stats Row - Compact
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ready',
                validCount.toString(),
                Colors.green,
                Icons.task_alt,
                isDark,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Skipped',
                skippedCount.toString(),
                Colors.orange,
                Icons.warning_amber,
                isDark,
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Lists
        if (skippedCount > 0) ...[
          Text(
            'Skipped Sets',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorConstants.lightTextColor,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: skippedCount,
              itemBuilder: (context, index) {
                final skipped = _importResult!.skippedSets[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    leading: Icon(
                      Icons.error_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    title: Text(
                      skipped.name,
                      style: TextStyle(
                        color: ColorConstants.lightTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      skipped.reason,
                      style: TextStyle(
                        color: ColorConstants.hintGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Text(
            'Sets to Add',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorConstants.lightTextColor,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: validCount,
              itemBuilder: (context, index) {
                final set = _importResult!.validSets[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    leading: Icon(
                      Icons.quiz,
                      color: ColorConstants.primaryColor,
                      size: 20,
                    ),
                    title: Text(
                      set.name,
                      style: TextStyle(
                        color: ColorConstants.lightTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${set.questions.length} questions',
                      style: TextStyle(
                        color: ColorConstants.hintGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _importResult = null; // Reset
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      EdgeInsets
                          .zero, // Use zero padding with fixed size for better alignment
                  fixedSize: Size.fromHeight(56), // Enforce exact height
                  side: BorderSide(
                    color: ColorConstants.lightTextColor,
                    width: 2,
                  ),
                  foregroundColor: ColorConstants.lightTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: validCount > 0 && !_isSaving ? _importSets : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero, // Use zero padding with fixed size
                  fixedSize: Size.fromHeight(56), // Enforce exact height
                  disabledBackgroundColor: ColorConstants.primaryColor
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    _isSaving
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          'Import $validCount Sets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ColorConstants.lightTextColor,
            ),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
