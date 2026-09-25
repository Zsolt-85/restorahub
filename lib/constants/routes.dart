class Routes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const completeProfile = '/complete-profile';
  static const customerHome = '/user_home';
  static const professionalHome = '/professional_home';
  static const businessSettings = '/business_settings';
  static const services = '/services';
  static const booking = '/booking';
  static const editAppointment = '/edit-appointment';
  static const addPayment = '/add-payment';
  static const receipt = '/receipt';
  static const success = '/success';
  static const profile = '/profile';
  static const notifications = '/notifications';
  // Personal analytics for staff (AnalyticsPage). Kept separate from the
  // business-level analyticsDashboard below: this one is role-gated to
  // staff/business_admin in the drawer and shows the professional's own stats.
  static const analytics = '/analytics';
  static const pastAppointments = '/past_appointments';
  static const settings = '/settings';
  static const professionalManualBooking = '/professional_manual_booking';
  static const teamManagement = '/team_management';
  static const adminCalendar = '/admin_calendar';
  static const superAdminDashboard = '/super_admin_dashboard';
  static const setupWizard = '/setup_wizard';
  static const adminDashboard = '/admin/dashboard';
  // Business-level analytics dashboard (AnalyticsDashboardPage) for admins,
  // additionally gated by FeatureGate 'analytics'. Not a duplicate of
  // [analytics]: that route serves individual staff stats.
  static const analyticsDashboard = '/admin/analytics';
  // Professional earnings report (EarningsReportPage). Admin/staff route.
  static const earningsReport = '/earnings_report';
}
