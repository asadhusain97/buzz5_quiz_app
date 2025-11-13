import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/set_model.dart' as model;
import 'package:buzz5_quiz_app/models/board_model.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';

// Simple Set class for UI mock data
class QuizSet {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> attachedBoardNames;
  final model.SetStatus status;
  final String authorName;
  final bool hasMedia;
  final List<String> tags;
  final DateTime lastModified;

  QuizSet({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.attachedBoardNames,
    required this.status,
    required this.authorName,
    required this.hasMedia,
    required this.tags,
    required this.lastModified,
  });
}

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Filter and sort state
  String _sortBy = 'Creation Date: Newest first';
  final Map<String, dynamic> _activeFilters = {};

  // Filter dropdown states
  model.SetStatus? _statusFilter;
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
  }

  bool get _isSetView => _currentTabIndex == 0;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock data
  final List<QuizSet> _sets = [
    QuizSet(
      id: '1',
      name: 'World History Trivia',
      description:
          'A comprehensive collection of questions covering major historical events from ancient civilizations to modern times.',
      category: 'History',
      attachedBoardNames: ['General Knowledge', 'Education'],
      status: model.SetStatus.complete,
      authorName: 'John Doe',
      hasMedia: true,
      tags: ['history', 'trivia', 'education'],
      lastModified: DateTime.now().subtract(Duration(days: 2)),
    ),
    QuizSet(
      id: '2',
      name: 'Science & Technology',
      description:
          'Questions about scientific discoveries, inventions, and technological advancements.',
      category: 'Science',
      attachedBoardNames: ['STEM', 'Tech Quiz', 'Innovation'],
      status: model.SetStatus.complete,
      authorName: 'Jane Smith',
      hasMedia: false,
      tags: ['science', 'tech'],
      lastModified: DateTime.now().subtract(Duration(days: 5)),
    ),
    QuizSet(
      id: '3',
      name: 'Pop Culture 2024',
      description: 'Latest trends, movies, music, and entertainment from 2024.',
      category: 'Entertainment',
      attachedBoardNames: ['Fun', 'Entertainment'],
      status: model.SetStatus.complete,
      authorName: 'Mike Johnson',
      hasMedia: true,
      tags: ['pop culture', 'entertainment'],
      lastModified: DateTime.now().subtract(Duration(hours: 12)),
    ),
    QuizSet(
      id: '4',
      name: 'Math Fundamentals',
      description: 'Basic algebra and geometry questions for students.',
      category: 'Mathematics',
      attachedBoardNames: ['Education'],
      status: model.SetStatus.draft,
      authorName: 'Sarah Williams',
      hasMedia: false,
      tags: ['math', 'education'],
      lastModified: DateTime.now().subtract(Duration(days: 1)),
    ),
    QuizSet(
      id: '5',
      name: 'Geography Quiz',
      description:
          'Test your knowledge of countries, capitals, and landmarks around the world.',
      category: 'Geography',
      attachedBoardNames: [],
      status: model.SetStatus.draft,
      authorName: 'Tom Brown',
      hasMedia: true,
      tags: ['geography', 'travel'],
      lastModified: DateTime.now().subtract(Duration(hours: 3)),
    ),
  ];

  // Mock boards data
  final List<BoardModel> _boards = [
    BoardModel(
      id: 'b1',
      name: 'General Knowledge Championship',
      description:
          'A comprehensive board covering history, science, and pop culture',
      authorName: 'John Doe',
      authorId: 'user1',
      rating: 4.5,
      downloads: 1200,
      creationDate: DateTime.now().subtract(Duration(days: 10)),
      modifiedDate: DateTime.now().subtract(Duration(days: 2)),
      sets: [],
    ),
    BoardModel(
      id: 'b2',
      name: 'Science & Technology Mastery',
      description:
          'Deep dive into scientific concepts and technological innovations',
      authorName: 'Jane Smith',
      authorId: 'user2',
      rating: 4.8,
      downloads: 2500,
      creationDate: DateTime.now().subtract(Duration(days: 20)),
      modifiedDate: DateTime.now().subtract(Duration(days: 5)),
      sets: [],
    ),
    BoardModel(
      id: 'b3',
      name: 'Entertainment Extravaganza',
      description: 'Movies, music, TV shows, and celebrity trivia',
      authorName: 'Mike Johnson',
      authorId: 'user3',
      rating: 4.2,
      downloads: 800,
      creationDate: DateTime.now().subtract(Duration(days: 3)),
      modifiedDate: DateTime.now().subtract(Duration(hours: 10)),
      sets: [],
    ),
    BoardModel(
      id: 'b4',
      name: 'World Geography Explorer',
      description: 'Countries, capitals, landmarks, and geographical features',
      authorName: 'Sarah Williams',
      authorId: 'user4',
      rating: 4.6,
      downloads: 1500,
      creationDate: DateTime.now().subtract(Duration(days: 15)),
      modifiedDate: DateTime.now().subtract(Duration(days: 1)),
      sets: [],
    ),
    BoardModel(
      id: 'b5',
      name: 'History Through Ages',
      description: 'From ancient civilizations to modern world events',
      authorName: 'Tom Brown',
      authorId: 'user5',
      rating: 4.7,
      downloads: 1800,
      creationDate: DateTime.now().subtract(Duration(days: 30)),
      modifiedDate: DateTime.now().subtract(Duration(hours: 5)),
      sets: [],
    ),
  ];

  List<QuizSet> get _filteredSets {
    List<QuizSet> filtered = _sets;

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
                (set) => set.tags.any((tag) => _selectedTags.contains(tag)),
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
          _statusFilter == model.SetStatus.complete
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
        model.SetStatus? selectedStatus = _statusFilter;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildRadioOption(String label, model.SetStatus? value) {
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
                  buildRadioOption('Complete', model.SetStatus.complete),
                  buildRadioOption('Draft', model.SetStatus.draft),
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
                            selectedStatus == model.SetStatus.complete
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
                                'Question sets',
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
                                'Create, manage and organize your quiz question sets',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: ColorConstants.hintGrey),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 24),
                        Row(
                          children: [
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
                                                ? CreateNewSetPage()
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
                          ? (_filteredSets.isEmpty
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
  final QuizSet set;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const SetListItemTile({
    super.key,
    required this.set,
    required this.isSelected,
    required this.onSelectionChanged,
  });

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
          // TODO: Navigate to set detail/edit page
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opening ${set.name}...')));
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
                    // Set Name
                    Row(
                      children: [
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
                        if (set.hasMedia) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.image,
                            size: 16,
                            color: ColorConstants.primaryColor,
                          ),
                        ],
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

                    SizedBox(height: 8),

                    // Board Chips
                    if (set.attachedBoardNames.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Show first 2-3 chips
                          ...set.attachedBoardNames
                              .take(3)
                              .map(
                                (boardName) => Chip(
                                  label: Text(
                                    boardName,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: ColorConstants.primaryColor
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
                          // Show "+N more" chip if there are more boards
                          if (set.attachedBoardNames.length > 3)
                            Chip(
                              label: Text(
                                '+${set.attachedBoardNames.length - 3} more',
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

                    if (set.attachedBoardNames.isEmpty)
                      Text(
                        'Not attached to any boards',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ColorConstants.hintGrey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
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
                  AppLogger.i('Selected: $value for set: ${set.name}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$value: ${set.name}')),
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

// Placeholder page for Create New Set
class CreateNewSetPage extends StatelessWidget {
  const CreateNewSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Set', style: AppTextStyles.titleBig),
        backgroundColor: ColorConstants.primaryContainerColor,
      ),
      body: Center(
        child: Text(
          'Create New Set Page - Coming Soon',
          style: AppTextStyles.titleMedium.copyWith(
            color: ColorConstants.hintGrey,
          ),
        ),
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

  String _getDifficultyLabel(model.DifficultyLevel difficulty) {
    switch (difficulty) {
      case model.DifficultyLevel.easy:
        return 'Easy';
      case model.DifficultyLevel.medium:
        return 'Medium';
      case model.DifficultyLevel.hard:
        return 'Hard';
    }
  }

  Color _getDifficultyColor(model.DifficultyLevel difficulty) {
    switch (difficulty) {
      case model.DifficultyLevel.easy:
        return Colors.green;
      case model.DifficultyLevel.medium:
        return Colors.orange;
      case model.DifficultyLevel.hard:
        return Colors.red;
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
                      children: [
                        // Sets count
                        Icon(
                          Icons.layers,
                          size: 14,
                          color: ColorConstants.hintGrey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${board.sets.length}/5 sets',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Difficulty
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(
                              board.difficulty,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getDifficultyLabel(board.difficulty),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getDifficultyColor(board.difficulty),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Rating
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        SizedBox(width: 2),
                        Text(
                          board.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ColorConstants.hintGrey,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 12),
                        // Downloads
                        Icon(
                          Icons.download,
                          size: 14,
                          color: ColorConstants.hintGrey,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${board.downloads}',
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
