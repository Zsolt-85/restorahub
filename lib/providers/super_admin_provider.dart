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
  }) async {
    _beginLoading();
    try {
      final business = Business(
        id: '',
        name: name.trim(),
        email: email,
        logoUrl: logoUrl,
        primaryColorHex: primaryColorHex,
        phone: phone,
        address: address,
      );
      await _repository.createBusiness(business);
      await loadAllBusinesses();
      return null;
    } on AppException catch (e) {
      _endLoading(e.message);
      return e.message;
    } catch (e) {
      _endLoading('Unexpected error creating business');
      return 'Unexpected error creating business';
    }
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
