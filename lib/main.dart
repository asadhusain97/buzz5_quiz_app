import 'package:flutter/material.dart';

void main() {
  // Read compile-time env via --dart-define
  const appEnv = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'not-set',
  );
  const apiBaseUrl = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'not-set',
  );

  // Log for terminal verification
  debugPrint('[Config] APP_ENV=$appEnv');
  debugPrint('[Config] API_BASE_URL=$apiBaseUrl');

  runApp(MyApp(appEnv: appEnv, apiBaseUrl: apiBaseUrl));
}

class MyApp extends StatelessWidget {
  final String appEnv;
  final String apiBaseUrl;
  const MyApp({super.key, required this.appEnv, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Config Smoke Test',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: HomePage(appEnv: appEnv, apiBaseUrl: apiBaseUrl),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  final String appEnv;
  final String apiBaseUrl;
  const HomePage({super.key, required this.appEnv, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Buzz5 Config Test',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reading compile-time configs via String.fromEnvironment',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ConfigRow(label: 'APP_ENV', value: appEnv),
                        const SizedBox(height: 8),
                        _ConfigRow(label: 'API_BASE_URL', value: apiBaseUrl),
                      ],
                    ),
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

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConfigRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isSet = value != 'not-set' && value.trim().isNotEmpty;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  isSet
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
