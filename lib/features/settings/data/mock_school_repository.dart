import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../../staff/domain/staff.dart';
import '../domain/school.dart';
import '../domain/school_repository.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>(
  (ref) => MockSchoolRepository(ref.watch(mockDatabaseProvider)),
);

class MockSchoolRepository implements SchoolRepository {
  MockSchoolRepository(this._db);

  final MockDatabase _db;

  @override
  Future<School> fetchSchool() async => _db.school;

  @override
  Future<School> saveSchool(School school) async => _db.school = school;

  @override
  Future<List<StaffMember>> fetchStaff() async => _db.staff.values.toList();

  @override
  Future<List<Vehicle>> fetchVehicles() async => _db.vehicles.values.toList();
}
