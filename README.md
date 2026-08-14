# RestoraHub

RestoraHub is a Flutter booking app for wellness and beauty services. Customers book appointments with professionals; professionals manage their schedule and incoming bookings.

## 🚀 Live Deployment

- **Live Web App:** [https://restorahub-2da2c.web.app](https://restorahub-2da2c.web.app)
- **Hosting:** Firebase Hosting with SPA path routing (`usePathUrlStrategy`)

## ✨ Recent Enhancements

- **PWA Branding Update:** Replaced default Flutter icons with the new minimalistic `logo_minimal.png` across `web/index.html`, `web/manifest.json`, and Firebase Hosting.
- **Service Cards Refresh:** Updated service card layouts and content in the customer booking flow for a cleaner, more modern presentation.
- **High-Contrast Themes:** 4 world-class palettes (Teal Clean, Midnight Dark, Rose Gold, Deep Slate) with 100% visible active, inactive, and disabled states.
- **Profile Avatar Badge:** Top-right app bar widget with user initials, role chip, theme switcher, and logout.
- **Interactive Empty States:** Engaging CTA cards when lists or booking feeds are empty.
- **Skeleton Shimmers:** Shimmer loading states for appointment cards replacing central spinners.
- **Production PWA Support:** HTML5 meta tags, manifest, and custom app bar theme coloring.
- **Notification Repository Split:** `NotificationRepository` (abstraction) and `FirestoreNotificationRepository` (implementation) split into separate files, matching the standard used by bookings, users, and payments.
- **Route Centralization & Guard Hardening:** All navigation routes are defined as constants in `lib/constants/routes.dart` and registered in `main.dart`'s `onGenerateRoute`. Parameterized pages (`booking`, `editAppointment`, `addPayment`, `receipt`, `success`) receive arguments via `settings.arguments`. Raw `MaterialPageRoute` pushes and hardcoded route strings were replaced with `Navigator.pushNamed` + route constants across the codebase.
- **Professional Manual Booking:** Professionals can create bookings directly for customers from the management screen via `ProfessionalManualBookingPage`. The page loads registered customers (`role == 'customer'`) from Firestore, supports search/selection by **name, email, or phone number**, displays **phone number in search result items**, and shows a **selected customer preview card** with full name, phone, and email plus a clear/change button. Services are **filtered by the logged-in professional's specialty** (e.g., Haircut services only appear for hair-cut professionals), the **professional ID is locked** to the current user, and **time slot generation uses the exact same availability checking** as the customer booking page — `ScheduleHelper.generateSlots` + `ScheduleHelper.isSlotAvailable` against the professional's appointments for the selected date, with booked slots displayed as disabled choice chips labeled "Booked".

## 🔄 Recent System Updates

### Firestore Persistence Fix
Atomic server writes are verified with a synchronous server read (`GetOptions(source: Source.server)`) in `FirestoreBookingRepository.createAppointmentAtomic` and `insertAppointment` (`lib/repositories/firestore_booking_repository.dart`). After a write, the document is re-fetched directly from the Firestore server; a missing `document.exists` now throws an `AppException` ("Server write rejected: Document does not exist on Firestore server.") instead of silently trusting offline cache, eliminating false-positive booking confirmations.

### Customer Dashboard Tabs
The customer dashboard uses a strict dual-tab layout — **Upcoming** vs. **History** (`lib/pages/user_home_page.dart`) — backed by `AppointmentProvider` (`lib/providers/appointment_provider.dart`). `upcomingAppointments` filters to `!isTerminal && !dateTime.isBefore(now)` and sorts **ascending** (closest first); `pastAppointments` filters to `dateTime.isBefore(now) || isTerminal` and sorts **descending** (most recent first), keeping past/cancelled bookings read-only and visually segregated from upcoming ones.

### UI/UX Refinement
The dashboard `TabBar` now uses a theme-based `UnderlineTabIndicator` (`Theme.of(context).colorScheme.primary`, width `3.0`) with `TabBarIndicatorSize.label`. Active tab text is primary-colored and unselected text is `Colors.black87` for clean contrast; the `TabBar` is wrapped in a padded `Container` with `isScrollable: false` so both tabs share equal width, with simple `Tab(text:)` labels and no forced-width backgrounds that caused clipping/overflow.

### Context & Lifecycle Safety
Post-async operations now guard against unmounted `BuildContext` lookups. Page widgets (`booking_page.dart`, `add_payment_page.dart`, `edit_appointment_page.dart`, `login_page.dart`, `registration_page.dart`, `earnings_report_page.dart`, `forgot_password_page.dart`, `success_page.dart`) and `lib/helpers/appointment_actions.dart` check `mounted` / `context.mounted` before calling `setState`, `Navigator`, or showing dialogs, preventing `setState`-after-dispose and navigation-after-dispose exceptions.

## Features

- **Customer accounts** — browse services, pick a subtype, book with a matching professional
- **Professional accounts** — choose a profession at registration, set working hours and slot length in profile
- **Role locking** — account type (customer vs professional) is fixed after registration
- **Profile editing** — update name, email, phone, password; professionals also edit specialty and schedule
- **Password recovery** — reset password via Firebase email link
- **First-login profile completion** — new users are prompted to provide name, phone, and role on first sign-in
- **User Profile Avatar Widget** — Top-right app bar avatar with initials, role badge (Customer / Professional), profile navigation, theme switcher dialog, and logout.
- **World-class high-contrast themes** — Overhauled `ThemeProvider` with 4 distinct palettes (Teal Clean, Midnight Dark, Rose Gold, Deep Slate) ensuring 100% contrast visibility across active, inactive, and disabled states for chips, tabs, and buttons.
- **Selection component contrast** — High-contrast styling for time-slot chips, category buttons, and tab bars with explicit active/inactive/disabled color states.
- **Interactive empty states** — CTA cards with direct action buttons when appointment feeds or requests are empty.
- **Skeleton loading shimmers** — Smooth pulsing shimmers during Firestore appointment loading.
- **Theme selection** — 4 high-contrast themes (Teal Clean, Midnight Dark, Rose Gold, Deep Slate); preference is saved locally via `shared_preferences`
- **Loading and error states** — all data-loading screens show progress indicators and error messages with retry
- **Professional booking confirmation** — professionals accept or decline incoming booking requests via confirmation dialog
- **Real-time notifications** — instant Firestore streaming for booking requests, confirmations, and cancellations with unread badge
- **Native calendar integration** — add confirmed bookings to device calendar (Google Calendar / Apple iCal) from the success screen
- **Upcoming / Past separation** — professionals manage upcoming bookings in a dedicated tab; past appointments are read-only
- **Centralized route guards** — `RouteGuardHelper.evaluateRedirect` enforces auth requirements, profile completion, and role-based access on every named-route transition via `onGenerateRoute`

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
- **Date-bounded availability queries** — `checkProfessionalAvailability` and `createAppointmentAtomic` now restrict Firestore queries to the specific calendar date of the requested slot using `isGreaterThanOrEqualTo(startOfDay)` / `isLessThanOrEqualTo(endOfDay)`. This replaces the previous unbounded `isLessThan(slotEnd)` and unfiltered queries that loaded all historical appointment records for a professional. The composite index on `professionalId` (ASC), `status` (ASC), `dateTime` (ASC) in `firestore.indexes.json` supports these filtered queries.
- **Availability check error handling** — Added comprehensive debug logging (`print`) to `checkProfessionalAvailability` showing query parameters, document count, per-document overlap results, and errors. Firestore permission/network failures now throw a descriptive `AppException` instead of silently returning `false` (which falsely reported slots as taken).
- **Raw exception exposure in UI** — Replaced scattered `e.toString()` and `$e` interpolation in page catch blocks with `ErrorHandler.getDisplayMessage`, which maps `AppException`, `FirebaseAuthException`, `FirebaseException`, and generic exceptions to user-safe, localized strings.

## Architecture improvements

- **Repository split** — `BookingRepository` is split into `BookingRepository` (appointments) and `UserRepository` (user profiles). `FirestoreBookingRepository` handles appointment data; `FirestoreUserRepository` handles user data. Both follow the singleton pattern (`._()` private constructor + `static final instance`).
- **Notification repository split** — `NotificationRepository` defines the abstraction in `lib/repositories/notification_repository.dart`; `FirestoreNotificationRepository` implements it in `lib/repositories/firestore_notification_repository.dart`, matching the architectural standard used for bookings, users, and payments.
- **Range-based slot availability** — `BookingRepository.checkProfessionalAvailability` now accepts a `slotDurationMinutes` parameter and uses `isLessThan` + in-code overlap detection instead of exact `isEqualTo` on the `dateTime` string field. Both availability checks and atomic transaction queries are further restricted to the targeted calendar date via `isGreaterThanOrEqualTo(startOfDay)` / `isLessThanOrEqualTo(endOfDay)` inequality filters, preventing unbounded loading of past records.
- **Debug observability** — All availability checks log query parameters, Firestore document counts, and overlap results via `print` statements for live debugging.
- **Appointment state machine** — Explicit status enum (`pending`, `confirmed`, `completed`, `cancelledByCustomer`, `cancelledByProfessional`, `noShow`) with enforced transition rules and cancellation window logic.
- **Real-time Firestore streaming** — `BookingRepository` exposes `snapshots()`-based streams for customer and professional appointment lists, enabling instant UI updates without manual refresh.
- **Real-time notifications** — `NotificationProvider` subscribes to Firestore notification streams so new alerts appear instantly in the notifications list and drawer badge.
- **Upcoming/Past separation** — Professional management screen uses tabs to separate modifiable upcoming bookings from read-only past appointments.
- **Centralized route guards** — `RouteGuardHelper.evaluateRedirect` replaces per-page auth checks. `AuthProvider` exposes `isAuthenticated` and `isProfileComplete` getters. All routes are defined as constants in `lib/constants/routes.dart` and registered in `main.dart`'s `onGenerateRoute`. Parameterized pages parse arguments from `settings.arguments` instead of constructor injection.
- **UI error boundaries** — `lib/exceptions/app_exception.dart` defines the exception hierarchy (`AppException`, `AuthException`, `NetworkException`, `BookingException`, `PermissionException`). `lib/utils/error_handler.dart` centralizes mapping to user-safe messages and a styled SnackBar helper. Pages in `login_page.dart`, `registration_page.dart`, `booking_page.dart`, `edit_appointment_page.dart`, and `profile_page.dart` use it to prevent raw exception leakage.
- **Exception consolidation** — Removed the duplicate `AppException` definition from `lib/helpers/app_exception.dart` and unified all exception classes into `lib/exceptions/app_exception.dart`. Renamed the `originalException` parameter to `cause` across the hierarchy to align with the named parameter used throughout repositories and providers. All imports across `lib/` and `test/` were repointed to the single canonical source.

## 🚀 Project Status & Progress Tracker

### Completed Phases

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Scoped Queries — User-scoped appointment queries | ✅ Completed |
| Phase 2 | Firestore Rules — Strict document ownership rules | ✅ Completed |
| Phase 3 | Firestore Indexes — `firestore.indexes.json` configured | ✅ Completed |
| Phase 4 | DI Cleanup — `NotificationProvider` & `PaymentProvider` refactored | ✅ Completed |
| Phase 5 / TD-003 | Repository Split — `UserRepository` extracted from `BookingRepository` | ✅ Completed |
| Phase 6 / TD-012 | Notification Repository Split — `NotificationRepository` + `FirestoreNotificationRepository` | ✅ Completed |
| Phase 7 / TD-014 | Route Centralization & Guard Hardening — All routes in `routes.dart`, `onGenerateRoute` registration, named-route navigation | ✅ Completed |
| Phase 8 | Query Optimization — Date-bounded Firestore availability & transaction checks in `FirestoreBookingRepository` | ✅ Completed |

### Technical Debt Items

| Item | Description | Status |
|------|-------------|--------|
| TD-007 | Route Guards — `RouteGuardHelper` + `onGenerateRoute` | ✅ Completed |
| TD-013 | Error Boundaries — `AppException` hierarchy + `ErrorHandler` | ✅ Completed |
| TD-011 | Console Logging — `AppLogger` using `developer.log` | ✅ Completed |
| TD-004 | UI Loading / Empty States — `AppLoadingIndicator` + `EmptyStateWidget` | ✅ Completed |
| TD-012 | Notification Repository Split — Abstract `NotificationRepository` + concrete `FirestoreNotificationRepository` | ✅ Completed |
| TD-014 | Route Centralization — Named routes + argument parsing + guard hardening | ✅ Completed |

## 🔄 How to Resume Development

- **Test suite:** 95/96 tests passing (`flutter test`) — 1 pre-existing failure in `appointment_provider_test.dart` (unrelated `SLOT_TAKEN` mock assertion)
- **Static analysis:** 0 errors, 12 info-level warnings in pre-existing files (`flutter analyze`)
- **Current focus:** Pre-Production Deployment & Smoke Testing
- **Next immediate steps:**
  1. Review Firestore security rules against the updated `UserRepository` and `NotificationRepository` queries.
  2. Run smoke tests on physical devices (Android/iOS) to validate real-time streams and calendar integration.
  3. Prepare release build (`flutter build apk` / `flutter build ios`) and verify ProGuard / obfuscation settings if applicable.
  4. Tag a release candidate and deploy to Firebase App Distribution or TestFlight.

## Project status

| Area | Status |
|------|--------|
| Phase 1: Atomic Transactions & Availability Hardening | Complete |
| Phase 2: Schedule Logic (Buffer/Break Time) | Complete |
| Phase 3: Real-Time Availability & State Machine Hardening | Complete |
| Phase 4: Native Device Calendar Integration | Complete |
| Phase 5: Dependency Injection Cleanup (Repository Split) | Complete |
| Phase 6: UI Error Boundaries & Exception Handling | Complete |
| Phase 7: Notification Repository Split | Complete |
| Phase 8: Route Centralization & Guard Hardening | Complete |
| Phase 9: Query Optimization — Date-bounded availability & transaction checks | Complete |
| Authentication | Registration, login, password reset, first-login profile completion |
| Booking | Slot availability check, create/cancel/reschedule appointments, 2-hour cancellation window |
| Professional workflow | Accept/decline pending bookings, upcoming/past tabs, real-time updates |
| Notifications | Real-time streaming, unread badge, booking request/confirm/cancel alerts |
| Calendar | Add confirmed bookings to native device calendar |
| Profile | Edit name, email, phone, password; professional specialty & schedule |
| Theme | Teal, dark, rose, indigo — persisted via shared_preferences |
| Tests | 95/96 passing (`flutter test`) |
| Analysis | 0 errors, 12 info warnings (`flutter analyze`) |

## Checks

```bash
flutter analyze   # 0 errors
flutter test      # 95/96 passing (1 pre-existing failure)
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
  constants/       # Service catalog, scheduling options, and route constants
  exceptions/      # AppException hierarchy (Auth, Network, Booking, Permission)
  helpers/         # Validation, scheduling, formatting, theme prefs, calendar export, route guard logic
  models/          # User, Appointment, BookingSummary, Notification
  pages/           # UI screens (login, register, home, booking, profile, etc.)
  providers/       # Auth, appointments, theme, notifications, payments (ChangeNotifier)
  repositories/    # Abstract repositories + Firestore implementations (Booking, User, Notification, Payment)
  utils/           # Shared utilities including centralized error handling
  widgets/         # Shared UI components
  firebase_options.dart
  main.dart        # App entry point, provider setup, centralized route guard, route resolution
test/              # Unit tests
```

## Navigation & route guards

- **Route constants** — All named routes are defined as `static const` strings in `lib/constants/routes.dart` (`login`, `register`, `forgotPassword`, `completeProfile`, `customerHome`, `professionalHome`, `services`, `booking`, `editAppointment`, `addPayment`, `receipt`, `success`, `profile`, `notifications`, `analytics`, `pastAppointments`, `settings`).
- **Centralized guard** — `RouteGuardHelper.evaluateRedirect` is called on every named-route transition in `onGenerateRoute`. It returns a target route or `null` if no redirect is needed.
- **Auth gating** — Unauthenticated users on protected routes are redirected to `/login`.
- **Profile completion** — Authenticated users with `!isProfileComplete` are redirected to `/complete-profile`.
- **Auth redirect from public routes** — Authenticated, profile-complete users on `/login` or `/register` are redirected to their role-appropriate home dashboard.
- **Role boundaries** — Customers on `/professional_home` are redirected to `/user_home`; professionals on `/user_home` are redirected to `/professional_home`.
- **Argument parsing** — Parameterized routes (`booking`, `editAppointment`, `addPayment`, `receipt`, `success`) parse their payload from `settings.arguments` inside `onGenerateRoute`, enforcing type safety at the router boundary.
- **`/complete-profile` page** — A minimal Scaffold with a "Go to Login" button is rendered inline in `onGenerateRoute`.
- **Named-route enforcement** — All navigation call sites use `Navigator.pushNamed(context, Routes.xxx, arguments: ...)` instead of `MaterialPageRoute`, ensuring every transition passes through the centralized guard.

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

- **Repository pattern** — `BookingRepository`, `UserRepository`, `NotificationRepository`, and `PaymentRepository` are abstract interfaces; `FirestoreBookingRepository`, `FirestoreUserRepository`, `FirestoreNotificationRepository`, and `FirestorePaymentRepository` are the concrete implementations. This allows swapping data sources in the future.
- **Typed exceptions** — `AppException` wraps repository errors with a message and optional cause. UI code catches `AppException` to show user-friendly messages.
- **ErrorHandler** — `ErrorHandler.getDisplayMessage` maps exception types (`AppException`, `FirebaseAuthException`, `FirebaseException`, and generic exceptions) to localized, human-readable strings. `showErrorSnackBar` clears existing SnackBars and displays a styled error toast.
- **State management** — Provider + ChangeNotifier. `AppointmentProvider` exposes `isLoading` and `error` for UI feedback; `AuthProvider` exposes `LoginResult` enum for first-login flows.
- **Theme persistence** — `ThemeProvider` loads/saves the selected theme via `ThemePreferences` (shared_preferences) before the app renders.
- **Slot availability** — `checkProfessionalAvailability` uses range-based overlap detection (`dateTime < slotEnd` + in-code `apptEnd > slotStart`) instead of exact timestamp matching, avoiding false positives from millisecond-level differences.
- **Real-time streams** — Appointment and notification lists use Firestore `snapshots()` so UI stays in sync across devices without pull-to-refresh.
- **Centralized route guards** — Navigation is routed through `onGenerateRoute` in `main.dart`. All routes are defined as constants in `lib/constants/routes.dart`. `RouteGuardHelper.evaluateRedirect` enforces auth, profile completion, and role boundaries. Parameterized pages parse typed arguments from `settings.arguments`. `AuthProvider` exposes `isAuthenticated` and `isProfileComplete` getters for guard evaluation.
- **Calendar export** — `CalendarHelper.addToNativeCalendar` builds a native event via `add_2_calendar` with booking details, contact info, and a 1-hour reminder.
