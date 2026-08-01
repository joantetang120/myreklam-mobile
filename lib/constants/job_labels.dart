/// French labels for the job-offer enum codes returned by the API.
///
/// The API exchanges SCREAMING_SNAKE_CASE codes (`FULL_TIME`, `MEAL_VOUCHERS`,
/// `BAC_2`, ...). Every screen that displays one of them must go through
/// [JobLabels.label]; the reverse direction (French label -> API code) lives in
/// `creer_offre_emploi_screen.dart::_toApiValue` and must stay consistent with
/// the values below so editing an offer round-trips without losing data.
class JobLabels {
  const JobLabels._();

  static const Map<String, String> labels = {
    // Work times
    'FULL_TIME': 'Temps plein',
    'PART_TIME': 'Temps partiel',
    // Contract types
    'INTERIM': 'Intérim',
    'FREELANCE': 'Freelance',
    'ALTERNANCE': 'Alternance',
    'STAGE': 'Stage',
    'INTERNSHIP': 'Stage',
    'CDI': 'CDI',
    'CDD': 'CDD',
    'SEASONAL': 'Saisonnier',
    'VOLUNTEER': 'Bénévolat',
    // Salary periods
    'YEAR': 'Par an',
    'MONTH': 'Par mois',
    'DAY': 'Par jour',
    'HOUR': 'Par heure',
    // Education levels
    'NONE': 'Sans diplôme',
    'CAP': 'CAP/BEP',
    'BAC': 'Baccalauréat',
    'BAC_2': 'Bac+2',
    'BAC_3': 'Bac+3',
    'MASTER': 'Master/Bac+5',
    'DOCTORATE': 'Doctorat',
    // Experience levels
    'JUNIOR': 'Débutant',
    '1_3_YEARS': '1-3 ans',
    '3_5_YEARS': '3-5 ans',
    '5_10_YEARS': '5-10 ans',
    'EXPERT': 'Expert (+10 ans)',
    // Advantages
    'TRANSPORT': 'Transport',
    'MEAL_VOUCHERS': 'Titre restaurant',
    'RTT': 'RTT',
    'REMOTE_WORK': 'Télétravail',
    'COMPANY_CAR': 'Voiture de fonction',
    'SAVINGS_PLAN': 'Plan épargne',
    'FLEXIBLE_HOURS': 'Horaires flexibles',
    'TIPS': 'Pourboires',
    'COMMISSIONS': 'Commissions',
    'THIRTEENTH_MONTH': '13ème mois',
    'OVERTIME_PAY': 'Heures supp. majorée',
  };

  /// French label for [value].
  ///
  /// [value] may already be a French label (some endpoints return labels rather
  /// than codes), in which case it is returned untouched. An unknown code is
  /// humanized so `SOME_NEW_CODE` never reaches the UI verbatim.
  static String label(String? value, {String fallback = ''}) {
    if (value == null || value.trim().isEmpty) return fallback;
    final raw = value.trim();
    final known = labels[raw] ?? labels[raw.toUpperCase()];
    if (known != null) return known;
    // Only humanize what actually looks like an API code.
    if (RegExp(r'^[A-Z0-9_]+$').hasMatch(raw)) {
      final spaced = raw.replaceAll('_', ' ').toLowerCase();
      return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
    }
    return raw;
  }
}
