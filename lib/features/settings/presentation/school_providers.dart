import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../staff/domain/staff.dart';
import '../data/mock_school_repository.dart';
import '../domain/school.dart';

final schoolProvider = AsyncNotifierProvider<SchoolNotifier, School>(
  SchoolNotifier.new,
);

class SchoolNotifier extends AsyncNotifier<School> {
  @override
  Future<School> build() => ref.watch(schoolRepositoryProvider).fetchSchool();

  Future<void> save(School school) async {
    state = AsyncData(
      await ref.read(schoolRepositoryProvider).saveSchool(school),
    );
  }
}

final staffProvider = FutureProvider<List<StaffMember>>(
  (ref) => ref.watch(schoolRepositoryProvider).fetchStaff(),
);

final instructorsProvider = Provider<List<StaffMember>>(
  (ref) => [
    ...?ref
        .watch(staffProvider)
        .value
        ?.where((s) => s.role == StaffRole.instructor),
  ],
);

final vehiclesProvider = FutureProvider<List<Vehicle>>(
  (ref) => ref.watch(schoolRepositoryProvider).fetchVehicles(),
);

/// Display name for an optional instructor ID.
final instructorNameProvider = Provider.family<String, String?>((ref, id) {
  if (id == null) return 'Unassigned';
  final staff = ref.watch(staffProvider).value ?? const [];
  return staff.where((s) => s.id == id).firstOrNull?.name ?? 'Unknown';
});

final vehicleLabelProvider = Provider.family<String, String?>((ref, id) {
  if (id == null) return 'Unassigned';
  final vehicles = ref.watch(vehiclesProvider).value ?? const [];
  return vehicles.where((v) => v.id == id).firstOrNull?.label ?? 'Unknown';
});
