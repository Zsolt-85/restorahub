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
- **Professional booking confirmation** — professionals accept or decline incoming booking requests via confirmation dialog
- **Real-time notifications** — instant Firestore streaming for booking requests, confirmations, and cancellations with unread badge
- **Native calendar integration** — add confirmed bookings to device calendar (Google Calendar / Apple iCal) from the success screen
- **Upcoming / Past separation** — professionals manage upcoming bookings in a dedicated tab; past appointments are read-only

## Tech stack

- Flutter / Dart
- Provider (state management)
- Firebase Auth (authentication)
- Cloud Firestore (users, appointments, notifications)
- `shared_preferences` for theme preference
- `intl` for date formatting
- `add_2_calendar` for native calendar events

## Getting started

```bash
flutter pub get
flutter run -d windows   # or android, web
```

### Run tests

```bash
flutter test
```

## Booking flow

1. Customer selects a service and professional
2. Customer picks a date and time slot
3. Booking is created with `pending` status
4. Professional receives a real-time notification and sees the booking in the **Upcoming** tab
5. Professional accepts (→ `confirmed`) or declines (→ `cancelledByProfessional`)
6. Customer receives a notification with the professional's decision
7. Both parties can view the booking; confirmed bookings can be added to the native device calendar

## Cancellation & rescheduling policy

- Customers can cancel up to **2 hours before** the appointment start time
- Attempting to cancel within the 2-hour window shows an error: *"Appointments cannot be cancelled less than 2 hours before the start time."*
- Customers and professionals can reschedule upcoming appointments if the new slot is still available
- Past appointments cannot be modified

## Bug fixes

- **Unauthenticated email check during registration** — Removed the pre-registration Firestore `isEmailTaken` query that was blocked by security rules (`request.auth != null`). Firebase Auth's `createUserWithEmailAndPassword` now handles duplicate emails natively via the `email-already-in-use` exception.
- **Slot availability false positives** — Replaced exact `isEqualTo` timestamp matching in `checkProfessionalAvailability` with a range-based overlap query. The method now queries for appointments that start before the slot ends and filters in code for actual time overlap, avoiding false matches from millisecond-level timestamp differences.
- **Availability check error handling** — Added comprehensive debug logging (`print`) to `checkProfessionalAvailability` showing query parameters, document count, per-document overlap results, and errors. Firestore permission/network failures now throw a descriptive `AppException` instead of silently returning `false` (which falsely reported slots as taken).

## Architecture improvements

- **Repository split** — `BookingRepository` is split into `BookingRepository` (appointments) and `UserRepository` (user profiles). `FirestoreBookingRepository` handles appointment data; `FirestoreUserRepository` handles user data. Both follow the singleton pattern (`._()` private constructor + `static final instance`).
- **Range-based slot availability** — `BookingRepository.checkProfessionalAvailability` now accepts a `slotDurationMinutes` parameter and uses `isLessThan` + in-code overlap detection instead of exact `isEqualTo` on the `dateTime` string field.
- **Debug observability** — All availability checks log query parameters, Firestore document counts, and overlap results via `print` statements for live debugging.
- **Appointment state machine** — Explicit status enum (`pending`, `confirmed`, `completed`, `cancelledByCustomer`, `cancelledByProfessional`, `noShow`) with enforced transition rules and cancellation window logic.
- **Real-time Firestore streaming** — `BookingRepository` exposes `snapshots()`-based streams for customer and professional appointment lists, enabling instant UI updates without manual refresh.
- **Real-time notifications** — `NotificationProvider` subscribes to Firestore notification streams so new alerts appear instantly in the notifications list and drawer badge.
- **Upcoming/Past separation** — Professional management screen uses tabs to separate modifiable upcoming bookings from read-only past appointments.

## Project status

| Area | Status |
|------|--------|
| Phase 1: Atomic Transactions & Availability Hardening | Complete |
| Phase 2: Schedule Logic (Buffer/Break Time) | Complete |
| Phase 3: Real-Time Availability & State Machine Hardening | Complete |
| Phase 4: Native Device Calendar Integration | Complete |
| Phase 5: Dependency Injection Cleanup (Repository Split) | Complete |
| Authentication | Registration, login, password reset, first-login profile completion |
| Booking | Slot availability check, create/cancel/reschedule appointments, 2-hour cancellation window |
| Professional workflow | Accept/decline pending bookings, upcoming/past tabs, real-time updates |
| Notifications | Real-time streaming, unread badge, booking request/confirm/cancel alerts |
| Calendar | Add confirmed bookings to native device calendar |
| Profile | Edit name, email, phone, password; professional specialty & schedule |
| Theme | Teal, dark, rose, indigo — persisted via shared_preferences |
| Tests | 57/57 passing (`flutter test`) |
| Analysis | 0 errors (`flutter analyze`) |

