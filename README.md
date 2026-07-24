# RestoraHub

RestoraHub is a Flutter booking app for wellness and beauty services. Customers book appointments with professionals; professionals manage their schedule and incoming bookings.

## Features

- **Customer accounts** — browse services, pick a subtype, book with a matching professional
- **Professional accounts** — choose a profession at registration, set working hours and slot length in profile
- **Role locking** — account type (customer vs professional) is fixed after registration
- **Profile editing** — update name, email, phone, password; professionals also edit specialty and schedule
- **Password recovery** — reset password via Firebase email link
- **First-login profile completion** — new users are prompted to provide name, phone, and role on first sign-in
- **Theme selection** — teal, dark, rose, or indigo; preference is saved locally via `shared_preferences`
- **Loading and error states** — all data-loading screens show progress indicators and error messages with retry

## Tech stack

- Flutter / Dart
- Provider (state management)
- Firebase Auth (authentication)
- Cloud Firestore (users and appointments)
- `shared_preferences` for theme preference
- `intl` for date formatting

## Getting started

```bash
flutter pub get
flutter run -d windows   # or android, web
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
4. Open **Settings → Edit profile** to set work hours and slot length

### Register as a customer

1. Open **Register** → choose **Customer**
2. Complete personal details and register
3. From the dashboard, tap **+** → pick a service → choose subtype → book

### Login with a new account (first-time)

1. Sign in with email and password
2. If the account has no profile yet, a **Complete your profile** dialog appears
3. Provide name, phone, and account type (customer or professional)
4. For professionals, select a specialty from the dropdown
5. After saving, the app navigates to the appropriate home screen

### Booking

- Only professionals whose **specialty matches the service category** appear in the picker
- Time slots are generated from the professional's own hours and slot length
- Overlapping bookings for the same professional are blocked

### Cancel / Reschedule

- Customers can cancel bookings from their home screen
- Customers can reschedule by picking a new time slot
- Professionals can cancel incoming bookings from their management screen

## Project structure

```
lib/
  constants/       # Service catalog and scheduling options
  helpers/         # Validation, scheduling, formatting, theme prefs, typed exceptions
  models/          # User, Appointment, BookingSummary
  pages/           # UI screens (login, register, home, booking, profile, etc.)
  providers/       # Auth, appointments, and theme state (ChangeNotifier)
  repositories/    # Abstract BookingRepository + Firestore implementation
  widgets/         # Shared UI components
  firebase_options.dart
  main.dart        # App entry point, provider setup, route resolution
test/              # Unit tests
```

## Data model notes

| Field | Customer | Professional |
|-------|----------|--------------|
| `role` | `customer` | `professional` |
| `specialty` | empty | required (e.g. Massage) |
| `workStartTime` / `workEndTime` | defaults | editable in profile |
| `slotDurationMinutes` | defaults | editable in profile |

Credentials are stored in **Firebase Auth**. Profile and booking data live in **Firestore** (`users` and `appointments` collections).

## Architecture notes

- **Repository pattern** — `BookingRepository` is an abstract interface; `FirestoreBookingRepository` is the sole concrete implementation. This allows swapping data sources in the future.
- **Typed exceptions** — `AppException` wraps repository errors with a message and optional cause. UI code catches `AppException` to show user-friendly messages.
- **State management** — Provider + ChangeNotifier. `AppointmentProvider` exposes `isLoading` and `error` for UI feedback; `AuthProvider` exposes `LoginResult` enum for first-login flows.
- **Theme persistence** — `ThemeProvider` loads/saves the selected theme via `ThemePreferences` (shared_preferences) before the app renders.