# Firestore Query Inventory

**Task:** RH-0002A
**Date:** 2026-07-31
**Status:** Documentation only — no code changes
**Scope:** All Firestore reads and writes in `lib/repositories/`, `lib/providers/`, and `lib/pages/`

---

## Project Configuration

| Item | Value |
|---|---|
| Firebase project ID | `restorahub-2da2c` |
| cloud_firestore | `^6.0.0` |
| firebase_auth | `^6.5.4` |
| firebase_core | `^4.10.0` |
| Security rules in repo | None (`firestore.rules` missing) |
| Indexes in repo | None (`firestore.indexes.json` missing) |

Firestore is initialized at `lib/main.dart:30` via `Firebase.initializeApp()`.

---

## Firestore Operations Inventory

### 1. `getUserById`

| Field | Value |
|---|---|
| Operation name | `getUserById` |
| File location | `lib/repositories/firestore_booking_repository.dart:21-35` |
| Collection | `users` |
| Operation type | read |
| Current query/filter | `_usersCol.doc(id).get()` |
| Which user data it accesses | Single user by UID (own user during login/session restore; any user during profile viewing) |
| Required security rule assumption | Any authenticated user can read any user document, or owner-only read with exceptions for professional profiles |
| Production risk | **Medium** — with no rules, any authenticated user can read any profile by guessing a UID |
| Recommended future change | Allow authenticated users to read professional profiles (for booking), but restrict customer profiles to owner-only |

---

### 2. `isEmailTaken`

| Field | Value |
|---|---|
| Operation name | `isEmailTaken` |
| File location | `lib/repositories/firestore_booking_repository.dart:38-51` |
| Collection | `users` |
| Operation type | query (read) |
| Current query/filter | `_usersCol.where('email', isEqualTo: email).get()` |
| Which user data it accesses | Scans all users to check email uniqueness (used during registration and profile update) |
| Required security rule assumption | Authenticated users can query `users` by email, or this check is moved to server-side (Cloud Function) |
| Production risk | **Low** — read-only existence check; with permissive rules it works, but with strict rules it may require a custom claim or server-side function |
| Recommended future change | Add an `email` composite index. Consider enforcing email uniqueness at the rule level with `request.resource.data.email` validation, or use Cloud Functions to validate before write |

---

### 3. `insertUser`

| Field | Value |
|---|---|
| Operation name | `insertUser` |
| File location | `lib/repositories/firestore_booking_repository.dart:54-65` |
| Collection | `users` |
| Operation type | create (write) |
| Current query/filter | `_usersCol.doc(user.id ?? auto).set(data)` — uses UID when available, otherwise auto-generated ID |
| Which user data it accesses | Creates the authenticated user's own profile document |
| Required security rule assumption | User can create a document where `request.resource.data.id == request.auth.uid` and `request.resource.id == request.auth.uid` |
| Production risk | **Low** — called only during first-login profile completion and registration; the UID comes from `FirebaseAuth` |
| Recommended future change | Enforce that the document ID and `id` field must match `request.auth.uid`. Prevent users from creating documents for other users |

---

### 4. `updateUser`

| Field | Value |
|---|---|
| Operation name | `updateUser` |
| File location | `lib/repositories/firestore_booking_repository.dart:68-81` |
| Collection | `users` |
| Operation type | update |
| Current query/filter | `_usersCol.doc(user.id).update(user.toMap())` — writes the entire `toMap()` |
| Which user data it accesses | Updates the currently authenticated user's own profile |
| Required security rule assumption | `request.auth.uid == resource.id` and immutable fields (role, id) are preserved |
| Production risk | **Medium** — writes the entire `toMap()` without server-side validation. A malicious client could attempt to change `role` or other protected fields |
| Recommended future change | Restrict updatable fields in rules: `name`, `email`, `phone`, `specialty`, `workStartTime`, `workEndTime`, `slotDurationMinutes`. Make `role` and `id` immutable after creation |

---

### 5. `syncUserInAppointments` — customer side

