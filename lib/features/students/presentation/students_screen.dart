import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../domain/student.dart';
import 'student_providers.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(studentFilterProvider);
    final students = ref.watch(filteredStudentsProvider);
    final notifier = ref.read(studentFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/students/new'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add student'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or phone',
              ),
              onChanged: notifier.setQuery,
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: filter.status == null,
                  onSelected: (_) => notifier.setStatus(null),
                ),
                for (final s in StudentStatus.values) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: Text(s.label),
                    selected: filter.status == s,
                    onSelected: (_) => notifier.setStatus(s),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: students,
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No students found',
                      message: 'Try a different search or filter.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = list[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text(s.initials)),
                          title: Text(s.fullName),
                          subtitle: Text(s.phone),
                          trailing: StatusChip(
                            label: s.status.label,
                            color: s.status.color,
                          ),
                          onTap: () => context.push('/students/${s.id}'),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
