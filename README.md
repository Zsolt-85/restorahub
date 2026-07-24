# RestoraHub

RestoraHub is a Flutter booking app for wellness and beauty services. Customers book appointments with professionals; professionals manage their schedule and incoming bookings.

## Features

- **Customer accounts** — browse services, pick a subtype, book with a matching professional
- **Professional accounts** — choose a profession at registration, set working hours and slot length in profile
- **Role locking** — account type (customer vs professional) is fixed after registration
- **Profile editing** — update name, email, phone, password; professionals also edit specialty and schedule
- **Password recovery** — reset password via Firebase email link
- **Theme selection** — teal, dark, rose, or indigo; preference is saved locally

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

### Booking

- Only professionals whose **specialty matches the service category** appear in the picker
- Time slots are generated from the professional's own hours and slot length
- Overlapping bookings for the same professional are blocked

## Project structure

```
lib/
  constants/       # Service catalog and scheduling options
  helpers/         # Validation, scheduling, formatting, theme prefs
  models/          # User, Appointment, BookingSummary
  pages/           # UI screens
  providers/       # Auth, appointments, and theme state
  repositories/    # Firestore data access
  widgets/         # Shared UI components
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