| Field | Value |
|---|---|
| Operation name | `syncUserInAppointments` (customer batch) |
| File location | `lib/repositories/firestore_booking_repository.dart:88-99` |
| Collection | `appointments` |
| Operation type | batch update |
| Current query/filter | `_appointmentsCol.where('customerId', isEqualTo: user.id).get()` then `batch.update(doc.reference, {...})` |
| Which user data it accesses | All appointments where the user is the customer; updates `customerName`, `customerPhone`, `customerEmail` on each |
| Required security rule assumption | User can update `customerName`, `customerPhone`, `customerEmail` on documents where `customerId == request.auth.uid` |
| Production risk | **Medium** — batch updates rely on the client passing the correct `user.id`; rules must validate ownership per document in the batch |
| Recommended future change | Test batch writes against security rules to ensure per-document evaluation works. Consider whether denormalized user data in appointments is necessary, or if it should be looked up at read time |

---

### 6. `syncUserInAppointments` — professional side

| Field | Value |
|---|---|
| Operation name | `syncUserInAppointments` (professional batch) |
| File location | `lib/repositories/firestore_booking_repository.dart:101-113` |
| Collection | `appointments` |
| Operation type | batch update |
| Current query/filter | `_appointmentsCol.where('professionalId', isEqualTo: user.id).get()` then `batch.update(doc.reference, {...})` |
| Which user data it accesses | All appointments where the user is the professional; updates `professionalName`, `professionalPhone`, `professionalEmail` on each |
| Required security rule assumption | User can update `professionalName`, `professionalPhone`, `professionalEmail` on documents where `professionalId == request.auth.uid` |
| Production risk | **Medium** — same batch ownership concerns as customer side |
| Recommended future change | Same as customer side. Consolidate into a single batch operation if possible |

---

### 7. `getProfessionalsBySpecialty`

| Field | Value |
|---|---|
| Operation name | `getProfessionalsBySpecialty` |
| File location | `lib/repositories/firestore_booking_repository.dart:121-140` |
| Collection | `users` |
| Operation type | query (read) |
| Current query/filter | `_usersCol.where('role', isEqualTo: 'professional').where('specialty', isEqualTo: specialty).get()` |
| Which user data it accesses | All users with `role == 'professional'` and matching `specialty` (used in booking flow to browse professionals) |
| Required security rule assumption | Any authenticated user can read professional profiles. Customer profiles remain private. Composite index on `role` + `specialty` is required |
| Production risk | **Low** — this is an intentional public directory query. With proper rules, it remains safe. Without rules, all professional PII is exposed |
| Recommended future change | Add composite index on `role` (ASC) + `specialty` (ASC). Ensure rules only expose fields needed for booking (name, specialty, schedule), not email or phone |

---

### 8. `getAppointments`

| Field | Value |
|---|---|
| Operation name | `getAppointments` |
| File location | `lib/repositories/firestore_booking_repository.dart:143-158` |
| Collection | `appointments` |
| Operation type | query (read) |
| Current query/filter | `_appointmentsCol.get()` — **no filters at all** |
| Which user data it accesses | ALL appointments across ALL users. Client-side filtering in `AppointmentProvider.filteredAppointments` separates customer/professional views |
| Required security rule assumption | **Currently incompatible with strict rules.** This query must be updated to filter by `customerId` or `professionalId` matching `request.auth.uid` |
| Production risk | **Critical** — downloads the entire `appointments` collection regardless of user role. With no rules, any authenticated user gets all appointment data |
| Recommended future change | **Must change before strict rules.** Add server-side filters: either pass user ID and role to the query, or split into `getCustomerAppointments()` and `getProfessionalAppointments()`. All provider methods (`addAppointment`, `updateAppointment`, `deleteAppointment`) call `getAppointments()` after mutation and will also need updating |

---

### 9. `insertAppointment`

| Field | Value |
|---|---|
| Operation name | `insertAppointment` |
| File location | `lib/repositories/firestore_booking_repository.dart:161-173` |
| Collection | `appointments` |
| Operation type | create (write) |
| Current query/filter | `_appointmentsCol.doc(appointment.id ?? auto).set(appointment.toMap())` |
| Which user data it accesses | Creates a single appointment. The `customerId` field identifies the booking customer |
| Required security rule assumption | `request.auth.uid == request.resource.data.customerId` — only the customer can create an appointment for themselves |
| Production risk | **Medium** — with no rules, any user could create appointments impersonating other users by manipulating the `customerId` field |
| Recommended future change | Add rule: `request.resource.data.customerId == request.auth.uid`. Also validate required fields: `professionalId`, `service`, `dateTime`, `status` |

