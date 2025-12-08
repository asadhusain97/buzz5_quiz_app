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
import 'package:buzz5_quiz_app/widgets/content_state_builder.dart';
import 'package:buzz5_quiz_app/widgets/delete_confirmation_dialog.dart';
import 'package:buzz5_quiz_app/widgets/filter_sort_bar.dart';
import 'package:buzz5_quiz_app/pages/create_set_page.dart';
import 'package:buzz5_quiz_app/pages/import_set_page.dart';
import 'package:buzz5_quiz_app/pages/new_board_page.dart';
import 'package:buzz5_quiz_app/presentation/components/set_list_item_tile.dart';
import 'package:buzz5_quiz_app/presentation/components/board_list_item_tile.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';
import 'package:buzz5_quiz_app/services/board_service.dart';

class CreatePage extends StatefulWidget {
  /// Initial tab to display (0 = Sets, 1 = Boards)
  final int initialTabIndex;

  const CreatePage({super.key, this.initialTabIndex = 0});

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
  // FIREBASE SERVICES
  // ============================================================
  final SetService _setService = SetService();
  final BoardService _boardService = BoardService();

  // ============================================================
  // DATA STATE
  // ============================================================
  // Sets data
  List<SetModel> _sets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Boards data
  List<BoardModel> _boards = [];
  bool _isBoardsLoading = true;
  String? _boardsErrorMessage;

  // ============================================================
  // FILTER AND SORT STATE
  // ============================================================
  SortOption _currentSort = SortOption.dateNewest;
  final Map<String, dynamic> _activeFilters = {};

  // Individual filter values
  SetStatus? _statusFilter;
  final List<String> _selectedTags = [];
  String _nameSearch = '';
  String _creatorSearch = '';

