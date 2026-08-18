import 'package:cloud_firestore/cloud_firestore.dart';

import '../exceptions/app_exception.dart';
import '../models/service.dart';
import '../utils/app_logger.dart';
import 'service_repository.dart';

class FirestoreServiceRepository implements ServiceRepository {
  FirestoreServiceRepository._();
  static final FirestoreServiceRepository instance =
      FirestoreServiceRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _servicesCol =>
      _firestore.collection('services');

  Query<Map<String, dynamic>> _withBusinessFilter(
    Query<Map<String, dynamic>> query,
    String? businessId,
  ) {
    if (businessId != null && businessId.isNotEmpty) {
      return query.where('businessId', isEqualTo: businessId);
    }
    return query;
  }

  @override
  Future<List<Service>> getServices({String? businessId}) async {
    try {
      final query = await _withBusinessFilter(_servicesCol, businessId).get();
      final services = <Service>[];
      for (final doc in query.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        services.add(Service.fromMap(data));
      }
      return services;
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreServiceRepository.getServices error: $e\n$stack',
      );
      throw AppException('Failed to load services', cause: e);
    }
  }

  @override
  Stream<List<Service>> watchServices({String? businessId}) {
    return _withBusinessFilter(_servicesCol, businessId).snapshots().map((
      snapshot,
    ) {
      final services = <Service>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        services.add(Service.fromMap(data));
      }
      return services;
    });
  }

  @override
  Future<void> createService(Service service) async {
    try {
      final docRef = _servicesCol.doc();
      service.id = docRef.id;
      await docRef.set(service.toMap());
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreServiceRepository.createService error: $e\n$stack',
      );
      throw AppException('Failed to create service', cause: e);
    }
  }

  @override
  Future<void> updateService(Service service) async {
    try {
      if (service.id == null || service.id!.isEmpty) {
        throw const AppException('Service ID is required');
      }
      await _servicesCol.doc(service.id).update(service.toMap());
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreServiceRepository.updateService error: $e\n$stack',
      );
      if (e is AppException) rethrow;
      throw AppException('Failed to update service', cause: e);
    }
  }

  @override
  Future<void> deleteService(String id) async {
    try {
      if (id.isEmpty) {
        throw const AppException('Service ID is required');
      }
      await _servicesCol.doc(id).delete();
    } catch (e, stack) {
      AppLogger.error(
        'FirestoreServiceRepository.deleteService error: $e\n$stack',
      );
      if (e is AppException) rethrow;
      throw AppException('Failed to delete service', cause: e);
    }
  }
}