---

### 10. `updateAppointment`

| Field | Value |
|---|---|
| Operation name | `updateAppointment` |
| File location | `lib/repositories/firestore_booking_repository.dart:176-188` |
| Collection | `appointments` |
| Operation type | update |
| Current query/filter | `_appointmentsCol.doc(appointment.id).update(appointment.toMap())` |
| Which user data it accesses | Updates a single appointment by ID. No server-side check that the caller is the customer or professional |
| Required security rule assumption | `request.auth.uid == resource.data.customerId` OR `request.auth.uid == resource.data.professionalId`. Fields `customerId` and `professionalId` must remain immutable |
| Production risk | **Medium** — any authenticated user could modify any appointment if they know the document ID |
| Recommended future change | Add ownership rules. Prevent changing `customerId` and `professionalId`. Allow status transitions only in the valid order: `pending → confirmed → completed/cancelled` |

---

### 11. `deleteAppointment`

| Field | Value |
|---|---|
| Operation name | `deleteAppointment` |
| File location | `lib/repositories/firestore_booking_repository.dart:191-203` |
| Collection | `appointments` |
| Operation type | delete |
| Current query/filter | `_appointmentsCol.doc(id).delete()` |
| Which user data it accesses | Deletes a single appointment by ID |
| Required security rule assumption | `request.auth.uid == resource.data.customerId` OR `request.auth.uid == resource.data.professionalId` |
| Production risk | **Medium** — any authenticated user could delete any appointment by guessing the document ID |
| Recommended future change | Add ownership rules. Consider making delete a soft-delete (set `status: 'cancelled'`) instead of hard delete, to preserve appointment history |

---

### 12. `getAppointmentsByStatus`

| Field | Value |
|---|---|
| Operation name | `getAppointmentsByStatus` |
| File location | `lib/repositories/firestore_booking_repository.dart:206-223` |
| Collection | `appointments` |
| Operation type | query (read) |
| Current query/filter | `_appointmentsCol.where('status', isEqualTo: status.name).get()` — no user filter |
| Which user data it accesses | ALL appointments matching the given status across ALL users |
| Required security rule assumption | **Currently incompatible with strict rules.** Must filter by user ownership |
| Production risk | **Critical** — same issue as `getAppointments()`. Returns all appointments of a given status regardless of user |
| Recommended future change | **Should change before strict rules, but this method is currently unused.** Either add user ID filter or remove the method. Client-side filtering in `AppointmentProvider` already handles this |

---

### 13. `getPastAppointments`

| Field | Value |
|---|---|
| Operation name | `getPastAppointments` |
| File location | `lib/repositories/firestore_booking_repository.dart:226-247` |
| Collection | `appointments` |
| Operation type | query (read) |
| Current query/filter | `_appointmentsCol.where('dateTime', isLessThan: now.toIso8601String()).get()` — no user filter |
| Which user data it accesses | ALL appointments with `dateTime` before now, then client-side filtered for `completed` or `cancelled` status |
| Required security rule assumption | **Currently incompatible with strict rules.** Must filter by user ownership |
| Production risk | **Critical** — returns all past appointments regardless of user |
| Recommended future change | **Should change before strict rules, but this method is currently unused.** Either add user ID filter or remove the method. Client-side `AppointmentProvider.pastAppointments` already handles this |

---

### 14. `getPaymentByAppointment`

| Field | Value |
|---|---|
| Operation name | `getPaymentByAppointment` |
| File location | `lib/repositories/firestore_payment_repository.dart:18-34` |
| Collection | `payments` |
| Operation type | query (read) |
| Current query/filter | `_paymentsCol.where('appointmentId', isEqualTo: appointmentId).limit(1).get()` |
| Which user data it accesses | Single payment linked to a specific appointment ID |
| Required security rule assumption | Payment documents are readable where `customerId == request.auth.uid` OR `professionalId == request.auth.uid`. The query filters by `appointmentId`, which must also be validated against ownership |
| Production risk | **Low** — returns at most one document, but with no rules any authenticated user can query by appointment ID |
| Recommended future change | Ensure rules validate that the caller is either the customer or professional on the linked appointment. Add `appointmentId` index |

---

### 15. `getPaymentsByProfessional`

