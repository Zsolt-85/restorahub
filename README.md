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

## Bug fixes

- **Unauthenticated email check during registration** — Removed the pre-registration Firestore `isEmailTaken` query that was blocked by security rules (`request.auth != null`). Firebase Auth's `createUserWithEmailAndPassword` now handles duplicate emails natively via the `email-already-in-use` exception.
- **Slot availability false positives** — Replaced exact `isEqualTo` timestamp matching in `checkProfessionalAvailability` with a range-based overlap query. The method now queries for appointments that start before the slot ends and filters in code for actual time overlap, avoiding false matches from millisecond-level timestamp differences.
- **Availability check error handling** — Added comprehensive debug logging (`print`) to `checkProfessionalAvailability` showing query parameters, document count, per-document overlap results, and errors. Firestore permission/network failures now throw a descriptive `AppException` instead of silently returning `false` (which falsely reported slots as taken).

## Architecture improvements

- **Range-based slot availability** — `BookingRepository.checkProfessionalAvailability` now accepts a `slotDurationMinutes` parameter and uses `isLessThan` + in-code overlap detection instead of exact `isEqualTo` on the `dateTime` string field.
- **Debug observability** — All availability checks log query parameters, Firestore document counts, and overlap results via `print` statements for live debugging.

## Project status

| Area | Status |
|------|--------|
| Authentication | Registration, login, password reset, first-login profile completion |
| Booking | Slot availability check, create/cancel/reschedule appointments |
| Profile | Edit name, email, phone, password; professional specialty & schedule |
| Theme | Teal, dark, rose, indigo — persisted via shared_preferences |
| Tests | 26/26 passing (`flutter test`) |
| Analysis | Clean (`flutter analyze`) |

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
- **Slot availability** — `checkProfessionalAvailability` uses range-based overlap detection (`dateTime < slotEnd` + in-code `apptEnd > slotStart`) instead of exact timestamp matching, avoiding false positives from millisecond-level differences.

## Current Status & Continuation

For the latest project state, completed phases, test status, and next tasks, see **[CHECKPOINT.md](./CHECKPOINT.md)**.
