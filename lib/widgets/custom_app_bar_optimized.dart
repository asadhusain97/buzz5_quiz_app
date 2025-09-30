import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/providers/auth_provider.dart';
import 'package:buzz5_quiz_app/pages/profile_page.dart';

/// A custom app bar widget that provides consistent navigation and user menu functionality.
///
/// This optimized version includes:
/// - Performance improvements with const constructors
/// - Extracted static widgets for better rebuild efficiency
/// - Comprehensive documentation
/// - Better error handling and null safety
///
/// Features:
/// - Customizable title and back button visibility
/// - User authentication status integration
/// - Profile dropdown menu with logout functionality
/// - Consistent theming and styling
/// - Smooth navigation transitions
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text to display in the app bar
  final String title;

  /// Whether to show the back navigation button
  final bool showBackButton;

  /// Custom actions to display instead of the default user menu (optional)
  final List<Widget>? customActions;

  /// Override the default background color (optional)
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.showBackButton,
    this.customActions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AppBar(
          title: Text(title, style: AppTextStyles.titleBig),
          backgroundColor:
              backgroundColor ?? ColorConstants.primaryContainerColor,
          leading: _buildLeadingWidget(context),
          actions: customActions ?? _buildDefaultActions(authProvider),
        );
      },
    );
  }

  /// Builds the leading widget (back button or null)
  Widget? _buildLeadingWidget(BuildContext context) {
    if (!showBackButton) return null;

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      iconSize: 30,
      color: Colors.white,
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Go back',
    );
  }

  /// Builds the default action widgets when user is authenticated
  List<Widget>? _buildDefaultActions(AuthProvider authProvider) {
    if (!authProvider.isAuthenticated || authProvider.user == null) {
      return null;
    }

    return [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: _UserProfileMenu(user: authProvider.user!),
      ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// An optimized user profile menu widget extracted for better performance.
///
/// This widget is stateless and uses const constructors where possible
/// to minimize rebuilds when the user data doesn't change.
class _UserProfileMenu extends StatelessWidget {
  final dynamic
  user; // Using dynamic to match the existing AuthProvider interface

  const _UserProfileMenu({required this.user});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (BuildContext context) => _buildMenuItems(),
      onSelected: (String value) => _handleMenuSelection(context, value),
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tooltip: 'User menu',
      child: _buildMenuButton(),
    );
  }

  /// Builds the popup menu items
  List<PopupMenuEntry<String>> _buildMenuItems() {
    return [
      const PopupMenuItem<String>(
        value: 'profile',
        child: _MenuItemWidget(
          icon: Icons.person,
          text: 'Profile',
          iconColor: null, // Will use default primary color
        ),
      ),
      const PopupMenuItem<String>(
        value: 'logout',
        child: _MenuItemWidget(
          icon: Icons.logout,
          text: 'Logout',
          iconColor: Colors.red,
        ),
      ),
    ];
  }

  /// Handles menu item selection
  Future<void> _handleMenuSelection(BuildContext context, String value) async {
    switch (value) {
      case 'profile':
        await _navigateToProfile(context);
        break;
      case 'logout':
        await _handleLogout(context);
        break;
    }
  }

  /// Navigates to the profile page
  Future<void> _navigateToProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  /// Handles user logout with proper navigation
  Future<void> _handleLogout(BuildContext context) async {
    if (!context.mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    // Navigate to home and clear stack only if context is still valid
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Builds the clickable menu button with user info
  Widget _buildMenuButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUserAvatar(),
          const SizedBox(width: 8),
          _buildUserNameText(),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  /// Builds the user avatar (profile photo or initials)
  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: ColorConstants.lightTextColor, width: 2),
      ),
      child: ClipOval(
        child:
            user.hasProfilePhoto
                ? Image.network(
                  user.photoURL,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(user.initials);
                  },
                )
                : _buildInitialsAvatar(user.initials),
      ),
    );
  }

  /// Builds the user name text widget
  Widget _buildUserNameText() {
    return Flexible(
      child: Text(
        user.displayNameOrEmail,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Builds an avatar with user initials
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
}

/// A reusable menu item widget with consistent styling.
///
/// This widget uses const constructors for optimal performance
/// and provides a standardized appearance for menu items.
class _MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _MenuItemWidget({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? ColorConstants.primaryColor;

    return Row(
      children: [
        Icon(icon, color: effectiveIconColor, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: iconColor == Colors.red ? Colors.red : null),
        ),
      ],
    );
  }
}
