import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/mock_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/lesson.dart';
import '../domain/lesson_repository.dart';

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => MockLessonRepository(watchPersistedDatabase(ref)),
);

class MockLessonRepository implements LessonRepository {
  MockLessonRepository(this._db);

  final MockDatabase _db;

  @override
  Future<List<Lesson>> fetchLessons() async => _db.lessons.values.toList();

  @override
  Future<void> saveLessons(List<Lesson> lessons) async {
    for (final l in lessons) {
      _db.lessons[l.id] = l;
    }
    _db.markDirty();
  }

  @override
  Future<List<RescheduleRequest>> fetchRequests() async =>
      _db.rescheduleRequests.values.toList();

  @override
  Future<RescheduleRequest> saveRequest(RescheduleRequest request) async {
    _db.rescheduleRequests[request.id] = request;
    _db.markDirty();
    return request;
  }
}
