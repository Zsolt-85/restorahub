import 'package:flutter/material.dart';

import '../exceptions/app_exception.dart';
import '../models/business.dart';
import '../models/user.dart';
import '../repositories/super_admin_repository.dart';


class SuperAdminProvider extends ChangeNotifier {
  SuperAdminProvider({SuperAdminRepository? repository})
      : _repository = repository ?? FirestoreSuperAdminRepository.instance;

  final SuperAdminRepository _repository;

  List<Business> _businesses = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<Business> get businesses => _businesses;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _beginLoading() {
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  void _endLoading([String? error]) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  Future<void> loadAllBusinesses() async {
    _beginLoading();
    try {
      _businesses = await _repository.getAllBusinesses();
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error loading businesses');
    }
  }

  Future<void> loadAllUsers({String? searchQuery}) async {
    _beginLoading();
    try {
      _users = await _repository.getAllUsers(searchQuery: searchQuery);
      _endLoading();
    } on AppException catch (e) {
      _endLoading(e.message);
    } catch (e) {
      _endLoading('Unexpected error loading users');
    }
  }

  Future<String?> createBusiness({
    required String name,
    String? email,
    String? logoUrl,
    String? primaryColorHex,
    String? phone,
    String? address,
    BusinessType? businessType,
    String? ownerEmail,
  }) async {
    _beginLoading();
    try {
      final now = DateTime.now();
      final slug = _generateSlug(name.trim());
      final effectiveOwnerId = ownerEmail?.trim().toLowerCase();

      final business = Business(
        id: '',
        name: name.trim(),
        email: email?.trim().toLowerCase(),
        logoUrl: logoUrl,
        primaryColorHex: primaryColorHex,
        phone: phone?.trim(),
        address: address?.trim(),
        slug: slug,
        businessType: businessType,
        status: BusinessStatus.trial,
        ownerId: effectiveOwnerId,
        contactInformation: BusinessContactInformation(
          address: address?.trim(),
          phone: phone?.trim(),
          email: email?.trim().toLowerCase(),
        ),
        branding: BusinessBranding(
          primaryColor: primaryColorHex,
        ),
        settings: BusinessSettings(),
        subscription: BusinessSubscription(
          status: 'trial',
          startDate: now,
        ),
        featureEntitlements: const [],
        createdAt: now,
        updatedAt: now,
      );
      await _repository.createBusiness(business);
      await loadAllBusinesses();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e) {
      _endLoading('Unexpected error creating business');
      return 'Unexpected error creating business: ${e.toString()}';
    }
  }

  String _generateSlug(String name) {
    final lower = name.toLowerCase().trim();
    final slug = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'business' : slug;
  }

  Future<String?> updateBusiness({
    required String businessId,
    required String name,
    String? email,
    String? logoUrl,
    String? primaryColorHex,
    String? phone,
    String? address,
  }) async {
    _beginLoading();
    try {
      final business = Business(
        id: businessId,
        name: name.trim(),
        email: email,
        logoUrl: logoUrl,
        primaryColorHex: primaryColorHex,
        phone: phone,
        address: address,
      );
      await _repository.updateBusiness(business);
      await loadAllBusinesses();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e) {
      _endLoading('Unexpected error updating business');
      return 'Unexpected error updating business';
    }
  }

  Future<String?> updateUserRoleAndBusiness({
    required String userId,
    required String newRole,
    String? businessId,
  }) async {
    _beginLoading();
    try {
      await _repository.updateUserRoleAndBusiness(
        userId,
        newRole,
        businessId,
      );
      await loadAllUsers();
      _endLoading();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e) {
      _endLoading('Unexpected error updating user');
      return 'Unexpected error updating user';
    }
  }
}
