# RestoraHub — User Registration & Login Work Instructions

**Audience**: Operators, super admins, and new business owners  
**Purpose**: Explain how each user type enters the system, what happens in the background, and why an “owner email” on a business does not automatically create a login account.

---

## 1. User Types at a Glance

| Role | Where it lives | Can log in? | How it is created |
|------|---------------|-------------|-------------------|
| `customer` | Firestore `/users/{uid}` + Firebase Auth | Yes | Self-registration via the app |
| `professional` | Firestore `/users/{uid}` + Firebase Auth | Yes | Self-registration via the app |
| `business_admin` | Firestore `/users/{uid}` + Firebase Auth | Yes (but not auto-created) | Created by super admin / existing user role change |
| `super_admin` | Firestore `/users/{uid}` + Firebase Auth | Yes | Created manually in Firebase Console or via Firestore document |

> **Important distinction**: The system uses **two** data stores:
> 1. **Firebase Authentication** — stores email, password hash, and a UID. This is what you use to log in.
> 2. **Cloud Firestore** — stores the user profile (`/users/{uid}`) with role, name, phone, businessId, etc.

A person can only log in if they have a Firebase Auth account. A Firestore user document alone is **not** enough to authenticate.

---

## 2. Customer & Professional Registration (Self-Service)

### Flow
1. User opens the app → sees **Login** screen.
2. Taps **“Don’t have an account? Register”**.
3. Fills in:
   - Full name
   - Email
   - Phone
   - Password
   - Account type: **Customer** or **Professional**
   - (Professional only) Select a **Specialty** from the dropdown
4. Taps **Register**.

### What happens in the code
- `AuthProvider.register()` is called (`lib/providers/auth_provider.dart:90`).
- A new Firebase Auth user is created with `createUserWithEmailAndPassword()`.
- Immediately after, a Firestore document is written to `/users/{uid}` with:
  - `id` = Firebase Auth UID
  - `name`, `email`, `phone`
  - `role` = `customer` or `professional`
  - `category` = specialty (if professional)
- If the Firestore write fails, the Firebase Auth user is **deleted** to keep the two stores in sync.
- On success, the user is redirected to their home dashboard.

### Result
The user now has:
- A Firebase Auth login (email + password).
- A Firestore profile with the chosen role.

---

## 3. Login Flow (All Roles)

### Steps
1. User enters email + password on the Login screen.
2. `AuthProvider.login()` signs in with Firebase Auth (`lib/providers/auth_provider.dart:37`).
3. The app fetches the Firestore user document by UID.
4. Three outcomes:
   - **Success** → user profile found → redirect to home.
   - **Needs Profile** (`LoginResult.needsProfile`) → Firebase Auth user exists, but no Firestore profile. The user sees a **“Complete your profile”** dialog and must enter name, phone, and choose a role.
   - **Invalid credentials** → wrong email/password → error message shown.

### First-time profile completion
When a user exists in Firebase Auth but has no Firestore profile, the app shows a dialog (`lib/pages/login_page.dart:160`) asking for:
- Full name
- Phone
- Account type: Customer or Professional
- Specialty (if professional)

This creates the Firestore `/users/{uid}` document and assigns the role.

---

## 4. Super Admin Dashboard — Business Creation

### Where it lives
`lib/pages/super_admin_dashboard_page.dart` → `_openAddBusinessDialog()`

### Steps
1. Super admin opens the **Super Admin Dashboard**.
2. Taps **Add Business**.
3. Fills in:
   - Business Name
   - Business Email
   - Owner Email
   - Phone
   - Address
   - Business Type
4. Taps **Save**.

### What happens in the code
- `SuperAdminProvider.createBusiness()` builds a `Business` object with:
  - `slug` — auto-generated from the business name
  - `status` — `trial`
  - `businessType` — selected value
  - `ownerId` — the **Owner Email** you entered (stored as a raw string)
  - `contactInformation` — address, phone, email
  - `branding` — primary color placeholder
  - `settings` — empty defaults
  - `subscription` — `status: 'trial'`, `startDate: now`
  - `featureEntitlements` — empty list
  - `createdAt`, `updatedAt` — timestamps
