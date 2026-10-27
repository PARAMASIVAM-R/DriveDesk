import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../settings/presentation/school_providers.dart';
import '../../students/domain/student.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/lesson.dart';
import 'lesson_providers.dart';

enum LessonFormMode { create, edit, reschedule }

/// One form for scheduling a new class, editing an assignment, or
/// rescheduling an existing class.
class LessonFormScreen extends ConsumerStatefulWidget {
  const LessonFormScreen({
    super.key,
    this.studentId,
    this.lessonId,
    this.mode = LessonFormMode.create,
  });

  final String? studentId;
  final String? lessonId;
  final LessonFormMode mode;

  @override
  ConsumerState<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends ConsumerState<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  final _reason = TextEditingController();
  Lesson? _original;
  String? _studentId;
  String? _instructorId;
  String? _vehicleId;
  late DateTime _date;
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  int _minutes = 60;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _studentId = widget.studentId;
    _date = dateOnly(ref.read(clockProvider)()).add(const Duration(days: 1));
    final id = widget.lessonId;
    if (id != null) {
      final l = ref.read(lessonByIdProvider(id));
      if (l != null) {
        _original = l;
        _studentId = l.studentId;
        _instructorId = l.instructorId;
        _vehicleId = l.vehicleId;
        _date = dateOnly(l.start);
        _start = TimeOfDay.fromDateTime(l.start);
        _minutes = l.end.difference(l.start).inMinutes;
        _notes.text = l.notes;
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final start = combine(_date, _start);
    final end = start.add(Duration(minutes: _minutes));
    if (widget.mode != LessonFormMode.edit &&
        start.isBefore(ref.read(clockProvider)())) {
      showMessage(context, 'Choose a time in the future.', error: true);
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(lessonsProvider.notifier);
    try {
      switch (widget.mode) {
        case LessonFormMode.create:
          await notifier.schedule(
            studentId: _studentId!,
            start: start,
            end: end,
            instructorId: _instructorId,
            vehicleId: _vehicleId,
            notes: _notes.text.trim(),
          );
        case LessonFormMode.edit:
          await notifier.updateAssignment(
            _original!,
            instructorId: _instructorId,
            vehicleId: _vehicleId,
            notes: _notes.text.trim(),
          );
        case LessonFormMode.reschedule:
          await notifier.reschedule(
            _original!,
            start: start,
            end: end,
            instructorId: _instructorId,
            vehicleId: _vehicleId,
            reason: _reason.text.trim(),
          );
      }
      if (!mounted) return;
      showMessage(context, switch (widget.mode) {
        LessonFormMode.create => 'Class scheduled.',
        LessonFormMode.edit => 'Class updated.',
        LessonFormMode.reschedule => 'Class rescheduled.',
      });
      context.pop();
    } catch (e) {
      if (mounted) {
        showMessage(context, '$e', error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final students =
        (ref.watch(studentsProvider).value ?? const <Student>[])
            .where(
              (s) => s.status == StudentStatus.active || s.id == _studentId,
            )
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final instructors = ref.watch(instructorsProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final timeLocked = mode == LessonFormMode.edit;

    if (widget.lessonId != null && _original == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.event_busy,
          title: 'Class not found',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (mode) {
          LessonFormMode.create => 'Schedule class',
          LessonFormMode.edit => 'Edit class',
          LessonFormMode.reschedule => 'Reschedule class',
        }),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            if (mode == LessonFormMode.reschedule)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Currently ${formatShortDate(_original!.start)} at '
                  '${formatTime(_original!.start)}. The original class is '
                  'kept in history as cancelled.',
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: _studentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Student *'),
              items: [
                for (final s in students)
                  DropdownMenuItem(value: s.id, child: Text(s.fullName)),
              ],
              onChanged: mode == LessonFormMode.create
                  ? (v) => setState(() => _studentId = v)
                  : null,
              validator: (v) => v == null ? 'Choose a student' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!timeLocked) ...[
              DateField(
                label: 'Date *',
                value: _date,
                onTap: () async {
                  final now = ref.read(clockProvider)();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date.isBefore(dateOnly(now)) ? now : _date,
                    firstDate: dateOnly(now),
                    lastDate: now.add(const Duration(days: 180)),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TimeField(
                      label: 'Start *',
                      value: _start,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (t != null) setState(() => _start = t);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _minutes,
                      decoration: const InputDecoration(labelText: 'Duration'),
                      items: [
                        for (final m in const [30, 45, 60, 90, 120])
                          DropdownMenuItem(value: m, child: Text('$m min')),
                      ],
                      onChanged: (v) => setState(() => _minutes = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            DropdownButtonFormField<String?>(
              initialValue: _instructorId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Instructor'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                for (final i in instructors)
                  DropdownMenuItem(value: i.id, child: Text(i.name)),
              ],
              onChanged: (v) => setState(() => _instructorId = v),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String?>(
              initialValue: _vehicleId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Vehicle'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unassigned')),
                for (final v in vehicles)
                  DropdownMenuItem(value: v.id, child: Text(v.label)),
              ],
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
            const SizedBox(height: AppSpacing.md),
            if (mode == LessonFormMode.reschedule)
              TextFormField(
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Reason'),
              )
            else
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Overlapping bookings for the same student, instructor or '
              'vehicle are blocked.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
