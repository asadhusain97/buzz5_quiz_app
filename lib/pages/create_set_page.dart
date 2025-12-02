import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/widgets/media_upload_widget.dart';

class NewSetPage extends StatefulWidget {
  const NewSetPage({super.key});

  @override
  State<NewSetPage> createState() => _NewSetPageState();
}

class _NewSetPageState extends State<NewSetPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _questionTabController;

  // Set info controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ValueNotifiers for efficient button updates (avoids full page rebuilds)
  final _nameNotifier = ValueNotifier<String>('');
  final _descriptionNotifier = ValueNotifier<String>('');

  // Question controllers - 5 questions with incremental points
  final List<Map<String, TextEditingController>> _questionControllers = [];
  final List<Map<String, PlatformFile?>> _questionMedia = [];
  final List<Map<String, String?>> _questionMediaUrls = [];
  final List<int> _questionPoints = [10, 20, 30, 40, 50];

  // Selection state
  DifficultyLevel? _selectedDifficulty;
  final Set<PredefinedTags> _selectedTags = {};

  // Display properties
  final int downloads = 0;
  final double rating = 0.0;

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

    // OPTIMIZATION: Question controllers only trigger rebuild for tab indicators
    // We don't need real-time updates while typing in questions
    // Tab completion will be checked on tab change instead
  }

  @override
  void dispose() {
    _questionTabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _nameNotifier.dispose();
    _descriptionNotifier.dispose();

    // Dispose question controllers
    for (var controllers in _questionControllers) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }

    super.dispose();
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

  void _saveAsDraft() {
    // TODO: Implement save as draft functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saving as draft...'),
        backgroundColor: ColorConstants.primaryColor,
      ),
    );
  }

  void _save() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saving set...'), backgroundColor: Colors.green),
    );
  }

  String _formatTagName(PredefinedTags tag) {
    final name = tag.toString().split('.').last;
    final specialCases = {
      'foodAndDrinks': 'Food & Drinks',
      'popCulture': 'Pop Culture',
      'videoGames': 'Video Games',
      'us': 'US',
    };
    if (specialCases.containsKey(name)) {
      return specialCases[name]!;
    }
    return name[0].toUpperCase() + name.substring(1);
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
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                                if (_selectedTags.length < 5) {
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
                                          ? ColorConstants.hintGrey.withValues(
                                            alpha: 0.05,
                                          )
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
                                                          _selectedTags.remove(
                                                            tag,
                                                          );
                                                        }
                                                      });
                                                    });
                                                  },
                                          activeColor:
                                              ColorConstants.primaryColor,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _formatTagName(tag),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDisabled
                                                    ? ColorConstants.hintGrey
                                                        .withValues(alpha: 0.4)
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
        title: Text('Create New Set', style: AppTextStyles.titleBig),
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
                                'Create a Set',
                                style: AppTextStyles.titleBig.copyWith(
                                  color: ColorConstants.lightTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              // OPTIMIZED: Buttons only rebuild when name/description change
                              _ActionButtons(
                                nameNotifier: _nameNotifier,
                                descriptionNotifier: _descriptionNotifier,
                                questionControllers: _questionControllers,
                                questionMedia: _questionMedia,
                                questionMediaUrls: _questionMediaUrls,
                                onSaveDraft: _saveAsDraft,
                                onSave: _save,
                              ),
                            ],
                          ),
                          SizedBox(height: 24),

                          // Row 1: Name and Description (same height)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildMinimalTextField(
                                  controller: _nameController,
                                  label: 'Name *',
                                  hint: 'Enter set name',
                                  maxLength: 30,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildMinimalTextField(
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
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                                    overflow: TextOverflow.ellipsis,
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

                                // Downloads and Rating - Aligned with difficulty buttons
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
                                        Icon(
                                          Icons.download,
                                          size: 22,
                                          color: ColorConstants.lightTextColor
                                              .withValues(alpha: 0.7),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '$downloads',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: ColorConstants
                                                    .lightTextColor
                                                    .withValues(alpha: 0.7),
                                                fontSize: 15,
                                              ),
                                        ),
                                        SizedBox(width: 20),
                                        // Rating
                                        Icon(
                                          Icons.star,
                                          size: 22,
                                          color: Colors.amber,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          '${rating.toStringAsFixed(1)}/5',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: ColorConstants
                                                    .lightTextColor
                                                    .withValues(alpha: 0.7),
                                                fontSize: 15,
                                              ),
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
                                buildMinimalTextField: _buildMinimalTextField,
                                points: _questionPoints[index],
                                onMediaChanged: (
                                  String key,
                                  PlatformFile? file,
                                ) {
                                  // Update media and rebuild for tab completion indicator
                                  _questionMedia[index][key] = file;
                                  setState(
                                    () {},
                                  ); // Only rebuilds tab indicators
                                },
                                onMediaUrlChanged: (String key, String? url) {
                                  // Update URL and rebuild for tab completion indicator
                                  _questionMediaUrls[index][key] = url;
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

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    bool isSmall = false,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: ColorConstants.lightTextColor.withValues(alpha: 0.7),
            fontSize: isSmall ? 12 : 14,
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ColorConstants.lightTextColor.withValues(alpha: 0.4),
              fontSize: isSmall ? 10 : 16,
            ),
            prefixText: prefixText,
            prefixStyle: AppTextStyles.bodySmall,
            counterText: '', // Hide character counter
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmall ? 8 : 14,
              vertical: isSmall ? 8 : (maxLines > 1 ? 14 : 16),
            ),
            isDense: true,
            filled: false,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: ColorConstants.lightTextColor,
            fontSize: isSmall ? 11 : 16,
          ),
        ),
      ],
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

