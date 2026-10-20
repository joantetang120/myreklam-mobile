/// Public heading: studies replace employment when the student status is selected.
String? profileOccupationLine(dynamic profile) {
  if (profile is! Map) return null;
  final statuses = profile['career_statuses'];
  final student = statuses is List && statuses.contains('student');
  final title =
      profile[student ? 'study_program' : 'job_title']?.toString().trim() ?? '';
  final institution =
      profile[student ? 'educational_institution' : 'company_name']
          ?.toString()
          .trim() ??
      '';
  if (title.isEmpty && institution.isEmpty) return null;
  if (title.isEmpty) return institution;
  if (institution.isEmpty) return title;
  return student ? '$title — $institution' : '$title chez $institution';
}
