# Firestore Security Audit

## Current State

**No Firestore security rules exist in the repository.**

- No `firestore.rules` file
- No `firestore.indexes.json` file
- No `firestore` key in `firebase.json`
- No security rules in any version-controlled configuration file

The application relies entirely on the default Firestore rules, which during development grant all authenticated users read/write access to all documents. The `firebase.json` file only contains Flutter platform configuration (Android app ID, Dart firebase_options) with no Firestore or security configuration.

### Current Firebase Configuration

```json
{
  "flutter": {
    "platforms": {
      "android": { ... },
      "dart": { "lib/firebase_options.dart": { ... } }
    }
  }
}
```

No Firestore rules, indexes, or security configuration is present.

### Production Implications

| Concern | Status |
|---|---|
| Rules version-controlled in repo | ❌ Missing |
| Access control enforced server-side | ❌ Missing |
| Per-collection read/write restrictions | ❌ Missing |
| Per-user data isolation | ❌ Missing |
| Indexes version-controlled in repo | ❌ Missing |
| Automated rule deployment in CI/CD | ❌ Missing |

---

## Required Access Model

### Users Collection (`users`)

| Operation | Who | Condition |
|---|---|---|
| **Read** | User themselves | `request.auth.uid == resource.id` |
| **Read** | Any user (for professional lookup) | `resource.data.role == 'professional'` |
| **Write** | User themselves (profile creation) | `request.auth.uid == request.resource.data.id` |
| **Write** | User themselves (profile update) | `request.auth.uid == request.resource.id` |
| **Create** | Any authenticated user | First-login profile completion |
| **Update** | User themselves only | Must match `request.auth.uid` |

**Special case**: `getUserById()` is called by `AuthProvider` during login, session restoration, and profile completion. This means users need to be able to read *other* users' profiles in limited circumstances (e.g., to display a professional's name and schedule during booking). The access model below addresses this.

**Recommended read rule**: Allow any authenticated user to read user documents, but restrict updates to the document owner.

### Appointments Collection (`appointments`)

| Operation | Who | Condition |
|---|---|---|
| **Create** | Authenticated user (as customer) | `request.auth.uid == request.resource.data.customerId` |
| **Read** | Customer for own appointments | `request.auth.uid == resource.data.customerId` |
| **Read** | Professional for own appointments | `request.auth.uid == resource.data.professionalId` |
| **Read** | Any authenticated user (booking flow) | Limited to professional discovery queries |
| **Update** | Customer (reschedule, cancel) | `request.auth.uid == resource.data.customerId` |
| **Update** | Professional (confirm, complete) | `request.auth.uid == resource.data.professionalId` |
| **Delete** (cancel) | Customer or professional | `request.auth.uid in [resource.data.customerId, resource.data.professionalId]` |

**Note**: The current `Appointment` model stores denormalized copies of both customer and professional data (name, phone, email). This is not a security concern for rules but means that any user with an appointment ID could theoretically read full contact data if rules are too permissive.

### Payments Collection (`payments`)

| Operation | Who | Condition |
|---|---|---|
| **Create** | Professional (recording payment) | `request.auth.uid == request.resource.data.professionalId` |
| **Read** | Customer for own appointments | `request.auth.uid == resource.data.customerId` |
| **Read** | Professional for own appointments | `request.auth.uid == resource.data.professionalId` |
| **Update** | Professional (status change) | `request.auth.uid == resource.data.professionalId` |
| **Delete** | Professional only | `request.auth.uid == resource.data.professionalId` |

**Note**: Payments contain denormalized copies of user contact data. Rules should prevent customers from creating or modifying payments — only professionals should record payments.

### Notifications Collection (`notifications`)

| Operation | Who | Condition |
|---|---|---|
| **Create** | Server-side only (no client writes) | `request.resource.data.receiverId != request.auth.uid` |
| **Read** | Receiver only | `request.auth.uid == resource.data.receiverId` |
| **Update** | Receiver only (mark as read) | `request.auth.uid == resource.data.receiverId` |
| **Delete** | Receiver only | `request.auth.uid == resource.data.receiverId` |

