/// French labels for the publication status of an announce (annonce).
///
/// Shared by the announce lists, the favourites and the public profiles so a
/// status never renders as the raw `PENDING_REVIEW` code.
class AnnonceStatusLabels {
  const AnnonceStatusLabels._();

  static const Map<String, String> labels = {
    'PUBLISHED': 'Publié',
    'PENDING_REVIEW': 'En attente',
    'DRAFT': 'Brouillon',
    'REJECTED': 'Rejeté',
    'ARCHIVED': 'Archivé',
    'EXPIRED': 'Expiré',
    'SUSPENDED': 'Suspendu',
  };

  static String label(String? status, {String fallback = ''}) {
    if (status == null || status.trim().isEmpty) return fallback;
    final raw = status.trim();
    final known = labels[raw.toUpperCase()];
    if (known != null) return known;
    final spaced = raw.replaceAll('_', ' ').toLowerCase();
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
