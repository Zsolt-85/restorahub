# RestoraHub — Project Overview & Status

## 1. Project Summary

RestoraHub is a Flutter cross-platform booking application for wellness and beauty services. It connects **customers** with **professionals** (massage therapists, hairstylists, spa specialists, facialists, and manicurists) to schedule, manage, and pay for appointments.

- **Platform**: Flutter (mobile, desktop, web)
- **Version**: 1.0.0
- **SDK**: Dart >= 3.0.0
- **Status**: Production-ready MVP with auth, booking, payments, notifications, analytics, and theme support

---

## 2. Core Features & Functionality

### 2.1 Authentication & User Management

| Feature | Status | Details |
|---|---|---|
| Email/Password Registration | ✅ Done | Customers and professionals register with name, phone, email, password |
| Role Selection | ✅ Done | Users choose `customer` or `professional` at registration; role is locked after creation |
| Login | ✅ Done | Firebase Auth email/password sign-in with credential validation |
| First-Login Profile Completion | ✅ Done | New accounts without a Firestore profile are prompted to complete name, phone, and role |
| Password Recovery | ✅ Done | "Forgot password" flow sends Firebase reset email |
| Session Restoration | ✅ Done | App restores Firebase session on startup and loads the user profile |
| Profile Editing | ✅ Done | Customers: update name, email, phone, password. Professionals: also edit specialty, work hours, and slot length |
| Email Uniqueness Check | ✅ Done | Registration and profile update both check for duplicate emails |
| Logout | ✅ Done | Signs out of Firebase Auth and clears the current user |

### 2.2 Service Catalog & Booking

| Feature | Status | Details |
|---|---|---|
| Service Browsing | ✅ Done | 5 categories: Massage, Haircut, Spa, Facial, Manicure |
| Service Subtypes | ✅ Done | Each category has subtypes (e.g., Massage → Full Body, Facial, Head & Neck) |
| Professional Filtering | ✅ Done | Only professionals whose `specialty` matches the selected service category are shown |
| Date Selection | ✅ Done | Date picker limited to today through +2 years |
| Time Slot Generation | ✅ Done | Slots are generated from the professional's configured `workStart`, `workEnd`, and `slotDurationMinutes` |
| Slot Availability Check | ✅ Done | Overlapping bookings for the same professional are blocked in real time |
| Booking Confirmation | ✅ Done | Appointment is created with customer and professional details copied into the record |
| Booking Summary | ✅ Done | Success screen shows service, professional, date/time, and duration |
| Booking Statuses | ✅ Done | `pending`, `confirmed`, `completed`, `cancelled` |

### 2.3 Appointment Management

| Feature | Status | Details |
|---|---|---|
| Customer Dashboard | ✅ Done | Shows upcoming appointments; empty state guides users to book |
| Professional Dashboard | ✅ Done | Shows incoming customer bookings; empty state explains the flow |
| Cancel Appointment | ✅ Done | Customers and professionals can cancel; appointment is removed from Firestore |
| Reschedule Appointment | ✅ Done | Customers can pick a new date and time; overlapping slot check is enforced |
| Past Appointments | ✅ Done | Dedicated page lists completed/cancelled past bookings |
| Appointment Filtering | ✅ Done | `filteredAppointments` returns role-appropriate lists (customer's own vs. professional's incoming) |
| Appointment Card Widget | ✅ Done | Reusable card showing service, date/time, status, and action buttons |

### 2.4 Payment System

| Feature | Status | Details |
|---|---|---|
| Payment Model | ✅ Done | Tracks amount, method (cash/card/transfer/other), status (pending/completed/refunded), currency, and receipt flag |
| Record Payment | ✅ Done | Professionals record a payment for a completed appointment |
| Link Payment to Appointment | ✅ Done | Recording a payment automatically marks the linked appointment as `completed` |
| Payment Repository | ✅ Done | Abstract interface with Firestore implementation; supports range queries |
| Earnings Report | ✅ Done | Professionals see total revenue, completed count, and average per appointment |
| Date-Range Filtering | ✅ Done | Earnings can be filtered by last 30 days, custom range, etc. |
| Share Report | ✅ Done | Earnings report can be shared as formatted text via `share_plus` |
| Receipt Generation | ✅ Done | Detailed receipt page with appointment, customer, professional, and payment details |
| Share Receipt | ✅ Done | Receipts can be shared as formatted text |

### 2.5 Notifications

| Feature | Status | Details |
|---|---|---|
| Notification Types | ✅ Done | `bookingRequested`, `bookingConfirmed`, `bookingCancelled`, `bookingRescheduled`, `bookingCompleted`, `upcomingReminder` |
| Notification Status | ✅ Done | `unread`, `read`, `dismissed` with visual distinction |
| Notifications Page | ✅ Done | Lists all notifications with relative timestamps (e.g., "5m ago") |
| Mark as Read | ✅ Done | Single notification tap marks it as read |
| Mark All as Read | ✅ Done | Batch action available when unread count > 0 |
| Upcoming Reminders | ✅ Done | `NotificationScheduleHelper` schedules local reminders 1 hour before appointments |
| Unread Count | ✅ Done | Badge-style count tracking in the provider |

