class Location {
  final String? id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;

  Location({
    this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.isActive = true,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'isActive': isActive,
    };
  }

  Location copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
    );
  }
}
