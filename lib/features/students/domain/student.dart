import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

enum StudentStatus {
  enquiry('Enquiry', AppColors.info),
  active('Active', AppColors.success),
  onHold('On hold', AppColors.warning),
  completed('Completed', AppColors.neutral),
  cancelled('Cancelled', AppColors.danger);

  const StudentStatus(this.label, this.color);
  final String label;
  final Color color;
}

class CoursePackage {
  const CoursePackage({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.fee,
    required this.lessonCount,
  });

  final String id;
  final String schoolId;
  final String name;
  final double fee;
  final int lessonCount;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'name': name,
    'fee': fee,
    'lessonCount': lessonCount,
  };

  factory CoursePackage.fromJson(Map<String, Object?> json) => CoursePackage(
    id: json['id'] as String,
    schoolId: json['schoolId'] as String,
    name: json['name'] as String,
    fee: (json['fee'] as num).toDouble(),
    lessonCount: (json['lessonCount'] as num).toInt(),
  );
}

class Student {
  const Student({
    required this.id,
    required this.schoolId,
    required this.fullName,
    required this.phone,
    required this.enrolmentDate,
    required this.packageId,
    required this.agreedFee,
    required this.status,
    this.address = '',
    this.dateOfBirth,
    this.notes = '',
  });

  final String id;
  final String schoolId;
  final String fullName;
  final String phone;
  final String address;
  final DateTime? dateOfBirth;
  final DateTime enrolmentDate;
  final String packageId;

  /// Fee agreed at enrolment. Payments are stored separately.
  final double agreedFee;
  final StudentStatus status;
  final String notes;

  Map<String, Object?> toJson() => {
    'id': id,
    'schoolId': schoolId,
    'fullName': fullName,
    'phone': phone,
    'address': address,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'enrolmentDate': enrolmentDate.toIso8601String(),
    'packageId': packageId,
    'agreedFee': agreedFee,
    'status': status.name,
    'notes': notes,
  };

  factory Student.fromJson(Map<String, Object?> json) {
    final dob = json['dateOfBirth'] as String?;
    return Student(
      id: json['id'] as String,
      schoolId: json['schoolId'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String? ?? '',
      dateOfBirth: dob == null ? null : DateTime.parse(dob),
      enrolmentDate: DateTime.parse(json['enrolmentDate'] as String),
      packageId: json['packageId'] as String,
      agreedFee: (json['agreedFee'] as num).toDouble(),
      status: StudentStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String? ?? '',
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }

  Student copyWith({
    String? fullName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    DateTime? enrolmentDate,
    String? packageId,
    double? agreedFee,
    StudentStatus? status,
    String? notes,
  }) {
    return Student(
      id: id,
      schoolId: schoolId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      enrolmentDate: enrolmentDate ?? this.enrolmentDate,
      packageId: packageId ?? this.packageId,
      agreedFee: agreedFee ?? this.agreedFee,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