| Field | Value |
|---|---|
| Operation name | `getPaymentsByProfessional` |
| File location | `lib/repositories/firestore_payment_repository.dart:37-56` |
| Collection | `payments` |
| Operation type | query (read) |
| Current query/filter | `_paymentsCol.where('professionalId', isEqualTo: professionalId).get()` |
| Which user data it accesses | All payments for a specific professional ID |
| Required security rule assumption | User can read payments where `professionalId == request.auth.uid` (professional viewing own earnings) OR `customerId == request.auth.uid` (customer viewing their own payment) |
| Production risk | **Medium** — with no rules, any authenticated user can view all payments for any professional by ID |
| Recommended future change | **This method is currently unused.** The app uses `getPaymentsByProfessionalInRange()` instead. Consider removing or adding proper ownership rules |

---

### 16. `getPaymentsByProfessionalInRange`

| Field | Value |
|---|---|
| Operation name | `getPaymentsByProfessionalInRange` |
| File location | `lib/repositories/firestore_payment_repository.dart:59-85` |
| Collection | `payments` |
| Operation type | query (read) |
| Current query/filter | `_paymentsCol.where('professionalId', isEqualTo: professionalId).where('appointmentDate', isGreaterThanOrEqualTo: startIso).where('appointmentDate', isLessThan: endIso).get()` |
| Which user data it accesses | All payments for a specific professional within a date range (used for analytics/earnings reports) |
| Required security rule assumption | User can read payments where `professionalId == request.auth.uid`. Composite index on `professionalId` + `appointmentDate` is required |
| Production risk | **Medium** — with no rules, any authenticated user can query another professional's payment history by ID and date range |
| Recommended future change | Add composite index on `professionalId` (ASC) + `appointmentDate` (DESC). Ensure rules restrict reads to the authenticated professional's own payments |

---

### 17. `recordPayment`

| Field | Value |
|---|---|
| Operation name | `recordPayment` |
| File location | `lib/repositories/firestore_payment_repository.dart:88-101` |
| Collection | `payments` |
| Operation type | create (write) |
| Current query/filter | `_paymentsCol.doc(payment.id ?? auto).set(payment.toMap())` |
| Which user data it accesses | Creates a single payment record. The `professionalId` field identifies who recorded it |
| Required security rule assumption | `request.auth.uid == request.resource.data.professionalId` — only the professional can record a payment for their own appointments |
| Production risk | **Medium** — with no rules, any authenticated user could create fake payment records for any professional |
| Recommended future change | Add rule: `request.resource.data.professionalId == request.auth.uid`. Validate required fields: `customerId`, `appointmentId`, `amount > 0`, valid `status` |

---

### 18. `updatePayment`

| Field | Value |
|---|---|
| Operation name | `updatePayment` |
| File location | `lib/repositories/firestore_payment_repository.dart:104-117` |
| Collection | `payments` |
| Operation type | update |
| Current query/filter | `_paymentsCol.doc(payment.id).update(payment.toMap())` |
| Which user data it accesses | Updates an entire payment document by ID |
| Required security rule assumption | `request.auth.uid == resource.data.professionalId`. Fields like `customerId` and `appointmentId` must remain immutable |
| Production risk | **Medium** — any authenticated user could modify payment amounts or status by guessing the document ID |
| Recommended future change | Add ownership rules. Restrict updatable fields: only `status`, `amount`, and `method` should be mutable. Make `professionalId`, `customerId`, and `appointmentId` immutable |

---

### 19. `updatePaymentStatus`

| Field | Value |
|---|---|
| Operation name | `updatePaymentStatus` |
| File location | `lib/repositories/firestore_payment_repository.dart:120-134` |
| Collection | `payments` |
| Operation type | update (partial) |
| Current query/filter | `_paymentsCol.doc(paymentId).update({'status': status.name})` |
| Which user data it accesses | Updates only the `status` field of a single payment |
| Required security rule assumption | `request.auth.uid == resource.data.professionalId`. Only `status` field is being updated |
| Production risk | **Medium** — same ownership concern as `updatePayment`, but more limited in scope |
| Recommended future change | Add ownership rules. Validate that `status` is one of the allowed values: `pending`, `completed`, `refunded` |

---

### 20. `sendNotification`

