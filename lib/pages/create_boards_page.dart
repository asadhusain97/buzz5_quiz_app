import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/question.dart';
import 'package:buzz5_quiz_app/providers/question_provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';

class CreateBoardsPage extends StatefulWidget {
  const CreateBoardsPage({super.key});

  @override
  State<CreateBoardsPage> createState() => _CreateBoardsPageState();
}

class _CreateBoardsPageState extends State<CreateBoardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
  String _selectedCategory = 'General Knowledge';
  Difficulty _selectedDifficulty = Difficulty.easy;
  double _selectedPoints = 10.0;
  bool _isSubmitting = false;

  // Categories list
  final List<String> _categories = [
    'General Knowledge',
    'History',
    'Science',
    'Art',
    'Sports',
    'Entertainment',
    'Literature',
    'Geography',
    'Technology',
    'Mathematics',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraftQuestions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionNameController.dispose();
    _questionTextController.dispose();
    _answerTextController.dispose();
    _promptsController.dispose();
    _explanationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadDraftQuestions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);

    if (authProvider.user != null) {
      questionProvider.loadDraftQuestionsByUser(authProvider.user!.uid);
    }
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
      _selectedCategory = 'General Knowledge';
      _selectedDifficulty = Difficulty.easy;
      _selectedPoints = 10.0;
    });
  }

  Future<void> _saveQuestion({required bool isActive}) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);

    if (authProvider.user == null) {
      _showMessage('Please sign in to create questions', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Create question
      final question = Question.create(
        questionName: _questionNameController.text.trim(),
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
        _loadDraftQuestions();
      } else {
        _showMessage('Failed to create question. Please try again.', isError: true);
      }
    } catch (e) {
      AppLogger.e('Error saving question: $e');
      _showMessage('An error occurred while saving the question.', isError: true);
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
              const SizedBox(height: 16),
              const Text('OR', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.media,
                      allowMultiple: false,
                    );

                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);

                      // Check file size (15MB limit)
                      final fileSizeInBytes = await file.length();
                      const maxSizeInBytes = 15 * 1024 * 1024; // 15MB

                      if (fileSizeInBytes > maxSizeInBytes) {
                        _showMessage('File size exceeds 15MB limit', isError: true);
                        return;
                      }

                      if (mounted) {
                        final navigator = Navigator.of(context);
                        final questionProvider = Provider.of<QuestionProvider>(context, listen: false);

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
                          _showMessage('Media uploaded successfully!', isError: false);
                        }
                      }
                    }
                  } catch (e) {
                    AppLogger.e('Error picking file: $e');
                    _showMessage('Error selecting file', isError: true);
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
              child: const Text('Add URL'),
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

  void _editQuestion(Question question) {
    // Populate form with question data
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

    // Switch to Questions tab
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("CreateBoardsPage built");

    return Scaffold(
      appBar: CustomAppBar(title: "Create Boards", showBackButton: true),
      body: AppBackground(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorConstants.darkCard
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: ColorConstants.primaryColor,
                  unselectedLabelColor: ColorConstants.hintGrey,
                  indicatorColor: ColorConstants.primaryColor,
                  tabs: const [
                    Tab(text: 'Boards'),
                    Tab(text: 'Sets'),
                    Tab(text: 'Questions'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBoardsTab(),
                    _buildSetsTab(),
                    _buildQuestionsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 80,
              color: ColorConstants.hintGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Boards',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Board creation functionality coming soon!',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 80,
              color: ColorConstants.hintGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sets',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Question set creation functionality coming soon!',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Consumer<QuestionProvider>(
      builder: (context, questionProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDraftsSection(questionProvider),
              const SizedBox(height: 24),
              _buildQuestionForm(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraftsSection(QuestionProvider questionProvider) {
    if (questionProvider.draftQuestions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.drafts_outlined,
                color: ColorConstants.hintGrey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'No drafts yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorConstants.hintGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drafts',
          style: AppTextStyles.headlineSmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? ColorConstants.lightTextColor
                : ColorConstants.primaryContainerColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: questionProvider.draftQuestions.length,
            itemBuilder: (context, index) {
              final question = questionProvider.draftQuestions[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.questionName,
                          style: AppTextStyles.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.category,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _editQuestion(question),
                            child: const Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Question',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? ColorConstants.lightTextColor
                  : ColorConstants.primaryContainerColor,
            ),
          ),
          const SizedBox(height: 20),

          // Question Name
          TextFormField(
            controller: _questionNameController,
            decoration: const InputDecoration(
              labelText: 'Question Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a question title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Question Text
          TextFormField(
            controller: _questionTextController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Question Content',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the question content';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Question Media
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMediaDialog(isForAnswer: false),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Question Media'),
                ),
              ),
              if (_questionMediaUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Answer Text
          TextFormField(
            controller: _answerTextController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Correct Answer',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the correct answer';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Answer Media
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMediaDialog(isForAnswer: true),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Answer Media'),
                ),
              ),
              if (_answerMediaUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Tags
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (comma-separated)',
              hintText: 'e.g., physics, newton, gravity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Points: ${_selectedPoints.round()}',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
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
          const SizedBox(height: 16),

          // Prompts/Hints
          TextFormField(
            controller: _promptsController,
            decoration: const InputDecoration(
              labelText: 'Answer Prompts/Hints',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Explanation
          TextFormField(
            controller: _explanationController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Explanation for Correct Answer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Difficulty
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Difficulty',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
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
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Easy'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Medium'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Hard'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _saveQuestion(isActive: false),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save as Draft'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _saveQuestion(isActive: true),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save and Activate'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}