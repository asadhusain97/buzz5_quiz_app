import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/widgets/duplicate_name_dialog.dart';
import 'package:buzz5_quiz_app/widgets/dynamic_save_button.dart';
import 'package:buzz5_quiz_app/widgets/media_upload_widget.dart';
import 'package:buzz5_quiz_app/widgets/minimal_text_field.dart';
import 'package:buzz5_quiz_app/widgets/stat_displays.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';

class NewSetPage extends StatefulWidget {
  final SetModel? existingSet;

  const NewSetPage({super.key, this.existingSet});

  @override
  State<NewSetPage> createState() => _NewSetPageState();
}

class _NewSetPageState extends State<NewSetPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _questionTabController;
  final SetService _setService = SetService();

  // Edit mode check
  bool get isEditing => widget.existingSet != null;

  // Loading state
  bool _isSaving = false;

  // Set info controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ValueNotifiers for efficient button updates (avoids full page rebuilds)
  final _nameNotifier = ValueNotifier<String>('');
  final _descriptionNotifier = ValueNotifier<String>('');
  final _completedQuestionsNotifier = ValueNotifier<int>(0);

  // Question controllers - 5 questions with incremental points
  final List<Map<String, TextEditingController>> _questionControllers = [];
  final List<Map<String, PlatformFile?>> _questionMedia = [];
  final List<Map<String, String?>> _questionMediaUrls = [];
  final List<int> _questionPoints = [10, 20, 30, 40, 50];

  // Selection state
  DifficultyLevel? _selectedDifficulty;
  final Set<PredefinedTags> _selectedTags = {};
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    _questionTabController = TabController(length: 5, vsync: this);

    // Only rebuild when tab actually changes (not during animation)
    _questionTabController.addListener(() {
      if (!_questionTabController.indexIsChanging) {
        setState(() {}); // Rebuild only on tab change completion
      }
    });

    // Initialize controllers for 5 questions
    for (int i = 0; i < 5; i++) {
      _questionControllers.add({
        'questionText': TextEditingController(),
        'answerText': TextEditingController(),
        'hint': TextEditingController(),
        'funda': TextEditingController(),
      });

      // Initialize media storage
      _questionMedia.add({'questionMedia': null, 'answerMedia': null});
      _questionMediaUrls.add({'questionMedia': null, 'answerMedia': null});
    }

    // OPTIMIZATION: Use ValueNotifiers for name/description
    // Only updates button widget, not entire page
    _nameController.addListener(() {
      _nameNotifier.value = _nameController.text;
    });
    _descriptionController.addListener(() {
      _descriptionNotifier.value = _descriptionController.text;
    });

    // Add listeners to question/answer controllers to update completion count
    for (int i = 0; i < 5; i++) {
      _questionControllers[i]['questionText']!.addListener(
        _updateCompletedCount,
      );
      _questionControllers[i]['answerText']!.addListener(_updateCompletedCount);
    }

    // Pre-populate if editing an existing set
    if (isEditing) {
      final existingSet = widget.existingSet!;
      _nameController.text = existingSet.name;
      _descriptionController.text = existingSet.description;
      _selectedDifficulty = existingSet.difficulty;
      _selectedTags.addAll(existingSet.tags);
      _isPublished = !existingSet.isPrivate;

      // Also update notifiers so buttons work immediately in edit mode
      _nameNotifier.value = existingSet.name;
      _descriptionNotifier.value = existingSet.description;

      // Pre-populate question controllers
      for (int i = 0; i < existingSet.questions.length && i < 5; i++) {
        final question = existingSet.questions[i];
        _questionControllers[i]['questionText']!.text =
            question.questionText ?? '';
        _questionControllers[i]['answerText']!.text = question.answerText ?? '';
        _questionControllers[i]['hint']!.text = question.hint ?? '';
        _questionControllers[i]['funda']!.text = question.funda ?? '';
        _questionMediaUrls[i]['questionMedia'] =
            question.questionMedia?.downloadURL;
        _questionMediaUrls[i]['answerMedia'] =
            question.answerMedia?.downloadURL;
      }

      // Update completed questions count for edit mode
      _updateCompletedCount();
    }
  }

  @override
  void dispose() {
    _questionTabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _nameNotifier.dispose();
    _descriptionNotifier.dispose();
    _completedQuestionsNotifier.dispose();

    // Dispose question controllers
    for (var controllers in _questionControllers) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  /// Updates the completed questions count notifier
  void _updateCompletedCount() {
    int count = 0;
    for (int i = 0; i < 5; i++) {
      if (_isQuestionComplete(i)) {
        count++;
      }
    }
    _completedQuestionsNotifier.value = count;
  }

  bool _isQuestionComplete(int index) {
    final controllers = _questionControllers[index];
    final media = _questionMedia[index];
    final mediaUrls = _questionMediaUrls[index];
    final hasQuestion =
        controllers['questionText']!.text.trim().isNotEmpty ||
        media['questionMedia'] != null ||
        (mediaUrls['questionMedia'] != null &&
            mediaUrls['questionMedia']!.trim().isNotEmpty);
    final hasAnswer =
        controllers['answerText']!.text.trim().isNotEmpty ||
        media['answerMedia'] != null ||
        (mediaUrls['answerMedia'] != null &&
            mediaUrls['answerMedia']!.trim().isNotEmpty);
    return hasQuestion && hasAnswer;
  }

  Future<void> _saveAsDraft() async {
    await _saveSet(isDraft: true);
  }

  Future<void> _save() async {
    await _saveSet(isDraft: false);
  }

  Future<void> _saveSet({required bool isDraft}) async {
    if (_isSaving) return;

    try {
      setState(() {
        _isSaving = true;
      });

      AppLogger.i('Starting to save set (isDraft: $isDraft)');

      // Validate that the name doesn't already exist
      final String setName = _nameController.text.trim();
      final bool nameExists = await _setService.checkSetNameExists(
        setName,
        excludeSetId: isEditing ? widget.existingSet!.id : null,
      );

      if (nameExists) {
        // Name already exists, show error and return
        if (!mounted) return;

        // Reset saving state
        setState(() {
          _isSaving = false;
        });

        // Show error dialog using shared utility
        await showDuplicateNameDialog(
          context: context,
          itemType: 'set',
          name: setName,
        );
        return;
      }

      // Prepare question data
      final List<Map<String, dynamic>> questionData = [];

      for (int i = 0; i < 5; i++) {
        final controllers = _questionControllers[i];
        final media = _questionMedia[i];
        final mediaUrls = _questionMediaUrls[i];

        questionData.add({
          'questionText':
              controllers['questionText']!.text.trim().isNotEmpty
                  ? controllers['questionText']!.text.trim()
                  : null,
          'questionMediaFile': media['questionMedia'],
          'questionMediaUrl': mediaUrls['questionMedia'],
          'answerText':
              controllers['answerText']!.text.trim().isNotEmpty
                  ? controllers['answerText']!.text.trim()
                  : null,
          'answerMediaFile': media['answerMedia'],
          'answerMediaUrl': mediaUrls['answerMedia'],
          'points': _questionPoints[i],
          'hint':
              controllers['hint']!.text.trim().isNotEmpty
                  ? controllers['hint']!.text.trim()
                  : null,
          'funda':
              controllers['funda']!.text.trim().isNotEmpty
                  ? controllers['funda']!.text.trim()
                  : null,
        });
      }

      // Create or update the set
      String setId;
      if (isEditing) {
        setId = widget.existingSet!.id;
        await _setService.updateSet(
          setId: setId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _selectedTags.toList(),
          difficulty: _selectedDifficulty,
          isPrivate: !_isPublished,
          questionData: questionData,
        );
        AppLogger.i('Set updated successfully with ID: $setId');
      } else {
        setId = await _setService.createSet(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _selectedTags.toList(),
          difficulty: _selectedDifficulty,
          isPrivate: !_isPublished,
          questionData: questionData,
          isDraft: isDraft,
        );
        AppLogger.i('Set created successfully with ID: $setId');
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Set updated successfully!'
                : isDraft
                ? 'Set saved as draft successfully!'
                : 'Set saved successfully!',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back after a short delay, returning true to indicate success
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      AppLogger.e('Error saving set: $e', error: e, stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving set: ${e.toString()}'),
          backgroundColor: ColorConstants.errorColor,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showTagsDropdown(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<void>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: BoxConstraints(
        maxHeight: 400,
        minWidth: button.size.width,
        maxWidth: button.size.width,
      ),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return SizedBox(
                width: button.size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Tags',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_selectedTags.length}/5',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  _selectedTags.length >= 5
                                      ? ColorConstants.errorColor
                                      : ColorConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Container(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children:
                              PredefinedTags.values.map((tag) {
                                final isSelected = _selectedTags.contains(tag);
                                final isDisabled =
                                    !isSelected && _selectedTags.length >= 5;

                                return InkWell(
                                  onTap:
                                      isDisabled
                                          ? null
                                          : () {
                                            setMenuState(() {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedTags.remove(tag);
                                                } else {
                                                  if (_selectedTags.length <
                                                      5) {
                                                    _selectedTags.add(tag);
                                                  }
                                                }
                                              });
                                            });
                                          },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    color:
                                        isDisabled
                                            ? ColorConstants.hintGrey
                                                .withValues(alpha: 0.05)
                                            : null,
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged:
                                                isDisabled
                                                    ? null
                                                    : (value) {
                                                      setMenuState(() {
                                                        setState(() {
                                                          if (value == true) {
                                                            if (_selectedTags
                                                                    .length <
                                                                5) {
                                                              _selectedTags.add(
                                                                tag,
                                                              );
                                                            }
                                                          } else {
                                                            _selectedTags
                                                                .remove(tag);
                                                          }
                                                        });
                                                      });
                                                    },
                                            activeColor:
                                                ColorConstants.primaryColor,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            tag.displayName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  isDisabled
                                                      ? ColorConstants.hintGrey
                                                          .withValues(
                                                            alpha: 0.4,
                                                          )
                                                      : isSelected
                                                      ? ColorConstants
                                                          .primaryColor
                                                      : ColorConstants
                                                          .lightTextColor,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Set' : 'Create New Set',
          style: AppTextStyles.titleBig,
        ),
        backgroundColor: ColorConstants.primaryContainerColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          iconSize: 30,
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppBackground(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Set Information Section (Top)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row with Title and Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEditing ? 'Edit Set' : 'Create a Set',
                                style: AppTextStyles.titleBig.copyWith(
                                  color: ColorConstants.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              // Dynamic save button - switches between Draft/Save based on completion
                              DynamicSaveButton(
                                nameNotifier: _nameNotifier,
                                descriptionNotifier: _descriptionNotifier,
                                completionCountNotifier:
                                    _completedQuestionsNotifier,
                                requiredCount: 5,
                                onSaveDraft: _saveAsDraft,
                                onSave: _save,
                                isSaving: _isSaving,
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Row 1: Name and Description (same height)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MinimalTextField(
                                  controller: _nameController,
                                  label: 'Name *',
                                  hint: 'Enter set name',
                                  maxLength: 30,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: MinimalTextField(
                                  controller: _descriptionController,
                                  label: 'Description *',
                                  hint:
                                      'Explain how this set works and its theme',
                                  maxLength: 150,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Row with Tags, Difficulty, Downloads, and Rating
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tags
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tags',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: ColorConstants.lightTextColor
                                            .withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        return SizedBox(
                                          width: 180, // Adjusted width
                                          child: OutlinedButton(
                                            onPressed:
                                                () =>
                                                    _showTagsDropdown(context),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  ColorConstants.lightTextColor,
                                              side: BorderSide(
                                                color: ColorConstants
                                                    .lightTextColor
                                                    .withValues(alpha: 0.3),
                                                width: 1,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                              minimumSize: Size(0, 44),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.label_outline,
                                                  size: 18,
                                                  color:
                                                      ColorConstants.hintGrey,
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'Select Tags',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color:
                                                          ColorConstants
                                                              .lightTextColor,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (_selectedTags
                                                    .isNotEmpty) ...[
                                                  SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          ColorConstants
                                                              .primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${_selectedTags.length}',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                                SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 24,
                                                  color:
                                                      ColorConstants.hintGrey,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                SizedBox(width: 18),

                                // Difficulty
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Difficulty',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: ColorConstants.lightTextColor
                                            .withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    SizedBox(
                                      height: 38,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          _buildDifficultyChip(
                                            'Easy',
                                            DifficultyLevel.easy,
                                            Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          _buildDifficultyChip(
                                            'Med',
                                            DifficultyLevel.medium,
                                            Colors.orange,
                                          ),
                                          SizedBox(width: 4),
                                          _buildDifficultyChip(
                                            'Hard',
                                            DifficultyLevel.hard,
                                            Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(width: 24),

                                // Publish
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Publish',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: ColorConstants.lightTextColor
                                            .withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Transform.translate(
                                          offset: Offset(-4, 0),
                                          child: Transform.scale(
                                            scale: 0.8,
                                            alignment: Alignment.centerLeft,
                                            child: Switch(
                                              value: _isPublished,
                                              onChanged: (widget.existingSet
                                                          ?.isDownloadedFromMarketplace ??
                                                      false)
                                                  ? null // Disable switch for downloaded sets
                                                  : (value) {
                                                      setState(() {
                                                        _isPublished = value;
                                                      });
                                                    },
                                              activeThumbColor:
                                                  ColorConstants.primaryColor,
                                              activeTrackColor: ColorConstants
                                                  .primaryColor
                                                  .withValues(alpha: 0.5),
                                              inactiveThumbColor: (widget
                                                          .existingSet
                                                          ?.isDownloadedFromMarketplace ??
                                                      false)
                                                  ? ColorConstants.hintGrey
                                                      .withValues(alpha: 0.3)
                                                  : null,
                                              inactiveTrackColor: (widget
                                                          .existingSet
                                                          ?.isDownloadedFromMarketplace ??
                                                      false)
                                                  ? ColorConstants.hintGrey
                                                      .withValues(alpha: 0.2)
                                                  : null,
                                              // THIS CONTROLS THE MARGIN AROUND THE TOGGLE
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        ),
                                        Transform.translate(
                                          offset: Offset(3, -5),
                                          child: Text(
                                            _isPublished ? 'Public' : 'Private',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                              height: 1.0,
                                              color:
                                                  _isPublished
                                                      ? ColorConstants
                                                          .primaryColor
                                                      : ColorConstants
                                                          .lightTextColor
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                            ),
                                          ),
                                        ),
                                        // Helper text for downloaded sets
                                        if (widget.existingSet
                                                ?.isDownloadedFromMarketplace ??
                                            false) ...[
                                          SizedBox(height: 4),
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              'Downloaded sets cannot be published',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: ColorConstants.hintGrey
                                                    .withValues(alpha: 0.7),
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(width: 24),

                                // Downloads and Rating - Display only (read-only)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 0),
                                  child: SizedBox(
                                    height: 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Downloads
                                        DownloadDisplay(
                                          downloads: 0,
                                          iconSize: 18,
                                          fontSize: 13,
                                        ),
                                        SizedBox(width: 20),
                                        // Rating
                                        RatingDisplay(
                                          rating: 0.0,
                                          iconSize: 18,
                                          fontSize: 13,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Questions Section (Bottom)
                    Column(
                      children: [
                        // Question Tabs - Equally spaced
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: TabBar(
                            controller: _questionTabController,
                            isScrollable: false, // Make tabs spread equally
                            labelColor: ColorConstants.lightTextColor,
                            unselectedLabelColor: ColorConstants.lightTextColor
                                .withValues(alpha: 0.5),
                            indicatorColor: ColorConstants.primaryColor,
                            indicatorWeight: 3,
                            labelStyle: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            tabs: List.generate(5, (index) {
                              final isComplete = _isQuestionComplete(index);
                              return Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Q${index + 1} (${_questionPoints[index]} points)',
                                    ),
                                    if (isComplete) ...[
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),

                        SizedBox(height: 8),

                        // Tab Content
                        SizedBox(
                          height: 500,
                          child: TabBarView(
                            controller: _questionTabController,
                            children: List.generate(
                              5,
                              (index) => _CachedQuestionForm(
                                key: ValueKey('question_$index'),
                                controllers: _questionControllers[index],
                                media: _questionMedia[index],
                                mediaUrls: _questionMediaUrls[index],
                                points: _questionPoints[index],
                                onMediaChanged: (
                                  String key,
                                  PlatformFile? file,
                                ) {
                                  // Update media and rebuild for tab completion indicator
                                  _questionMedia[index][key] = file;
                                  _updateCompletedCount(); // Update button state
                                  setState(
                                    () {},
                                  ); // Only rebuilds tab indicators
                                },
                                onMediaUrlChanged: (String key, String? url) {
                                  // Update URL and rebuild for tab completion indicator
                                  _questionMediaUrls[index][key] = url;
                                  _updateCompletedCount(); // Update button state
                                  setState(
                                    () {},
                                  ); // Only rebuilds tab indicators
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(
    String label,
    DifficultyLevel difficulty,
    Color color,
  ) {
    final isSelected = _selectedDifficulty == difficulty;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDifficulty = isSelected ? null : difficulty;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color:
                isSelected
                    ? color
                    : ColorConstants.hintGrey.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : ColorConstants.hintGrey,
          ),
        ),
      ),
    );
  }
}

// Cached Question Form Widget to prevent rebuilds during tab switches
class _CachedQuestionForm extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, PlatformFile?> media;
  final Map<String, String?> mediaUrls;
  final int points;
  final Function(String key, PlatformFile? file) onMediaChanged;
  final Function(String key, String? url) onMediaUrlChanged;

  const _CachedQuestionForm({
    super.key,
    required this.controllers,
    required this.media,
    required this.mediaUrls,
    required this.points,
    required this.onMediaChanged,
    required this.onMediaUrlChanged,
  });

  @override
  State<_CachedQuestionForm> createState() => _CachedQuestionFormState();
}

class _CachedQuestionFormState extends State<_CachedQuestionForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep the widget alive

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two Column Layout for Question and Answer
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Column
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 300, maxWidth: 350),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question *',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: ColorConstants.lightTextColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        MinimalTextField(
                          controller: widget.controllers['questionText']!,
                          label: 'Text',
                          hint: 'Enter question text',
                          maxLines: 3,
                          isSmall: true,
                        ),
                        SizedBox(height: 12),
                        MediaUploadWidget(
                          label: 'Media (Image/Audio/Video)',
                          initialFile: widget.media['questionMedia'],
                          initialUrl: widget.mediaUrls['questionMedia'],
                          onFileSelected: (file) {
                            widget.onMediaChanged('questionMedia', file);
                          },
                          onUrlChanged: (url) {
                            widget.onMediaUrlChanged('questionMedia', url);
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 24),

                  // Answer Column
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 300, maxWidth: 350),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answer *',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: ColorConstants.lightTextColor,
                          ),
                        ),
                        SizedBox(height: 12),
                        MinimalTextField(
                          controller: widget.controllers['answerText']!,
                          label: 'Text',
                          hint: 'Enter answer text',
                          maxLines: 3,
                          isSmall: true,
                        ),
                        SizedBox(height: 12),
                        MediaUploadWidget(
                          label: 'Media (Image/Audio/Video)',
                          initialFile: widget.media['answerMedia'],
                          initialUrl: widget.mediaUrls['answerMedia'],
                          onFileSelected: (file) {
                            widget.onMediaChanged('answerMedia', file);
                          },
                          onUrlChanged: (url) {
                            widget.onMediaUrlChanged('answerMedia', url);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Row with Hint and Points
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points Field (smaller width, disabled)
                  SizedBox(
                    width: 75,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Points',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: ColorConstants.lightTextColor.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 4),
                        TextFormField(
                          initialValue: widget.points.toString(),
                          enabled: false, // Disabled for now
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Points',
                            hintStyle: TextStyle(
                              color: ColorConstants.lightTextColor.withValues(
                                alpha: 0.4,
                              ),
                              fontSize: 12,
                            ),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: ColorConstants.lightTextColor.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: ColorConstants.lightTextColor.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: ColorConstants.hintGrey.withValues(
                              alpha: 0.1,
                            ),
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.lightTextColor.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 50),

                  // Hint Field (takes most space)
                  SizedBox(
                    width: 300,
                    child: MinimalTextField(
                      controller: widget.controllers['hint']!,
                      label: 'Hint (Optional)',
                      hint: 'Enter a hint to help players',
                      maxLines: 2,
                      isSmall: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Full Width - Funda/Explanation
          MinimalTextField(
            controller: widget.controllers['funda']!,
            label: 'Funda (Optional)',
            hint: 'Explain the concept or provide context or sources',
            maxLines: 3,
            isSmall: true,
          ),
        ],
      ),
    );
  }
}
