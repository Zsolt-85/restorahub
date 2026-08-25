# Domain Audit Report

**Date**: 2026-08-25
**Scope**: Full `lib/` wellness-specific assumption discovery
**Status**: Complete

---

## Executive Summary

This audit identified **47 wellness-specific assumptions** across the codebase, classified into three categories:

| Classification | Count | Description |
|----------------|-------|-------------|
| CORE | 18 | Terminology/fields that must be renamed for multi-vertical support |
| CONFIGURATION | 16 | Hardcoded values that should be tenant-configurable |
| MODULE | 13 | Vertical-specific modules that should be feature-flagged |

**Key finding**: The codebase is approximately **40% toward "Platform Ready"**. Core booking mechanics are sound, but domain terminology, service catalog, and business model are wellness-specific.

---

## CORE Findings (Rename Required)

### CORE-001: `User.specialty` field
- **File**: `lib/models/user.dart:11`
- **Current**: String field storing wellness category (e.g., "Massage", "Haircut")
- **Issue**: Wellness-specific semantic; should be generic category
- **Action**: Rename to `category` (nullable, optional)
- **Risk**: Medium — affects AuthProvider, ProfilePage, FirestoreUserRepository queries

### CORE-002: `User.isProfessional` getter
- **File**: `lib/models/user.dart:36`
- **Current**: `role == 'professional'` string comparison
- **Issue**: Domain-specific role name
- **Action**: Rename to `isStaff`; use Role enum value `staff`
- **Risk**: High — referenced in 50+ locations across providers and pages

### CORE-003: `User.roleLabel` getter
- **File**: `lib/models/user.dart:38`
- **Current**: Returns 'Professional' or 'Customer'
- **Issue**: Hardcoded display labels
- **Action**: Generalize to use Role enum with localization
- **Risk**: Low — UI display only

### CORE-004: Role stored as String, not enum
- **File**: `lib/models/user.dart:10,36`
- **Current**: `final String role;` with `Role` enum unused
- **Issue**: String comparisons scattered across codebase
- **Action**: Migrate to `Role` enum with backward-compatible serialization
- **Risk**: High — requires updating all role comparisons

### CORE-005: `Payment.specialty` field
- **File**: `lib/models/payment.dart:16`
- **Current**: Duplicates User.specialty for payment records
- **Issue**: Wellness-specific semantic
- **Action**: Rename to `staffCategory` or remove (resolve from user at read time)
- **Risk**: Medium — affects payment display in UI

### CORE-006: `Appointment.serviceType` getter
- **File**: `lib/models/appointment.dart:65-71`
- **Current**: Parses service string for subtype using em-dash delimiter
- **Issue**: Implicit service hierarchy convention
- **Action**: Rename to `serviceVariant`; document convention
- **Risk**: Low — internal helper

### CORE-007: `professionalId` field names
- **Files**: `lib/models/appointment.dart:39`, `lib/models/payment.dart:11`, `lib/repositories/booking_repository.dart`
- **Current**: `professionalId`, `professionalName`, etc.
- **Issue**: Domain-specific reference to booking party
- **Action**: Rename to `staffId`, `staffName`, etc.
- **Risk**: High — affects all repository methods and UI

### CORE-008: `getProfessionalsBySpecialty` repository method
- **File**: `lib/repositories/user_repository.dart:9`
- **Current**: Filters by `specialty` field
- **Issue**: Wellness-specific query method
- **Action**: Rename to `getStaffByCategory` after rename
- **Risk**: Medium — used in booking_page.dart

### CORE-009: `getProfessionals` repository method
- **File**: `lib/repositories/user_repository.dart:10`
- **Current**: Filters by `role == 'professional'`
- **Issue**: Domain-specific method name
- **Action**: Rename to `getStaff` after rename
- **Risk**: Medium — widely used

### CORE-010: `watchProfessionals` repository method
- **File**: `lib/repositories/user_repository.dart:11`
- **Current**: Filters by `role == 'professional'`
- **Issue**: Domain-specific method name
- **Action**: Rename to `watchStaff` after rename
- **Risk**: Medium — used in team management

### CORE-011: Professional-specific notification messages
- **File**: `lib/providers/appointment_provider.dart:187-220`
- **Current**: "Your professional confirmed...", "Your professional declined..."
- **Issue**: Hardcoded "professional" in notification templates
- **Action**: Parameterize with role-aware labels
- **Risk**: Low — display strings

