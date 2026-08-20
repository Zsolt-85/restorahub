class Service {
  String? id;
  String name;
  String? description;
  String? businessId;
  int? durationMinutes;
  double? price;
  List<String>? subtypes;
  List<String> assignedProfessionalIds;

  Service({
    this.id,
    required this.name,
    this.description,
    this.businessId,
    this.durationMinutes,
    this.price,
    this.subtypes,
    this.assignedProfessionalIds = const [],
  });

  bool isOfferedBy(String professionalId) =>
      assignedProfessionalIds.isEmpty ||
      assignedProfessionalIds.contains(professionalId);

  factory Service.fromMap(Map<String, dynamic> map) {
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
    );
  }
}