| Field | Value |
|---|---|
| Operation name | `sendNotification` |
| File location | `lib/repositories/notification_repository.dart:26-36` |
| Collection | `notifications` |
| Operation type | create (write) |
| Current query/filter | `_notificationsCol.doc().set(notification.toMap())` — auto-generated doc ID |
| Which user data it accesses | Creates a notification addressed to a `receiverId`. The `senderId` is set in the notification data but not validated server-side |
| Required security rule assumption | **Client-side notification creation should be denied.** Rules should set `allow create: if false` and require Cloud Functions for notification creation. If client-side is allowed, validate `receiverId != request.auth.uid` to prevent self-notification |
| Production risk | **High** — any authenticated user can craft and send notifications to any other user, including spoofing `senderId`. This is a social engineering/phishing vector |
| Recommended future change | **Move notification creation to Cloud Functions** triggered by booking events (appointment created, appointment confirmed, etc.). Deny client-side `create` in rules. Add `senderId` validation if client-side must be supported temporarily |

---

### 21. `getNotificationsForUser`

| Field | Value |
|---|---|
| Operation name | `getNotificationsForUser` |
| File location | `lib/repositories/notification_repository.dart:39-57` |
| Collection | `notifications` |
| Operation type | query (read) |
| Current query/filter | `_notificationsCol.where('receiverId', isEqualTo: userId).orderBy('createdAt', descending: true).get()` |
| Which user data it accesses | All notifications where the logged-in user is the `receiverId` |
| Required security rule assumption | `request.auth.uid == resource.data.receiverId`. Composite index on `receiverId` + `createdAt` is required |
| Production risk | **Low** — correctly scoped to the receiver. With no rules, any user could query another user's notifications by guessing their UID |
| Recommended future change | Add composite index on `receiverId` (ASC) + `createdAt` (DESC). Ensure rules restrict reads to the receiver only |

---

### 22. `markAsRead`

| Field | Value |
|---|---|
| Operation name | `markAsRead` |
| File location | `lib/repositories/notification_repository.dart:60-71` |
| Collection | `notifications` |
| Operation type | update (partial) |
| Current query/filter | `_notificationsCol.doc(notificationId).update({'status': NotificationStatus.read.name})` |
| Which user data it accesses | Updates a single notification's `status` field |
| Required security rule assumption | `request.auth.uid == resource.data.receiverId`. Only the `status` field is updated; `receiverId` must remain immutable |
| Production risk | **Low** — single document update, scoped to notification ID. With no rules, any user could mark any notification as read |
| Recommended future change | Add ownership rules. Validate that `status` is one of: `unread`, `read`, `dismissed`. Ensure `receiverId` cannot be changed |

---

### 23. `markAllAsRead` (query)

| Field | Value |
|---|---|
| Operation name | `markAllAsRead` (query phase) |
| File location | `lib/repositories/notification_repository.dart:76-79` |
| Collection | `notifications` |
| Operation type | query (read) |
| Current query/filter | `_notificationsCol.where('receiverId', isEqualTo: userId).where('status', isEqualTo: NotificationStatus.unread.name).get()` |
| Which user data it accesses | All unread notifications for a specific user |
| Required security rule assumption | `request.auth.uid == resource.data.receiverId`. Composite index on `receiverId` + `status` is required |
| Production risk | **Low** — correctly scoped to the receiver's unread notifications |
| Recommended future change | Add composite index on `receiverId` (ASC) + `status` (ASC) |

---

### 24. `markAllAsRead` (batch update)

| Field | Value |
|---|---|
| Operation name | `markAllAsRead` (batch update phase) |
| File location | `lib/repositories/notification_repository.dart:80-86` |
| Collection | `notifications` |
| Operation type | batch update |
| Current query/filter | `_firestore.batch()` then `batch.update(doc.reference, {'status': NotificationStatus.read.name})` for each unread doc |
| Which user data it accesses | Bulk-updates all unread notifications for the receiver to `status: 'read'` |
| Required security rule assumption | `request.auth.uid == resource.data.receiverId` for each document in the batch. Firestore evaluates rules per-document in batch operations |
| Production risk | **Low** — ownership is enforced per-document. Batch size could be large for users with many notifications |
| Recommended future change | Ensure security rules handle batch updates correctly. Consider adding a `readAt` timestamp field for more accurate tracking |

---

### 25. `getNotificationsStream`

