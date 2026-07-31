# Technical Debt Backlog

## TD-001

**Title**: Full collection scan in `getAppointments()` loads all documents

**Description**: `FirestoreBookingRepository.getAppointments()` fetches every document in the `appointments` collection with no filtering, pagination, or limit. As the collection grows, this becomes slow, expensive, and risks hitting Firestore document limits.

**Severity**: High

**Estimated Effort**: Small

**Recommended Priority**: P1 — Immediate

---

## TD-002

**Title**: No pagination on any reads

**Description**: All `get()` calls return complete result sets. There is no cursor-based or limit-based pagination anywhere in the repository layer. This affects `getAppointments()`, `getProfessionalsBySpecialty()`, `getPaymentsByProfessional()`, `getNotificationsForUser()`, and others.

**Severity**: High

**Estimated Effort**: Small

**Recommended Priority**: P1 — Immediate

---

## TD-003

**Title**: `BookingRepository` mixes user and appointment concerns

**Description**: The `BookingRepository` abstract interface includes user CRUD operations (`getUserById`, `isEmailTaken`, `insertUser`, `updateUser`, `syncUserInAppointments`) alongside appointment operations. The name "BookingRepository" implies it should only handle bookings, not user profiles.

**Severity**: Medium

**Estimated Effort**: Medium

**Recommended Priority**: P2 — Next Sprint

---

## TD-004

**Title**: `NotificationRepository` combines abstract and concrete class in one file

**Description**: Unlike `BookingRepository`/`FirestoreBookingRepository`, `PaymentRepository`/`FirestorePaymentRepository` (which are split into separate files), `NotificationRepository` and `FirestoreNotificationRepository` are combined in a single file (`notification_repository.dart`). This breaks the pattern established by the other repositories.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P3 — Next Release

---

## TD-005

**Title**: Denormalized user data in appointments and payments creates sync risk

**Description**: `Appointment` stores `customerName`, `customerPhone`, `customerEmail`, `professionalName`, `professionalPhone`, `professionalEmail`. `Payment` stores the same fields plus service/specialty/appointment details. These are kept in sync via `syncUserInAppointments()` and duplicated at write time, creating a risk of data inconsistency if sync fails or is missed.

**Severity**: Medium

**Estimated Effort**: Medium

**Recommended Priority**: P2 — Next Sprint

---

## TD-006

**Title**: `AppointmentProvider.loadAppointments()` called eagerly before user is known

**Description**: In `main.dart`, `appointmentProvider.loadAppointments()` is called before `AuthProvider.restoreSession()` completes and before the user is known. This means all appointments (including other users') are loaded into memory, which is both a performance waste and a potential data exposure concern.

**Severity**: Medium

**Estimated Effort**: Small

**Recommended Priority**: P1 — Immediate

---

## TD-007

**Title**: No route guards — auth state checked only per-page

**Description**: Route protection relies on individual page widgets checking `auth.currentUser == null` and redirecting. There is no centralized route guard. A user can navigate directly to any route (including `/analytics` as a non-professional, or `/professional_home` as a customer) and the page will attempt to load data.

**Severity**: Medium

**Estimated Effort**: Medium

**Recommended Priority**: P2 — Next Sprint

---

## TD-008

**Title**: `NotificationProvider` and `PaymentProvider` create internal repository singletons

**Description**: Unlike `AuthProvider` and `AppointmentProvider` which receive their repository via constructor injection in `main.dart`, `NotificationProvider` and `PaymentProvider` instantiate their own `FirestoreNotificationRepository.instance` and `FirestorePaymentRepository.instance` internally when no repository is provided. This breaks the dependency injection pattern used by the other providers.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P3 — Next Release

---

## TD-009

**Title**: `getAppointments()` returns appointments for all users

**Description**: The repository method `getAppointments()` queries the entire `appointments` collection with no `where` clause filtering by user. This means every call loads every appointment in the system, not just the current user's appointments. The filtering to the current user is done client-side by `AppointmentProvider.filteredAppointments`.

**Severity**: High

**Estimated Effort**: Medium

**Recommended Priority**: P1 — Immediate

---

## TD-010

**Title**: `syncUserInAppointments()` is a write hotspot

**Description**: Every profile update for a professional triggers two collection queries across the `appointments` collection (one for appointments where the user is the customer, one where they are the professional) followed by a batch write to potentially hundreds of documents. This creates contention and is expensive in terms of read and write operations.

**Severity**: Medium

**Estimated Effort**: Medium

**Recommended Priority**: P2 — Next Sprint

---

## TD-011

**Title**: `services/` directory is empty — dead code

**Description**: The `lib/services/` directory exists but contains no files. This is likely a leftover from refactoring or an incomplete feature.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P3 — Clean up when convenient

---

## TD-012

**Title**: `Payment` model stores `appointmentTime` as separate string field

**Description**: The `Payment` model stores `appointmentTime` as a separate `String` field (`HH:mm` format), which is redundant since `appointmentDate` is a `DateTime` that already contains the time. This creates a consistency risk if one is updated but not the other.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P4 — Future cleanup

---

## TD-013

**Title**: `BookingSummary` route arguments use unsafe cast

**Description**: In `main.dart`, the `/success` route argument is cast with `as BookingSummary?` without validation. If the wrong type is passed, this will throw at runtime. There is no null check or type guard at the route level.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P4 — Future cleanup

---

## TD-014

**Title**: No Firestore security rules included in the codebase

**Description**: The codebase has no Firestore security rules file. All data access is assumed to be protected by server-side rules, but these are not version-controlled or reviewed as part of the project. Misconfigured rules could expose user data.

**Severity**: High

**Estimated Effort**: Small

**Recommended Priority**: P0 — Before next release

---

## TD-015

**Title**: `Appointment.fromMap()` contains legacy migration logic for `type` field

**Description**: The `Appointment.fromMap()` method parses a legacy `type` field from Firestore documents to reconstruct the service display name (e.g., "Massage — Full Body"). This migration logic will never be needed once all existing data has been migrated to the new format, but there is no plan to remove it.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P4 — Future cleanup

---

## TD-016

**Title**: `appointment_actions.dart` imports `edit_appointment_page.dart` creating a circular dependency risk

**Description**: `appointment_actions.dart` imports `edit_appointment_page.dart` to navigate to the reschedule screen. While this does not create a circular dependency today, `appointment_actions.dart` is a helper that is imported by pages which also import `edit_appointment_page.dart`, creating a fragile coupling.

**Severity**: Low

**Estimated Effort**: Small

**Recommended Priority**: P4 — Future cleanup