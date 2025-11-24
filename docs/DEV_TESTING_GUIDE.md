# Development Testing Guide

## Overview

This guide explains how to use the development configuration system to streamline testing during development.

## Quick Start

### 1. **Bypass Authentication and Navigate to a Specific Page**

Open `lib/config/dev_config.dart` and modify these settings:

```dart
static const bool bypassAuth = true;  // Skip login
static const String? testPage = 'profile';  // Go directly to profile page
//'home' | 'profile' | 'create' | 'marketplace' | 'joingame' | 'instructions' | 'final' | 'gsheet'
```

Press the debug button and the app will **skip authentication** and **navigate directly to the Profile page**.

### 2. **Test With Mock User Login**

```dart
static const bool bypassAuth = false;
static const bool useTestUser = true;  // Auto-login with test credentials
static const String testUserEmail = 'your-test@email.com';
static const String testUserPassword = 'your-test-password';
```

### 3. **Normal Authentication Flow**

```dart
static const bool bypassAuth = false;
static const bool useTestUser = false;
```

This uses the standard login flow.

---

## Available Test Pages

You can navigate to any of these pages by setting `testPage`:

| Page Name | Set `testPage` to | Description |
|-----------|-------------------|-------------|
| Home | `'home'` | Main homepage |
| Profile | `'profile'` | User profile page |
| Create | `'create'` | Create new quiz/room |
| Marketplace | `'marketplace'` | Browse marketplace |
| Join Game | `'joingame'` | Join existing game |
| Instructions | `'instructions'` | Instructions page |
| Final | `'final'` | Final results page |
| GSheet Check | `'gsheet'` | Google Sheets integration test |

**Note:** Some pages like `gameroom`, `questionboard`, and `question` require specific parameters and will redirect to home page for now. You can update the wrapper classes in `dev_auth_gate.dart` to provide mock data.

---

## Configuration Options

### Main Toggles (`lib/config/dev_config.dart`)

```dart
// Skip authentication entirely
static const bool bypassAuth = false;

// Which page to navigate to on startup (when bypassAuth is true)
static const String? testPage = null;

// Auto-login with test credentials (when bypassAuth is false)
static const bool useTestUser = false;
```

### Test User Credentials

```dart
static const String testUserEmail = 'test@example.com';
static const String testUserPassword = 'testpassword123';
static const String testUserDisplayName = 'Test User';
```

### Advanced Options

```dart
// Show detailed debug logs
static const bool verboseLogging = true;

// Simulate guest user (unauthenticated)
static const bool simulateGuest = false;
```

---

## How It Works

### Architecture

```
main.dart
   ↓
DevAuthGate (checks kDebugMode and DevConfig)
   ↓
   ├─→ [If bypassAuth=true] Navigate to testPage
   ├─→ [If useTestUser=true] Auto-login with credentials
   └─→ [Otherwise] Normal AuthGate flow
```

### Safety Features

1. **Automatic Disable in Release**: All dev features are automatically disabled in release builds using Flutter's `kDebugMode` constant
2. **Clear Logging**: Console shows exactly what dev mode is doing
3. **No Code Changes Needed**: Just edit `dev_config.dart` - no commenting/uncommenting required
4. **Version Control Safe**: `dev_config.dart` can be committed with default values, each developer can customize locally

---

## Common Workflows

### Testing Profile Page

```dart
// dev_config.dart
static const bool bypassAuth = true;
static const String? testPage = 'profile';
```

### Testing as Authenticated User

```dart
// dev_config.dart
static const bool bypassAuth = false;
static const bool useTestUser = true;
static const String testUserEmail = 'mytest@example.com';
static const String testUserPassword = 'mypassword';
```

### Testing as Guest

```dart
// dev_config.dart
static const bool bypassAuth = true;
static const bool simulateGuest = true;
static const String? testPage = 'home';
```

### Normal Testing (with login)

```dart
// dev_config.dart
static const bool bypassAuth = false;
static const bool useTestUser = false;
```

---

## Adding Support for Pages with Parameters

Some pages like `GameRoomPage` require parameters (room ID, etc.). To test these:

1. Open `lib/widgets/dev_auth_gate.dart`
2. Find the wrapper class (e.g., `_DevGameRoomWrapper`)
3. Add mock parameters:

```dart
class _DevGameRoomWrapper extends StatelessWidget {
  const _DevGameRoomWrapper();

  @override
  Widget build(BuildContext context) {
    // Provide mock data for testing
    return GameRoomPage(
      roomId: 'test-room-123',
      roomName: 'Test Room',
      // ... other required parameters
    );
  }
}
```

---

## Tips & Best Practices

1. **Keep Defaults Off**: Commit `dev_config.dart` with `bypassAuth = false` so other developers start with normal behavior
2. **Use `.gitignore`**: If you want personal dev settings, add `lib/config/dev_config.dart` to `.gitignore`
3. **Verbose Logging**: Enable `verboseLogging = true` to see exactly what's happening
4. **Real Credentials**: For `useTestUser`, use real test account credentials from your Firebase project

---

## Troubleshooting

### Config not working

1. Make sure you're running in **debug mode** (not release)
2. Check the console for the dev config banner on startup
3. Verify `kDebugMode` is true

### Page requires parameters

Some pages need data to function. Update the wrapper classes in `dev_auth_gate.dart` or choose a different test page.

### Want to test production behavior

Set all flags to `false` in `dev_config.dart` to simulate production authentication flow.

---

## Example Console Output

When dev config is active, you'll see:

```
═══════════════════════════════════════════════════════════
🔧 DEV CONFIG ACTIVE
═══════════════════════════════════════════════════════════
Bypass Auth:     true
Test Page:       profile
Use Test User:   false
Simulate Guest:  false
Verbose Logging: true
═══════════════════════════════════════════════════════════
🔧 DEV MODE: Bypassing authentication
🔧 DEV MODE: Navigating to profile
```

---

## Files Modified

- **Created**: `lib/config/dev_config.dart` - Configuration file
- **Created**: `lib/widgets/dev_auth_gate.dart` - Development-aware auth gate
- **Modified**: `lib/main.dart` - Uses `DevAuthGate` instead of `AuthGate`

---

## Reverting to Original Behavior

To completely disable dev features without modifying code:

```dart
// dev_config.dart
static const bool bypassAuth = false;
static const bool useTestUser = false;
```

Or revert the changes by using `AuthGate` directly in `main.dart`:

```dart
// main.dart
home: const AuthGate(),  // Instead of DevAuthGate()
```