| Field | Value |
|---|---|
| Operation name | `getNotificationsStream` |
| File location | `lib/repositories/notification_repository.dart:96-101` |
| Collection | `notifications` |
| Operation type | stream (real-time) |
| Current query/filter | `_notificationsCol.where('receiverId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots()` |
| Which user data it accesses | Real-time stream of all notifications for a specific user |
| Required security rule assumption | `request.auth.uid == resource.data.receiverId`. Composite index on `receiverId` + `createdAt` is required |
| Production risk | **Low** — correctly scoped, but **this method is currently unused** — no page or provider subscribes to it |
| Recommended future change | Either implement real-time notifications in the UI, or remove the method to reduce attack surface. If kept, ensure rules and indexes are in place |

---

## Page-Level Firestore Access Summary

The following pages trigger Firestore operations through providers. Pages do not call repositories directly.

| Page | File | Line(s) | Provider Method | Underlying Firestore Operation |
|---|---|---|---|---|
| Login | `lib/pages/login_page.dart` | 110-112 | `auth.login()` | `getUserById` (users read) |
| Login | `lib/pages/login_page.dart` | 119-124 | `appointmentProvider.setCurrentUser()` | `getAppointments` (appointments query all) |
| Registration | `lib/pages/registration_page.dart` | 68-75 | `auth.register()` | `isEmailTaken` (users query), `insertUser` (users create) |
| Registration | `lib/pages/registration_page.dart` | 86 | `appointmentProvider.setCurrentUser()` | `getAppointments` (appointments query all) |
| Profile | `lib/pages/profile_page.dart` | 239-255 | `auth.updateProfile()` | `isEmailTaken`, `updateUser`, `syncUserInAppointments` |
| Profile | `lib/pages/profile_page.dart` | 262-264 | `appointmentProvider.loadAppointments()` | `getAppointments` (appointments query all) |
| Booking | `lib/pages/booking_page.dart` | 44 | `repo.getProfessionalsBySpecialty()` | `users` where role=professional + specialty |
| Booking | `lib/pages/booking_page.dart` | 267 | `apptProvider.addAppointment()` | `insertAppointment`, then `getAppointments` |
| Edit Appointment | `lib/pages/edit_appointment_page.dart` | 37-39 | `repo.getUserById()` | `users` by doc ID |
| Edit Appointment | `lib/pages/edit_appointment_page.dart` | 187-190 | `apptProvider.rescheduleAppointment()` | `updateAppointment`, then `getAppointments` |
| Professional Booking Management | `lib/pages/professional_booking_management_page.dart` | 29 | `apptProvider.setCurrentUser()` | `getAppointments` |
| Professional Booking Management | `lib/pages/professional_booking_management_page.dart` | 90 | `apptProvider.loadAppointments()` | `getAppointments` |
| User Home | `lib/pages/user_home_page.dart` | 29 | `apptProvider.setCurrentUser()` | `getAppointments` |
| Analytics | `lib/pages/analytics_page.dart` | 27-32 | `paymentProvider.loadPaymentsForProfessionalInRange()` | `getPaymentsByProfessionalInRange` |
| Earnings Report | `lib/pages/earnings_report_page.dart` | 28-33 | `paymentProvider.loadPaymentsForProfessionalInRange()` | `getPaymentsByProfessionalInRange` |
| Earnings Report | `lib/pages/earnings_report_page.dart` | 176-181 | `paymentProvider.loadPaymentsForProfessionalInRange()` | `getPaymentsByProfessionalInRange` (date change) |
| Notifications | `lib/pages/notifications_page.dart` | 22-23 | `notificationProvider.loadNotifications()` | `getNotificationsForUser` |
| Notifications | `lib/pages/notifications_page.dart` | 49 | `notificationProvider.markAllAsRead()` | `markAllAsRead` (batch) |
| Notifications | `lib/pages/notifications_page.dart` | 79 | `notificationProvider.markAsRead()` | `markAsRead` |
| Add Payment | `lib/pages/add_payment_page.dart` | 62 | `paymentProvider.recordPayment()` | `recordPayment` |
| Add Payment | `lib/pages/add_payment_page.dart` | 67-70 | `apptProvider.linkPaymentToAppointment()` | `updateAppointment`, then `getAppointments` |

---

## Collection Access Matrix