  // ============================================================
  // SELECTION STATE (for bulk operations on both sets and boards)
  // ============================================================
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for Sets/Boards tabs with initial index
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _currentTabIndex = widget.initialTabIndex;
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    // Load data from Firebase on page load
    _loadSets();
    _loadBoards();
  }

  // ============================================================
  // SET DATA LOADING AND CRUD OPERATIONS
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

  // ============================================================
  // BOARD DATA LOADING AND CRUD OPERATIONS
  // ============================================================

  /// Fetches user's boards from Firebase and updates the UI state.
  Future<void> _loadBoards() async {
    try {
      setState(() {
        _isBoardsLoading = true;
        _boardsErrorMessage = null;
      });
      final boards = await _boardService.getUserBoards();
      if (mounted) {
        setState(() {
          _boards = boards;
          _isBoardsLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading boards: $e');
      if (mounted) {
        setState(() {
          _boardsErrorMessage = 'Failed to load boards: $e';
          _isBoardsLoading = false;
        });
      }
    }
  }

  /// Deletes a board from Firebase and refreshes the list.
  Future<void> _deleteBoard(BoardModel board) async {
    try {
      await _boardService.deleteBoard(board.id);
      await _loadBoards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${board.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error deleting board: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete board: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  /// Creates a duplicate of an existing board with "(Copy)" suffix.
  Future<void> _duplicateBoard(BoardModel board) async {
    try {
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
                Text('Duplicating "${board.name}"...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      await _boardService.duplicateBoard(board.id);
      await _loadBoards();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${board.name}" duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error duplicating board: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate board: $e'),
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
  // FILTERING LOGIC
  // ============================================================

  /// Returns the list of sets filtered and sorted by current criteria.
  /// Applies status, name, creator, and tag filters, then sorts.
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

    // Apply sorting
    return _sortSets(filtered);
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

  /// Returns the list of boards filtered and sorted by current criteria.
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

    // Apply sorting
    return _sortBoards(filtered);
  }

  /// Sort boards based on current sort option (no difficulty for boards)
  List<BoardModel> _sortBoards(List<BoardModel> boards) {
    final sorted = List<BoardModel>.from(boards);
    switch (_currentSort) {
      case SortOption.nameAZ:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameZA:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.difficultyHighToLow:
      case SortOption.difficultyLowToHigh:
        // Boards don't have difficulty, fall back to date newest
        sorted.sort((a, b) => b.creationDate.compareTo(a.creationDate));
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
  // FILTER DIALOG HANDLERS (using shared widgets)
  // ============================================================

  /// Shows a dialog to filter sets/boards by status (Complete/Draft).
  void _showStatusFilter() async {
    final result = await showStatusFilterDialog(
      context: context,
      currentStatus: _statusFilter,
    );
    // Only apply if user clicked Apply (not cancelled)
    if (result != null && result.applied) {
      setState(() {
        _statusFilter = result.status;
        if (result.status == null) {
          _activeFilters.remove('Status');
        } else {
          _activeFilters['Status'] =
              result.status == SetStatus.complete ? 'Complete' : 'Draft';
        }
      });
    }
  }

  /// Shows a dialog to filter sets by tags (multi-select).
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
        if (_selectedTags.isEmpty) {
          _activeFilters.remove('Tags');
        } else {
          _activeFilters['Tags'] = _selectedTags.join(', ');
        }
      });
    }
  }

  /// Shows a dialog to search sets/boards by name.
  void _showNameSearch() async {
    final result = await showNameSearchDialog(
      context: context,
      currentValue: _nameSearch,
      title: 'Search by Name',
      hint: 'Enter set name',
    );
    if (result != null) {
      setState(() {
        _nameSearch = result;
        if (_nameSearch.isEmpty) {
          _activeFilters.remove('Name');
        } else {
          _activeFilters['Name'] = _nameSearch;
        }
      });
    }
  }

  /// Shows a dialog to search sets/boards by creator name.
  void _showCreatorSearch() async {
    final result = await showCreatorSearchDialog(
      context: context,
      currentValue: _creatorSearch,
    );
    if (result != null) {
      setState(() {
        _creatorSearch = result;
        if (_creatorSearch.isEmpty) {
          _activeFilters.remove('Creator');
        } else {
          _activeFilters['Creator'] = _creatorSearch;
        }
      });
    }
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                _isSetView ? NewSetPage() : NewBoardPage(),
                      ),
                    );
                    // Reload data if a set or board was created
                    if (result == true) {
                      if (_isSetView) {
                        _loadSets();
                      } else {
                        _loadBoards();
                      }
                    }
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

  /// Builds the filter and sort control bar using shared widgets.
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
                FilterChipButton(
                  label: 'Status',
                  value: _activeFilters['Status'] as String?,
                  isActive: _statusFilter != null,
                  onTap: _showStatusFilter,
                ),

                const SizedBox(width: 8),

                // Tags filter chip (only for Sets)
                if (_isSetView) ...[
                  FilterChipButton(
                    label: 'Tags',
                    value:
                        _selectedTags.isNotEmpty
                            ? '${_selectedTags.length} selected'
                            : null,
                    isActive: _selectedTags.isNotEmpty,
                    onTap: _showTagsFilter,
                  ),
                  const SizedBox(width: 8),
                ],

                // Name search chip
                SearchChipButton(
                  label: 'Name',
                  value: _nameSearch.isNotEmpty ? _nameSearch : null,
                  isActive: _nameSearch.isNotEmpty,
                  onTap: _showNameSearch,
                ),

                const SizedBox(width: 8),

                // Creator search chip
                SearchChipButton(
                  label: 'Creator',
                  value: _creatorSearch.isNotEmpty ? _creatorSearch : null,
                  isActive: _creatorSearch.isNotEmpty,
                  onTap: _showCreatorSearch,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Sort dropdown (using shared widget)
        SortDropdownButton(
          currentSort: _currentSort,
          onSortChanged: (sort) {
            setState(() {
              _currentSort = sort;
            });
          },
          showDifficulty: _isSetView, // Only show difficulty for Sets
        ),

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
    return ContentStateBuilder(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      errorTitle: 'Error loading sets',
      onRetry: _loadSets,
      isEmpty: _filteredSets.isEmpty,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: 'No sets found',
      emptySubtitle: 'Try adjusting your filters or create a new set',
      content: ListView.builder(
        itemCount: _filteredSets.length,
        itemBuilder: (context, index) {
          final set = _filteredSets[index];
          return SetListItemTile(
            set: set,
            isSelected: _selectedItemIds.contains(set.id),
            onSelectionChanged: (selected) {
              setState(() {
                if (selected) {
                  _selectedItemIds.add(set.id);
                } else {
                  _selectedItemIds.remove(set.id);
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
              final confirmed = await showDeleteConfirmationDialog(
                context: context,
                itemType: 'set',
                itemName: set.name,
              );
              if (confirmed == true) {
                await _deleteSet(set);
              }
            },
          );
        },
      ),
    );
  }

  /// Builds the boards list content with loading, error, and empty state handling.
  Widget _buildBoardsContent() {
    return ContentStateBuilder(
      isLoading: _isBoardsLoading,
      errorMessage: _boardsErrorMessage,
      errorTitle: 'Error loading boards',
      onRetry: _loadBoards,
      isEmpty: _filteredBoards.isEmpty,
      emptyIcon: Icons.dashboard_outlined,
      emptyTitle: 'No boards found',
      emptySubtitle: _boards.isEmpty
          ? 'Create your first board to get started'
          : 'Try adjusting your filters or create a new board',
      content: ListView.builder(
        itemCount: _filteredBoards.length,
        itemBuilder: (context, index) {
          final board = _filteredBoards[index];
          return BoardListItemTile(
            board: board,
            isSelected: _selectedItemIds.contains(board.id),
            onSelectionChanged: (selected) {
              setState(() {
                if (selected) {
                  _selectedItemIds.add(board.id);
                } else {
                  _selectedItemIds.remove(board.id);
                }
              });
            },
            onEdit: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => NewBoardPage(existingBoard: board),
                    ),
                  )
                  .then((_) => _loadBoards());
            },
            onDuplicate: () => _duplicateBoard(board),
            onDelete: () async {
              final confirmed = await showDeleteConfirmationDialog(
                context: context,
                itemType: 'board',
                itemName: board.name,
                additionalMessage: 'This action cannot be undone.',
              );
              if (confirmed == true) {
                _deleteBoard(board);
              }
            },
          );
        },
      ),
    );
  }
}
