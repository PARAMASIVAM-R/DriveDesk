import 'lesson.dart';

abstract interface class LessonRepository {
  Future<List<Lesson>> fetchLessons();

  /// Saves several lessons together (e.g. an original and its rescheduled
  /// replacement).
  Future<void> saveLessons(List<Lesson> lessons);
  Future<List<RescheduleRequest>> fetchRequests();
  Future<RescheduleRequest> saveRequest(RescheduleRequest request);
}
