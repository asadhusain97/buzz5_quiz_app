import 'package:buzz5_quiz_app/config/app_dimensions.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/providers/question_done.dart';
import 'package:buzz5_quiz_app/providers/player_provider.dart';
import 'package:buzz5_quiz_app/pages/question_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A widget that displays a set of questions with their point values in a quiz format.
///
/// Features:
/// - Displays question set name as clickable header
/// - Shows questions as circular buttons with point values
/// - Visual feedback for answered questions (checkmark)
/// - Popup with set information and examples
/// - Smooth page transitions to question view
class QuestionSetWidget extends StatelessWidget {
  /// The question data for this set
  final List<Map<String, dynamic>> data;

  const QuestionSetWidget({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Sort questions by point value
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => a['points'].compareTo(b['points']));

    return Container(
      width: 150,
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSetNameHeader(context),
          const SizedBox(height: 20.0),
          _buildQuestionButtons(context, sortedData),
        ],
      ),
    );
  }

  /// Builds the clickable set name header
  Widget _buildSetNameHeader(BuildContext context) {
    return InkWell(
      onTap: () => _showSetInfoPopup(context),
      borderRadius: BorderRadius.circular(8.0),
      hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Container(
        width: 150,
        height: 80,
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1.0,
          ),
          borderRadius: AppDimensions.smallBorderRadius,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                data.isNotEmpty ? data[0]['set_name'] : 'No setname present',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the column of question buttons
  Widget _buildQuestionButtons(
    BuildContext context,
    List<Map<String, dynamic>> sortedData,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sortedData.map((item) => _buildQuestionButton(context, item)).toList(),
    );
  }

  /// Builds individual question button with answered state (optimized)
  Widget _buildQuestionButton(BuildContext context, Map<String, dynamic> item) {
    final String questionId = "${item['qid']}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Consumer<AnsweredQuestionsProvider>(
        builder: (context, answeredProvider, child) {
          final bool isAnswered = answeredProvider.isQuestionAnswered(questionId);

          // Use RepaintBoundary to optimize repaints of individual buttons
          return RepaintBoundary(
            child: isAnswered
                ? _buildAnsweredButton(context, item, questionId)
                : _buildUnansweredButton(context, item, questionId),
          );
        },
      ),
    );
  }

  /// Builds button for answered questions (with checkmark)
  Widget _buildAnsweredButton(
    BuildContext context,
    Map<String, dynamic> item,
    String questionId,
  ) {
    return ElevatedButton(
      onPressed: () => _navigateToQuestion(context, item, questionId),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        backgroundColor: ColorConstants.transparent,
        shadowColor: ColorConstants.transparent,
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check,
                color: ColorConstants.answeredQuestion,
                size: 30,
              ),
              Text(
                item['points'].toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ColorConstants.answeredQuestion,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds button for unanswered questions
  Widget _buildUnansweredButton(
    BuildContext context,
    Map<String, dynamic> item,
    String questionId,
  ) {
    return ElevatedButton(
      onPressed: () => _navigateToQuestion(context, item, questionId),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Text(
            item['points'].toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  /// Navigates to the question page with smooth transition
  void _navigateToQuestion(
    BuildContext context,
    Map<String, dynamic> item,
    String questionId,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const QuestionPage(),
        settings: RouteSettings(
          arguments: {
            'qid': questionId,
            'setname': item['set_name'],
            'question': item['question'],
            'answer': item['answer'],
            'score': item['points'],
            'qstn_media': item['qstn_media'] ?? "",
            'ans_media': item['ans_media'] ?? "",
            'playerList': Provider.of<PlayerProvider>(context, listen: false)
                .playerList
                .map((player) => player.name)
                .toList(),
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      ),
    );
  }

  /// Shows popup with set information
  void _showSetInfoPopup(BuildContext context) {
    if (data.isEmpty) return;

    final setData = data[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPopupHeader(context, setData),
                const SizedBox(height: 24),
                _buildPopupExplanation(context, setData),
                const SizedBox(height: 24),
                _buildPopupCloseButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds popup header
  Widget _buildPopupHeader(BuildContext context, Map<String, dynamic> setData) {
    return Center(
      child: Text(
        setData['set_name'] ?? 'Category Info',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  /// Builds popup explanation section
  Widget _buildPopupExplanation(BuildContext context, Map<String, dynamic> setData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explanation',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _truncateText(
            setData['set_explanation'] ?? 'No explanation available',
            500,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Builds popup close button
  Widget _buildPopupCloseButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        child: Text(
          'Close',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  /// Helper method to truncate text
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}