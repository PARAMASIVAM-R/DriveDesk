import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/entity_list_notifier.dart';
import '../data/mock_student_repository.dart';
import '../domain/student.dart';

final studentsProvider = AsyncNotifierProvider<StudentsNotifier, List<Student>>(
  StudentsNotifier.new,
);

class StudentsNotifier extends EntityListNotifier<Student> {
  @override
  String idOf(Student entity) => entity.id;

  @override
  Future<List<Student>> build() =>
      ref.watch(studentRepositoryProvider).fetchStudents();

  Future<Student> save(Student student) async {
    final saved = await ref
        .read(studentRepositoryProvider)
        .saveStudent(student);
    upsertAll([saved]);
    return saved;
  }
}

final packagesProvider = FutureProvider<List<CoursePackage>>(
  (ref) => ref.watch(studentRepositoryProvider).fetchPackages(),
);

final studentByIdProvider = Provider.family<Student?, String>((ref, id) {
  final students = ref.watch(studentsProvider).value ?? const [];
  return students.where((s) => s.id == id).firstOrNull;
});

final studentNameProvider = Provider.family<String, String>(
  (ref, id) =>
      ref.watch(studentByIdProvider(id))?.fullName ?? 'Unknown student',
);

final packageByIdProvider = Provider.family<CoursePackage?, String>((ref, id) {
  final packages = ref.watch(packagesProvider).value ?? const [];
  return packages.where((p) => p.id == id).firstOrNull;
});

class StudentFilter {
  const StudentFilter({this.query = '', this.status});

  final String query;
  final StudentStatus? status;
}

final studentFilterProvider =
    NotifierProvider<StudentFilterNotifier, StudentFilter>(
      StudentFilterNotifier.new,
    );

class StudentFilterNotifier extends Notifier<StudentFilter> {
  @override
  StudentFilter build() => const StudentFilter();

  void setQuery(String query) =>
      state = StudentFilter(query: query, status: state.status);

  void setStatus(StudentStatus? status) =>
      state = StudentFilter(query: state.query, status: status);
}

/// Students matching the search box (name or phone) and status filter.
final filteredStudentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final filter = ref.watch(studentFilterProvider);
  final q = filter.query.trim().toLowerCase();
  final qDigits = q.replaceAll(RegExp(r'\D'), '');
  return ref.watch(studentsProvider).whenData((students) {
    final list = students.where((s) {
      if (filter.status != null && s.status != filter.status) return false;
      if (q.isEmpty) return true;
      return s.fullName.toLowerCase().contains(q) ||
          (qDigits.isNotEmpty && s.phone.contains(qDigits));
    }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));
    return list;
  });
});