| Collection | Read By | Write By | Current Risk |
|---|---|---|---|
| `users` | `getUserById`, `isEmailTaken`, `getProfessionalsBySpecialty` | `insertUser`, `updateUser` | **Medium** — no per-user read restriction; `updateUser` writes entire document without field validation |
| `appointments` | `getUserById` (indirect via sync), `getAppointments` (ALL), `getAppointmentsByStatus` (ALL), `getPastAppointments` (ALL), `syncUserInAppointments` (by customerId/professionalId) | `insertAppointment`, `updateAppointment`, `deleteAppointment`, `syncUserInAppointments` (batch) | **Critical** — `getAppointments()`, `getAppointmentsByStatus()`, and `getPastAppointments()` return all appointments with no user filter |
| `payments` | `getPaymentByAppointment`, `getPaymentsByProfessional` (unused), `getPaymentsByProfessionalInRange` | `recordPayment`, `updatePayment`, `updatePaymentStatus` | **Medium** — no ownership checks; analytics queries are scoped by professionalId but rely on client enforcement |
| `notifications` | `getNotificationsForUser`, `markAllAsRead` (query), `getNotificationsStream` (unused) | `sendNotification`, `markAsRead`, `markAllAsRead` (batch) | **Medium** — `sendNotification` allows client-side spoofing; read/update operations are correctly scoped by `receiverId` but lack rule enforcement |

---

## Security Migration Impact

The following repository methods must change before strict Firestore security rules can be enabled:

### Critical — Must Change (Breaks with Strict Rules)

| # | Method | File | Why It Must Change |
|---|---|---|---|
| 1 | `getAppointments()` | `lib/repositories/firestore_booking_repository.dart:143-158` | Queries entire `appointments` collection with no user filter. Strict rules will block this. Must add `customerId` or `professionalId` filter |
| 2 | `getAppointmentsByStatus()` | `lib/repositories/firestore_booking_repository.dart:206-223` | Queries entire `appointments` collection by status with no user filter. Currently unused but will break with strict rules |
| 3 | `getPastAppointments()` | `lib/repositories/firestore_booking_repository.dart:226-247` | Queries entire `appointments` collection by dateTime with no user filter. Currently unused but will break with strict rules |

**Provider impact:** `AppointmentProvider` calls `getAppointments()` in `loadAppointments()` (line 45), `addAppointment()` (line 58), `updateAppointment()` (line 71), `deleteAppointment()` (line 84), `updateAppointmentStatus()` (line 102), and `linkPaymentToAppointment()` (line 215). All of these will need to pass the current user's ID and role to the repository query.

### High Priority — Should Change

| # | Method | File | Why It Should Change |
|---|---|---|---|
| 4 | `updateUser()` | `lib/repositories/firestore_booking_repository.dart:68-81` | Writes entire `toMap()` including potentially mutable `role` field. Rules should restrict writable fields |
| 5 | `updateAppointment()` | `lib/repositories/firestore_booking_repository.dart:176-188` | No ownership check before update. Rules will require `customerId` or `professionalId` match |
| 6 | `deleteAppointment()` | `lib/repositories/firestore_booking_repository.dart:191-203` | No ownership check before delete. Rules will require `customerId` or `professionalId` match |
| 7 | `sendNotification()` | `lib/repositories/notification_repository.dart:26-36` | Client-side write with no validation. Rules should deny client-side creation entirely |
| 8 | `recordPayment()` | `lib/repositories/firestore_payment_repository.dart:88-101` | No validation that `professionalId == request.auth.uid`. Rules must enforce this |
| 9 | `updatePayment()` | `lib/repositories/firestore_payment_repository.dart:104-117` | Writes entire `toMap()`; rules should restrict mutable fields |
| 10 | `syncUserInAppointments()` | `lib/repositories/firestore_booking_repository.dart:84-117` | Batch writes must be tested against per-document rules. May need rule adjustments for batch contexts |

### Medium Priority — Recommended Changes

