import '../../../core/errors/app_exception.dart';
import 'lesson.dart';

/// Business rules for lessons, kept free of UI and storage concerns.
abstract final class LessonRules {
  /// Throws [AppException] when [candidate] is invalid or clashes with an
  /// existing scheduled/completed lesson for the same student, instructor
  /// or vehicle.
  static void validate(Lesson candidate, Iterable<Lesson> existing) {
    if (!candidate.end.isAfter(candidate.start)) {
      throw const AppException('End time must be after start time.');
    }
    for (final other in existing) {
      if (other.id == candidate.id) continue;
      if (other.status == LessonStatus.cancelled ||
          other.status == LessonStatus.missed) {
        continue;
      }
      if (!candidate.overlaps(other)) continue;

      if (other.studentId == candidate.studentId) {
        throw const AppException(
          'This student already has a lesson at that time.',
        );
      }
      if (candidate.instructorId != null &&
          candidate.instructorId == other.instructorId) {
        throw const AppException(
          'The instructor is already booked for an overlapping lesson.',
        );
      }
      if (candidate.vehicleId != null &&
          candidate.vehicleId == other.vehicleId) {
        throw const AppException(
          'The vehicle is already booked for an overlapping lesson.',
        );
      }
    }
  }

  /// Only scheduled lessons can be moved; completed history is preserved.
  static void ensureCanReschedule(Lesson lesson) {
    if (lesson.status != LessonStatus.scheduled) {
      throw AppException(
        'A ${lesson.status.label.toLowerCase()} lesson cannot be rescheduled.',
      );
    }
  }

  static void ensureCanChangeStatus(Lesson lesson, LessonStatus next) {
    if (lesson.status != LessonStatus.scheduled) {
      throw AppException(
        'This lesson is already ${lesson.status.label.toLowerCase()}.',
      );
    }
    if (next == LessonStatus.scheduled) {
      throw const AppException('Lesson is already scheduled.');
    }
  }
}
