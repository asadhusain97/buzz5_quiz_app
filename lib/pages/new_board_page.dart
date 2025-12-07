// New Board Page
//
// This page handles creating new quiz boards with drag-and-drop functionality.
// Users can drag sets from the bottom list into 5 slots at the top.
// A board requires exactly 5 sets to be marked as complete.
//
// Features:
// - Responsive design with minimum width requirement (800px)
// - Sticky scroll: header scrolls away, slots stick at top
// - Drag-and-drop from source list to fixed slots
// - Filtering by tags, name, creator
// - Sorting by name, difficulty, date
// - Save as Draft / Save functionality based on slot count

import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/widgets/dynamic_save_button.dart';
import 'package:buzz5_quiz_app/widgets/filter_sort_bar.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';
import 'package:buzz5_quiz_app/services/board_service.dart';

/// Minimum width required to display this page properly
const double kMinBoardPageWidth = 800.0;

/// Height of the board slots section (reduced by ~50% from original 140px)
const double kSlotHeight = 75.0;

class NewBoardPage extends StatefulWidget {
  /// Optional existing board for edit mode. If null, creates a new board.
  final BoardModel? existingBoard;

  const NewBoardPage({super.key, this.existingBoard});

  @override
  State<NewBoardPage> createState() => _NewBoardPageState();
}

class _NewBoardPageState extends State<NewBoardPage> {
  final _formKey = GlobalKey<FormState>();
  final SetService _setService = SetService();
  final BoardService _boardService = BoardService();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Data state
  List<SetModel> _allCompleteSets = [];

  // Selected sets for the 5 slots (null means empty slot)
  final List<SetModel?> _boardSlots = List.filled(5, null);

  // Filter and sort state
  SortOption _currentSort = SortOption.dateNewest;
  final List<String> _selectedTags = [];
  String _nameSearch = '';
  String _creatorSearch = '';

  // ValueNotifiers for efficient button updates
  final _nameNotifier = ValueNotifier<String>('');
  final _descriptionNotifier = ValueNotifier<String>('');
  final _slotCountNotifier = ValueNotifier<int>(0);

  /// Returns true if we're editing an existing board
  bool get _isEditMode => widget.existingBoard != null;

