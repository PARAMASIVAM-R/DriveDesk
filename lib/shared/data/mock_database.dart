import '../../core/utils/formatters.dart';
import '../../features/fees/domain/fees.dart';
import '../../features/licences_tests/domain/licence.dart';
import '../../features/reminders/domain/reminder.dart';
import '../../features/scheduling/domain/lesson.dart';
import '../../features/settings/domain/school.dart';
import '../../features/staff/domain/staff.dart';
import '../../features/students/domain/student.dart';

/// Session-scoped in-memory storage for the frontend MVP. All data is
/// fictional and is reset when the app restarts.
class MockDatabase {
  MockDatabase._(this.school);

  School school;
  final Map<String, StaffMember> staff = {};
  final Map<String, Vehicle> vehicles = {};
  final Map<String, CoursePackage> packages = {};
  final Map<String, Student> students = {};
  final Map<String, Lesson> lessons = {};
  final Map<String, RescheduleRequest> rescheduleRequests = {};
  final Map<String, LicenceRecord> licences = {};
  final Map<String, DrivingTest> tests = {};
  final Map<String, Payment> payments = {};
  final Map<String, Installment> installments = {};
  final Map<String, ReminderStatus> reminderStatuses = {};

  /// Builds the demo dataset with dates relative to [now], covering edge
  /// cases: no LLR, expired/expiring LLR, failed and rescheduled tests,
  /// partial and voided payments, overdue installments, on-hold students.
  factory MockDatabase.seeded(DateTime now) {
    const sid = 'sch_001';
    final today = dateOnly(now);
    DateTime day(int offset, [int hour = 0, int minute = 0]) =>
        today.add(Duration(days: offset, hours: hour, minutes: minute));

    final db = MockDatabase._(
      const School(
        id: sid,
        name: 'Sunrise Driving School (Demo)',
        address: '12 Gandhi Road, Coimbatore, Tamil Nadu',
        phone: '+91 98765 00000',
        licenceNumber: 'DEMO-MDS-0001',
      ),
    );

    for (final s in const [
      StaffMember(
        id: 'stf_owner',
        schoolId: sid,
        name: 'Ramesh Kumar',
        phone: '9876500001',
        role: StaffRole.owner,
      ),
      StaffMember(
        id: 'stf_office',
        schoolId: sid,
        name: 'Priya Sundaram',
        phone: '9876500002',
        role: StaffRole.officeStaff,
      ),
      StaffMember(
        id: 'stf_ins1',
        schoolId: sid,
        name: 'Senthil Raj',
        phone: '9876500003',
        role: StaffRole.instructor,
      ),
      StaffMember(
        id: 'stf_ins2',
        schoolId: sid,
        name: 'Anitha Mohan',
        phone: '9876500004',
        role: StaffRole.instructor,
      ),
    ]) {
      db.staff[s.id] = s;
    }

    for (final v in const [
      Vehicle(
        id: 'veh_1',
        schoolId: sid,
        registration: 'TN 38 AB 1234',
        model: 'Maruti Swift',
        transmission: 'Manual',
      ),
      Vehicle(
        id: 'veh_2',
        schoolId: sid,
        registration: 'TN 38 CD 5678',
        model: 'Hyundai i10',
        transmission: 'Manual',
      ),
      Vehicle(
        id: 'veh_3',
        schoolId: sid,
        registration: 'TN 38 EF 9012',
        model: 'Honda Activa',
        transmission: 'Automatic (2W)',
      ),
    ]) {
      db.vehicles[v.id] = v;
    }

    for (final p in const [
      CoursePackage(
        id: 'pkg_basic',
        schoolId: sid,
        name: 'Car — Basic (15 lessons)',
        fee: 6500,
        lessonCount: 15,
      ),
      CoursePackage(
        id: 'pkg_full',
        schoolId: sid,
        name: 'Car — Complete with test (22 lessons)',
        fee: 9000,
        lessonCount: 22,
      ),
      CoursePackage(
        id: 'pkg_2w',
        schoolId: sid,
        name: 'Two-wheeler (8 lessons)',
        fee: 3500,
        lessonCount: 8,
      ),
      CoursePackage(
        id: 'pkg_refresher',
        schoolId: sid,
        name: 'Refresher (5 lessons)',
        fee: 2500,
        lessonCount: 5,
      ),
    ]) {
      db.packages[p.id] = p;
    }

    void student(
      String id,
      String name,
      String phone,
      String pkg,
      double fee,
      StudentStatus status,
      int enrolledDaysAgo, {
      String notes = '',
      String address = '',
    }) {
      db.students[id] = Student(
        id: id,
        schoolId: sid,
        fullName: name,
        phone: phone,
        address: address,
        enrolmentDate: day(-enrolledDaysAgo),
        packageId: pkg,
        agreedFee: fee,
        status: status,
        notes: notes,
      );
    }

    student(
      'stu_001',
      'Arun Prakash',
      '9840011001',
      'pkg_full',
      9000,
      StudentStatus.active,
      45,
      address: 'RS Puram, Coimbatore',
    );
    student(
      'stu_002',
      'Divya Ramesh',
      '9840011002',
      'pkg_basic',
      6500,
      StudentStatus.active,
      38,
      address: 'Peelamedu, Coimbatore',
    );
    student(
      'stu_003',
      'Karthik Subramanian',
      '9840011003',
      'pkg_full',
      9000,
      StudentStatus.active,
      10,
      notes: 'LLR application submitted, awaiting slot.',
    );
    student(
      'stu_004',
      'Meena Krishnan',
      '9840011004',
      'pkg_basic',
      6500,
      StudentStatus.onHold,
      70,
      notes: 'On hold — travelling until next month.',
    );
    student(
      'stu_005',
      'Vignesh Babu',
      '9840011005',
      'pkg_2w',
      3500,
      StudentStatus.active,
      30,
    );
    student(
      'stu_006',
      'Lakshmi Narayanan',
      '9840011006',
      'pkg_full',
      9000,
      StudentStatus.completed,
      120,
    );
    student(
      'stu_007',
      'Mohammed Irfan',
      '9840011007',
      'pkg_full',
      8500,
      StudentStatus.active,
      5,
      notes: 'Agreed ₹500 discount (student referral).',
    );
    student(
      'stu_008',
      'Sneha Venkatesh',
      '9840011008',
      'pkg_basic',
      6500,
      StudentStatus.enquiry,
      1,
      notes: 'Enquired by phone; will visit on Saturday.',
    );
    student(
      'stu_009',
      'Rahul Dev',
      '9840011009',
      'pkg_refresher',
      2500,
      StudentStatus.cancelled,
      60,
      notes: 'Moved to Chennai. Refund not applicable.',
    );
    student(
      'stu_010',
      'Fathima Begum',
      '9840011010',
      'pkg_refresher',
      2500,
      StudentStatus.active,
      15,
    );
    student(
      'stu_011',
      'Gokul Raj',
      '9840011011',
      'pkg_2w',
      3500,
      StudentStatus.active,
      25,
    );
    student(
      'stu_012',
      'Priyanka Iyer',
      '9840011012',
      'pkg_basic',
      6500,
      StudentStatus.active,
      20,
      address: 'Saibaba Colony, Coimbatore',
    );

    var lessonNo = 0;
    void lesson(
      String stu,
      int offset,
      int hour,
      LessonStatus status, {
      String? ins,
      String? veh,
      String notes = '',
      int minutes = 60,
    }) {
      lessonNo++;
      final id = 'les_${lessonNo.toString().padLeft(3, '0')}';
      final start = day(offset, hour);
      db.lessons[id] = Lesson(
        id: id,
        schoolId: sid,
        studentId: stu,
        start: start,
        end: start.add(Duration(minutes: minutes)),
        instructorId: ins,
        vehicleId: veh,
        status: status,
        notes: notes,
      );
    }

    const done = LessonStatus.completed;
    const sched = LessonStatus.scheduled;
    // Completed history.
    for (final o in [-8, -6, -4, -2]) {
      lesson('stu_001', o, 7, done, ins: 'stf_ins1', veh: 'veh_1');
    }
    lesson('stu_002', -5, 8, done, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_002', -3, 8, done, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_003', -1, 16, done, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_004', -25, 9, done, ins: 'stf_ins2', veh: 'veh_2');
    lesson('stu_005', -2, 18, done, ins: 'stf_ins2', veh: 'veh_3');
    lesson('stu_006', -40, 7, done, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_006', -35, 7, done, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_012', -4, 12, done, ins: 'stf_ins2', veh: 'veh_2');
    lesson('stu_012', -2, 12, done, ins: 'stf_ins2', veh: 'veh_2');
    // Exceptions.
    lesson(
      'stu_007',
      -1,
      10,
      LessonStatus.missed,
      ins: 'stf_ins1',
      veh: 'veh_2',
      notes: 'Student did not turn up.',
    );
    lesson(
      'stu_010',
      -1,
      17,
      LessonStatus.cancelled,
      ins: 'stf_ins2',
      veh: 'veh_2',
      notes: 'Instructor unavailable.',
    );
    // Today.
    lesson('stu_001', 0, 7, sched, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_012', 0, 12, sched, ins: 'stf_ins2', veh: 'veh_2');
    lesson('stu_003', 0, 16, sched, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_005', 0, 18, sched, ins: 'stf_ins2', veh: 'veh_3');
    // Upcoming.
    lesson('stu_002', 1, 8, sched, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_010', 1, 17, sched, ins: 'stf_ins2', veh: 'veh_2');
    lesson('stu_011', 2, 7, sched, ins: 'stf_ins2', veh: 'veh_3');
    lesson('stu_007', 2, 9, sched, ins: 'stf_ins1', veh: 'veh_2');
    lesson('stu_001', 3, 7, sched, ins: 'stf_ins1', veh: 'veh_1');
    lesson('stu_003', 4, 16, sched); // No instructor/vehicle assigned yet.
    lesson('stu_012', 5, 12, sched, ins: 'stf_ins2', veh: 'veh_2');

    db.rescheduleRequests['req_001'] = RescheduleRequest(
      id: 'req_001',
      schoolId: sid,
      studentId: 'stu_002',
      lessonId: 'les_020',
      preferredStart: day(2, 11),
      reason: 'College exam in the morning.',
      createdAt: day(0, 6, 30),
    );

    void llr(String id, String stu, String? no, int? issued, int? expires) {
      db.licences[id] = LicenceRecord(
        id: id,
        schoolId: sid,
        studentId: stu,
        llrNumber: no,
        issueDate: issued == null ? null : day(issued),
        expiryDate: expires == null ? null : day(expires),
      );
    }

    llr('llr_001', 'stu_001', 'TN38/LLR/2026/01101', -60, 120);
    llr('llr_002', 'stu_002', 'TN38/LLR/2026/01102', -168, 12);
    llr('llr_004', 'stu_004', 'TN38/LLR/2026/00874', -185, -5);
    llr('llr_005', 'stu_005', 'TN38/LLR/2026/01105', -50, 130);
    llr('llr_006', 'stu_006', 'TN38/LLR/2026/00650', -150, 30);
    llr('llr_007', 'stu_007', 'TN38/LLR/2026/01207', -3, null);
    llr('llr_010', 'stu_010', 'TN38/LLR/2026/01110', -20, 160);
    llr('llr_011', 'stu_011', 'TN38/LLR/2026/01111', -90, 90);
    llr('llr_012', 'stu_012', 'TN38/LLR/2026/01112', -120, 60);

    void test(
      String id,
      String stu,
      int attempt,
      TestStatus status,
      int? offset, {
      String notes = '',
    }) {
      db.tests[id] = DrivingTest(
        id: id,
        schoolId: sid,
        studentId: stu,
        attempt: attempt,
        status: status,
        scheduledAt: offset == null ? null : day(offset, 10),
        location: offset == null ? '' : 'RTO Coimbatore (Central)',
        notes: notes,
      );
    }

    test('tst_001', 'stu_001', 1, TestStatus.scheduled, 3);
    test(
      'tst_002',
      'stu_005',
      1,
      TestStatus.failed,
      -14,
      notes: 'Failed figure-of-eight manoeuvre.',
    );
    test('tst_003', 'stu_005', 2, TestStatus.scheduled, 6);
    test('tst_004', 'stu_006', 1, TestStatus.passed, -30);
    test(
      'tst_005',
      'stu_011',
      1,
      TestStatus.rescheduled,
      4,
      notes: 'RTO moved the slot.',
    );
    test('tst_006', 'stu_011', 2, TestStatus.scheduled, 20);
    test('tst_007', 'stu_012', 1, TestStatus.notScheduled, null);

    var payNo = 0;
    void pay(
      String stu,
      double amount,
      int offset,
      PaymentMethod method, {
      String? ref,
      String? voidReason,
    }) {
      payNo++;
      final id = 'pay_${payNo.toString().padLeft(3, '0')}';
      db.payments[id] = Payment(
        id: id,
        schoolId: sid,
        studentId: stu,
        amount: amount,
        date: day(offset),
        method: method,
        reference: ref ?? 'RCPT-${1000 + payNo}',
        voidReason: voidReason,
      );
    }

    pay('stu_001', 4500, -45, PaymentMethod.cash);
    pay('stu_001', 1500, -10, PaymentMethod.upi, ref: 'UPI-55120931');
    pay('stu_002', 3000, -38, PaymentMethod.cash);
    pay('stu_003', 9000, -10, PaymentMethod.bankTransfer, ref: 'NEFT-778812');
    pay('stu_004', 2000, -70, PaymentMethod.cash);
    pay('stu_005', 2000, -30, PaymentMethod.upi, ref: 'UPI-44120011');
    pay('stu_005', 1500, -15, PaymentMethod.cash);
    pay('stu_006', 9000, -120, PaymentMethod.card);
    pay('stu_009', 1000, -60, PaymentMethod.cash);
    pay('stu_010', 1500, -15, PaymentMethod.cash);
    pay(
      'stu_010',
      500,
      -12,
      PaymentMethod.upi,
      ref: 'UPI-99001234',
      voidReason: 'Duplicate entry — recorded twice.',
    );
    pay('stu_011', 2000, -25, PaymentMethod.upi, ref: 'UPI-33002211');
    pay('stu_012', 6500, -20, PaymentMethod.card);

    var instNo = 0;
    void inst(String stu, double amount, int offset) {
      instNo++;
      final id = 'ins_${instNo.toString().padLeft(3, '0')}';
      db.installments[id] = Installment(
        id: id,
        schoolId: sid,
        studentId: stu,
        amountDue: amount,
        dueDate: day(offset),
      );
    }

    inst('stu_001', 4500, -45);
    inst('stu_001', 4500, 5);
    inst('stu_002', 3000, -38);
    inst('stu_002', 3500, -5);
    inst('stu_004', 2000, -70);
    inst('stu_004', 4500, -20);
    inst('stu_007', 4250, 2);
    inst('stu_007', 4250, 32);
    inst('stu_010', 1500, -15);
    inst('stu_010', 1000, 10);
    inst('stu_011', 2000, -25);
    inst('stu_011', 1500, 6);

    db.reminderStatuses['inst-ins_004'] = ReminderStatus.markedSent;
    return db;
  }
}
