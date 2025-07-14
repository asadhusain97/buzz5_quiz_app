import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzz5_quiz_app/models/auth_provider.dart';
import 'package:buzz5_quiz_app/pages/home_page.dart';
import 'package:buzz5_quiz_app/widgets/app_background.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while authentication state is being determined
        if (authProvider.isLoading && authProvider.user == null) {
          return const Scaffold(
            body: AppBackground(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        }

        // Show main app if user is authenticated
        if (authProvider.isAuthenticated) {
          return const HomePage();
        }

        // Show unauthenticated homepage if user is not signed in
        return const HomePage();
      },
    );
  }
}