### CORE-012: Professional-specific UI labels
- **File**: `lib/pages/booking_page.dart:560,579,775`
- **Current**: "Showing {category} professionals only", "Select professional"
- **Issue**: Hardcoded "professional" in UI text
- **Action**: Localize and generalize
- **Risk**: Low — display strings

### CORE-013: `professionalEmail` field in Appointment
- **File**: `lib/models/appointment.dart:42`
- **Current**: Denormalized professional email
- **Issue**: Domain-specific denormalization
- **Action**: Rename to `staffEmail`; eventually remove in favor of resolution
- **Risk**: Medium — used in availability checks

### CORE-014: `professionalPhone` field in Appointment
- **File**: `lib/models/appointment.dart:41`
- **Current**: Denormalized professional phone
- **Issue**: Domain-specific denormalization
- **Action**: Rename to `staffPhone`; eventually remove
- **Risk**: Medium — displayed in appointment cards

### CORE-015: `professionalName` field in Appointment
- **File**: `lib/models/appointment.dart:40`
- **Current**: Denormalized professional name
- **Issue**: Domain-specific denormalization
- **Action**: Rename to `staffName`; eventually remove
- **Risk**: High — displayed throughout UI

### CORE-016: Professional parameter names in providers
- **Files**: `lib/providers/appointment_provider.dart`, `lib/providers/payment_provider.dart`
- **Current**: `professionalId` parameter throughout
- **Issue**: Domain-specific parameter naming
- **Action**: Rename to `staffId` after model layer rename
- **Risk**: High — public API surface

### CORE-017: `professional_home` route
- **File**: `lib/constants/routes.dart`
- **Current**: Route name implies professional-specific landing
- **Issue**: Domain-specific route naming
- **Action**: Rename to `staff_home` after role rename
- **Risk**: Low — internal route constant

### CORE-018: `ProfessionalBookingManagementPage` class name
- **File**: `lib/pages/professional_booking_management_page.dart`
- **Current**: Domain-specific page class name
- **Issue**: Tied to "professional" terminology
- **Action**: Rename to `StaffBookingManagementPage` after rename
- **Risk**: Medium — file and class rename

---

## CONFIGURATION Findings (Hardcoded Values)

### CONFIG-001: `serviceDescriptions` map
- **File**: `lib/constants/constants.dart:3-9`
- **Current**: Hardcoded wellness service descriptions
- **Issue**: Wellness-specific descriptions
- **Action**: Remove; move to Firestore per-tenant catalog
- **Risk**: Low — fallback display only

### CONFIG-002: `serviceNames` list
- **File**: `lib/constants/constants.dart:11-17`
- **Current**: `['Massage', 'Haircut', 'Spa', 'Facial', 'Manicure']`
- **Issue**: Hardcoded wellness catalog
- **Action**: Remove; move to Firestore per-tenant catalog
- **Risk**: High — referenced in ServiceProvider.defaultServices

### CONFIG-003: `serviceIcons` map
- **File**: `lib/constants/constants.dart:19-25`
- **Current**: Wellness-specific Material icons
- **Issue**: Wellness-specific icon mapping
- **Action**: Remove; move to tenant-branding config
- **Risk**: Low — display only

### CONFIG-004: `serviceTypes` map
- **File**: `lib/constants/constants.dart:27-33`
- **Current**: Wellness service subtypes (e.g., Massage: ['Full Body', 'Facial', 'Head & Neck'])
- **Issue**: Hardcoded wellness subtypes
- **Action**: Remove; move to Firestore per-tenant catalog
- **Risk**: High — referenced in ServiceProvider.defaultServices

### CONFIG-005: `ServiceProvider.defaultServices`
- **File**: `lib/providers/service_provider.dart:12-27`
- **Current**: Hardcoded wellness catalog as fallback
- **Issue**: Wellness assumption baked into service layer
- **Action**: Two-step migration: (1) Firestore primary with hardcoded fallback, (2) remove after setup wizard
- **Risk**: High — booking_page.dart depends on fallback

### CONFIG-006: `ServiceProvider.getCategoryForService` static method
- **File**: `lib/providers/service_provider.dart:38-46`
- **Current**: Iterates `defaultServices` for category matching
- **Issue**: Tightly coupled to hardcoded wellness catalog
- **Action**: Generalize to query Firestore catalog
- **Risk**: Medium — used in booking_page.dart

### CONFIG-007: Wellness catalog in localization files
- **Files**: `lib/l10n/app_localizations_*.dart`
- **Current**: Service names may appear in translations
- **Issue**: Wellness-specific strings
- **Action**: Audit and remove wellness-specific keys
- **Risk**: Low — localization

