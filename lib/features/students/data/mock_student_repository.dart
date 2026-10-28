import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/student.dart';
import '../domain/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => MockStudentRepository(watchPersistedDatabase(ref)),
);

class MockStudentRepository implements StudentRepository {
  MockStudentRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Student>> fetchStudents() async => _db.students.values.toList();

  @override
  Future<List<CoursePackage>> fetchPackages() async =>
      _db.packages.values.toList();

  @override
  Future<Student> saveStudent(Student student) async {
    _db.students[student.id] = student;
    _db.markDirty();
    return student;
  }
}
