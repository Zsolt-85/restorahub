import 'package:restorahub/constants/routes.dart';
import 'package:restorahub/models/business.dart';
import 'package:restorahub/providers/auth_provider.dart' as app;
import 'package:restorahub/providers/business_provider.dart';

class RouteGuardHelper {
  static String? evaluateRedirect({
    required String currentRoute,
    required app.AuthProvider authProvider,
    BusinessProvider? businessProvider,
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
        final user = authProvider.currentUser!;

        if (user.role == 'super_admin') {
          return Routes.superAdminDashboard;
        }

        if (user.role == 'business_admin') {
          final business = businessProvider?.currentBusiness;
          if (business == null || business.status == BusinessStatus.trial) {
            return Routes.setupWizard;
          }
          return Routes.adminDashboard;
        }

        return user.isProfessional
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

    if (user.role == 'business_admin') {
      final business = businessProvider?.currentBusiness;
      final isTrial = business == null || business.status == BusinessStatus.trial;

      if (isTrial && currentRoute != Routes.setupWizard) {
        return Routes.setupWizard;
      }

      if (!isTrial && !_isAdminRoute(currentRoute)) {
        return Routes.adminDashboard;
      }
    }

    return null;
  }

  static bool _isAdminRoute(String route) {
    const adminRoutes = <String>{
      Routes.adminDashboard,
      Routes.businessSettings,
      Routes.teamManagement,
      Routes.services,
      Routes.adminCalendar,
      Routes.profile,
      Routes.settings,
      Routes.notifications,
      Routes.analytics,
      Routes.pastAppointments,
    };
    return adminRoutes.contains(route);
  }
}
