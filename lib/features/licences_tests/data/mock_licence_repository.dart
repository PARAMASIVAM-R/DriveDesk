import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/licence.dart';
import '../domain/licence_repository.dart';

final licenceRepositoryProvider = Provider<LicenceRepository>(
  (ref) => MockLicenceRepository(watchPersistedDatabase(ref)),
);

class MockLicenceRepository implements LicenceRepository {
  MockLicenceRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<LicenceRecord>> fetchLicences() async =>
      _db.licences.values.toList();

  @override
  Future<LicenceRecord> saveLicence(LicenceRecord record) async {
    _db.licences[record.id] = record;
    _db.markDirty();
    return record;
  }

  @override
  Future<List<DrivingTest>> fetchTests() async => _db.tests.values.toList();

  @override
  Future<void> saveTests(List<DrivingTest> tests) async {
    for (final t in tests) {
      _db.tests[t.id] = t;
    }
    _db.markDirty();
  }
}
