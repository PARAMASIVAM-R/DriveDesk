import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/providers/entity_list_notifier.dart';
import '../../auth/presentation/session_provider.dart';
import '../data/mock_lesson_repository.dart';
import '../domain/lesson.dart';
import '../domain/lesson_rules.dart';

final lessonsProvider = AsyncNotifierProvider<LessonsNotifier, List<Lesson>>(
  LessonsNotifier.new,
);

class LessonsNotifier extends EntityListNotifier<Lesson> {
  @override
  String idOf(Lesson entity) => entity.id;

  @override
  Future<List<Lesson>> build() =>
      ref.watch(lessonRepositoryProvider).fetchLessons();

  Future<void> _persist(List<Lesson> lessons) async {
    await ref.read(lessonRepositoryProvider).saveLessons(lessons);
    upsertAll(lessons);
  }

  /// Creates a new scheduled lesson after overlap validation.
  Future<Lesson> schedule({
    required String studentId,
    required DateTime start,
    required DateTime end,
    String? instructorId,
    String? vehicleId,
    String notes = '',
  }) async {
    final lesson = Lesson(
      id: newId('les'),
      schoolId: demoSchoolId,
      studentId: studentId,
      start: start,
      end: end,
      instructorId: instructorId,
      vehicleId: vehicleId,
      status: LessonStatus.scheduled,
      notes: notes,
    );
    LessonRules.validate(lesson, await current());
    await _persist([lesson]);
    return lesson;
  }

  /// Edits instructor/vehicle/notes of a lesson that is still scheduled.
  Future<void> updateAssignment(
    Lesson lesson, {
    String? instructorId,
    String? vehicleId,
    required String notes,
  }) async {
    LessonRules.ensureCanReschedule(lesson);
    final updated = lesson.copyWith(
      instructorId: () => instructorId,
      vehicleId: () => vehicleId,
      notes: notes,
    );
    LessonRules.validate(updated, await current());
    await _persist([updated]);
  }

  /// Moves a lesson by cancelling the original (kept for history) and
  /// creating a linked replacement.
  Future<Lesson> reschedule(
    Lesson original, {
    required DateTime start,
    required DateTime end,
    String? instructorId,
    String? vehicleId,
    String reason = '',
  }) async {
    LessonRules.ensureCanReschedule(original);
    final replacement = Lesson(
      id: newId('les'),
      schoolId: original.schoolId,
      studentId: original.studentId,
      start: start,
      end: end,
      instructorId: instructorId,
      vehicleId: vehicleId,
      status: LessonStatus.scheduled,
      notes: original.notes,
      rescheduledFromId: original.id,
    );
    final others = (await current()).where((l) => l.id != original.id);
    LessonRules.validate(replacement, others);
    final note =
        'Rescheduled to ${formatShortDate(start)} ${formatTime(start)}'
        '${reason.isEmpty ? '' : ' — $reason'}';
    await _persist([
      original.copyWith(
        status: LessonStatus.cancelled,
        rescheduledToId: replacement.id,
        notes: original.notes.isEmpty ? note : '${original.notes}\n$note',
      ),
      replacement,
    ]);
    return replacement;
  }

  /// Records attendance (completed / missed) or a cancellation. Callers
  /// must confirm with the user first.
  Future<void> setStatus(Lesson lesson, LessonStatus status, {String? note}) {
    LessonRules.ensureCanChangeStatus(lesson, status);
    final notes = (note == null || note.isEmpty)
        ? lesson.notes
        : (lesson.notes.isEmpty ? note : '${lesson.notes}\n$note');
    return _persist([lesson.copyWith(status: status, notes: notes)]);
  }
}

final lessonByIdProvider = Provider.family<Lesson?, String>((ref, id) {
  final lessons = ref.watch(lessonsProvider).value ?? const [];
  return lessons.where((l) => l.id == id).firstOrNull;
});

/// All lessons of a student, newest first.
final lessonsForStudentProvider = Provider.family<List<Lesson>, String>((
  ref,
  studentId,
) {
  final lessons = ref.watch(lessonsProvider).value ?? const [];
  return lessons.where((l) => l.studentId == studentId).toList()
    ..sort((a, b) => b.start.compareTo(a.start));
});

/// Lessons on a calendar day, by start time.
final lessonsOnDayProvider = Provider.family<List<Lesson>, DateTime>((
  ref,
  day,
) {
  final lessons = ref.watch(lessonsProvider).value ?? const [];
  return lessons.where((l) => isSameDay(l.start, day)).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
});

final rescheduleRequestsProvider =
    AsyncNotifierProvider<RescheduleRequestsNotifier, List<RescheduleRequest>>(
      RescheduleRequestsNotifier.new,
    );

class RescheduleRequestsNotifier extends EntityListNotifier<RescheduleRequest> {
  @override
  String idOf(RescheduleRequest entity) => entity.id;

  @override
  Future<List<RescheduleRequest>> build() =>
      ref.watch(lessonRepositoryProvider).fetchRequests();

  Future<void> _save(RescheduleRequest request) async {
    upsertAll([await ref.read(lessonRepositoryProvider).saveRequest(request)]);
  }

  /// Student-initiated request. The lesson is untouched until staff approve.
  Future<void> submit({
    required Lesson lesson,
    required DateTime preferredStart,
    required String reason,
  }) async {
    final studentId = ref.read(currentStudentIdProvider);
    if (studentId == null || studentId != lesson.studentId) {
      throw const AppException(
        'You can only request changes to your own classes.',
      );
    }
    LessonRules.ensureCanReschedule(lesson);
    final pending = (await current()).any(
      (r) =>
          r.lessonId == lesson.id &&
          r.status == RescheduleRequestStatus.pending,
    );
    if (pending) {
      throw const AppException('A request for this class is already pending.');
    }
    if (!preferredStart.isAfter(ref.read(clockProvider)())) {
      throw const AppException('Please choose a future date and time.');
    }
    await _save(
      RescheduleRequest(
        id: newId('req'),
        schoolId: lesson.schoolId,
        studentId: studentId,
        lessonId: lesson.id,
        preferredStart: preferredStart,
        reason: reason,
        createdAt: ref.read(clockProvider)(),
      ),
    );
  }

  /// Staff approval: reschedules the lesson to the requested time, keeping
  /// the same duration, instructor and vehicle.
  Future<void> approve(RescheduleRequest request) async {
    final lesson = ref.read(lessonByIdProvider(request.lessonId));
    if (lesson == null) throw const AppException('Lesson not found.');
    final duration = lesson.end.difference(lesson.start);
    await ref
        .read(lessonsProvider.notifier)
        .reschedule(
          lesson,
          start: request.preferredStart,
          end: request.preferredStart.add(duration),
          instructorId: lesson.instructorId,
          vehicleId: lesson.vehicleId,
          reason: 'student request',
        );
    await _save(request.copyWith(status: RescheduleRequestStatus.approved));
  }

  Future<void> decline(RescheduleRequest request) =>
      _save(request.copyWith(status: RescheduleRequestStatus.declined));
}

final pendingRequestsProvider = Provider<List<RescheduleRequest>>(
  (ref) => [
    ...?ref
        .watch(rescheduleRequestsProvider)
        .value
        ?.where((r) => r.status == RescheduleRequestStatus.pending),
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
);
