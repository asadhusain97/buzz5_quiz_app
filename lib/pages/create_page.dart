import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/set_model.dart' as model;
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

class _CreatePageState extends State<CreatePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Filter and sort state
  String _sortBy = 'Creation Date';
  bool _sortAscending = false;
  final Map<String, dynamic> _activeFilters = {};

  // Selection state
  final Set<String> _selectedSetIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

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
      description: 'A comprehensive collection of questions covering major historical events from ancient civilizations to modern times.',
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
      description: 'Questions about scientific discoveries, inventions, and technological advancements.',
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
      description: 'Test your knowledge of countries, capitals, and landmarks around the world.',
      category: 'Geography',
      attachedBoardNames: [],
      status: model.SetStatus.draft,
      authorName: 'Tom Brown',
      hasMedia: true,
      tags: ['geography', 'travel'],
      lastModified: DateTime.now().subtract(Duration(hours: 3)),
    ),
  ];

  List<QuizSet> get _filteredSets {
    List<QuizSet> filtered = _sets;

    // Filter by tab
    if (_currentTabIndex == 1) {
      filtered = filtered.where((set) => set.status == model.SetStatus.complete).toList();
    } else if (_currentTabIndex == 2) {
      filtered = filtered.where((set) => set.status == model.SetStatus.draft).toList();
    }

    // Apply additional filters
    // TODO: Implement filtering logic based on _activeFilters

    return filtered;
  }

  void _showAddFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AddFilterDialog(
        onFilterAdded: (filterType, filterValue) {
          setState(() {
            _activeFilters[filterType] = filterValue;
          });
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _activeFilters.clear();
    });
  }

  void _removeFilter(String filterKey) {
    setState(() {
      _activeFilters.remove(filterKey);
    });
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
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? ColorConstants.lightTextColor
                                      : ColorConstants.darkTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create, manage and organize your quiz question sets',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: ColorConstants.hintGrey,
                                ),
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
                                foregroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? ColorConstants.lightTextColor
                                    : ColorConstants.darkTextColor,
                                side: BorderSide(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? ColorConstants.lightTextColor.withValues(alpha: 0.3)
                                      : ColorConstants.darkTextColor.withValues(alpha: 0.3),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                minimumSize: Size(110, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: Icon(Icons.add, size: 18),
                              label: Text('New Set'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateNewSetPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstants.primaryColor,
                                foregroundColor: ColorConstants.lightTextColor,
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                minimumSize: Size(110, 40),
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
                  labelColor: Theme.of(context).brightness == Brightness.dark
                      ? ColorConstants.lightTextColor
                      : ColorConstants.darkTextColor,
                  unselectedLabelColor: ColorConstants.hintGrey,
                  indicatorColor: ColorConstants.primaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  labelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Complete'),
                    Tab(text: 'Draft'),
                  ],
                ),

                SizedBox(height: 16),

                // Filter and Sort Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Row: Add Filter and Sort controls
                    Row(
                      children: [
                        // Add Filter Button
                        OutlinedButton.icon(
                          icon: Icon(Icons.add, size: 16),
                          label: Text('Add Filter'),
                          onPressed: _showAddFilterDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorConstants.hintGrey,
                            side: BorderSide(color: ColorConstants.hintGrey.withValues(alpha: 0.3)),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),

                        Spacer(),

                        // Sort Dropdown
                        PopupMenuButton<String>(
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
                                  'Sort: $_sortBy ${_sortAscending ? '↑' : '↓'}',
                                  style: TextStyle(fontSize: 13, color: ColorConstants.hintGrey),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'Creation Date',
                              child: Text('Creation Date'),
                            ),
                            PopupMenuItem(
                              value: 'Name',
                              child: Text('Name'),
                            ),
                            PopupMenuItem(
                              value: 'Difficulty',
                              child: Text('Difficulty'),
                            ),
                            PopupMenuItem(
                              value: 'Downloads',
                              child: Text('Downloads'),
                            ),
                            PopupMenuItem(
                              value: 'Rating',
                              child: Text('Rating'),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                                  SizedBox(width: 8),
                                  Text(_sortAscending ? 'Ascending' : 'Descending'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            setState(() {
                              if (value == 'toggle') {
                                _sortAscending = !_sortAscending;
                              } else {
                                _sortBy = value;
                              }
                            });
                          },
                        ),

                        // Clear Filters
                        if (_activeFilters.isNotEmpty) ...[
                          SizedBox(width: 12),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(
                              'Clear Filters',
                              style: TextStyle(color: ColorConstants.primaryColor),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Second Row: Active Filter Chips (wrapping)
                    if (_activeFilters.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activeFilters.entries.map((entry) {
                          return Chip(
                            label: Text('${entry.key}: ${entry.value}'),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () => _removeFilter(entry.key),
                            backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
                            side: BorderSide(color: ColorConstants.primaryColor.withValues(alpha: 0.3)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 16),

                // Sets List
                Expanded(
                  child: _filteredSets.isEmpty
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
                            );
                          },
                        ),
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
      color: Theme.of(context).brightness == Brightness.dark
          ? ColorConstants.darkCard
          : ColorConstants.surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to set detail/edit page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${set.name}...')),
          );
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness == Brightness.dark
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
                          ...set.attachedBoardNames.take(3).map((boardName) => Chip(
                            label: Text(
                              boardName,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.2),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )),
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
                              backgroundColor: ColorConstants.primaryColor.withValues(alpha: 0.1),
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? ColorConstants.lightTextColor
                      : ColorConstants.darkTextColor,
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: ColorConstants.primaryColor),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20, color: ColorConstants.secondaryColor),
                        SizedBox(width: 12),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: ColorConstants.errorColor),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: ColorConstants.errorColor)),
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

// Add Filter Dialog
class AddFilterDialog extends StatefulWidget {
  final Function(String, dynamic) onFilterAdded;

  const AddFilterDialog({super.key, required this.onFilterAdded});

  @override
  State<AddFilterDialog> createState() => _AddFilterDialogState();
}

class _AddFilterDialogState extends State<AddFilterDialog> {
  String? _selectedFilterType;
  dynamic _filterValue;

  final List<String> _filterTypes = [
    'Tags',
    'Creation Date',
    'Difficulty',
    'Rating',
    'Downloads',
    'Author Name',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Filter'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select filter type:', style: AppTextStyles.labelMedium),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: ColorConstants.hintGrey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButton<String>(
                value: _selectedFilterType,
                hint: Text('Choose a filter'),
                isExpanded: true,
                underline: SizedBox(),
                items: _filterTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilterType = value;
                    _filterValue = null;
                  });
                },
              ),
            ),
            if (_selectedFilterType != null) ...[
              SizedBox(height: 20),
              _buildFilterValueInput(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _filterValue != null
              ? () {
                  widget.onFilterAdded(_selectedFilterType!, _filterValue);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            foregroundColor: ColorConstants.lightTextColor,
          ),
          child: Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildFilterValueInput() {
    switch (_selectedFilterType) {
      case 'Tags':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select tags:', style: AppTextStyles.labelMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['History', 'Science', 'Math', 'Geography', 'Pop Culture'].map((tag) {
                return FilterChip(
                  label: Text(tag),
                  selected: _filterValue == tag,
                  onSelected: (selected) {
                    setState(() {
                      _filterValue = selected ? tag : null;
                    });
                  },
                  selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        );
      case 'Difficulty':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select difficulty:', style: AppTextStyles.labelMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Easy', 'Medium', 'Hard'].map((difficulty) {
                return FilterChip(
                  label: Text(difficulty),
                  selected: _filterValue == difficulty,
                  onSelected: (selected) {
                    setState(() {
                      _filterValue = selected ? difficulty : null;
                    });
                  },
                  selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        );
      case 'Rating':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minimum rating:', style: AppTextStyles.labelMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5].map((rating) {
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$rating'),
                      Icon(Icons.star, size: 14),
                      Text('+'),
                    ],
                  ),
                  selected: _filterValue == rating,
                  onSelected: (selected) {
                    setState(() {
                      _filterValue = selected ? rating : null;
                    });
                  },
                  selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        );
      case 'Downloads':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Minimum downloads:', style: AppTextStyles.labelMedium),
            SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _filterValue = int.tryParse(value);
                });
              },
            ),
          ],
        );
      case 'Author Name':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author name:', style: AppTextStyles.labelMedium),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter author name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _filterValue = value.isNotEmpty ? value : null;
                });
              },
            ),
          ],
        );
      case 'Creation Date':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select date range:', style: AppTextStyles.labelMedium),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Last 7 days', 'Last 30 days', 'Last 90 days', 'This year'].map((range) {
                return FilterChip(
                  label: Text(range),
                  selected: _filterValue == range,
                  onSelected: (selected) {
                    setState(() {
                      _filterValue = selected ? range : null;
                    });
                  },
                  selectedColor: ColorConstants.primaryColor.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
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