| # | Method | File | Why It Should Change |
|---|---|---|---|
| 11 | `isEmailTaken()` | `lib/repositories/firestore_booking_repository.dart:38-51` | Works with current rules but may need an email index. Consider Cloud Function for server-side uniqueness check |
| 12 | `getProfessionalsBySpecialty()` | `lib/repositories/firestore_booking_repository.dart:121-140` | Add composite index on `role` + `specialty`. Ensure rules only expose booking-relevant fields |
| 13 | `getPaymentsByProfessionalInRange()` | `lib/repositories/firestore_payment_repository.dart:59-85` | Add composite index on `professionalId` + `appointmentDate`. Ensure rules restrict to owner |
| 14 | `getNotificationsStream()` | `lib/repositories/notification_repository.dart:96-101` | Currently unused. Either implement real-time UI or remove to reduce attack surface |
| 15 | `getPaymentByAppointment()` | `lib/repositories/firestore_payment_repository.dart:18-34` | Currently unused. Ensure rules validate appointment ownership if kept |
| 16 | `getPaymentsByProfessional()` | `lib/repositories/firestore_payment_repository.dart:37-56` | Currently unused. Either remove or add proper ownership rules |

---

## Recommended First Code Changes

To enable strict Firestore rules with minimal app breakage, make these changes in order:

1. **Split `getAppointments()` into user-scoped queries**
   - Create `getAppointmentsForCustomer(String customerId)` and `getAppointmentsForProfessional(String professionalId)` in `FirestoreBookingRepository`
   - Update `AppointmentProvider` to call the appropriate method based on `currentUser.role`
   - This is the single highest-impact change. It fixes the critical data exposure and enables per-user rules

2. **Remove or fix unused unscoped queries**
   - Either remove `getAppointmentsByStatus()` and `getPastAppointments()`, or add user ID parameters
   - Client-side filtering in `AppointmentProvider` already provides this functionality from the scoped `getAppointments()` data

3. **Restrict `updateUser()` writable fields**
   - Create a `toUpdatableMap()` method that excludes `role`, `id`, and other immutable fields
   - Update rules to validate only allowed fields are changed

4. **Migrate `sendNotification()` to Cloud Functions**
   - Deny client-side notification creation in rules (`allow create: if false`)
   - Create a Firebase Cloud Function triggered by appointment status changes
   - If client-side must remain temporarily, add `receiverId != request.auth.uid` validation

5. **Add required composite indexes**
   - `users`: `role` + `specialty`
   - `users`: `email`
   - `appointments`: `customerId` + `dateTime`
   - `appointments`: `professionalId` + `dateTime`
   - `appointments`: `status`
   - `payments`: `professionalId` + `appointmentDate`
   - `payments`: `appointmentId`
   - `notifications`: `receiverId` + `createdAt`
   - `notifications`: `receiverId` + `status`

---

## Summary

| Metric | Count |
|---|---|
| Total Firestore operations found | 25 |
| Collections accessed | 4 (`users`, `appointments`, `payments`, `notifications`) |
| Files with Firestore imports | 3 repositories |
| Read operations | 13 |
| Write operations (create/update/delete) | 8 |
| Batch operations | 2 |
| Stream operations | 1 (unused) |
| Unused repository methods | 4 (`getAppointmentsByStatus`, `getPastAppointments`, `getPaymentByAppointment`, `getPaymentsByProfessional`) |

| Risk Level | Count | Operations |
|---|---|---|
| Critical | 3 | `getAppointments()`, `getAppointmentsByStatus()`, `getPastAppointments()` |
| High | 1 | `sendNotification()` |
| Medium | 11 | `updateUser`, `syncUserInAppointments` (both sides), `insertAppointment`, `updateAppointment`, `deleteAppointment`, `getPaymentsByProfessional`, `getPaymentsByProfessionalInRange`, `recordPayment`, `updatePayment`, `updatePaymentStatus` |
| Low | 10 | `getUserById`, `isEmailTaken`, `insertUser`, `getProfessionalsBySpecialty`, `getPaymentByAppointment`, `getNotificationsForUser`, `markAsRead`, `markAllAsRead` (query+batch), `getNotificationsStream` |

**Highest risk operations:** `getAppointments()` is the most critical issue. It exposes all appointment data to any authenticated user and is called from every major app flow (login, booking, profile update, payment). Fixing this method is the prerequisite for enabling strict Firestore rules.

**Recommended first code change:** Split `getAppointments()` into `getAppointmentsForCustomer()` and `getAppointmentsForProfessional()`, update `AppointmentProvider` to use the scoped queries, and then remove the unfiltered `getAppointments()` method entirely.
