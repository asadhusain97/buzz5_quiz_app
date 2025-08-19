#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 1. Install Flutter ---
# Clone the Flutter repository from the stable channel.
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# --- 2. Prepare Flutter for Build ---
# Run flutter doctor to download any missing components.
flutter doctor

# Enable web support.
flutter config --enable-web

# Get project dependencies.
flutter pub get

# --- 3. Build the Flutter Web App ---
# Now run your build command with the secrets.
flutter build web --release \
    --dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY \
    --dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    --dart-define=FIREBASE_AUTH_DOMAIN=$FIREBASE_AUTH_DOMAIN \
    --dart-define=FIREBASE_DATABASE_URL=$FIREBASE_DATABASE_URL \
    --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET \
    --dart-define=GOOGLE_SHEET_API_KEY=$GOOGLE_SHEET_API_KEY \
    --dart-define=RECAPTCHA_SITE_KEY=$RECAPTCHA_SITE_KEY

echo "Flutter build complete."
