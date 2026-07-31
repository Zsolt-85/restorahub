# Testing Audit

## Current Tests

### Test Files

| File | Tests | What's Covered |
|---|---|---|
| `test/models/user_test.dart` | 3 tests | `User.copyWith()` preserves role; professional defaults; `formatTime` round-trip |
| `test/providers/appointment_provider_test.dart` | 7 tests | `loadAppointments`, `addAppointment`, `updateAppointment`, `deleteAppointment`, `linkPaymentToAppointment`, `rescheduleAppointment` (success + failure) |
| `test/providers/payment_provider_test.dart` | 5 tests | Initial state, `recordPayment`, `totalRevenue`/`completedCount` filtering, `updatePayment`, `loadPaymentsForProfessionalInRange`, `selectPayment` |
| `test/helpers/schedule_helper_test.dart` | 6 tests | `parseServiceCategory`, `generateSlots`, `intervalsOverlap`, `isSlotAvailable` (excluded appt, conflict, no conflict), `validateWorkSchedule` |
| `test/helpers/validation_helper_test.dart` | 3 tests | `validateEmail`, `validatePhone`, `validatePassword` |

### Total Test Count
- **24 tests** across 5 test files
- All tests use `FakeBookingRepository` or `FakePaymentRepository` (in-memory fakes)
- No tests use real Firebase or Firestore

### Test Infrastructure
- `flutter_test` framework (standard Flutter testing)
- No mock package (fakes are hand-rolled)
- No integration tests
- No widget tests
- No golden tests

## Missing Tests

### Critical Gaps

1. **AuthProvider**: No tests for `login()`, `register()`, `createProfile()`, `updateProfile()`, `restoreSession()`, `sendPasswordResetEmail()`, `logout()`. This is the most critical gap — auth is the security boundary of the app.

2. **NotificationProvider**: No tests for `loadNotifications()`, `markAsRead()`, `markAllAsRead()`, `addNotification()`.

3. **PaymentProvider**: Tests exist, but no test for `updatePaymentStatus()` — a key method for payment lifecycle management.

4. **PaymentRepository**: No tests for `FirestorePaymentRepository` — the concrete Firestore implementation is untested.

5. **BookingRepository**: No tests for `FirestoreBookingRepository` — the most complex repository (handles both users and appointments) is entirely untested.

6. **NotificationRepository**: No tests for `FirestoreNotificationRepository` — including `markAllAsRead()` batch write and `getNotificationsStream()` real-time listener.

### Repository Layer

7. **No repository tests at all** — all repository layer code (including error handling, `AppException` wrapping, and Firestore query construction) is untested.

### Firestore Models

8. **Appointment model**: No tests for `toMap()`/`fromMap()` serialization, `copyWith()`, computed getters (`endTime`, `isPast`).

9. **Payment model**: No tests for `toMap()`/`fromMap()` serialization, `copyWith()`, computed getters (`methodLabel`, `statusLabel`).

10. **AppNotification model**: No tests for `toMap()`/`fromMap()` serialization.

11. **BookingSummary model**: No tests at all.

### Helpers

12. **FormatHelper**: No tests — date/time formatting is untested.

13. **ThemePreferences**: No tests — persistence logic is untested.

14. **NotificationScheduleHelper**: No tests — local notification scheduling is untested.

15. **AppointmentActions**: No tests — the confirmation dialog logic (cancel, reschedule, status change) is untested.

### Pages and Widgets

16. **No widget tests** — all 18 page widgets and 2 shared widgets are untested.

17. **No page navigation tests** — route resolution, navigation flows, and auth redirects are untested.

### Integration

18. **No integration tests** — end-to-end user flows (register → login → book → pay → receipt) are untested.

## High-Risk Areas

1. **Authentication** — `AuthProvider` has no tests. Auth failures are security-sensitive and directly impact user trust.
2. **Firestore repository error handling** — All repository methods wrap errors in `AppException` but this error wrapping is untested. If `AppException` is not thrown correctly, users will see raw Firebase errors.
3. **Payment recording and linking** — The payment-to-appointment linking flow (`recordPayment` → `linkPaymentToAppointment`) has no integration test. A failure in this flow means appointments remain unpaid or payments are orphaned.
4. **Slot availability** — `ScheduleHelper.isSlotAvailable()` has tests but the integration with `AppointmentProvider.isSlotAvailable()` is not tested. Race conditions (two users booking the same slot simultaneously) are not addressed.
5. **Data serialization** — `fromMap()`/`toMap()` round-trip for all models is untested. A serialization bug would corrupt all data persisted to Firestore.

## Suggested Testing Strategy

### Short Term (P1)
1. **AuthProvider tests** — Test `login()` with valid/invalid credentials, `register()` with valid/invalid inputs, `restoreSession()`, `updateProfile()`, and `sendPasswordResetEmail()`.
2. **Repository tests** — Add tests for `FirestoreBookingRepository`, `FirestorePaymentRepository`, and `FirestoreNotificationRepository` using mocking (e.g., `mockito` or `firebase_mock`) to verify Firestore queries are constructed and called correctly.
3. **Firestore model serialization tests** — Add round-trip tests for `toMap()`/`fromMap()` on all 5 models.
4. **NotificationProvider tests** — Test `loadNotifications()`, `markAsRead()`, `markAllAsRead()`, and `addNotification()`.

### Medium Term (P2)
5. **PaymentProvider completion** — Add tests for `updatePaymentStatus()`.
6. **Widget tests** — Write widget tests for the main page widgets (login, registration, home screens).
7. **Navigation tests** — Test route resolution at startup and auth-protected route redirects.
8. **Helper tests** — Add tests for `FormatHelper`, `ThemePreferences`, and `AppointmentActions`.

### Long Term (P3)
9. **Integration tests** — Write integration tests for key user flows (register, login, book, pay, receipt).
10. **Performance tests** — Benchmark `getAppointments()` with large collections to establish baseline performance.
11. **Golden tests** — Add golden tests for critical screens to detect UI regressions.