import 'package:flutter/material.dart';

import '../models/service.dart';
import '../repositories/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  ServiceProvider({required ServiceRepository repository}) : _repository = repository;

  Stream<List<Service>> streamServices({String? businessId}) {
    final effectiveBusinessId =
        (businessId?.isEmpty ?? true) ? null : businessId;

    return _repository.watchServices(businessId: effectiveBusinessId);
  }

  static String getCategoryForService(String serviceName, {List<Service>? services}) {
    if (services != null) {
      for (final service in services) {
        if (service.name == serviceName) return service.category ?? serviceName;
        if (service.subtypes != null && service.subtypes!.contains(serviceName)) {
          return service.category ?? service.name;
        }
      }
    }
    return serviceName;
  }

  Stream<List<Service>> streamServicesForProfessional({String? businessId, String? professionalId}) {
    return streamServices(businessId: businessId).map((services) {
      if (professionalId == null || professionalId.isEmpty) return services;
      return services.where((s) => s.isOfferedBy(professionalId)).toList();
    });
  }
}
