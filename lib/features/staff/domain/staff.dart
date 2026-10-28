enum StaffRole {
  owner('Owner'),
  officeStaff('Office staff'),
  instructor('Instructor');

  const StaffRole(this.label);
  final String label;
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.phone,
    required this.role,
  });

  final String id;
  final String schoolId;
  final String name;
  final String phone;
  final StaffRole role;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'name': name,
    'phone': phone,
    'role': role.name,
  };

  factory StaffMember.fromJson(Map<String, Object?> json) => StaffMember(
    id: json['id'] as String,
    schoolId: json['schoolId'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    role: StaffRole.values.byName(json['role'] as String),
  );
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.schoolId,
    required this.registration,
    required this.model,
    required this.transmission,
  });

  final String id;
  final String schoolId;
  final String registration;
  final String model;
  final String transmission;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'registration': registration,
    'model': model,
    'transmission': transmission,
  };

  factory Vehicle.fromJson(Map<String, Object?> json) => Vehicle(
    id: json['id'] as String,
    schoolId: json['schoolId'] as String,
    registration: json['registration'] as String,
    model: json['model'] as String,
    transmission: json['transmission'] as String,
  );

  String get label => '$model · $registration';
}
