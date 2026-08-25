# Security Audit Report

**Date**: 2026-08-25
**Scope**: Firestore security rules, tenant isolation, privilege escalation
**Status**: Complete

---

## Executive Summary

This audit identified **7 critical security gaps** in Firestore rules that must be addressed before multi-tenant launch. The current rules provide basic tenant isolation but have dangerous bypass conditions and over-permissive access patterns.

| Severity | Count | Description |
|----------|-------|-------------|
| Critical | 3 | Immediate risk of data exposure or privilege escalation |
| High | 3 | Significant isolation gaps |
| Medium | 1 | Defense-in-depth improvements needed |

---

## Critical Findings

### SEC-001: `isBusinessMatch` Null/Empty Bypass

**Location**: `firestore.rules:12-14`

**Current rule**:
```javascript
function isBusinessMatch(bizId) {
  return bizId == null || bizId == '' || (isSignedIn() && (resource == null || resource.data.businessId == null || resource.data.businessId == '' || resource.data.businessId == bizId));
}
```

**Issue**: The `bizId == null || bizId == ''` condition allows ANY authenticated user to write documents with null/empty businessId, potentially bypassing tenant isolation.

**Attack scenario**:
1. Attacker authenticates with Tenant A credentials
2. Writes appointment with `businessId: null`
3. Document becomes readable by anyone who knows the null bypass pattern
4. Tenant B data could be inferred or corrupted

**Fix**:
```javascript
function isBusinessMatch(bizId) {
  return isSignedIn() && 
    bizId != null && 
    bizId != '' && 
    (resource == null || resource.data.businessId == null || resource.data.businessId == '' || resource.data.businessId == bizId);
}
```

**Risk**: Critical — undermines entire tenant isolation model

---

### SEC-002: Users Collection Readable by Any Authenticated User

**Location**: `firestore.rules:17`

**Current rule**:
```javascript
allow read: if isOwner(userId) || isSignedIn();
```

**Issue**: Any authenticated user can read ALL user profiles across all tenants. This exposes:
- Email addresses
- Phone numbers
- Role assignments
- Business associations
- Schedule information

**Attack scenario**:
1. Attacker creates account in Tenant A
2. Queries `users` collection
3. Harvests all user data from Tenant B, C, D...
4. Builds target list for social engineering

**Fix**:
```javascript
allow read: if isOwner(userId) || isBusinessMember(userId) || isSuperAdmin();
```

With new helper:
```javascript
function isBusinessMember(userId) {
  return isSignedIn() && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.businessId == 
    get(/databases/$(database)/documents/users/$(userId)).data.businessId;
}

function isSuperAdmin() {
  return isSignedIn() && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
}
```

**Risk**: Critical — GDPR/privacy violation, competitive intelligence exposure

---

### SEC-003: Notifications Creatable by Anyone

**Location**: `firestore.rules:41`

**Current rule**:
```javascript
allow create: if isSignedIn();
```

**Issue**: Any authenticated user can create notifications for ANY receiverId. This enables:
- Spam notifications to users
- Notification-based phishing attacks
- Potential for denial-of-service via notification flooding

**Attack scenario**:
1. Attacker authenticates
2. Creates 10,000 notifications targeting a specific user
3. Victim's notification stream becomes unusable
4. Could mask legitimate booking notifications

**Fix**:
```javascript
allow create: if isSignedIn() && (
  resource == null || // New document
  request.auth.uid == request.resource.data.senderId
);
```

And ensure receiverId is validated server-side (future Cloud Function).

**Risk**: High — abuse vector, though not data exposure

---

## High Findings

### SEC-004: Businesses Collection Publicly Readable

**Location**: `firestore.rules:45`

**Current rule**:
```javascript
allow read: if true;
```

**Issue**: Business names, emails, phone numbers, and addresses are publicly visible without authentication. While some data might need to be public (for booking pages), owner emails and internal data should be protected.

**Fix**:
```javascript
// Public fields for customer-facing booking
allow get: if true; // Single document read for booking page
allow list: if isSignedIn(); // Query only for authenticated users

// Write restricted to owner
allow create: if isSignedIn() && request.resource.data.ownerId == request.auth.uid;
allow update: if isSignedIn() && resource.data.ownerId == request.auth.uid;
allow delete: if isSignedIn() && resource.data.ownerId == request.auth.uid;
```

