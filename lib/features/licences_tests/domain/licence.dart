import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Learner's licence (LLR) record. Dates may be unknown.
class LicenceRecord {
  const LicenceRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    this.llrNumber,
    this.issueDate,
    this.expiryDate,
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String? llrNumber;
  final DateTime? issueDate;
  final DateTime? expiryDate;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'studentId': studentId,
    'llrNumber': llrNumber,
    'issueDate': issueDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
  };

  factory LicenceRecord.fromJson(Map<String, Object?> json) {
    final issued = json['issueDate'] as String?;
    final expires = json['expiryDate'] as String?;
    return LicenceRecord(
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      studentId: json['studentId'] as String,
      llrNumber: json['llrNumber'] as String?,
      issueDate: issued == null ? null : DateTime.parse(issued),
      expiryDate: expires == null ? null : DateTime.parse(expires),
    );
  }

  LicenceRecord copyWith({
    String? Function()? llrNumber,
    DateTime? Function()? issueDate,
    DateTime? Function()? expiryDate,
  }) {
    return LicenceRecord(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      llrNumber: llrNumber != null ? llrNumber() : this.llrNumber,
      issueDate: issueDate != null ? issueDate() : this.issueDate,
      expiryDate: expiryDate != null ? expiryDate() : this.expiryDate,
    );
  }
}

enum LlrState {
  none('No LLR recorded', AppColors.neutral),
  unknownExpiry('Expiry unknown', AppColors.neutral),
  valid('Valid', AppColors.success),
  expiringSoon('Expiring soon', AppColors.warning),
  expired('Expired', AppColors.danger);

  const LlrState(this.label, this.color);
  final String label;
  final Color color;
}

/// Days before expiry at which an LLR is flagged.
const llrWarningDays = 30;

LlrState llrStateOf(LicenceRecord? record, DateTime today) {
  if (record == null) return LlrState.none;
  final expiry = record.expiryDate;
  if (expiry == null) return LlrState.unknownExpiry;
  final days = daysBetween(today, expiry);
  if (days < 0) return LlrState.expired;
  if (days <= llrWarningDays) return LlrState.expiringSoon;
  return LlrState.valid;
}

enum TestStatus {
  notScheduled('Not scheduled', AppColors.neutral),
  scheduled('Scheduled', AppColors.info),
  passed('Passed', AppColors.success),
  failed('Failed', AppColors.danger),
  rescheduled('Rescheduled', AppColors.warning);

  const TestStatus(this.label, this.color);
  final String label;
  final Color color;
}

/// One driving-test attempt. A rescheduled or failed attempt is kept and a
/// new attempt is created, so history is never overwritten.
class DrivingTest {
  const DrivingTest({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.attempt,
    required this.status,
    this.scheduledAt,
    this.location = '',
    this.notes = '',
  });

  final String id;
  final String schoolId;
  final String studentId;
  final int attempt;
  final DateTime? scheduledAt;
  final String location;
  final TestStatus status;
  final String notes;

  bool get isOpen =>
      status == TestStatus.scheduled || status == TestStatus.notScheduled;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'studentId': studentId,
    'attempt': attempt,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'location': location,
    'status': status.name,
    'notes': notes,
  };

  factory DrivingTest.fromJson(Map<String, Object?> json) {
    final at = json['scheduledAt'] as String?;
    return DrivingTest(
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      studentId: json['studentId'] as String,
      attempt: (json['attempt'] as num).toInt(),
      scheduledAt: at == null ? null : DateTime.parse(at),
      location: json['location'] as String? ?? '',
      status: TestStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }

  DrivingTest copyWith({
    TestStatus? status,
    DateTime? scheduledAt,
    String? location,
    String? notes,
  }) {
    return DrivingTest(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      attempt: attempt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
