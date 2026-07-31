# Models Audit

## User

**File**: `lib/models/user.dart` (99 lines)

### Fields
| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String?` | No | `null` | Firestore document ID |
| `name` | `String` | Yes | — | Full name |
| `email` | `String` | Yes | — | Email address (normalized to lowercase) |
| `phone` | `String` | Yes | — | Phone number |
| `role` | `String` | Yes | `'customer'` | `'customer'` or `'professional'` |
| `specialty` | `String` | No | `''` | Professional specialty |
| `workStartTime` | `String` | No | `'09:00'` | Work day start (HH:mm) |
| `workEndTime` | `String` | No | `'17:00'` | Work day end (HH:mm) |
| `slotDurationMinutes` | `int` | No | `60` | Appointment slot duration |

### Responsibilities
- Represents a user profile in the system
- Provides role-based behavior (`isProfessional`, `roleLabel`)
- Provides work schedule helpers (`workStart`, `workEnd` as `TimeOfDay`)
- Serializes to/from Firestore map via `toMap()`/`fromMap()`
- Supports `copyWith()` for immutable updates

### Relationships
- One-to-many with `Appointment` (as `customerId` or `professionalId`)
- One-to-many with `Payment` (as `customerId` or `professionalId`)
- One-to-many with `AppNotification` (as `receiverId`)

### Possible Duplication
- `phone` and `email` are stored in both `User` and `Appointment` (copied into `customerPhone`, `customerEmail`, `professionalPhone`, `professionalEmail`). This denormalization requires manual sync via `syncUserInAppointments()`.

### Future Considerations
- Consider storing phone formatted rather than raw digits
- `workStartTime`/`workEndTime` are strings (`HH:mm`) — consider using a `Duration` or minutes-since-midnight integer for easier computation
- The `isProfessional` getter derives from `role == 'professional'`, which is a string comparison rather than an enum

---

## Appointment

**File**: `lib/models/appointment.dart` (130 lines)

### Fields
| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String?` | No | `null` | Firestore document ID |
| `service` | `String` | Yes | — | Service name (e.g., "Massage — Full Body") |
| `dateTime` | `DateTime` | Yes | — | Scheduled date and time |
| `durationMinutes` | `int` | No | `60` | Appointment duration |
| `status` | `AppointmentStatus` | No | `pending` | Enum: pending, confirmed, completed, cancelled |
| `paymentId` | `String?` | No | `null` | Linked payment document ID |
| `customerId` | `String?` | No | `null` | Reference to customer user document |
| `customerName` | `String?` | No | `null` | Denormalized customer name |
| `customerPhone` | `String?` | No | `null` | Denormalized customer phone |
| `customerEmail` | `String?` | No | `null` | Denormalized customer email |
| `professionalId` | `String?` | No | `null` | Reference to professional user document |
| `professionalName` | `String?` | No | `null` | Denormalized professional name |
| `professionalPhone` | `String?` | No | `null` | Denormalized professional phone |
| `professionalEmail` | `String?` | No | `null` | Denormalized professional email |

### Responsibilities
- Represents a booking between a customer and a professional
- Includes computed getters (`endTime`, `isPast`)
- Serializes to/from Firestore map via `toMap()`/`fromMap()`
- Supports `copyWith()` for immutable updates
- Handles legacy data format migration in `fromMap()` (parses `type` field for service display)

### Relationships
- Belongs to one `User` as `customerId`
- Belongs to one `User` as `professionalId`
- Belongs to one `Payment` via `paymentId`
- Contains redundant copies of `User` fields (name, phone, email) for both customer and professional

### Possible Duplication
- **Significant**: User contact data (name, phone, email) is duplicated into the appointment document for both the customer and the professional. This is updated via `syncUserInAppointments()` in `FirestoreBookingRepository`, but creates a data consistency risk if the sync fails or is skipped.

### Future Considerations
- Consider moving denormalized user data out of `Appointment` and resolving it at query time via joins (or application-level lookups)
- The `service` field stores a combined string like "Massage — Full Body" — consider splitting into `serviceCategory` and `serviceSubtype` for more flexible querying
- `fromMap()` has legacy migration logic for `type` field — this technical debt should be cleaned up if no longer needed

---

## Payment

**File**: `lib/models/payment.dart` (176 lines)

