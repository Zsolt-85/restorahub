import 'package:cloud_firestore/cloud_firestore.dart';

import '../exceptions/app_exception.dart';
import '../models/business.dart';
import '../utils/app_logger.dart';
import 'business_repository.dart';

class FirestoreBusinessRepository implements BusinessRepository {
  FirestoreBusinessRepository._();
  static final FirestoreBusinessRepository instance =
      FirestoreBusinessRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _businessesCol =>
      _firestore.collection('businesses');

  @override
  Future<Business?> getBusinessById(String businessId) async {
    try {
      final doc = await _businessesCol.doc(businessId).get();
      if (!doc.exists) {
        AppLogger.debug(
          'FirestoreBusinessRepository.getBusinessById: doc does not exist for ID $businessId',
        );
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return Business.fromMap(data);
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreBusinessRepository.getBusinessById error: $e\n$stack',
      );
      throw AppException('Failed to load business', cause: e);
    }
  }

  @override
  Future<void> updateBusiness(Business business) async {
    try {
      if (business.id.isEmpty) {
        throw const AppException('Business ID is required');
      }
      await _businessesCol.doc(business.id).update(business.toMap());
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreBusinessRepository.updateBusiness error: $e\n$stack',
      );
      if (e is AppException) rethrow;
      throw AppException('Failed to update business', cause: e);
    }
  }
}
