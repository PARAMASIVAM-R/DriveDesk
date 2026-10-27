import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../students/presentation/student_providers.dart';
import '../domain/licence.dart';
import 'licence_providers.dart';
import 'licence_widgets.dart';

/// Staff view to edit a student's LLR and manage driving test attempts.
class LicenceDetailScreen extends ConsumerWidget {
  const LicenceDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(testsForStudentProvider(studentId));
    final hasScheduled = tests.any((t) => t.status == TestStatus.scheduled);
    final passed = tests.any((t) => t.status == TestStatus.passed);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: Text(ref.watch(studentNameProvider(studentId)))),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          LlrCard(
            studentId: studentId,
            onEdit: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => _LlrForm(studentId: studentId),
            ),
          ),
          SectionHeader(
            'Driving tests',
            action: !hasScheduled && !passed
                ? TextButton.icon(
                    onPressed: () => _bookTest(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Book test'),
                  )
                : null,
          ),
          if (tests.isEmpty)
            const Text('No test records. Book a test once a date is known.')
          else
            Card(
              child: Column(
                children: [
                  for (final t in tests.reversed)
                    TestAttemptTile(
                      test: t,
                      trailing: t.status == TestStatus.scheduled
                          ? PopupMenuButton<String>(
                              tooltip: 'Test actions',
                              onSelected: (v) => switch (v) {
                                'reschedule' => _bookTest(context, ref, t),
                                'pass' => _outcome(context, ref, t, true),
                                _ => _outcome(context, ref, t, false),
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'reschedule',
                                  child: Text('Reschedule'),
                                ),
                                if (t.scheduledAt == null ||
                                    !t.scheduledAt!.isAfter(now)) ...[
                                  const PopupMenuItem(
                                    value: 'pass',
                                    child: Text('Record: passed'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'fail',
                                    child: Text('Record: failed'),
                                  ),
                                ],
                              ],
                            )
                          : null,
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Earlier attempts and rescheduled bookings are kept for history. '
            'Outcomes can be recorded once the test date has passed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _bookTest(
    BuildContext context,
    WidgetRef ref, [
    DrivingTest? existing,
  ]) async {
    final result = await showModalBottomSheet<(DateTime, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TestForm(existing: existing),
    );
    if (result == null) return;
    final notifier = ref.read(testsProvider.notifier);
    try {
      if (existing == null) {
        await notifier.book(
          studentId: studentId,
          at: result.$1,
          location: result.$2,
        );
      } else {
        await notifier.reschedule(existing, at: result.$1, location: result.$2);
      }
      if (context.mounted) {
        showMessage(
          context,
          existing == null ? 'Test booked.' : 'Test rescheduled.',
        );
      }
    } catch (e) {
      if (context.mounted) showMessage(context, '$e', error: true);
    }
  }

  Future<void> _outcome(
    BuildContext context,
    WidgetRef ref,
    DrivingTest test,
    bool passed,
  ) async {
    final ok = await confirm(
      context,
      title: passed ? 'Record pass?' : 'Record fail?',
      message: 'Confirm the official result of this driving test.',
    );
    if (!ok) return;
    try {
      await ref
          .read(testsProvider.notifier)
          .recordOutcome(test, passed: passed);
      if (context.mounted) showMessage(context, 'Outcome recorded.');
    } catch (e) {
      if (context.mounted) showMessage(context, '$e', error: true);
    }
  }
}

class _LlrForm extends ConsumerStatefulWidget {
  const _LlrForm({required this.studentId});

  final String studentId;

  @override
  ConsumerState<_LlrForm> createState() => _LlrFormState();
}

class _LlrFormState extends ConsumerState<_LlrForm> {
  final _number = TextEditingController();
  DateTime? _issue;
  DateTime? _expiry;
  String? _existingId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = ref.read(licenceForStudentProvider(widget.studentId));
    if (r != null) {
      _existingId = r.id;
      _number.text = r.llrNumber ?? '';
      _issue = r.issueDate;
      _expiry = r.expiryDate;
    }
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime? initial) {
    final now = ref.read(clockProvider)();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(licencesProvider.notifier)
          .save(
            studentId: widget.studentId,
            existingId: _existingId,
            llrNumber: _number.text,
            issueDate: _issue,
            expiryDate: _expiry,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showMessage(context, '$e', error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Learner's licence",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _number,
            decoration: const InputDecoration(labelText: 'LLR number'),
          ),
          const SizedBox(height: AppSpacing.md),
          DateField(
            label: 'Issue date',
            value: _issue,
            onTap: () async {
              final d = await _pick(_issue);
              if (d != null) setState(() => _issue = d);
            },
            onClear: () => setState(() => _issue = null),
          ),
          const SizedBox(height: AppSpacing.md),
          DateField(
            label: 'Expiry date',
            value: _expiry,
            onTap: () async {
              final d = await _pick(_expiry);
              if (d != null) setState(() => _expiry = d);
            },
            onClear: () => setState(() => _expiry = null),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Leave dates empty if not yet known.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TestForm extends ConsumerStatefulWidget {
  const _TestForm({this.existing});

  final DrivingTest? existing;

  @override
  ConsumerState<_TestForm> createState() => _TestFormState();
}

class _TestFormState extends ConsumerState<_TestForm> {
  final _location = TextEditingController(text: 'RTO Coimbatore (Central)');
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _date = dateOnly(ref.read(clockProvider)()).add(const Duration(days: 7));
    final e = widget.existing;
    if (e != null && e.location.isNotEmpty) _location.text = e.location;
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Book driving test' : 'Reschedule test',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.existing != null)
            Text(
              'The current booking is kept in history as "Rescheduled".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.md),
          DateField(
            label: 'Test date',
            value: _date,
            onTap: () async {
              final now = ref.read(clockProvider)();
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: dateOnly(now),
                lastDate: DateTime(now.year + 1),
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
            controller: _location,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context, (
              combine(_date, _time),
              _location.text.trim(),
            )),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
