enum ResourceType { staff, equipment, room }

class Service {
  String? id;
  String name;
  String? description;
  String? businessId;
  int? durationMinutes;
  double? price;
  List<String>? subtypes;
  List<String> assignedProfessionalIds;
  String? category;
  ResourceType? resourceType;
  List<String> locationIds;
  int? bufferTimeMinutes;
  int? preparationTimeMinutes;

  Service({
    this.id,
    required this.name,
    this.description,
    this.businessId,
    this.durationMinutes,
    this.price,
    this.subtypes,
    this.assignedProfessionalIds = const [],
    this.category,
    this.resourceType,
    this.locationIds = const [],
    this.bufferTimeMinutes,
    this.preparationTimeMinutes,
  });

  bool isOfferedBy(String professionalId) =>
      assignedProfessionalIds.isEmpty ||
      assignedProfessionalIds.contains(professionalId);

  bool isAvailableAt(String locationId) =>
      locationIds.isEmpty || locationIds.contains(locationId);

  int get totalDurationMinutes =>
      (durationMinutes ?? 0) + (bufferTimeMinutes ?? 0) + (preparationTimeMinutes ?? 0);

  factory Service.fromMap(Map<String, dynamic> map) {
    ResourceType? parsedResourceType;
    final resourceTypeRaw = map['resourceType']?.toString();
    if (resourceTypeRaw != null && resourceTypeRaw.isNotEmpty) {
      for (final type in ResourceType.values) {
        if (type.name == resourceTypeRaw) {
          parsedResourceType = type;
          break;
        }
      }
    }

    return Service(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      businessId: map['businessId']?.toString(),
      durationMinutes: map['durationMinutes'] is int ? map['durationMinutes'] as int : int.tryParse(map['durationMinutes']?.toString() ?? ''),
      price: map['price'] != null ? (map['price'] is double ? map['price'] as double : double.tryParse(map['price'].toString())) : null,
      subtypes: map['subtypes'] != null
          ? List<String>.from(
              (map['subtypes'] as List<dynamic>).map((e) => e.toString()),
            )
          : null,
      assignedProfessionalIds: map['assignedProfessionalIds'] != null
          ? List<String>.from(
              (map['assignedProfessionalIds'] as List<dynamic>).map((e) => e.toString()),
            )
          : const [],
      category: map['category']?.toString(),
      resourceType: parsedResourceType,
      locationIds: map['locationIds'] != null
          ? List<String>.from(
              (map['locationIds'] as List<dynamic>).map((e) => e.toString()),
            )
          : const [],
      bufferTimeMinutes: map['bufferTimeMinutes'] as int?,
      preparationTimeMinutes: map['preparationTimeMinutes'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'businessId': businessId,
      'durationMinutes': durationMinutes != null ? durationMinutes as int : null,
      'price': price != null ? price as double : null,
      'subtypes': subtypes,
      'assignedProfessionalIds': assignedProfessionalIds,
      'category': category,
      'resourceType': resourceType?.name,
      'locationIds': locationIds,
      'bufferTimeMinutes': bufferTimeMinutes,
      'preparationTimeMinutes': preparationTimeMinutes,
    };
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    String? businessId,
    int? durationMinutes,
    double? price,
    List<String>? subtypes,
    List<String>? assignedProfessionalIds,
    String? category,
    ResourceType? resourceType,
    List<String>? locationIds,
    int? bufferTimeMinutes,
    int? preparationTimeMinutes,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessId: businessId ?? this.businessId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      subtypes: subtypes ?? this.subtypes,
      assignedProfessionalIds: assignedProfessionalIds ?? this.assignedProfessionalIds,
      category: category ?? this.category,
      resourceType: resourceType ?? this.resourceType,
      locationIds: locationIds ?? this.locationIds,
      bufferTimeMinutes: bufferTimeMinutes ?? this.bufferTimeMinutes,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
    );
  }
}
