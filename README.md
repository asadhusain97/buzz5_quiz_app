# buzz5_quiz_app

Welcome to buzz5_quiz_app – a place to host quizzes among friends!

Go to the [app](https://buzz5quiz.web.app/) or
learn more about the project [in my portfolio](https://asadhusain97.github.io/projects/flutterquizapp.html)

## Overview

This app allows users to create, share, and participate in quizzes with friends in a fun and interactive way.

## Features

- **User Authentication**: Secure login/signup with Firebase Auth and email/password support
- **Quiz Management**: Host quiz games with question boards from Google Sheets
- **Real-time Gameplay**: Live multiplayer quiz sessions with game codes
- **Player Management**: Add players manually or let them join via game codes
- **Score Tracking**: Real-time leaderboard and game analytics
- **Host Controls**: Special host interface for managing game flow and questions
- **Dark Theme UI**: Consistent dark theme experience across the app
- **Responsive Design**: Optimized for web deployment on various screen sizes

## Setup

Follow these steps to get your app up and running:

1. **Clone the repo:**

   ```sh
   git clone https://github.com/asadhusain97/buzz5_quiz_app.git
   cd buzz5_quiz_app
   ```

2. **Install Flutter:**
   Follow the instructions on the [official Flutter website](https://flutter.dev/docs/get-started/install) to install Flutter on your machine.

3. **Install dependencies:**

   ```sh
   flutter pub get
   ```

4. **Required Configuration Values:**

   You'll need to set up the following services and get their configuration values:

   | Service | Required Values | Where to Get |
   |---------|----------------|--------------|
   | **Firebase** | API Key, Project ID, Auth Domain, Database URL, Storage Bucket, Messaging Sender ID, App ID | [Firebase Console](https://console.firebase.google.com) → Project Settings → General |
   | **Google OAuth** | Web Client ID | [Google Cloud Console](https://console.cloud.google.com) → APIs & Credentials → OAuth 2.0 Client IDs |
   | **reCAPTCHA** | Site Key | [Google reCAPTCHA](https://www.google.com/recaptcha/admin) |
   | **Google Sheets** | Apps Script URL | Deploy your Google Apps Script as web app for quiz data |

5. **Firebase Setup:**

   1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   2. Enable Authentication → Email/Password provider
   3. Set up Firestore Database and Realtime Database
   4. Enable Firebase App Check with reCAPTCHA v3
   5. Add your domains (localhost:8080, your-site.netlify.app, etc.) to Authorized domains
   6. Copy configuration values to your `dev.json`

6. **Run the app:**

   ```sh
   flutter run --dart-define-from-file=dev.json -d chrome
   ```

   6.1. Development environment (with dev.json)

   6.1.1. Copy `example.json` to `dev.json`:

      ```sh
      cp example.json dev.json
      ```

   6.1.2. Update `dev.json` with your actual configuration values:
      - Get Firebase config from [Firebase Console](https://console.firebase.google.com)
      - Get Google OAuth client ID from [Google Cloud Console](https://console.cloud.google.com)
      - Get reCAPTCHA site key from [Google reCAPTCHA](https://www.google.com/recaptcha)
      - Set up your Google Apps Script URL for `GOOGLE_SHEET_API_KEY`

   6.1.3. Debug with configuration:

      set up your launch.json in .vscode directory (find similar json for debugging in other IDEs)

      ```json
      {
         "version": "0.2.0",
         "configurations": [
            {
                  "name": "Debug App",
                  "request": "launch",
                  "type": "dart",
                  "deviceId": "chrome",
                  "program": "lib/main.dart",
                  "cwd": "${workspaceFolder}",
                  "toolArgs": [
                     "--dart-define-from-file=${workspaceFolder}/dev.json"
                  ],
                  "flutterMode": "debug",
                  "templateFor": ""
            },
         ]
      }
      ```

   6.2 Production environment

   For production deployments (Firebase, Netlify, etc.):

   6.2.1. **Hosting site Configuration:**

      (a) Firebase Hosting
      - Use the Firebase CLI to create necessary files
      - Save environment variables in the Github Secrets
      - Set relevant permissions in firebase authentication adn google web client

      (b) Netlify
      - Go to Site settings → Environment variables
      - Add all variables from your `dev.json` as key-value pairs
      - Create a `netlify-build.sh` with instructions on building the app with configurations
      - Build command:

        ```sh
        ./netlify-build.sh
        ```

   6.2.2. **Other Hosting Platforms:**
      - Set environment variables in your hosting platform's dashboard
      - Use `--dart-define-from-file` or individual `--dart-define` flags in your build process

## Important Notes

- **Never commit `dev.json`** with real credentials (it's already in .gitignore)
- **Use `example.json`** as a template for required configuration structure
- **For production**: Use your hosting platform's environment variable settings
- **Firebase domains**: Add all your deployment domains to Firebase Auth → Settings → Authorized domains

## Usage

1. **Create a Quiz:**
   Set up your questions in [this Google Sheet](https://docs.google.com/spreadsheets/d/149cG62dE_5H9JYmNYoJ_h0w5exYSFNY-HvX8Yq-HZrI/edit?usp=sharing) with rounds and question sets.

2. **Host a Game:**
   - Sign in to your account
   - Create a new game room which generates a unique game code
   - Share the game code with players to join
   - Use the host interface to manage game flow and navigate questions

3. **Join a Game:**
   - Enter the game code provided by the host
   - Add your player name
   - Wait for the host to start the quiz

4. **Game Flow:**
   The quizmaster controls the question board while players answer questions of their choice. The app tracks scores in real-time and displays a leaderboard.

   *Inspired by [Buzzing with Kvizzing](https://youtu.be/EZNETfkm7lQ?si=im4mlrph7Ozgs2vo) - check out this video to see the gameplay concept.*

## Future Features

Stay tuned for:

- Improved UI/UX enhancements
- Partial points scoring system
- Buzzer functionality to identify fastest responses
- In-app quiz creation and editing
- Personal quiz library and saved games
- Quiz sharing and bookmarking system
- Community marketplace for sharing quizzes
- Enhanced player profiles and statistics
- Mobile app versions (iOS/Android)
- Real-time chat during games
- More question types and formats

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License.

## Contact

For any inquiries or feedback, please contact me at [asad.husain97@gmail.com].
