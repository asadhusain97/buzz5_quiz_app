# Buzz5 Quiz App - Application Flow Documentation

## 1. Overview

Buzz5 Quiz App is a real-time, multiplayer quiz platform built with Flutter that enables users to create, share, and compete in live trivia games. The app features a Jeopardy-style game board with custom question sets, real-time buzzer mechanics, and a marketplace for sharing user-generated content.

**Target Platforms:** Web, iOS, Android (Flutter cross-platform)

## 2. Technology Stack

### Frontend
- **Framework:** Flutter (SDK ^3.7.0)
- **Language:** Dart
- **State Management:** Provider (v6.1.2)
- **UI Components:** Material Design (Dark theme only)
- **Media Handling:**
  - `image_picker` (v1.1.2) - Image selection
  - `file_picker` (v8.1.6) - File selection
- **Content Rendering:** `flutter_markdown` (v0.7.6+2)
- **URL Handling:** `url_launcher` (v6.3.1)
- **Network Monitoring:** `connectivity_plus` (v6.1.2)
- **Logging:** `logger` (v2.5.0)
- **Data Import:** `excel` (v4.0.6), `csv` (v6.0.0), `file_saver` (v0.3.1)
- **Utilities:** `uuid` (v4.5.1), `path` (v1.9.0), `http` (v1.4.0)

### Backend (Firebase)
- **Firebase Core** (v3.1.1) - Firebase initialization
- **Firebase Authentication** (v5.1.1) - User authentication
- **Cloud Firestore** (v5.0.2) - Persistent data storage
  - User profiles (`users` collection)
  - Question sets (`sets` collection)
  - Boards (`boards` collection)
- **Firebase Storage** (v12.3.5) - Media file storage
- **Firebase Realtime Database** (v11.1.4) - Live game state
  - Active game rooms
  - Real-time player positions
  - Buzzer queue
  - Game synchronization
- **Firebase App Check** (v0.3.2+9) - Security & bot protection
- **Cloud Functions for Firebase** - Backend automation
  - Scheduled room cleanup (runs weekly)
- **Firebase Hosting** - Web deployment

### Security
- **ReCAPTCHA v3** - Bot protection for web
- **Firebase App Check** - Request validation
- **Environment Variables** - Configuration via `.env` files (flutter_dotenv v5.0.2)

## 3. Architecture Overview

### Application Structure
```
lib/
├── config/          # App configuration (theme, logger, dev settings)
├── main.dart        # App entry point
├── models/          # Data models
├── pages/           # Screen components
├── providers/       # State management (Provider pattern)
├── services/        # Business logic & API services
└── widgets/         # Reusable UI components

functions/           # Cloud Functions (Node.js)
assets/images/       # App assets
```

### State Management Pattern
The app uses **Provider** with multiple providers:
1. **AuthProvider** - Authentication state
2. **PlayerProvider** - Current player state
3. **RoomProvider** - Game room state (depends on AuthProvider)
4. **AnsweredQuestionsProvider** - Track answered questions

## 4. Data Models (Database Schema)

### 4.1 User Model (`AppUser`)
**Storage:** Cloud Firestore (`users` collection)

```dart
{
  uid: String (Primary Key),
  email: String,
  displayName: String,
  photoURL: String,
  createdAt: Timestamp,
  lastLogin: Timestamp,
  updatedAt: Timestamp
}
```

**Features:**
- Firebase Authentication integration
- Guest user support (uid starts with `guest_`)
- Profile photo support
- Display name with fallback to email

### 4.2 Media Model (`Media`)
**Storage:** Cloud Firestore (embedded in Questions)

```dart
{
  type: String ("image" | "audio" | "video"),
  storagePath: String (path in Firebase Storage),
  downloadURL: String (public URL),
  thumbnailURL?: String (optional),
  altText?: String (accessibility text, optional),
  dimensions?: MediaDimensions (optional, for images/videos),
  fileSize: int (bytes),
  status: String ("uploading" | "ready" | "failed", default: "ready")
}

MediaDimensions {
  width: int,
  height: int,
  aspectRatio: double
}
```

