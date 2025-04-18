import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTextStyles.titleBig),
      backgroundColor: ColorConstants.primaryContainerColor,
      leading:
          showBackButton
              ? IconButton(
                icon: Icon(Icons.arrow_back),
                iconSize: 30,
                color: Colors.white,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
              : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
