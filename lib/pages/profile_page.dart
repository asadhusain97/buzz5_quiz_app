import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buzz5_quiz_app/models/auth_provider.dart';
import 'package:buzz5_quiz_app/widgets/appbar.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';
import 'package:buzz5_quiz_app/config/colors.dart';
import 'package:buzz5_quiz_app/config/logger.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _displayNameController.text = authProvider.user?.displayName ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        // TODO: Implement Firebase Storage upload
        // For now, show a placeholder message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload feature coming soon!')),
        );
        AppLogger.i('Image selected: ${image.path}');
      }
    } catch (e) {
      AppLogger.e('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.updateProfile(
      displayName: _displayNameController.text.trim(),
    );

    if (success) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelEdit() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _displayNameController.text = authProvider.user?.displayName ?? '';
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return Scaffold(
            appBar: CustomAppBar(title: "Profile", showBackButton: true),
            body: const AppBackground(
              child: Center(child: Text('No user logged in')),
            ),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(title: "Profile", showBackButton: true),
          body: AppBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Profile Photo Section
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorConstants.primaryContainerColor,
                              border: Border.all(
                                color: ColorConstants.primaryColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstants.primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  user.hasProfilePhoto
                                      ? Image.network(
                                        user.photoURL,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return _buildInitialsAvatar(
                                            user.initials,
                                          );
                                        },
                                      )
                                      : _buildInitialsAvatar(user.initials),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: ColorConstants.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: ColorConstants.hintGrey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Profile Information Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstants.lightTextColor,
                                ),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  },
                                  icon: const Icon(Icons.edit),
                                  iconSize: 20,
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Display Name Field
                          if (_isEditing) ...[
                            TextFormField(
                              controller: _displayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Display name cannot be empty';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            _buildInfoRow(
                              'Display Name',
                              user.displayName.isNotEmpty
                                  ? user.displayName
                                  : 'Not set',
                              Icons.person,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Email (Read-only)
                          _buildInfoRow('Email', user.email, Icons.email),

                          const SizedBox(height: 16),

                          // Account Created Date
                          _buildInfoRow(
                            'Member Since',
                            user.createdAt != null
                                ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                                : 'Unknown',
                            Icons.calendar_today,
                          ),

                          const SizedBox(height: 16),

                          // Last Login
                          _buildInfoRow(
                            'Last Login',
                            user.lastLogin != null
                                ? '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year}'
                                : 'Unknown',
                            Icons.login,
                          ),

                          if (_isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelEdit,
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed:
                                        authProvider.isLoading
                                            ? null
                                            : _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          ColorConstants.primaryColor,
                                      foregroundColor:
                                          ColorConstants.lightTextColor,
                                    ),
                                    child:
                                        authProvider.isLoading
                                            ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            authProvider.isLoading
                                ? null
                                : () async {
                                  await authProvider.signOut();
                                  if (mounted) {
                                    Navigator.of(
                                      context,
                                    ).pushNamedAndRemoveUntil(
                                      '/',
                                      (route) => false,
                                    );
                                  }
                                },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: ColorConstants.primaryContainerColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: ColorConstants.lightTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorConstants.hintGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: ColorConstants.hintGrey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: ColorConstants.lightTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
