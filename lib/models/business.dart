import 'package:restorahub/models/location.dart';

enum BusinessType { wellness, beauty, fitness, automotive, healthcare, custom }

enum BusinessStatus { trial, active, suspended, cancelled, archived }

class BusinessBranding {
  final String? businessName;
  final String? logo;
  final String? favicon;
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final String? typography;
  final String? customDomain;
  final String? themeMode;

  BusinessBranding({
    this.businessName,
    this.logo,
    this.favicon,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.typography,
    this.customDomain,
    this.themeMode,
  });

  factory BusinessBranding.fromMap(Map<String, dynamic> map) {
    return BusinessBranding(
      businessName: map['businessName']?.toString(),
      logo: map['logo']?.toString(),
      favicon: map['favicon']?.toString(),
      primaryColor: map['primaryColor']?.toString(),
      secondaryColor: map['secondaryColor']?.toString(),
      accentColor: map['accentColor']?.toString(),
      typography: map['typography']?.toString(),
      customDomain: map['customDomain']?.toString(),
      themeMode: map['themeMode']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'logo': logo,
      'favicon': favicon,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'typography': typography,
      'customDomain': customDomain,
      'themeMode': themeMode,
    };
  }

  BusinessBranding copyWith({
    String? businessName,
    String? logo,
    String? favicon,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? typography,
    String? customDomain,
    String? themeMode,
  }) {
    return BusinessBranding(
      businessName: businessName ?? this.businessName,
      logo: logo ?? this.logo,
      favicon: favicon ?? this.favicon,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      typography: typography ?? this.typography,
      customDomain: customDomain ?? this.customDomain,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class BusinessContactInformation {
  final String? address;
  final String? phone;
  final String? email;
  final String? website;

  BusinessContactInformation({
    this.address,
    this.phone,
    this.email,
    this.website,
  });

  factory BusinessContactInformation.fromMap(Map<String, dynamic> map) {
    return BusinessContactInformation(
      address: map['address']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      website: map['website']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
    };
  }

  BusinessContactInformation copyWith({
    String? address,
    String? phone,
    String? email,
    String? website,
  }) {
    return BusinessContactInformation(
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
    );
  }
}

class BusinessSettings {
  final int? cancellationWindowHours;
  final int? bufferTimeMinutes;
  final Map<String, dynamic>? notificationConfig;
  final Map<String, dynamic>? onboardingProgress;
  final bool? isSoloProvider;
  final bool? depositRequired;
  final double? depositPercent;
  final double? noShowFeeAmount;

  BusinessSettings({
    this.cancellationWindowHours,
    this.bufferTimeMinutes,
    this.notificationConfig,
    this.onboardingProgress,
    this.isSoloProvider,
    this.depositRequired,
    this.depositPercent,
    this.noShowFeeAmount,
  });

  /// Effective cancellation window, defaulting to the legacy 2 hours.
  Duration get effectiveCancellationWindow =>
      Duration(hours: cancellationWindowHours ?? 2);

  /// Effective deposit percent, clamped to 0–100.
  double get effectiveDepositPercent {
    final percent = depositPercent ?? 0.0;
    if (percent.isNaN || percent <= 0) return 0.0;
    if (percent > 100) return 100.0;
    return percent;
  }

  bool get isDepositRequired =>
      (depositRequired ?? false) && effectiveDepositPercent > 0;

  double get effectiveNoShowFee {
    final fee = noShowFeeAmount ?? 0.0;
    if (fee.isNaN || fee <= 0) return 0.0;
    return fee;
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      cancellationWindowHours: map['cancellationWindowHours'] as int?,
      bufferTimeMinutes: map['bufferTimeMinutes'] as int?,
      notificationConfig: map['notificationConfig'] as Map<String, dynamic>?,
      onboardingProgress: map['onboardingProgress'] as Map<String, dynamic>?,
      isSoloProvider: map['isSoloProvider'] as bool?,
      depositRequired: map['depositRequired'] as bool?,
      depositPercent: (map['depositPercent'] as num?)?.toDouble(),
      noShowFeeAmount: (map['noShowFeeAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cancellationWindowHours': cancellationWindowHours,
      'bufferTimeMinutes': bufferTimeMinutes,
      'notificationConfig': notificationConfig,
      'onboardingProgress': onboardingProgress,
      'isSoloProvider': isSoloProvider,
      'depositRequired': depositRequired,
      'depositPercent': depositPercent,
      'noShowFeeAmount': noShowFeeAmount,
    };
  }

  BusinessSettings copyWith({
    int? cancellationWindowHours,
    int? bufferTimeMinutes,
    Map<String, dynamic>? notificationConfig,
    Map<String, dynamic>? onboardingProgress,
    bool? isSoloProvider,
    bool? depositRequired,
    double? depositPercent,
    double? noShowFeeAmount,
  }) {
    return BusinessSettings(
      cancellationWindowHours:
          cancellationWindowHours ?? this.cancellationWindowHours,
      bufferTimeMinutes: bufferTimeMinutes ?? this.bufferTimeMinutes,
      notificationConfig: notificationConfig ?? this.notificationConfig,
      onboardingProgress: onboardingProgress ?? this.onboardingProgress,
      isSoloProvider: isSoloProvider ?? this.isSoloProvider,
      depositRequired: depositRequired ?? this.depositRequired,
      depositPercent: depositPercent ?? this.depositPercent,
      noShowFeeAmount: noShowFeeAmount ?? this.noShowFeeAmount,
    );
  }
}

class BusinessSubscription {
  final String? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  BusinessSubscription({
    this.plan,
    this.startDate,
    this.endDate,
    this.status,
  });

  factory BusinessSubscription.fromMap(Map<String, dynamic> map) {
    return BusinessSubscription(
      plan: map['plan']?.toString(),
      startDate: _parseNullableDateTime(map['startDate']),
      endDate: _parseNullableDateTime(map['endDate']),
      status: map['status']?.toString(),
    );
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
    };
  }

  BusinessSubscription copyWith({
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) {
    return BusinessSubscription(
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}

class Business {
  final String id;
  final String name;
  final String? email;
  final String? logoUrl;
  final String? primaryColorHex;
  final String? phone;
  final String? address;

  final String? slug;
  final BusinessType? businessType;
  final BusinessStatus status;
  final String? ownerId;
  final BusinessContactInformation? contactInformation;
  final BusinessBranding? branding;
  final BusinessSettings? settings;
  final BusinessSubscription? subscription;
  final List<String> featureEntitlements;
  final List<Location> locations;
  final String? activeLocationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int staffCount;

  Business({
    required this.id,
    required this.name,
    this.email,
    this.logoUrl,
    this.primaryColorHex,
    this.phone,
    this.address,
    this.slug,
    this.businessType,
    this.status = BusinessStatus.trial,
    this.ownerId,
    this.contactInformation,
    this.branding,
    this.settings,
    this.subscription,
    this.featureEntitlements = const [],
    this.locations = const [],
    this.activeLocationId,
    this.createdAt,
    this.updatedAt,
    this.staffCount = 0,
  });

  bool get isActive => status == BusinessStatus.active;
  bool get isTrial => status == BusinessStatus.trial;
  bool get isSuspended => status == BusinessStatus.suspended;

  bool get isSolo => (settings?.isSoloProvider ?? false) || staffCount <= 1;

  bool get isOnboarded {
    if (status == BusinessStatus.active) return true;
    final progress = settings?.onboardingProgress;
    if (progress == null) return false;
    return progress['isCompleted'] == true;
  }

  String? get effectivePrimaryColor =>
      branding?.primaryColor ?? primaryColorHex;
  String? get effectiveBusinessName => branding?.businessName ?? name;
  String? get effectiveLogo => branding?.logo ?? logoUrl;

  bool hasFeature(String feature) => featureEntitlements.contains(feature);

  factory Business.fromMap(Map<String, dynamic> map) {
    final brandingMap = map['branding'] as Map<String, dynamic>?;
    final contactMap = map['contactInformation'] as Map<String, dynamic>?;
    final settingsMap = map['settings'] as Map<String, dynamic>?;
    final subscriptionMap = map['subscription'] as Map<String, dynamic>?;

    BusinessType? parsedBusinessType;
    final businessTypeRaw = map['businessType']?.toString();
    if (businessTypeRaw != null && businessTypeRaw.isNotEmpty) {
      for (final type in BusinessType.values) {
        if (type.name == businessTypeRaw) {
          parsedBusinessType = type;
          break;
        }
      }
    }

    BusinessStatus parsedStatus = BusinessStatus.trial;
    final statusRaw = map['status']?.toString();
    if (statusRaw != null && statusRaw.isNotEmpty) {
      for (final s in BusinessStatus.values) {
        if (s.name == statusRaw) {
          parsedStatus = s;
          break;
        }
      }
    }

    return Business(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? contactMap?['email']?.toString(),
      logoUrl: map['logoUrl']?.toString() ?? brandingMap?['logo']?.toString(),
      primaryColorHex: map['primaryColorHex']?.toString() ??
          brandingMap?['primaryColor']?.toString(),
      phone: map['phone']?.toString() ?? contactMap?['phone']?.toString(),
      address: map['address']?.toString() ?? contactMap?['address']?.toString(),
      slug: map['slug']?.toString(),
      businessType: parsedBusinessType,
      status: parsedStatus,
      ownerId: map['ownerId']?.toString(),
      contactInformation: contactMap != null
          ? BusinessContactInformation.fromMap(contactMap)
          : null,
      branding:
          brandingMap != null ? BusinessBranding.fromMap(brandingMap) : null,
      settings:
          settingsMap != null ? BusinessSettings.fromMap(settingsMap) : null,
      subscription: subscriptionMap != null
          ? BusinessSubscription.fromMap(subscriptionMap)
          : null,
      featureEntitlements: map['featureEntitlements'] != null
          ? List<String>.from((map['featureEntitlements'] as List<dynamic>)
              .map((e) => e.toString()))
          : const [],
      locations: map['locations'] != null
          ? List<Location>.from(
              (map['locations'] as List<dynamic>)
                  .map((e) => Location.fromMap(e as Map<String, dynamic>)),
            )
          : const [],
      activeLocationId: map['activeLocationId']?.toString(),
      createdAt: _parseNullableDateTime(map['createdAt']),
      updatedAt: _parseNullableDateTime(map['updatedAt']),
      staffCount: _parseStaffCount(map['staffCount']),
    );
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  static int _parseStaffCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'logoUrl': logoUrl,
      'primaryColorHex': primaryColorHex,
      'phone': phone,
      'address': address,
      'slug': slug,
      'businessType': businessType?.name,
      'status': status.name,
      'ownerId': ownerId,
      'contactInformation': contactInformation?.toMap(),
      'branding': branding?.toMap(),
      'settings': settings?.toMap(),
      'subscription': subscription?.toMap(),
      'featureEntitlements': featureEntitlements,
      'locations': locations.map((l) => l.toMap()).toList(),
      'activeLocationId': activeLocationId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'staffCount': staffCount,
    };
  }

  Business copyWith({
    String? id,
    String? name,
    String? email,
    String? logoUrl,
    String? primaryColorHex,
    String? phone,
    String? address,
    String? slug,
    BusinessType? businessType,
    BusinessStatus? status,
    String? ownerId,
    BusinessContactInformation? contactInformation,
    BusinessBranding? branding,
    BusinessSettings? settings,
    BusinessSubscription? subscription,
    List<String>? featureEntitlements,
    List<Location>? locations,
    String? activeLocationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? staffCount,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      slug: slug ?? this.slug,
      businessType: businessType ?? this.businessType,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      contactInformation: contactInformation ?? this.contactInformation,
      branding: branding ?? this.branding,
      settings: settings ?? this.settings,
      subscription: subscription ?? this.subscription,
      featureEntitlements: featureEntitlements ?? this.featureEntitlements,
      locations: locations ?? this.locations,
      activeLocationId: activeLocationId ?? this.activeLocationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffCount: staffCount ?? this.staffCount,
    );
  }
}
