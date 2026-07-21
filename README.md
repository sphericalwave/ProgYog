# groundWerk

A progressive yoga & bodyweight-skill training app for iOS (and macOS), built with SwiftUI.
groundWerk helps you work through a structured catalog of poses and skills, log your sets,
watch your form with a live on-device skeleton overlay, and track progress over time — with
your history synced across devices via iCloud.

> The Xcode target, scheme, and bundle identifier remain `ProgYog` / `SWS.ProgYog` for
> continuity; **groundWerk** is the user-facing display name.

## Features

- **Skill catalog** — browse skill families, abstract skills, and progressive yoga series
  with posters and per-pose imagery.
- **Guided sessions** — run a workout session, log sets (`SetLog`), and get a completion
  score for each session.
- **Vision posture coach** — a real-time camera skeleton overlay (Apple Vision) analyzes
  your alignment during practice, with an on-screen HUD and optional recordings.
- **Heart rate** — connect a BLE chest strap to capture live heart rate; samples are stored
  and charted per session.
- **Progress dashboards** — Swift Charts views for HR curves, metric/skill trends, and
  per-family completion.
- **Apple Health** — completed sessions are logged to Health as Yoga workouts.
- **Apple Calendar** — completed workouts mirror into a dedicated "Workout" calendar
  (deep-linkable back into the app).
- **Reminders** — local notifications to schedule your next workout.
- **Shake to undo** — accidentally deleted a set or session? Shake to restore it.
- **iCloud sync** — all data is stored in CloudKit-backed Core Data and syncs across your
  devices.

## Tech stack

- **SwiftUI**, targeting iOS 26 and macOS 14+ (universal — `RootView` on iOS,
  `MacRootView` on macOS).
- **Core Data + CloudKit** (`NSPersistentCloudKitContainer`, model `ProgressiveYog7`,
  iCloud container `iCloud.SWS.ProgYog`).
- **Apple Vision** for pose detection, **CoreBluetooth** for heart rate, **HealthKit**,
  **EventKit**, and **UserNotifications**.
- **Swift Charts** for all trend/history visualizations.
- Shared functionality lives in Swift packages pulled from GitHub
  (`github.com/sphericalwave/*`): `WorkoutSyncKit`, `WorkoutSessionKit`, `WorkoutAudioKit`,
  `SetLogKit`, `EquipmentKit`, `SwKeyboard`.

## Project structure

```
ProgYog/
├── ProgYogApp.swift        App entry point; builds AppServices
├── Models/                 Domain models (e.g. TEDDescription)
├── Data/
│   ├── CoreData/           NSManagedObject subclasses + .xcdatamodeld
│   └── Json/               JSON/CSV seed import
├── Services/               AppServices (DI root), Core Data, heart rate,
│                           pose detection, posture analysis, Health, Calendar,
│                           reminders, session recovery, undo, scoring
└── Views/
    ├── Root/               RootView (tabs) + MacRootView
    ├── Workouts/           Session flow, set logging, skill pickers
    ├── Catalog/            Skill families, skill detail, poster gallery
    ├── Pose/               Camera preview, skeleton overlay, posture HUD
    ├── Charts/             HR + trend + completion charts
    ├── Dashboard/          Progress dashboard
    ├── History/            Session history
    ├── Onboarding/         First-run onboarding
    └── Settings/           App settings
```

The app is organized around `AppServices` (an `@StateObject` dependency container) that owns
the Core Data stack and the feature services; SwiftUI views receive it via the environment.

## Requirements

- Xcode 26+
- An Apple Developer account (for HealthKit, iCloud/CloudKit, and device runs)

## Building & running

Open `ProgYog.xcodeproj` in Xcode, select the `ProgYog` scheme, and run on a device or
simulator. Swift package dependencies resolve automatically from GitHub.

Tests run via the `ProgYog` scheme (`ProgYogTests` unit tests, `ProgYogUITests` UI tests).
UI tests launch with `-UI-TESTING`, which routes the app to an **in-memory** store so tests
never touch real logged workouts.

## TestFlight

Distribution is automated with [fastlane](fastlane/). The `beta` lane builds an App Store
archive and uploads it to TestFlight:

```sh
export ASC_KEY_ID=…
export ASC_ISSUER_ID=…
export ASC_KEY_PATH=…      # path to your App Store Connect API .p8 key
bundle exec fastlane beta
```

See `fastlane/Fastfile` for details.
