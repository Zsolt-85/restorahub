# Firestore Audit

## Collections

### `users`
- **Purpose**: Stores user profiles (both customers and professionals)
- **Document ID**: Firebase Auth UID (`user.uid`)
- **Fields stored**: `id`, `name`, `email`, `phone`, `role`, `specialty`, `workStartTime`, `workEndTime`, `slotDurationMinutes`
- **Indexes needed**:
  - Single field: `email` (for uniqueness checks)
  - Compound: `role` + `specialty` (for `getProfessionalsBySpecialty`)

### `appointments`
- **Purpose**: Stores all booking records
- **Document ID**: Firestore auto-generated
- **Fields stored**: `id`, `paymentId`, `service`, `dateTime`, `durationMinutes`, `status`, `customerId`, `customerName`, `customerPhone`, `customerEmail`, `professionalId`, `professionalName`, `professionalPhone`, `professionalEmail`
- **Indexes needed**:
  - Single field: `status` (for `getAppointmentsByStatus`)
  - Single field: `dateTime` (for `getPastAppointments` range query)
  - Compound: `professionalId` + `dateTime` (for slot availability and professional-specific queries)
  - Compound: `customerId` + `dateTime` (for user-specific past/future queries)
  - Compound: `dateTime` + `status` (for analytics queries)
- **Concern**: Contains denormalized user data (name, phone, email for both parties) which duplicates `users` collection data

### `payments`
- **Purpose**: Stores payment records linked to appointments
- **Document ID**: Firestore auto-generated
- **Fields stored**: `id`, `appointmentId`, `customerId`, `customerName`, `customerPhone`, `customerEmail`, `professionalId`, `professionalName`, `professionalPhone`, `professionalEmail`, `service`, `specialty`, `appointmentDate`, `appointmentTime`, `appointmentDurationMinutes`, `amount`, `currency`, `method`, `status`, `receiptGenerated`
- **Indexes needed**:
  - Compound: `professionalId` + `appointmentDate` (for `getPaymentsByProfessionalInRange` range query)
  - Single field: `professionalId` (for `getPaymentsByProfessional`)
  - Single field: `appointmentId` (for `getPaymentByAppointment`)
  - Single field: `status` (for future status filtering)
- **Concern**: Significant data duplication — stores user details and appointment details that exist in other collections

### `notifications`
- **Purpose**: Stores user-facing notifications
- **Document ID**: Firestore auto-generated
- **Fields stored**: `id`, `type`, `title`, `message`, `appointmentId`, `receiverId`, `senderId`, `status`, `createdAt`
- **Indexes needed**:
  - Compound: `receiverId` + `createdAt` (for `getNotificationsForUser` ordered query)
  - Compound: `receiverId` + `status` (for `markAllAsRead` batch query)
- **Concern**: Notifications collection will grow indefinitely — no TTL or archival strategy

## Documents

### User Documents
- One document per registered user
- Keyed by Firebase Auth UID
- Required for auth to work — a missing Firestore profile triggers first-login flow
- Professionals have additional fields: `specialty`, `workStartTime`, `workEndTime`, `slotDurationMinutes`

### Appointment Documents
- One document per booking
- Keyed by Firestore auto-ID
- Contains both parties' user data (denormalized)
- Status progression: `pending` → `confirmed` → `completed` (or `cancelled` at any point)

### Payment Documents
- One document per payment
- Keyed by Firestore auto-ID
- Linked to appointment via `appointmentId`
- Linked to both user profiles via IDs + denormalized fields

### Notification Documents
- One document per notification event
- Keyed by Firestore auto-ID
- Targeted to a single user via `receiverId`
- Has a `status` field for tracking read state

## Relationships

```
User (1) ──── (N) Appointment (as customerId → users)
User (1) ──── (N) Appointment (as professionalId → users)
Appointment (1) ──── (1) Payment (via appointmentId → paymentId)
User (1) ──── (N) Payment (as customerId → users)
User (1) ──── (N) Payment (as professionalId → users)
User (1) ──── (N) Notification (as receiverId → users)
User (1) ──── (N) Notification (as senderId → users)
Appointment (N) ──── (1) Appointment (via appointmentId)
```

### Relationship Notes
- **Appointment → User (customer)**: FK-like reference via `customerId`, but customer data is also denormalized into the appointment document
- **Appointment → User (professional)**: FK-like reference via `professionalId`, but professional data is also denormalized
- **Payment → Appointment**: FK-like reference via `appointmentId`, but payment also stores a snapshot of appointment service details
- **Payment → User**: FK-like references via `customerId`/`professionalId`, with denormalized copies of user data
- **Notification → User**: Directed relationship via `receiverId` (target user) and `senderId` (source user)

## Read Operations

