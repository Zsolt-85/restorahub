# Providers Audit

## AuthProvider

**File**: `lib/providers/auth_provider.dart` (283 lines)

### Responsibilities
- Firebase Auth sign-in, registration, and session restoration
- Profile creation and editing (name, email, phone, password, specialty, schedule)
- Email uniqueness validation
- Password reset email sending
- First-login profile completion flow

### Public Methods
| Method | Signature | Purpose |
|---|---|---|
| `login` | `(String email, String password) → Future<LoginResult>` | Authenticate user, load Firestore profile |
| `createProfile` | `(String name, String phone, String role, String specialty) → Future<bool>` | Create Firestore profile for first-login users |
| `register` | `(String email, String password, String role, String name, String phone, String specialty) → Future<String?>` | Full registration flow (Auth + Firestore profile) |
| `logout` | `() → Future<void>` | Sign out of Firebase Auth |
| `restoreSession` | `() → Future<bool>` | Restore Firebase session and load Firestore profile on app start |
| `sendPasswordResetEmail` | `(String email) → Future<String?>` | Send Firebase password reset email |
| `updateProfile` | `(String name, String email, String phone, String? newPassword, String? confirmPassword, String? specialty, TimeOfDay? workStart, TimeOfDay? workEnd, int? slotDurationMinutes) → Future<String?>` | Update user profile with full validation |

### Dependencies
- `BookingRepository` (abstract) — for user CRUD operations
- `FirebaseAuth` (Firebase) — for auth operations
- `ValidationHelper` — for input validation
- `ScheduleHelper` — for work schedule validation

### State Exposed
- `User? currentUser` — the currently logged-in user
- `LoginResult` enum — returned by `login()` to signal first-login flow

### Whether Responsibilities Are Appropriate
The responsibilities are broadly appropriate for an auth provider, though the provider has considerable breadth:

- **Profile editing** (name, email, phone, password, specialty, schedule) belongs in the same provider as authentication, which is common in small apps but creates a large provider.
- **Email uniqueness check** is a data-layer concern that leaks into the provider.
- **First-login profile completion** is a UI-flow concern that is partially handled in `LoginPage` with `createProfile()`.

### Possible Future Improvements
- Split profile editing into a separate `ProfileProvider` to reduce `AuthProvider` size
- Extract email uniqueness checking into the repository layer
- Add `Stream<User?>` to expose auth state changes reactively

---

## AppointmentProvider

**File**: `lib/providers/appointment_provider.dart` (291 lines)

### Responsibilities
- Loading all appointments from the repository
- Creating, updating, and deleting appointments
- Filtering appointments by status, role, and time period
- Slot availability checking
- Linking payments to appointments
- Scheduling local notification reminders
- Count queries for analytics

### Public Methods
| Method | Signature | Purpose |
|---|---|---|
| `loadAppointments` | `() → Future<void>` | Fetch all appointments from repository |
| `addAppointment` | `(Appointment appt) → Future<void>` | Insert new appointment and reload list |
| `updateAppointment` | `(Appointment appt) → Future<void>` | Update existing appointment and reload list |
| `deleteAppointment` | `(String id) → Future<void>` | Delete appointment by ID |
| `updateAppointmentStatus` | `(String id, AppointmentStatus newStatus) → Future<void>` | Change appointment status |
| `isSlotAvailable` | `(DateTime slotStart, int slotDuration, String professionalId, {String? excludeAppointmentId}) → bool` | Check if a time slot is free |
| `linkPaymentToAppointment` | `(String appointmentId, String paymentId) → Future<void>` | Mark appointment completed after payment |
| `cancelAppointment` | `(String id) → Future<String?>` | Cancel (delete) an appointment |
| `rescheduleAppointment` | `(Appointment appointment, DateTime newDateTime) → Future<String?>` | Reschedule with slot availability check |
| `setCurrentUser` | `(User user) → void` | Set current user and reload appointments |
| `scheduleUpcomingReminders` | `() → Future<void>` | Schedule local notifications for upcoming appointments |

### Getters (Derived State)
| Getter | Purpose |
|---|---|
| `appointments` | Full list of loaded appointments |
| `filteredAppointments` | Role-filtered list (customer's own vs. professional's incoming) |
| `pendingAppointments` | Appointments with `pending` status |
| `confirmedAppointments` | Appointments with `confirmed` status |
| `completedAppointments` | Appointments with `completed` status |
| `cancelledAppointments` | Appointments with `cancelled` status |
| `pastAppointments` | Appointments in the past that are completed or cancelled |
| `currentAppointments` | Future non-cancelled appointments |
| `getAppointmentCountForMonth(int year, int month)` | Count of appointments for a specific month |
| `getYearToDateAppointmentCount(int year)` | Year-to-date appointment count |

### Dependencies
- `BookingRepository` (abstract) — for all data operations
- `NotificationScheduleHelper` — for scheduling local reminders
- `ScheduleHelper` — for slot availability logic

### State Exposed
- `List<Appointment> appointments` — all loaded appointments
- `List<Appointment> filteredAppointments` — role-appropriate subset
- `List<Appointment>` status-filtered getters
- `bool isLoading` — whether a data operation is in progress
- `String? error` — last error message, if any
- `User? currentUser` — the current user for role-based filtering

### Whether Responsibilities Are Appropriate
`AppointmentProvider` is the largest and most complex provider. Its responsibilities are reasonable for a booking app but it has several areas of concern:

