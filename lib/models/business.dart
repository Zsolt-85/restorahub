class Business {
  final String id;
  final String name;
  final String? logoUrl;
  final String? primaryColorHex;
  final String? phone;
  final String? address;

  Business({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColorHex,
    this.phone,
    this.address,
  });

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      logoUrl: map['logoUrl']?.toString(),
      primaryColorHex: map['primaryColorHex']?.toString(),
      phone: map['phone']?.toString(),
      address: map['address']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'primaryColorHex': primaryColorHex,
      'phone': phone,
      'address': address,
    };
  }

  Business copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? primaryColorHex,
    String? phone,
    String? address,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
