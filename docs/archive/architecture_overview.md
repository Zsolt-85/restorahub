# RestoraHub — Architecture Overview

## Overall Architecture

RestoraHub is a Flutter cross-platform application (mobile, web, desktop) built with the **Provider + ChangeNotifier** state management pattern and a **Repository Pattern** for data access. The app connects customers with wellness/beauty professionals for booking, managing, and paying for appointments.

The architecture follows a layered design with clear separation between UI, state, business logic, and data access:

```
UI (Pages + Widgets)
    ↓
Providers (ChangeNotifier)
    ↓
Repositories (Abstract interfaces → Firestore implementations)
    ↓
Firebase (Auth + Firestore)
```

## Main Layers

### 1. Presentation Layer (`lib/pages/`, `lib/widgets/`)
- **18 page widgets** (`pages/`) representing every screen in the app
- **2 shared widgets** (`widgets/`): `AppointmentCard` and `AppDrawer`
- Pages are stateless or stateful widgets that consume providers via `Provider.of<T>(context)` or `context.watch<T>()`
- Navigation is done via named routes (`Navigator.pushNamed`, `pushReplacementNamed`, `pushAndRemoveUntil`)

### 2. State Management Layer (`lib/providers/`)
- 5 `ChangeNotifier` providers:
  - `AuthProvider` — authentication, registration, profile management
  - `AppointmentProvider` — CRUD operations, filtering, slot availability, reminders
  - `ThemeProvider` — theme selection and persistence
  - `PaymentProvider` — payment loading, recording, revenue stats
  - `NotificationProvider` — notification loading, read/unread tracking
- Providers are instantiated once in `main.dart` and injected via `MultiProvider`

### 3. Business Logic / Data Access Layer (`lib/repositories/`)
- 3 abstract repository interfaces: `BookingRepository`, `PaymentRepository`, `NotificationRepository`
- 3 Firestore implementations: `FirestoreBookingRepository`, `FirestorePaymentRepository`, `FirestoreNotificationRepository`
- `BookingRepository` also handles user CRUD operations (unusual coupling)

### 4. Models (`lib/models/`)
- 5 data classes: `User`, `Appointment`, `Payment`, `AppNotification`, `BookingSummary`
- Each model includes `toMap()`, `fromMap()`, and `copyWith()` for Firestore serialization

### 5. Helpers (`lib/helpers/`)
- `AppException` — typed error wrapper
- `ValidationHelper` — input validation
- `ScheduleHelper` — slot generation, overlap detection, schedule validation
- `FormatHelper` — date/time formatting
- `ThemePreferences` — theme persistence via shared_preferences
- `NotificationScheduleHelper` — local notification scheduling
- `AppointmentActions` — shared confirmation dialog logic for cancel/reschedule/status changes

### 6. Constants (`lib/constants/`)
- Service catalog, icons, colors, slot duration options

## Dependency Flow

```
main.dart
  ├── FirestoreBookingRepository (singleton)
  │     └── used by AuthProvider and AppointmentProvider
  ├── AuthProvider (depends on BookingRepository)
  ├── AppointmentProvider (depends on BookingRepository)
  ├── ThemeProvider (no repository dependency)
  ├── NotificationProvider (depends on NotificationRepository, default: FirestoreNotificationRepository)
  │     └── creates its own FirestoreNotificationRepository.instance if none provided
  └── PaymentProvider (depends on PaymentRepository, default: FirestorePaymentRepository)
        └── creates its own FirestorePaymentRepository.instance if none provided
```

**Key observation**: `NotificationProvider` and `PaymentProvider` are not provided their repository in `main.dart` — they default to their Firestore singletons internally. `AuthProvider` and `AppointmentProvider` receive the shared `FirestoreBookingRepository.instance` explicitly.

## Folder Structure

```
lib/
  main.dart                          # App entry, Firebase init, provider wiring, routes
  firebase_options.dart              # Firebase platform config
  constants/
    constants.dart                   # Service catalog, icons, colors, slot options
  models/
    appointment.dart                 # Appointment model + AppointmentStatus enum
    booking_summary.dart             # Lightweight DTO for booking success screen
    notification.dart                # AppNotification + NotificationType/Status enums
    payment.dart                     # Payment model + PaymentMethod/Status enums
    user.dart                        # User profile model
  providers/
    auth_provider.dart               # Auth, registration, profile, password reset
    appointment_provider.dart        # Appointment CRUD, filtering, slot checks, reminders
    theme_provider.dart              # Theme selection and persistence
    payment_provider.dart            # Payment loading, recording, updating, revenue stats
    notification_provider.dart       # Notification loading, read/unread tracking
  repositories/
    booking_repository.dart          # Abstract BookingRepository + user operations
    firestore_booking_repository.dart # Firestore implementation for bookings + users
    payment_repository.dart          # Abstract PaymentRepository interface
    firestore_payment_repository.dart # Firestore implementation for payments
    notification_repository.dart     # Abstract NotificationRepository + Firestore impl (combined)
  pages/
    login_page.dart                  # Email/password login
    registration_page.dart           # Registration with role selection
    forgot_password_page.dart        # Password reset
    user_home_page.dart              # Customer dashboard
    professional_booking_management_page.dart # Professional dashboard
    services_page.dart               # Service catalog grid
    booking_page.dart                # Booking flow (professional, date, slot)
    edit_appointment_page.dart       # Reschedule flow
    profile_page.dart                # Edit profile + professional schedule
    settings_page.dart               # Theme picker + logout
    notifications_page.dart          # Notification list
    analytics_page.dart              # Professional analytics dashboard
    earnings_report_page.dart        # Earnings with date range + sharing
    add_payment_page.dart            # Record payment form
    receipt_page.dart                # Receipt view + share
    past_appointments_page.dart      # History of past bookings
    success_page.dart                # Booking confirmation summary
  widgets/
    appointment_card.dart            # Reusable appointment display with actions
    app_drawer.dart                  # Navigation drawer
  helpers/
    app_exception.dart               # Typed repository error wrapper
    validation_helper.dart           # Input validation (name, email, phone, password)
    schedule_helper.dart             # Slot generation, overlap detection, work schedule validation
    format_helper.dart               # Date/time formatting
    theme_preferences.dart           # Theme persistence via shared_preferences
    notification_schedule_helper.dart  # Local notification scheduling
    appointment_actions.dart         # Confirm/cancel/reschedule dialog logic
```

