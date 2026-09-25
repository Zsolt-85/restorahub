# RestoraHub Project Continuation Checkpoint

**Date:** 2026-08-25
**Tests:** 149/149 passing

---

## Current Completed Features & Phases

### Phase 1: Atomic Transactions & Availability Hardening
- Range-based slot availability queries (`checkProfessionalAvailability` uses `isLessThan` + in-code overlap detection)
- Atomic appointment creation with double-booking prevention (`createAppointmentAtomic` via Firestore transaction)
- Comprehensive debug logging for availability checks

### Phase 2: Schedule Logic (Buffer/Break Time)
- Professional `bufferTimeMinutes` and `breakStartTime`/`breakEndTime` profile fields
- `ScheduleHelper` generates slots respecting work hours, slot duration, buffer time, and breaks
- Slot availability checks respect buffer time between appointments

### Phase 3: Real-Time Availability & State Machine Hardening
- Explicit appointment status enum: `pending`, `confirmed`, `completed`, `cancelledByCustomer`, `cancelledByProfessional`, `noShow`
- State machine helpers: `canTransitionTo()`, `withStatus()`, `canBeCancelledByCustomer()`, `canBeRescheduled()`, `isTerminal`, `isCancelled`
- Terminal status invariant enforced: terminal statuses cannot transition to any other status
- 2-hour cancellation window enforcement with typed `AppException`
- Backward-compatible `fromMap` handling for legacy `cancelled` Firestore data (maps to `cancelledByCustomer`)
- Real-time Firestore streaming via `BookingRepository.watchAppointmentsForCustomer()`, `watchAppointmentsForProfessional()`, `watchAppointment()`
- `AppointmentProvider.startRealtimeAppointments()` / `stopRealtimeAppointments()` for live UI updates

### Phase 4: Native Device Calendar Integration
- Added `add_2_calendar: ^3.0.1` dependency
- `CalendarHelper.addToNativeCalendar()` builds native calendar events with title, description, times, and location
- "Add to Calendar" button on booking confirmation screen with success/error `SnackBar` feedback

### Phase 5: Dependency Injection Cleanup — Repository Split
- Split `BookingRepository` into `BookingRepository` (appointments) and `UserRepository` (user profiles)
- Created `FirestoreUserRepository` singleton implementing `UserRepository`
- Moved user methods (`getUserById`, `isEmailTaken`, `insertUser`, `updateUser`, `syncUserInAppointments`, `getProfessionalsBySpecialty`) from `BookingRepository` to `UserRepository`
- Updated `AuthProvider` to depend on `UserRepository` instead of `BookingRepository`
- Updated `AppointmentProvider` to accept both `BookingRepository` and `UserRepository`; `rescheduleAppointment` now uses `UserRepository` for `bufferTimeMinutes`
- Updated pages (`edit_appointment_page.dart`, `booking_page.dart`, `success_page.dart`) to read `UserRepository` directly from the Provider tree
- Updated `main.dart` to provide `UserRepository` in `MultiProvider`
- Split `FakeBookingRepository` in tests into `FakeBookingRepository` (appointment-only) and `FakeUserRepository` (user-only)

### Phase 6: Platform Audit & Security Hardening (Sprint 1)
- **Domain Audit Complete**: `DOMAIN_AUDIT.md` documents 47 wellness-specific assumptions (18 CORE, 16 CONFIGURATION, 13 MODULE)
- **Security Audit Complete**: `SECURITY_AUDIT.md` identifies 7 critical security gaps with proposed fixes
- **Firestore Rules Rewritten**: Fixed `isBusinessMatch` null bypass, restricted users collection reads, restricted notification creation, added role-based helpers
- **Cross-Tenant Isolation Tests**: Added tests proving tenant data isolation
- **Privilege Escalation Tests**: Added tests proving role boundaries are enforced

---

## Test & Analysis Status

| Check | Status | Details |
|-------|--------|---------|
| `flutter analyze` | **0 errors** | 2 deprecation warnings only (`value` → `initialValue`) |
| `flutter test` | **123/123 passing** | 12 new security tests added |

