enum UserRole {
  owner('Owner'),
  officeStaff('Office staff'),
  student('Student');

  const UserRole(this.label);
  final String label;

  bool get isStaff => this != UserRole.student;
}

/// Simulated signed-in user. There is no real authentication in this MVP.
class DemoSession {
  const DemoSession({
    required this.role,
    required this.userId,
    required this.displayName,
    required this.schoolId,
  });

  final UserRole role;

  /// Stable ID of the staff member or student. Student data is always
  /// scoped by this ID, never by name or phone.
  final String userId;
  final String displayName;
  final String schoolId;
}

/// Central place for role checks. These only shape the prototype UX;
/// a future backend must enforce the real authorisation rules.
abstract final class Permissions {
  static bool canManageStudents(UserRole r) => r.isStaff;
  static bool canManageLessons(UserRole r) => r.isStaff;
  static bool canManageLicences(UserRole r) => r.isStaff;
  static bool canRecordPayments(UserRole r) => r.isStaff;
  static bool canVoidPayments(UserRole r) => r == UserRole.owner;
  static bool canManageReminders(UserRole r) => r.isStaff;
  static bool canViewStaff(UserRole r) => r.isStaff;
  static bool canManageStaff(UserRole r) => r == UserRole.owner;
  static bool canEditSchoolSettings(UserRole r) => r == UserRole.owner;
  static bool canRequestReschedule(UserRole r) => r == UserRole.student;
}
