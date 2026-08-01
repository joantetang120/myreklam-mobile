/// French labels for the MYS reward action types returned by the API.
///
/// Shared by the rewards screens and the MYS history so an action type never
/// renders as the raw `profile_picture` code.
class RewardActionLabels {
  const RewardActionLabels._();

  static const Map<String, String> labels = {
    'bon_plan': 'Bon plan',
    'demande': 'Demande',
    'evenement': 'Événement',
    'formation': 'Formation',
    'job_offer': 'Offre d\'emploi',
    'profile_complete': 'Profil complété',
    'comment': 'Commentaire',
    'review': 'Avis',
    'share': 'Partage',
    'event_participation': 'Participation événement',
    'training_subscription': 'Inscription formation',
    'job_application': 'Candidature',
    'referral_particulier': 'Parrainage particulier',
    'referral_pro': 'Parrainage entreprise',
    'mys_conversion': 'Conversion récompense',
    'registration': 'Inscription',
    'profile_picture': 'Photo de profil',
    'phone_added': 'Numéro de téléphone',
    'social_media': 'Réseau social',
  };

  static String label(String? actionType, {String fallback = 'Action'}) {
    if (actionType == null || actionType.trim().isEmpty) return fallback;
    final raw = actionType.trim();
    final known = labels[raw.toLowerCase()];
    if (known != null) return known;
    final spaced = raw.replaceAll('_', ' ');
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