**Note**: Notifications should never be created by client-side code. The `sendNotification()` method in `FirestoreNotificationRepository` is a client-side write, which is a security concern. Rule implementation should restrict notification creation to server-side (Cloud Functions) or the `request.resource.data` should not allow arbitrary `senderId` spoofing.

---

## Security Risks

### SEC-001

**Description**: No Firestore security rules exist. All authenticated users can read and write all documents in every collection. This means any user can:
- Read all user profiles (names, emails, phone numbers)
- Read all appointments (including other users' bookings)
- Read and modify all payment records (including amounts and methods)
- Create, modify, or delete notifications for any user
- Create appointments impersonating other users

**Severity**: Critical

**Recommendation**: Implement security rules immediately before any further production use. Rules should enforce per-user data isolation and role-based write permissions.

---

### SEC-002

**Description**: `getAppointments()` reads the entire `appointments` collection with no server-side filtering or access control. Combined with missing rules, any authenticated user can download every appointment in the database. Even with rules in place, the current repository pattern does not pass the user ID to Firestore queries, so the app itself fetches data it should not need.

**Severity**: Critical

**Recommendation**: Add security rules that restrict `appointments` reads to the authenticated user's own document IDs (`customerId == request.auth.uid` or `professionalId == request.auth.uid`). Simultaneously, update `getAppointments()` calls to filter by user ID server-side.

---

### SEC-003

**Description**: `getProfessionalsBySpecialty()` queries all `users` documents where `role == 'professional'`. With no rules, any authenticated user can download all professional profiles including names, emails, and phone numbers. This is a PII exposure risk.

**Severity**: High

**Recommendation**: Allow any authenticated user to read professional profiles (necessary for booking), but restrict reads of `customer` role profiles to the document owner only.

---

### SEC-004

**Description**: `Appointment` and `Payment` documents contain denormalized copies of user contact data (name, phone, email for both customer and professional). If rules are too permissive or if a user gains access to an appointment document they do not own, their PII (and the PII of both parties) is exposed.

**Severity**: High

**Recommendation**: Either remove denormalized user data from appointments and payments, or add rules that ensure users can only read documents where they are a participant (customerId, professionalId, or receiverId for notifications). Ensure rules validate that `customerId`, `professionalId`, and `receiverId` match `request.auth.uid` for read operations.

---

### SEC-005

**Description**: `sendNotification()` in `FirestoreNotificationRepository` is a client-side write with no server-side validation. Any authenticated user could theoretically craft and send notifications to any other user, including spoofing the `senderId` field or sending fraudulent notification content.

**Severity**: High

**Recommendation**: Restrict notification document creation so that `receiverId` must differ from `senderId`, and ideally move notification creation to Cloud Functions triggered by booking events rather than allowing client-side writes.

---

### SEC-006

**Description**: `updateUser()` writes the entire `toMap()` output without any server-side validation. A malicious client could modify fields they should not have access to (e.g., changing `role` from `customer` to `professional`, or tampering with `specialty`).

**Severity**: High

**Recommendation**: Rules should validate that on update:
- `role` field is immutable after creation
- `id` field matches `request.auth.uid`
- `email` changes require re-authentication (handled at the app level, but rules can enforce immutable fields)
- `specialty` can only be set for `professional` role

---

### SEC-007

**Description**: `syncUserInAppointments()` in `FirestoreBookingRepository` performs batch writes to potentially thousands of appointment documents on every profile update. With permissive rules, this is not exploitable. With restrictive rules (as recommended), this batch write could fail if the user is both the customer and professional on different appointments, because the rule evaluation may not account for the batch context correctly.

**Severity**: Medium

**Recommendation**: Test security rules against the `syncUserInAppointments()` batch write pattern to ensure rules handle batch operations correctly. Consider whether `syncUserInAppointments()` is necessary or if contact data should be looked up at read time instead of stored denormalized.

---

### SEC-008

**Description**: `getPaymentsByProfessionalInRange()` uses compound queries with `professionalId` and `appointmentDate` range filters. If rules restrict payment reads to the owner, the query must include the owner's ID as a filter clause. The current repository code already includes `professionalId` in the query, but payment records include both `customerId` and `professionalId`, so rules must be precise to avoid blocking valid queries.

**Severity**: Medium

**Recommendation**: Ensure Firestore rules for `payments` allow reads where `customerId == request.auth.uid` OR `professionalId == request.auth.uid`, and that the corresponding queries include the appropriate filter field to satisfy rule evaluation.

---

### SEC-009

**Description**: No Firestore indexes are defined in the repository. Compound queries (e.g., `professionalId + appointmentDate` range for payments, `receiverId + createdAt` for notifications) will fail at runtime without the required composite indexes. While this is not a security vulnerability, it is a reliability risk that could cause runtime query failures.

**Severity**: Medium

**Recommendation**: Add a `firestore.indexes.json` (or equivalent) file to the repository that defines all required composite indexes. This file should be version-controlled and deployed alongside rule changes.

---

### SEC-010

**Description**: The `users` collection uses Firebase Auth UIDs as document IDs. If rules do not validate that `request.auth.uid` matches the document ID for write operations, a user could potentially overwrite another user's profile document. The `insertUser()` method sets `id` to `docRef.id` (the Firestore auto-generated ID), but during first-login profile completion, the document ID is the user's Auth UID. If rules allow writes by any authenticated user, ID field manipulation could be a vector.

**Severity**: Medium

**Recommendation**: Rules should enforce that on create, `resource.data.id == request.auth.uid`, and on update, `request.resource.id == request.auth.uid`. This prevents users from creating documents with other users' IDs or updating documents they don't own.

---

## Proposed Future Rules Structure

### Document: `firestore.rules` (proposed)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ============================================================
    // Helper functions
    // ============================================================

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function isCustomerOrProfessional() {
      return resource.data.role == 'customer' || resource.data.role == 'professional';
    }

    // ============================================================
    // Users Collection
    // ============================================================
    match /users/{userId} {
      // Any authenticated user can read professional profiles
      // (needed for booking - to find professionals by specialty)
      allow read: if isAuthenticated() && (
        isOwner(userId) ||
        resource.data.role == 'professional'
      );

      // Users can create their own profile (first-login completion)
      // Users can update their own profile
      allow write: if isAuthenticated() && (
        // Create: ID must match the requesting user's UID
        (request.resource.id == request.auth.uid &&
         request.resource.data.role in ['customer', 'professional'] &&
         request.resource.data.id == request.auth.uid) ||
        // Update: must own the document
        (request.resource.id == request.auth.uid &&
         request.resource.data.diff(resource.data).affectedKeys()
           .hasOnly(['name', 'email', 'phone', 'specialty',
                     'workStartTime', 'workEndTime', 'slotDurationMinutes']))
      );

      // Prevent role escalation
      allow write: if isAuthenticated() && isOwner(userId) &&
        resource.data.role == request.resource.data.role;
    }

    // ============================================================
    // Appointments Collection
    // ============================================================
    match /appointments/{appointmentId} {
      allow read: if isAuthenticated() && (
        isOwner(resource.data.customerId) ||
        isOwner(resource.data.professionalId)
      );

      allow create: if isAuthenticated() &&
        request.resource.data.customerId == request.auth.uid &&
        request.resource.data.customerId is string &&
        request.resource.data.professionalId is string &&
        request.resource.data.service is string &&
        request.resource.data.dateTime is timestamp &&
        request.resource.data.status in ['pending', 'confirmed', 'completed', 'cancelled'];

      allow update: if isAuthenticated() && (
        // Customer can update their own appointments
        (isOwner(resource.data.customerId) &&
         request.resource.data.customerId == resource.data.customerId) ||
        // Professional can update their own appointments
        (isOwner(resource.data.professionalId) &&
         request.resource.data.professionalId == resource.data.professionalId)
      ) &&
      // Status can only progress forward
      request.resource.data.status in ['pending', 'confirmed', 'completed', 'cancelled'] &&
      // Prevent changing the other party's ID
      request.resource.data.customerId == resource.data.customerId &&
      request.resource.data.professionalId == resource.data.professionalId;

      allow delete: if isAuthenticated() && (
        isOwner(resource.data.customerId) ||
        isOwner(resource.data.professionalId)
      );
    }

    // ============================================================
    // Payments Collection
    // ============================================================
    match /payments/{paymentId} {
      allow read: if isAuthenticated() && (
        isOwner(resource.data.customerId) ||
        isOwner(resource.data.professionalId)
      );

      allow create: if isAuthenticated() &&
        request.resource.data.professionalId == request.auth.uid &&
        request.resource.data.customerId is string &&
        request.resource.data.appointmentId is string &&
        request.resource.data.amount is number &&
        request.resource.data.amount > 0 &&
        request.resource.data.status in ['pending', 'completed', 'refunded'];

      allow update: if isAuthenticated() &&
        isOwner(resource.data.professionalId) &&
        request.resource.data.professionalId == resource.data.professionalId;

      allow delete: if isAuthenticated() &&
        isOwner(resource.data.professionalId);
    }

    // ============================================================
    // Notifications Collection
    // ============================================================
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() &&
        request.auth.uid == resource.data.receiverId;

      // Notifications should only be created server-side (Cloud Functions)
      // Client-side creation is denied by default
      allow create: if false;

      allow update: if isAuthenticated() &&
        request.auth.uid == resource.data.receiverId &&
        request.resource.data.receiverId == resource.data.receiverId &&
        request.resource.data.status in ['unread', 'read', 'dismissed'];

      allow delete: if isAuthenticated() &&
        request.auth.uid == resource.data.receiverId;
    }
  }
}
```

### Document: `firestore.indexes.json` (proposed)

```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "fields": [{"fieldPath": "role", "order": "ASCENDING"}, {"fieldPath": "specialty", "order": "ASCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "users",
      "fields": [{"fieldPath": "email", "order": "ASCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "appointments",
      "fields": [{"fieldPath": "customerId", "order": "ASCENDING"}, {"fieldPath": "dateTime", "order": "DESCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "appointments",
      "fields": [{"fieldPath": "professionalId", "order": "ASCENDING"}, {"fieldPath": "dateTime", "order": "DESCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "appointments",
      "fields": [{"fieldPath": "status", "order": "ASCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "payments",
      "fields": [{"fieldPath": "professionalId", "order": "ASCENDING"}, {"fieldPath": "appointmentDate", "order": "DESCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "payments",
      "fields": [{"fieldPath": "appointmentId", "order": "ASCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "notifications",
      "fields": [{"fieldPath": "receiverId", "order": "ASCENDING"}, {"fieldPath": "createdAt", "order": "DESCENDING"}],
      "queryScope": "COLLECTION"
    },
    {
      "collectionGroup": "notifications",
      "fields": [{"fieldPath": "receiverId", "order": "ASCENDING"}, {"fieldPath": "status", "order": "ASCENDING"}],
      "queryScope": "COLLECTION"
    }
  ]
}
```

### Deployment Process (Recommended)

1. Save `firestore.rules` and `firestore.indexes.json` in the repository root
2. Deploy rules: `firebase deploy --only firestore:rules`
3. Deploy indexes: `firebase deploy --only firestore:indexes`
4. Integrate deployment into CI/CD pipeline so rule changes are reviewed before deployment

### Migration Strategy

The current application assumes no server-side access control. Adding rules will immediately break any client behavior that relies on unconditional read/write access. The migration checklist:

1. **Verify all queries include user ID filters** — `getAppointments()` must be updated to filter by `customerId` or `professionalId` matching `request.auth.uid`
2. **Verify `syncUserInAppointments()` batch writes** — rules must allow the authenticated user to update documents where they are either `customerId` or `professionalId`
3. **Verify notification creation** — `sendNotification()` is currently client-side; rules should deny it, requiring migration to Cloud Functions
4. **Test all query patterns** against the new rules in a staging Firebase project before deploying to production
5. **Deploy rules in audit mode first** — use `firebase firestore:rules:test` with realistic test cases before enforcing
6. **Monitor the Firebase console** for rule denial metrics during the first weeks after deployment