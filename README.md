# Location Tracker

A Flutter application that continuously tracks and records the device's GPS location every 60 seconds, including when the app is running in the background. The app also displays the device's current battery percentage and location status using native platform integration.

## Features

- **Background Location Tracking:** Tracks GPS coordinates (Latitude, Longitude, Timestamp, Accuracy) every 60 seconds even when the app is in the background, minimized, or the screen is locked.
- **Local Data Storage:** Location data is persistently saved locally using [Hive](https://pub.dev/packages/hive), a lightweight and blazing-fast key-value database written in pure Dart.
- **Native Battery Monitoring:** Displays real-time battery percentage using a native Android `EventChannel` (BroadcastReceiver) and `MethodChannel`, without relying on third-party battery plugins.
- **Dynamic Service State:** Automatically halts background tracking if the user disables device location services.
- **Permissions Handling:** Comprehensive handling of Location, Background Location, and Notification permissions seamlessly.

## Architecture & Technical Stack

The app is built following a clean, modular architecture separating UI, state management, and background services.

### 1. State Management (Provider)
We use the `provider` package (`ChangeNotifierProvider`) to manage the application's UI state. The `TrackingProvider` acts as the bridge between the UI and the underlying services. It listens to background service events and triggers UI rebuilds when new location data is available or when tracking status changes.

### 2. Local Storage (Hive)
Hive was chosen over SQLite for its exceptional read/write performance and simplicity. 
- **Concurrency Handling:** Since the background tracking runs in a separate Dart Isolate, the background service writes directly to the Hive box on disk. The main UI isolate then reloads the Hive box to reflect the newly written data.

### 3. Background Execution
The core of the background processing is powered by `flutter_background_service`.
- **Isolates:** When tracking starts, a background Dart isolate is spawned. This isolate operates independently of the UI.
- **Foreground Service:** On Android, it runs as a Foreground Service with a persistent notification, ensuring the OS does not aggressively kill the process.

### 4. Native Platform Channels
To fulfill the requirement of not using a third-party package for battery status, the app implements custom Platform Channels:
- **`MethodChannel`:** Fetches the instantaneous battery level when the app starts.
- **`EventChannel`:** Subscribes to the Android `ACTION_BATTERY_CHANGED` broadcast intent. This provides a continuous stream of battery level updates directly to the Flutter UI, which are consumed via a `StreamSubscription`.

## Application Workflow

1. **Initialization:** On app startup, `Hive` is initialized, native battery levels are fetched via `MethodChannel`, and the app checks if the background service is already running from a previous session.
2. **Permissions:** When the user taps the "START" button, the app sequentially requests necessary permissions: Location -> Notification -> Background Location ("Allow all the time").
3. **Background Tracking:** 
   - Once permissions are granted, `BackgroundTrackingService.start()` is invoked.
   - The background isolate begins execution. It initializes its own Hive instance.
   - It captures an initial high-accuracy GPS fix using `Geolocator`.
   - A `Timer.periodic` is set to capture and save the location every 60 seconds.
   - After each write to disk, the background isolate calls `service.invoke('update')` to notify the main isolate.
4. **UI Synchronization:** The `TrackingProvider` on the main isolate listens for the `'update'` event. When received, it calls `HiveService.reload()` to sync the disk changes into memory and calls `notifyListeners()` to update the UI with the latest location list.
5. **Auto-Stop Mechanism:** The UI isolate actively listens to `Geolocator.getServiceStatusStream()`. If the user disables device GPS globally, the `TrackingProvider` automatically invokes `stopTracking()` to clean up.
6. **Battery Status:** Concurrently, the `BatteryCard` widget listens to the native `EventChannel` stream and updates its UI instantly whenever the Android OS broadcasts a battery level change.

## Project Structure

```text
lib/
├── main.dart                      # App entry point & Theme definition
├── models/
│   └── location_record.dart       # Hive model for location data
├── providers/
│   └── tracking_provider.dart     # ChangeNotifier for state management
├── screens/
│   ├── home_screen.dart           # Main dashboard UI
│   └── main_shell.dart            # Scaffold wrapper (Bottom Navigation)
├── services/
│   ├── background_tracking_service.dart # Background Isolate Logic
│   ├── battery_service.dart       # Platform Channels wrapper for battery
│   └── hive_service.dart          # Local storage wrapper
├── theme/
│   └── app_colors.dart            # Centralized color palette
└── widgets/
    ├── battery_card.dart          # Displays battery & location status
    ├── location_list.dart         # List items for recorded locations
    └── tracking_controls.dart     # Start/Stop buttons
```

## How to Run

1. Ensure you have Flutter installed and an Android emulator or physical device connected.
2. Clone the repository.
3. Run `flutter pub get` to fetch dependencies.
4. Run `flutter run` to build and deploy the app.
