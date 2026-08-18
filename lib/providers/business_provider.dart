import 'package:flutter/material.dart';

import '../models/business.dart';
import '../theme/theme_helper.dart';

class BusinessProvider extends ChangeNotifier {
  Business? _currentBusiness;

  Business? get currentBusiness => _currentBusiness;

  bool get hasBusiness => _currentBusiness != null;

  ThemeData get tenantTheme => ThemeHelper.generateTenantTheme(_currentBusiness?.primaryColorHex);

  void setBusiness(Business? business) {
    _currentBusiness = business;
    notifyListeners();
  }

  void clearBusiness() {
    _currentBusiness = null;
    notifyListeners();
  }
}
