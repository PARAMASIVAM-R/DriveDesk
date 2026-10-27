import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_provider.dart';
import '../domain/reminder.dart';
import 'reminder_providers.dart';

/// Staff reminder centre, or (with [studentView]) the signed-in student's
/// own reminders.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key, this.studentView = false});

  final bool studentView;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  ReminderStatus? _status;

  @override
  Widget build(BuildContext context) {
    final studentId = ref.watch(currentStudentIdProvider);
    final all = widget.studentView
        ? (studentId == null
              ? const <Reminder>[]
              : ref.watch(remindersForStudentProvider(studentId)))
        : ref.watch(remindersProvider);
    final list = _status == null
        ? all
        : all.where((r) => r.status == _status).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentView ? 'My reminders' : 'Reminders'),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          DemoBanner(
            text: widget.studentView
                ? 'Reminders are shown in the app only. The school may also '
                      'contact you on WhatsApp.'
                : 'Messages are never sent automatically. Preview a message, '
                      'send it yourself in WhatsApp, then mark it sent.',
          ),
          if (!widget.studentView) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text('All (${all.length})'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                for (final s in ReminderStatus.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (list.isEmpty)
            const EmptyState(
              icon: Icons.notifications_none,
              title: 'No reminders',
              message:
                  'Upcoming classes, tests, LLR expiry and fee dues '
                  'will appear here.',
            )
          else
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ReminderCard(
                  reminder: r,
                  showRecipient: !widget.studentView,
                  onTap: () => showReminderPreview(
                    context,
                    r,
                    staff: !widget.studentView,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    this.showRecipient = true,
    this.onTap,
  });

  final Reminder reminder;
  final bool showRecipient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = reminder;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: r.urgency.color.withValues(alpha: 0.12),
          child: Icon(r.type.icon, color: r.urgency.color),
        ),
        title: Text(r.title),
        subtitle: Text(
          [
            if (showRecipient) r.recipientName,
            '${r.type.label} · ${formatDate(r.dueAt)}',
          ].join('\n'),
        ),
        isThreeLine: showRecipient,
        trailing: showRecipient
            ? StatusChip(label: r.status.label, color: r.status.color)
            : StatusChip(label: r.urgency.label, color: r.urgency.color),
      ),
    );
  }
}

Future<void> showReminderPreview(
  BuildContext context,
  Reminder reminder, {
  required bool staff,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PreviewSheet(reminderId: reminder.id, staff: staff),
  );
}

class _PreviewSheet extends ConsumerWidget {
  const _PreviewSheet({required this.reminderId, required this.staff});

  final String reminderId;
  final bool staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref
        .watch(remindersProvider)
        .where((x) => x.id == reminderId)
        .firstOrNull;
    if (r == null) return const SizedBox(height: 120);
    final canManage =
        staff && Permissions.canManageReminders(ref.watch(currentRoleProvider));
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(r.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                StatusChip(
                  label: '${r.urgency.label} urgency',
                  color: r.urgency.color,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (canManage)
                  StatusChip(label: r.status.label, color: r.status.color),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (canManage)
              InfoRow('To', '${r.recipientName} · ${r.recipientPhone}'),
            InfoRow('Date', formatDate(r.dueAt)),
            const SizedBox(height: AppSpacing.md),
            Text('WhatsApp message preview', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF8C6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                r.message,
                style: const TextStyle(color: Colors.black87, height: 1.35),
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Not sent. DriveDesk does not deliver WhatsApp messages; '
                '"Open WhatsApp" only opens a chat with this text prefilled.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open WhatsApp (send manually)'),
                onPressed: () => _openWhatsApp(context, r),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Record status', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<ReminderStatus>(
                segments: [
                  for (final s in ReminderStatus.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: {r.status},
                onSelectionChanged: (s) => ref
                    .read(reminderStatusesProvider.notifier)
                    .setStatus(r.id, s.first),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context, Reminder r) async {
    final digits = r.recipientPhone.replaceAll(RegExp(r'\D'), '');
    final phone = digits.length == 10 ? '91$digits' : digits;
    final uri = Uri.https('wa.me', '/$phone', {'text': r.message});
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showMessage(
        context,
        'Could not open WhatsApp on this device.',
        error: true,
      );
    }
  }
}