- **Notification scheduling** (`scheduleUpcomingReminders`) is a cross-cutting concern that arguably belongs in its own provider or a dedicated service.
- **Analytics count methods** (`getAppointmentCountForMonth`, `getYearToDateAppointmentCount`) are analytics-specific and could be extracted.
- **`setCurrentUser`** both sets state and triggers a data load, which is a side effect in a setter-like method.
- **`filteredAppointments`** depends on `currentUser` being set; if it is null, it returns an empty list, which is a silent failure mode.

### Possible Future Improvements
- Extract notification scheduling into a dedicated `NotificationScheduleProvider` or service
- Create `AnalyticsProvider` for count queries and date-range computations
- Add `Stream` support for real-time appointment updates
- Implement pagination for large appointment lists

---

## ThemeProvider

**File**: `lib/providers/theme_provider.dart` (98 lines)

### Responsibilities
- Managing app theme selection (Teal, Dark, Rose, Indigo)
- Building `ThemeData` for each theme variant
- Persisting and restoring theme preference via `shared_preferences`

### Public Methods
| Method | Signature | Purpose |
|---|---|---|
| `loadTheme` | `() → Future<void>` | Load saved theme from shared_preferences |
| `setTheme` | `(AppTheme theme) → void` | Set theme and persist to shared_preferences |

### Getters (Derived State)
| Getter | Purpose |
|---|---|
| `currentTheme` | Currently selected `AppTheme` enum |
| `theme` | `ThemeData` for the currently selected theme |

### Dependencies
- `ThemePreferences` (helper) — for persistence
- Flutter `ThemeData` — for building theme objects

### State Exposed
- `AppTheme currentTheme` — the selected theme enum
- `ThemeData theme` — the material theme data

### Whether Responsibilities Are Appropriate
The responsibilities are well-scoped and appropriate. `ThemeProvider` is a clean, focused provider that does one thing well. The `theme` getter is a computed property that reconstructs `ThemeData` on each access, which is acceptable for a small number of theme options.

### Possible Future Improvements
- Add support for dynamic theming (e.g., custom accent colors)
- Support system dark/light mode detection as a theme option

---

## PaymentProvider

**File**: `lib/providers/payment_provider.dart` (108 lines)

### Responsibilities
- Loading payments for a professional (all or date-range filtered)
- Recording new payments
- Updating payment records
- Updating payment status
- Computing revenue statistics (total revenue, completed count)
- Selecting a payment for detail viewing

### Public Methods
| Method | Signature | Purpose |
|---|---|---|
| `loadPaymentsForProfessional` | `(String professionalId) → Future<void>` | Load all payments for a professional |
| `loadPaymentsForProfessionalInRange` | `(String professionalId, DateTime start, DateTime end) → Future<void>` | Load payments within a date range |
| `recordPayment` | `(Payment payment) → Future<void>` | Save a new payment record |
| `updatePayment` | `(Payment payment) → Future<void>` | Update an existing payment |
| `updatePaymentStatus` | `(String paymentId, PaymentStatus status) → Future<void>` | Update only the status field |
| `selectPayment` | `(Payment? payment) → void` | Set the selected payment for detail view |

### Getters (Derived State)
| Getter | Purpose |
|---|---|
| `payments` | All loaded payments |
| `selectedPayment` | Currently selected payment |
| `totalRevenue` | Sum of all completed payment amounts |
| `completedCount` | Count of completed payments |

### Dependencies
- `PaymentRepository` (abstract, defaults to `FirestorePaymentRepository.instance`)

### State Exposed
- `List<Payment> payments`
- `Payment? selectedPayment`
- `double totalRevenue`
- `int completedCount`

### Whether Responsibilities Are Appropriate
The responsibilities are well-scoped. However, there is a notable issue: `PaymentProvider` defaults to `FirestorePaymentRepository.instance` directly rather than receiving the repository via constructor injection like `AuthProvider` and `AppointmentProvider`. This inconsistency means the dependency injection is less testable for `PaymentProvider`.

### Possible Future Improvements
- Accept `PaymentRepository` via constructor injection in `main.dart` for consistency and testability
- Add revenue trend data (daily/weekly breakdown)
- Add export functionality (CSV/PDF) computation within the provider

---

## NotificationProvider

**File**: `lib/providers/notification_provider.dart` (65 lines)

### Responsibilities
- Loading notifications for the current user
- Tracking unread notification count
- Marking individual notifications as read
- Marking all notifications as read
- Adding notifications to the in-memory list (optimistic updates)

### Public Methods
| Method | Signature | Purpose |
|---|---|---|
| `loadNotifications` | `(String userId) → Future<void>` | Load notifications for a user from repository |
| `markAsRead` | `(String notificationId) → Future<void>` | Mark a single notification as read |
| `markAllAsRead` | `(String userId) → Future<void>` | Mark all unread notifications as read |
| `addNotification` | `(AppNotification notification) → void` | Add a notification optimistically (no repository call) |

### Getters (Derived State)
| Getter | Purpose |
|---|---|
| `notifications` | All loaded notifications |
| `unreadCount` | Count of unread notifications |

### Dependencies
- `NotificationRepository` (abstract, defaults to `FirestoreNotificationRepository.instance`)

### State Exposed
- `List<AppNotification> notifications`
- `int unreadCount`

### Whether Responsibilities Are Appropriate
The responsibilities are well-scoped and appropriate. However, `addNotification()` performs an in-memory-only update without persisting to the repository, which is inconsistent with other providers. This method is likely used for optimistic UI updates when a notification is triggered locally, but the lack of a corresponding persistence call means the notification will not survive app restarts unless loaded from Firestore again.

### Possible Future Improvements
- Add persistence call in `addNotification()` or document the intentional in-memory-only behavior
- Subscribe to the `getNotificationsStream()` defined in `NotificationRepository` for real-time updates (currently unused)
- Add notification grouping or threading for related events