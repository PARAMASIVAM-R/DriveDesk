import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

enum ReminderType {
  classUpcoming('Class', Icons.directions_car_outlined),
  llrExpiry('LLR expiry', Icons.badge_outlined),
  drivingTest('Driving test', Icons.fact_check_outlined),
  installmentDue('Installment due', Icons.payments_outlined),
  installmentOverdue('Installment overdue', Icons.money_off_outlined),
  classChanged('Class changed', Icons.event_busy_outlined);

  const ReminderType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum Urgency {
  high('High', AppColors.danger),
  medium('Medium', AppColors.warning),
  low('Low', AppColors.info);

  const Urgency(this.label, this.color);
  final String label;
  final Color color;
}

/// Manual/demo state only — nothing is ever delivered automatically.
enum ReminderStatus {
  draft('Draft', AppColors.neutral),
  readyToSend('Ready to send', AppColors.info),
  markedSent('Marked sent', AppColors.success);

  const ReminderStatus(this.label, this.color);
  final String label;
  final Color color;
}

class Reminder {
  const Reminder({
    required this.id,
    required this.studentId,
    required this.type,
    required this.dueAt,
    required this.urgency,
    required this.title,
    required this.message,
    required this.recipientName,
    required this.recipientPhone,
    this.status = ReminderStatus.draft,
  });

  /// Deterministic ID derived from the source record, so a status recorded
  /// by staff survives regeneration.
  final String id;
  final String studentId;
  final ReminderType type;
  final DateTime dueAt;
  final Urgency urgency;
  final String title;

  /// WhatsApp-ready message text for preview.
  final String message;
  final String recipientName;
  final String recipientPhone;
  final ReminderStatus status;

  Reminder withStatus(ReminderStatus status) => Reminder(
    id: id,
    studentId: studentId,
    type: type,
    dueAt: dueAt,
    urgency: urgency,
    title: title,
    message: message,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
    status: status,
  );
}
