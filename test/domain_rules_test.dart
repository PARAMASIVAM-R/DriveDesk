import 'package:drive_desk/core/errors/app_exception.dart';
import 'package:drive_desk/core/utils/validators.dart';
import 'package:drive_desk/features/fees/domain/fees.dart';
import 'package:drive_desk/features/licences_tests/domain/licence.dart';
import 'package:drive_desk/features/scheduling/domain/lesson.dart';
import 'package:drive_desk/features/scheduling/domain/lesson_rules.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime(2026, 10, 27, 9);

Payment pay(double amount, {String id = 'p', String? voidReason}) => Payment(
  id: id,
  schoolId: 's',
  studentId: 'stu',
  amount: amount,
  date: today,
  method: PaymentMethod.cash,
  voidReason: voidReason,
);

Installment inst(String id, double amount, int dueOffset) => Installment(
  id: id,
  schoolId: 's',
  studentId: 'stu',
  amountDue: amount,
  dueDate: DateTime(2026, 10, 27).add(Duration(days: dueOffset)),
);

Lesson lesson(
  String id,
  int hour, {
  String student = 'a',
  String? ins,
  String? veh,
  LessonStatus status = LessonStatus.scheduled,
  int minutes = 60,
}) {
  final start = DateTime(2026, 10, 28, hour);
  return Lesson(
    id: id,
    schoolId: 's',
    studentId: student,
    start: start,
    end: start.add(Duration(minutes: minutes)),
    instructorId: ins,
    vehicleId: veh,
    status: status,
  );
}

void main() {
  group('FeeCalculator', () {
    test('balance is agreed fee minus valid payments; voided excluded', () {
      final s = FeeCalculator.summarise(
        agreedFee: 9000,
        payments: [
          pay(4000, id: '1'),
          pay(500, id: '2', voidReason: 'dup'),
        ],
        installments: const [],
        today: today,
      );
      expect(s.totalPaid, 4000);
      expect(s.balance, 5000);
    });

    test('payments cover installments oldest first', () {
      final s = FeeCalculator.summarise(
        agreedFee: 9000,
        payments: [pay(5000)],
        installments: [inst('b', 4500, 10), inst('a', 4500, -20)],
        today: today,
      );
      expect(s.installments.map((v) => v.installment.id), ['a', 'b']);
      expect(s.installments[0].status, InstallmentStatus.paid);
      expect(s.installments[1].status, InstallmentStatus.partlyPaid);
      expect(s.installments[1].remaining, 4000);
      expect(s.hasOverdue, isFalse);
    });

    test('unpaid past-due installment is overdue', () {
      final s = FeeCalculator.summarise(
        agreedFee: 6500,
        payments: [pay(3000)],
        installments: [inst('a', 3000, -30), inst('b', 3500, -1)],
        today: today,
      );
      expect(s.installments[1].status, InstallmentStatus.overdue);
      expect(s.overdueAmount, 3500);
      expect(s.nextDue?.installment.id, 'b');
    });

    test('overpayment gives a negative balance (credit)', () {
      final s = FeeCalculator.summarise(
        agreedFee: 2500,
        payments: [pay(3000)],
        installments: const [],
        today: today,
      );
      expect(s.balance, -500);
    });
  });

  group('LessonRules', () {
    test('rejects end before start', () {
      expect(
        () => LessonRules.validate(lesson('x', 9, minutes: 0), const []),
        throwsA(isA<AppException>()),
      );
    });

    test('rejects overlapping instructor, vehicle and student', () {
      final existing = [lesson('e', 9, student: 'b', ins: 'i1', veh: 'v1')];
      expect(
        () => LessonRules.validate(
          lesson('x', 9, student: 'a', ins: 'i1'),
          existing,
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => LessonRules.validate(
          lesson('x', 9, student: 'a', veh: 'v1'),
          existing,
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => LessonRules.validate(lesson('x', 9, student: 'b'), existing),
        throwsA(isA<AppException>()),
      );
    });

    test('allows back-to-back, unassigned, and cancelled overlaps', () {
      final existing = [
        lesson('e', 9, student: 'b', ins: 'i1', veh: 'v1'),
        lesson('c', 10, ins: 'i2', status: LessonStatus.cancelled),
      ];
      LessonRules.validate(
        lesson('x', 10, student: 'a', ins: 'i1', veh: 'v1'),
        existing,
      );
      LessonRules.validate(lesson('y', 9, student: 'c'), existing);
      LessonRules.validate(lesson('z', 10, ins: 'i2'), existing);
    });

    test('completed lessons cannot be rescheduled or re-marked', () {
      final done = lesson('d', 9, status: LessonStatus.completed);
      expect(
        () => LessonRules.ensureCanReschedule(done),
        throwsA(isA<AppException>()),
      );
      expect(
        () => LessonRules.ensureCanChangeStatus(done, LessonStatus.missed),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('LLR state', () {
    LicenceRecord llr(DateTime? expiry) => LicenceRecord(
      id: 'l',
      schoolId: 's',
      studentId: 'stu',
      expiryDate: expiry,
    );

    test('classifies missing, unknown, expired, expiring and valid', () {
      expect(llrStateOf(null, today), LlrState.none);
      expect(llrStateOf(llr(null), today), LlrState.unknownExpiry);
      expect(llrStateOf(llr(DateTime(2026, 10, 26)), today), LlrState.expired);
      expect(
        llrStateOf(llr(DateTime(2026, 10, 27)), today),
        LlrState.expiringSoon,
      );
      expect(
        llrStateOf(llr(DateTime(2026, 11, 26)), today),
        LlrState.expiringSoon,
      );
      expect(llrStateOf(llr(DateTime(2027, 1, 1)), today), LlrState.valid);
    });
  });

  group('Validators', () {
    test('phone', () {
      expect(Validators.phone('9840011001'), isNull);
      expect(Validators.phone('+91 98400 11001'), isNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('1840011001'), isNotNull);
    });

    test('positive amount rejects zero, negative and garbage', () {
      expect(Validators.positiveAmount('1500'), isNull);
      expect(Validators.positiveAmount('0'), isNotNull);
      expect(Validators.positiveAmount('-10'), isNotNull);
      expect(Validators.positiveAmount('abc'), isNotNull);
    });
  });
}
