// Create Page - Set and Board Management
//
// This page serves as the main hub for creating and managing quiz content.
// It provides a tabbed interface to view and manage:
// - Sets: Individual question sets with 5 questions each
// - Boards: Collections of up to 5 sets for complete quiz games
//
// Key Features:
// - Tab switching between Sets and Boards views
// - Filtering by status, tags, name, and creator
// - Sorting by name, difficulty, or creation date
// - CRUD operations: Create, Edit, Duplicate, Delete sets/boards
// - Bulk selection for future batch operations
// - Import set functionality (from external sources)
//
// Data Flow:
// - Sets are fetched from Firebase via SetService
// - Boards currently use mock data (Firebase integration pending)
// - Filters and sorts are applied client-side for performance

import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/pages/create_set_page.dart';
import 'package:buzz5_quiz_app/pages/import_set_page.dart';
import 'package:buzz5_quiz_app/pages/create_new_board_page.dart';
import 'package:buzz5_quiz_app/presentation/components/set_list_item_tile.dart';
import 'package:buzz5_quiz_app/presentation/components/board_list_item_tile.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // TAB CONTROLLER AND VIEW STATE
  // ============================================================
  late TabController _tabController;
  int _currentTabIndex = 0;

  // ============================================================
  // FIREBASE SERVICE
  // ============================================================
  final SetService _setService = SetService();

  // ============================================================
  // DATA STATE
  // ============================================================
  List<SetModel> _sets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // FILTER AND SORT STATE
  // ============================================================
  String _sortBy = 'Creation Date: Newest first';
  final Map<String, dynamic> _activeFilters = {};

  // Individual filter values
  SetStatus? _statusFilter;
  final List<String> _selectedTags = [];
  String _nameSearch = '';
  String _creatorSearch = '';

  // ============================================================
  // SELECTION STATE (for bulk operations)
  // ============================================================
  final Set<String> _selectedSetIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for Sets/Boards tabs
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    // Load sets from Firebase on page load
    _loadSets();
  }

  // ============================================================
  // DATA LOADING AND CRUD OPERATIONS
  // ============================================================

  /// Fetches user's sets from Firebase and updates the UI state.
  /// Shows loading indicator while fetching and handles errors gracefully.
  Future<void> _loadSets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final sets = await _setService.getUserSets();
      if (mounted) {
        setState(() {
          _sets = sets;
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

  /// Deletes a set from Firebase and refreshes the list.
  /// Shows success/error feedback via snackbar.
  Future<void> _deleteSet(SetModel set) async {
    try {
      await _setService.deleteSet(set.id);
      await _loadSets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${set.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error deleting set: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete set: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  /// Creates a duplicate of an existing set with "(Copy)" suffix.
  /// Shows loading indicator during operation and refreshes list on success.
  Future<void> _duplicateSet(SetModel set) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Duplicating "${set.name}"...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Perform duplication via service
      await _setService.duplicateSet(set.id);

      // Reload sets to show the new duplicate
      await _loadSets();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${set.name}" duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error duplicating set: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate set: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  /// Returns true if currently viewing the Sets tab, false for Boards tab.
  bool get _isSetView => _currentTabIndex == 0;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // MOCK BOARDS DATA (TODO: Replace with Firebase integration)
  // ============================================================
  final List<BoardModel> _boards = [
    BoardModel(
      id: 'b1',
      name: 'General Knowledge Championship',
      description:
          'A comprehensive board covering history, science, and pop culture',
      authorName: 'John Doe',
      authorId: 'user1',
      creationDate: DateTime.now().subtract(Duration(days: 10)),
      modifiedDate: DateTime.now().subtract(Duration(days: 2)),
      setIds: ['1', '2', '3'],
    ),
    BoardModel(
      id: 'b2',
      name: 'Science & Technology Mastery',
      description:
          'Deep dive into scientific concepts and technological innovations',
      authorName: 'Jane Smith',
      authorId: 'user2',
      creationDate: DateTime.now().subtract(Duration(days: 20)),
      modifiedDate: DateTime.now().subtract(Duration(days: 5)),
      setIds: ['2', '4'],
    ),
    BoardModel(
      id: 'b3',
      name: 'Entertainment Extravaganza',
      description: 'Movies, music, TV shows, and celebrity trivia',
      authorName: 'Mike Johnson',
      authorId: 'user3',
      creationDate: DateTime.now().subtract(Duration(days: 3)),
      modifiedDate: DateTime.now().subtract(Duration(hours: 10)),
      setIds: ['3'],
    ),
    BoardModel(
      id: 'b4',
      name: 'World Geography Explorer',
      description: 'Countries, capitals, landmarks, and geographical features',
      authorName: 'Sarah Williams',
      authorId: 'user4',
      creationDate: DateTime.now().subtract(Duration(days: 15)),
      modifiedDate: DateTime.now().subtract(Duration(days: 1)),
      setIds: ['5', '1', '2', '3', '4'],
    ),
    BoardModel(
      id: 'b5',
      name: 'History Through Ages',
      description: 'From ancient civilizations to modern world events',
      authorName: 'Tom Brown',
      authorId: 'user5',
      creationDate: DateTime.now().subtract(Duration(days: 30)),
      modifiedDate: DateTime.now().subtract(Duration(hours: 5)),
      setIds: ['1'],
    ),
  ];

  // ============================================================
  // FILTERING LOGIC
  // ============================================================

  /// Returns the list of sets filtered by current filter criteria.
  /// Applies status, name, creator, and tag filters in sequence.
  List<SetModel> get _filteredSets {
    List<SetModel> filtered = _sets;

    // Filter by status (Complete/Draft)
    if (_statusFilter != null) {
      filtered = filtered.where((set) => set.status == _statusFilter).toList();
    }

    // Filter by name search
    if (_nameSearch.isNotEmpty) {
      filtered =
          filtered
              .where(
                (set) =>
                    set.name.toLowerCase().contains(_nameSearch.toLowerCase()),
              )
              .toList();
    }

    // Filter by creator search
    if (_creatorSearch.isNotEmpty) {
      filtered =
          filtered
              .where(
                (set) => set.authorName.toLowerCase().contains(
                  _creatorSearch.toLowerCase(),
                ),
              )
              .toList();
    }

    // Filter by selected tags (any match)
    if (_selectedTags.isNotEmpty) {
      filtered =
          filtered
              .where(
                (set) => set.tags.any(
                  (tag) =>
                      _selectedTags.contains(tag.toString().split('.').last),
                ),
              )
              .toList();
    }

    return filtered;
  }

  /// Returns the list of boards filtered by current filter criteria.
  /// Maps SetStatus filter to BoardStatus for consistency.
  List<BoardModel> get _filteredBoards {
    List<BoardModel> filtered = _boards;

    // Filter by status (convert SetStatus to BoardStatus)
    if (_statusFilter != null) {
      BoardStatus boardStatus =
          _statusFilter == SetStatus.complete
              ? BoardStatus.complete
              : BoardStatus.draft;
      filtered =
          filtered.where((board) => board.status == boardStatus).toList();
    }

    // Filter by name search
    if (_nameSearch.isNotEmpty) {
      filtered =
          filtered
              .where(
                (board) => board.name.toLowerCase().contains(
                  _nameSearch.toLowerCase(),
                ),
              )
              .toList();
    }

    // Filter by creator search
    if (_creatorSearch.isNotEmpty) {
      filtered =
          filtered
              .where(
                (board) => board.authorName.toLowerCase().contains(
                  _creatorSearch.toLowerCase(),
                ),
              )
              .toList();
    }

    return filtered;
  }

  /// Resets all active filters to their default state.
  void _clearFilters() {
    setState(() {
      _activeFilters.clear();
      _statusFilter = null;
      _selectedTags.clear();
      _nameSearch = '';
      _creatorSearch = '';
    });
  }

  // ============================================================
  // FILTER DIALOG BUILDERS
  // ============================================================

  /// Shows a dialog to filter sets/boards by status (Complete/Draft).
  void _showStatusFilterDropdown(BuildContext context, RenderBox renderBox) {
    showDialog(
      context: context,
      builder: (context) {
        SetStatus? selectedStatus = _statusFilter;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper to build radio button options
            Widget buildRadioOption(String label, SetStatus? value) {
              final isSelected = selectedStatus == value;
              return InkWell(
                onTap: () {
                  setDialogState(() {
                    selectedStatus = value;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected
                                    ? ColorConstants.primaryColor
                                    : ColorConstants.hintGrey,
                            width: 2,
                          ),
                        ),
                        child:
                            isSelected
                                ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: ColorConstants.primaryColor,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      SizedBox(width: 16),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              isSelected ? ColorConstants.primaryColor : null,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text('Filter by Status'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildRadioOption('All', null),
                  buildRadioOption('Complete', SetStatus.complete),
                  buildRadioOption('Draft', SetStatus.draft),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = selectedStatus;
                      if (selectedStatus == null) {
                        _activeFilters.remove('Status');
                      } else {
                        _activeFilters['Status'] =
                            selectedStatus == SetStatus.complete
                                ? 'Complete'
                                : 'Draft';
                      }
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    foregroundColor: ColorConstants.lightTextColor,
                  ),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog to filter sets by tags (multi-select).
  void _showTagsFilterDropdown(BuildContext context, RenderBox renderBox) {
    final availableTags = [
      'history',
      'science',
      'tech',
      'math',
      'geography',
      'pop culture',
      'education',
      'entertainment',
      'trivia',
      'travel',
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Tags'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          availableTags.map((tag) {
                            return CheckboxListTile(
                              title: Text(tag),
                              value: _selectedTags.contains(tag),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                              activeColor: ColorConstants.primaryColor,
                              dense: true,
                            );
                          }).toList(),
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_selectedTags.isEmpty) {
                      _activeFilters.remove('Tags');
                    } else {
                      _activeFilters['Tags'] = _selectedTags.join(', ');
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: ColorConstants.lightTextColor,
                ),
                child: Text('Apply'),
              ),
            ],
          ),
    );
  }

  /// Shows a dialog to search sets/boards by name.
  void _showNameSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: _nameSearch);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Search by Name'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter set name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _nameSearch = controller.text;
                    if (_nameSearch.isEmpty) {
                      _activeFilters.remove('Name');
                    } else {
                      _activeFilters['Name'] = _nameSearch;
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: ColorConstants.lightTextColor,
                ),
                child: Text('Apply'),
              ),
            ],
          ),
    );
  }

  /// Shows a dialog to search sets/boards by creator name.
  void _showCreatorSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: _creatorSearch);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Search by Creator'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter creator name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _creatorSearch = controller.text;
                    if (_creatorSearch.isEmpty) {
                      _activeFilters.remove('Creator');
                    } else {
                      _activeFilters['Creator'] = _creatorSearch;
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: ColorConstants.lightTextColor,
                ),
                child: Text('Apply'),
              ),
            ],
          ),
    );
  }

  // ============================================================
  // UI BUILD METHODS
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          iconSize: 30,
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: AppBackground(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Page header with title, description, and action buttons
                _buildHeader(),

                const SizedBox(height: 24),

                // Tab bar for Sets/Boards toggle
                _buildTabBar(),

                const SizedBox(height: 16),

                // Filter and sort controls
                _buildFilterSortBar(),

                const SizedBox(height: 16),

                // Main content: Sets or Boards list
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the page header with title, description, and action buttons.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Sets and Boards',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? ColorConstants.lightTextColor
                              : ColorConstants.darkTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create, edit and organize your quiz questions in sets and boards.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ColorConstants.hintGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Action buttons
            Row(
              children: [
                // Import button (only shown on Sets tab)
                if (_isSetView) ...[
                  OutlinedButton.icon(
                    icon: Icon(Icons.upload_file, size: 18),
                    label: Text('Import'),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImportSetPage(),
                        ),
                      );
                      if (result == true) {
                        _loadSets();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? ColorConstants.lightTextColor
                              : ColorConstants.darkTextColor,
                      side: BorderSide(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? ColorConstants.lightTextColor.withValues(
                                  alpha: 0.3,
                                )
                                : ColorConstants.darkTextColor.withValues(
                                  alpha: 0.3,
                                ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      minimumSize: Size(110, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // New Set/Board button
                ElevatedButton.icon(
                  icon: Icon(Icons.add, size: 18),
                  label: Text(_isSetView ? 'New Set' : 'New Board'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                _isSetView
                                    ? NewSetPage()
                                    : CreateNewBoardPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    foregroundColor: ColorConstants.lightTextColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the tab bar for switching between Sets and Boards views.
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor:
          Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.lightTextColor
              : ColorConstants.darkTextColor,
      unselectedLabelColor: ColorConstants.hintGrey,
      indicatorColor: ColorConstants.primaryColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      labelStyle: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.bold,
      ),
      tabs: const [Tab(text: 'Sets'), Tab(text: 'Boards')],
    );
  }

  /// Builds the filter and sort control bar.
  Widget _buildFilterSortBar() {
    return Row(
      children: [
        // Filter chips (scrollable)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filter icon
                Icon(
                  Icons.filter_list,
                  size: 18,
                  color: ColorConstants.hintGrey,
                ),
                const SizedBox(width: 8),

                // Status filter chip
                _buildFilterChip(
                  label: 'Status',
                  value: _activeFilters['Status'],
                  isActive: _statusFilter != null,
                  onTap: () {
                    final renderBox = context.findRenderObject() as RenderBox;
                    _showStatusFilterDropdown(context, renderBox);
                  },
                ),

                const SizedBox(width: 8),

                // Tags filter chip (only for Sets)
                if (_isSetView) ...[
                  _buildFilterChip(
                    label: 'Tags',
                    value:
                        _selectedTags.isNotEmpty
                            ? '${_selectedTags.length} selected'
                            : null,
                    isActive: _selectedTags.isNotEmpty,
                    onTap: () {
                      final renderBox = context.findRenderObject() as RenderBox;
                      _showTagsFilterDropdown(context, renderBox);
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Name search chip
                _buildSearchChip(
                  label: 'Name',
                  value: _nameSearch.isNotEmpty ? _nameSearch : null,
                  isActive: _nameSearch.isNotEmpty,
                  onTap: () => _showNameSearchDialog(context),
                ),

                const SizedBox(width: 8),

                // Creator search chip
                _buildSearchChip(
                  label: 'Creator',
                  value: _creatorSearch.isNotEmpty ? _creatorSearch : null,
                  isActive: _creatorSearch.isNotEmpty,
                  onTap: () => _showCreatorSearchDialog(context),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Sort dropdown
        _buildSortDropdown(),

        // Clear filters button
        if (_activeFilters.isNotEmpty) ...[
          const SizedBox(width: 8),
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
    );
  }

  /// Builds a filter chip button with dropdown arrow.
  Widget _buildFilterChip({
    required String label,
    String? value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? ColorConstants.primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
          border: Border.all(
            color:
                isActive
                    ? ColorConstants.primaryColor
                    : ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color:
                    isActive
                        ? ColorConstants.primaryColor
                        : ColorConstants.hintGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (value != null) ...[
              Text(
                ': $value',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color:
                  isActive
                      ? ColorConstants.primaryColor
                      : ColorConstants.hintGrey,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a search chip button with search icon.
  Widget _buildSearchChip({
    required String label,
    String? value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? ColorConstants.primaryColor.withValues(alpha: 0.15)
                  : Colors.transparent,
          border: Border.all(
            color:
                isActive
                    ? ColorConstants.primaryColor
                    : ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 16,
              color:
                  isActive
                      ? ColorConstants.primaryColor
                      : ColorConstants.hintGrey,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color:
                    isActive
                        ? ColorConstants.primaryColor
                        : ColorConstants.hintGrey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (value != null) ...[
              Text(
                ': $value',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the sort dropdown menu.
  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: ColorConstants.hintGrey),
            SizedBox(width: 6),
            Text(
              _sortBy,
              style: TextStyle(fontSize: 13, color: ColorConstants.hintGrey),
            ),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(value: 'Name: A → Z', child: Text('Name: A → Z')),
            PopupMenuItem(value: 'Name: Z → A', child: Text('Name: Z → A')),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'Difficulty: High to Low',
              child: Text('Difficulty: High to Low'),
            ),
            PopupMenuItem(
              value: 'Difficulty: Low to High',
              child: Text('Difficulty: Low to High'),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'Creation Date: Newest first',
              child: Text('Creation Date: Newest first'),
            ),
            PopupMenuItem(
              value: 'Creation Date: Oldest first',
              child: Text('Creation Date: Oldest first'),
            ),
          ],
      onSelected: (value) {
        setState(() {
          _sortBy = value;
        });
      },
    );
  }

  /// Builds the main content area (sets list or boards list).
  Widget _buildContent() {
    if (_isSetView) {
      return _buildSetsContent();
    } else {
      return _buildBoardsContent();
    }
  }

  /// Builds the sets list content with loading, error, and empty states.
  Widget _buildSetsContent() {
    // Loading state
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: ColorConstants.primaryColor),
      );
    }

    // Error state
    if (_errorMessage != null) {
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
            ElevatedButton(onPressed: _loadSets, child: Text('Retry')),
          ],
        ),
      );
    }

    // Empty state
    if (_filteredSets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: ColorConstants.hintGrey,
            ),
            SizedBox(height: 16),
            Text(
              'No sets found',
              style: AppTextStyles.titleMedium.copyWith(
                color: ColorConstants.hintGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new set',
              style: AppTextStyles.bodySmall.copyWith(
                color: ColorConstants.hintGrey,
              ),
            ),
          ],
        ),
      );
    }

    // Sets list
    return ListView.builder(
      itemCount: _filteredSets.length,
      itemBuilder: (context, index) {
        final set = _filteredSets[index];
        return SetListItemTile(
          set: set,
          isSelected: _selectedSetIds.contains(set.id),
          onSelectionChanged: (selected) {
            setState(() {
              if (selected) {
                _selectedSetIds.add(set.id);
              } else {
                _selectedSetIds.remove(set.id);
              }
            });
          },
          onEdit: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => NewSetPage(existingSet: set),
                  ),
                )
                .then((_) => _loadSets());
          },
          onDuplicate: () => _duplicateSet(set),
          onDelete: () async {
            // Show confirmation dialog before deleting
            final confirmed = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: Text('Delete Set'),
                    content: Text(
                      'Are you sure you want to delete "${set.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: ColorConstants.errorColor,
                        ),
                        child: Text('Delete'),
                      ),
                    ],
                  ),
            );
            if (confirmed == true) {
              await _deleteSet(set);
            }
          },
        );
      },
    );
  }

  /// Builds the boards list content with empty state handling.
  Widget _buildBoardsContent() {
    // Empty state
    if (_filteredBoards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_outlined,
              size: 64,
              color: ColorConstants.hintGrey,
            ),
            SizedBox(height: 16),
            Text(
              'No boards found',
              style: AppTextStyles.titleMedium.copyWith(
                color: ColorConstants.hintGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new board',
              style: AppTextStyles.bodySmall.copyWith(
                color: ColorConstants.hintGrey,
              ),
            ),
          ],
        ),
      );
    }

    // Boards list
    return ListView.builder(
      itemCount: _filteredBoards.length,
      itemBuilder: (context, index) {
        final board = _filteredBoards[index];
        return BoardListItemTile(
          board: board,
          isSelected: _selectedSetIds.contains(board.id),
          onSelectionChanged: (selected) {
            setState(() {
              if (selected) {
                _selectedSetIds.add(board.id);
              } else {
                _selectedSetIds.remove(board.id);
              }
            });
          },
        );
      },
    );
  }
}
