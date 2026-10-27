import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_database.dart';

/// Current time source. Override in tests for deterministic dates.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// In-memory store backing every mock repository for this session.
/// Swap the repository providers (not this) for API-backed versions later.
final mockDatabaseProvider = Provider<MockDatabase>(
  (ref) => MockDatabase.seeded(ref.watch(clockProvider)()),
);

/// The school the app is operating on. Centralised so a future backend can
/// enforce tenant boundaries from a single place.
const demoSchoolId = 'sch_001';
