import '../../staff/domain/staff.dart';
import 'school.dart';

abstract interface class SchoolRepository {
  Future<School> fetchSchool();
  Future<School> saveSchool(School school);
  Future<List<StaffMember>> fetchStaff();
  Future<List<Vehicle>> fetchVehicles();
}
