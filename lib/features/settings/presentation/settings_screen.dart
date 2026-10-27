import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_provider.dart';
import '../domain/school.dart';
import 'school_providers.dart';

/// School profile. Editable by the owner; read-only for office staff.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final school = ref.watch(schoolProvider);
    final canEdit = Permissions.canEditSchoolSettings(
      ref.watch(currentRoleProvider),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('School settings')),
      body: AsyncValueView(
        value: school,
        data: (s) => canEdit
            ? _SchoolForm(school: s)
            : ListView(
                padding: AppSpacing.screen,
                children: [
                  SectionCard(
                    child: Column(
                      children: [
                        InfoRow('Name', s.name),
                        InfoRow('Address', s.address),
                        InfoRow('Phone', s.phone),
                        InfoRow('Licence no.', s.licenceNumber),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Only the owner can change school settings.'),
                ],
              ),
      ),
    );
  }
}

class _SchoolForm extends ConsumerStatefulWidget {
  const _SchoolForm({required this.school});

  final School school;

  @override
  ConsumerState<_SchoolForm> createState() => _SchoolFormState();
}

class _SchoolFormState extends ConsumerState<_SchoolForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.school.name);
  late final _address = TextEditingController(text: widget.school.address);
  late final _phone = TextEditingController(text: widget.school.phone);
  late final _licence = TextEditingController(
    text: widget.school.licenceNumber,
  );

  @override
  void dispose() {
    for (final c in [_name, _address, _phone, _licence]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(schoolProvider.notifier)
        .save(
          widget.school.copyWith(
            name: _name.text.trim(),
            address: _address.text.trim(),
            phone: _phone.text.trim(),
            licenceNumber: _licence.text.trim(),
          ),
        );
    if (mounted) showMessage(context, 'School settings saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.screen,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'School name'),
            validator: (v) => Validators.required(v, 'School name'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Address'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Office phone'),
            validator: (v) => Validators.required(v, 'Phone'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _licence,
            decoration: const InputDecoration(
              labelText: 'Driving school licence no.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
