import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../settings/presentation/school_providers.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/lesson.dart';

class LessonTile extends ConsumerWidget {
  const LessonTile({
    super.key,
    required this.lesson,
    this.showStudent = true,
    this.showDate = false,
    this.onTap,
  });

  final Lesson lesson;
  final bool showStudent;
  final bool showDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructor = ref.watch(instructorNameProvider(lesson.instructorId));
    final vehicle = ref.watch(vehicleLabelProvider(lesson.vehicleId));
    final title = showStudent
        ? ref.watch(studentNameProvider(lesson.studentId))
        : formatShortDate(lesson.start);
    final when = showDate && showStudent
        ? '${formatShortDate(lesson.start)} · ${formatTimeRange(lesson.start, lesson.end)}'
        : formatTimeRange(lesson.start, lesson.end);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: lesson.status.color.withValues(alpha: 0.12),
        child: Icon(Icons.directions_car_outlined, color: lesson.status.color),
      ),
      title: Text(title),
      subtitle: Text('$when\n$instructor · $vehicle'),
      isThreeLine: true,
      trailing: StatusChip(
        label: lesson.rescheduledToId != null ? 'Moved' : lesson.status.label,
        color: lesson.status.color,
      ),
    );
  }
}