**Supported File Types:**
- Images: jpg, jpeg, png, gif, webp, bmp
- Audio: mp3, wav, ogg, aac, m4a
- Video: mp4, mov, avi, mkv, webm

### 4.3 Question Model (`Question`)
**Storage:** Cloud Firestore (embedded in Sets)

```dart
{
  id: String (Primary Key),
  questionText?: String (optional),
  questionMedia?: Media (optional),
  answerText?: String (optional),
  answerMedia?: Media (optional),
  points: int (default: 10),
  hint?: String (optional),
  funda?: String (explanation, optional),
  status: enum (draft | complete)
}
```

**Validation Rules:**
- Must have either questionText OR questionMedia
- Must have either answerText OR answerMedia
- Status is automatically set to `draft` if validation fails
- Status is `complete` only when both question and answer exist

### 4.4 Set Model (`SetModel`)
**Storage:** Cloud Firestore (`sets` collection)

```dart
{
  id: String (Primary Key),
  name: String,
  description: String,
  authorId: String (Foreign Key -> users.uid),
  authorName: String,
  tags: List<PredefinedTags>,
  creationDate: Timestamp,

  // Privacy & Marketplace fields
  isPrivate: boolean (default: true),
  price?: double (optional),
  downloads: int (default: 0),
  rating: double (default: 0.0),
  difficulty?: enum (easy | medium | hard),

  // Questions array (embedded)
  questions: List<Question> (max 5)
}
```

**Computed Properties:**
- `status` - Auto-calculated:
  - `complete` if name & description exist AND exactly 5 questions AND all questions are complete
  - `draft` otherwise
- `questionCount` - Number of questions (max 5)
- `isValidPrivacySetting` - False if trying to publish (isPrivate=false) a draft set
- `canBeListedInMarketplace` - True only if !isPrivate AND status is complete

**Business Rules:**
- Maximum 5 questions per set
- Set is only complete when it has 5 complete questions
- Draft sets cannot be published (must remain private)

### 4.5 Board Model (`BoardModel`)
**Storage:** Cloud Firestore (`boards` collection)

```dart
{
  id: String (Primary Key),
  name: String,
  description: String,
  authorId: String (Foreign Key -> users.uid),
  authorName: String,
  creationDate: Timestamp,
  modifiedDate: Timestamp,
  status: enum (draft | complete),

  // Set references (IDs only, not full objects)
  setIds: List<String> (max 5)
}
```

**Computed Properties:**
- `status` - Stored explicitly but validated:
  - Can only be `complete` if exactly 5 sets
  - Otherwise forced to `draft`
- `setCount` - Number of sets in the board

**Business Rules:**
- Maximum 5 sets per board
- Board stores only set IDs (not full set objects) for efficiency
- A set can belong to multiple boards
- Boards are personal DIY collections (not for marketplace sale)

### 4.6 Room Model (`Room`)
**Storage:** Firebase Realtime Database (`/rooms/{roomCode}`)

```dart
{
  roomInfo: {
    roomCode: String (6-char unique code),
    hostId: String (Foreign Key -> users.uid),
    status: enum (waiting | active | questionActive | ended),
    createdAt: int (timestamp),
    maxPlayers: int (default: 50),
    currentQuestion: int (default: 0),
    totalQuestions: int,
    questionStartTime?: int (timestamp),
    deleteAt?: int (timestamp for cleanup)
  },

  players: {
    [playerId]: {
      name: String,
      isHost: boolean,
      joinedAt: int (timestamp),
      buzzCount: int,
      isConnected: boolean,
      lastSeen?: int (timestamp)
    }
  },

  buzzers: {
    [buzzerId]: {
      playerId: String,
      playerName: String,
      timestamp: int,
      questionNumber: int,
      position: int
    }
  },

  gameState: {
    questionActive: boolean,
    buzzersEnabled: boolean,
    topBuzzersCount: int (default: 3)
  },

  board: {
    // Board data for the game (question sets)
  },

  scores: {
    [playerId]: int
  }
}
```