// OPTIMIZATION: Action buttons as separate widget
// Uses ValueListenableBuilder to rebuild ONLY buttons, not entire page
class _ActionButtons extends StatelessWidget {
  final ValueNotifier<String> nameNotifier;
  final ValueNotifier<String> descriptionNotifier;
  final List<Map<String, TextEditingController>> questionControllers;
  final List<Map<String, PlatformFile?>> questionMedia;
  final List<Map<String, String?>> questionMediaUrls;
  final VoidCallback onSaveDraft;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.nameNotifier,
    required this.descriptionNotifier,
    required this.questionControllers,
    required this.questionMedia,
    required this.questionMediaUrls,
    required this.onSaveDraft,
    required this.onSave,
  });

  bool _isQuestionComplete(int index) {
    final controllers = questionControllers[index];
    final media = questionMedia[index];
    final mediaUrls = questionMediaUrls[index];
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

  bool _canSaveAsDraft(String name, String description) {
    return name.trim().isNotEmpty && description.trim().isNotEmpty;
  }

  bool _canSave(String name, String description) {
    if (!_canSaveAsDraft(name, description)) return false;

    for (int i = 0; i < 5; i++) {
      if (!_isQuestionComplete(i)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: nameNotifier,
      builder: (context, name, child) {
        return ValueListenableBuilder<String>(
          valueListenable: descriptionNotifier,
          builder: (context, description, _) {
            final canDraft = _canSaveAsDraft(name, description);
            final canSave = _canSave(name, description);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save as Draft Button
                SizedBox(
                  width: 110,
                  height: 45,
                  child: OutlinedButton(
                    onPressed: canDraft ? onSaveDraft : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.primaryColor,
                      disabledForegroundColor: ColorConstants.hintGrey
                          .withValues(alpha: 0.5),
                      side: BorderSide(
                        color:
                            canDraft
                                ? ColorConstants.primaryColor
                                : ColorConstants.hintGrey.withValues(
                                  alpha: 0.3,
                                ),
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Save As Draft',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Save Button
                SizedBox(
                  width: 110,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: canSave ? onSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor,
                      foregroundColor: ColorConstants.lightTextColor,
                      disabledBackgroundColor: ColorConstants.primaryColor
                          .withValues(alpha: 0.3),
                      disabledForegroundColor: ColorConstants.lightTextColor
                          .withValues(alpha: 0.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: canSave ? 2 : 0,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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
  final Widget Function({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines,
    int? maxLength,
    bool isSmall,
    TextInputType? keyboardType,
    String? prefixText,
  })
  buildMinimalTextField;

  const _CachedQuestionForm({
    super.key,
    required this.controllers,
    required this.media,
    required this.mediaUrls,
    required this.buildMinimalTextField,
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
                        widget.buildMinimalTextField(
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
                        widget.buildMinimalTextField(
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
                    child: widget.buildMinimalTextField(
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
          widget.buildMinimalTextField(
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
