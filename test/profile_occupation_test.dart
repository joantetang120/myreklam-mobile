import 'package:flutter_test/flutter_test.dart';
import 'package:myreklam/utils/profile_occupation.dart';

void main() {
  test(
    'student with several statuses shows studies, not stored employment',
    () {
      expect(
        profileOccupationLine({
          'career_statuses': ['internship', 'student'],
          'study_program': ' BTS informatique ',
          'educational_institution': ' Lycée Test ',
          'job_title': 'Ancien poste',
          'company_name': 'Ancien employeur',
        }),
        'BTS informatique — Lycée Test',
      );
    },
  );
  test(
    'institution alone is shown and empty studies never use old employment',
    () {
      expect(
        profileOccupationLine({
          'career_statuses': ['student'],
          'educational_institution': 'Université',
        }),
        'Université',
      );
      expect(
        profileOccupationLine({
          'career_statuses': ['student'],
          'job_title': 'Ancien poste',
        }),
        isNull,
      );
    },
  );
  test('non student employment remains unchanged', () {
    expect(
      profileOccupationLine({
        'career_statuses': ['job'],
        'job_title': 'Développeur',
        'company_name': 'Entreprise',
        'study_program': 'BTS',
      }),
      'Développeur chez Entreprise',
    );
    expect(profileOccupationLine(null), isNull);
  });
}