**Room Code Generation:**
- 6 uppercase alphanumeric characters
- Excludes confusing characters (0, O, I, 1)
- Uniqueness validated against existing rooms

**Room Lifecycle:**
- Created when host starts a new game
- Expires after 24 hours
- Cleaned up weekly by Cloud Function if:
  - `deleteAt` timestamp exists and is in the past
  - `deleteAt` timestamp does not exist

### 4.7 Player Model (`Player`)
**Storage:** In-memory during game, saved to Firestore for stats

```dart
{
  name: String,
  accountId?: String (Foreign Key -> users.uid),
  score: int,
  allPoints: List<int> (point history),
  correctAnsCount: int,
  correctAnsTotal: int,
  wrongAnsCount: int,
  wrongAnsTotal: int,
  firstHits: int (times buzzed first)
}
```

**Features:**
- Complete score history for undo functionality
- Detailed statistics tracking
- Accuracy calculation
- Average points per correct answer

### 4.8 Predefined Tags (Enum)
Categories for question sets:
- Architecture, Arts, Astronomy, Biology, Business
- Civics, Words, Entertainment, Fashion, Food & Drinks
- General, Geography, History, India, Literature
- Logos, Maths, Movies, Mythology, Other
- Personal, Politics, Pop Culture, Science, Songs
- Sports, Technology, US, Video Games, Wordplay, World

### 4.9 Enums Summary
```dart
SetStatus: draft | complete
BoardStatus: draft | complete
QuestionStatus: draft | complete
RoomStatus: waiting | active | questionActive | ended
DifficultyLevel: easy | medium | hard
```

## 5. Features

### 5.1 User Management
- **Firebase Authentication**
  - Email/Password login
  - User registration
  - Password reset functionality
  - Guest user support (limited features: can join games, cannot host or create content)
- **User Profiles**
  - Display name
  - Profile photo (via Firebase Storage)
  - Email
  - Account timestamps (created, last login, updated)

### 5.2 Content Creation
- **Question Creation**
  - Text-based questions & answers
  - Media support (images, audio, video via Firebase Storage)
  - Full media metadata (type, dimensions, file size, thumbnails)
  - Point value assignment (10/20/30/40/50 points, currently fixed per question position)
  - Optional hints
  - Optional "funda" (concept explanation)
  - Draft/Complete status (auto-calculated)
- **Set Creation**
  - Organize questions into sets (exactly 5 questions for complete status)
  - Set metadata (name max 30 chars, description max 150 chars)
  - Tag selection (up to 5 predefined tags)
  - Difficulty level (Easy/Medium/Hard)
  - Privacy controls (Private/Public toggle)
  - Auto-status calculation
  - Duplicate name validation
  - Edit existing sets
  - Duplicate sets (creates copy with "(Copy)" suffix)
- **Set Import**
  - Import sets from external files (Excel, CSV templates)
  - Template-based import system
- **Board Creation**
  - Organize sets into boards (exactly 5 sets for complete status)
  - Board metadata (name, description, author)
  - Set selection from user's library
  - Status explicitly stored and validated
  - Edit existing boards
  - Duplicate boards
  - Boards are DIY collections (not for marketplace)

### 5.3 Marketplace
- **Status:** Coming Soon (placeholder page)
- **Planned Features:**
  - Browse public question sets (isPrivate=false)
  - Filter by tags/categories, difficulty
  - Sort by rating, downloads, creation date
  - Download/use sets in games
  - Rating system (0.0-5.0)
  - Download counter
  - Pricing system (free and paid sets)

### 5.4 Real-time Multiplayer Gaming
- **Room Management**
  - Create game room with unique 6-character code
  - Join room via code
  - Room capacity (max 50 players)
  - Host controls
- **Game Lobby**
  - Real-time player list
  - Player connection status
  - Host can start game
- **Live Gameplay**
  - Jeopardy-style question board
  - Real-time question display
  - Buzzer system (top 3 buzzers get to answer)
  - Live score updates
  - Question navigation
