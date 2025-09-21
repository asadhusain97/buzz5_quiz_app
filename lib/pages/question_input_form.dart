import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/question.dart';
import 'package:buzz5_quiz_app/providers/question_provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';

class QuestionInputForm extends StatefulWidget {
  final Question? existingQuestion;

  const QuestionInputForm({super.key, this.existingQuestion});

  @override
  State<QuestionInputForm> createState() => _QuestionInputFormState();
}

class _QuestionInputFormState extends State<QuestionInputForm> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _questionNameController = TextEditingController();
  final _questionTextController = TextEditingController();
  final _answerTextController = TextEditingController();
  final _promptsController = TextEditingController();
  final _explanationController = TextEditingController();
  final _tagsController = TextEditingController();

  // Form state
  String _questionMediaUrl = '';
  String _answerMediaUrl = '';
  String _selectedCategory = '';
  Difficulty _selectedDifficulty = Difficulty.easy;
  double _selectedPoints = 10.0;
  bool _isSubmitting = false;

  // Categories list
  final List<String> _categories = [
    '',
    'General',
    'Pop Culture',
    'History',
    'Science',
    'Art',
    'Sports',
    'Entertainment',
    'Literature',
    'Geography',
    'Technology',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingQuestion != null) {
      _populateForm(widget.existingQuestion!);
    }
  }

  @override
  void dispose() {
    _questionNameController.dispose();
    _questionTextController.dispose();
    _answerTextController.dispose();
    _promptsController.dispose();
    _explanationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _populateForm(Question question) {
    _questionNameController.text = question.questionName;
    _questionTextController.text = question.questionText;
    _answerTextController.text = question.answerText;
    _promptsController.text = question.prompts;
    _explanationController.text = question.explanation;
    _tagsController.text = question.tags.join(', ');

    setState(() {
      _questionMediaUrl = question.questionMedia;
      _answerMediaUrl = question.answerMedia;
      _selectedCategory = question.category;
      _selectedDifficulty = question.difficulty;
      _selectedPoints = question.points.toDouble();
    });
  }

  void _clearForm() {
    _questionNameController.clear();
    _questionTextController.clear();
    _answerTextController.clear();
    _promptsController.clear();
    _explanationController.clear();
    _tagsController.clear();

    setState(() {
      _questionMediaUrl = '';
      _answerMediaUrl = '';
      _selectedCategory = '';
      _selectedDifficulty = Difficulty.easy;
      _selectedPoints = 10.0;
    });
  }

  Future<void> _saveQuestion({required bool isActive}) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final questionProvider = Provider.of<QuestionProvider>(
      context,
      listen: false,
    );

    if (authProvider.user == null) {
      _showMessage('Please sign in to create questions', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse tags
      final tags =
          _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList();

      // Create question
      final question = Question.create(
        questionName: _questionTextController.text
            .trim()
            .split(' ')
            .take(5)
            .join(' '), // Use first 5 words as title
        questionText: _questionTextController.text.trim(),
        questionMedia: _questionMediaUrl,
        answerText: _answerTextController.text.trim(),
        answerMedia: _answerMediaUrl,
        createdBy: authProvider.user!.uid,
        category: _selectedCategory,
        tags: tags,
        points: _selectedPoints.round(),
        prompts: _promptsController.text.trim(),
        explanation: _explanationController.text.trim(),
        isActive: isActive,
        difficulty: _selectedDifficulty,
      );

      final questionId = await questionProvider.createQuestion(question);

      if (questionId != null) {
        _showMessage(
          isActive
              ? 'Question created and activated successfully!'
              : 'Question saved as draft successfully!',
          isError: false,
        );
        _clearForm();
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        _showMessage(
          'Failed to create question. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      AppLogger.e('Error saving question: $e');
      _showMessage(
        'An error occurred while saving the question.',
        isError: true,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showMediaDialog({required bool isForAnswer}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final mediaUrlController = TextEditingController();

        return AlertDialog(
          title: Text('Add ${isForAnswer ? 'Answer' : 'Question'} Media'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: mediaUrlController,
                decoration: const InputDecoration(
                  labelText: 'Media URL',
                  hintText: 'Paste media URL here',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppConstants.defaultSpacing),
              const Text('OR', textAlign: TextAlign.center),
              const SizedBox(height: AppConstants.defaultSpacing),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final navigator = Navigator.of(context);
                    final questionProvider = Provider.of<QuestionProvider>(
                      context,
                      listen: false,
                    );

                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(type: FileType.media, allowMultiple: false);

                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);

                      // Check file size (15MB limit)
                      final fileSizeInBytes = await file.length();
                      const maxSizeInBytes = 15 * 1024 * 1024; // 15MB

                      if (fileSizeInBytes > maxSizeInBytes) {
                        if (mounted) {
                          _showMessage(
                            'File size exceeds 15MB limit',
                            isError: true,
                          );
                        }
                        return;
                      }

                      if (mounted) {
                        navigator.pop();

                        // Upload file
                        final mediaUrl = await questionProvider.uploadMedia(
                          file,
                          'temp_${DateTime.now().millisecondsSinceEpoch}',
                          isAnswer: isForAnswer,
                        );

                        if (mounted && mediaUrl != null) {
                          setState(() {
                            if (isForAnswer) {
                              _answerMediaUrl = mediaUrl;
                            } else {
                              _questionMediaUrl = mediaUrl;
                            }
                          });
                          _showMessage(
                            'Media uploaded successfully!',
                            isError: false,
                          );
                        }
                      }
                    }
                  } catch (e) {
                    AppLogger.e('Error picking file: $e');
                    if (mounted) {
                      _showMessage('Error selecting file', isError: true);
                    }
                  }
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Upload from Device'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Upload'),
              onPressed: () {
                if (mediaUrlController.text.isNotEmpty) {
                  setState(() {
                    if (isForAnswer) {
                      _answerMediaUrl = mediaUrlController.text.trim();
                    } else {
                      _questionMediaUrl = mediaUrlController.text.trim();
                    }
                  });
                  _showMessage('Media URL added successfully!', isError: false);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to increment points
  void _incrementPoints() {
    setState(() {
      if (_selectedPoints < 50) {
        _selectedPoints += 5;
      }
    });
  }

  // Helper method to decrement points
  void _decrementPoints() {
    setState(() {
      if (_selectedPoints > 5) {
        _selectedPoints -= 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:
            widget.existingQuestion != null
                ? "Edit Question"
                : "Create Question",
        showBackButton: true,
      ),
      body: AppBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use single column layout on smaller screens
            if (constraints.maxWidth < 600) {
              return _buildMobileLayout();
            }
            // Use two-panel layout on larger screens
            return _buildDesktopLayout();
          },
        ),
      ),
    );
  }

  // Single column layout for mobile/smaller screens
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: AppConstants.defaultPadding,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingQuestion != null
                  ? 'Edit Question'
                  : 'Create New Question',
              style: AppTextStyles.headlineSmall.copyWith(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? ColorConstants.lightTextColor
                        : ColorConstants.primaryContainerColor,
              ),
            ),
            const SizedBox(height: AppConstants.largeSpacing),
            ..._buildAllFormFields(),
          ],
        ),
      ),
    );
  }

  // Two-panel layout for desktop/larger screens
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200), // Limit max width
          child: Padding(
            padding: AppConstants.defaultPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.existingQuestion != null
                        ? 'Edit Question'
                        : 'Create New Question',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? ColorConstants.lightTextColor
                              : ColorConstants.primaryContainerColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.extraLargeSpacing),

                  // Two-panel layout with 60/40 split
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT PANEL (60% width) - Question & Answer
                      Expanded(flex: 6, child: _buildLeftPanel()),
                      const SizedBox(width: AppConstants.mediumSpacing),

                      // RIGHT PANEL (40% width) - Details & Configuration
                      Expanded(flex: 4, child: _buildRightPanel()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Left panel: Question & Answer (60% width)
  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Section (removed question title field)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text (takes most space)
            Expanded(
              child: TextFormField(
                controller: _questionTextController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Question Text',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the question text';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppConstants.defaultSpacing),

            // Question Media Button (aligned right)
            Column(
              children: [
                const SizedBox(height: AppConstants.smallSpacing),
                OutlinedButton.icon(
                  onPressed: () => _showMediaDialog(isForAnswer: false),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Upload Media'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(140, 40),
                  ),
                ),
                if (_questionMediaUrl.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.smallSpacing),
                  const Icon(
                    Icons.check_circle,
                    color: ColorConstants.success,
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppConstants.mediumSpacing),

        // Answer Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Answer Text (smaller height than question)
            Expanded(
              child: TextFormField(
                controller: _answerTextController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Answer Text',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the answer text';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppConstants.defaultSpacing),

            // Answer Media Button (aligned right)
            Column(
              children: [
                const SizedBox(height: AppConstants.smallSpacing),
                OutlinedButton.icon(
                  onPressed: () => _showMediaDialog(isForAnswer: true),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Upload Media'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(140, 40),
                  ),
                ),
                if (_answerMediaUrl.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.smallSpacing),
                  const Icon(
                    Icons.check_circle,
                    color: ColorConstants.success,
                    size: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: AppConstants.extraLargeSpacing),

        // Action Buttons (right-aligned)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed:
                  _isSubmitting ? null : () => _saveQuestion(isActive: false),
              style: OutlinedButton.styleFrom(minimumSize: const Size(140, 40)),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save as Draft'),
            ),
            const SizedBox(width: AppConstants.defaultSpacing),
            ElevatedButton(
              onPressed:
                  _isSubmitting ? null : () => _saveQuestion(isActive: true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  // Right panel: Details & Configuration (40% width)
  Widget _buildRightPanel() {
    return Container(
      padding: AppConstants.defaultPadding,
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? ColorConstants.darkCard.withValues(alpha: 0.3)
                : ColorConstants.greyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category (aligned with question text top)
          DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select Category'),
            items:
                _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value ?? '';
              });
            },
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Tags
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma-separated)',
              hintText: 'e.g., physics, newton, gravity',
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Points and Difficulty Row
          Row(
            children: [
              // Points Input (30% of row - smaller)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Points', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppConstants.smallSpacing),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: ColorConstants.hintGrey),
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: _decrementPoints,
                            icon: const Icon(Icons.remove, size: 16),
                            tooltip: 'Decrease points',
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          Text(
                            '${_selectedPoints.round()}',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: ColorConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _incrementPoints,
                            icon: const Icon(Icons.add, size: 16),
                            tooltip: 'Increase points',
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.defaultSpacing),

              // Difficulty (70% of row - larger)
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Difficulty', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppConstants.smallSpacing),
                    ToggleButtons(
                      constraints: const BoxConstraints(
                        minWidth: 55,
                        minHeight: 48,
                      ),
                      isSelected: [
                        _selectedDifficulty == Difficulty.easy,
                        _selectedDifficulty == Difficulty.medium,
                        _selectedDifficulty == Difficulty.hard,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _selectedDifficulty = Difficulty.values[index];
                        });
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Easy', style: AppTextStyles.labelMedium),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Medium',
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Hard', style: AppTextStyles.labelMedium),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Answer Hint
          TextFormField(
            controller: _promptsController,
            decoration: const InputDecoration(
              labelText: 'Hint',
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Funda (previously Explanation) - aligned with answer bottom
          TextFormField(
            controller: _explanationController,
            maxLines: 1,
            decoration: const InputDecoration(
              labelText: 'Funda',
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build all form fields for mobile layout
  List<Widget> _buildAllFormFields() {
    return [
      // Question Text (no title field for mobile)
      TextFormField(
        controller: _questionTextController,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Question Text',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the question text';
          }
          return null;
        },
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Question Media
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showMediaDialog(isForAnswer: false),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Question Media'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                ),
              ),
            ),
          ),
          if (_questionMediaUrl.isNotEmpty) ...[
            const SizedBox(width: AppConstants.smallSpacing),
            const Icon(
              Icons.check_circle,
              color: ColorConstants.success,
              size: 20,
            ),
          ],
        ],
      ),
      const SizedBox(height: AppConstants.largeSpacing),

      // Answer Text
      TextFormField(
        controller: _answerTextController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Answer Text',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the answer text';
          }
          return null;
        },
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Answer Media
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showMediaDialog(isForAnswer: true),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Answer Media'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                ),
              ),
            ),
          ),
          if (_answerMediaUrl.isNotEmpty) ...[
            const SizedBox(width: AppConstants.smallSpacing),
            const Icon(
              Icons.check_circle,
              color: ColorConstants.success,
              size: 20,
            ),
          ],
        ],
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Category
      DropdownButtonFormField<String>(
        value: _selectedCategory.isEmpty ? null : _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select Category'),
        items:
            _categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value ?? '';
          });
        },
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Tags
      TextFormField(
        controller: _tagsController,
        decoration: const InputDecoration(
          labelText: 'Tags (comma-separated)',
          hintText: 'e.g., physics, newton, gravity',
          border: UnderlineInputBorder(),
        ),
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Points
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Points: ${_selectedPoints.round()}',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Slider(
            value: _selectedPoints,
            min: 5,
            max: 50,
            divisions: 9,
            label: _selectedPoints.round().toString(),
            onChanged: (value) {
              setState(() {
                _selectedPoints = value;
              });
            },
          ),
        ],
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Prompts/Hints
      TextFormField(
        controller: _promptsController,
        decoration: const InputDecoration(
          labelText: 'Hint',
          border: UnderlineInputBorder(),
        ),
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Funda (Explanation)
      TextFormField(
        controller: _explanationController,
        maxLines: 1,
        decoration: const InputDecoration(
          labelText: 'Funda',
          border: UnderlineInputBorder(),
        ),
      ),
      const SizedBox(height: AppConstants.defaultSpacing),

      // Difficulty
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Difficulty', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppConstants.smallSpacing),
          ToggleButtons(
            isSelected: [
              _selectedDifficulty == Difficulty.easy,
              _selectedDifficulty == Difficulty.medium,
              _selectedDifficulty == Difficulty.hard,
            ],
            onPressed: (index) {
              setState(() {
                _selectedDifficulty = Difficulty.values[index];
              });
            },
            children: const [
              Padding(
                padding: AppConstants.defaultHorizontalPadding,
                child: Text('Easy'),
              ),
              Padding(
                padding: AppConstants.defaultHorizontalPadding,
                child: Text('Medium'),
              ),
              Padding(
                padding: AppConstants.defaultHorizontalPadding,
                child: Text('Hard'),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppConstants.pageSpacing),

      // Action Buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed:
                  _isSubmitting ? null : () => _saveQuestion(isActive: false),
              style: OutlinedButton.styleFrom(minimumSize: const Size(140, 40)),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save as Draft'),
            ),
          ),
          const SizedBox(width: AppConstants.defaultSpacing),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isSubmitting ? null : () => _saveQuestion(isActive: true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Save'),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppConstants.pageSpacing),
    ];
  }
}