## Checks

```bash
flutter analyze   # 0 errors
flutter test      # 57/57 passing
```

## Register as a professional

1. Open **Register** → choose **Professional**
2. Select a **profession** (Massage, Haircut, Spa, Facial, Manicure)
3. Complete personal details and register
4. Open **Settings → Edit profile** to set work hours and slot length

## Register as a customer

1. Open **Register** → choose **Customer**
2. Complete personal details and register
3. From the dashboard, tap **+** → pick a service → choose subtype → book

## Login with a new account (first-time)

1. Sign in with email and password
2. If the account has no profile yet, a **Complete your profile** dialog appears
3. Provide name, phone, and account type (customer or professional)
4. For professionals, select a specialty from the dropdown
5. After saving, the app navigates to the appropriate home screen

## Booking

- Only professionals whose **specialty matches the service category** appear in the picker
- Time slots are generated from the professional's own hours and slot length
- Overlapping bookings for the same professional are blocked
- New bookings appear as `pending` on the professional's **Upcoming** tab
- Professionals must **accept** or **decline** each pending booking
- Customers receive a notification once the professional responds

## Cancel / Reschedule

- Customers can cancel bookings from their home screen (up to 2 hours before the appointment)
- Customers can reschedule by picking a new time slot
- Professionals can cancel or reschedule incoming bookings from their management screen
- Past appointments cannot be modified

## Notifications

- Real-time notifications appear in the **Notifications** screen and drawer badge
- Types: booking requested, confirmed, cancelled, rescheduled, completed, upcoming reminder
- Tap a notification to mark it as read; use the drawer action to mark all as read

## Add to Calendar

- After a successful booking, the confirmation screen shows **Add to Calendar**
- Tapping it creates a native calendar event with booking details, contact info, and a 1-hour reminder

## Project structure

```
lib/
  constants/       # Service catalog and scheduling options
  helpers/         # Validation, scheduling, formatting, theme prefs, typed exceptions, calendar export
  models/          # User, Appointment, BookingSummary, Notification
  pages/           # UI screens (login, register, home, booking, profile, etc.)
  providers/       # Auth, appointments, theme, notifications, payments (ChangeNotifier)
  repositories/    # Abstract BookingRepository + Firestore implementation, UserRepository + FirestoreUserRepository
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
| `bufferTimeMinutes` | — | editable in profile |
| `breakStartTime` / `breakEndTime` | — | editable in profile |

### Appointment statuses

| Status | Meaning |
|--------|---------|
| `pending` | Awaiting professional confirmation |
| `confirmed` | Accepted by professional |
| `completed` | Service delivered / payment linked |
| `cancelledByCustomer` | Cancelled by customer |
| `cancelledByProfessional` | Declined by professional |
| `noShow` | Customer did not attend |

Terminal statuses (`completed`, `cancelledByCustomer`, `cancelledByProfessional`, `noShow`) cannot transition to any other status.

Credentials are stored in **Firebase Auth**. Profile, booking, and notification data live in **Firestore** (`users`, `appointments`, and `notifications` collections).

## Architecture notes

- **Repository pattern** — `BookingRepository` and `UserRepository` are abstract interfaces; `FirestoreBookingRepository` and `FirestoreUserRepository` are the concrete implementations. This allows swapping data sources in the future.
- **Typed exceptions** — `AppException` wraps repository errors with a message and optional cause. UI code catches `AppException` to show user-friendly messages.
- **State management** — Provider + ChangeNotifier. `AppointmentProvider` exposes `isLoading` and `error` for UI feedback; `AuthProvider` exposes `LoginResult` enum for first-login flows.
- **Theme persistence** — `ThemeProvider` loads/saves the selected theme via `ThemePreferences` (shared_preferences) before the app renders.
- **Slot availability** — `checkProfessionalAvailability` uses range-based overlap detection (`dateTime < slotEnd` + in-code `apptEnd > slotStart`) instead of exact timestamp matching, avoiding false positives from millisecond-level differences.
- **Real-time streams** — Appointment and notification lists use Firestore `snapshots()` so UI stays in sync across devices without pull-to-refresh.
- **Calendar export** — `CalendarHelper.addToNativeCalendar` builds a native event via `add_2_calendar` with booking details, contact info, and a 1-hour reminder.
