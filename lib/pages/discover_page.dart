// Discover Page - Marketplace Lite for discovering public sets
//
// This page allows users to discover and download public sets from other creators.
// Key Features:
// - Discover public sets from the marketplace
// - Filter by tags, difficulty, and search by name/author
// - Sort by downloads, rating, name, or date
// - "Add to Collection" button to copy sets to user's library
// - Sets are deep-copied (fork strategy) - downloaded sets are independent

import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/widgets/content_state_builder.dart';
import 'package:buzz5_quiz_app/widgets/filter_sort_bar.dart';
import 'package:buzz5_quiz_app/presentation/components/discover_set_tile.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';

/// Sort options for marketplace discovery
enum DiscoverSortOption {
  downloadsHighToLow,
  downloadsLowToHigh,
  ratingHighToLow,
  ratingLowToHigh,
  nameAZ,
  nameZA,
  dateNewest,
  dateOldest,
}

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // ============================================================
  // SERVICES
  // ============================================================
  final SetService _setService = SetService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // DATA STATE
  // ============================================================
  List<SetModel> _sets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // FILTER AND SORT STATE
  // ============================================================
  DiscoverSortOption _currentSort = DiscoverSortOption.downloadsHighToLow;
  final Map<String, dynamic> _activeFilters = {};

  // Individual filter values
  DifficultyLevel? _difficultyFilter;
  final List<String> _selectedTags = [];
  String _nameSearch = '';
  String _authorSearch = '';

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================

  /// Fetches public sets from the marketplace.
  Future<void> _loadSets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final sets = await _setService.getMarketplaceSets(limit: 100);
      if (mounted) {
        setState(() {
          _sets = sets;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.e('Error loading marketplace sets: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load sets: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Downloads a set to the user's library.
  Future<void> _addToCollection(SetModel set) async {
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
                Text('Adding "${set.name}" to your collection...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Perform the copy operation
      await _setService.duplicateSetToLibrary(set);

      // Reload sets to update download counts
      await _loadSets();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${set.name}" added to your collection!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate back to let user access their collection
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('Error adding set to collection: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add set: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  // ============================================================
  // FILTERING LOGIC
  // ============================================================

  /// Returns the list of sets filtered and sorted by current criteria.
  List<SetModel> get _filteredSets {
    List<SetModel> filtered = _sets;

    // Filter by difficulty
    if (_difficultyFilter != null) {
      filtered =
          filtered
              .where((set) => set.difficulty == _difficultyFilter)
              .toList();
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

    // Filter by author search
    if (_authorSearch.isNotEmpty) {
      filtered =
          filtered
              .where(
                (set) => set.authorName.toLowerCase().contains(
                  _authorSearch.toLowerCase(),
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
      case DiscoverSortOption.downloadsHighToLow:
        sorted.sort((a, b) => b.downloads.compareTo(a.downloads));
        break;
      case DiscoverSortOption.downloadsLowToHigh:
        sorted.sort((a, b) => a.downloads.compareTo(b.downloads));
        break;
      case DiscoverSortOption.ratingHighToLow:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case DiscoverSortOption.ratingLowToHigh:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case DiscoverSortOption.nameAZ:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case DiscoverSortOption.nameZA:
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case DiscoverSortOption.dateNewest:
        sorted.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case DiscoverSortOption.dateOldest:
        sorted.sort((a, b) => a.creationDate.compareTo(b.creationDate));
        break;
    }
    return sorted;
  }

  /// Resets all active filters to their default state.
  void _clearFilters() {
    setState(() {
      _activeFilters.clear();
      _difficultyFilter = null;
      _selectedTags.clear();
      _nameSearch = '';
      _authorSearch = '';
    });
  }

  // ============================================================
  // FILTER DIALOG HANDLERS
  // ============================================================

  /// Shows a dialog to filter sets by difficulty.
  void _showDifficultyFilter() async {
    final result = await showDialog<DifficultyLevel?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter by Difficulty'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<DifficultyLevel?>(
                title: Text('All'),
                value: null,
                groupValue: _difficultyFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<DifficultyLevel?>(
                title: Text('Easy'),
                value: DifficultyLevel.easy,
                groupValue: _difficultyFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<DifficultyLevel?>(
                title: Text('Medium'),
                value: DifficultyLevel.medium,
                groupValue: _difficultyFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<DifficultyLevel?>(
                title: Text('Hard'),
                value: DifficultyLevel.hard,
                groupValue: _difficultyFilter,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
        );
      },
    );

    if (result != _difficultyFilter) {
      setState(() {
        _difficultyFilter = result;
        if (result == null) {
          _activeFilters.remove('Difficulty');
        } else {
          _activeFilters['Difficulty'] = result.label;
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

  /// Shows a dialog to search sets by name.
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

  /// Shows a dialog to search sets by author name.
  void _showAuthorSearch() async {
    final result = await showNameSearchDialog(
      context: context,
      currentValue: _authorSearch,
      title: 'Search by Author',
      hint: 'Enter author name',
    );
    if (result != null) {
      setState(() {
        _authorSearch = result;
        if (_authorSearch.isEmpty) {
          _activeFilters.remove('Author');
        } else {
          _activeFilters['Author'] = _authorSearch;
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
        title: Text('Discover', style: AppTextStyles.titleBig),
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

                // Page header
                _buildHeader(),

                const SizedBox(height: 24),

                // Filter and sort controls
                _buildFilterSortBar(),

                const SizedBox(height: 16),

                // Main content: Sets list
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the page header with title and description.
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover Sets',
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
          'Browse and add public quiz sets from other creators to your collection.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ColorConstants.hintGrey,
          ),
        ),
      ],
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

                // Difficulty filter chip
                FilterChipButton(
                  label: 'Difficulty',
                  value: _activeFilters['Difficulty'] as String?,
                  isActive: _difficultyFilter != null,
                  onTap: _showDifficultyFilter,
                ),

                const SizedBox(width: 8),

                // Tags filter chip
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

                // Name search chip
                SearchChipButton(
                  label: 'Name',
                  value: _nameSearch.isNotEmpty ? _nameSearch : null,
                  isActive: _nameSearch.isNotEmpty,
                  onTap: _showNameSearch,
                ),

                const SizedBox(width: 8),

                // Author search chip
                SearchChipButton(
                  label: 'Author',
                  value: _authorSearch.isNotEmpty ? _authorSearch : null,
                  isActive: _authorSearch.isNotEmpty,
                  onTap: _showAuthorSearch,
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

  /// Builds the sort dropdown specific to Discover page.
  Widget _buildSortDropdown() {
    String getSortLabel(DiscoverSortOption option) {
      switch (option) {
        case DiscoverSortOption.downloadsHighToLow:
          return 'Most Downloaded';
        case DiscoverSortOption.downloadsLowToHigh:
          return 'Least Downloaded';
        case DiscoverSortOption.ratingHighToLow:
          return 'Highest Rated';
        case DiscoverSortOption.ratingLowToHigh:
          return 'Lowest Rated';
        case DiscoverSortOption.nameAZ:
          return 'Name (A-Z)';
        case DiscoverSortOption.nameZA:
          return 'Name (Z-A)';
        case DiscoverSortOption.dateNewest:
          return 'Newest';
        case DiscoverSortOption.dateOldest:
          return 'Oldest';
      }
    }

    return PopupMenuButton<DiscoverSortOption>(
      initialValue: _currentSort,
      onSelected: (sort) {
        setState(() {
          _currentSort = sort;
        });
      },
      itemBuilder:
          (context) =>
              DiscoverSortOption.values
                  .map(
                    (option) => PopupMenuItem<DiscoverSortOption>(
                      value: option,
                      child: Row(
                        children: [
                          if (_currentSort == option)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: ColorConstants.primaryColor,
                            )
                          else
                            SizedBox(width: 18),
                          SizedBox(width: 8),
                          Text(getSortLabel(option)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: ColorConstants.hintGrey.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: ColorConstants.hintGrey),
            SizedBox(width: 6),
            Text(
              getSortLabel(_currentSort),
              style: TextStyle(fontSize: 13, color: ColorConstants.hintGrey),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: ColorConstants.hintGrey),
          ],
        ),
      ),
    );
  }

  /// Builds the main content area (sets list).
  Widget _buildContent() {
    final currentUserId = _auth.currentUser?.uid;

    return ContentStateBuilder(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      errorTitle: 'Error loading sets',
      onRetry: _loadSets,
      isEmpty: _filteredSets.isEmpty,
      emptyIcon: Icons.search_off,
      emptyTitle: 'No sets found',
      emptySubtitle:
          _sets.isEmpty
              ? 'There are no public sets available yet. Be the first to publish one!'
              : 'Try adjusting your filters to find more sets.',
      content: ListView.builder(
        itemCount: _filteredSets.length,
        itemBuilder: (context, index) {
          final set = _filteredSets[index];
          final isOwnSet = set.authorId == currentUserId;

          return DiscoverSetTile(
            set: set,
            isOwnSet: isOwnSet,
            onAddToCollection: isOwnSet ? null : () => _addToCollection(set),
          );
        },
      ),
    );
  }
}
