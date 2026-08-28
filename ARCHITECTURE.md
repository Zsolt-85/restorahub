# RestoraHub — Architecture

## Overview

RestoraHub is a Flutter cross-platform booking application built with **Provider + ChangeNotifier** state management and a **Repository Pattern** for data access. It connects customers with professionals for appointment scheduling, management, and payments.

The codebase is organized into strict layers:

```
UI (Pages + Widgets)
    ↓
Providers (ChangeNotifier)
    ↓
Repositories (Abstract interfaces → Firestore implementations)
    ↓
Firebase (Auth + Firestore)
```

## Layers

### 1. Presentation (`lib/pages/`, `lib/widgets/`)
- 30+ page widgets representing every screen
- Shared widgets: `AppointmentCard`, `AppDrawer`, chart widgets
- Pages consume providers via `context.read<T>()` / `Provider.of<T>(context)`
- All navigation uses named routes registered in `main.dart`'s `onGenerateRoute`

### 2. State Management (`lib/providers/`)
- All providers extend `ChangeNotifier`
- 10 providers: `AuthProvider`, `AppointmentProvider`, `BusinessProvider`, `LocaleProvider`, `NotificationProvider`, `PaymentProvider`, `ServiceProvider`, `SetupWizardProvider`, `SuperAdminProvider`, `ThemeProvider`
- Loading pattern: `_beginLoading()` / `_endLoading([String? error])`
- Repository injection via constructor or singleton fallback

### 3. Repositories (`lib/repositories/`)
- Abstract interfaces + Firestore implementations in separate files
- 7 repository pairs: `Booking`, `Business`, `Notification`, `Payment`, `Service`, `User`, `SuperAdmin`
- All implementations are singletons (`._()` + `static final instance`)
- Errors wrapped in `AppException` hierarchy

### 4. Models (`lib/models/`)
- Immutable data classes with `fromMap()` / `toMap()` / `copyWith()`
- Enums for typed fields with safe defaults
- Derived getters for computed state
- 8 models: `Appointment`, `Business`, `BookingSummary`, `Notification`, `Payment`, `Plan`, `Service`, `User`

### 5. Helpers (`lib/helpers/`)
- Pure business-logic utilities (no Flutter dependencies where possible)
- `FeatureGate` — entitlement checks
- `ScheduleHelper` — slot generation, overlap detection
- `BusinessLifecycleHelper` — state machine transitions
- `UserResolutionHelper` — runtime user data resolution
- `RouteGuardHelper` — centralized auth/role redirects
- `CalendarHelper` — native calendar export
- `CsvExportHelper` — analytics export

### 6. Constants (`lib/constants/`)
- Route constants (`routes.dart`)
- Deprecated static service catalog (`constants.dart`)

## State Management

All providers are wired in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ChangeNotifierProvider<AppointmentProvider>.value(value: appointmentProvider),
    ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    Provider<BusinessRepository>.value(value: FirestoreBusinessRepository.instance),
    ChangeNotifierProxyProvider<BusinessRepository, BusinessProvider>(
      create: (_) => BusinessProvider(),
      update: (_, repo, __) => BusinessProvider()..setBusiness(...),
    ),
    // ... 6 more providers
  ],
  child: const RestoraHubApp(),
)
```

## Multi-Tenant Architecture

- Each `Business` has a unique `id`, `slug`, and `businessType`
- All repository queries filter by `businessId`
- `BusinessProvider` holds the active tenant state
- White-label branding via `BusinessBranding` (colors, logo, custom domain, theme mode)
- Tenant theme resolved dynamically via `ThemeHelper.generateTenantTheme(business.branding)`

## Feature Entitlements

- `Plan` model defines feature sets for `trial`, `basic`, `pro`, `enterprise`
- `FeatureGate` helper checks `business.hasFeature(feature)` and `PlanDefinitions`
- New businesses seeded with trial plan entitlements
- UI gating not yet implemented (future sprint)

## Security

- Firebase Auth for authentication
- Firestore security rules enforce role-based access and tenant isolation
- `AppException` hierarchy prevents raw Firebase errors in UI
- Route guards enforce auth/profile/role boundaries on every navigation

## Testing

- 228 unit tests across `test/models/`, `test/providers/`, `test/helpers/`, `test/utils/`, `test/widgets/`, `test/unit/`
- Fake repository pattern (no mockito)
- Multi-tenant isolation tests verify zero cross-tenant data leaks
- `flutter analyze`: 0 errors
- `flutter test`: 228/228 passing

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter |
| Language | Dart >= 3.0.0 |
| State Management | Provider + ChangeNotifier |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| Local Storage | shared_preferences |
| Notifications | flutter_local_notifications + timezone |
| Charts | fl_chart |
| Calendar | add_2_calendar |
| Sharing | share_plus |
| Web APIs | package:web |
