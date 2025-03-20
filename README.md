# MyFinance



## Setup Instructions

1. Clone the repository:
```bash
git clone https://github.com/Avijitbera/MyFinance.git
cd MyFinance
```

2. Install dependencies:
```bash
flutter pub get
```

3. Firebase Setup:
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download and add the configuration files:
     - For Android: Place `google-services.json` in `android/app/`
     - For iOS: Place `GoogleService-Info.plist` in `ios/Runner/`

## Running the App

1. Connect a device or start an emulator

2. Run the app:
```bash
flutter run
```


## Dependencies

- `provider`: State management
- `firebase_core`: Firebase core functionality
- `firebase_auth`: User authentication
- `cloud_firestore`: Cloud database
- `isar`: Local database
- `intl`: Internationalization
- `uuid`: Unique ID generation
- `path_provider`: File system access
