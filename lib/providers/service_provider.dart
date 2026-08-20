import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../models/service.dart';
import '../repositories/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceRepository _repository;

  ServiceProvider({required ServiceRepository repository}) : _repository = repository;

  static const List<String> _defaultServiceNames = [
    'Massage',
    'Haircut',
    'Spa',
    'Facial',
  ];

  static List<Service> get defaultServices {
    return _defaultServiceNames.map((name) {
      return Service(
        name: name,
        description: serviceDescriptions[name],
        subtypes: serviceTypes[name],
      );
    }).toList();
  }

  Stream<List<Service>> streamServices({String? businessId}) {
    final effectiveBusinessId =
        (businessId?.isEmpty ?? true) ? null : businessId;

    return _repository.watchServices(businessId: effectiveBusinessId).map((services) {
      return services.isEmpty ? defaultServices : services;
    });
  }

  static String getCategoryForService(String serviceName) {
    for (final service in defaultServices) {
      if (service.name == serviceName) return serviceName;
      if (service.subtypes != null && service.subtypes!.contains(serviceName)) {
        return service.name;
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
