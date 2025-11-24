# Testing Guide - Production Safety Checks

## Overview

This guide explains the automated testing system that ensures the app is in a production-ready state before merging branches.

## Dev Config Production Safety Test

### Purpose

The dev config test (`test/config/dev_config_test.dart`) validates that all development toggles in `lib/config/dev_config.dart` are disabled before deploying to production.

### What It Checks

The test ensures these values are in production-safe state:

| Config Variable | Required Value | Purpose |
|----------------|----------------|---------|
| `bypassAuth` | `false` | Authentication must be required |
| `testPage` | `null` | No auto-navigation to test pages |
| `useTestUser` | `false` | No auto-login with test credentials |
| `simulateGuest` | `false` | No guest user simulation |
| `verboseLogging` | `false` | Minimal logging in production |

### Running the Test Locally

```bash
# Run just the dev_config test
flutter test test/config/dev_config_test.dart

# Run all tests
flutter test
```

### Expected Output

**When config is production-ready:**
```
✅ All tests passed (8 tests)
```

**When config needs fixes:**
```
❌ Test failed: verboseLogging should be false for production
   Expected: false
   Actual: true
```

## GitHub Actions Integration

### Automated Workflows

Two workflows run automatically on GitHub:

#### 1. **Test Workflow** (`.github/workflows/tests.yml`)

Runs on:
- Pull requests to `main` or `master`
- Direct pushes to `main` or `master`

What it does:
- ✅ Installs Flutter and dependencies
- ✅ Runs `flutter analyze` for code quality
- ✅ Runs all tests including dev_config test
- ✅ Validates dev_config values with grep checks
- ✅ Basic security scan for hardcoded secrets

#### 2. **Firebase Deploy Workflows**

Existing workflows continue to work:
- `firebase-hosting-pull-request.yml` - Preview deployments
- `firebase-hosting-merge.yml` - Production deployments

### Setting Up Branch Protection

To **require** tests to pass before merging:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Branches**
3. Click **Add branch protection rule**
4. Configure:
   - **Branch name pattern:** `main` (or `master`)
   - Enable: ✅ **Require status checks to pass before merging**
   - Select required checks:
     - `Run Flutter Tests`
     - `Production Safety Validation`
   - Enable: ✅ **Require branches to be up to date before merging**
   - Enable: ✅ **Do not allow bypassing the above settings**

5. Click **Create** or **Save changes**

### Visual Indicators

On pull requests, you'll see:

```
✅ Run Flutter Tests — passed
✅ Production Safety Validation — passed
✅ All checks have passed
```

Or if config isn't ready:

```
❌ Run Flutter Tests — failed
   verboseLogging must be false for production
```

## Workflow for Developers

### Before Creating a Pull Request

1. **Ensure dev_config is production-ready:**
   ```bash
   flutter test test/config/dev_config_test.dart
   ```

2. **Fix any failures** by editing `lib/config/dev_config.dart`

3. **Run all tests:**
   ```bash
   flutter test
   ```

4. **Create your pull request** - tests will run automatically

### During Development

You can keep development features enabled while working:

```dart
// lib/config/dev_config.dart
static const bool bypassAuth = true;  // OK during development
static const bool verboseLogging = true;  // OK during development
```

But remember to reset them before merging:

```dart
// lib/config/dev_config.dart
static const bool bypassAuth = false;  // Required for production
static const bool verboseLogging = false;  // Required for production
```

### Quick Reset Command

To quickly reset all dev configs to production-safe values:

```bash
# Check current values
grep -E "bypass|testPage|useTest|simulate|verbose" lib/config/dev_config.dart

# Or run the test to see what needs fixing
flutter test test/config/dev_config_test.dart
```

## Troubleshooting

### Test Fails Locally

1. **Check the error message** - it will tell you which config value is wrong
2. **Edit `lib/config/dev_config.dart`** and set the value correctly
3. **Re-run the test** to verify the fix

### GitHub Action Fails

1. **Click on the failed check** in the PR to see details
2. **Review the logs** to identify which test failed
3. **Fix locally** and push the changes
4. **The workflow will re-run automatically**

### Branch Protection Blocks Merge

If you see "Merging is blocked" on a PR:

1. All required status checks must pass
2. Check the PR for failed workflows
3. Fix issues and push new commits
4. Wait for checks to pass

## Best Practices

1. **Run tests before committing:**
   ```bash
   flutter test
   ```

2. **Use feature branches for development:**
   - Keep dev features enabled in your branch
   - Reset before creating PR to main

3. **Review the workflow logs:**
   - Helps catch issues early
   - Learn from failed checks

4. **Don't disable branch protection:**
   - Protects production from broken code
   - Ensures team accountability

## Emergency Override

If you need to merge urgently (not recommended):

1. An admin can temporarily disable branch protection
2. Merge the PR
3. **Immediately re-enable branch protection**
4. Create a follow-up PR to fix any issues

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
