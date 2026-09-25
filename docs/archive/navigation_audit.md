# Navigation Audit

## Routes

All application routes are defined in `MyApp` within `main.dart`:

| Route | Destination Widget | Auth Required |
|---|---|---|
| `/login` | `LoginPage` | No |
| `/register` | `RegistrationPage` | No |
| `/forgot-password` | `ForgotPasswordPage` | No |
| `/user_home` | `UserHomePage` | Yes (customer) |
| `/professional_home` | `ProfessionalBookingManagementPage` | Yes (professional) |
| `/success` | `SuccessPage` | Yes (customer) |
| `/profile` | `ProfilePage` | Yes |
| `/notifications` | `NotificationsPage` | Yes |
| `/analytics` | `AnalyticsPage` | Yes (professional) |
| `/past_appointments` | `PastAppointmentsPage` | Yes |

### Route Definition Pattern
Routes are registered in `MaterialApp.routes` as a `Map<String, WidgetBuilder>`:

```dart
routes: {
  '/login': (_) => const LoginPage(),
  '/register': (_) => const RegistrationPage(),
  '/forgot-password': (_) => const ForgotPasswordPage(),
  '/user_home': (_) => const UserHomePage(),
  '/professional_home': (_) => const ProfessionalBookingManagementPage(),
  '/success': (context) { ... },  // with arguments
  '/profile': (_) => const ProfilePage(),
  '/notifications': (_) => const NotificationsPage(),
  '/analytics': (_) => const AnalyticsPage(),
  '/past_appointments': (_) => const PastAppointmentsPage(),
},
```

**Observation**: All routes use `MaterialPageRoute` by default (no custom transitions or route guards). The `/success` route reads arguments from `ModalRoute.of(context)?.settings.arguments`.

## Navigation Flow

### App Startup
1. `main()` initializes Firebase, `NotificationScheduleHelper`, and providers
2. `FirestoreBookingRepository.instance` is created as a singleton
3. `AuthProvider` and `AppointmentProvider` receive the shared repository
4. `ThemeProvider` loads saved theme
5. `AppointmentProvider.loadAppointments()` is called eagerly (even before user is known)
6. `AuthProvider.restoreSession()` checks for existing Firebase session
7. If session exists, `appointmentProvider.setCurrentUser()` is called
8. `_resolveInitialRoute()` determines whether to go to `/login`, `/user_home`, or `/professional_home`
9. `NotificationProvider` and `PaymentProvider` are created (they instantiate their own Firestore repos internally)

### Login Flow
1. User enters email + password on `/login`
2. `AuthProvider.login()` calls Firebase Auth `signInWithEmailAndPassword`
3. If successful, `getUserById()` loads the Firestore profile
4. If no profile exists → `LoginResult.needsProfile` → profile completion dialog
5. If profile exists → `LoginResult.success` → navigate to role-appropriate home
6. If credentials invalid → `LoginResult.invalidCredentials` → show error

### Registration Flow
1. User enters details on `/register`
2. `AuthProvider.register()` validates input, checks email uniqueness, calls Firebase Auth `createUserWithEmailAndPassword`
3. Saves user profile to Firestore via `insertUser()`
4. If profile save fails, deletes the Firebase Auth user (cleanup)
5. On success, navigates to role-appropriate home

### Booking Flow
1. Customer navigates from `/user_home` → `+` → `/services` (not a named route; pushed via `MaterialPageRoute`)
2. `ServicesPage` shows service grid; tapping a service opens subtype picker (bottom sheet)
3. Subtype selection pushes `/booking` for the specific service (pushed via `MaterialPageRoute`)
4. `BookingPage` collects professional, date, time → creates `Appointment` → saves via `AppointmentProvider.addAppointment()`
5. On success, pushes `/success` with `BookingSummary` arguments and removes all previous routes

