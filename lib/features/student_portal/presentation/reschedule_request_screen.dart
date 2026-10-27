import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/presentation/session_provider.dart';
import '../../scheduling/presentation/lesson_providers.dart';

/// Student asks to move a class. Nothing changes until staff approve.
class RescheduleRequestScreen extends ConsumerStatefulWidget {
  const RescheduleRequestScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<RescheduleRequestScreen> createState() =>
      _RescheduleRequestScreenState();
}

class _RescheduleRequestScreenState
    extends ConsumerState<RescheduleRequestScreen> {
  final _reason = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final lesson = ref.read(lessonByIdProvider(widget.lessonId));
    final base = lesson?.start ?? ref.read(clockProvider)();
    _date = dateOnly(base).add(const Duration(days: 1));
    _time = TimeOfDay.fromDateTime(base);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(lessonByIdProvider(widget.lessonId));
    // Scope check: a student can only open their own lessons.
    if (lesson == null ||
        lesson.studentId != ref.watch(currentStudentIdProvider)) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Class not found',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Request class change')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current class'),
                Text(
                  '${formatShortDate(lesson.start)} · '
                  '${formatTimeRange(lesson.start, lesson.end)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SectionHeader('Preferred new time'),
          DateField(
            label: 'Date',
            value: _date,
            onTap: () async {
              final now = ref.read(clockProvider)();
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: dateOnly(now),
                lastDate: now.add(const Duration(days: 60)),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TimeField(
            label: 'Time',
            value: _time,
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (t != null) setState(() => _time = t);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The office will confirm. Your class stays at its current time '
            'until then.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    try {
                      await ref
                          .read(rescheduleRequestsProvider.notifier)
                          .submit(
                            lesson: lesson,
                            preferredStart: combine(_date, _time),
                            reason: _reason.text.trim(),
                          );
                      if (!context.mounted) return;
                      showMessage(context, 'Request sent to the office.');
                      context.pop();
                    } catch (e) {
                      if (!context.mounted) return;
                      showMessage(context, '$e', error: true);
                      setState(() => _saving = false);
                    }
                  },
            child: const Text('Send request'),
          ),
        ],
      ),
    );
  }
}
