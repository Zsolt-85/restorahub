class Service {
  String? id;
  String name;
  String? description;
  String? businessId;
  int? durationMinutes;
  double? price;
  List<String>? subtypes;

  Service({
    this.id,
    required this.name,
    this.description,
    this.businessId,
    this.durationMinutes,
    this.price,
    this.subtypes,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      businessId: map['businessId']?.toString(),
      durationMinutes: map['durationMinutes'] as int?,
      price: map['price'] != null ? double.tryParse(map['price'].toString()) : null,
      subtypes: map['subtypes'] != null
          ? List<String>.from(
              (map['subtypes'] as List<dynamic>).map((e) => e.toString()),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'businessId': businessId,
      'durationMinutes': durationMinutes,
      'price': price,
      'subtypes': subtypes,
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
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessId: businessId ?? this.businessId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      subtypes: subtypes ?? this.subtypes,
    );
  }
}
