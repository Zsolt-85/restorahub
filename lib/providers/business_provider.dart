import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/location.dart';
import '../theme/theme_helper.dart';

class BusinessProvider extends ChangeNotifier {
  Business? _currentBusiness;
  String? _activeLocationId;

  Business? get currentBusiness => _currentBusiness;

  bool get hasBusiness => _currentBusiness != null;

  Location? get activeLocation {
    if (_activeLocationId == null || _currentBusiness == null) return null;
    return _currentBusiness!.locations.firstWhere(
      (l) => l.id == _activeLocationId,
      orElse: () => _currentBusiness!.locations.isNotEmpty ? _currentBusiness!.locations.first : Location(id: null, name: 'All Locations', isActive: true),
    );
  }

  ThemeData get tenantTheme => ThemeHelper.generateTenantTheme(_currentBusiness?.branding);

  void setBusiness(Business? business) {
    _currentBusiness = business;
    if (business != null && business.activeLocationId != null) {
      _activeLocationId = business.activeLocationId;
    } else if (business != null && business.locations.isNotEmpty) {
      _activeLocationId = business.locations.first.id;
    } else {
      _activeLocationId = null;
    }
    notifyListeners();
  }

  void setActiveLocation(String? locationId) {
    _activeLocationId = locationId;
    notifyListeners();
  }

  void clearBusiness() {
    _currentBusiness = null;
    _activeLocationId = null;
    notifyListeners();
  }
}
