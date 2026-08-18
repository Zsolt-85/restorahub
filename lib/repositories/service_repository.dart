import '../models/service.dart';

abstract class ServiceRepository {
  Future<List<Service>> getServices({String? businessId});
  Stream<List<Service>> watchServices({String? businessId});
  Future<void> createService(Service service);
  Future<void> updateService(Service service);
  Future<void> deleteService(String id);
}
