import 'package:luminar_std/repository/home_screen/dashmoard_model.dart';

/// One rule for "has this course finished?", used by every certificate entry
/// point (the Home card and the More → Certificates card) so they can never
/// disagree.
///
/// A batch counts as completed when the dashboard flags it so — either
/// `is_completed` or a "completed" status. Anything else (upcoming, ongoing,
/// active) is still running and cannot have a certificate yet.
///
/// [fallbackStatus] is only consulted when the dashboard batch has no status
/// of its own.
bool isBatchCompleted(BatchInfo? batch, {Object? fallbackStatus}) =>
    batch?.isCompleted == true ||
    (batch?.status ?? fallbackStatus ?? '').toString().toLowerCase() ==
        'completed';

/// Names of the student's completed courses, from the dashboard. Dropped and
/// removed enrollments never count: they can't get a certificate.
///
/// A course with no name still counts (as an empty string), so the list's
/// length is always the number of completed courses.
List<String> completedCourseNames(Iterable<Enrollment> enrollments) => [
  for (final e in enrollments)
    if (!e.isBlockedForStudent && isBatchCompleted(e.batchInfo))
      e.courseInfo?.courseName ?? '',
];