  @override
  void initState() {
    super.initState();
    _loadCompleteSets();

    // Pre-populate form fields if editing
    if (_isEditMode) {
      _nameController.text = widget.existingBoard!.name;
      _descriptionController.text = widget.existingBoard!.description;
      // Also update notifiers so buttons are enabled immediately
      _nameNotifier.value = widget.existingBoard!.name;
      _descriptionNotifier.value = widget.existingBoard!.description;
    }

    _nameController.addListener(() {
      _nameNotifier.value = _nameController.text;
    });
    _descriptionController.addListener(() {
      _descriptionNotifier.value = _descriptionController.text;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameNotifier.dispose();
    _descriptionNotifier.dispose();
    _slotCountNotifier.dispose();
    super.dispose();
  }

  /// Load all complete sets from the user's collection
  Future<void> _loadCompleteSets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allSets = await _setService.getUserSets();

      // Filter only complete sets
      final completeSets =
          allSets.where((set) => set.status == SetStatus.complete).toList();

      if (mounted) {
        setState(() {
          _allCompleteSets = completeSets;

          // If editing, populate the board slots with existing sets
          if (_isEditMode && widget.existingBoard != null) {
            final existingSetIds = widget.existingBoard!.setIds;
            for (int i = 0; i < existingSetIds.length && i < 5; i++) {
              // Find the set by ID in our complete sets list
              final setModel = completeSets.firstWhere(
                (set) => set.id == existingSetIds[i],
                orElse: () => SetModel(
                  id: existingSetIds[i],
                  name: 'Unknown Set',
                  description: 'This set may have been deleted or changed',
                  authorId: '',
                  authorName: '',
                  questions: [],
                ),
              );
              _boardSlots[i] = setModel;
            }
            _slotCountNotifier.value = _filledSlotCount;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading sets: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load sets: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Get available sets (not already in board slots), filtered and sorted
  List<SetModel> get _availableSets {
    final selectedIds =
        _boardSlots.where((s) => s != null).map((s) => s!.id).toSet();

    List<SetModel> filtered =
        _allCompleteSets.where((set) => !selectedIds.contains(set.id)).toList();

    // Apply name filter
    if (_nameSearch.isNotEmpty) {
      filtered = filtered
          .where(
              (set) => set.name.toLowerCase().contains(_nameSearch.toLowerCase()))
          .toList();
    }

    // Apply creator filter
    if (_creatorSearch.isNotEmpty) {
      filtered = filtered
          .where((set) =>
              set.authorName.toLowerCase().contains(_creatorSearch.toLowerCase()))
          .toList();
    }

    // Apply tags filter
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((set) {
        return set.tags.any(
            (tag) => _selectedTags.contains(tag.toString().split('.').last));
      }).toList();
    }

    // Apply sorting
    filtered = _sortSets(filtered);

    return filtered;
  }

  /// Sort sets based on current sort option
  List<SetModel> _sortSets(List<SetModel> sets) {
    final sorted = List<SetModel>.from(sets);
    switch (_currentSort) {
      case SortOption.nameAZ:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameZA:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.difficultyHighToLow:
        sorted.sort((a, b) {
          final aIndex = a.difficulty?.index ?? 1;
          final bIndex = b.difficulty?.index ?? 1;
          return bIndex.compareTo(aIndex);
        });
        break;
      case SortOption.difficultyLowToHigh:
        sorted.sort((a, b) {
          final aIndex = a.difficulty?.index ?? 1;
          final bIndex = b.difficulty?.index ?? 1;
          return aIndex.compareTo(bIndex);
        });
        break;
      case SortOption.dateNewest:
        sorted.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case SortOption.dateOldest:
        sorted.sort((a, b) => a.creationDate.compareTo(b.creationDate));
        break;
    }
    return sorted;
  }

  /// Count of filled slots
  int get _filledSlotCount => _boardSlots.where((s) => s != null).length;

  /// Check if any filters are active
  bool get _hasActiveFilters =>
      _selectedTags.isNotEmpty ||
      _nameSearch.isNotEmpty ||
      _creatorSearch.isNotEmpty;

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedTags.clear();
      _nameSearch = '';
      _creatorSearch = '';
    });
  }

  /// Remove a set from a specific slot
  void _removeSetFromSlot(int slotIndex) {
    setState(() {
      _boardSlots[slotIndex] = null;
      _slotCountNotifier.value = _filledSlotCount;
    });
  }

  /// Add a set to a specific slot index
  void _addSetToSlotAtIndex(SetModel set, int index) {
    if (_boardSlots[index] == null) {
      setState(() {
        _boardSlots[index] = set;
        _slotCountNotifier.value = _filledSlotCount;
      });
    }
  }

  /// Handle saving the board (create or update based on edit mode)
  Future<void> _saveBoard({required bool isDraft}) async {
    if (_isSaving) return;

    // Validate form
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in the board name and description'),
          backgroundColor: ColorConstants.errorColor,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      // Check if name already exists (exclude current board when editing)
      final nameExists = await _boardService.checkBoardNameExists(
        _nameController.text.trim(),
        excludeBoardId: _isEditMode ? widget.existingBoard!.id : null,
      );

      if (nameExists) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
        });

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: ColorConstants.errorColor,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text('Duplicate Name'),
              ],
            ),
            content: Text(
              'A board with the name "${_nameController.text.trim()}" already exists. Please choose a different name.',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(color: ColorConstants.primaryColor),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Get selected set IDs
      final setIds =
          _boardSlots.where((s) => s != null).map((s) => s!.id).toList();

      // Create or update the board based on mode
      if (_isEditMode) {
        // Update existing board
        await _boardService.updateBoard(
          boardId: widget.existingBoard!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          setIds: setIds,
          isDraft: isDraft,
        );
      } else {
        // Create new board
        await _boardService.createBoard(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          setIds: setIds,
          isDraft: isDraft,
        );
      }

      if (!mounted) return;

      // Show success message
      final actionWord = _isEditMode ? 'updated' : 'saved';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? 'Board $actionWord as draft successfully!'
                : 'Board $actionWord successfully!',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      await Future.delayed(Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      AppLogger.e('Error saving board: $e', error: e, stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving board: ${e.toString()}'),
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

  // ============================================================
  // FILTER DIALOG HANDLERS
  // ============================================================

  void _showTagsFilter() async {
    final result = await showTagsFilterDialog(
      context: context,
      availableTags: getAvailableTagNames(),
      selectedTags: _selectedTags,
    );
    if (result != null) {
      setState(() {
        _selectedTags.clear();
        _selectedTags.addAll(result);
      });
    }
  }

  void _showNameSearch() async {
    final result = await showNameSearchDialog(
      context: context,
      currentValue: _nameSearch,
      title: 'Search by Set Name',
      hint: 'Enter set name',
    );
    if (result != null) {
      setState(() {
        _nameSearch = result;
      });
    }
  }

  void _showCreatorSearch() async {
    final result = await showCreatorSearchDialog(
      context: context,
      currentValue: _creatorSearch,
    );
    if (result != null) {
      setState(() {
        _creatorSearch = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Board' : 'Create New Board',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Check minimum width requirement
          if (constraints.maxWidth < kMinBoardPageWidth) {
            return _buildWidthConstraintMessage();
          }

          return AppBackground(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 900),
                child: Form(
                  key: _formKey,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: ColorConstants.primaryColor,
                          ),
                        )
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _buildMainContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build the width constraint message for small screens
  Widget _buildWidthConstraintMessage() {
    return AppBackground(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.desktop_windows_outlined,
                size: 80,
                color: ColorConstants.hintGrey,
              ),
              SizedBox(height: 24),
              Text(
                'Screen Too Small',
                style: AppTextStyles.titleBig.copyWith(
                  color: ColorConstants.lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'The Board Creator requires a larger screen to function properly. '
                'Please use a device with a wider display or resize your browser window.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorConstants.hintGrey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                'Minimum width required: ${kMinBoardPageWidth.toInt()}px',
                style: AppTextStyles.labelSmall.copyWith(
                  color: ColorConstants.hintGrey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back),
                label: Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.lightTextColor,
                  side: BorderSide(
                    color: ColorConstants.lightTextColor.withValues(alpha: 0.3),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build error state UI
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: ColorConstants.errorColor,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading sets',
            style: AppTextStyles.titleMedium.copyWith(
              color: ColorConstants.errorColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: AppTextStyles.bodySmall.copyWith(
              color: ColorConstants.hintGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCompleteSets,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build the main scrollable content with sticky slots
  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Header section (scrolls away)
        SliverToBoxAdapter(
          child: _buildHeaderSection(),
        ),

        // Board slots section (sticky)
        SliverPersistentHeader(
          pinned: true,
          floating: false,
          delegate: _BoardSlotsSectionDelegate(
            boardSlots: _boardSlots,
            filledSlotCount: _filledSlotCount,
            onRemoveFromSlot: _removeSetFromSlot,
            onAddToSlot: _addSetToSlotAtIndex,
          ),
        ),

        // Available sets header with filters
        SliverToBoxAdapter(
          child: _buildAvailableSetsHeader(),
        ),

        // Available sets list
        _availableSets.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptySetsMessage())
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final set = _availableSets[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _buildDraggableSetItem(set),
                    );
                  },
                  childCount: _availableSets.length,
                ),
              ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  /// Build the header section with form fields and action buttons
  Widget _buildHeaderSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode ? 'Edit Board' : 'Create a Board',
                style: AppTextStyles.titleBig.copyWith(
                  color: ColorConstants.lightTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(width: 16),
              DynamicSaveButton(
                nameNotifier: _nameNotifier,
                descriptionNotifier: _descriptionNotifier,
                completionCountNotifier: _slotCountNotifier,
                requiredCount: 5,
                onSaveDraft: () => _saveBoard(isDraft: true),
                onSave: () => _saveBoard(isDraft: false),
                isSaving: _isSaving,
              ),
            ],
          ),
          SizedBox(height: 24),

          // Name and Description row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMinimalTextField(
                  controller: _nameController,
                  label: 'Board Name *',
                  hint: 'Enter board name',
                  maxLength: 50,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildMinimalTextField(
                  controller: _descriptionController,
                  label: 'Description *',
                  hint: 'Describe what this board is about',
                  maxLength: 200,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a minimal text field matching the NewSetPage style
  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: ColorConstants.lightTextColor.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ColorConstants.lightTextColor.withValues(alpha: 0.4),
              fontSize: 16,
            ),
            counterText: '',
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
              horizontal: 14,
              vertical: 16,
            ),
            isDense: true,
            filled: false,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            color: ColorConstants.lightTextColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Build available sets header with filters
  Widget _buildAvailableSetsHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Available Sets',
                style: AppTextStyles.titleSmall.copyWith(
                  color: ColorConstants.lightTextColor,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.hintGrey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_availableSets.length} sets',
                  style: TextStyle(
                    color: ColorConstants.hintGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Only complete sets are shown. Drag a set to add it to the board.',
            style: AppTextStyles.labelSmall.copyWith(
              color: ColorConstants.hintGrey,
            ),
          ),
          SizedBox(height: 12),

          // Filter and sort bar
          Row(
            children: [
              // Filter chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: ColorConstants.hintGrey,
                      ),
                      SizedBox(width: 8),

                      // Tags filter
                      FilterChipButton(
                        label: 'Tags',
                        value: _selectedTags.isNotEmpty
                            ? '${_selectedTags.length} selected'
                            : null,
                        isActive: _selectedTags.isNotEmpty,
                        onTap: _showTagsFilter,
                      ),
                      SizedBox(width: 8),

                      // Name search
                      SearchChipButton(
                        label: 'Name',
                        value: _nameSearch.isNotEmpty ? _nameSearch : null,
                        isActive: _nameSearch.isNotEmpty,
                        onTap: _showNameSearch,
                      ),
                      SizedBox(width: 8),

                      // Creator search
                      SearchChipButton(
                        label: 'Creator',
                        value:
                            _creatorSearch.isNotEmpty ? _creatorSearch : null,
                        isActive: _creatorSearch.isNotEmpty,
                        onTap: _showCreatorSearch,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Sort dropdown
              SortDropdownButton(
                currentSort: _currentSort,
                onSortChanged: (sort) {
                  setState(() {
                    _currentSort = sort;
                  });
                },
                showDifficulty: true,
              ),

              // Clear filters button
              if (_hasActiveFilters) ...[
                SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build empty sets message
  Widget _buildEmptySetsMessage() {
    final allSetsUsed =
        _allCompleteSets.length == _filledSlotCount && !_hasActiveFilters;

    return Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allSetsUsed ? Icons.check_circle : Icons.inventory_2_outlined,
              size: 48,
              color: allSetsUsed
                  ? ColorConstants.successColor
                  : ColorConstants.hintGrey,
            ),
            SizedBox(height: 16),
            Text(
              allSetsUsed
                  ? 'All sets have been added to the board'
                  : _hasActiveFilters
                      ? 'No sets match the current filters'
                      : 'No complete sets available',
              style: AppTextStyles.bodyMedium.copyWith(
                color: allSetsUsed
                    ? ColorConstants.successColor
                    : ColorConstants.hintGrey,
              ),
            ),
            if (_hasActiveFilters) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: _clearFilters,
                child: Text('Clear filters'),
              ),
            ],
            if (!allSetsUsed && !_hasActiveFilters) ...[
              SizedBox(height: 8),
              Text(
                'Create and complete sets first to add them to a board',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ColorConstants.hintGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a draggable set item
  Widget _buildDraggableSetItem(SetModel set) {
    return Draggable<SetModel>(
      data: set,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorConstants.darkCardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.drag_indicator,
                color: ColorConstants.hintGrey,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  set.name,
                  style: TextStyle(
                    color: ColorConstants.lightTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _DraggableSetCard(set: set),
      ),
      child: _DraggableSetCard(set: set),
    );
  }
}

// ============================================================
// BOARD SLOTS SECTION DELEGATE (for sticky header)
// ============================================================

class _BoardSlotsSectionDelegate extends SliverPersistentHeaderDelegate {
  final List<SetModel?> boardSlots;
  final int filledSlotCount;
  final Function(int) onRemoveFromSlot;
  final Function(SetModel, int) onAddToSlot;

  _BoardSlotsSectionDelegate({
    required this.boardSlots,
    required this.filledSlotCount,
    required this.onRemoveFromSlot,
    required this.onAddToSlot,
  });

  @override
  double get minExtent => kSlotHeight + 60; // slots + header

  @override
  double get maxExtent => kSlotHeight + 60;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Transparent background - matches other sections
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Board Slots',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: ColorConstants.lightTextColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: filledSlotCount == 5
                          ? ColorConstants.successColor.withValues(alpha: 0.2)
                          : ColorConstants.hintGrey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$filledSlotCount / 5',
                      style: TextStyle(
                        color: filledSlotCount == 5
                            ? ColorConstants.successColor
                            : ColorConstants.hintGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Drag sets here',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: ColorConstants.hintGrey,
                    ),
                  ),
                ],
              ),
            ),

            // The 5 slots
            SizedBox(
              height: kSlotHeight,
              child: Row(
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: _BoardSlotCard(
                        index: index,
                        set: boardSlots[index],
                        onRemove: () => onRemoveFromSlot(index),
                        onAccept: (set) => onAddToSlot(set, index),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Divider at bottom
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                height: 1,
                color: ColorConstants.hintGrey.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _BoardSlotsSectionDelegate oldDelegate) {
    return oldDelegate.filledSlotCount != filledSlotCount ||
        oldDelegate.boardSlots != boardSlots;
  }
}

// ============================================================
// BOARD SLOT CARD WIDGET
// ============================================================

class _BoardSlotCard extends StatelessWidget {
  final int index;
  final SetModel? set;
  final VoidCallback onRemove;
  final Function(SetModel) onAccept;

  const _BoardSlotCard({
    required this.index,
    required this.set,
    required this.onRemove,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = set == null;

    return DragTarget<SetModel>(
      onWillAcceptWithDetails: (details) => isEmpty,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            // Subtle transparent background with slight shading
            color: isEmpty
                ? (isHovering
                    ? ColorConstants.primaryColor.withValues(alpha: 0.12)
                    : ColorConstants.hintGrey.withValues(alpha: 0.08))
                : ColorConstants.hintGrey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEmpty
                  ? (isHovering
                      ? ColorConstants.primaryColor
                      : ColorConstants.hintGrey.withValues(alpha: 0.25))
                  : ColorConstants.primaryColor.withValues(alpha: 0.5),
              width: isHovering ? 2 : 1,
            ),
          ),
          child: isEmpty
              ? _buildEmptySlot(isHovering)
              : _buildFilledSlot(set!),
        );
      },
    );
  }

  Widget _buildEmptySlot(bool isHovering) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHovering ? Icons.add_circle : Icons.add_circle_outline,
            size: 24,
            color: isHovering
                ? ColorConstants.primaryColor
                : ColorConstants.hintGrey.withValues(alpha: 0.5),
          ),
          SizedBox(height: 4),
          Text(
            '${index + 1}',
            style: TextStyle(
              color: isHovering
                  ? ColorConstants.primaryColor
                  : ColorConstants.hintGrey.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilledSlot(SetModel set) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Slot number badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: ColorConstants.primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4),
              // Set name
              Expanded(
                child: Text(
                  set.name,
                  style: TextStyle(
                    color: ColorConstants.lightTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Remove button
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ColorConstants.errorColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: ColorConstants.errorColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DRAGGABLE SET CARD WIDGET (for source list)
// ============================================================

class _DraggableSetCard extends StatelessWidget {
  final SetModel set;

  const _DraggableSetCard({required this.set});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: ColorConstants.darkCard,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Drag handle
            Icon(
              Icons.drag_indicator,
              color: ColorConstants.hintGrey,
              size: 24,
            ),
            SizedBox(width: 12),

            // Set info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.name,
                    style: TextStyle(
                      color: ColorConstants.lightTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    set.description,
                    style: TextStyle(
                      color: ColorConstants.hintGrey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Difficulty badge (no question count per requirement)
            if (set.difficulty != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(set.difficulty!)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getDifficultyColor(set.difficulty!)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _getDifficultyLabel(set.difficulty!),
                  style: TextStyle(
                    color: _getDifficultyColor(set.difficulty!),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }
}