### CONFIG-008: `Business.primaryColorHex` branding
- **File**: `lib/models/business.dart:6`, `lib/providers/business_provider.dart:13`
- **Current**: Single color for white-label theming
- **Issue**: Minimal branding; no logo, secondary colors, typography
- **Action**: Expand to `BusinessBranding` object per PLAT-0501
- **Risk**: Medium — theming pipeline

### CONFIG-009: Missing `businessType` field
- **Files**: `lib/models/business.dart`, all business-related code
- **Current**: No business type distinction
- **Issue**: Cannot differentiate wellness/fitness/automotive configurations
- **Action**: Add `businessType` enum field to Business model
- **Risk**: Low — additive change

### CONFIG-010: Missing `Business.status` field
- **File**: `lib/models/business.dart`
- **Current**: No lifecycle state (trial/active/suspended)
- **Issue**: Cannot implement business lifecycle
- **Action**: Add `status` enum field to Business model
- **Risk**: Low — additive change

### CONFIG-011: Missing `Business.ownerId` field
- **File**: `lib/models/business.dart`
- **Current**: No owner reference despite rules using it
- **Issue**: Incomplete ownership model
- **Action**: Add `ownerId` field; backfill from existing documents
- **Risk**: Low — additive change

### CONFIG-012: Missing `Business.subscription` field
- **File**: `lib/models/business.dart`
- **Current**: No subscription/plan tracking
- **Issue**: Cannot implement entitlement gating
- **Action**: Add `subscription` object field to Business model
- **Risk**: Low — additive change

### CONFIG-013: Missing `Business.settings` field
- **File**: `lib/models/business.dart`
- **Current**: No configurable booking rules
- **Issue**: Cannot customize cancellation window, buffer time, etc.
- **Action**: Add `settings` object field to Business model
- **Risk**: Low — additive change

### CONFIG-014: `slotDurationOptions` hardcoded
- **File**: `lib/constants/constants.dart:35`
- **Current**: `[15, 30, 45, 60, 90, 120]`
- **Issue**: Fixed slot duration options
- **Action**: Move to tenant settings; keep sensible defaults
- **Risk**: Low — configuration

### CONFIG-015: `bufferTimeOptions` hardcoded
- **File**: `lib/constants/constants.dart:37`
- **Current**: `[0, 10, 15, 30]`
- **Issue**: Fixed buffer time options
- **Action**: Move to tenant settings; keep sensible defaults
- **Risk**: Low — configuration

### CONFIG-016: `Service.subtypes` field
- **File**: `lib/models/service.dart:8`
- **Current**: Hardcoded subtype list
- **Issue**: Wellness-specific hierarchy
- **Action**: Rename to `variants`; document as tenant-specific
- **Risk**: Medium — used in booking_page.dart

---

## MODULE Findings (Feature-Flag Candidates)

### MODULE-001: Calendar integration
- **File**: `lib/helpers/calendar_helper.dart`
- **Current**: Google/Apple calendar export
- **Issue**: Should be feature-entitled
- **Action**: Gate behind `calendarIntegration` entitlement
- **Risk**: Low — additive gating

### MODULE-002: Analytics dashboard
- **File**: `lib/pages/analytics_page.dart`
- **Current**: Full analytics with charts
- **Issue**: Should be feature-entitled (basic vs advanced)
- **Action**: Gate behind `analytics` / `advancedAnalytics` entitlements
- **Risk**: Low — additive gating

### MODULE-003: Payment recording
- **File**: `lib/pages/add_payment_page.dart`
- **Current**: Manual payment recording
- **Issue**: Should be feature-entitled
- **Action**: Gate behind `payments` entitlement
- **Risk**: Low — additive gating

### MODULE-004: Notifications system
- **Files**: `lib/providers/notification_provider.dart`, `lib/pages/notifications_page.dart`
- **Current**: Real-time notifications
- **Issue**: Should be feature-entitled
- **Action**: Gate behind `notifications` entitlement
- **Risk**: Low — additive gating

### MODULE-005: Team management
- **File**: `lib/pages/team_management_page.dart`
- **Current**: Staff management interface
- **Issue**: Should be feature-entitled (multipleStaff)
- **Action**: Gate behind `multipleStaff` entitlement
- **Risk**: Low — additive gating

### MODULE-006: CSV export
- **Files**: `lib/helpers/csv_export_helper*.dart`
- **Current**: Earnings/analytics CSV export
- **Issue**: Should be feature-entitled
- **Action**: Gate behind `analytics` entitlement
- **Risk**: Low — additive gating

