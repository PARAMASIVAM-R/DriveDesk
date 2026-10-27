class School {
  const School({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.licenceNumber,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String licenceNumber;

  School copyWith({
    String? name,
    String? address,
    String? phone,
    String? licenceNumber,
  }) {
    return School(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      licenceNumber: licenceNumber ?? this.licenceNumber,
    );
  }
}
