import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/providers/auth_provider.dart' as app;

class RouteGuardHelper {
  static String? evaluateRedirect({
    required String currentRoute,
    required app.AuthProvider authProvider,
    bool? isAuthenticatedOverride,
    bool? isProfileCompleteOverride,
  }) {
    final isAuthenticated =
        isAuthenticatedOverride ?? authProvider.isAuthenticated;
    final isProfileComplete =
        isProfileCompleteOverride ?? authProvider.isProfileComplete;

    final publicRoutes = <String>{Routes.login, Routes.register};

    if (publicRoutes.contains(currentRoute)) {
      if (isAuthenticated && isProfileComplete) {
        return authProvider.currentUser!.isProfessional
            ? Routes.professionalHome
            : Routes.customerHome;
      }
      return null;
    }

    if (!isAuthenticated) {
      return Routes.login;
    }

    if (!isProfileComplete) {
      return Routes.completeProfile;
    }

    final user = authProvider.currentUser!;
    if (user.role == 'customer' && currentRoute == Routes.professionalHome) {
      return Routes.customerHome;
    }
    if (user.role == 'professional' && currentRoute == Routes.customerHome) {
      return Routes.professionalHome;
    }

    return null;
  }
}