- **Buzzer System**
  - Real-time buzzer queue
  - Timestamp-based ordering
  - Position tracking (1st, 2nd, 3rd)
  - Top N players get to answer (configurable, default: 3)
- **Scoring**
  - Points awarded for correct answers
  - Points deducted for wrong answers
  - Real-time leaderboard
  - Detailed statistics (accuracy, avg points, first hits)
- **Game Completion**
  - Final scoreboard
  - Winner announcement
  - Detailed player statistics

### 5.5 Developer Features
- **Dev Auth Gate** - Development mode authentication bypass
- **Environment Configuration** - `.env` file support
- **Logging** - Comprehensive app logging
- **Connectivity Monitoring** - Network status tracking

## 6. User Flows

### 6.1 Authentication Flow
```
1. App Launch
   └─> DevAuthGate checks authentication
       ├─> Authenticated → Home Page
       └─> Not Authenticated → Login Page
           ├─> Login with Email/Password → Home Page
           ├─> Register New Account → Home Page
           ├─> Forgot Password → Reset Email Sent
           └─> Continue as Guest → Home Page (limited features)
```

### 6.2 Content Creation Flow
```
1. Home Page → Create Page
   ├─> Sets Tab (default)
   │   ├─> View all user's sets (with filters/sort)
   │   ├─> Filter by: Status (Draft/Complete), Tags, Name, Creator
   │   ├─> Sort by: Name (A-Z/Z-A), Difficulty, Date (Newest/Oldest)
   │   ├─> Import Set (from Excel/CSV template)
   │   └─> New Set
   │       ├─> Enter set info (name ≤30 chars, description ≤150 chars)
   │       ├─> Select tags (up to 5 from predefined list)
   │       ├─> Select difficulty (Easy/Medium/Hard)
   │       ├─> Toggle privacy (Private/Public switch)
   │       ├─> Add 5 questions via tabs (Q1-Q5)
   │       │   ├─> Question: text (required) OR media (image/audio/video)
   │       │   ├─> Answer: text (required) OR media
   │       │   ├─> Points: 10/20/30/40/50 (fixed per question)
   │       │   ├─> Hint (optional)
   │       │   └─> Funda/explanation (optional)
   │       ├─> Dynamic save button:
   │       │   ├─> "Save as Draft" (if incomplete)
   │       │   └─> "Save" (if 5 complete questions)
   │       └─> Duplicate name validation before save
   │
   └─> Boards Tab
       ├─> View all user's boards (with filters/sort)
       ├─> Filter by: Status, Name, Creator
       ├─> Sort by: Name, Date
       └─> New Board
           ├─> Enter board details (name, description)
           ├─> Select 5 sets from user's library
           ├─> Auto-calculate status (complete if 5 sets)
           └─> Save board
```

### 6.3 Game Creation & Join Flow
```
1. Home Page
   ├─> Create New Game
   │   ├─> Select board/set from marketplace or own library
   │   ├─> Generate unique room code (e.g., ABC-123)
   │   ├─> Share room code with friends
   │   ├─> Wait in lobby for players to join
   │   ├─> Start game (host only)
   │   └─> Navigate to Question Board
   │
   └─> Join Existing Game
       ├─> Enter room code
       ├─> Enter player name
       ├─> Join lobby
       └─> Wait for host to start
```

### 6.4 Gameplay Flow
```
1. Question Board Page (Jeopardy-style grid)
   ├─> Host selects a question
   │
2. Question Display
   ├─> All players see question
   ├─> Buzzers enabled
   │
3. Buzzer Race
   ├─> Players hit buzzer button
   ├─> Top 3 fastest buzzers recorded (timestamp-based)
   ├─> Buzzers disabled
   │
4. Answer Phase
   ├─> Top 3 buzzers get to answer
   ├─> Host validates answers
   │   ├─> Correct → Add points
   │   └─> Wrong → Deduct points
   │
5. Score Update
   ├─> Real-time leaderboard updates
   ├─> Return to Question Board
   │
6. Next Question
   ├─> Host selects next question
   └─> Repeat until all questions answered
   │
7. Game End
   └─> Final Page
       ├─> Winner announcement
       ├─> Final leaderboard
       └─> Detailed statistics (accuracy, avg points, first hits)
```