- The business is written to Firestore `/businesses/{autoId}`.

### Critical point about Owner Email
The **Owner Email** field is stored as `ownerId` on the business document. It is **only a reference string**. It does **not**:
- Create a Firebase Auth account.
- Create a Firestore user document.
- Assign the `business_admin` role.

This is intentional: the super admin may create a business before the owner has ever interacted with the app.

---

## 5. How Does the Owner Log In? (The Current Logic)

### The short answer
The owner **cannot** log in yet with the email entered during business creation. That email is just a label on the business document.

### What the owner must do
1. Open the app.
2. Go to **Register**.
3. Sign up with the **same email** they were assigned as owner.
4. Choose a role — currently the registration form only offers **Customer** or **Professional**.
5. After registration, a super admin or the owner themselves must change the role to `business_admin` (see below).

### Why it works this way
- Business creation and user authentication are separate domains.
- The system does not auto-provision Firebase Auth accounts from business owner emails because:
  - It would require sending invitation emails or generating temporary passwords.
  - The owner might already have an account under a different email.
  - The business could be created speculatively before the owner is known.

### How a user becomes `business_admin`
Currently, this is a **manual step** performed by a super admin in the Super Admin Dashboard:
- Super admin edits the user.
- Changes role from `customer` or `professional` to `business_admin`.
- Assigns the `businessId` of the business they should manage.

Alternatively, in the Firestore Console:
- Navigate to `/users/{uid}`.
- Edit the `role` field to `business_admin`.
- Set `businessId` to the business ID.

---

## 6. Setup Wizard (New Business Onboarding)

When a `business_admin` logs in for the first time and their business status is `trial` or `active`, they are redirected to the **Setup Wizard** (`Routes.setupWizard`).

### What the wizard covers
1. Business Information (name, email, phone, address)
2. Brand (customer-facing name, logo URL, colors)
3. Business Type
4. Services
5. Staff
6. Opening Hours
7. Booking Rules
8. Preview
9. Launch

### Where progress is saved
- The wizard saves progress into `business.settings.onboardingProgress` in Firestore.
- On completion, the business status is set to `active` and onboarding data is cleared.
- The wizard then redirects to the customer/professional home.

---

## 7. Summary of Registration Paths

```
+------------------+---------------------------+----------------------+---------------------+
| User Type        | How they get a login      | How they get role    | Who assigns business|
+------------------+---------------------------+----------------------+---------------------+
| Customer         | Self-register             | Self-select at reg   | N/A                 |
| Professional     | Self-register             | Self-select at reg   | N/A                 |
| Business Admin   | Self-register             | Super admin changes  | Super admin sets     |
|                  | (as customer/prof)        | role to business_admin| businessId on user  |
| Super Admin      | Manual in Firebase/Firestore| N/A                 | N/A                 |
+------------------+---------------------------+----------------------+---------------------+
```

---

## 8. Known Limitations (As Built)

1. **No auto-invite for business owners** — entering an owner email during business creation does not create an account or send an invitation.
2. **Registration form is limited** — new users can only choose `customer` or `professional`. There is no `business_admin` or `super_admin` option in the public registration form.
3. **Role changes are manual** — promoting a user to `business_admin` requires a super admin action or direct Firestore edit.
4. **Setup wizard assumes auth exists** — the wizard is only reachable after a user has already logged in and has a Firestore profile.

---

## 9. Quick Reference — Steps to Get a New Business Live

1. **Super Admin** creates the business in the dashboard, entering the owner’s email.
2. **Owner** registers in the app with that same email, choosing any available role.
3. **Super Admin** changes the owner’s role to `business_admin` and assigns the businessId.
4. **Owner** logs in and is taken through the Setup Wizard.
5. **Owner** completes the wizard → business is activated → owner can manage the business.

---

*Document generated from code analysis of `restorahub` commit `a6f91a4`. No code was modified.*
