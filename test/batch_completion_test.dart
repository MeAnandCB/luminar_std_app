import 'package:flutter_test/flutter_test.dart';
import 'package:luminar_std/presentation/certificate/batch_completion.dart';
import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';

Enrollment _enrollment({
  bool? isCompleted,
  String? batchStatus,
  String course = 'Python Full Stack',
  String enrollmentStatus = 'active',
}) => Enrollment(
  status: CurrentStatus(name: enrollmentStatus, value: enrollmentStatus),
  batchInfo: BatchInfo(isCompleted: isCompleted, status: batchStatus),
  courseInfo: CourseInfo(courseName: course),
);

void main() {
  group('isBatchCompleted', () {
    test('is_completed true counts', () {
      expect(isBatchCompleted(BatchInfo(isCompleted: true)), isTrue);
    });

    test('a "completed" status counts, in any letter case', () {
      expect(isBatchCompleted(BatchInfo(status: 'completed')), isTrue);
      expect(isBatchCompleted(BatchInfo(status: 'Completed')), isTrue);
      expect(isBatchCompleted(BatchInfo(status: ' COMPLETED'.trim())), isTrue);
    });

    test('running and upcoming batches do not count', () {
      expect(isBatchCompleted(BatchInfo(status: 'ongoing')), isFalse);
      expect(isBatchCompleted(BatchInfo(status: 'active')), isFalse);
      expect(isBatchCompleted(BatchInfo(status: 'upcoming')), isFalse);
      expect(
        isBatchCompleted(BatchInfo(isCompleted: false, status: 'ongoing')),
        isFalse,
      );
    });

    test('no batch / no data is not completed', () {
      expect(isBatchCompleted(null), isFalse);
      expect(isBatchCompleted(BatchInfo()), isFalse);
    });

    test('the fallback status is used only when the batch has none', () {
      expect(isBatchCompleted(null, fallbackStatus: 'completed'), isTrue);
      expect(isBatchCompleted(BatchInfo(), fallbackStatus: 'completed'), isTrue);
      // The dashboard's own status wins over the fallback.
      expect(
        isBatchCompleted(
          BatchInfo(status: 'ongoing'),
          fallbackStatus: 'completed',
        ),
        isFalse,
      );
    });
  });

  group('completedCourseNames', () {
    test('lists only completed courses', () {
      final names = completedCourseNames([
        _enrollment(isCompleted: true, course: 'Python'),
        _enrollment(batchStatus: 'ongoing', course: 'Flutter'),
        _enrollment(batchStatus: 'completed', course: 'Data Science'),
      ]);
      expect(names, ['Python', 'Data Science']);
    });

    test('dropped and removed enrollments never count', () {
      final names = completedCourseNames([
        _enrollment(isCompleted: true, enrollmentStatus: 'dropped'),
        _enrollment(isCompleted: true, enrollmentStatus: 'removed'),
      ]);
      expect(names, isEmpty);
    });

    test('a nameless completed course still counts', () {
      final names = completedCourseNames([
        Enrollment(
          status: CurrentStatus(name: 'active', value: 'active'),
          batchInfo: BatchInfo(isCompleted: true),
        ),
      ]);
      expect(names, ['']);
    });

    test('nothing completed gives an empty list', () {
      expect(completedCourseNames(const []), isEmpty);
      expect(
        completedCourseNames([_enrollment(batchStatus: 'ongoing')]),
        isEmpty,
      );
    });
  });
}