### 6.5 Marketplace Flow
```
1. Marketplace Page (Currently: Coming Soon)

   Planned Flow:
   ├─> Browse public sets (where isPrivate=false AND status=complete)
   ├─> Filter by: Tags, Difficulty, Price (Free/Paid)
   ├─> Sort by: Rating, Downloads, Date, Name
   ├─> View set details
   │   ├─> Preview questions (limited)
   │   ├─> View rating & downloads
   │   ├─> See difficulty level, tags
   │   ├─> Check price (if applicable)
   │   └─> View author info
   ├─> Download/Purchase set
   ├─> Add to personal library
   └─> Leave rating/review
```

## 7. Real-time Game Flow (Technical)

### 7.1 Room Synchronization
**Database:** Firebase Realtime Database

**Room States:**
- `waiting` - Lobby, waiting for players
- `active` - Game in progress
- `questionActive` - A question is currently being displayed
- `ended` - Game finished

**Real-time Listeners:**
1. **Room Info Listener**
   - Monitors room status changes
   - Tracks current question number
   - Detects game start/end
2. **Players Listener**
   - Real-time player join/leave
   - Connection status monitoring
   - Last seen timestamps
3. **Buzzers Listener**
   - Listens for buzzer presses
   - Orders by timestamp
   - Identifies top N buzzers
4. **Scores Listener**
   - Live score updates
   - Leaderboard synchronization
5. **Game State Listener**
   - Buzzer enable/disable status
   - Question active status

### 7.2 Buzzer System Implementation
```
1. Question Starts
   └─> Host sets gameState.buzzersEnabled = true
       └─> All clients enable buzzer button

2. Player Buzzes
   └─> Client writes to /rooms/{roomCode}/buzzers/{buzzerId}
       {
         playerId: "player123",
         playerName: "John",
         timestamp: 1234567890,
         questionNumber: 5,
         position: 0 (calculated server-side)
       }

3. Buzzer Processing
   └─> All clients listen to /buzzers
       └─> Sort by timestamp (ascending)
       └─> Identify top 3
       └─> Display buzzer order UI

4. Answer Phase
   └─> Host disables buzzers (gameState.buzzersEnabled = false)
   └─> Host validates answers for top 3
   └─> Updates scores in /scores/{playerId}

5. Reset
   └─> Clear buzzers for current question
   └─> Enable buzzers for next question
```

### 7.3 Connection Management
- **Presence Detection**
  - Players have `isConnected` boolean
  - Last seen timestamp updated periodically
  - Disconnected players marked as inactive
- **Host Migration** (if implemented)
  - If host disconnects, assign new host
  - Maintain game continuity

## 8. Backend Services

### 8.1 Cloud Functions
**Location:** `/functions/index.js`

**Function 1: cleanupOldRooms**
- **Trigger:** Scheduled (every Sunday at 00:00 PST)
- **Purpose:** Remove expired game rooms
- **Logic:**
  1. Query all rooms in Realtime Database
  2. Check each room's `deleteAt` timestamp
  3. Delete room if:
     - `deleteAt` exists and is in the past
     - `deleteAt` does not exist (orphaned room)
  4. Keep room if `deleteAt` is in the future
- **Logging:** Detailed logs for each room action

**Future Functions (Recommended):**
- `onUserCreate` - Initialize user profile in Firestore
- `onSetPublish` - Validate set completeness
- `updateSetRating` - Calculate average rating from reviews
- `incrementDownloadCount` - Track set downloads
- `generateThumbnails` - Create thumbnails for media uploads

### 8.2 Security Rules (Recommended)

