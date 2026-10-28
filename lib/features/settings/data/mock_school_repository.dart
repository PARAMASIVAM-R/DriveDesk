import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../../staff/domain/staff.dart';
import '../domain/school.dart';
import '../domain/school_repository.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>(
  (ref) => MockSchoolRepository(watchPersistedDatabase(ref)),
);

class MockSchoolRepository implements SchoolRepository {
  MockSchoolRepository(this._db);

  final MockDatabase _db;

  @override
  Future<School> fetchSchool() async => _db.school;

  @override
  Future<School> saveSchool(School school) async {
    _db.school = school;
    _db.markDirty();
    return school;
  }

  @override
  Future<List<StaffMember>> fetchStaff() async => _db.staff.values.toList();

  @override
  Future<List<Vehicle>> fetchVehicles() async => _db.vehicles.values.toList();

  @override
  Future<StaffMember> saveStaff(StaffMember member) async {
    _db.staff[member.id] = member;
    _db.markDirty();
    return member;
  }

  @override
  Future<Vehicle> saveVehicle(Vehicle vehicle) async {
    _db.vehicles[vehicle.id] = vehicle;
    _db.markDirty();
    return vehicle;
  }
}
