import 'licence.dart';

abstract interface class LicenceRepository {
  Future<List<LicenceRecord>> fetchLicences();
  Future<LicenceRecord> saveLicence(LicenceRecord record);
  Future<List<DrivingTest>> fetchTests();
  Future<void> saveTests(List<DrivingTest> tests);
}