## Current Design Patterns

1. **Repository Pattern** — Abstract interfaces (`BookingRepository`, `PaymentRepository`, `NotificationRepository`) with Firestore implementations. Allows swapping data sources theoretically.
2. **Provider + ChangeNotifier** — State management throughout the app. Providers expose streams of state via getter properties and notify listeners on mutation.
3. **Singleton Firestore Repositories** — `FirestoreBookingRepository.instance`, `FirestorePaymentRepository.instance`, `FirestoreNotificationRepository.instance` are singletons accessed throughout the app.
4. **Typed Exceptions** — `AppException` wraps repository errors with a user-friendly message and optional cause.
5. **Named Routes** — All navigation uses named routes defined in `MaterialApp.routes`.
6. **Model Serialization** — Each model provides `toMap()` and `fromMap()` for Firestore read/write.
7. **Role-Based Access** — `User.role` field (`customer` or `professional`) drives UI branching and data filtering.

## Strengths

1. **Clear layer separation** — UI, state, business logic, and data access are cleanly separated.
2. **Repository pattern** — Abstract interfaces provide a theoretical path to swap data sources (e.g., to a REST API or local DB).
3. **Typed error handling** — `AppException` provides structured error information with user-friendly messages.
4. **Slot availability checking** — Overlap detection prevents double-booking, implemented in a reusable helper.
5. **Role-based filtering** — `filteredAppointments` in `AppointmentProvider` correctly partitions data by role.
6. **Theme persistence** — Theme selection survives app restarts via `shared_preferences`.
7. **First-login profile completion** — Graceful onboarding flow for new Firebase users without Firestore profiles.
8. **Comprehensive loading/error states** — All data-loading screens show progress indicators and error messages with retry buttons.
9. **Model serialization** — Consistent `toMap()`/`fromMap()` patterns across all models.

## Weaknesses

1. **No Firestore persistence layer abstraction** — `FirestoreBookingRepository` uses `FirebaseFirestore.instance` directly with no ability to mock or swap the Firestore instance itself.
2. **Provider creation inconsistencies** — `NotificationProvider` and `PaymentProvider` create their own repository singletons internally rather than receiving them from `main.dart`, unlike `AuthProvider` and `AppointmentProvider`.
3. **No streaming/listening to Firestore** — All repository reads are one-shot `.get()` calls. Data is not kept in sync with the server in real time (except `NotificationRepository.getNotificationsStream` which is defined but never used by the UI).
4. **Full collection scans** — `getAppointments()` and `getProfessionalsBySpecialty()` load all documents in the collection with no pagination or filtering on the client side.
5. **User data duplication in appointments** — `Appointment` stores `customerName`, `customerPhone`, `customerEmail`, `professionalName`, `professionalPhone`, `professionalEmail` — redundant copies of `User` data that must be manually synced via `syncUserInAppointments()`.
6. **`BookingRepository` mixes concerns** — The `BookingRepository` interface includes user operations (`getUserById`, `isEmailTaken`, `insertUser`, `updateUser`, `syncUserInAppointments`) alongside appointment operations.
7. **No route guards** — Any user can navigate to any route by URL. Protection relies on individual page widgets checking for `currentUser == null` and redirecting.
8. **`lib/services/` directory is empty** — Dead code/directory with no files.
9. **`NotificationRepository` combines interface and implementation** — Unlike the other repositories which split abstract and concrete classes into separate files, `notification_repository.dart` contains both.

## Potential Scalability Issues

1. **Full collection reads** — `getAppointments()` and `getProfessionalsBySpecialty()` fetch every document. As the user base grows, this will become slow and expensive.
2. **No pagination** — All list-based reads return complete result sets with no lazy loading or pagination.
3. **No real-time sync** — The app re-fetches data on every operation rather than listening to Firestore snapshots. This means the UI can become stale between operations.
4. **Single Firestore instance** — No ability to use multiple Firestore databases or regions.
5. **Notification stream unused** — `getNotificationsStream()` is defined in the abstract repository but never consumed by the UI, representing unrealized scalability for real-time notifications.
6. **Write contention** — `syncUserInAppointments()` performs a batch write across potentially many appointment documents on every profile update, creating a write hotspot.