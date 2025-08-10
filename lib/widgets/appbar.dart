import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/auth_provider.dart';
import 'package:buzz5_quiz_app/pages/profile_page.dart';

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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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
          actions:
              authProvider.isAuthenticated && authProvider.user != null
                  ? [
                    // User Profile Dropdown
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: PopupMenuButton<String>(
                        itemBuilder:
                            (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: ColorConstants.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Profile'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (String value) async {
                          switch (value) {
                            case 'profile':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                              break;
                            case 'logout':
                              await authProvider.signOut();
                              // Navigate to root and clear stack
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
                              }
                              break;
                          }
                        },
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Profile Photo or Initials
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: ColorConstants.lightTextColor,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child:
                                      authProvider.user!.hasProfilePhoto
                                          ? Image.network(
                                            authProvider.user!.photoURL,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return _buildInitialsAvatar(
                                                authProvider.user!.initials,
                                              );
                                            },
                                          )
                                          : _buildInitialsAvatar(
                                            authProvider.user!.initials,
                                          ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // User Name
                              Flexible(
                                child: Text(
                                  authProvider.user!.displayNameOrEmail,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]
                  : null,
        );
      },
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