### Sprint 2: Business Model Expansion & Technical Debt Remediation
- **PLAT-0201 Complete**: Business model expanded from 7 to 18 fields with backward compatibility
  - New fields: `slug`, `businessType`, `status`, `ownerId`, `contactInformation`, `branding`, `settings`, `subscription`, `featureEntitlements`, `createdAt`, `updatedAt`
  - Helper classes: `BusinessBranding`, `BusinessContactInformation`, `BusinessSettings`, `BusinessSubscription`
  - Enums: `BusinessType`, `BusinessStatus`
  - Effective property fallbacks: `effectivePrimaryColor`, `effectiveBusinessName`, `effectiveLogo`
- **TD-001 Complete**: Repository reads now enforce `businessId` filtering
- **TD-002 Complete**: Pagination added to `getAppointmentsForBusiness()` with `limit` and `startAfterDocumentId`
- **TD-006 Complete**: Eager loading deferred until session restoration completes in `main.dart`
- **TD-008 Verified**: DI already consistent (NotificationProvider/PaymentProvider use constructor injection)
- **TD-005 Started**: `UserResolutionHelper` created for runtime user data resolution
- **Tests**: 149/149 passing (26 new tests for Business model and UserResolutionHelper)

---

## Key Audit Deliverables

### DOMAIN_AUDIT.md
- 18 CORE findings requiring terminology rename (`professional` → `staff`, `specialty` → `category`)
- 16 CONFIGURATION findings (hardcoded wellness catalog in `constants.dart`)
- 13 MODULE findings (feature-flag candidates)
- Dependency map for wellness catalog removal

### SECURITY_AUDIT.md
- 3 Critical findings (null bypass, users readable by all, notifications creatable by anyone)
- 3 High findings (businesses public, no role verification, no field restrictions)
- 1 Medium finding (no audit trail)
- Complete revised Firestore rules
- Cross-tenant isolation test plan
- Privilege escalation test plan

---

## Pending / Next Immediate Tasks

### Sprint 2 — Model & Security Hardening
- **PLAT-0201**: Expand Business model (additive migration: `businessType`, `status`, `ownerId`, `subscription`, `settings`, `branding`)
- **TD-001**: Add `businessId` filtering to all repository methods
- **TD-002**: Add pagination to `getAppointmentsForBusiness()`
- **TD-005**: Begin denormalized data removal (Appointment model first)
- **TD-006**: Fix eager loading in `main.dart`
- **TD-007**: Ensure all routes use centralized guards
- **TD-008**: Fix DI inconsistency in providers

### Sprint 3 — Domain Generalization
- **REF-001**: Rename wellness terminology (`User.specialty` → `category`, `professional` → `staff`)
- **REF-002**: Generalize Service model
- **REF-003**: Remove hardcoded service catalog
- **TD-015**: Remove legacy migration logic

---

## Instructions for Next Session

> **Project:** RestoraHub — Flutter booking app transforming into multi-tenant white-label SaaS platform.
>
> **Current State (2026-08-25, baseline/v1.0 tag):**
> - 123/123 unit tests passing, `flutter analyze` clean (0 errors)
> - Domain audit complete: `DOMAIN_AUDIT.md` (47 findings)
> - Security audit complete: `SECURITY_AUDIT.md` (7 gaps, rules rewritten)
> - Firestore rules hardened with role-based access control
> - Cross-tenant isolation and privilege escalation tests added
>
> **Key files to review first:**
> - `DOMAIN_AUDIT.md` — full domain audit with rename plan
> - `SECURITY_AUDIT.md` — security audit with revised rules
> - `firestore.rules` — hardened security rules
> - `lib/models/user.dart` — String-based role, `specialty` field (rename target)
> - `lib/models/appointment.dart` — stable state machine, denormalized fields (removal target)
> - `lib/models/business.dart` — minimal 7-field model (expansion target)
> - `lib/constants/constants.dart` — hardcoded wellness catalog (removal target)
> - `lib/providers/appointment_provider.dart` — 631-line God object (refactor target)
> - `lib/pages/booking_page.dart` — 920 lines, depends on hardcoded catalog
>
> **Next tasks:** Execute Sprint 2 (Business model expansion, repository filtering, pagination, denormalized data removal, eager loading fix, DI cleanup).
>
> **How to verify:** Run `flutter analyze` (expect 0 errors) and `flutter test` (expect 123/123 passing).