### Fields
| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String?` | No | `null` | Firestore document ID |
| `appointmentId` | `String` | Yes | — | Linked appointment document ID |
| `customerId` | `String` | Yes | — | Reference to customer user |
| `customerName` | `String` | Yes | — | Denormalized customer name |
| `customerPhone` | `String` | Yes | — | Denormalized customer phone |
| `customerEmail` | `String` | Yes | — | Denormalized customer email |
| `professionalId` | `String` | Yes | — | Reference to professional user |
| `professionalName` | `String` | Yes | — | Denormalized professional name |
| `professionalPhone` | `String` | Yes | — | Denormalized professional phone |
| `professionalEmail` | `String` | Yes | — | Denormalized professional email |
| `service` | `String` | Yes | — | Service name |
| `specialty` | `String` | Yes | — | Professional specialty |
| `appointmentDate` | `DateTime` | Yes | — | Date of the appointment |
| `appointmentTime` | `String` | Yes | — | Time of appointment (HH:mm) |
| `appointmentDurationMinutes` | `int` | Yes | — | Duration in minutes |
| `amount` | `double` | Yes | — | Payment amount |
| `currency` | `String` | No | `'EUR'` | Currency code |
| `method` | `PaymentMethod` | No | `cash` | Enum: cash, card, transfer, other |
| `status` | `PaymentStatus` | No | `pending` | Enum: pending, completed, refunded |
| `receiptGenerated` | `bool` | No | `false` | Whether a receipt has been generated |

### Responsibilities
- Represents a payment record linked to an appointment
- Includes computed getters (`methodLabel`, `statusLabel`)
- Serializes to/from Firestore map via `toMap()`/`fromMap()`
- Supports `copyWith()` for immutable updates

### Relationships
- Belongs to one `Appointment` via `appointmentId`
- Contains denormalized copies of both customer and professional user data

### Possible Duplication
- **High**: Payment stores the full user contact details for both customer and professional (name, phone, email), plus service name, specialty, appointment date/time, and duration. This is a significant amount of denormalized data that duplicates information already in the `Appointment` and `User` models.

### Future Considerations
- Consider storing only IDs and resolving user data at read time
- The `appointmentTime` field (String HH:mm) is redundant since `appointmentDate` already contains the full DateTime
- `currency` is hardcoded to EUR in the default constructor but is configurable

---

## AppNotification

**File**: `lib/models/notification.dart` (69 lines)

### Fields
| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | `String?` | No | `null` | Firestore document ID |
| `type` | `NotificationType` | Yes | — | Enum: bookingRequested, bookingConfirmed, bookingCancelled, bookingRescheduled, bookingCompleted, upcomingReminder |
| `title` | `String` | Yes | — | Notification title |
| `message` | `String` | Yes | — | Notification body |
| `appointmentId` | `String?` | No | `null` | Reference to related appointment |
| `receiverId` | `String` | Yes | — | Target user document ID |
| `senderId` | `String` | Yes | — | Source user document ID |
| `status` | `NotificationStatus` | No | `unread` | Enum: unread, read, dismissed |
| `createdAt` | `DateTime` | No | `DateTime.now()` | When the notification was created |

### Responsibilities
- Represents a user-facing notification
- Types cover the full booking lifecycle (requested → confirmed → completed, plus cancellation, reschedule, and reminders)
- Status tracking for read/unread/dismissed states

### Relationships
- Belongs to one `Appointment` via `appointmentId`
- Directed from `senderId` to `receiverId` (user-to-user)

### Possible Duplication
- `appointmentId` duplicates a reference that could be navigated via the appointment document ID

### Future Considerations
- Consider adding a `targetRoute` field to support deep linking to specific pages when a notification is tapped
- The `dismissed` status is defined but never used in the current UI

---

## BookingSummary

**File**: `lib/models/booking_summary.dart` (17 lines)

### Fields
| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `service` | `String` | Yes | — | Service name |
| `professionalName` | `String` | Yes | — | Professional's display name |
| `dateTime` | `DateTime` | Yes | — | Scheduled date and time |
| `durationMinutes` | `int` | Yes | — | Duration in minutes |
| `status` | `AppointmentStatus` | No | `pending` | Appointment status |

### Responsibilities
- Lightweight DTO passed as route arguments from `BookingPage` to `SuccessPage`
- Contains only the essential display fields needed on the booking confirmation screen

### Relationships
- References `AppointmentStatus` enum from the `appointment.dart` model

### Possible Duplication
- None — this is intentionally a minimal DTO

### Future Considerations
- Could be expanded to include booking ID for deep linking to the appointment detail