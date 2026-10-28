import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

enum LessonStatus {
  scheduled('Scheduled', AppColors.info),
  completed('Completed', AppColors.success),
  cancelled('Cancelled', AppColors.neutral),
  missed('Missed', AppColors.danger);

  const LessonStatus(this.label, this.color);
  final String label;
  final Color color;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.start,
    required this.end,
    required this.status,
    this.instructorId,
    this.vehicleId,
    this.notes = '',
    this.rescheduledFromId,
    this.rescheduledToId,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final DateTime start;
  final DateTime end;
  final String? instructorId;
  final String? vehicleId;
  final LessonStatus status;
  final String notes;

  /// Set on a lesson created by rescheduling another one.
  final String? rescheduledFromId;

  /// Set on the original lesson once it has been moved.
  final String? rescheduledToId;

  bool get isUpcoming => status == LessonStatus.scheduled;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'studentId': studentId,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'instructorId': instructorId,
    'vehicleId': vehicleId,
    'status': status.name,
    'notes': notes,
    'rescheduledFromId': rescheduledFromId,
    'rescheduledToId': rescheduledToId,
  };

  factory Lesson.fromJson(Map<String, Object?> json) => Lesson(
    id: json['id'] as String,
    schoolId: json['schoolId'] as String,
    studentId: json['studentId'] as String,
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    instructorId: json['instructorId'] as String?,
    vehicleId: json['vehicleId'] as String?,
    status: LessonStatus.values.byName(json['status'] as String),
    notes: json['notes'] as String? ?? '',
    rescheduledFromId: json['rescheduledFromId'] as String?,
    rescheduledToId: json['rescheduledToId'] as String?,
  );

  bool overlaps(Lesson other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  Lesson copyWith({
    DateTime? start,
    DateTime? end,
    LessonStatus? status,
    String? notes,
    String? rescheduledToId,
    String? Function()? instructorId,
    String? Function()? vehicleId,
  }) {
    return Lesson(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      start: start ?? this.start,
      end: end ?? this.end,
      instructorId: instructorId != null ? instructorId() : this.instructorId,
      vehicleId: vehicleId != null ? vehicleId() : this.vehicleId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      rescheduledFromId: rescheduledFromId,
      rescheduledToId: rescheduledToId ?? this.rescheduledToId,
    );
  }
}

enum RescheduleRequestStatus {
  pending('Pending', AppColors.warning),
  approved('Approved', AppColors.success),
  declined('Declined', AppColors.danger);

  const RescheduleRequestStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// A student's request to move a lesson. Staff must approve before the
/// lesson itself changes.
class RescheduleRequest {
  const RescheduleRequest({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.lessonId,
    required this.preferredStart,
    required this.reason,
    required this.createdAt,
    this.status = RescheduleRequestStatus.pending,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String lessonId;
  final DateTime preferredStart;
  final String reason;
  final DateTime createdAt;
  final RescheduleRequestStatus status;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'studentId': studentId,
    'lessonId': lessonId,
    'preferredStart': preferredStart.toIso8601String(),
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory RescheduleRequest.fromJson(Map<String, Object?> json) =>
      RescheduleRequest(
        id: json['id'] as String,
        schoolId: json['schoolId'] as String,
        studentId: json['studentId'] as String,
        lessonId: json['lessonId'] as String,
        preferredStart: DateTime.parse(json['preferredStart'] as String),
        reason: json['reason'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: RescheduleRequestStatus.values.byName(json['status'] as String),
      );

  RescheduleRequest copyWith({RescheduleRequestStatus? status}) {
    return RescheduleRequest(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      lessonId: lessonId,
      preferredStart: preferredStart,
      reason: reason,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
