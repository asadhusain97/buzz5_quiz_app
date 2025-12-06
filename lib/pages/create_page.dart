import 'package:buzz5_quiz_app/models/all_enums.dart';
import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/models/set_model.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/widgets/stat_displays.dart';
import 'package:buzz5_quiz_app/widgets/standard_menu_item.dart';
import 'package:buzz5_quiz_app/pages/create_set_page.dart';
import 'package:buzz5_quiz_app/services/set_service.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Firebase service
  final SetService _setService = SetService();

  // Data state
  List<SetModel> _sets = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter and sort state
  String _sortBy = 'Creation Date: Newest first';
  final Map<String, dynamic> _activeFilters = {};

  // Filter dropdown states
  SetStatus? _statusFilter;
  final List<String> _selectedTags = [];
  String _nameSearch = '';
  String _creatorSearch = '';

  // Selection state
  final Set<String> _selectedSetIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadSets();
  }

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
            duration: Duration(
              seconds: 10,
            ), // Long duration, will dismiss on completion
          ),
        );
      }

      // Duplicate the set
      await _setService.duplicateSet(set.id);

      // Reload sets to show the new duplicate
      await _loadSets();

      if (mounted) {
        // Dismiss loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message
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
        // Dismiss loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate set: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  bool get _isSetView => _currentTabIndex == 0;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock boards data
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

  List<SetModel> get _filteredSets {
    List<SetModel> filtered = _sets;

    // Apply filters based on _activeFilters
    if (_statusFilter != null) {
      filtered = filtered.where((set) => set.status == _statusFilter).toList();
    }

    if (_nameSearch.isNotEmpty) {
      filtered =
          filtered
              .where(
                (set) =>
                    set.name.toLowerCase().contains(_nameSearch.toLowerCase()),
              )
              .toList();
    }

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

  List<BoardModel> get _filteredBoards {
    List<BoardModel> filtered = _boards;

    // Apply filters based on _activeFilters
    if (_statusFilter != null) {
      BoardStatus boardStatus =
          _statusFilter == SetStatus.complete
              ? BoardStatus.complete
              : BoardStatus.draft;
      filtered =
          filtered.where((board) => board.status == boardStatus).toList();
    }

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

  void _clearFilters() {
    setState(() {
      _activeFilters.clear();
      _statusFilter = null;
      _selectedTags.clear();
      _nameSearch = '';
      _creatorSearch = '';
    });
  }

  void _showStatusFilterDropdown(BuildContext context, RenderBox renderBox) {
    showDialog(
      context: context,
      builder: (context) {
        SetStatus? selectedStatus = _statusFilter;

        return StatefulBuilder(
          builder: (context, setDialogState) {
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
            constraints: BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24),

                // Header with title, description and action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Sets and Boards',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? ColorConstants.lightTextColor
                                          : ColorConstants.darkTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create, edit and organize your quiz questions in sets and boards.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: ColorConstants.hintGrey),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 24),
                        Row(
                          children: [
                            if (_isSetView) ...[
                              OutlinedButton.icon(
                                icon: Icon(Icons.upload_file, size: 18),
                                label: Text('Import'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImportSetPage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? ColorConstants.lightTextColor
                                          : ColorConstants.darkTextColor,
                                  side: BorderSide(
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? ColorConstants.lightTextColor
                                                .withValues(alpha: 0.3)
                                            : ColorConstants.darkTextColor
                                                .withValues(alpha: 0.3),
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
                              SizedBox(width: 12),
                            ],
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
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
                ),

                SizedBox(height: 24),

                // Tabs
                TabBar(
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
                  labelPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: [Tab(text: 'Sets'), Tab(text: 'Boards')],
                ),

                SizedBox(height: 16),

                // Filter and Sort Bar
                Row(
                  children: [
                    // Filter chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Filter Icon
                            Icon(
                              Icons.filter_list,
                              size: 18,
                              color: ColorConstants.hintGrey,
                            ),
                            SizedBox(width: 8),

                            // Status Filter Chip
                            Builder(
                              builder:
                                  (context) => InkWell(
                                    onTap: () {
                                      final renderBox =
                                          context.findRenderObject()
                                              as RenderBox;
                                      _showStatusFilterDropdown(
                                        context,
                                        renderBox,
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _statusFilter != null
                                                ? ColorConstants.primaryColor
                                                    .withValues(alpha: 0.15)
                                                : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              _statusFilter != null
                                                  ? ColorConstants.primaryColor
                                                  : ColorConstants.hintGrey
                                                      .withValues(alpha: 0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Status',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  _statusFilter != null
                                                      ? ColorConstants
                                                          .primaryColor
                                                      : ColorConstants.hintGrey,
                                              fontWeight:
                                                  _statusFilter != null
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          if (_statusFilter != null) ...[
                                            Text(
                                              ': ${_activeFilters['Status']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    ColorConstants.primaryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 18,
                                            color:
                                                _statusFilter != null
                                                    ? ColorConstants
                                                        .primaryColor
                                                    : ColorConstants.hintGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ),

                            SizedBox(width: 8),

                            // Tags Filter Chip (only for Sets)
                            if (_isSetView) ...[
                              Builder(
                                builder:
                                    (context) => InkWell(
                                      onTap: () {
                                        final renderBox =
                                            context.findRenderObject()
                                                as RenderBox;
                                        _showTagsFilterDropdown(
                                          context,
                                          renderBox,
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _selectedTags.isNotEmpty
                                                  ? ColorConstants.primaryColor
                                                      .withValues(alpha: 0.15)
                                                  : Colors.transparent,
                                          border: Border.all(
                                            color:
                                                _selectedTags.isNotEmpty
                                                    ? ColorConstants
                                                        .primaryColor
                                                    : ColorConstants.hintGrey
                                                        .withValues(alpha: 0.3),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Tags',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    _selectedTags.isNotEmpty
                                                        ? ColorConstants
                                                            .primaryColor
                                                        : ColorConstants
                                                            .hintGrey,
                                                fontWeight:
                                                    _selectedTags.isNotEmpty
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                              ),
                                            ),
                                            if (_selectedTags.isNotEmpty) ...[
                                              Text(
                                                ': ${_selectedTags.length} selected',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      ColorConstants
                                                          .primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 18,
                                              color:
                                                  _selectedTags.isNotEmpty
                                                      ? ColorConstants
                                                          .primaryColor
                                                      : ColorConstants.hintGrey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ),
                              SizedBox(width: 8),
                            ],

                            // Name Search Chip
                            InkWell(
                              onTap: () => _showNameSearchDialog(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _nameSearch.isNotEmpty
                                          ? ColorConstants.primaryColor
                                              .withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        _nameSearch.isNotEmpty
                                            ? ColorConstants.primaryColor
                                            : ColorConstants.hintGrey
                                                .withValues(alpha: 0.3),
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
                                          _nameSearch.isNotEmpty
                                              ? ColorConstants.primaryColor
                                              : ColorConstants.hintGrey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            _nameSearch.isNotEmpty
                                                ? ColorConstants.primaryColor
                                                : ColorConstants.hintGrey,
                                        fontWeight:
                                            _nameSearch.isNotEmpty
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    if (_nameSearch.isNotEmpty) ...[
                                      Text(
                                        ': $_nameSearch',
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
                            ),

                            SizedBox(width: 8),

                            // Creator Search Chip
                            InkWell(
                              onTap: () => _showCreatorSearchDialog(context),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _creatorSearch.isNotEmpty
                                          ? ColorConstants.primaryColor
                                              .withValues(alpha: 0.15)
                                          : Colors.transparent,
                                  border: Border.all(
                                    color:
                                        _creatorSearch.isNotEmpty
                                            ? ColorConstants.primaryColor
                                            : ColorConstants.hintGrey
                                                .withValues(alpha: 0.3),
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
                                          _creatorSearch.isNotEmpty
                                              ? ColorConstants.primaryColor
                                              : ColorConstants.hintGrey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Creator',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            _creatorSearch.isNotEmpty
                                                ? ColorConstants.primaryColor
                                                : ColorConstants.hintGrey,
                                        fontWeight:
                                            _creatorSearch.isNotEmpty
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    if (_creatorSearch.isNotEmpty) ...[
                                      Text(
                                        ': $_creatorSearch',
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
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // Sort Dropdown
                    PopupMenuButton<String>(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ColorConstants.hintGrey.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort,
                              size: 16,
                              color: ColorConstants.hintGrey,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _sortBy,
                              style: TextStyle(
                                fontSize: 13,
                                color: ColorConstants.hintGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'Name: A → Z',
                              child: Text('Name: A → Z'),
                            ),
                            PopupMenuItem(
                              value: 'Name: Z → A',
                              child: Text('Name: Z → A'),
                            ),
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
                    ),

                    // Clear Filters
                    if (_activeFilters.isNotEmpty) ...[
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

                SizedBox(height: 16),

                // Sets/Boards List
                Expanded(
                  child:
                      _isSetView
                          ? (_isLoading
                              ? Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.primaryColor,
                                ),
                              )
                              : _errorMessage != null
                              ? Center(
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
                                      onPressed: _loadSets,
                                      child: Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                              : _filteredSets.isEmpty
                              ? Center(
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
                              )
                              : ListView.builder(
                                itemCount: _filteredSets.length,
                                itemBuilder: (context, index) {
                                  final set = _filteredSets[index];
                                  return SetListItemTile(
                                    set: set,
                                    isSelected: _selectedSetIds.contains(
                                      set.id,
                                    ),
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
                                              builder:
                                                  (context) => NewSetPage(
                                                    existingSet: set,
                                                  ),
                                            ),
                                          )
                                          .then((_) => _loadSets());
                                    },
                                    onDuplicate: () {
                                      _duplicateSet(set);
                                    },
                                    onDelete: () async {
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
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        ColorConstants
                                                            .errorColor,
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
                              ))
                          : (_filteredBoards.isEmpty
                              ? Center(
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
                              )
                              : ListView.builder(
                                itemCount: _filteredBoards.length,
                                itemBuilder: (context, index) {
                                  final board = _filteredBoards[index];
                                  return BoardListItemTile(
                                    board: board,
                                    isSelected: _selectedSetIds.contains(
                                      board.id,
                                    ),
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
                              )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SetListItemTile extends StatelessWidget {
  final SetModel set;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const SetListItemTile({
    super.key,
    required this.set,
    required this.isSelected,
    required this.onSelectionChanged,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
  });

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

  String _getDifficultyLabel(DifficultyLevel? difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDraft = set.status == SetStatus.draft;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.darkCard
              : ColorConstants.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // Vertical draft indicator on the left edge (40% thinner: 28 * 0.6 = 17px)
          if (isDraft)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 17,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'DRAFT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Main content
          Padding(
            padding: EdgeInsets.only(
              left: isDraft ? 29.0 : 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 16.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox aligned with content
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged(value ?? false),
                  activeColor: ColorConstants.primaryColor,
                ),

                SizedBox(width: 12),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Set Name with Rating and Downloads in the same row
                      Row(
                        children: [
                          // Set Name
                          Expanded(
                            child: Text(
                              set.name,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? ColorConstants.lightTextColor
                                        : ColorConstants.darkTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          SizedBox(width: 12),

                          // Rating
                          RatingDisplay(rating: set.rating),

                          SizedBox(width: 12),

                          // Downloads
                          DownloadDisplay(downloads: set.downloads),
                        ],
                      ),

                      SizedBox(height: 4),

                      // Description
                      Text(
                        set.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ColorConstants.hintGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 12),

                      // Difficulty and Tags Row with spacing
                      Row(
                        children: [
                          // Difficulty chip (no color)
                          if (set.difficulty != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstants.hintGrey.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: ColorConstants.hintGrey.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getDifficultyLabel(set.difficulty),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? ColorConstants.lightTextColor
                                          : ColorConstants.darkTextColor,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ), // Space between difficulty and tags
                          ],

                          // Tag chips
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                ...set.tags
                                    .take(3)
                                    .map(
                                      (tag) => Chip(
                                        label: Text(
                                          _formatTagName(tag),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(fontSize: 11),
                                        ),
                                        backgroundColor: ColorConstants
                                            .primaryColor
                                            .withValues(alpha: 0.2),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 0,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                // Show "+N" chip if there are more tags
                                if (set.tags.length > 3)
                                  Chip(
                                    label: Text(
                                      '+${set.tags.length - 3}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        fontSize: 11,
                                        color: ColorConstants.primaryColor,
                                      ),
                                    ),
                                    backgroundColor: ColorConstants.primaryColor
                                        .withValues(alpha: 0.1),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 0,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8),

                // Actions menu, aligned
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? ColorConstants.lightTextColor
                            : ColorConstants.darkTextColor,
                  ),
                  itemBuilder:
                      (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: StandardMenuItem(
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'duplicate',
                          child: StandardMenuItem(
                            icon: Icons.copy,
                            label: 'Duplicate',
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: StandardMenuItem(
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ),
                      ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'duplicate':
                        onDuplicate?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder page for Import Set
class ImportSetPage extends StatelessWidget {
  const ImportSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import Set', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
      ),
      body: Center(
        child: Text(
          'Import Set Page - Coming Soon',
          style: AppTextStyles.titleMedium.copyWith(
            color: ColorConstants.hintGrey,
          ),
        ),
      ),
    );
  }
}

// Placeholder page for Create New Board
class CreateNewBoardPage extends StatelessWidget {
  const CreateNewBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Board', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
      ),
      body: Center(
        child: Text(
          'Create New Board Page - Coming Soon',
          style: AppTextStyles.titleMedium.copyWith(
            color: ColorConstants.hintGrey,
          ),
        ),
      ),
    );
  }
}

// Board List Item Tile
class BoardListItemTile extends StatelessWidget {
  final BoardModel board;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const BoardListItemTile({
    super.key,
    required this.board,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? ColorConstants.darkCard
              : ColorConstants.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opening ${board.name}...')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelectionChanged(value ?? false),
                activeColor: ColorConstants.primaryColor,
              ),

              SizedBox(width: 12),

              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Board Name and Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            board.name,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? ColorConstants.lightTextColor
                                      : ColorConstants.darkTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                board.status == BoardStatus.complete
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            board.status == BoardStatus.complete
                                ? 'Complete'
                                : 'Draft',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  board.status == BoardStatus.complete
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),

                    // Description
                    Text(
                      board.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ColorConstants.hintGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 8),

                    // Metadata Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sets count
                        Icon(
                          Icons.layers,
                          size: 14,
                          color: ColorConstants.hintGrey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${board.setCount}/5 sets',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        // Last modified
                        Icon(
                          Icons.edit_calendar,
                          size: 14,
                          color: ColorConstants.hintGrey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Modified ${_getRelativeTime(board.modifiedDate)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? ColorConstants.lightTextColor
                          : ColorConstants.darkTextColor,
                ),
                itemBuilder:
                    (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: ColorConstants.primaryColor,
                            ),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy,
                              size: 20,
                              color: ColorConstants.secondaryColor,
                            ),
                            SizedBox(width: 12),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: ColorConstants.errorColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: ColorConstants.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                onSelected: (String value) {
                  AppLogger.i('Selected: $value for board: ${board.name}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value: ${board.name}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