| Operation | Collection | Query | Frequency |
|---|---|---|---|
| `getUserById` | `users` | Single doc by ID | Every login, profile load, first-login check |
| `isEmailTaken` | `users` | `where('email', ...)` | Every registration and profile email update |
| `getProfessionalsBySpecialty` | `users` | `where('role', ...).where('specialty', ...)` | Every booking step 1 (professional picker load) |
| `getAppointments` | `appointments` | Full collection scan | Every home screen visit, every CRUD operation |
| `getAppointmentsByStatus` | `appointments` | `where('status', ...)` | Analytics queries |
| `getPastAppointments` | `appointments` | `where('dateTime', < now)` | Past appointments page |
| `getPaymentByAppointment` | `payments` | `where('appointmentId', ...)` | Receipt generation |
| `getPaymentsByProfessional` | `payments` | `where('professionalId', ...)` | Earnings page, analytics |
| `getPaymentsByProfessionalInRange` | `payments` | `where('professionalId', ...)` + `where('appointmentDate', range)` | Earnings page with date range |
| `getNotificationsForUser` | `notifications` | `where('receiverId', ...)` | Notifications page load |
| `markAllAsRead` | `notifications` | `where('receiverId', ...).where('status', ...)` | Batch mark-as-read action |
| `syncUserInAppointments` | `appointments` | Two `where` queries + batch write | Every profile update for professionals |

## Write Operations

| Operation | Collection | Write Type | Frequency |
|---|---|---|---|
| `insertUser` | `users` | `set()` (create) | Registration, first-login profile completion |
| `updateUser` | `users` | `update()` | Profile edits |
| `insertAppointment` | `appointments` | `set()` (create) | Booking confirmation |
| `updateAppointment` | `appointments` | `update()` | Reschedule, status change, payment link |
| `deleteAppointment` | `appointments` | `delete()` | Cancel appointment |
| `recordPayment` | `payments` | `set()` (create) | Payment recording |
| `updatePayment` | `payments` | `update()` | Payment edit |
| `updatePaymentStatus` | `payments` | `update()` (single field) | Payment status change |
| `sendNotification` | `notifications` | `set()` (create) | Booking events (not currently triggered by UI) |
| `markAsRead` | `notifications` | `update()` (single field) | Notification tap |
| `markAllAsRead` | `notifications` | `batch.update()` | Batch mark-as-read |
| `syncUserInAppointments` | `appointments` | `batch.update()` (multiple docs) | Every professional profile update |

### Write Concerns
- **`syncUserInAppointments()` is a write hotspot**: Every profile update for a professional triggers a collection scan of all appointments (both as customer and professional) and a batch write to potentially hundreds of documents. This is expensive and creates contention.
- **`getAppointments()` does a full collection scan**: Every operation that loads appointments reads the entire collection, which scales poorly.

## Potential Indexing Needs

1. **`users` collection**:
   - `role` + `specialty` compound index (for `getProfessionalsBySpecialty`)
   - `email` field index (for `isEmailTaken` uniqueness check)

2. **`appointments` collection**:
   - `status` field index (for `getAppointmentsByStatus`)
   - `dateTime` range index (for `getPastAppointments`)
   - `professionalId` + `dateTime` compound index (for slot availability and professional queries)
   - `customerId` + `dateTime` compound index (for user-specific past/future queries)
   - `customerId` composite index (for `syncUserInAppointments` query)
   - `professionalId` composite index (for `syncUserInAppointments` query)

3. **`payments` collection**:
   - `professionalId` + `appointmentDate` composite index (for `getPaymentsByProfessionalInRange`)
   - `appointmentId` field index (for `getPaymentByAppointment`)
   - `professionalId` field index (for `getPaymentsByProfessional`)

4. **`notifications` collection**:
   - `receiverId` + `createdAt` descending composite index (for `getNotificationsForUser`)
   - `receiverId` + `status` composite index (for `markAllAsRead` batch query)

## Potential Security Concerns

1. **No client-side security rules documented**: Audit assumes Firestore security rules are configured, but the codebase does not include them. All data is accessible by any authenticated user with a valid Firestore reference.

2. **Full collection scans expose all data**: Endpoints like `getAppointments()` and `getProfessionalsBySpecialty()` return all documents in the collection. Without Firestore security rules, any authenticated user could read all appointments or all user profiles.

3. **User data in payments and appointments**: Payment documents and appointment documents contain full copies of user contact data (name, phone, email). If a user queries documents they don't "own," they could access other users' PII.

4. **No user ID-based security rules enforced in code**: The repository layer does not filter by `userId` — it relies on Firestore security rules to enforce access control. If rules are misconfigured, data exposure is possible.

5. **`updateUser` allows overwriting any user field**: The repository's `updateUser` method passes the entire `toMap()` output to Firestore without server-side field-level validation. A malicious client could modify fields like `role`.

6. **No server-side timestamps**: Documents use client-side `DateTime.now()` for creation timestamps, which can be spoofed. Consider using Firestore server timestamps for audit fields.

7. **Notification writes are not authenticated**: `sendNotification()` doesn't verify that the caller is the sender — any authenticated user could inject notifications for any user.