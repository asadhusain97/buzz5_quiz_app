import 'package:flutter/material.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:buzz5_quiz_app/config/app_constants.dart';

class MinimalistTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final EdgeInsets? padding;
  final double? width;

  const MinimalistTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding ?? AppConstants.smallPadding,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelPadding: AppConstants.defaultHorizontalPadding.copyWith(
          bottom: AppConstants.smallSpacing,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 2.0,
            color: ColorConstants.primaryColor,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 0.0),
        ),
        labelColor: ColorConstants.primaryColor,
        labelStyle: AppTextStyles.titleMedium,
        unselectedLabelColor: ColorConstants.hintGrey,
        unselectedLabelStyle: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.normal,
        ),
        tabs: tabs.map((tabText) => Tab(
          child: Container(
            padding: AppConstants.smallPadding,
            child: Text(tabText),
          ),
        )).toList(),
      ),
    );
  }
}