**Firestore Rules:**
```javascript
// Users can read their own data, admins can read all
match /users/{userId} {
  allow read: if request.auth != null &&
    (request.auth.uid == userId || isAdmin());
  allow write: if request.auth.uid == userId;
}

// Sets can be read by all, written by author
match /sets/{setId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update, delete: if request.auth.uid == resource.data.authorId;
}

// Boards can be read by all, written by author
match /boards/{boardId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update, delete: if request.auth.uid == resource.data.authorId;
}
```

**Realtime Database Rules:**
```json
{
  "rules": {
    "rooms": {
      "$roomCode": {
        ".read": true,
        ".write": "auth != null",
        "players": {
          "$playerId": {
            ".write": "auth != null && auth.uid == $playerId"
          }
        }
      }
    }
  }
}
```

## 9. Database Design Recommendations

### 9.1 Cloud Firestore Collections

**Collection: `users`**
```
users/{userId}
  - uid: string
  - email: string
  - displayName: string
  - photoURL: string
  - createdAt: timestamp
  - lastLogin: timestamp
  - updatedAt: timestamp
  - stats: {
      totalGamesPlayed: number
      totalSetsCreated: number
      totalBoardsCreated: number
      averageScore: number
    }
```

**Collection: `sets`**
```
sets/{setId}
  - id: string
  - name: string
  - description: string
  - authorId: string (indexed)
  - tags: array<string> (indexed)
  - difficulty: string (indexed)
  - creationDate: timestamp
  - price: number
  - downloads: number
  - rating: number
  - isPublished: boolean (indexed)
  - questions: array<Question> (max 5, embedded)
```

**Collection: `boards`**
```
boards/{boardId}
  - id: string
  - name: string
  - description: string
  - authorId: string (indexed)
  - creationDate: timestamp
  - modifiedDate: timestamp
  - rating: number
  - downloads: number
  - price: number
  - isPublished: boolean (indexed)
  - setIds: array<string> (max 5)
    // NOTE: Store only IDs, not full set objects
```

**Collection: `reviews` (Recommended)**
```
reviews/{reviewId}
  - setId: string (indexed)
  - userId: string (indexed)
  - rating: number (1-5)
  - comment: string
  - createdAt: timestamp
  - helpful: number (upvote count)
```

**Collection: `gameHistory` (Recommended)**
```
gameHistory/{gameId}
  - roomCode: string
  - hostId: string
  - boardId: string
  - players: array<{
      playerId: string
      name: string
      finalScore: number
      correctAnswers: number
      wrongAnswers: number
      accuracy: number
      firstHits: number
    }>
  - winner: {
      playerId: string
      name: string
      score: number
    }
  - startedAt: timestamp
  - endedAt: timestamp
  - duration: number (seconds)
```

### 9.2 Firebase Realtime Database Structure

```
/rooms
  /{roomCode}
    /roomInfo
      roomCode: string
      hostId: string
      status: "waiting" | "active" | "questionActive" | "ended"
      createdAt: number (timestamp)
      maxPlayers: number
      currentQuestion: number
      totalQuestions: number
      questionStartTime: number
      deleteAt: number (timestamp, for cleanup)

    /players
      /{playerId}
        name: string
        isHost: boolean
        joinedAt: number
        buzzCount: number
        isConnected: boolean
        lastSeen: number

    /buzzers
      /{buzzerId}
        playerId: string
        playerName: string
        timestamp: number
        questionNumber: number
        position: number

    /gameState
      questionActive: boolean
      buzzersEnabled: boolean
      topBuzzersCount: number

    /board
      // Current board/set data for the game

    /scores
      /{playerId}: number
```

### 9.3 Indexing Strategy

**Cloud Firestore Composite Indexes:**
1. `sets`: `(authorId, creationDate DESC)`
2. `sets`: `(tags, rating DESC)`
3. `sets`: `(difficulty, downloads DESC)`
4. `sets`: `(isPublished, creationDate DESC)`
5. `boards`: `(authorId, modifiedDate DESC)`
6. `boards`: `(isPublished, rating DESC)`
7. `reviews`: `(setId, createdAt DESC)`
8. `gameHistory`: `(hostId, endedAt DESC)`

