import 'package:myreklam/constants/demande_natures.dart';

/// French labels for the demande sub-category codes (`type`) returned by the
/// API, which arrive in PascalCase (`RealEstateInvestment`, `Carpooling`, ...).
///
/// A demande's `type` refines its [DemandeNatures]; both are rendered side by
/// side as tags, so every screen showing one must go through
/// [DemandeTypes.label].
class DemandeTypes {
  const DemandeTypes._();

  static const Map<String, String> labels = {
    // Real Estate subcategories
    'RealEstateInvestment': 'Investissement immobilier',
    'LookingForRental': 'Cherche location',
    'LookingForSharedHousing': 'Cherche colocation',
    'LookingForProfessionalSpace': 'Cherche local professionnel',
    // Services subcategories
    'Ticketing': 'Billetterie',
    'ServiceProvision': 'Prestations de services',
    'Events': 'Événements',
    'Carpooling': 'Covoiturage',
    'PrivateLessons': 'Cours particuliers',
    // Pro Material subcategories
    'AgriculturalEquipment': 'Matériel agricole',
    'TransportHandling': 'Transport & Manutention',
    'ConstructionHeavyWork': 'Construction & Travaux lourds',
    'ToolsSecondaryWork': 'Outillage & Second œuvre',
    'IndustrialEquipment': 'Matériel industriel',
    'CateringHotel': 'Restauration & Hôtellerie',
    'OfficeSupplies': 'Fournitures de bureau',
    'ShopsMarkets': 'Commerces & Marchés',
    'MedicalEquipment': 'Matériel médical',
    // House subcategories
    'Furniture': 'Mobilier',
    'Appliances': 'Électroménager',
    'Tableware': 'Arts de la table',
    'Decoration': 'Décoration',
    'HomeLinen': 'Linge de maison',
    'DIY': 'Bricolage',
    'Gardening': 'Jardinage',
    // Fashion subcategories
    'Clothing': 'Vêtements',
    'Shoes': 'Chaussures',
    'AccessoriesLuggage': 'Accessoires & Bagages',
    'WatchesJewelry': 'Montres & Bijoux',
    'BabyGear': 'Équipement bébé',
    'BabyClothing': 'Vêtements bébé',
    'LuxuryTrendy': 'Luxe & Tendance',
    // Vehicle subcategories
    'Cars': 'Voitures',
    'Motorcycles': 'Motos',
    'Caravanning': 'Camping-car',
    'UtilityVehicles': 'Véhicules utilitaires',
    'Trucks': 'Poids lourds',
    'Boating': 'Bateaux',
    'CarEquipment': 'Équipement voiture',
    'MotorcycleEquipment': 'Équipement moto',
    'CaravanningEquipment': 'Équipement camping-car',
    'BoatingEquipment': 'Équipement bateau',
    // Holiday subcategories
    'RentalCottages': 'Location & Gîtes',
    'AirBnB': 'AirBnB',
    'GuestRooms': 'Chambres d\'hôtes',
    'Campings': 'Campings',
    'TrainTickets': 'Billets de train',
    'PlaneTickets': 'Billets d\'avion',
    'Hotels': 'Hôtels',
    'Stays': 'Séjours',
    // Multimedia subcategories
    'ImageSound': 'Image et son',
    'ConsolesVideoGames': 'Consoles & Jeux vidéo',
    'Phones': 'Téléphones',
    'Computing': 'Informatique',
    'DVDMovies': 'DVD - Film',
    'CDMusic': 'CD - Musique',
    'Books': 'Livres',
    // Hobbies subcategories
    'Bicycles': 'Vélos',
    'SportsHobbies': 'Sport & Loisirs',
    'MusicalInstruments': 'Instruments de musique',
    'Collections': 'Collections',
    'GamesToys': 'Jeux & Jouets',
    'WineGastronomy': 'Vin & Gastronomie',
    'Others': 'Autres',
  };

  /// Lower-cased index, built once, so lookups stay case-insensitive without
  /// scanning the whole map on every call.
  static final Map<String, String> _byLowerCaseKey = {
    for (final entry in labels.entries) entry.key.toLowerCase(): entry.value,
  };

  /// French label for [type], falling back to a humanized version of the raw
  /// code so `RealEstateInvestment` never reaches the UI verbatim.
  static String label(String? type, {String fallback = ''}) {
    if (type == null || type.trim().isEmpty) return fallback;
    final raw = type.trim();
    return _byLowerCaseKey[raw.toLowerCase()] ?? DemandeNatures.humanize(raw);
  }
}
