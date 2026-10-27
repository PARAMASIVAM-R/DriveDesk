import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/student.dart';
import 'student_providers.dart';

/// Registers a new student, or edits one when [studentId] is given.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _fee = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _dob;
  late DateTime _enrolment;
  String? _packageId;
  StudentStatus _status = StudentStatus.active;
  Student? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enrolment = dateOnly(ref.read(clockProvider)());
    final id = widget.studentId;
    if (id != null) {
      final s = ref.read(studentByIdProvider(id));
      if (s != null) {
        _existing = s;
        _name.text = s.fullName;
        _phone.text = s.phone;
        _address.text = s.address;
        _fee.text = s.agreedFee.toStringAsFixed(0);
        _notes.text = s.notes;
        _dob = s.dateOfBirth;
        _enrolment = s.enrolmentDate;
        _packageId = s.packageId;
        _status = s.status;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _fee, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final phone = _phone.text.replaceAll(RegExp(r'[\s-]'), '');
    final normalised = phone.length > 10
        ? phone.substring(phone.length - 10)
        : phone;
    final fee = double.parse(_fee.text.trim());
    final base =
        _existing ??
        Student(
          id: newId('stu'),
          schoolId: demoSchoolId,
          fullName: '',
          phone: '',
          enrolmentDate: _enrolment,
          packageId: _packageId!,
          agreedFee: fee,
          status: _status,
        );
    final student = base.copyWith(
      fullName: _name.text.trim(),
      phone: normalised,
      address: _address.text.trim(),
      dateOfBirth: _dob,
      enrolmentDate: _enrolment,
      packageId: _packageId,
      agreedFee: fee,
      status: _status,
      notes: _notes.text.trim(),
    );
    try {
      final saved = await ref.read(studentsProvider.notifier).save(student);
      if (!mounted) return;
      showMessage(
        context,
        _existing == null ? 'Student registered.' : 'Student updated.',
      );
      if (_existing == null) {
        context.pushReplacement('/students/${saved.id}');
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
      setState(() => _saving = false);
    }
  }

  Future<DateTime?> _pickDate(DateTime? initial, {DateTime? last}) {
    final now = ref.read(clockProvider)();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1940),
      lastDate: last ?? DateTime(now.year + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(packagesProvider);
    final isEdit = _existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit student' : 'Register student')),
      body: AsyncValueView(
        value: packages,
        data: (pkgs) => Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name *'),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number *',
                  helperText: 'Used for WhatsApp reminder previews',
                ),
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                label: 'Date of birth',
                value: _dob,
                onTap: () async {
                  final d = await _pickDate(
                    _dob ?? DateTime(2000),
                    last: ref.read(clockProvider)(),
                  );
                  if (d != null) setState(() => _dob = d);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DateField(
                label: 'Enrolment date *',
                value: _enrolment,
                onTap: () async {
                  final d = await _pickDate(_enrolment);
                  if (d != null) setState(() => _enrolment = d);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _packageId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Course package *',
                ),
                items: [
                  for (final p in pkgs)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} · ${formatMoney(p.fee)}'),
                    ),
                ],
                validator: (v) => v == null ? 'Choose a package' : null,
                onChanged: (id) {
                  setState(() => _packageId = id);
                  // Pre-fill the package price; staff may still negotiate.
                  final pkg = pkgs.firstWhere((p) => p.id == id);
                  if (!isEdit || _fee.text.isEmpty) {
                    _fee.text = pkg.fee.toStringAsFixed(0);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _fee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Agreed course fee (₹) *',
                ),
                validator: Validators.positiveAmount,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<StudentStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final s in StudentStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (s) => setState(() => _status = s!),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'LLR and test details can be added later from the student '
                'profile.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  _saving
                      ? 'Saving…'
                      : isEdit
                      ? 'Save changes'
                      : 'Register student',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
