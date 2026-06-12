# RestoraHub

RestoraHub is a Flutter booking app for wellness and beauty services. Customers book appointments with professionals; professionals manage their schedule and incoming bookings.

## Features

- **Customer accounts** — browse services, pick a subtype, book with a matching professional
- **Professional accounts** — choose a profession at registration, set working hours and slot length in profile
- **Role locking** — account type (customer vs professional) is fixed after registration
- **Profile editing** — update name, email, phone, password; professionals also edit specialty and schedule
- **Local-first storage** — SQLite on device with a repository layer ready for future API sync
- **Session persistence** — stay logged in across restarts; theme preference is saved

## Tech stack

- Flutter / Dart
- Provider (state management)
- SQLite (`sqflite` + `sqflite_common_ffi` for desktop)
- `shared_preferences` for session and theme
- `intl` for date formatting

## Getting started

```bash
flutter pub get
flutter run -d windows   # or android, ios, chrome
```

### Run tests

```bash
flutter test
```

## User flows

### Register as a professional

1. Open **Register** → choose **Professional**
2. Select a **profession** (Massage, Haircut, Spa, Facial, Manicure)
3. Complete personal details and register
4. Open **Settings → Edit profile** to set:
   - Work day start / end
   - Appointment slot length (15–120 minutes)

### Register as a customer

1. Open **Register** → choose **Customer**
2. Complete personal details and register
3. From the dashboard, tap **+** → pick a service → choose subtype → book

### Booking

- Only professionals whose **specialty matches the service category** appear in the picker
- Time slots are generated from the professional's own hours and slot length
- Overlapping bookings for the same professional are blocked

## Project structure

```
lib/
  constants/       # Service catalog, colors, slot options
  helpers/         # Database, validation, scheduling, formatting
  models/          # User, Appointment, BookingSummary
  pages/           # UI screens
  providers/       # Auth and appointment state
  repositories/    # Local data access (swap for remote later)
  services/        # SyncService stub for future API integration
test/              # Unit tests
```

## Data model notes

| Field | Customer | Professional |
|-------|----------|--------------|
| `role` | `customer` | `professional` |
| `specialty` | empty | required (e.g. Massage) |
| `workStartTime` / `workEndTime` | defaults | editable in profile |
| `slotDurationMinutes` | defaults | editable in profile |

## Future backend sync

`lib/services/sync_service.dart` exposes `pullRemoteChanges()` and `pushPendingChanges()`. Wire these to your REST API when ready; the UI **Sync data** action in Settings already calls the service.

## License

Private project — not published to pub.dev.
