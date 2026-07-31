# Repositories Audit

## BookingRepository (Abstract)

**File**: `lib/repositories/booking_repository.dart` (19 lines)

### Responsibilities
Abstract interface defining all data operations for:
- User profile CRUD (create, read, update, email uniqueness check)
- Appointment CRUD (create, read, update, delete)
- User synchronization in appointments (update patient/professional names across all related appointments)
- Professional discovery by specialty
- Status-filtered appointment queries
- Past appointment queries

### Methods
| Method | Signature | Purpose |
|---|---|---|
| `getUserById` | `(String id) → Future<User?>` | Fetch user profile by Firestore document ID |
| `isEmailTaken` | `(String email, {String? excludeUserId}) → Future<bool>` | Check if email is already registered |
| `insertUser` | `(User user) → Future<int>` | Create or update a user document |
| `updateUser` | `(User user) → Future<int>` | Update user profile |
| `syncUserInAppointments` | `(User user) → Future<void>` | Update user name/phone/email across all related appointments |
| `getProfessionalsBySpecialty` | `(String specialty) → Future<List<User>>` | Find professionals by specialty |
| `getAppointments` | `() → Future<List<Appointment>>` | Load all appointments |
| `insertAppointment` | `(Appointment appointment) → Future<int>` | Create a new appointment |
| `updateAppointment` | `(Appointment appointment) → Future<int>` | Update an existing appointment |
| `deleteAppointment` | `(String id) → Future<int>` | Delete/cancel an appointment |
| `getAppointmentsByStatus` | `(AppointmentStatus status) → Future<List<Appointment>>` | Filter appointments by status |
| `getPastAppointments` | `() → Future<List<Appointment>>` | Load completed/cancelled past appointments |

### Coupling
- Couples **user operations** and **appointment operations** in a single interface, despite these being distinct domain areas. The `BookingRepository` name suggests it should only handle bookings, but it also handles user CRUD.

### Suggested Future Improvements
- Split into `UserRepository` and `BookingRepository` to separate user management from appointment management
- The `syncUserInAppointments()` method creates a write hotspot — consider whether user data should be stored directly in appointments (denormalized) or looked up at read time
- Add pagination parameters to `getAppointments()` and `getProfessionalsBySpecialty()`

---

## FirestoreBookingRepository (Concrete)

**File**: `lib/repositories/firestore_booking_repository.dart` (248 lines)

### Responsibilities
Concrete implementation of `BookingRepository` using Cloud Firestore. Manages two collections:
- `users` — user profiles
- `appointments` — booking records

### Firestore Interaction
- **Collections**: `users`, `appointments`
- **Singleton pattern**: `FirestoreBookingRepository.instance`
- **Document IDs**: Uses Firestore auto-generated IDs for new documents; uses provided IDs for updates

### Query Patterns
| Operation | Query Pattern |
|---|---|
| `getUserById` | `_usersCol.doc(id).get()` — single document read |
| `isEmailTaken` | `_usersCol.where('email', isEqualTo: email).get()` — collection query |
| `insertUser` | `_usersCol.doc(id).set(data)` — single document write |
| `updateUser` | `_usersCol.doc(id).update(data)` — single document update |
| `syncUserInAppointments` | Two `where` queries + batch write — collection query + batch update |
| `getProfessionalsBySpecialty` | `_usersCol.where('role', isEqualTo: 'professional').where('specialty', isEqualTo: specialty).get()` — compound query |
| `getAppointments` | `_appointmentsCol.get()` — full collection scan |
| `insertAppointment` | `_appointmentsCol.doc(id).set(data)` — single document write |
| `updateAppointment` | `_appointmentsCol.doc(id).update(data)` — single document update |
| `deleteAppointment` | `_appointmentsCol.doc(id).delete()` — single document delete |
| `getAppointmentsByStatus` | `_appointmentsCol.where('status', isEqualTo: status.name).get()` — collection query |
| `getPastAppointments` | `_appointmentsCol.where('dateTime', isLessThan: now).get()` — range query |

### Coupling
- Tightly coupled to `FirebaseFirestore` and the `users` + `appointments` collection structure
- The `fromMap()`/`toMap()` patterns in models tightly couple data shape to Firestore document structure
- `appointment.toMap()` in `insertAppointment` writes the `id` field to Firestore, which is typically redundant since Firestore uses the document ID

### Suggested Future Improvements
- Add indexes for compound queries (`role` + `specialty`, `dateTime` range queries)
- Add pagination (limit + cursor) for `getAppointments()` and `getProfessionalsBySpecialty()`
- Consider using Firestore subcollection pattern for appointments under users
- Remove redundant `id` field from `toMap()` output (Firestore documents already have an ID)
- Use Firestore `DocumentReference` instead of storing ID strings in documents

---

## PaymentRepository (Abstract)

**File**: `lib/repositories/payment_repository.dart` (14 lines)

### Responsibilities
Abstract interface for payment data operations:
- Fetch payment by appointment ID
- Fetch payments for a professional (all or date-range filtered)
- Record a new payment
- Update payment details
- Update payment status only