**Risk**: Medium — data exposure, but limited to business directory

---

### SEC-005: No Role Escalation Protection in Rules

**Location**: `firestore.rules:19`

**Current rule**:
```javascript
allow update: if isOwner(userId) && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['role']));
}

**Issue**: While role change is blocked, there's no server-side role verification for operations. A user could potentially:
- Write to business documents if they know the businessId
- Access admin functions by manipulating client-side state

**Fix**:
Add role-based helper functions:
```javascript
function getUserRole() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
}

function isRole(role) {
  return isSignedIn() && getUserRole() == role;
}

function isAtLeastRole(role) {
  final userRole = getUserRole();
  final hierarchy = ['customer', 'professional', 'business_admin', 'super_admin'];
  final userIndex = hierarchy.indexOf(userRole);
  final requiredIndex = hierarchy.indexOf(role);
  return userIndex >= requiredIndex;
}
```

**Risk**: High — privilege escalation potential

---

### SEC-006: No Field-Level Restrictions on Sensitive Data

**Location**: `firestore.rules:17-19`

**Current rule**: Users can update all fields except role.

**Issue**: No restriction on:
- `businessId` changes (could move user to different tenant)
- `specialty` changes (could impersonate different professional type)
- Other sensitive fields

**Fix**:
```javascript
allow update: if isOwner(userId) && 
  (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'businessId']));
```

**Risk**: Medium — field manipulation

---

## Medium Findings

### SEC-007: No Audit Trail in Rules

**Location**: Global

**Issue**: No logging of security-relevant operations. Cannot detect or investigate:
- Failed access attempts
- Unusual query patterns
- Data exfiltration attempts

**Fix**: Implement Cloud Functions audit logging:
```javascript
// Future: Cloud Function trigger on writes
exports.auditLog = functions.firestore
  .document('{collection}/{docId}')
  .onWrite((change, context) => {
    // Log to audit collection
  });
```

**Risk**: Medium — operational visibility

---

## Proposed Revised Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function getCurrentUser() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid));
    }
    
    function getCurrentUserRole() {
      return getCurrentUser().data.role;
    }
    
    function isSuperAdmin() {
      return isSignedIn() && getCurrentUserRole() == 'super_admin';
    }
    
    function isBusinessAdmin() {
      return isSignedIn() && getCurrentUserRole() == 'business_admin';
    }
    
    function isProfessional() {
      return isSignedIn() && getCurrentUserRole() == 'professional';
    }
    
    function isCustomer() {
      return isSignedIn() && getCurrentUserRole() == 'customer';
    }
    
    function getCurrentUserBusinessId() {
      return getCurrentUser().data.businessId;
    }
    
    function isBusinessMatch(bizId) {
      return isSignedIn() && 
        bizId != null && 
        bizId != '' && 
        bizId == getCurrentUserBusinessId();
    }
    
    function isSameBusiness(userId) {
      return isSignedIn() && 
        get(/databases/$(database)/documents/users/$(userId)).data.businessId == 
        getCurrentUserBusinessId();
    }
    
    function isBusinessMember(userId) {
      return isOwner(userId) || isSameBusiness(userId);
    }

    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId) || isSameBusiness(userId) || isSuperAdmin();
      allow create: if isOwner(userId) && request.resource.data.role == 'customer';
      allow update: if (isOwner(userId) || isSuperAdmin()) && 
        (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'businessId']));
      allow delete: if isSuperAdmin();
    }
    
    // Services collection
    match /services/{serviceId} {
      allow read: if isSignedIn();
      allow create, update, delete: if isBusinessAdmin() || isSuperAdmin();
    }
    
    // Appointments collection
    match /appointments/{appointmentId} {
      allow get: if isOwner(resource.data.customerId) || 
                    isOwner(resource.data.professionalId) || 
                    isBusinessMatch(resource.data.businessId) ||
                    isSuperAdmin();
      allow list: if isSignedIn() && (
        request.query.filters.businessId == getCurrentUserBusinessId() ||
        isSuperAdmin()
      );
      allow create: if isSignedIn() && 
        request.resource.data.customerId != null && 
        request.resource.data.professionalId != null && 
        request.resource.data.dateTime != null && 
        request.resource.data.service != null &&
        request.resource.data.businessId == getCurrentUserBusinessId();
      allow update: if (isOwner(resource.data.customerId) || 
                    isOwner(resource.data.professionalId) || 
                    isBusinessMatch(resource.data.businessId) ||
                    isSuperAdmin());
      allow delete: if isBusinessAdmin() || isSuperAdmin();
    }
    
    // Payments collection
    match /payments/{paymentId} {
      allow read: if isOwner(resource.data.customerId) || 
                    isOwner(resource.data.professionalId) || 
                    isBusinessMatch(resource.data.businessId) ||
                    isSuperAdmin();
      allow create: if isSignedIn() && 
        request.resource.data.professionalId == request.auth.uid;
      allow update: if isOwner(resource.data.professionalId) || 
                    isBusinessMatch(resource.data.businessId) ||
                    isSuperAdmin();
      allow delete: if isBusinessAdmin() || isSuperAdmin();
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.receiverId) || isSuperAdmin();
      allow create: if isSignedIn() && 
        request.resource.data.senderId == request.auth.uid;
      allow update: if isOwner(resource.data.receiverId) || isSuperAdmin();
      allow delete: if isSuperAdmin();
    }
    
    // Businesses collection
    match /businesses/{businessId} {
      allow get: if true; // Public read for booking page
      allow list: if isSuperAdmin(); // Only super admin can list all
      allow create: if isSuperAdmin();
      allow update: if isBusinessAdmin() && resource.data.ownerId == request.auth.uid || isSuperAdmin();
      allow delete: if isSuperAdmin();
    }
  }
}
```

