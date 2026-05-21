# Mobile Kasir - Flutter Firebase App

A Flutter application for a cashier system with role-based authentication using Firebase.

## Features

- **Authentication**: Login and registration with email/password
- **Role-based Access**: Owner and Employee roles
- **Owner Features**:
  - Dashboard with transaction and profit summaries
  - Manage employees (CRUD operations)
  - View all transactions
- **Employee Features**:
  - Dashboard with personal transaction summary
  - Add new transactions
  - View personal transaction history
- **Profile Management**: View and edit profile, change password, upload profile image

## Setup Instructions

### 1. Firebase Setup

1. Create a new Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Enable Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password
3. Enable Firestore Database:
   - Go to Firestore Database > Create database
   - Start in test mode (you can change rules later)
4. Enable Storage (for profile images):
   - Go to Storage > Get started
   - Set up storage bucket

### 2. Flutter Configuration

#### Android Setup:
1. Download `google-services.json` from Firebase console (Project settings > General > Your apps > Add app > Android)
2. Place `google-services.json` in `android/app/`

#### iOS Setup:
1. Download `GoogleService-Info.plist` from Firebase console
2. Place `GoogleService-Info.plist` in `ios/Runner/`

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Firestore Security Rules

Update Firestore rules in Firebase console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Owners can read all users and transactions
    match /users/{userId} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'owner';
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Transactions
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Storage Security Rules

Update Storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Running the App

```bash
flutter run
```

## Project Structure

```
lib/
├── models/
│   ├── user_model.dart
│   └── transaction_model.dart
├── providers/
│   ├── auth_provider.dart
│   └── cart_provider.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── owner/
│   │   ├── dashboard_screen.dart
│   │   └── manage_employees_screen.dart
│   ├── employee/
│   │   ├── dashboard_screen.dart
│   │   └── add_transaction_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── cart_item_tile.dart
    └── product_card.dart
```

## Usage

1. **Registration**: Users can register as either "owner" or "employee"
2. **Login**: Authenticate with email and password
3. **Role-based Navigation**: App automatically navigates based on user role
4. **Owner Dashboard**: View summaries and manage employees
5. **Employee Dashboard**: View personal data and add transactions
6. **Profile**: Manage personal information and password

## Dependencies

- firebase_core: ^2.15.1
- firebase_auth: ^4.7.3
- cloud_firestore: ^4.9.1
- firebase_storage: ^11.2.6
- image_picker: ^1.0.1
- cached_network_image: ^3.3.0
- provider: ^6.0.0

## Notes

- Profile image upload functionality is partially implemented (TODO: complete Firebase Storage integration)
- Add proper error handling and loading states as needed
- Implement pagination for large lists if required
- Add activity logs if needed
