/// Shared mapping of demande "nature" codes to their French labels.
///
/// The categories API returns English codes (`searchjob`, `realestate`, ...).
/// Older records still carry the legacy French codes (`emploi`, `logement`, ...),
/// so both are kept here. Every screen that displays a demande nature must go
/// through [DemandeNatures.label] so the list, the detail and the profile views
/// never drift apart.
class DemandeNatures {
  const DemandeNatures._();

  static const Map<String, String> labels = {
    // Codes returned by the categories API
    'searchjob': 'Recherche d\'emploi',
    'training': 'Formation',
    'realestate': 'Immobilier',
    'servicehelp': 'Services / Aide',
    'promaterial': 'Matériel pro',
    'house': 'Maison',
    'fashion': 'Mode',
    'vehicle': 'Véhicules',
    'holiday': 'Vacances',
    'multimedia': 'Multimédia',
    'hobbies': 'Loisirs',
    'animals': 'Animaux',
    'various': 'Divers',
    // Legacy codes kept for backward compatibility
    'emploi': 'Recherche d\'emploi',
    'jobsearch': 'Recherche d\'emploi',
    'service': 'Services / Aide',
    'logement': 'Immobilier',
    'formation': 'Formation',
    'produit': 'Recherche de produit',
    'product': 'Recherche de produit',
    'stage': 'Recherche de stage / alternance',
    'internship': 'Recherche de stage / alternance',
    'collaboration': 'Collaboration',
    'autre': 'Autre demande',
  };

  /// French label for [nature], falling back to a humanized version of the raw
  /// code so an unknown API value never surfaces as `searchjob` in the UI.
  static String label(String? nature, {String fallback = 'Demande'}) {
    if (nature == null || nature.trim().isEmpty) return fallback;
    return labels[nature.trim().toLowerCase()] ?? humanize(nature);
  }

  /// Turns a raw API code (`secteur_realEstate`, `pro-material`) into readable
  /// text (`Real estate`, `Pro material`) when no explicit label exists.
  static String humanize(String value) {
    final spaced = value
        .trim()
        .replaceAll(RegExp(r'^secteur[_-]'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-zà-ÿ])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ');
    if (spaced.isEmpty) return value;
    return '${spaced[0].toUpperCase()}${spaced.substring(1).toLowerCase()}';
  }
}