---

## Cross-Tenant Isolation Test Plan

### Test 1: Tenant A cannot read Tenant B appointments
```dart
test('Tenant A cannot read Tenant B appointments', () async {
  // Setup: Create appointments for Tenant B
  // Action: Query appointments as Tenant A user
  // Expect: Empty result or permission denied
});
```

### Test 2: Tenant A cannot read Tenant B users
```dart
test('Tenant A cannot read Tenant B users', () async {
  // Setup: Create users in Tenant B
  // Action: Query users collection as Tenant A user
  // Expect: Only Tenant A users returned
});
```

### Test 3: Tenant A cannot read Tenant B businesses
```dart
test('Tenant A cannot read Tenant B businesses', () async {
  // Setup: Create businesses for Tenant B
  // Action: Query businesses as Tenant A user
  // Expect: Only Tenant A business returned (or public fields only)
});
```

### Test 4: Tenant A cannot infer Tenant B data via queries
```dart
test('Tenant A cannot infer Tenant B data via queries', () async {
  // Setup: Create appointments for Tenant B
  // Action: Attempt queries with various filters as Tenant A
  // Expect: No Tenant B data in any response
});
```

---

## Privilege Escalation Test Plan

### Test 1: Customer cannot write as professional
```dart
test('Customer cannot write as professional', () async {
  // Setup: Authenticate as customer
  // Action: Attempt to create appointment with professionalId != self
  // Expect: Permission denied
});
```

### Test 2: Professional cannot write as business_admin
```dart
test('Professional cannot write as business_admin', () async {
  // Setup: Authenticate as professional
  // Action: Attempt to update business settings
  // Expect: Permission denied
});
```

### Test 3: Business Admin cannot write as super_admin
```dart
test('Business Admin cannot write as super_admin', () async {
  // Setup: Authenticate as business_admin
  // Action: Attempt to create new business
  // Expect: Permission denied
});
```

### Test 4: Client-side role manipulation fails server-side
```dart
test('Client-side role manipulation fails server-side', () async {
  // Setup: Authenticate as customer
  // Action: Attempt to update role field in user document
  // Expect: Permission denied
});
```

---

## Implementation Priority

### Immediate (Sprint 1)
1. Fix `isBusinessMatch` null/empty bypass
2. Restrict users collection reads
3. Restrict notification creation

### Short-term (Sprint 2)
4. Restrict businesses collection list
5. Add role verification helpers
6. Add field-level restrictions

### Medium-term (Sprint 3+)
7. Implement audit logging
8. Add rate limiting
9. Implement query complexity limits

---

## Deployment Checklist

- [ ] Test all rules in Firebase Emulator Suite
- [ ] Run existing test suite against emulator
- [ ] Deploy to staging project first
- [ ] Verify production functionality
- [ ] Monitor error logs for permission-denied errors
- [ ] Have rollback plan ready (git revert + redeploy)

---

*Audit complete. Revised rules provided. Test plan documented. Deployment checklist included.*
