# buzz5_quiz_app

Welcome to buzz5_quiz_app – a place to host quizzes among friends!

Go to the [app](https://buzz5quiz.netlify.app/) or
learn more about the project [here](https://asadhusain97.github.io/projects/flutterquizapp.html)

## Overview

This app allows users to create, share, and participate in quizzes with friends in a fun and interactive way.

## Features

- Create custom quizzes
- Login to your profile
- Play quizzes with friends
- Track scores and see game analytics

## Setup

Follow these steps to get your app up and running:

1. **Clone the repo:**

   ```sh
   git clone https://github.com/yourusername/buzz5_quiz_app.git
   ```

2. **Install Flutter:**
   Follow the instructions on the [official Flutter website](https://flutter.dev/docs/get-started/install) to install Flutter on your machine.

3. **Required Configuration Values:**

   You'll need to set up the following services and get their configuration values:

   | Service | Required Values | Where to Get |
   |---------|----------------|--------------|
   | **Firebase** | API Key, Project ID, Auth Domain, Database URL, Storage Bucket, Messaging Sender ID, App ID | [Firebase Console](https://console.firebase.google.com) → Project Settings → General |
   | **Google OAuth** | Web Client ID | [Google Cloud Console](https://console.cloud.google.com) → APIs & Credentials → OAuth 2.0 Client IDs |
   | **reCAPTCHA** | Site Key | [Google reCAPTCHA](https://www.google.com/recaptcha/admin) |
   | **Google Sheets** | Apps Script URL | Deploy your Google Apps Script as web app |

4. **Firebase Setup:**

   1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   2. Enable Authentication → Email/Password provider
   3. Add your domain (localhost:8080, your-site.netlify.app) to Authorized domains
   4. Set up Firestore Database and Storage
   5. Copy configuration values to your `dev.json`

5. **Run the app:**

   ```sh
   flutter run --dart-define-from-file=dev.json -d chrome
   ```

   5.1. Development environment (with dev.json)

   5.1.1. Copy `example.json` to `dev.json`:

      ```sh
      cp example.json dev.json
      ```

   5.1.2. Update `dev.json` with your actual configuration values:
      - Get Firebase config from [Firebase Console](https://console.firebase.google.com)
      - Get Google OAuth client ID from [Google Cloud Console](https://console.cloud.google.com)
      - Get reCAPTCHA site key from [Google reCAPTCHA](https://www.google.com/recaptcha)
      - Set up your Google Apps Script URL for `GOOGLE_SHEET_API_KEY`

   5.1.3. Debug with configuration:

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

   5.2 Production environment

   For production deployments (Netlify, etc.):

   5.2.1. **Netlify Configuration:**
      - Go to Site settings → Environment variables
      - Add all variables from your `dev.json` as key-value pairs
      - Create a `netlify-build.sh` with instructions on building the app with configurations
      - Build command:

        ```sh
        ./netlify-build.sh
        ```

   5.2.2. **Other Hosting Platforms:**
      - Set environment variables in your hosting platform's dashboard
      - Use `--dart-define-from-file` or individual `--dart-define` flags in your build process

## Important Notes

- **Never commit `dev.json`** with real credentials (it's already in .gitignore)
- **Use `example.json`** as a template for required configuration structure
- **For production**: Use your hosting platform's environment variable settings
- **Firebase domains**: Add all your deployment domains to Firebase Auth → Settings → Authorized domains

## Usage

1. **Create a Quiz:**
   Go to [this google sheet](https://docs.google.com/spreadsheets/d/149cG62dE_5H9JYmNYoJ_h0w5exYSFNY-HvX8Yq-HZrI/edit?usp=sharing) to add your round and sets.
2. **Host or play the Quiz:**
    A quizmaster hosts the game and navigates the question board while other players try to answer the questions of their choosing. You can watch a [Buzzing with Kvizzing](https://youtu.be/EZNETfkm7lQ?si=im4mlrph7Ozgs2vo) video which was the inspiration for this project.

## Future Features

Stay tuned for:

- Improved UI/UX quirks
- Part points for questions
- A buzzer app that identifies the fastest player
- Login and user profile in the app
- Input your questions through the app
- Save all of your quizzes
- Bookmark/play quizzes made by other users
- Build a marketplace where people can share and play quizzes
- More surprises!

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License.

## Contact

For any inquiries or feedback, please contact me at [asad.husain97@gmail.com].
