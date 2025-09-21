import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';
import 'package:buzz5_quiz_app/widgets/custom_app_bar.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/config/logger.dart';
import 'package:buzz5_quiz_app/models/question.dart';
import 'package:buzz5_quiz_app/providers/question_provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';
import 'package:buzz5_quiz_app/pages/question_input_form.dart';

class CreateBoardsPage extends StatefulWidget {
  const CreateBoardsPage({super.key});

  @override
  State<CreateBoardsPage> createState() => _CreateBoardsPageState();
}

class _CreateBoardsPageState extends State<CreateBoardsPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _questionsTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _questionsTabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _questionsTabController.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final questionProvider = Provider.of<QuestionProvider>(
      context,
      listen: false,
    );

    if (authProvider.user != null) {
      questionProvider.loadDraftQuestionsByUser(authProvider.user!.uid);
      questionProvider.loadActiveQuestionsByUser(authProvider.user!.uid);
    }
  }

  Future<void> _navigateToQuestionForm([Question? existingQuestion]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuestionInputForm(existingQuestion: existingQuestion),
      ),
    );

    if (result == true) {
      _loadQuestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.i("CreateBoardsPage built");

    return Scaffold(
      appBar: CustomAppBar(title: "Create", showBackButton: true),
      body: AppBackground(
        child: Column(
          children: [
            Container(
              margin: AppConstants.smallPadding.add(
                AppConstants.smallVerticalPadding,
              ),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? ColorConstants.darkCard
                        : Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              ),
              child: TabBar(
                controller: _mainTabController,
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
                controller: _mainTabController,
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
    );
  }

  Widget _buildBoardsTab() {
    return Padding(
      padding: AppConstants.defaultPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Boards',
                style: AppTextStyles.headlineSmall.copyWith(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? ColorConstants.lightTextColor
                          : ColorConstants.primaryContainerColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to create board form
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Board creation coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    size: AppConstants.extraLargeIconSize + 16,
                    color: ColorConstants.hintGrey,
                  ),
                  const SizedBox(height: AppConstants.defaultSpacing),
                  const Text(
                    'No boards yet',
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Text(
                    'Create your first board to organize your questions',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: ColorConstants.hintGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsTab() {
    return Padding(
      padding: AppConstants.defaultPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sets',
                style: AppTextStyles.headlineSmall.copyWith(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? ColorConstants.lightTextColor
                          : ColorConstants.primaryContainerColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to create set form
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Set creation coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mediumSpacing),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.collections_outlined,
                    size: AppConstants.extraLargeIconSize + 16,
                    color: ColorConstants.hintGrey,
                  ),
                  const SizedBox(height: AppConstants.defaultSpacing),
                  const Text(
                    'No sets yet',
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Text(
                    'Create your first question set to group related questions',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: ColorConstants.hintGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Padding(
      padding: AppConstants.defaultPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Questions',
                style: AppTextStyles.headlineSmall.copyWith(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? ColorConstants.lightTextColor
                          : ColorConstants.primaryContainerColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToQuestionForm(),
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultSpacing),
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? ColorConstants.darkCard
                      : Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
            child: TabBar(
              controller: _questionsTabController,
              labelColor: ColorConstants.primaryColor,
              unselectedLabelColor: ColorConstants.hintGrey,
              indicatorColor: ColorConstants.primaryColor,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Complete'),
                Tab(text: 'Drafts'),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultSpacing),
          Expanded(
            child: TabBarView(
              controller: _questionsTabController,
              children: [
                _buildAllQuestionsTab(),
                _buildCompleteQuestionsTab(),
                _buildDraftQuestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllQuestionsTab() {
    return Consumer<QuestionProvider>(
      builder: (context, questionProvider, child) {
        final allQuestions = [
          ...questionProvider.activeQuestions,
          ...questionProvider.draftQuestions,
        ];

        if (allQuestions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.quiz_outlined,
            title: 'No questions yet',
            subtitle: 'Create your first question to get started',
          );
        }

        return _buildQuestionsList(allQuestions);
      },
    );
  }

  Widget _buildCompleteQuestionsTab() {
    return Consumer<QuestionProvider>(
      builder: (context, questionProvider, child) {
        final activeQuestions = questionProvider.activeQuestions;

        if (activeQuestions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No active questions',
            subtitle: 'Complete and activate questions to see them here',
          );
        }

        return _buildQuestionsList(activeQuestions);
      },
    );
  }

  Widget _buildDraftQuestionsTab() {
    return Consumer<QuestionProvider>(
      builder: (context, questionProvider, child) {
        final draftQuestions = questionProvider.draftQuestions;

        if (draftQuestions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.drafts_outlined,
            title: 'No drafts yet',
            subtitle: 'Save questions as drafts while you work on them',
          );
        }

        return _buildQuestionsList(draftQuestions);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppConstants.extraLargeIconSize + 16,
            color: ColorConstants.hintGrey,
          ),
          const SizedBox(height: AppConstants.defaultSpacing),
          Text(
            title,
            style: AppTextStyles.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.smallSpacing),
          Text(
            subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: ColorConstants.hintGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsList(List<Question> questions) {
    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.cardSpacing),
          child: Card(
            child: Padding(
              padding: AppConstants.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          question.questionName,
                          style: AppTextStyles.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: AppConstants.extraSmallPadding,
                        decoration: BoxDecoration(
                          color:
                              question.isActive
                                  ? ColorConstants.success.withValues(
                                    alpha: 0.1,
                                  )
                                  : ColorConstants.warning.withValues(
                                    alpha: 0.1,
                                  ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.smallRadius,
                          ),
                        ),
                        child: Text(
                          question.isActive ? 'Active' : 'Draft',
                          style: AppTextStyles.labelSmall.copyWith(
                            color:
                                question.isActive
                                    ? ColorConstants.success
                                    : ColorConstants.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Text(
                    question.questionText,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.smallSpacing),
                  Row(
                    children: [
                      Container(
                        padding: AppConstants.extraSmallPadding,
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.smallRadius,
                          ),
                        ),
                        child: Text(
                          question.category,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.smallSpacing),
                      Text(
                        '${question.points} points',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ColorConstants.hintGrey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        question.difficulty.name.toUpperCase(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _getDifficultyColor(question.difficulty),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _navigateToQuestionForm(question),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: AppConstants.smallSpacing),
                      OutlinedButton(
                        onPressed: () {
                          // TODO: Add delete functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Delete functionality coming soon!',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return ColorConstants.success;
      case Difficulty.medium:
        return ColorConstants.warning;
      case Difficulty.hard:
        return ColorConstants.errorColor;
    }
  }
}
