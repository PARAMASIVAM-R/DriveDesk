import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/session_provider.dart';
import '../features/dashboard/presentation/staff_dashboard_screen.dart';
import '../features/fees/presentation/fees_screen.dart';
import '../features/fees/presentation/payment_form_screen.dart';
import '../features/fees/presentation/student_fees_screen.dart';
import '../features/licences_tests/presentation/licence_detail_screen.dart';
import '../features/licences_tests/presentation/licences_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';
import '../features/scheduling/presentation/classes_screen.dart';
import '../features/scheduling/presentation/lesson_detail_screen.dart';
import '../features/scheduling/presentation/lesson_form_screen.dart';
import '../features/scheduling/presentation/reschedule_requests_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/staff_more_screen.dart';
import '../features/staff/presentation/staff_screen.dart';
import '../features/student_portal/presentation/my_classes_screen.dart';
import '../features/student_portal/presentation/my_fees_screen.dart';
import '../features/student_portal/presentation/my_licence_screen.dart';
import '../features/student_portal/presentation/my_profile_screen.dart';
import '../features/student_portal/presentation/reschedule_request_screen.dart';
import '../features/student_portal/presentation/student_home_screen.dart';
import '../features/student_portal/presentation/student_more_screen.dart';
import '../features/students/presentation/student_detail_screen.dart';
import '../features/students/presentation/student_form_screen.dart';
import '../features/students/presentation/students_screen.dart';
import 'shell_scaffold.dart';

abstract final class Routes {
  static const login = '/login';
  static const staffHome = '/staff';
  static const studentHome = '/me';
}

/// Root-level routes that only staff may open.
const _staffOnlyPrefixes = [
  '/staff',
  '/students',
  '/lessons',
  '/fees',
  '/licences',
  '/reminders',
  '/team',
  '/settings',
];

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Bridges Riverpod session changes into go_router's refresh mechanism
  // without rebuilding the router (which would reset navigation state).
  final refresh = ValueNotifier<DemoSession?>(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => refresh.value = next);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = refresh.value;
      final path = state.uri.path;
      if (session == null) return path == Routes.login ? null : Routes.login;
      final home = session.role.isStaff ? Routes.staffHome : Routes.studentHome;
      if (path == Routes.login) return home;
      final isStudentArea = path == '/me' || path.startsWith('/me/');
      if (!session.role.isStaff && !isStudentArea) return home;
      if (session.role.isStaff &&
          !_staffOnlyPrefixes.any((p) => path.startsWith(p))) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ShellScaffold(shell: shell, destinations: staffDestinations),
        branches: [
          _branch('/staff', const StaffDashboardScreen()),
          _branch('/staff/students', const StudentsScreen()),
          _branch('/staff/classes', const ClassesScreen()),
          _branch('/staff/fees', const FeesScreen()),
          _branch('/staff/more', const StaffMoreScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ShellScaffold(shell: shell, destinations: studentDestinations),
        branches: [
          _branch('/me', const StudentHomeScreen()),
          _branch('/me/classes', const MyClassesScreen()),
          _branch('/me/licence', const MyLicenceScreen()),
          _branch('/me/fees', const MyFeesScreen()),
          _branch('/me/more', const StudentMoreScreen()),
        ],
      ),
      // Staff detail and form screens open full-screen above the shell.
      GoRoute(
        path: '/students/new',
        builder: (_, _) => const StudentFormScreen(),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (_, s) =>
            StudentDetailScreen(studentId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) =>
                StudentFormScreen(studentId: s.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: '/lessons/new',
        builder: (_, s) =>
            LessonFormScreen(studentId: s.uri.queryParameters['studentId']),
      ),
      GoRoute(
        path: '/lessons/requests',
        builder: (_, _) => const RescheduleRequestsScreen(),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (_, s) =>
            LessonDetailScreen(lessonId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'reschedule',
            builder: (_, s) => LessonFormScreen(
              lessonId: s.pathParameters['id'],
              mode: LessonFormMode.reschedule,
            ),
          ),
          GoRoute(
            path: 'edit',
            builder: (_, s) => LessonFormScreen(
              lessonId: s.pathParameters['id'],
              mode: LessonFormMode.edit,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/fees/:studentId',
        builder: (_, s) =>
            StudentFeesScreen(studentId: s.pathParameters['studentId']!),
        routes: [
          GoRoute(
            path: 'pay',
            builder: (_, s) =>
                PaymentFormScreen(studentId: s.pathParameters['studentId']),
          ),
        ],
      ),
      GoRoute(path: '/fees-pay', builder: (_, _) => const PaymentFormScreen()),
      GoRoute(path: '/licences', builder: (_, _) => const LicencesScreen()),
      GoRoute(
        path: '/licences/:studentId',
        builder: (_, s) =>
            LicenceDetailScreen(studentId: s.pathParameters['studentId']!),
      ),
      GoRoute(path: '/reminders', builder: (_, _) => const RemindersScreen()),
      GoRoute(path: '/team', builder: (_, _) => const StaffScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      // Student full-screen routes.
      GoRoute(
        path: '/me/reminders',
        builder: (_, _) => const RemindersScreen(studentView: true),
      ),
      GoRoute(path: '/me/profile', builder: (_, _) => const MyProfileScreen()),
      GoRoute(
        path: '/me/request/:lessonId',
        builder: (_, s) =>
            RescheduleRequestScreen(lessonId: s.pathParameters['lessonId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => screen)],
);
