import 'package:drive_desk/app/app.dart';
import 'package:drive_desk/shared/providers/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 27, 9, 30)),
      ],
      child: const DriveDeskApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('login shows simulated sign-in notice and roles', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Simulated sign-in'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Office staff'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
  });

  testWidgets('owner gets staff navigation and dashboard', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Owner'));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Ramesh'), findsOneWidget);
    for (final l in ['Dashboard', 'Students', 'Classes', 'Fees', 'More']) {
      expect(navLabel(l), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.textContaining('Needs attention'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Needs attention'), findsOneWidget);

    await tester.tap(navLabel('Students'));
    await tester.pumpAndSettle();
    expect(find.text('Arun Prakash'), findsWidgets);
  });

  testWidgets('student gets student navigation scoped to themselves', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Divya Ramesh'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Divya'), findsOneWidget);
    for (final l in ['Home', 'My classes', 'Licence', 'Fees', 'More']) {
      expect(navLabel(l), findsOneWidget);
    }
    expect(navLabel('Students'), findsNothing);
    expect(navLabel('Dashboard'), findsNothing);

    await tester.tap(navLabel('Fees'));
    await tester.pumpAndSettle();
    expect(find.text('My fees'), findsOneWidget);
    expect(find.text('Outstanding balance'), findsOneWidget);
  });

  testWidgets('signing out returns to login', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Office staff'));
    await tester.pumpAndSettle();
    await tester.tap(navLabel('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Simulated sign-in'), findsOneWidget);
  });
}
