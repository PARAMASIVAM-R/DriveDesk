import 'student.dart';

abstract interface class StudentRepository {
  Future<List<Student>> fetchStudents();
  Future<List<CoursePackage>> fetchPackages();
  Future<Student> saveStudent(Student student);
}