### 2.6 Theme & UI

| Feature | Status | Details |
|---|---|---|
| Theme Selection | ✅ Done | 4 themes: Teal (default), Dark, Rose, Indigo |
| Theme Persistence | ✅ Done | Selected theme is saved to `shared_preferences` and restored on app launch |
| Loading States | ✅ Done | All data-loading screens show `CircularProgressIndicator` |
| Error States | ✅ Done | Errors display a message with a Retry button that re-triggers the load |
| App Drawer | ✅ Done | Navigation drawer with profile, notifications, past appointments, and settings links |

### 2.7 Analytics

| Feature | Status | Details |
|---|---|---|
| Analytics Dashboard | ✅ Done | Professionals-only page showing bookings, revenue, and upcoming appointments |
| Range Selector | ✅ Done | Segmented control for Day / Month / Year views |
| Total Bookings | ✅ Done | Counts filtered by selected range |
| Completed / Pending / Cancelled | ✅ Done | Counts pulled from `AppointmentProvider` |
| Revenue Display | ✅ Done | Shows revenue for the selected range |
| Upcoming Appointments List | ✅ Done | Lists future non-cancelled appointments with status badges |

---

## 3. Architecture & Data Flow

### 3.1 State Management

- **Provider + ChangeNotifier** is used throughout.
- **5 top-level providers** are injected via `MultiProvider` in `main.dart`:
  - `AuthProvider`
  - `AppointmentProvider`
  - `ThemeProvider`
  - `NotificationProvider`
  - `PaymentProvider`

### 3.2 Repository Pattern

- `BookingRepository` is an **abstract interface**.
- `FirestoreBookingRepository` is the **sole concrete implementation**.
- `PaymentRepository` follows the same pattern with `FirestorePaymentRepository`.
- `NotificationRepository` follows the same pattern with `FirestoreNotificationRepository`.
- This design allows swapping data sources (e.g., to a local DB or REST API) without changing UI or provider code.

### 3.3 Error Handling

- `AppException` is a typed exception that wraps repository errors with a user-friendly message and optional cause.
- UI code catches `AppException` to display errors and retry options.
- Generic `catch` blocks provide fallback error messages.

### 3.4 Data Models

| Model | Key Fields | Notes |
|---|---|---|
| `User` | `id`, `name`, `email`, `phone`, `role`, `specialty`, `workStartTime`, `workEndTime`, `slotDurationMinutes` | `role` is `customer` or `professional` |
| `Appointment` | `id`, `service`, `dateTime`, `durationMinutes`, `status`, `customerId`, `professionalId`, `paymentId` | Status enum: `pending`, `confirmed`, `completed`, `cancelled` |
| `Payment` | `id`, `appointmentId`, `customerId`, `professionalId`, `service`, `amount`, `currency`, `method`, `status`, `receiptGenerated` | Method enum: `cash`, `card`, `transfer`, `other` |
| `AppNotification` | `id`, `type`, `title`, `message`, `receiverId`, `senderId`, `status`, `createdAt` | Type enum covers all booking lifecycle events |
| `BookingSummary` | `service`, `professionalName`, `dateTime`, `durationMinutes` | Used for success screen arguments |

### 3.5 Persistence

| Data | Storage | Details |
|---|---|---|
| User credentials | Firebase Auth | Email/password accounts |
| User profiles | Cloud Firestore (`users` collection) | Name, phone, role, specialty, schedule |
| Appointments | Cloud Firestore (`appointments` collection) | Full booking details |
| Payments | Cloud Firestore (`payments` collection) | Payment records linked to appointments |
| Notifications | Cloud Firestore (`notifications` collection) | User-scoped notification history |
| Theme preference | `shared_preferences` | Local key-value store |

---

## 4. Project Structure

