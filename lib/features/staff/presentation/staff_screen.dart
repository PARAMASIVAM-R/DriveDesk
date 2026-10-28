import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_provider.dart';
import '../../settings/presentation/school_providers.dart';
import '../domain/staff.dart';

/// Team and fleet. The owner can add and edit staff and vehicles; everyone
/// else sees a read-only list.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffProvider);
    final vehicles = ref.watch(vehiclesProvider).value ?? const [];
    final isOwner = Permissions.canManageStaff(ref.watch(currentRoleProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff & vehicles')),
      body: AsyncValueView(
        value: staff,
        data: (members) => ListView(
          padding: AppSpacing.screen,
          children: [
            if (!isOwner)
              const DemoBanner(
                text: 'Only the owner can manage staff and vehicles.',
              ),
            SectionHeader(
              'Team (${members.length})',
              action: isOwner
                  ? TextButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
                      onPressed: () => _editStaff(context, ref, null),
                    )
                  : null,
            ),
            Card(
              child: Column(
                children: [
                  for (final m in members)
                    ListTile(
                      leading: Avatar3D(initials: m.name.characters.first),
                      title: Text(m.name),
                      subtitle: Text(m.phone),
                      trailing: StatusChip(
                        label: m.role.label,
                        color: m.role == StaffRole.owner
                            ? AppColors.amber
                            : AppColors.neutral,
                      ),
                      onTap: isOwner ? () => _editStaff(context, ref, m) : null,
                    ),
                ],
              ),
            ),
            SectionHeader(
              'Vehicles (${vehicles.length})',
              action: isOwner
                  ? TextButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
                      onPressed: () => _editVehicle(context, ref, null),
                    )
                  : null,
            ),
            if (vehicles.isEmpty)
              const Text('No vehicles yet.')
            else
              Card(
                child: Column(
                  children: [
                    for (final v in vehicles)
                      ListTile(
                        leading: const GlossyIcon(
                          Icons.directions_car_rounded,
                          size: 40,
                        ),
                        title: Text(v.model),
                        subtitle: Text('${v.registration} · ${v.transmission}'),
                        trailing: isOwner
                            ? const Icon(Icons.edit_outlined, size: 20)
                            : null,
                        onTap: isOwner
                            ? () => _editVehicle(context, ref, v)
                            : null,
                      ),
                  ],
                ),
              ),
            const SectionHeader('Role permissions'),
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoRow(
                    'Owner',
                    'Everything, incl. voiding payments, '
                        'staff, vehicles and school settings',
                  ),
                  InfoRow(
                    'Office staff',
                    'Students, classes, licences, '
                        'payments and reminders',
                  ),
                  InfoRow(
                    'Instructor',
                    'Listed for class assignment; no app login '
                        'in this version',
                  ),
                  InfoRow(
                    'Student',
                    'Own records only; can request class '
                        'changes',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _editStaff(
    BuildContext context,
    WidgetRef ref,
    StaffMember? member,
  ) async {
    final saved = await showModalBottomSheet<StaffMember>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StaffForm(
        member: member,
        schoolId: member?.schoolId ?? demoSchoolId,
      ),
    );
    if (saved == null) return;
    await ref.read(teamActionsProvider).saveStaff(saved);
    if (context.mounted) {
      showMessage(context, member == null ? 'Staff added' : 'Staff updated');
    }
  }

  Future<void> _editVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle? vehicle,
  ) async {
    final saved = await showModalBottomSheet<Vehicle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VehicleForm(
        vehicle: vehicle,
        schoolId: vehicle?.schoolId ?? demoSchoolId,
      ),
    );
    if (saved == null) return;
    await ref.read(teamActionsProvider).saveVehicle(saved);
    if (context.mounted) {
      showMessage(
        context,
        vehicle == null ? 'Vehicle added' : 'Vehicle updated',
      );
    }
  }
}

/// Bottom-sheet scaffold shared by the two forms: title, fields, save.
class _SheetForm extends StatelessWidget {
  const _SheetForm({
    required this.formKey,
    required this.title,
    required this.fields,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            for (final f in fields) ...[
              f,
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            AmberPillButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffForm extends StatefulWidget {
  const _StaffForm({required this.member, required this.schoolId});

  final StaffMember? member;
  final String schoolId;

  @override
  State<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<_StaffForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.member?.name);
  late final _phone = TextEditingController(text: widget.member?.phone);
  late var _role = widget.member?.role ?? StaffRole.instructor;
  // Generated once so a double tap can't create two records.
  late final _id = widget.member?.id ?? newId('stf');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      StaffMember(
        id: _id,
        schoolId: widget.schoolId,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // There is one owner; the role can't be given or taken away here.
    final isOwner = widget.member?.role == StaffRole.owner;
    return _SheetForm(
      formKey: _formKey,
      title: widget.member == null ? 'Add staff' : 'Edit staff',
      onSave: _save,
      fields: [
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (v) => Validators.required(v, 'Name'),
        ),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Mobile number'),
          validator: Validators.phone,
        ),
        if (isOwner)
          const InfoRow('Role', 'Owner')
        else
          SegmentedButton<StaffRole>(
            segments: const [
              ButtonSegment(
                value: StaffRole.instructor,
                label: Text('Instructor'),
              ),
              ButtonSegment(
                value: StaffRole.officeStaff,
                label: Text('Office staff'),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (s) => setState(() => _role = s.first),
          ),
      ],
    );
  }
}

class _VehicleForm extends StatefulWidget {
  const _VehicleForm({required this.vehicle, required this.schoolId});

  final Vehicle? vehicle;
  final String schoolId;

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  late final _model = TextEditingController(text: widget.vehicle?.model);
  late final _registration = TextEditingController(
    text: widget.vehicle?.registration,
  );
  late var _transmission = widget.vehicle?.transmission ?? 'Manual';
  late final _id = widget.vehicle?.id ?? newId('veh');

  @override
  void dispose() {
    _model.dispose();
    _registration.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Vehicle(
        id: _id,
        schoolId: widget.schoolId,
        model: _model.text.trim(),
        registration: _registration.text.trim().toUpperCase(),
        transmission: _transmission,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetForm(
      formKey: _formKey,
      title: widget.vehicle == null ? 'Add vehicle' : 'Edit vehicle',
      onSave: _save,
      fields: [
        TextFormField(
          controller: _model,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Model',
            hintText: 'e.g. Maruti Swift',
          ),
          validator: (v) => Validators.required(v, 'Model'),
        ),
        TextFormField(
          controller: _registration,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Registration number',
            hintText: 'e.g. TN 09 AB 1234',
          ),
          validator: (v) => Validators.required(v, 'Registration'),
        ),
        SegmentedButton<String>(
          // Keep any existing non-standard value (e.g. "Automatic (2W)").
          segments: [
            for (final t in {'Manual', 'Automatic', _transmission})
              ButtonSegment(value: t, label: Text(t)),
          ],
          selected: {_transmission},
          onSelectionChanged: (s) => setState(() => _transmission = s.first),
        ),
      ],
    );
  }
}