**Realtime Database Indexes:**
1. `rooms/.indexOn`: `["createdAt", "status"]`

### 9.4 Data Optimization

**Implemented Optimizations:**
1. ✅ **Board Model** - Now stores only set IDs instead of full SetModel objects
   - Boards reference sets via `setIds: List<String>`
   - Sets are fetched separately when needed
   - Allows same set to be reused across multiple boards efficiently

2. ✅ **Set Privacy** - `isPrivate` field implemented
   - Default: `true` (private)
   - Can be toggled to `false` (public) for marketplace listing
   - Draft sets cannot be published (validation enforced)

3. ✅ **Media Storage** - Full Media model with metadata
   - Stores type, storagePath, downloadURL
   - Includes dimensions (width, height, aspectRatio) for images/videos
   - Tracks file size, status, optional thumbnailURL and altText

**Current Implementation Status:**
- Boards: Store set IDs only (optimized) ✅
- Sets: Include privacy controls ✅
- Media: Full metadata model ✅
- Marketplace: Not yet implemented (coming soon)

**Storage Estimates:**
- User document: ~500 bytes
- Set document (with 5 questions, text only): ~5-10 KB
- Set document (with media): ~15-25 KB
- Board document (with 5 set IDs): ~1-2 KB
- Room (active game): ~10-50 KB (depends on player count)

## 10. Future Enhancements

### 10.1 Planned Features
- **Marketplace Implementation** - Browse and download public sets
  - Filter and search functionality
  - Set preview before download
  - Rating and review system
- **Payment Integration** - Enable paid sets (price field exists but not active)
- **User Following** - Follow favorite creators
- **Set Collections** - Organize downloaded/favorited sets
- **Game History** - Track past games and personal statistics
- **Leaderboards** - Global/weekly/monthly rankings
- **Achievements** - Gamification elements
- **Live Streaming** - Spectator mode for games
- **Custom Themes** - User-selectable themes (currently dark only)
- **AI Question Generation** - Generate questions from topics
- **Custom Point Values** - Allow users to set custom points per question
- **Media Thumbnails** - Auto-generate thumbnails for video/images

### 10.2 Scalability Considerations
- **Caching Strategy** - Cache popular sets/boards
- **CDN Integration** - Serve media via CDN
- **Database Partitioning** - Separate hot/cold data
- **Read Replicas** - Reduce read latency
- **Rate Limiting** - Prevent abuse
- **Batch Operations** - Optimize bulk data operations

### 10.3 Analytics & Monitoring
- **Firebase Analytics** - Track user engagement
- **Crashlytics** - Error monitoring
- **Performance Monitoring** - App performance metrics
- **Custom Events** - Track key user actions
  - Set created
  - Game completed
  - Set downloaded
  - Buzzer pressed

---

## Appendix: Key File References

- **Main Entry:** `lib/main.dart`
- **Models:** `lib/models/`
- **Pages:** `lib/pages/`
- **Providers:** `lib/providers/`
- **Services:** `lib/services/`
- **Cloud Functions:** `functions/index.js`
- **Dependencies:** `pubspec.yaml`
- **Firebase Config:** `firebase_options.dart`, `firebase.json`

---

## Document Changelog

### Version 2.0 (December 13, 2024)
**Major Updates:**
- Added Media model (4.2) with full metadata support for images/audio/video
- Updated Set model (4.4) with `isPrivate` field and `authorName`
- Updated Board model (4.5) to store set IDs instead of full objects
- Added privacy controls to set creation flow
- Updated technology stack with all current dependencies
- Documented set import functionality (Excel/CSV)
- Updated marketplace status (coming soon, not active)
- Clarified guest user limitations
- Updated content creation flow with current UI
- Added implemented optimizations section
- Updated storage estimates

### Version 1.0 (November 25, 2024)
- Initial documentation

---

**Document Version:** 2.0
**Last Updated:** December 13, 2024
**Status:** Current implementation state with privacy controls, media metadata, and board optimization