```
lib/
  main.dart                    # App entry, Firebase init, provider wiring, routes
  firebase_options.dart        # Firebase platform config

  constants/
    constants.dart             # Service catalog, icons, colors, slot options

  models/
    user.dart                  # User profile model
    appointment.dart           # Appointment model with status enums
    payment.dart               # Payment model with method/status enums
    notification.dart          # Notification model with type/status enums
    booking_summary.dart       # Lightweight DTO for booking success screen

  providers/
    auth_provider.dart         # Auth, registration, profile updates, password reset
    appointment_provider.dart  # Appointment CRUD, filtering, slot availability, reminders
    theme_provider.dart        # Theme selection and persistence
    payment_provider.dart      # Payment loading, recording, updating, revenue stats
    notification_provider.dart # Notification loading, read/unread tracking

  repositories/
    booking_repository.dart    # Abstract BookingRepository interface
    firestore_booking_repository.dart  # Firestore implementation for bookings and users
    payment_repository.dart    # Abstract PaymentRepository interface
    firestore_payment_repository.dart  # Firestore implementation for payments
    notification_repository.dart        # Abstract NotificationRepository interface
    firestore_notification_repository.dart  # Firestore implementation for notifications

  pages/
    login_page.dart            # Email/password login
    registration_page.dart     # Registration with role and specialty selection
    forgot_password_page.dart  # Password reset via Firebase email
    user_home_page.dart        # Customer dashboard
    professional_booking_management_page.dart  # Professional dashboard
    services_page.dart         # Service catalog grid with subtype picker
    booking_page.dart          # Full booking flow (professional, date, slot)
    edit_appointment_page.dart # Reschedule flow with slot picker
    profile_page.dart          # Edit profile (all roles); professional schedule settings
    settings_page.dart         # Theme picker and logout
    notifications_page.dart    # Notification list with read/unread actions
    analytics_page.dart        # Professional analytics (bookings, revenue, ranges)
    earnings_report_page.dart  # Professional earnings with date range and sharing
    add_payment_page.dart      # Record payment form with method selection
    receipt_page.dart          # Receipt view with share action
    past_appointments_page.dart # History of past bookings
    success_page.dart          # Booking confirmation summary

  widgets/
    appointment_card.dart      # Reusable appointment display with actions
    app_drawer.dart            # Navigation drawer

  helpers/
    validation_helper.dart     # Input validation (name, email, phone, password)
    schedule_helper.dart       # Slot generation, work schedule validation, service category parsing
    format_helper.dart         # Date/time formatting utilities
    theme_preferences.dart     # Theme persistence via shared_preferences
    notification_schedule_helper.dart  # Local notification scheduling
    app_exception.dart         # Typed repository error wrapper
    appointment_actions.dart   # Confirm/cancel/reschedule dialog logic

test/
  providers/
    payment_provider_test.dart
    appointment_provider_test.dart
  models/
    user_test.dart
```

---

## 5. Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart |
| State Management | Provider + ChangeNotifier |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Local Storage | shared_preferences |
| Notifications | flutter_local_notifications + timezone |
| Sharing | share_plus |
| Date/Time | intl |

---

## 6. Current Working Features (Verified)

- [x] Customer and professional registration with role locking
- [x] Firebase Auth login and session restoration
- [x] First-login profile completion dialog
- [x] Password reset via email
- [x] Profile editing for both roles
- [x] Professional schedule configuration (work hours, slot duration)
- [x] Service catalog with subtypes (5 categories, 3 subtypes each)
- [x] Booking flow with professional filtering by specialty
- [x] Time slot generation based on professional schedule
- [x] Overlapping booking prevention
- [x] Customer dashboard with upcoming appointments
- [x] Professional dashboard with incoming bookings
- [x] Cancel and reschedule with slot availability checks
- [x] Past appointments history
- [x] Payment recording and linking to appointments
- [x] Earnings report with date range and sharing
- [x] Receipt generation and sharing
- [x] Analytics dashboard (bookings, revenue, status breakdowns)
- [x] Notification system with 6 event types
- [x] Local upcoming appointment reminders
- [x] Theme selection (Teal, Dark, Rose, Indigo) with persistence
- [x] Loading and error states with retry on all data screens
- [x] Repository pattern with abstract interfaces
- [x] Typed exception handling

---

## 7. Potential Improvements & Brainstorming Ideas

### 7.1 UX & Onboarding
- Onboarding tutorial for first-time users
- Booking confirmation email/SMS to both customer and professional
- Push notifications (FCM) in addition to local scheduled reminders
- In-app chat between customer and professional before/after booking
- Booking calendar view (monthly/weekly) instead of list-only
- Drag-to-reschedule on calendar view
- Service pricing display during booking
- Customer reviews and ratings for professionals

### 7.2 Business Features
- Service pricing configuration per professional
- Discount codes and promotions
- Subscription or package deals (e.g., 5-massage bundle)
- Cancellation policy enforcement (e.g., 24h cutoff)
- Waitlist / auto-fill for cancelled slots
- Multi-location support for professionals
- Professional verification / badge system
- Admin dashboard for platform oversight

### 7.3 Data & Analytics
- Revenue charts (daily/weekly/monthly trends)
- Customer retention metrics for professionals
- Most popular services report
- Peak booking hours analysis
- Export earnings to PDF/CSV
- Advanced filters in analytics (by service, by professional)

### 7.4 Technical Improvements
- Offline mode with local cache and sync on reconnect
- Image upload for professional profiles and service galleries
- Biometric authentication (fingerprint/face)
- Multi-language support (i18n)
- Accessibility improvements (screen reader support, high contrast)
- Widget tests and integration tests expansion
- CI/CD pipeline
- Crash reporting (e.g., Firebase Crashlytics)
- Performance monitoring
- Dependency injection (e.g., get_it) for cleaner provider wiring
- API abstraction layer to prepare for future backend swap

### 7.5 Platform Expansion
- iOS and macOS native builds
- Web deployment with responsive design refinement
- PWA support for mobile web users

---

## 8. How to Run

```bash
flutter pub get
flutter run -d windows   # or android, web, ios, macos
```

## 9. How to Test

```bash
flutter test
```

---

*Generated on 2026-07-31*
