import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import 'lesson_providers.dart';
import 'lesson_tile.dart';

final _selectedDayProvider = NotifierProvider<_SelectedDay, DateTime>(
  _SelectedDay.new,
);

class _SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.watch(clockProvider)());

  void select(DateTime day) => state = day;
}

/// Day-by-day schedule with a two-week strip (past week + next week).
class ClassesScreen extends ConsumerWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_selectedDayProvider);
    final today = dateOnly(ref.watch(clockProvider)());
    final lessons = ref.watch(lessonsProvider);
    final dayLessons = ref.watch(lessonsOnDayProvider(selected));
    final pending = ref.watch(pendingRequestsProvider).length;
    final days = [for (var i = -7; i <= 14; i++) today.add(Duration(days: i))];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        actions: [
          IconButton(
            tooltip: 'Reschedule requests',
            onPressed: () => context.push('/lessons/requests'),
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.swap_horiz),
            ),
          ),
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today),
            onPressed: () =>
                ref.read(_selectedDayProvider.notifier).select(today),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/lessons/new'),
        icon: const Icon(Icons.add),
        label: const Text('Schedule'),
      ),
      body: Column(
        children: [
          _DayStrip(
            days: days,
            selected: selected,
            today: today,
            onSelect: ref.read(_selectedDayProvider.notifier).select,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('EEEE, d MMMM').format(selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: lessons,
              data: (_) => dayLessons.isEmpty
                  ? const EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'No classes on this day',
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        for (final l in dayLessons)
                          LessonTile(
                            lesson: l,
                            onTap: () => context.push('/lessons/${l.id}'),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayStrip extends StatefulWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  // Start scrolled so the past week is just off-screen and today is first.
  final _controller = ScrollController(initialScrollOffset: 7 * 60);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: widget.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final day = widget.days[i];
          return _DayChip(
            day: day,
            selected: isSameDay(day, widget.selected),
            isToday: isSameDay(day, widget.today),
            onTap: () => widget.onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(day),
                style: TextStyle(color: fg, fontSize: 12),
              ),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  decoration: isToday && !selected
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