### Methods
| Method | Signature | Purpose |
|---|---|---|
| `getPaymentByAppointment` | `(String appointmentId) → Future<Payment?>` | Find payment linked to an appointment |
| `getPaymentsByProfessional` | `(String professionalId) → Future<List<Payment>>` | Load all payments for a professional |
| `getPaymentsByProfessionalInRange` | `(String professionalId, DateTime start, DateTime end) → Future<List<Payment>>` | Load payments within a date range |
| `recordPayment` | `(Payment payment) → Future<int>` | Save a new payment |
| `updatePayment` | `(Payment payment) → Future<int>` | Update payment details |
| `updatePaymentStatus` | `(String paymentId, PaymentStatus status) → Future<int>` | Update only the status field |

### Coupling
- Clean separation from booking/appointment logic
- Methods are appropriately scoped for payment operations

### Suggested Future Improvements
- Add method to fetch payments by customer ID
- Add method to get revenue statistics directly from the repository (rather than computing client-side)

---

## FirestorePaymentRepository (Concrete)

**File**: `lib/repositories/firestore_payment_repository.dart` (135 lines)

### Responsibilities
Concrete implementation of `PaymentRepository` using Cloud Firestore. Manages the `payments` collection.

### Firestore Interaction
- **Collection**: `payments`
- **Singleton pattern**: `FirestorePaymentRepository.instance`

### Query Patterns
| Operation | Query Pattern |
|---|---|
| `getPaymentByAppointment` | `_paymentsCol.where('appointmentId', isEqualTo: appointmentId).limit(1).get()` — collection query |
| `getPaymentsByProfessional` | `_paymentsCol.where('professionalId', isEqualTo: professionalId).get()` — collection query |
| `getPaymentsByProfessionalInRange` | `_paymentsCol.where('professionalId', ...).where('appointmentDate', >= start).where('appointmentDate', < end).get()` — compound query with range |
| `recordPayment` | `_paymentsCol.doc(id).set(data)` — single document write |
| `updatePayment` | `_paymentsCol.doc(id).update(data)` — single document update |
| `updatePaymentStatus` | `_paymentsCol.doc(id).update({'status': status.name})` — single field update |

### Coupling
- Tightly coupled to the `payments` collection schema
- Stores redundant user data (`customerName`, `customerPhone`, `customerEmail`, `professionalName`, `professionalPhone`, `professionalEmail`) alongside user IDs, creating data duplication that must be managed

### Suggested Future Improvements
- Add composite index for `professionalId` + `appointmentDate` range query
- Consider removing redundant user fields from payment documents if they can be looked up from user profiles
- Add method to query payments by customer ID

---

## NotificationRepository (Abstract + Implementation)

**File**: `lib/repositories/notification_repository.dart` (102 lines)

### Responsibilities
Abstract interface and Firestore implementation combined in a single file for notification data operations:
- Send notifications
- Fetch notifications for a user
- Mark notifications as read (individual and batch)
- Stream real-time notification updates

### Methods (Abstract)
| Method | Signature | Purpose |
|---|---|---|
| `sendNotification` | `(AppNotification notification) → Future<void>` | Persist a new notification |
| `getNotificationsForUser` | `(String userId) → Future<List<AppNotification>>` | Load notifications for a user |
| `markAsRead` | `(String notificationId) → Future<int>` | Mark a notification as read |
| `markAllAsRead` | `(String userId) → Future<int>` | Batch-mark all unread notifications for a user |
| `getNotificationsStream` | `(String userId) → Stream<QuerySnapshot>` | Real-time stream of notifications |

### Firestore Interaction
- **Collection**: `notifications`
- **Singleton pattern**: `FirestoreNotificationRepository.instance`

### Query Patterns
| Operation | Query Pattern |
|---|---|
| `sendNotification` | `_notificationsCol.doc().set(data)` — auto-ID document write |
| `getNotificationsForUser` | `_notificationsCol.where('receiverId', isEqualTo: userId).orderBy('createdAt', descending: true).get()` — filtered query |
| `markAsRead` | `_notificationsCol.doc(id).update({'status': 'read'})` — single field update |
| `markAllAsRead` | `_notificationsCol.where('receiverId', isEqualTo: userId).where('status', isEqualTo: 'unread').get()` + batch update — filtered query + batch write |
| `getNotificationsStream` | `_notificationsCol.where('receiverId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots()` — real-time listener |

### Coupling
- Coupled to the `notifications` collection schema
- The `receiverId` field is used for all user-scoped queries

### Suggested Future Improvements
- The file combines abstract interface and concrete implementation, unlike the other repositories which separate them
- Consider splitting into `NotificationRepository` (abstract) and `FirestoreNotificationRepository` (concrete) for consistency
- The `getNotificationsStream()` is defined but never consumed by the UI — either integrate it into `NotificationProvider` or remove it
- Consider adding TTL (time-to-live) for notifications to manage collection growth