### Reschedule Flow
1. From `AppointmentCard` → `AppointmentActions.confirmReschedule()` → pushes `/edit_appointment`
2. `EditAppointmentPage` loads professional, allows date/time selection
3. On save, updates appointment and pops back

### Professional Dashboard → Analytics/Earnings
- `ProfessionalBookingManagementPage` has FAB that navigates to itself (manage bookings view)
- `AnalyticsPage` and `EarningsReportPage` are in the `/analytics` route and accessed via `AppDrawer`
- `AddPaymentPage` and `ReceiptPage` are pushed via `MaterialPageRoute` from payment list and earnings list respectively

### Settings Flow
- `/settings` (via FAB on home pages) opens `SettingsPage`
- `SettingsPage` pushes `/profile` for profile editing
- Theme selection is handled inline
- Logout calls `AuthProvider.logout()` and navigates to `/login` with route removal

## Authentication Flow

### Session Restoration
1. On app start, `AuthProvider.restoreSession()` checks `FirebaseAuth.instance.currentUser`
2. If a Firebase user exists, loads Firestore profile via `getUserById()`
3. If profile exists, sets `currentUser` and navigates to the appropriate home screen
4. If no profile exists, navigates to `/login` (will trigger first-login flow)

### Route Protection
**There are no route guards.** Protection is implemented per-page:
- `UserHomePage`, `ProfessionalBookingManagementPage`, `ProfilePage`, `NotificationsPage`, `SettingsPage`, `PastAppointmentsPage`: check `auth.currentUser == null` and redirect to `/login` using `pushNamedAndRemoveUntil`
- `AnalyticsPage`: checks `user == null || !user.isProfessional` and shows an access denied message
- `ServicesPage`: checks `auth.currentUser == null` and redirects to `/login`
- `BookingPage`: no explicit auth check (relies on FAB navigation from authenticated home screen)

**Risk**: A user can manually navigate to any route by typing it in the URL bar or programmatically, and the page will attempt to load data even without authentication.

## Startup Flow

```
main() → Firebase.initializeApp() → NotificationScheduleHelper.initialize()
  → FirestoreBookingRepository.instance created
  → AuthProvider created with repository injection
  → AppointmentProvider created with repository injection
  → ThemeProvider created, loadTheme() called
  → AppointmentProvider.loadAppointments() called (eagerly, before auth)
  → AuthProvider.restoreSession() called
    → If session exists: appointmentProvider.setCurrentUser(user)
  → _resolveInitialRoute(user) determines start route
  → NotificationProvider created (no repository injection)
  → PaymentProvider created (no repository injection)
  → MyApp rendered with MultiProvider
```

### Observations
- `AppointmentProvider.loadAppointments()` is called **before** the user is known, meaning all appointments are loaded for all users — this is a security and performance concern
- `NotificationProvider` and `PaymentProvider` are created without any repository injection or initial data loading; they only load data when their respective pages are visited
- `themeProvider.loadTheme()` is awaited before the app renders, preventing flash of wrong theme

## Potential Improvements

1. **Route guards**: Implement a `RouteGuard` or use `onGenerateRoute` to protect authenticated routes centrally rather than duplicating checks in each page
2. **Lazy loading**: Do not call `loadAppointments()` eagerly in `main()`; defer until user is known
3. **Named route consistency**: Some routes are pushed via `MaterialPageRoute` directly (`/services`, `/booking`, `/edit_appointment`, `/add_payment`, `/receipt`) rather than being registered in `MaterialApp.routes`. This means deep linking to these screens is not possible via named routes
4. **Route arguments type safety**: The `/success` route uses `ModalRoute.of(context)?.settings.arguments` with a raw cast (`as BookingSummary?`) — no type safety or validation at the route level
5. **Deep link support**: No support for deep links from push notifications, emails, or external sources
6. **Logout route cleanup**: Logout uses `pushNamedAndRemoveUntil('/login', ...)` which leaves the entire navigation stack; consider a more thorough stack cleanup