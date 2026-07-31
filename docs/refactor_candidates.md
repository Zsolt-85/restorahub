# Refactor Candidates

## RC-001: `lib/repositories/notification_repository.dart`

**Reason**: Combines the abstract `NotificationRepository` interface and the `FirestoreNotificationRepository` concrete implementation in a single file. Every other repository (`booking_repository.dart`/`firestore_booking_repository.dart`, `payment_repository.dart`/`firestore_payment_repository.dart`) uses a separate file for the interface and the implementation. This inconsistency should be resolved for maintainability and consistency.

**Estimated Complexity**: Low

**Risk**: Low — the split is mechanical; the abstract class and implementation can be extracted into separate files without changing logic.

**Priority**: P3

---

## RC-002: `lib/providers/payment_provider.dart` — inconsistent repository injection

**Reason**: `PaymentProvider` defaults to `FirestorePaymentRepository.instance` internally rather than receiving the repository via constructor injection like `AuthProvider` and `AppointmentProvider`. This inconsistency makes `PaymentProvider` less testable and less consistent with the app's dependency injection pattern.

**Estimated Complexity**: Low

**Risk**: Low — changing the constructor to accept a `PaymentRepository?` parameter and passing it from `main.dart` is straightforward and backward-compatible.

**Priority**: P3

---

## RC-003: `lib/providers/notification_provider.dart` — inconsistent repository injection

**Reason**: Same issue as RC-002. `NotificationProvider` defaults to `FirestoreNotificationRepository.instance` internally rather than receiving it via constructor injection from `main.dart`.

**Estimated Complexity**: Low

**Risk**: Low — same as RC-002.

**Priority**: P3

---

## RC-004: `lib/main.dart` — eager appointment loading before user is known

**Reason**: `appointmentProvider.loadAppointments()` is called in `main.dart` before the user is authenticated and before `setCurrentUser()` is called. This loads all appointments into memory (including those belonging to other users), which is both a performance waste and a potential data exposure concern. The call chain should be deferred until after the user is known.

**Estimated Complexity**: Medium

**Risk**: Medium — removing the eager load and deferring it to `setCurrentUser()` may change the initial load timing for the home screen, which could affect user experience if the home screen appears before data is ready.

**Priority**: P1

---

## RC-005: `lib/providers/appointment_provider.dart` — notification scheduling in wrong layer

**Reason**: `AppointmentProvider.scheduleUpcomingReminders()` is a cross-cutting concern (notification scheduling) mixed into the appointment provider. Notification scheduling belongs in its own provider or a dedicated service class. This makes `AppointmentProvider` larger and less focused than necessary.

**Estimated Complexity**: Medium

**Risk**: Medium — extracting notification scheduling into a separate class would require updating all callers (currently `AppointmentProvider` only).

**Priority**: P2

---

## RC-006: `lib/models/appointment.dart` — denormalized user data and legacy migration logic

**Reason**: The `Appointment` model stores redundant copies of user contact data for both customer and professional, and `fromMap()` contains legacy migration logic for a deprecated `type` field. The denormalization creates sync risk (must be kept in sync via `syncUserInAppointments()`), and the legacy migration logic should be cleaned up.

**Estimated Complexity**: Medium

**Risk**: Medium — removing the legacy `type` field parsing could break reading of older Firestore documents. The denormalization change is a data model migration that requires a Firestore migration strategy.

**Priority**: P2

---

## RC-007: `lib/models/payment.dart` — excessive denormalized data

**Reason**: The `Payment` model stores full user contact details for both customer and professional, plus service name, specialty, and appointment date/time/duration — all of which are already available in the linked `Appointment` document. This duplication creates a consistency risk (the payment snapshot could become stale if the appointment or user data changes).

**Estimated Complexity**: Medium

**Risk**: Medium — reducing denormalized data requires a Firestore migration strategy and could change the receipt page's behavior if it reads from the appointment instead of the payment.

**Priority**: P2

---

## RC-008: `lib/repositories/booking_repository.dart` — mixed domain concerns in `BookingRepository`

**Reason**: The `BookingRepository` interface includes user operations (`getUserById`, `isEmailTaken`, `insertUser`, `updateUser`, `syncUserInAppointments`) alongside appointment operations. Despite its name, it handles two distinct domain areas. Splitting it into `UserRepository` and `BookingRepository` would improve clarity and testability.

**Estimated Complexity**: Medium

**Risk**: Medium — splitting requires updating all callers of the user methods and could affect `AuthProvider` which depends on `BookingRepository` for user operations.

**Priority**: P2

---

## RC-009: `lib/main.dart` — no centralized route guards

**Reason**: Route protection is implemented per-page (each page checks `auth.currentUser == null` and redirects). A centralized route guard via `onGenerateRoute` would eliminate duplicated auth-check code across 7+ page widgets and provide a single place for access control decisions.

**Estimated Complexity**: Medium

**Risk**: Medium — switching to `onGenerateRoute` changes how routes are defined and could affect the `/success` route which uses `ModalRoute.of(context)?.settings.arguments`.

**Priority**: P2

---

## RC-010: `lib/helpers/appointment_actions.dart` — direct page import creating coupling

**Reason**: `appointment_actions.dart` imports `edit_appointment_page.dart` directly to navigate to the reschedule screen. This creates coupling between a helper utility and a page widget. The reschedule navigation target should be configurable or the helper should not handle navigation directly.

**Estimated Complexity**: Low

**Risk**: Low — extracting the navigation callback as a parameter or using a navigation service would decouple the helper from the page.

**Priority**: P4