### MODULE-007: Receipt generation
- **File**: `lib/pages/receipt_page.dart`
- **Current**: Payment receipt PDF
- **Issue**: Should be feature-entitled
- **Action**: Gate behind `payments` entitlement
- **Risk**: Low — additive gating

### MODULE-008: Business settings
- **File**: `lib/pages/business_settings_page.dart`
- **Current**: Business configuration
- **Issue**: Should be restricted to business admin
- **Action**: Ensure role-based access
- **Risk**: Low — access control

### MODULE-009: Super admin dashboard
- **Files**: `lib/pages/super_admin_dashboard_page.dart`, `lib/providers/super_admin_provider.dart`
- **Current**: Tenant CRUD operations
- **Issue**: Should require super_admin role
- **Action**: Add server-side role verification
- **Risk**: Medium — security-sensitive

### MODULE-010: Service management
- **File**: `lib/pages/services_page.dart`
- **Current**: CRUD for services
- **Issue**: Wellness-specific UI assumptions possible
- **Action**: Audit for wellness-specific language
- **Risk**: Low — audit only

### MODULE-011: Schedule helper
- **File**: `lib/helpers/schedule_helper.dart`
- **Current**: Pure scheduling logic
- **Issue**: Domain-agnostic; should remain unchanged
- **Action**: Keep as-is; reusable across verticals
- **Risk**: None — already generic

### MODULE-012: Route guard helper
- **File**: `lib/helpers/route_guard_helper.dart`
- **Current**: Centralized route guards
- **Issue**: Uses role string comparisons
- **Action**: Update after Role enum migration
- **Risk**: Low — internal helper

### MODULE-013: Theme helper
- **File**: `lib/theme/theme_helper.dart`
- **Current**: Generates theme from primaryColorHex
- **Issue**: Limited branding capability
- **Action**: Expand to use BusinessBranding object
- **Risk**: Medium — theming pipeline

---

## Dependency Map: Wellness Catalog Removal

The following files form a dependency chain for the wellness catalog:

```
constants.dart (serviceNames, serviceTypes, serviceDescriptions)
    ↓
service_provider.dart (defaultServices, getCategoryForService)
    ↓
booking_page.dart (_servicesForDisplay, _loadAppointmentForReschedule, _loadProfessionals)
    ↓
user_repository.dart (getProfessionalsBySpecialty)
    ↓
firestore_user_repository.dart (getProfessionalsBySpecialty implementation)
```

**Migration order**:
1. Add Firestore-backed catalog with fallback to hardcoded
2. Populate Firestore catalog during setup wizard
3. Remove hardcoded catalog after wizard is stable

---

## Implementation Priority

### Phase 1: Terminology Rename (Sprint 3)
1. Rename `User.specialty` → `User.category`
2. Rename `User.isProfessional` → `User.isStaff`
3. Rename `professionalId` → `staffId` across models, repositories, providers
4. Update Role enum usage (currently String-based)

### Phase 2: Business Model Expansion (Sprint 2)
1. Add `businessType`, `status`, `ownerId` to Business model
2. Add `subscription`, `settings`, `branding` objects
3. Backfill existing Firestore documents

### Phase 3: Catalog Migration (Sprint 3)
1. Create Firestore catalog service
2. Build setup wizard for catalog population
3. Remove hardcoded wellness catalog

### Phase 4: Feature Entitlements (Sprint 6)
1. Implement FeatureGate service
2. Add plan definitions
3. Gate MODULE findings behind entitlements

---

## Appendix: Search Term Frequency

| Term | Occurrences | Files | Classification |
|------|-------------|-------|----------------|
| `specialty` | 15+ | 5 files | CORE |
| `professional` | 200+ | 50+ files | CORE |
| `Massage` | 10+ | 3 files | CONFIGURATION |
| `Haircut` | 10+ | 3 files | CONFIGURATION |
| `Spa` | 8+ | 3 files | CONFIGURATION |
| `Facial` | 8+ | 3 files | CONFIGURATION |
| `Manicure` | 8+ | 3 files | CONFIGURATION |
| `serviceTypes` | 5+ | 2 files | CONFIGURATION |
| `profession` | 3+ | 2 files | CORE |
| `treatment` | 0 | 0 | None (good) |
| `wellness` | 2 | README only | CONFIGURATION |

---

*Audit complete. All findings documented with recommended actions and risk assessments.*
