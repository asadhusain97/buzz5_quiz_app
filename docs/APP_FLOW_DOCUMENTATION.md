# Buzz5 Quiz App - Application Flow Documentation

## 1. Overview

Buzz5 Quiz App is a real-time, multiplayer quiz platform built with Flutter that enables users to create, share, and compete in live trivia games. The app features a Jeopardy-style game board with custom question sets, real-time buzzer mechanics, and a marketplace for sharing user-generated content.

**Target Platforms:** Web, iOS, Android (Flutter cross-platform)

## 2. Technology Stack

### Frontend
- **Framework:** Flutter (SDK 3.7.0+)
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

### Backend (Firebase)
- **Firebase Core** (v3.1.1) - Firebase initialization
- **Firebase Authentication** (v5.1.1) - User authentication
- **Cloud Firestore** (v5.0.2) - Persistent data storage
  - User profiles
  - Question sets
  - Boards (collections of sets)
  - Marketplace data
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
- **Environment Variables** - Configuration via `.env` files

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

### 4.2 Question Model
**Storage:** Cloud Firestore (embedded in Sets)

```dart
{
  id: String (Primary Key),
  questionText?: String (optional),
  questionMedia?: String (Firebase Storage URL),
  answerText?: String (optional),
  answerMedia?: String (Firebase Storage URL),
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
- Status can be set to `complete` only when both question and answer exist

### 4.3 Set Model (`SetModel`)
**Storage:** Cloud Firestore (`sets` collection)

```dart
{
  id: String (Primary Key),
  name: String,
  description: String,
  authorId: String (Foreign Key -> users.uid),
  tags: List<PredefinedTags>,
  creationDate: Timestamp,

  // Marketplace fields
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
  - `complete` if exactly 5 questions AND all are complete
  - `draft` otherwise
- `questionCount` - Number of questions (max 5)

**Business Rules:**
- Maximum 5 questions per set
- Set is only complete when it has 5 complete questions

### 4.4 Board Model (`BoardModel`)
**Storage:** Cloud Firestore (`boards` collection)

```dart
{
  id: String (Primary Key),
  name: String,
  description: String,
  authorId: String (Foreign Key -> users.uid),
  creationDate: Timestamp,
  modifiedDate: Timestamp,

  // Marketplace fields
  rating: double (default: 0.0),
  downloads: int (default: 0),
  price?: double (optional),

  // Sets array (embedded, but should be IDs)
  sets: List<SetModel> (max 5)
  // TODO: Should be List<String> (set IDs) to save space
}
```

**Computed Properties:**
- `status` - Auto-calculated:
  - `complete` if exactly 5 sets AND all are complete
  - `draft` otherwise
- `difficulty` - Average difficulty of all sets

**Business Rules:**
- Maximum 5 sets per board
- Board is complete when it has 5 complete sets
- Difficulty is calculated as average of set difficulties

### 4.5 Room Model (`Room`)
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

### 4.6 Player Model (`Player`)
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

### 4.7 Predefined Tags (Enum)
Categories for question sets:
- Architecture, Arts, Astronomy, Biology, Business
- Civics, Words, Entertainment, Fashion, Food & Drinks
- General, Geography, History, India, Literature
- Logos, Maths, Movies, Mythology, Other
- Personal, Politics, Pop Culture, Science, Songs
- Sports, Technology, US, Video Games, Wordplay, World

### 4.8 Enums Summary
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
  - Guest user support (no authentication required)
- **User Profiles**
  - Display name
  - Profile photo (via Firebase Storage)
  - Email
  - Account timestamps (created, last login, updated)

### 5.2 Content Creation
- **Question Creation**
  - Text-based questions & answers
  - Media support (images via Firebase Storage)
  - Point value assignment (default: 10)
  - Optional hints
  - Optional "funda" (concept explanation)
  - Draft/Complete status
- **Set Creation**
  - Organize questions into sets (max 5 questions)
  - Set metadata (name, description, tags)
  - Difficulty level
  - Auto-status calculation
- **Board Creation**
  - Organize sets into boards (max 5 sets)
  - Board metadata
  - Average difficulty calculation
  - Auto-status calculation

### 5.3 Marketplace
- **Browse Content**
  - View available question sets
  - Filter by tags/categories
  - Sort by rating, downloads, difficulty
- **Pricing System** (planned)
  - Free sets
  - Paid sets (price field exists)
- **Statistics**
  - Downloads counter
  - Rating system (0.0-5.0)
  - User reviews (planned)

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
   ├─> Create New Set
   │   ├─> Enter set details (name, description, tags, difficulty)
   │   ├─> Add questions (max 5)
   │   │   ├─> Enter question (text or media)
   │   │   ├─> Enter answer (text or media)
   │   │   ├─> Set points (default: 10)
   │   │   ├─> Add hint (optional)
   │   │   └─> Add funda/explanation (optional)
   │   ├─> Review set
   │   └─> Publish (when 5 complete questions)
   │
   └─> Create New Board
       ├─> Enter board details
       ├─> Add sets (max 5)
       └─> Publish (when 5 complete sets)
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
1. Marketplace Page
   ├─> Browse available sets
   ├─> Filter by tags/categories
   ├─> View set details
   │   ├─> Preview questions
   │   ├─> View rating & downloads
   │   ├─> See difficulty level
   │   └─> Check price
   ├─> Download/Purchase set
   └─> Add to library
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

**Current Issues to Address:**
1. **Board Model** - Currently stores full `SetModel` objects in `sets` array
   - **Problem:** Duplication if same set is used in multiple boards
   - **Solution:** Store only `setIds: List<string>`, fetch sets separately

2. **Set Privacy** - No privacy field
   - **Problem:** All sets are public
   - **Solution:** Add `isPublic: boolean` field to SetModel

3. **Media Storage** - URLs stored as strings
   - **Problem:** No metadata about media files
   - **Solution:** Create `MediaMetadata` model with URL, type, size, dimensions

**Storage Estimates:**
- User document: ~500 bytes
- Set document (with 5 questions): ~5-10 KB
- Board document (with 5 set IDs): ~1-2 KB
- Room (active game): ~10-50 KB (depends on player count)

## 10. Future Enhancements

### 10.1 Planned Features
- **Payment Integration** - Enable paid sets
- **Set Privacy Controls** - Public/private sets
- **User Following** - Follow favorite creators
- **Set Collections** - Organize sets into custom collections
- **Leaderboards** - Global/weekly/monthly rankings
- **Achievements** - Gamification elements
- **Live Streaming** - Spectator mode for games
- **Custom Themes** - User-selectable themes (currently dark only)
- **AI Question Generation** - Generate questions from topics

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

**Document Version:** 1.0
**Last Updated:** November 25, 2024
**Generated for:** Backend Database Design
