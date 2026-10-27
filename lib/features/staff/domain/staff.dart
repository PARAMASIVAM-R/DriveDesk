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

  String get label => '$model · $registration';
}
