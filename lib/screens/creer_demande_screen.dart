import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class CreerDemandeScreen extends StatefulWidget {
  final String? demandeId;
  final Map<String, dynamic>? initialData;
  final bool shouldReturnToListingOnSuccess;

  const CreerDemandeScreen({
    super.key,
    this.demandeId,
    this.initialData,
    this.shouldReturnToListingOnSuccess = false,
  });

  bool get isEditMode => demandeId != null;

  @override
  State<CreerDemandeScreen> createState() => _CreerDemandeScreenState();
}

class _CreerDemandeScreenState extends State<CreerDemandeScreen> {
  static const String _draftKey = 'demande_draft';

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Focus tracking for helper hints
  String? _focusedField;

  // Categories API
  final String _categoriesApiUrl = 'https://api.myreklam.fr/Categorie.php';
  bool _isCategoryLoading = false;
  String? _categoryLoadError;
  List<Map<String, String>> _natureOptions = [];
  List<Map<String, String>> _typeOptions = [];
  final Map<String, String> _categoryCodeToId = {};
  final Map<String, List<Map<String, String>>> _subsByParentId = {};

  // Catégories de formation statiques (codes uniques avec préfixe)
  final List<Map<String, String>> _formationCategories = [
    {
      'code': 'formation_agriculture',
      'label': 'Agriculture, Agroalimentaire, Environnement',
    },
    {'code': 'formation_art', 'label': 'Art, Arts appliqués, Artisanat'},
    {'code': 'formation_commerce', 'label': 'Commerce, Vente, Marketing'},
    {
      'code': 'formation_communication',
      'label': 'Communication, Information, Journalisme',
    },
    {
      'code': 'formation_comptabilite',
      'label': 'Comptabilité, Gestion, Finance, Audit',
    },
    {
      'code': 'formation_construction',
      'label': 'Construction, Bâtiment, Travaux publics',
    },
    {
      'code': 'formation_developpement',
      'label': 'Développement personnel, Coaching',
    },
    {'code': 'formation_droit', 'label': 'Droit, Sciences politiques'},
    {
      'code': 'formation_education',
      'label': 'Éducation, Enseignement, Formation',
    },
    {
      'code': 'formation_hotellerie',
      'label': 'Hôtellerie, Restauration, Tourisme',
    },
    {
      'code': 'formation_industrie',
      'label': 'Industrie, Production, Maintenance',
    },
    {
      'code': 'formation_informatique',
      'label': 'Informatique, Numerique, Telecommunications',
    },
    {
      'code': 'formation_sante',
      'label': 'Sante, Social, Services a la personne',
    },
    {'code': 'formation_transport', 'label': 'Transport, Logistique, Sécurité'},
    {
      'code': 'formation_formations_reglementaires',
      'label': 'Formations réglementaires',
    },
    {
      'code': 'formation_energie',
      'label': 'Énergie, Énergies renouvelables, Nucléaire',
    },
    {
      'code': 'formation_mecanique',
      'label': 'Mécanique de précision, Aéronautique, Ferroviaire',
    },
    {
      'code': 'formation_fonction_publique',
      'label': 'Fonction publique, Collectivités',
    },
    {
      'code': 'formation_jeux_video',
      'label': 'Jeux vidéo, Animation, Multimédia',
    },
    {'code': 'formation_sciences', 'label': 'Sciences, Recherche, Qualité'},
    {'code': 'formation_langues', 'label': 'Langues étrangères'},
    {
      'code': 'formation_neurosciences',
      'label': 'Neurosciences, Apprentissage, Pédagogie innovante',
    },
    {
      'code': 'transversal',
      'label': 'Transversal, Entrepreneuriat, Soft skills',
    },
    {'code': 'statuts', 'label': 'Statuts Specifique'},
  ];

  // Types de formation statiques
  final List<Map<String, String>> _formationTypes = [
    {'code': 'initiale', 'label': 'Formation initiale'},
    {'code': 'continue', 'label': 'Formation continue'},
    {'code': 'alternance', 'label': 'Formation en alternance'},
    {'code': 'certifiante', 'label': 'Formation certifiante'},
    {'code': 'diplomante', 'label': 'Formation diplomante'},
    {'code': 'qualifiant', 'label': 'Programme qualifiant'},
    {'code': 'professionnelle', 'label': 'Formation professionnelle'},
    {'code': 'mixte', 'label': 'Formation mixte (présentiel/e-learning)'},
    {'code': 'en_ligne', 'label': 'Formation en ligne (e-learning)'},
    {'code': 'intensive', 'label': 'Formation intensive'},
    {'code': 'vae', 'label': 'Validation des acquis de compétence (VAE)'},
    {'code': 'stage', 'label': 'Stage/Immersion professionelle'},
  ];

  // Secteurs d'activité pour Emploi/Stage (codes uniques avec préfixe)
  final List<Map<String, String>> _secteursActivite = [
    {'code': 'secteur_achats', 'label': 'Achats'},
    {'code': 'secteur_administratif', 'label': 'Administratif'},
    {'code': 'secteur_aeronautique', 'label': 'Aéronautique'},
    {'code': 'secteur_agriculture', 'label': 'Agriculture'},
    {'code': 'secteur_agroalimentaire', 'label': 'Agroalimentaire'},
    {'code': 'secteur_architecture', 'label': 'Architecture'},
    {'code': 'secteur_artisanat', 'label': 'Artisanat'},
    {'code': 'secteur_assurances', 'label': 'Assurances'},
    {'code': 'secteur_audiovisuel', 'label': 'Audiovisuel'},
    {'code': 'secteur_audit', 'label': 'Audit'},
    {'code': 'secteur_automobile', 'label': 'Automobile'},
    {'code': 'secteur_banque', 'label': 'Banque'},
    {'code': 'secteur_batiment', 'label': 'Bâtiment'},
    {'code': 'secteur_beaute', 'label': 'Beauté'},
    {'code': 'secteur_bois', 'label': 'Bois'},
    {'code': 'secteur_chimie', 'label': 'Chimie'},
    {'code': 'secteur_commerce', 'label': 'Commerce'},
    {'code': 'secteur_communication', 'label': 'Communication'},
    {'code': 'secteur_comptabilite', 'label': 'Comptabilité'},
    {'code': 'secteur_conseil', 'label': 'Conseil'},
    {'code': 'secteur_construction', 'label': 'Construction'},
    {'code': 'secteur_culture', 'label': 'Culture'},
    {'code': 'secteur_defense', 'label': 'Défense'},
    {'code': 'secteur_design', 'label': 'Design'},
    {'code': 'secteur_distribution', 'label': 'Distribution'},
    {'code': 'secteur_droit', 'label': 'Droit'},
    {'code': 'secteur_edition', 'label': 'Édition'},
    {'code': 'secteur_education', 'label': 'Éducation'},
    {'code': 'secteur_electronique', 'label': 'Électronique'},
    {'code': 'secteur_energie', 'label': 'Énergie'},
    {'code': 'secteur_enseignement', 'label': 'Enseignement'},
    {'code': 'secteur_environnement', 'label': 'Environnement'},
    {'code': 'secteur_evenementiel', 'label': 'Événementiel'},
    {'code': 'secteur_finance', 'label': 'Finance'},
    {'code': 'secteur_fonction_publique', 'label': 'Fonction publique'},
    {'code': 'secteur_hotellerie', 'label': 'Hôtellerie'},
    {'code': 'secteur_immobilier', 'label': 'Immobilier'},
    {'code': 'secteur_industrie', 'label': 'Industrie'},
    {'code': 'secteur_informatique', 'label': 'Informatique'},
    {'code': 'secteur_ingenierie', 'label': 'Ingénierie'},
    {'code': 'secteur_internet', 'label': 'Internet'},
    {'code': 'secteur_journalisme', 'label': 'Journalisme'},
    {'code': 'secteur_juridique', 'label': 'Juridique'},
    {'code': 'secteur_logistique', 'label': 'Logistique'},
    {'code': 'secteur_luxe', 'label': 'Luxe'},
    {'code': 'secteur_marketing', 'label': 'Marketing'},
    {'code': 'secteur_mecanique', 'label': 'Mécanique'},
    {'code': 'secteur_medical', 'label': 'Médical'},
    {'code': 'secteur_mode', 'label': 'Mode'},
    {'code': 'secteur_multimedia', 'label': 'Multimédia'},
    {'code': 'secteur_naval', 'label': 'Naval'},
    {'code': 'secteur_pharmaceutique', 'label': 'Pharmaceutique'},
    {'code': 'secteur_production', 'label': 'Production'},
    {'code': 'secteur_publicite', 'label': 'Publicité'},
    {'code': 'secteur_qualite', 'label': 'Qualité'},
    {'code': 'secteur_recherche', 'label': 'Recherche'},
    {'code': 'secteur_restauration', 'label': 'Restauration'},
    {'code': 'secteur_ressources_humaines', 'label': 'Ressources humaines'},
    {'code': 'secteur_sante', 'label': 'Santé'},
    {'code': 'secteur_securite', 'label': 'Sécurité'},
    {'code': 'secteur_services', 'label': 'Services'},
    {'code': 'secteur_social', 'label': 'Social'},
    {'code': 'secteur_sport', 'label': 'Sport'},
    {'code': 'secteur_telecommunication', 'label': 'Télécommunication'},
    {'code': 'secteur_textile', 'label': 'Textile'},
    {'code': 'secteur_tourisme', 'label': 'Tourisme'},
    {'code': 'secteur_transport', 'label': 'Transport'},
    {'code': 'secteur_travail_temporaire', 'label': 'Travail temporaire'},
    {'code': 'secteur_vente', 'label': 'Vente'},
  ];

  // Secteurs d'activité pour Emploi/Stage
  final List<Map<String, String>> _allFunction = [
    {'code': 'administratif', 'label': 'Agent de bureau'},
    {'code': 'aeronautique', 'label': 'Agent de liaison'},
    {'code': 'agriculture', 'label': 'Adjoint DAF'},
  ];

  // Options pour le dropdown immobilier (codes uniques)
  final List<Map<String, String>> _immobilierTypeOptions = [
    {'code': 'RealEstateInvestment', 'label': 'Investissement immobilier'},
    {'code': 'LookingForRental', 'label': 'Cherche location'},
    {'code': 'LookingForSharedHousing', 'label': 'Cherche colocation'},
    {
      'code': 'LookingForProfessionalSpace',
      'label': 'Cherche local professionel',
    },
  ];

  // Job categories API (for Emploi/Stage forms)
  bool _isJobCategoriesLoading = false;
  String? _jobCategoriesLoadError;
  List<Map<String, String>> _jobSecteursOptions = [];
  final Map<String, String> _jobSecteursCodeToId = {};
  final Map<String, List<Map<String, String>>> _jobFonctionsByParentId = {};

  // Step 1 - Nature
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedFormationType;
  String? _selectedFormationSector;
  String? _selectedFunction;

  // Variables séparées pour Emploi/Stage afin d'éviter les conflits
  String? _selectedSecteurActivite;

  // Variable séparée pour Formation afin d'éviter les conflits
  String? _selectedFormationCategory;

  // Variable séparée pour Immobilier afin d'éviter les conflits
  String? _selectedImmobilierType;

  // Step 2 - Details
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionQuillController = QuillController.basic();
  bool _acceptDemand = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _prixInitialController = TextEditingController();
  final TextEditingController _prixFinalController = TextEditingController();

  // Formation spécifique
  List<String> _selectedTeachingTypes = [];
  List<String> _selectedFinancingTypes = [];
  final TextEditingController _nbPersonnesController = TextEditingController();
  final TextEditingController _nbGroupesController = TextEditingController();
  bool _dansImmediat = false;
  bool _docCand = false;
  bool _aDefinir = false;

  // Immobilier spécifique
  final List<String> _selectedTypeBien = [];
  final TextEditingController _surfaceHabitableMinController =
      TextEditingController();
  final TextEditingController _surfaceHabitableMaxController =
      TextEditingController();
  final TextEditingController _surfaceTerrainMinController =
      TextEditingController();
  final TextEditingController _surfaceTerrainMaxController =
      TextEditingController();
  String? _nbPieces;
  String? _nbChambres;
  String? _meuble; // 'meuble', 'non_meuble', 'indifferent'

  // Emploi/Stage spécifique
  List<String> _selectedTypeContrat = [];
  String? _tempsPartielPlein;
  String? _trancheSalariale;
  final TextEditingController _salaryMinController = TextEditingController();
  final TextEditingController _salaryMaxController = TextEditingController();
  String? _salaryNetOrBrut = 'brut'; // 'net' ou 'brut'
  String? _salaryIndiceTemporel = 'annees'; // 'annees' ou 'heures' ou 'mois'
  String? _niveauEtudes;
  String? _niveauExperience;
  bool _accepteTeletravaill = false;
  String? _cvOption; // 'cv', 'lettre_motivation', 'portfolio'
  final List<String> _selectedCvOptions = [];

  // Step 3 - Localisation
  final TextEditingController _disponibleChezController =
      TextEditingController();
  bool _touteLaFrance = false;
  bool _useCurrentLocation = false;
  bool _showGoogleLocation = false;
  double _rayonRecherche = 0;

  // Media (photos from _buildStepPhoto)
  final List<PlatformFile> _selectedMediaFiles = [];
  final List<String> _existingMediaUrls = [];
  bool _isUploadingMedia = false;

  // Documents (CV, lettre de motivation, portfolio from Emploi/Stage forms)
  final List<PlatformFile> _selectedDocumentFiles = [];
  final Map<String, PlatformFile> _documentFilesByType = {}; // type -> file

  // Review
  bool _acceptMessages = false;

  // Submission state
  bool _isSubmitting = false;

  // User Role
  String? userRole;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _loadDemandeCategories();
    _loadJobCategories(); // Charger les catégories d'emploi pour les formulaires Emploi/Stage
    if (_isEditMode) {
      _prefillFromInitialData();
    } else {
      _checkForSavedProgress();
    }
  }

  void _prefillFromInitialData() {
    final data = widget.initialData;
    if (data == null) return;

    _titleController.text = data['title']?.toString() ?? '';
    _disponibleChezController.text = data['location']?.toString() ?? '';
    _selectedCategory = data['nature']?.toString();
    _selectedType = data['type']?.toString();
    _acceptDemand = data['urgent'] == true;
    if (data['start_date'] != null)
      _startDate = DateTime.tryParse(data['start_date'].toString());
    if (data['end_date'] != null)
      _endDate = DateTime.tryParse(data['end_date'].toString());
    _touteLaFrance = data['nationwide'] == true;
    _useCurrentLocation = data['use_current_location'] == true;
    _showGoogleLocation = data['show_google_location'] == true;
    _acceptMessages = data['accept_messages'] == true;

    final budgetMin = data['budget_min'];
    final budgetMax = data['budget_max'];
    if (budgetMin != null) _prixInitialController.text = budgetMin.toString();
    if (budgetMax != null) _prixFinalController.text = budgetMax.toString();

    final radius = data['search_radius_km'];
    if (radius != null) {
      _rayonRecherche = (radius is int)
          ? radius.toDouble()
          : (double.tryParse(radius.toString()) ?? 0);
    }

    // Load existing media URLs
    final mediaFiles =
        data['media_files'] as List? ?? data['media'] as List? ?? [];
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    for (final media in mediaFiles) {
      if (media is Map && media['url'] != null) {
        final url = media['url'].toString();
        if (url.isNotEmpty) {
          String fullUrl;
          if (url.startsWith('http')) {
            fullUrl = url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);
          } else {
            fullUrl = '$serverBase$url';
          }
          _existingMediaUrls.add(fullUrl);
        }
      }
    }

    if (_selectedCategory != null) {
      _typeOptions = _getSubCategoriesForCode(_selectedCategory);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDescription(data);
    });
  }

  void _restoreDescription(Map<String, dynamic> data) {
    final descDelta = data['description_delta'];
    bool deltaRestored = false;

    if (descDelta != null) {
      try {
        List opsList;
        if (descDelta is List) {
          opsList = descDelta;
        } else if (descDelta is Map && descDelta['ops'] is List) {
          opsList = descDelta['ops'] as List;
        } else if (descDelta is String && descDelta.isNotEmpty) {
          String jsonString = descDelta;
          jsonString = jsonString.replaceAllMapped(
            RegExp(r'(\{|,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
            (match) => '${match.group(1)}"${match.group(2)}":',
          );
          jsonString = jsonString.replaceAllMapped(
            RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_\s]*?)(\s*[,\}\]])'),
            (match) {
              final value = match.group(1)!.trim();
              if (value == 'true' || value == 'false' || value == 'null') {
                return ': $value${match.group(2)}';
              }
              return ': "$value"${match.group(2)}';
            },
          );
          dynamic rawData = jsonDecode(jsonString);
          if (rawData is String) rawData = jsonDecode(rawData);
          if (rawData is List) {
            opsList = rawData;
          } else if (rawData is Map && rawData['ops'] is List) {
            opsList = rawData['ops'] as List;
          } else {
            throw Exception('Unknown delta format');
          }
        } else {
          throw Exception('Unsupported descDelta type');
        }

        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();

        if (filteredOps.isNotEmpty) {
          final lastInsert = filteredOps.last['insert'];
          if (lastInsert is String && !lastInsert.endsWith('\n')) {
            filteredOps.add({'insert': '\n'});
          }
          _descriptionQuillController.document = Document.fromJson(filteredOps);
          deltaRestored = true;
        }
      } catch (e) {
        debugPrint('Error restoring demande description delta: $e');
      }
    }

    if (!deltaRestored) {
      final plainDesc = data['description']?.toString() ?? '';
      if (plainDesc.isNotEmpty) {
        final doc = Document();
        doc.insert(0, plainDesc);
        _descriptionQuillController.document = doc;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkForSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_draftKey);
    if (savedData != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showContinueOrNewModal();
      });
    }
  }

  Future<void> _showContinueOrNewModal() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Formulaire en cours'),
        content: const Text(
          'Vous avez une demande non terminée. Voulez-vous continuer où vous vous êtes arrêté ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nouveau formulaire'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAE5E),
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _restoreFormData();
    } else {
      await _clearSavedProgress();
    }
  }

  Future<void> _saveFormProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formData = {
        'step': _currentStep,
        'category': _selectedCategory,
        'type': _selectedType,
        'function': _selectedFunction,
        'title': _titleController.text,
        'description_delta': jsonEncode(
          _descriptionQuillController.document.toDelta().toJson(),
        ),
        'urgent': _acceptDemand,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'budget_min': _prixInitialController.text,
        'budget_max': _prixFinalController.text,
        'location': _disponibleChezController.text,
        'toute_la_france': _touteLaFrance,
        'use_current_location': _useCurrentLocation,
        'show_google_location': _showGoogleLocation,
        'rayon': _rayonRecherche,
        'accept_messages': _acceptMessages,
        // Nouvelles variables pour Emploi/Stage
        'temps_partiel_plein': _tempsPartielPlein,
        'niveau_etudes': _niveauEtudes,
        'niveau_experience': _niveauExperience,
        'accepte_teletravail': _accepteTeletravaill,
        'dans_immediat': _dansImmediat,
        'type_contrat': _selectedTypeContrat,
        // Nouvelles variables pour Formation
        'formation_type': _selectedFormationType,
        'formation_sector': _selectedFormationSector,
        'tranche_salariale': _trancheSalariale,
        'salary_min': _salaryMinController.text,
        'salary_max': _salaryMaxController.text,
        'salary_net_or_brut': _salaryNetOrBrut,
        'salary_indice_temporel': _salaryIndiceTemporel,
        // Variables Emploi/Stage
        'secteur_activite': _selectedSecteurActivite,
        // Variables Formation
        'formation_category': _selectedFormationCategory,
        // Variables Immobilier
        'immobilier_type': _selectedImmobilierType,
        'type_bien': _selectedTypeBien,
        'surface_habitable_min': _surfaceHabitableMinController.text,
        'surface_habitable_max': _surfaceHabitableMaxController.text,
        'surface_terrain_min': _surfaceTerrainMinController.text,
        'surface_terrain_max': _surfaceTerrainMaxController.text,
        'nb_pieces': _nbPieces,
        'nb_chambres': _nbChambres,
        'meuble': _meuble,
        // Documents
        'doc_cand': _docCand,
        'selected_cv_options': _selectedCvOptions,
        'document_files_count': _selectedDocumentFiles.length,
        // Formation spécifique
        'nb_personnes': _nbPersonnesController.text,
        'nb_groupes': _nbGroupesController.text,
        'a_definir': _aDefinir,
        'financingTypes': _selectedFinancingTypes,
        'teachingTypes': _selectedTeachingTypes,
      };
      await prefs.setString(_draftKey, jsonEncode(formData));
    } catch (e) {
      debugPrint('Error saving demande draft: $e');
    }
  }

  Future<void> _restoreFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_draftKey);
      if (savedData == null) return;
      final formData = jsonDecode(savedData) as Map<String, dynamic>;
      setState(() {
        _currentStep = formData['step'] ?? 0;
        _selectedCategory = formData['category'];
        _selectedType = formData['type'];
        _selectedFunction = formData['function'];
        _titleController.text = formData['title'] ?? '';
        _prixInitialController.text = formData['budget_min'] ?? '';
        _prixFinalController.text = formData['budget_max'] ?? '';
        _disponibleChezController.text = formData['location'] ?? '';
        _acceptDemand = formData['urgent'] ?? false;
        if (formData['start_date'] != null)
          _startDate = DateTime.tryParse(formData['start_date'].toString());
        if (formData['end_date'] != null)
          _endDate = DateTime.tryParse(formData['end_date'].toString());
        _touteLaFrance = formData['toute_la_france'] ?? false;
        _useCurrentLocation = formData['use_current_location'] ?? false;
        _showGoogleLocation = formData['show_google_location'] ?? false;
        _rayonRecherche = (formData['rayon'] ?? 0).toDouble();
        _acceptMessages = formData['accept_messages'] ?? false;

        // Restaurer les nouvelles variables Emploi/Stage
        _tempsPartielPlein = formData['temps_partiel_plein'];
        _niveauEtudes = formData['niveau_etudes'];
        _niveauExperience = formData['niveau_experience'];
        _accepteTeletravaill = formData['accepte_teletravail'] ?? false;
        _dansImmediat = formData['dans_immediat'] ?? false;
        if (formData['type_contrat'] is List) {
          _selectedTypeContrat = List<String>.from(formData['type_contrat']);
        }

        // Restaurer les nouvelles variables Formation
        _selectedFormationType = formData['formation_type'];
        _selectedFormationSector = formData['formation_sector'];
        _trancheSalariale = formData['tranche_salariale'];
        _salaryMinController.text = formData['salary_min'] ?? '';
        _salaryMaxController.text = formData['salary_max'] ?? '';
        _salaryNetOrBrut = formData['salary_net_or_brut'];
        _salaryIndiceTemporel = formData['salary_indice_temporel'];

        // Restaurer les variables Emploi/Stage
        _selectedSecteurActivite = formData['secteur_activite'];

        // Restaurer les variables Formation
        _selectedFormationCategory = formData['formation_category'];

        // Restaurer les variables Immobilier
        _selectedImmobilierType = formData['immobilier_type'];
        if (formData['type_bien'] is List) {
          _selectedTypeBien.clear();
          _selectedTypeBien.addAll(List<String>.from(formData['type_bien']));
        }
        _surfaceHabitableMinController.text =
            formData['surface_habitable_min'] ?? '';
        _surfaceHabitableMaxController.text =
            formData['surface_habitable_max'] ?? '';
        _surfaceTerrainMinController.text =
            formData['surface_terrain_min'] ?? '';
        _surfaceTerrainMaxController.text =
            formData['surface_terrain_max'] ?? '';
        _nbPieces = formData['nb_pieces'];
        _nbChambres = formData['nb_chambres'];
        _meuble = formData['meuble'];

        if (formData['financingTypes'] is List) {
          _selectedFinancingTypes = List<String>.from(
            formData['financingTypes'],
          );
        }
        if (formData['teachingTypes'] is List) {
          _selectedTeachingTypes = List<String>.from(formData['teachingTypes']);
        }

        // Restaurer les nouvelles variables documents
        _docCand = formData['doc_cand'] ?? false;
        if (formData['selected_cv_options'] is List) {
          _selectedCvOptions.clear();
          _selectedCvOptions.addAll(
            List<String>.from(formData['selected_cv_options']),
          );
        }
        // Note: _selectedDocumentFiles cannot be restored from SharedPreferences
        // as PlatformFile objects cannot be serialized. User will need to re-select files.

        // Restaurer les variables spécifiques Formation
        _nbPersonnesController.text = formData['nb_personnes'] ?? '';
        _nbGroupesController.text = formData['nb_groupes'] ?? '';
        _aDefinir = formData['a_definir'] ?? false;

        if (_selectedCategory != null) {
          _typeOptions = _getSubCategoriesForCode(_selectedCategory);
        }
      });
      if (formData['description_delta'] != null) {
        try {
          final delta = jsonDecode(formData['description_delta']);
          _descriptionQuillController.document = Document.fromJson(delta);
        } catch (e) {
          debugPrint('Error restoring description: $e');
        }
      }
    } catch (e) {
      debugPrint('Error restoring demande draft: $e');
    }
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (e) {
      debugPrint('Error clearing demande draft: $e');
    }
  }

  Future<void> _handleBackButton() async {
    if (_isEditMode) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Quitter la modification ?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Les modifications non enregistrées seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quitter'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder votre progression ?'),
        content: const Text(
          'Voulez-vous sauvegarder votre progression pour continuer plus tard ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Abandonner'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAE5E),
            ),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _saveFormProgress();
      if (mounted) Navigator.pop(context);
    } else if (result == 'discard') {
      await _clearSavedProgress();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _loadDemandeCategories() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryLoadError = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_categoriesApiUrl),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: const {'Method': 'getByType', 'type': 'demandes'},
      );

      if (response.statusCode != 200) {
        throw Exception('Status code ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']?.toString() ??
                  'Réponse invalide du service des catégories.'
            : 'Réponse invalide du service des catégories.';
        throw Exception(message);
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Structure de données inattendue.');
      }

      final mainRaw = data['main'];
      final subsRaw = data['subs'];

      final parsedNatures = <Map<String, String>>[];
      final parsedCodeToId = <String, String>{};

      if (mainRaw is List) {
        for (final item in mainRaw) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString();
            final code = item['code']?.toString();
            final label = (item['label'] ?? item['labelEn'])?.toString();
            if (id != null && code != null && label != null) {
              parsedNatures.add({'id': id, 'code': code, 'label': label});
              parsedCodeToId[code] = id;
            }
          }
        }
      }

      final parsedSubs = <String, List<Map<String, String>>>{};
      if (subsRaw is Map) {
        subsRaw.forEach((key, value) {
          final parentId = key.toString();
          if (value is List) {
            final subList = <Map<String, String>>[];
            for (final sub in value) {
              if (sub is Map<String, dynamic>) {
                final subCode = sub['code']?.toString();
                final subLabel = (sub['label'] ?? sub['labelEn'])?.toString();
                if (subCode != null && subLabel != null) {
                  subList.add({'code': subCode, 'label': subLabel});
                }
              }
            }
            parsedSubs[parentId] = subList;
          }
        });
      }

      // Filtrer les catégories selon le type d'utilisateur
      userRole = await _getUserRole();
      final filteredNatures = _filterNatureByRole(parsedNatures, userRole!);

      // Convertir filteredNatures en List<Map<String, String>>
      final convertedNatures = <Map<String, String>>[];
      for (final nature in filteredNatures) {
        final stringNature = <String, String>{};
        for (final key in nature.keys) {
          stringNature[key] = nature[key]?.toString() ?? '';
        }
        convertedNatures.add(stringNature);
      }

      setState(() {
        _natureOptions = convertedNatures;
        print("Filtered nature for $userRole: $_natureOptions");
        _categoryCodeToId
          ..clear()
          ..addAll(parsedCodeToId);
        _subsByParentId
          ..clear()
          ..addAll(parsedSubs);
        _isCategoryLoading = false;
        // In edit mode, re-populate type options from the now-loaded categories
        if (_isEditMode && _selectedCategory != null) {
          // Validate _selectedCategory exists in loaded nature options
          final hasNatureCode = parsedNatures.any(
            (o) => o['code'] == _selectedCategory,
          );
          if (!hasNatureCode) {
            // Fallback: try matching by label (API may return label instead of code)
            final matchByLabel = parsedNatures.firstWhere(
              (o) => o['label'] == _selectedCategory,
              orElse: () => {},
            );
            if (matchByLabel.containsKey('code')) {
              _selectedCategory = matchByLabel['code'];
            }
          }
          _typeOptions = _getSubCategoriesForCode(_selectedCategory);
          // Validate _selectedType exists in loaded options
          if (_selectedType != null && _typeOptions.isNotEmpty) {
            final hasCode = _typeOptions.any((o) => o['code'] == _selectedType);
            if (!hasCode) {
              // Fallback: try matching by label (API may return label instead of code)
              final matchByLabel = _typeOptions.firstWhere(
                (o) => o['label'] == _selectedType,
                orElse: () => {},
              );
              if (matchByLabel.containsKey('code')) {
                _selectedType = matchByLabel['code'];
              } else {
                _selectedType = null;
              }
            }
          }
        } else {
          _typeOptions = [];
        }
      });
    } catch (e) {
      debugPrint('Error loading demande categories: $e');
      setState(() {
        _categoryLoadError =
            'Impossible de charger les natures. Veuillez réessayer.';
        _isCategoryLoading = false;
      });
    }
  }

  List<Map<String, String>> _getSubCategoriesForCode(String? categoryCode) {
    if (categoryCode == null) return [];
    final parentId = _categoryCodeToId[categoryCode];
    if (parentId == null) return [];
    final subs = _subsByParentId[parentId];
    if (subs == null) return [];
    return List<Map<String, String>>.from(subs);
  }

  // Obtenir les secteurs de formation selon la catégorie sélectionnée
  List<Map<String, String>> _getFormationSectors(String? categoryValue) {
    if (categoryValue == null) return [];

    // Si c'est déjà un code connu, l'utiliser directement
    String codeToUse = categoryValue;

    // Sinon, chercher le code correspondant au label
    if (!categoryValue.startsWith('formation_')) {
      final match = _formationCategories.firstWhere(
        (cat) => cat['label'] == categoryValue,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        codeToUse = match['code']!;
      }
    }

    switch (codeToUse) {
      case 'formation_langues':
        return [
          {'code': 'anglais', 'label': 'Anglais professionnel'},
          {'code': 'espagnol', 'label': 'Espagnol'},
          {'code': 'allemand', 'label': 'Allemand'},
          {'code': 'italien', 'label': 'Italien'},
          {'code': 'mandarin', 'label': 'Mandarin'},
          {'code': 'arabe', 'label': 'Arabe'},
          {'code': 'japonais', 'label': 'Japonais'},
        ];
      case 'formation_informatique':
        return [
          {'code': 'dev_web', 'label': 'Développement web'},
          {'code': 'dev_mobile', 'label': 'Développement mobile'},
          {'code': 'data_science', 'label': 'Data Science / IA'},
          {'code': 'cybersecurite', 'label': 'Cybersécurité'},
          {'code': 'reseaux', 'label': 'Réseaux et systèmes'},
          {'code': 'devops', 'label': 'DevOps'},
        ];
      case 'formation_commerce':
        return [
          {'code': 'vente', 'label': 'Techniques de vente'},
          {'code': 'negociation', 'label': 'Négociation commerciale'},
          {'code': 'marketing_digital', 'label': 'Marketing digital'},
          {'code': 'relation_client', 'label': 'Relation client'},
        ];
      case 'formation_sante':
        return [
          {'code': 'soins_infirmiers', 'label': 'Soins infirmiers'},
          {'code': 'aide_soignant', 'label': 'Aide-soignant'},
          {'code': 'auxiliaire_vie', 'label': 'Auxiliaire de vie'},
          {'code': 'kinesitherapie', 'label': 'Kinésithérapie'},
        ];
      default:
        return [];
    }
  }

  /// Load job categories (secteurs d'activité) from API for Emploi/Stage forms
  Future<void> _loadJobCategories() async {
    setState(() {
      _isJobCategoriesLoading = true;
      _jobCategoriesLoadError = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_categoriesApiUrl),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: const {'Method': 'getByType', 'type': 'offres_emploi'},
      );

      if (response.statusCode != 200) {
        throw Exception('Status code ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']?.toString() ??
                  'Réponse invalide du service des catégories.'
            : 'Réponse invalide du service des catégories.';
        throw Exception(message);
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Structure de données inattendue.');
      }

      final mainRaw = data['main'];
      final subsRaw = data['subs'];

      final parsedSecteurs = <Map<String, String>>[];
      final parsedCodeToId = <String, String>{};

      if (mainRaw is List) {
        for (final item in mainRaw) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString();
            final code = item['code']?.toString();
            final label = (item['label'] ?? item['labelEn'])?.toString();
            if (id != null && code != null && label != null) {
              parsedSecteurs.add({'id': id, 'code': code, 'label': label});
              parsedCodeToId[code] = id;
            }
          }
        }
      }

      final parsedFonctions = <String, List<Map<String, String>>>{};
      if (subsRaw is Map) {
        subsRaw.forEach((key, value) {
          final parentId = key.toString();
          if (value is List) {
            final foncList = <Map<String, String>>[];
            for (final fonc in value) {
              if (fonc is Map<String, dynamic>) {
                final foncCode = fonc['code']?.toString();
                final foncLabel = (fonc['label'] ?? fonc['labelEn'])
                    ?.toString();
                if (foncCode != null && foncLabel != null) {
                  foncList.add({'code': foncCode, 'label': foncLabel});
                }
              }
            }
            parsedFonctions[parentId] = foncList;
          }
        });
      }

      setState(() {
        _jobSecteursOptions = parsedSecteurs;
        _jobSecteursCodeToId
          ..clear()
          ..addAll(parsedCodeToId);
        _jobFonctionsByParentId
          ..clear()
          ..addAll(parsedFonctions);
        _isJobCategoriesLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading job categories: $e');
      setState(() {
        _jobCategoriesLoadError =
            'Impossible de charger les secteurs d\'activité.';
        _isJobCategoriesLoading = false;
      });
    }
  }

  /// Get fonctions (sub-categories) for a selected secteur d'activité
  List<Map<String, String>> _getJobFonctionsForSecteur(String? secteurCode) {
    if (secteurCode == null) return [];
    final parentId = _jobSecteursCodeToId[secteurCode];
    if (parentId == null) return [];
    final fonctions = _jobFonctionsByParentId[parentId];
    if (fonctions == null) return [];
    return List<Map<String, String>>.from(fonctions);
  }

  void _onNatureChanged(String? code) {
    setState(() {
      _selectedCategory = code;
      // _selectedType = null;
      _typeOptions = _getSubCategoriesForCode(code);
    });
  }

  Future<void> _submitDemande() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null)
        throw Exception('Session expirée. Veuillez vous reconnecter.');

      final payload = _buildDemandePayload();
      final uri = _isEditMode
          ? Uri.parse('${ApiConfig.baseUrl}/demandes/${widget.demandeId}')
          : Uri.parse('${ApiConfig.baseUrl}/demandes');
      final response = _isEditMode
          ? await http.put(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            )
          : await http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(payload),
            );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          final demandeData = decoded['data'];
          final demandeId = _isEditMode
              ? widget.demandeId
              : (demandeData is Map ? demandeData['id']?.toString() : null);
          if ((_selectedMediaFiles.isNotEmpty ||
                  _selectedDocumentFiles.isNotEmpty) &&
              demandeId != null) {
            await _uploadMediaFiles(demandeId);
          }
          await _clearSavedProgress();
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          _showSuccessDialog();

          // Award My's for creating a demande (only on create, not edit)
          if (!_isEditMode) {
            try {
              final mysResponse = await MysEarningService().awardMys(
                actionType: 'demande',
                referenceId: demandeId,
              );

              if (mysResponse['success'] == true && mounted) {
                // Update UserSession with new balance
                final newBalance = mysResponse['earning']?['new_balance'];
                if (newBalance != null) {
                  UserSession().updateMys(newBalance);
                }

                // Show reward modal AFTER dialog closes - use microtask to avoid conflict
                Future.microtask(() async {
                  if (mounted) {
                    await MysRewardModal.show(
                      context,
                      amount: mysResponse['earning']?['amount'] ?? 2,
                      actionType: 'demande',
                    );
                  }
                });
              }
            } catch (e) {
              debugPrint("Error awarding My's for demande: $e");
              // Don't block the user if awarding fails
            }
          }
          return;
        }
      }
      final errorMsg =
          _extractErrorMessage(response.body) ??
          (_isEditMode
              ? 'Impossible de modifier la demande (code ${response.statusCode}).'
              : 'Impossible de créer la demande (code ${response.statusCode}).');
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('Error submitting demande: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  Map<String, dynamic> _buildDemandePayload() {
    final description = _descriptionQuillController.document
        .toPlainText()
        .trim();
    final descriptionDelta = _descriptionQuillController.document
        .toDelta()
        .toJson();
    final payload = <String, dynamic>{
      'nature': _selectedCategory,
      'type': _selectedType,
      'function': _selectedFunction,
      'title': _titleController.text.trim(),
      'description': description,
      'description_delta': descriptionDelta,
      'urgent': _acceptDemand,
      if (!_acceptDemand && _startDate != null)
        'start_date': _startDate!.toIso8601String().split('T').first,
      if (!_acceptDemand && _endDate != null)
        'end_date': _endDate!.toIso8601String().split('T').first,
      'accept_messages': _acceptMessages,
      'nationwide': _touteLaFrance,
      'use_current_location': _useCurrentLocation,
      'show_google_location': _showGoogleLocation,
      'status': 'pending',

      // Variables Emploi/Stage
      if (_tempsPartielPlein != null) 'work_type': _tempsPartielPlein,
      if (_niveauEtudes != null) 'education_level': _niveauEtudes,
      if (_niveauExperience != null) 'experience_level': _niveauExperience,
      if (_accepteTeletravaill != null)
        'accept_remote_work': _accepteTeletravaill,
      if (_dansImmediat != null) 'immediate_availability': _dansImmediat,
      if (_trancheSalariale != null) 'salary_range': _trancheSalariale,
      if (_salaryMinController.text.trim().isNotEmpty)
        'salary_min': int.tryParse(_salaryMinController.text.trim()),
      if (_salaryMaxController.text.trim().isNotEmpty)
        'salary_max': int.tryParse(_salaryMaxController.text.trim()),
      if (_salaryNetOrBrut != null) 'salary_net_or_brut': _salaryNetOrBrut,
      if (_salaryIndiceTemporel != null)
        'salary_indice_temporel': _salaryIndiceTemporel,
      if (_selectedSecteurActivite != null)
        'activity_sector': _selectedSecteurActivite,
      if (_selectedTypeContrat.isNotEmpty)
        'contract_types': _selectedTypeContrat,

      // Variables Formation
      if (_selectedFormationCategory != null)
        'training_category': _selectedFormationCategory,
      if (_selectedFormationType != null)
        'training_type': _selectedFormationType,
      if (_selectedFormationSector != null)
        'training_sector': _selectedFormationSector,

      // Variables Immobilier
      if (_selectedImmobilierType != null)
        'real_estate_type': _selectedImmobilierType,
      if (_selectedTypeBien.isNotEmpty) 'property_types': _selectedTypeBien,
      if (_surfaceHabitableMinController.text.trim().isNotEmpty)
        'surface_habitable_min': int.tryParse(
          _surfaceHabitableMinController.text.trim(),
        ),
      if (_surfaceHabitableMaxController.text.trim().isNotEmpty)
        'surface_habitable_max': int.tryParse(
          _surfaceHabitableMaxController.text.trim(),
        ),
      if (_surfaceTerrainMinController.text.trim().isNotEmpty)
        'surface_terrain_min': int.tryParse(
          _surfaceTerrainMinController.text.trim(),
        ),
      if (_surfaceTerrainMaxController.text.trim().isNotEmpty)
        'surface_terrain_max': int.tryParse(
          _surfaceTerrainMaxController.text.trim(),
        ),
      if (_nbPieces != null && _nbPieces != 'Indifférent')
        'nb_pieces': _nbPieces,
      if (_nbChambres != null && _nbChambres != 'Indifférent')
        'nb_chambres': _nbChambres,
      if (_meuble != null) 'meuble': _meuble,
      if (_selectedFinancingTypes.isNotEmpty)
        'financing_types': _selectedFinancingTypes,
      if (_selectedTeachingTypes.isNotEmpty)
        'teaching_types': _selectedTeachingTypes,

      // Documents
      if (_docCand != null) 'use_candidate_documents': _docCand,
      if (_selectedCvOptions.isNotEmpty) 'cv_options': _selectedCvOptions,

      // Variables spécifiques Formation
      if (_nbPersonnesController.text.trim().isNotEmpty)
        'nb_personnes': int.tryParse(_nbPersonnesController.text.trim()),
      if (_nbGroupesController.text.trim().isNotEmpty)
        'nb_groupes': int.tryParse(_nbGroupesController.text.trim()),
      if (_aDefinir != null) 'a_definir': _aDefinir,
    };
    if (_prixInitialController.text.trim().isNotEmpty) {
      final v = double.tryParse(
        _prixInitialController.text.replaceAll(',', '.'),
      );
      if (v != null && v > 0) payload['budget_min'] = v;
    }
    if (_prixFinalController.text.trim().isNotEmpty) {
      final v = double.tryParse(_prixFinalController.text.replaceAll(',', '.'));
      if (v != null && v > 0) payload['budget_max'] = v;
    }
    if (_disponibleChezController.text.trim().isNotEmpty) {
      payload['location'] = _disponibleChezController.text.trim();
    }
    if (_rayonRecherche > 0) {
      payload['search_radius_km'] = _rayonRecherche.toInt();
    }
    payload.removeWhere((k, v) => v == null || (v is String && v.isEmpty));
    return payload;
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['message'] != null) return decoded['message'].toString();
        if (decoded['errors'] is Map && (decoded['errors'] as Map).isNotEmpty) {
          final first = (decoded['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionQuillController.dispose();
    _disponibleChezController.dispose();
    _prixInitialController.dispose();
    _prixFinalController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
        withData: true,
      );
      if (result == null) return;
      setState(() => _selectedMediaFiles.addAll(result.files));
    } catch (_) {
      _showSnack('Impossible d\'accéder aux fichiers.', isError: true);
    }
  }

  Future<void> _pickDocumentMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null) return;
      setState(() => _selectedDocumentFiles.addAll(result.files));
      _showSnack('${result.files.length} fichier(s) ajouté(s)');
    } catch (_) {
      _showSnack('Impossible d\'accéder aux fichiers.', isError: true);
    }
  }

  void _removeMedia(int index) {
    setState(() => _selectedMediaFiles.removeAt(index));
  }

  Widget _buildMediaPreview(PlatformFile file) {
    final ext = file.extension?.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
    final isVideo = ['mp4', 'mov'].contains(ext);
    if (isImage && file.bytes != null) {
      return Image.memory(
        file.bytes!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    } else if (isVideo) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white),
        ),
      );
    }
    return Container(
      color: const Color(0xFFF9FAFB),
      child: const Center(
        child: Icon(
          Icons.insert_drive_file,
          size: 40,
          color: Color(0xFF3AAE5E),
        ),
      ),
    );
  }

  Future<bool> _uploadMediaFiles(String demandeId) async {
    if (_selectedMediaFiles.isEmpty && _selectedDocumentFiles.isEmpty)
      return true;
    setState(() => _isUploadingMedia = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return false;
      final uri = Uri.parse('${ApiConfig.baseUrl}/demandes/$demandeId/media');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      // Add photos from _selectedMediaFiles
      for (final file in _selectedMediaFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'media[]',
              file.path!,
              filename: file.name,
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'media[]',
              file.bytes!,
              filename: file.name ?? 'media',
            ),
          );
        }
      }

      // Add documents from _selectedDocumentFiles
      for (final file in _selectedDocumentFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'documents[]',
              file.path!,
              filename: file.name,
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'documents[]',
              file.bytes!,
              filename: file.name ?? 'document',
            ),
          );
        }
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        setState(() {
          _selectedMediaFiles.clear();
          _selectedDocumentFiles.clear();
          _documentFilesByType.clear();
        });
        return true;
      }
      final msg =
          _extractErrorMessage(body) ??
          'Impossible d\'envoyer les médias (${streamed.statusCode}).';
      _showSnack(msg, isError: true);
      print("Erreur upload: $msg");
      return false;
    } catch (_) {
      _showSnack(
        'Échec de l\'upload des médias. Veuillez réessayer.',
        isError: true,
      );
      return false;
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF3AAE5E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<String> _getUserRole() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final userData = response['user'] as Map<String, dynamic>?;
      final role = userData?['account_type']?.toString() ?? 'particulier';
      return role.toLowerCase();
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return 'particulier'; // Valeur par défaut
    }
  }

  List<Map<String, dynamic>> _filterNatureByRole(
    List<Map<String, dynamic>> categories,
    String role,
  ) {
    if (role == 'pro') {
      // Pour les comptes pro, exclure "Recherche d'emploi"
      // Pour les comptes pro, exclure "Recherche de stage"
      return categories.where((cat) => cat['code'] != 'SearchJob').toList();
    } else if (role == 'particulier') {
      // Pour les comptes particuliers, vérifier si "Recherche de stage" existe
      final hasInternship = categories.any(
        (cat) => cat['code'] == 'Internship',
      );
      if (!hasInternship) {
        // L'API ne retourne pas Internship — l'insérer après SearchJob (index 1)
        final updatedCategories = categories.map((cat) {
          final stringCat = <String, String>{};
          for (final key in cat.keys) {
            stringCat[key] = cat[key]?.toString() ?? '';
          }
          return stringCat;
        }).toList();

        updatedCategories.insert(0, {
          'id': '999',
          'code': 'Internship',
          'label': 'Recherche de stage/Alternance',
        });

        return updatedCategories.cast<Map<String, dynamic>>();
      }
    }
    return categories;
  }

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Step 1: Catégories
        if (_selectedCategory == null) {
          return 'Veuillez sélectionner la nature de la demande.';
        }
        break;

      case 1: // Step 2: Détails selon la nature
        if (_titleController.text.trim().length < 5) {
          return 'Le titre doit contenir au moins 5 caractères.';
        }
        if (_descriptionQuillController.document.toPlainText().trim().length <
            20) {
          return 'La description doit contenir au moins 20 caractères.';
        }

        // Validations spécifiques selon la catégorie
        if (_selectedCategory == 'SearchJob' ||
            _selectedCategory == 'Internship') {
          if (_selectedSecteurActivite == null) {
            return 'Veuillez sélectionner un secteur d\'activité.';
          }
          if (_selectedFunction == null) {
            return 'Veuillez sélectionner une fonction recherchée.';
          }
          if (_niveauExperience == null) {
            return 'Veuillez sélectionner votre niveau d\'expérience.';
          }
          if (_selectedTypeContrat.isEmpty &&
              _selectedCategory == 'Internship') {
            return 'Veuillez sélectionner au moins un type de stage.';
          }
        }

        if (_selectedCategory == 'Training') {
          if (_selectedFormationCategory == null) {
            return 'Veuillez sélectionner une catégorie de formation.';
          }
          if (_selectedFormationType == null) {
            return 'Veuillez sélectionner un type de formation.';
          }
          if (_getFormationSectors(_selectedFormationCategory).isNotEmpty &&
              _selectedFormationSector == null) {
            return 'Veuillez sélectionner un secteur de formation.';
          }
          if (_selectedFinancingTypes.isEmpty) {
            return 'Veuillez sélectionner au moins un type de financement.';
          }
        }

        if (_selectedCategory == 'RealEstate') {
          if (_selectedImmobilierType == null) {
            return 'Veuillez sélectionner un type de demande immobilière.';
          }
        }
        break;

      case 2: // Step 3: Localisation
        if (!_touteLaFrance &&
            _disponibleChezController.text.trim().isEmpty &&
            !_useCurrentLocation) {
          return 'Veuillez indiquer une ville/adresse, utiliser votre position ou cocher "Toute la France".';
        }
        break;

      case 3: // Step 4: Photos (optional)
        break;
    }
    return null;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // pop edit/create screen
                    if (widget.shouldReturnToListingOnSuccess) {
                      Navigator.pop(
                        context,
                      ); // pop detail screen back to listing
                    }
                  },
                  child: const Icon(Icons.close, color: Colors.grey, size: 22),
                ),
              ),
              const SizedBox(height: 8),
              // Container(
              //   width: 120,
              //   height: 120,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     color: const Color(0xFFFFF3E0).withOpacity(0.5),
              //   ),
              //   child: Center(
              //     child: Container(
              //       width: 80,
              //       height: 80,
              //       decoration: const BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: Color(0xFFE6F7EF),
              //       ),
              //       child: const Icon(
              //         Icons.verified,
              //         color: Color(0xFF3AAE5E),
              //         size: 50,
              //       ),
              //     ),
              //   ),
              // ),
              Image.asset("assets/images/imagepop.png"),
              const SizedBox(height: 20),
              Text(
                _isEditMode ? 'Demande modifiée' : 'Demande publiée',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3AAE5E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vous pouvez consulter cela au niveau de votre espace professionnel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackButton();
      },
      child: AppLayout(
        currentIndex: 2,
        backgroundColor: const Color(0xFFF9F9FB),
        onTabTapped: (index) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => ParticulierMainScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 4,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _handleBackButton,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF616161),
                          size: 24,
                        ),
                      ),
                    ),
                    Text(
                      _isEditMode ? 'Modifier la demande' : 'Créer une demande',
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Manjari',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              ),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _isEditMode
                      ? 'Modifiez les informations de votre demande'
                      : 'Décrivez ce que vous recherchez et recevez des propositions',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProgressBar(),
              ),
              const SizedBox(height: 12),
              // Previous button
              if (_currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _previousStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'Précédent',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Step content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: (_currentStep + 1) / (_totalSteps),
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
        minHeight: 6,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Nature();
      case 1:
        return _buildStep2Details();
      case 2:
        return _buildStep3Localisation();
      case 3:
        return _buildStepPhoto();
      case 4:
        return _buildStep4Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 1: Nature ───
  Widget _buildStep1Nature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.info_outline,
          title: 'Nature de la demande',
          children: [
            if (_isCategoryLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFFFF9800)),
                ),
              )
            else if (_categoryLoadError != null)
              _buildInlineErrorBanner(
                _categoryLoadError!,
                onRetry: _loadDemandeCategories,
              )
            else
              _buildDropdownFieldWithMap(
                label: 'Nature de la demande*',
                value: _selectedCategory,
                items: _natureOptions,
                onChanged: _onNatureChanged,
                hint: _buildRequiredHint('Nature de la demande'),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 2: Details ───
  Widget _buildStep2Details() {
    // Déterminer quel formulaire afficher selon la nature
    if (_selectedCategory == 'Training') {
      return _buildStep2Formation();
    } else if (_selectedCategory == 'RealEstate') {
      return _buildStep2Immobilier();
    } else if (_selectedCategory == 'SearchJob') {
      return _buildStep2Emploi();
    } else if (_selectedCategory == 'Internship') {
      return _buildStep2Stage();
    }

    // Formulaire par défaut
    return _buildStep2Default();
  }

  // Formulaire par défaut
  Widget _buildStep2Default() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.description_outlined,
          title: 'Détails de la demande',
          children: [
            _buildDropdownFieldWithMap(
              label: 'Type de la demande*',
              value: _selectedType,
              items: _typeOptions,
              onChanged: (val) => setState(() => _selectedType = val),
              hint: _buildRequiredHint('Type de la demande'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Titre de votre demande*',
              controller: _titleController,
              fieldKey: 'title',
              helperText:
                  'Saisissez un titre clair et précis pour votre demande (ex: "Recherche plombier pour fuite d\'eau urgente").',
            ),
            const SizedBox(height: 12),
            _buildRichTextEditor(
              label: 'Description de votre demande*',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText:
                  'Décrivez en détail ce que vous recherchez : contexte, contraintes, attentes particulières. Plus vous êtes précis, meilleures seront les réponses.',
            ),
            const SizedBox(height: 16),
            Text(
              "Quel serait le délai idéal pour répondre à votre demande ?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            _buildCheckOption("Dans l'immédiat (urgent)", _acceptDemand, () {
              setState(() {
                _acceptDemand = !_acceptDemand;
                if (_acceptDemand) {
                  _startDate = null;
                  _endDate = null;
                }
              });
            }),
            if (!_acceptDemand) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'À partir du :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null)
                              setState(() => _startDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _startDate != null
                                        ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}'
                                        : 'mm/dd/yyyy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _startDate != null
                                          ? Colors.black87
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jusqu\'au (facultatif) :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _endDate ?? _startDate ?? DateTime.now(),
                              firstDate:
                                  _startDate ??
                                  DateTime.now().subtract(
                                    const Duration(days: 1),
                                  ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null)
                              setState(() => _endDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _endDate != null
                                        ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                                        : 'mm/dd/yyyy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _endDate != null
                                          ? Colors.black87
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              "Quel est votre budget ?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ces champs sont optionnels. Laissez vides si vous n\'avez pas encore de budget défini.',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Budget minimum (€)',
              controller: _prixInitialController,
              keyboardType: TextInputType.number,
              suffix: '€',
              fieldKey: 'budget_min',
              helperText:
                  'Indiquez le montant minimum que vous êtes prêt à investir.',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Budget maximum (€)',
              controller: _prixFinalController,
              keyboardType: TextInputType.number,
              suffix: '€',
              fieldKey: 'budget_max',
              helperText:
                  'Indiquez le montant maximum que vous ne souhaitez pas dépasser.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 2: Formation ───
  Widget _buildStep2Formation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.school_outlined,
          title: 'Détails de la formation',
          children: [
            _buildDropdownFieldWithMap(
              label: 'Catégorie de la formation recherchée*',
              value: _selectedFormationCategory,
              items: _formationCategories,
              onChanged: (val) => {
                print("_formationCategories: $_formationCategories"),
                print(
                  "_selectedFormationCategory: $_selectedFormationCategory",
                ),
                setState(() {
                  _selectedFormationCategory = val;
                  _selectedFormationSector = null; // Réinitialiser le secteur
                }),
              },
              hint: _buildRequiredHint(
                'Sélectionner une catégorie de formation',
              ),
              backgroundColor: const Color(0xFFF9FAFB),
              useLabelAsValue: true,
            ),
            const SizedBox(height: 12),
            // Afficher le champ Secteur si la catégorie a des secteurs
            if (_getFormationSectors(
              _selectedFormationCategory,
            ).isNotEmpty) ...[
              _buildDropdownFieldWithMap(
                label: 'Secteur de formation recherché*',
                value: _selectedFormationSector,
                items: _getFormationSectors(_selectedFormationCategory),
                onChanged: (val) => {
                  setState(() => _selectedFormationSector = val),
                },
                hint: _buildRequiredHint('Sélectionner un secteur'),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
              const SizedBox(height: 12),
            ],
            _buildDropdownFieldWithMap(
              label: 'Type de formation recherchée*',
              value: _selectedFormationType,
              items: _formationTypes,
              onChanged: (val) => setState(() => _selectedFormationType = val),
              hint: _buildRequiredHint('Sélectionner un type'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            const SizedBox(height: 12),

            Text(
              'Intitulé de la formation recherchée *',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 2),
            _buildTextField(
              label: 'Intitulé de la formation recherchée*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Ex: Formation data analyste',
            ),
            const SizedBox(height: 16),

            // Type d'enseignement (choix multiple)
            _buildCheckboxGroup(
              title: "Type d'enseignement* (Choix multiple possible)",
              options: [
                {'code': 'tout', 'label': 'Tout'},
                {'code': 'entreprise', 'label': 'En entreprise'},
                {'code': 'alternance', 'label': 'En alternance'},
                {'code': 'centre', 'label': 'En centre'},
                {'code': 'distance', 'label': 'À distance'},
              ],
              selectedValues: _selectedTeachingTypes,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedTeachingTypes.add(code);
                  } else {
                    _selectedTeachingTypes.remove(code);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Financement (choix multiple)
            _buildCheckboxGroup(
              title: "Financement* (Choix multiple possible)",
              options: [
                {'code': 'tout', 'label': 'Tout'},
                {
                  'code': 'conseil_regional',
                  'label': 'Conseil régional - Collectivités territoriales',
                },
                {'code': 'opco', 'label': 'Opérateur de compétences (OPCO)'},
                {'code': 'mission_locale', 'label': 'Mission Locale'},
                {'code': 'auto_financement', 'label': 'Auto-Financement'},
                {'code': 'agefiph', 'label': 'AGEFIPH'},
                {'code': 'pole_emploi', 'label': 'Pôle Emploi'},
                {'code': 'cpf', 'label': 'Compte Personnel de Formation'},
              ],
              selectedValues: _selectedFinancingTypes,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedFinancingTypes.add(code);
                  } else {
                    _selectedFinancingTypes.remove(code);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Disponibilités
            Text(
              "Quelles sont vos disponibilités ?",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Theme(
              data: ThemeData(visualDensity: const VisualDensity(vertical: -4)),
              child: CheckboxListTile(
                dense: true,
                activeColor: const Color(0xFF3AAE5E),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  "Dans l'immédiat",
                  style: TextStyle(fontSize: 15),
                ),
                value: _dansImmediat,
                onChanged: (checked) {
                  setState(() {
                    _dansImmediat = checked ?? false;
                    if (_dansImmediat) {
                      _startDate = null;
                      _endDate = null;
                    }
                  });
                },
              ),
            ),
            if (!_dansImmediat) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'À partir du :',
                      selectedDate: _startDate,
                      onDateSelected: (date) =>
                          setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Jusqu\'au (facultatif) :',
                      selectedDate: _endDate,
                      onDateSelected: (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            _buildRichTextEditor(
              label: 'Décrivez votre demande de formation*',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText:
                  'Décrivez en détail la formation que vous recherchez...',
            ),
            const SizedBox(height: 16),

            // Ajouter des documents
            Text(
              "Ajouter des documents",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "(Portfolio etc...)",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _pickDocumentMedia();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3AAE5E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajouter des fichiers',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre de personnes ou groupes
            if (userRole == 'pro') ...[
              Text(
                "Nombre de personnes ou de groupes à former*",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                  fontFamily: 'Manjari',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _aDefinir,
                      child: Opacity(
                        opacity: _aDefinir ? 0.5 : 1.0,
                        child: _buildTextField(
                          label: 'Nb personne',
                          controller: _nbPersonnesController,
                          keyboardType: TextInputType.number,
                          fieldKey: 'nb_personnes',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _aDefinir,
                      child: Opacity(
                        opacity: _aDefinir ? 0.5 : 1.0,
                        child: _buildTextField(
                          label: 'Nb groupes',
                          controller: _nbGroupesController,
                          keyboardType: TextInputType.number,
                          fieldKey: 'nb_groupes',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Theme(
                data: ThemeData(
                  visualDensity: const VisualDensity(vertical: -4),
                ),
                child: CheckboxListTile(
                  dense: true,
                  activeColor: const Color(0xFF3AAE5E),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    "À définir",
                    style: TextStyle(fontSize: 15),
                  ),
                  value: _aDefinir,
                  onChanged: (checked) {
                    setState(() {
                      _aDefinir = checked ?? false;
                      if (_aDefinir) {
                        _nbPersonnesController.clear();
                        _nbGroupesController.clear();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),

              // Partager vos réseaux sociaux professionnels
              Text(
                'Partager vos réseaux sociaux professionnels (Cela augmente vos chances de vous faire remarquer)',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous n\'avez renseigné aucun réseau social. Veuillez mettre à jour votre profil pour que le réseau social s\'affiche ici',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 2: Immobilier ───
  Widget _buildStep2Immobilier() {
    // Déterminer quel formulaire afficher selon le type sélectionné
    Widget? specificForm;

    if (_selectedImmobilierType == 'RealEstateInvestment') {
      specificForm = _buildStep2ImmobilierInvestissement();
    } else if (_selectedImmobilierType == 'LookingForRental' ||
        _selectedImmobilierType == 'LookingForSharedHousing') {
      specificForm = _buildStep2ImmobilierLocation();
    } else if (_selectedImmobilierType == 'LookingForProfessionalSpace') {
      specificForm = _buildStep2ImmobilierLocalPro();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.home_outlined,
          title: 'Détails de votre recherche',
          children: [
            _buildDropdownFieldWithMap(
              label: 'Type de demande*',
              value: _selectedImmobilierType,
              items: _immobilierTypeOptions,
              onChanged: (val) => setState(() {
                _selectedImmobilierType = val;
                _selectedTypeBien.clear();
              }),
              hint: _buildRequiredHint('Sélectionner un type de demande'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
          ],
        ),
        if (specificForm != null) ...[
          const SizedBox(height: 16),
          specificForm,
        ] else ...[
          const SizedBox(height: 24),
          _buildNextButton(),
          const SizedBox(height: 30),
        ],
      ],
    );
  }

  // Formulaire pour Investissement immobilier
  Widget _buildStep2ImmobilierInvestissement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.home_outlined,
          title: 'Détails recherche immobiliere',
          children: [
            // Type de bien (choix multiple)
            _buildCheckboxGroup(
              title: "Type de bien* (Choix multiple possible)",
              options: [
                {'code': 'appartement', 'label': 'Appartement'},
                {'code': 'maison', 'label': 'Maison'},
                {'code': 'terrain', 'label': 'Terrain'},
                {'code': 'parking_box', 'label': 'Parking/Box'},
                {'code': 'loft_atelier', 'label': 'Loft/Atelier'},
                {'code': 'local_professionnel', 'label': 'Local professionnel'},
                {'code': 'bureau', 'label': 'Bureau'},
                {'code': 'chateau', 'label': 'Château'},
                {'code': 'hotel_particulier', 'label': 'Hôtel particulier'},
                {'code': 'batiment', 'label': 'Bâtiment'},
                {'code': 'boutique', 'label': 'Boutique'},
                {'code': 'immeuble', 'label': 'Immeuble'},
                {'code': 'peniche', 'label': 'Péniche'},
                {'code': 'divers', 'label': 'Divers'},
              ],
              selectedValues: _selectedTypeBien,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedTypeBien.add(code);
                  } else {
                    _selectedTypeBien.remove(code);
                  }
                });
              },
              scrollable: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'Quel est le titre de la demande ?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Ex: Appartement 3 pièces centre-ville',
            ),
            const SizedBox(height: 16),

            Text(
              'Quel est votre budget ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vous pouvez n\'indiquer qu\'un seul des deux, les deux ou aucun',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Budget minimum',
                    controller: _prixInitialController,
                    keyboardType: TextInputType.number,
                    suffix: '€',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Budget maximum',
                    controller: _prixFinalController,
                    keyboardType: TextInputType.number,
                    suffix: '€',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Pour quelle surface habitable ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Minimum',
                    controller: _surfaceHabitableMinController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Maximum',
                    controller: _surfaceHabitableMaxController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Pour quelle surface de terrain ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Minimum',
                    controller: _surfaceTerrainMinController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Maximum',
                    controller: _surfaceTerrainMaxController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Combien de pièces souhaitez-vous ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  '1',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '2',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '3',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '4',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '5 ou +',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  'Indifférent',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Combien de chambres souhaitez-vous ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  '1',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '2',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '3',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '4',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '5 ou +',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  'Indifférent',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRichTextEditor(
              label: 'Décrivez votre demande**',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail ce que vous recherchez...',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // Formulaire pour Cherche location / Cherche colocation
  Widget _buildStep2ImmobilierLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.home_outlined,
          title: 'Détails recherche immobiliere',
          children: [
            // Type de bien (choix multiple)
            _buildCheckboxGroup(
              title: "Type de bien* (Choix multiple possible)",
              options: [
                {'code': 'appartement', 'label': 'Appartement'},
                {'code': 'maison', 'label': 'Maison'},
                {'code': 'terrain', 'label': 'Terrain'},
                {'code': 'parking_box', 'label': 'Parking/Box'},
                {'code': 'loft_atelier', 'label': 'Loft/Atelier'},
                {'code': 'local_professionnel', 'label': 'Local professionnel'},
                {'code': 'bureau', 'label': 'Bureau'},
                {'code': 'chateau', 'label': 'Château'},
                {'code': 'hotel_particulier', 'label': 'Hôtel particulier'},
                {'code': 'batiment', 'label': 'Bâtiment'},
                {'code': 'boutique', 'label': 'Boutique'},
                {'code': 'immeuble', 'label': 'Immeuble'},
                {'code': 'peniche', 'label': 'Péniche'},
                {'code': 'divers', 'label': 'Divers'},
              ],
              selectedValues: _selectedTypeBien,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedTypeBien.add(code);
                  } else {
                    _selectedTypeBien.remove(code);
                  }
                });
              },
              scrollable: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'Quel est le titre de la demande ?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Ex: Appartement 3 pièces centre-ville',
            ),
            const SizedBox(height: 16),

            Text(
              'Quel est votre budget ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vous pouvez n\'indiquer qu\'un seul des deux, les deux ou aucun',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Budget minimum',
                    controller: _prixInitialController,
                    keyboardType: TextInputType.number,
                    suffix: '€',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Budget maximum',
                    controller: _prixFinalController,
                    keyboardType: TextInputType.number,
                    suffix: '€',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Pour quelle surface habitable ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Minimum',
                    controller: _surfaceHabitableMinController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Maximum',
                    controller: _surfaceHabitableMaxController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Pour quelle surface de terrain ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Minimum',
                    controller: _surfaceTerrainMinController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Maximum',
                    controller: _surfaceTerrainMaxController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Combien de pièces souhaitez-vous ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  '1',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '2',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '3',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '4',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  '5 ou +',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
                _buildNumberChip(
                  'Indifférent',
                  _nbPieces,
                  (val) => setState(() => _nbPieces = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Combien de chambres souhaitez-vous ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  '1',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '2',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '3',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '4',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  '5 ou +',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
                _buildNumberChip(
                  'Indifférent',
                  _nbChambres,
                  (val) => setState(() => _nbChambres = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meublé / Non-Meublé
            Text(
              'Meublé / Non-Meublé',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Meublé',
                  _meuble,
                  (val) => setState(() => _meuble = val),
                ),
                _buildNumberChip(
                  'Non-Meublé',
                  _meuble,
                  (val) => setState(() => _meuble = val),
                ),
                _buildNumberChip(
                  'Indifférent',
                  _meuble,
                  (val) => setState(() => _meuble = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRichTextEditor(
              label: 'Décrivez votre demande**',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail ce que vous recherchez...',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // Formulaire pour Cherche local professionnel
  Widget _buildStep2ImmobilierLocalPro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.home_outlined,
          title: 'Détails recherche immobiliere',
          children: [
            // Type de bien (choix multiple)
            _buildCheckboxGroup(
              title: "Type de bien* (Choix multiple possible)",
              options: [
                {'code': 'bureau', 'label': 'Bureau'},
                {'code': 'boutique', 'label': 'Boutique'},
                {'code': 'fond_commerce', 'label': 'Fond de commerce'},
                {'code': 'terrain', 'label': 'Terrain'},
                {'code': 'local_commercial', 'label': 'Local commercial'},
                {'code': 'coworking', 'label': 'Coworking'},
              ],
              selectedValues: _selectedTypeBien,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedTypeBien.add(code);
                  } else {
                    _selectedTypeBien.remove(code);
                  }
                });
              },
              scrollable: true,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'Quel est le titre de la demande ?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Ex: Appartement 3 pièces centre-ville',
            ),
            const SizedBox(height: 16),

            Text(
              'Quel est votre budget ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vous pouvez n\'indiquer qu\'un seul des deux, les deux ou aucun',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Budget minimum',
                    controller: _prixInitialController,
                    keyboardType: TextInputType.number,
                    suffix: '€',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Budget maximum',
                    controller: _prixFinalController,
                    keyboardType: TextInputType.number,
                    suffix: '€',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Pour quelle surface habitable ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Minimum',
                    controller: _surfaceHabitableMinController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Maximum',
                    controller: _surfaceHabitableMaxController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Pour quelle surface de terrain ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Minimum',
                    controller: _surfaceTerrainMinController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: 'Maximum',
                    controller: _surfaceTerrainMaxController,
                    keyboardType: TextInputType.number,
                    suffix: 'm²',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meublé / Non-Meublé
            Text(
              'Meublé / Non-Meublé',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Meublé',
                  _meuble,
                  (val) => setState(() => _meuble = val),
                ),
                _buildNumberChip(
                  'Non-Meublé',
                  _meuble,
                  (val) => setState(() => _meuble = val),
                ),
                _buildNumberChip(
                  'Indifférent',
                  _meuble,
                  (val) => setState(() => _meuble = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRichTextEditor(
              label: 'Décrivez votre demande**',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail ce que vous recherchez...',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 2: Emploi/Stage ───
  Widget _buildStep2Emploi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.work_outline,
          title: 'Détails du poste recherché',
          children: [
            _buildDropdownFieldWithMap(
              label: 'Secteur d\'activité*',
              value: _selectedSecteurActivite,
              items: _jobSecteursOptions.isNotEmpty ? _jobSecteursOptions : [],
              onChanged: (val) {
                setState(() {
                  _selectedSecteurActivite = val;
                  _selectedFunction =
                      null; // Reset function when sector changes
                });
              },
              hint: _buildRequiredHint('Sélectionner un secteur d\'activité'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            const SizedBox(height: 16),

            // Afficher le champ "Fonction recherchée" seulement si un secteur est sélectionné
            if (_selectedSecteurActivite != null) ...[
              _buildDropdownFieldWithMap(
                label: 'Fonction recherchée*',
                value: _selectedFunction,
                items: _getJobFonctionsForSecteur(_selectedSecteurActivite),
                onChanged: (val) => setState(() => _selectedFunction = val),
                hint: _buildRequiredHint('Sélectionner une fonction'),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
              const SizedBox(height: 16),
            ],

            _buildTextField(
              label: 'Quel est le poste recherché ?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Titre (ex: recherche développeur)',
            ),
            const SizedBox(height: 16),

            // Type de contrat recherché (choix multiple)
            _buildCheckboxGroup(
              title: "Type de contrat recherché* (Choix multiple)",
              options: [
                {'code': 'cdi', 'label': 'Contrat à durée indéterminée'},
                {'code': 'cdd', 'label': 'Contrat à durée déterminée'},
                {'code': 'interim', 'label': 'Intérim'},
                {
                  'code': 'independant',
                  'label': 'Indépendant / Freelance / Franchise',
                },
                {'code': 'benevolat', 'label': 'Bénévolat'},
              ],
              selectedValues: _selectedTypeContrat,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedTypeContrat.add(code);
                  } else {
                    _selectedTypeContrat.remove(code);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Temps plein ou temps partiel
            Text(
              'Temps plein ou temps partiel ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Temps plein',
                  _tempsPartielPlein,
                  (val) => setState(() => _tempsPartielPlein = val),
                ),
                _buildNumberChip(
                  'Temps partiel',
                  _tempsPartielPlein,
                  (val) => setState(() => _tempsPartielPlein = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quel est votre niveau d'études
            _buildDropdownFieldWithMap(
              label: 'Quel est votre niveau d\'études ?',
              value: _niveauEtudes,
              items: [
                {'code': 'sans_diplome', 'label': 'Sans diplome'},
                {'code': 'cap_bep', 'label': 'CAP/BEP'},
                {
                  'code': 'bac_employe',
                  'label': 'BAC/Employé/Ouvrier spécialisé',
                },
                {
                  'code': 'bac2_technicien',
                  'label': 'BAC+2/Technicien/Employé',
                },
                {
                  'code': 'bac3_agent_maitrise',
                  'label': 'BAC+3/Agent de maîtrise',
                },
                {
                  'code': 'bac5_ingenieur',
                  'label': 'BAC+5 ou plus/Ingénieur/Cadre',
                },
              ],
              onChanged: (val) => setState(() => _niveauEtudes = val),
              hint: const Text('Sélectionner'),
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),

            // Quel est votre niveau d'expérience
            _buildDropdownFieldWithMap(
              label: 'Quel est votre niveau d\'expérience ?*',
              value: _niveauExperience,
              items: [
                {'code': 'debutant', 'label': 'Débutant : de 0 a 1 annee'},
                {
                  'code': 'intermediaire',
                  'label': 'Intermédiaire : de 2 a 4 annee',
                },
                {'code': 'confirme', 'label': 'Confirme : de 5 a 9 annee'},
                {'code': 'senior', 'label': 'Senior : de 10 annee ou plus'},
              ],
              onChanged: (val) => setState(() => _niveauExperience = val),
              hint: const Text('Sélectionner'),
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),

            // Quelles sont vos disponibilités
            Text(
              'Quelles sont vos disponibilités ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Theme(
              data: ThemeData(visualDensity: const VisualDensity(vertical: -4)),
              child: CheckboxListTile(
                dense: true,
                activeColor: const Color(0xFF3AAE5E),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  "Dans l'immédiat",
                  style: TextStyle(fontSize: 15),
                ),
                value: _dansImmediat,
                onChanged: (checked) {
                  setState(() {
                    _dansImmediat = checked ?? false;
                    if (_dansImmediat) {
                      _startDate = null;
                      _endDate = null;
                    }
                  });
                },
              ),
            ),
            if (!_dansImmediat) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'À partir du :',
                      selectedDate: _startDate,
                      onDateSelected: (date) =>
                          setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Jusqu\'au (facultatif) :',
                      selectedDate: _endDate,
                      onDateSelected: (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Quel est votre prétention salariale
            Text(
              'Quel est votre prétention salariale ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Tranche salariale',
                  _trancheSalariale,
                  (val) => setState(() => _trancheSalariale = val),
                ),
                _buildNumberChip(
                  'Salaire exact',
                  _trancheSalariale,
                  (val) => setState(() => _trancheSalariale = val),
                ),
                _buildNumberChip(
                  'Aucune',
                  _trancheSalariale,
                  (val) => setState(() => _trancheSalariale = val),
                ),
              ],
            ),

            // Champs conditionnels pour "Tranche salariale"
            if (_trancheSalariale == 'Tranche salariale') ...[
              const SizedBox(height: 16),
              Text(
                'Tranche salariale',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Min',
                      controller: _salaryMinController,
                      keyboardType: TextInputType.number,
                      suffix: '€',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Max',
                      controller: _salaryMaxController,
                      keyboardType: TextInputType.number,
                      suffix: '€',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFieldWithMap(
                      label: 'Net ou Brut ?',
                      value: _salaryNetOrBrut,
                      items: [
                        {'code': 'net', 'label': 'Net'},
                        {'code': 'brut', 'label': 'Brut'},
                      ],
                      onChanged: (val) =>
                          setState(() => _salaryNetOrBrut = val),
                      hint: const Text('Sélectionner'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownFieldWithMap(
                      label: 'Indice temporel',
                      value: _salaryIndiceTemporel,
                      items: [
                        {'code': 'heures', 'label': 'Heures'},
                        {'code': 'jours', 'label': 'Jours'},
                        {'code': 'semaines', 'label': 'Semaines'},
                        {'code': 'mois', 'label': 'Mois'},
                        {'code': 'annees', 'label': 'Années'},
                      ],
                      onChanged: (val) =>
                          setState(() => _salaryIndiceTemporel = val),
                      hint: const Text('Sélectionner'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Acceptez-vous une offre en télétravail
            Text(
              'Acceptez-vous une offre en télétravail ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Oui',
                  _accepteTeletravaill ? 'Oui' : null,
                  (val) => setState(() => _accepteTeletravaill = true),
                ),
                _buildNumberChip(
                  'Non',
                  !_accepteTeletravaill && _accepteTeletravaill != null
                      ? 'Non'
                      : null,
                  (val) => setState(() => _accepteTeletravaill = false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRichTextEditor(
              label: 'Décrivez votre demande**',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail ce que vous recherchez...',
            ),
            const SizedBox(height: 16),

            // Utiliser les documents de l'espace candidat
            CheckboxListTile(
              dense: true,
              activeColor: const Color(0xFF3AAE5E),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                "Utiliser les documents de l'espace candidat",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                  fontFamily: 'Manjari',
                ),
              ),
              value: _docCand,
              onChanged: (checked) {
                setState(() {
                  _docCand = checked ?? false;
                });
              },
            ),
            if (!_docCand) ...[
              const SizedBox(height: 8),
              Text(
                'Aucun document dans l\'espace candidat',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildDocumentChip('Ajouter un CV', 'cv'),
                  _buildDocumentChip(
                    'Ajouter une lettre de motivation',
                    'lettre_motivation',
                  ),
                  _buildDocumentChip('Ajouter un portfolio', 'portfolio'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Ajouter des documents
            Text(
              'Ajouter des documents',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _selectedDocumentFiles.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAddDocButton();
                final docIndex = index - 1;
                return _buildDocumentPreviewCard(
                  _selectedDocumentFiles[docIndex],
                  docIndex,
                );
              },
            ),
            const SizedBox(height: 15),

            // Partager vos réseaux sociaux professionnels
            Text(
              'Partager vos réseaux sociaux professionnels (Cela augmente vos chances de vous faire remarquer)',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez renseigné aucun réseau social. Veuillez mettre à jour votre profil pour que le réseau social s\'affiche ici',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 2: Stage ───
  Widget _buildStep2Stage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.work_outline,
          title: 'Détails du poste recherché',
          children: [
            _buildDropdownFieldWithMap(
              label: 'Secteur d\'activité*',
              value: _selectedSecteurActivite,
              items: _jobSecteursOptions.isNotEmpty ? _jobSecteursOptions : [],
              onChanged: (val) {
                setState(() {
                  _selectedSecteurActivite = val;
                  _selectedFunction =
                      null; // Reset function when sector changes
                });
              },
              hint: _buildRequiredHint('Sélectionner un secteur d\'activité'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            const SizedBox(height: 16),

            // Afficher le champ "Quel est le poste recherché ?" seulement si un secteur est sélectionné
            if (_selectedSecteurActivite != null) ...[
              _buildDropdownFieldWithMap(
                label: 'Fonction recherchée*',
                value: _selectedFunction,
                items: _getJobFonctionsForSecteur(_selectedSecteurActivite),
                onChanged: (val) => setState(() => _selectedFunction = val),
                hint: _buildRequiredHint('Sélectionner une fonction'),
                backgroundColor: const Color(0xFFF9FAFB),
                useLabelAsValue: true,
              ),
              const SizedBox(height: 16),
            ],

            _buildTextField(
              label: 'Quel est le poste recherché ?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Titre de l\'annonce (ex: recherche développeur)',
            ),
            const SizedBox(height: 16),

            // Type de contrat recherché (choix multiple)
            _buildCheckboxGroup(
              title: "Type de contrat recherché* (Choix multiple)",
              options: [
                {'code': 'apprentissage', 'label': 'Apprentissage/Alternance'},
                {'code': 'stage', 'label': 'Stage'},
              ],
              selectedValues: _selectedTypeContrat,
              onChanged: (code, checked) {
                setState(() {
                  if (checked) {
                    _selectedTypeContrat.add(code);
                  } else {
                    _selectedTypeContrat.remove(code);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Temps plein ou temps partiel
            Text(
              'Temps plein ou temps partiel ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Temps plein',
                  _tempsPartielPlein,
                  (val) => setState(() => _tempsPartielPlein = val),
                ),
                _buildNumberChip(
                  'Temps partiel',
                  _tempsPartielPlein,
                  (val) => setState(() => _tempsPartielPlein = val),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quel est votre niveau d'études
            _buildDropdownFieldWithMap(
              label: 'Quel est votre niveau d\'études ?',
              value: _niveauEtudes,
              items: [
                {'code': 'sans_diplome', 'label': 'Sans diplome'},
                {'code': 'cap_bep', 'label': 'CAP/BEP'},
                {
                  'code': 'bac_employe',
                  'label': 'BAC/Employé/Ouvrier spécialisé',
                },
                {
                  'code': 'bac2_technicien',
                  'label': 'BAC+2/Technicien/Employé',
                },
                {
                  'code': 'bac3_agent_maitrise',
                  'label': 'BAC+3/Agent de maîtrise',
                },
                {
                  'code': 'bac5_ingenieur',
                  'label': 'BAC+5 ou plus/Ingénieur/Cadre',
                },
              ],
              onChanged: (val) => setState(() => _niveauEtudes = val),
              hint: const Text('Sélectionner'),
              backgroundColor: Colors.white,
              useLabelAsValue: true,
            ),
            const SizedBox(height: 16),

            // Quel est votre niveau d'expérience
            _buildDropdownFieldWithMap(
              label: 'Quel est votre niveau d\'expérience ?*',
              value: _niveauExperience,
              items: [
                {'code': 'debutant', 'label': 'Débutant : de 0 a 1 annee'},
                {
                  'code': 'intermediaire',
                  'label': 'Intermédiaire : de 2 a 4 annee',
                },
                {'code': 'confirme', 'label': 'Confirme : de 5 a 9 annee'},
                {'code': 'senior', 'label': 'Senior : de 10 annee ou plus'},
              ],
              onChanged: (val) => setState(() => _niveauExperience = val),
              hint: const Text('Sélectionner'),
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),

            // Quelles sont vos disponibilités
            Text(
              'Quelles sont vos disponibilités ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              dense: true,
              activeColor: const Color(0xFF3AAE5E),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                "Dans l'immédiat",
                style: TextStyle(fontSize: 15),
              ),
              value: _dansImmediat,
              onChanged: (checked) {
                setState(() {
                  _dansImmediat = checked ?? false;
                  if (_dansImmediat) {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
            ),
            if (!_dansImmediat) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'À partir du :',
                      selectedDate: _startDate,
                      onDateSelected: (date) =>
                          setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Jusqu\'au (facultatif) :',
                      selectedDate: _endDate,
                      onDateSelected: (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Quel est votre prétention salariale
            Text(
              'Quel est votre prétention salariale ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Tranche salariale',
                  _trancheSalariale,
                  (val) => setState(() => _trancheSalariale = val),
                ),
                _buildNumberChip(
                  'Salaire exact',
                  _trancheSalariale,
                  (val) => setState(() => _trancheSalariale = val),
                ),
                _buildNumberChip(
                  'Aucune',
                  _trancheSalariale,
                  (val) => setState(() => _trancheSalariale = val),
                ),
              ],
            ),

            // Champs conditionnels pour "Tranche salariale"
            if (_trancheSalariale == 'Tranche salariale') ...[
              const SizedBox(height: 16),
              Text(
                'Tranche salariale',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Min',
                      controller: _salaryMinController,
                      keyboardType: TextInputType.number,
                      suffix: '€',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: 'Max',
                      controller: _salaryMaxController,
                      keyboardType: TextInputType.number,
                      suffix: '€',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFieldWithMap(
                      label: 'Net ou Brut ?',
                      value: _salaryNetOrBrut,
                      items: [
                        {'code': 'net', 'label': 'Net'},
                        {'code': 'brut', 'label': 'Brut'},
                      ],
                      onChanged: (val) =>
                          setState(() => _salaryNetOrBrut = val),
                      hint: const Text('Sélectionner'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdownFieldWithMap(
                      label: 'Indice temporel',
                      value: _salaryIndiceTemporel,
                      items: [
                        {'code': 'heures', 'label': 'Heures'},
                        {'code': 'jours', 'label': 'Jours'},
                        {'code': 'semaines', 'label': 'Semaines'},
                        {'code': 'mois', 'label': 'Mois'},
                        {'code': 'annees', 'label': 'Années'},
                      ],
                      onChanged: (val) =>
                          setState(() => _salaryIndiceTemporel = val),
                      hint: const Text('Sélectionner'),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Acceptez-vous une offre en télétravail
            Text(
              'Acceptez-vous une offre en télétravail ?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildNumberChip(
                  'Oui',
                  _accepteTeletravaill ? 'Oui' : null,
                  (val) => setState(() => _accepteTeletravaill = true),
                ),
                _buildNumberChip(
                  'Non',
                  !_accepteTeletravaill && _accepteTeletravaill != null
                      ? 'Non'
                      : null,
                  (val) => setState(() => _accepteTeletravaill = false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildRichTextEditor(
              label: 'Décrivez votre demande**',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail ce que vous recherchez...',
            ),
            const SizedBox(height: 16),

            // Utiliser les documents de l'espace candidat
            CheckboxListTile(
              dense: true,
              activeColor: const Color(0xFF3AAE5E),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                "Utiliser les documents de l'espace candidat",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                  fontFamily: 'Manjari',
                ),
              ),
              value: _docCand,
              onChanged: (checked) {
                setState(() {
                  _docCand = checked ?? false;
                });
              },
            ),
            if (!_docCand) ...[
              const SizedBox(height: 8),
              Text(
                'Aucun document dans l\'espace candidat',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildDocumentChip('Ajouter un CV', 'cv'),
                  _buildDocumentChip(
                    'Ajouter une lettre de motivation',
                    'lettre_motivation',
                  ),
                  _buildDocumentChip('Ajouter un portfolio', 'portfolio'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Ajouter des documents
            Text(
              'Ajouter des documents',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                fontFamily: 'Manjari',
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _selectedDocumentFiles.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildAddDocButton();
                final docIndex = index - 1;
                return _buildDocumentPreviewCard(
                  _selectedDocumentFiles[docIndex],
                  docIndex,
                );
              },
            ),
            const SizedBox(height: 15),
            // Partager vos réseaux sociaux professionnels
            Text(
              'Partager vos réseaux sociaux professionnels (Cela augmente vos chances de vous faire remarquer)',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez renseigné aucun réseau social. Veuillez mettre à jour votre profil pour que le réseau social s\'affiche ici',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 3: Localisation ───
  Widget _buildStep3Localisation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.location_on,
          title: 'Localisation de la demande',
          children: [
            _buildCheckOption('Toute la France', _touteLaFrance, () {
              setState(() => _touteLaFrance = !_touteLaFrance);
            }),
            if (!_touteLaFrance) ...[
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Ville ou adresse',
                controller: _disponibleChezController,
                fieldKey: 'location',
                helperText:
                    'Indiquez la ville ou l\'adresse où vous souhaitez que la prestation soit réalisée.',
              ),
              const SizedBox(height: 8),
              _buildCheckOption(
                'Utiliser ma position actuelle',
                _useCurrentLocation,
                () =>
                    setState(() => _useCurrentLocation = !_useCurrentLocation),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rayon de recherche',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
              Text(
                '${_rayonRecherche.toInt()} km',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFFF9800),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFEF8A40),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: const Color(0xFFEF8A40),
                  overlayColor: const Color(0xFFEF8A40).withOpacity(0.2),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  value: _rayonRecherche,
                  min: 0,
                  max: 200,
                  divisions: 40,
                  onChanged: (value) => setState(() => _rayonRecherche = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['0 km', '50 km', '100 km', '150 km', '200 km']
                      .map(
                        (t) => Text(
                          t,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildCheckOption(
              "Afficher ma localisation sur l'annonce",
              _showGoogleLocation,
              () => setState(() => _showGoogleLocation = !_showGoogleLocation),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP PHOTO ───
  Widget _buildStepPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajoutez des photos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Illustrez votre demande avec des photos pour attirer plus de réponses pertinentes.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Vos photos (non-obligatoires)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _existingMediaUrls.length + _selectedMediaFiles.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildAddPhotoButton();
            final existingCount = _existingMediaUrls.length;
            if (index <= existingCount) {
              return _buildExistingPhotoCard(
                _existingMediaUrls[index - 1],
                index - 1,
              );
            }
            final newIndex = index - 1 - existingCount;
            return _buildPhotoPreviewCard(
              _selectedMediaFiles[newIndex],
              newIndex,
            );
          },
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAddDocButton() {
    return GestureDetector(
      onTap: _pickDocumentMedia,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3AAE5E), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAE5E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 40, color: Color(0xFF3AAE5E)),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedDocumentFiles.isEmpty
                  ? 'Ajouter des documents'
                  : 'Ajouter plus',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3AAE5E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3AAE5E), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3AAE5E).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 40,
                color: Color(0xFF3AAE5E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMediaFiles.isEmpty
                  ? 'Ajouter des photos'
                  : 'Ajouter plus',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3AAE5E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingPhotoCard(String url, int index) {
    final isCover = index == 0 && _selectedMediaFiles.isEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF9800),
                    ),
                  );
                },
              ),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Photo de couverture',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _existingMediaUrls.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreviewCard(PlatformFile file, int index) {
    final ext = file.extension?.toLowerCase();
    final isPdf = ext == 'pdf';
    final isDoc = ext == 'doc' || ext == 'docx';
    final isImage = ['jpg', 'jpeg', 'png'].contains(ext);

    Widget contentWidget;

    if (isImage && file.bytes != null) {
      contentWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      IconData iconData;
      Color iconColor;
      if (isPdf) {
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
      } else if (isDoc) {
        iconData = Icons.description;
        iconColor = Colors.blue;
      } else if (isImage) {
        iconData = Icons.image;
        iconColor = Colors.green;
      } else {
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
      }

      contentWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 48, color: iconColor),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                file.name,
                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        color: Colors.grey[50],
      ),
      child: Stack(
        children: [
          contentWidget,
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeDocument(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreviewCard(PlatformFile file, int index) {
    final isCover = index == 0 && _existingMediaUrls.isEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFFF5F5F5),
              child: _buildMediaPreview(file),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Photo de couverture',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour obtenir le label à partir d'un code dans une liste de maps
  String _getLabelFromCode(List<Map<String, String>> items, String? code) {
    if (code == null) return '-';
    final match = items.firstWhere(
      (o) => o['code'] == code,
      orElse: () => {'label': code},
    );
    return match['label'] ?? code;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<Widget> _buildReviewRowsForCategory() {
    final rows = <Widget>[];

    // Titre (commun à tous)
    rows.add(
      _buildReviewRow(
        'Titre',
        _titleController.text.trim().isEmpty
            ? '-'
            : _titleController.text.trim(),
      ),
    );

    // Description (commun à tous)
    final descText = _descriptionQuillController.document.toPlainText().trim();
    rows.add(_buildReviewRow('Description', descText.isEmpty ? '-' : descText));

    // ─── Emploi / Stage ───
    if (_selectedCategory == 'SearchJob' || _selectedCategory == 'Internship') {
      rows.add(
        _buildReviewRow(
          'Secteur d\'activité',
          // _getLabelFromCode(_secteursActivite, _selectedSecteurActivite),
          _selectedSecteurActivite!,
        ),
      );
      rows.add(
        _buildReviewRow(
          'Fonction recherchée',
          // _getLabelFromCode(_allFunction, _selectedFunction),
          _selectedFunction!,
        ),
      );
      if (_tempsPartielPlein != null) {
        rows.add(_buildReviewRow('Temps de travail', _tempsPartielPlein!));
      }
      if (_niveauEtudes != null) {
        rows.add(_buildReviewRow('Niveau d\'études', _niveauEtudes!));
      }
      if (_niveauExperience != null) {
        rows.add(_buildReviewRow('Niveau d\'expérience', _niveauExperience!));
      }
      if (_trancheSalariale != null) {
        if (_trancheSalariale == 'Tranche salariale' &&
            (_salaryMinController.text.trim().isNotEmpty ||
                _salaryMaxController.text.trim().isNotEmpty)) {
          String salaryRange = '';
          if (_salaryMinController.text.trim().isNotEmpty) {
            salaryRange += _salaryMinController.text.trim();
          }
          salaryRange += ' - ';
          if (_salaryMaxController.text.trim().isNotEmpty) {
            salaryRange += _salaryMaxController.text.trim();
          }
          salaryRange += ' €';
          if (_salaryNetOrBrut != null) {
            salaryRange += ' (${_salaryNetOrBrut == 'net' ? 'Net' : 'Brut'})';
          }
          if (_salaryIndiceTemporel != null) {
            salaryRange +=
                ' / ${_salaryIndiceTemporel != null ? '$_salaryIndiceTemporel' : 'Années'}';
          }
          rows.add(_buildReviewRow('Tranche salariale', salaryRange));
        } else {
          rows.add(_buildReviewRow('Prétention salariale', _trancheSalariale!));
        }
      }
      rows.add(
        _buildReviewRow(
          'Télétravail accepté',
          _accepteTeletravaill ? 'Oui' : 'Non',
        ),
      );
      rows.add(
        _buildReviewRow('Dans l\'immédiat', _dansImmediat ? 'Oui' : 'Non'),
      );
      if (!_dansImmediat) {
        rows.add(_buildReviewRow('À partir du', _formatDate(_startDate)));
        rows.add(_buildReviewRow('Jusqu\'au', _formatDate(_endDate)));
      }
      if (_selectedTypeContrat.isNotEmpty) {
        rows.add(
          _buildReviewRow('Type de contrat', _selectedTypeContrat.join(', ')),
        );
      }
      if (_prixInitialController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Budget min',
            '${_prixInitialController.text.trim()} €',
          ),
        );
      }
      if (_prixFinalController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Budget max',
            '${_prixFinalController.text.trim()} €',
          ),
        );
      }
      // Documents
      // if (_selectedDocumentFiles.isNotEmpty) {
      //   final docNames = _selectedDocumentFiles.map((f) => f.name).join(', ');
      //   rows.add(_buildReviewRow('Documents ajoutés', docNames));
      // }
    }
    // ─── Formation ───
    else if (_selectedCategory == 'Training') {
      rows.add(
        _buildReviewRow(
          'Catégorie',
          _getLabelFromCode(_formationCategories, _selectedFormationCategory),
        ),
      );
      if (_selectedFormationType != null) {
        rows.add(_buildReviewRow('Type de formation', _selectedFormationType!));
      }
      if (_selectedFormationSector != null) {
        rows.add(
          _buildReviewRow('Secteur de formation', _selectedFormationSector!),
        );
      }
      if (_selectedFinancingTypes.isNotEmpty) {
        rows.add(
          _buildReviewRow('Financement', _selectedFinancingTypes.join(', ')),
        );
      }
      if (_selectedTeachingTypes.isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Type d\'enseignement',
            _selectedTeachingTypes.join(', '),
          ),
        );
      }
      if (_nbPersonnesController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Nombre de personnes',
            _nbPersonnesController.text.trim(),
          ),
        );
      }
      if (_nbGroupesController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Nombre de groupes',
            _nbGroupesController.text.trim(),
          ),
        );
      }
      rows.add(_buildReviewRow('À définir', _aDefinir ? 'Oui' : 'Non'));
      rows.add(
        _buildReviewRow('Dans l\'immédiat', _dansImmediat ? 'Oui' : 'Non'),
      );
      if (!_dansImmediat) {
        rows.add(_buildReviewRow('À partir du', _formatDate(_startDate)));
        rows.add(_buildReviewRow('Jusqu\'au', _formatDate(_endDate)));
      }
    }
    // ─── Immobilier ───
    else if (_selectedCategory == 'RealEstate') {
      rows.add(
        _buildReviewRow(
          'Type de demande',
          _getLabelFromCode(_immobilierTypeOptions, _selectedImmobilierType),
        ),
      );
      if (_selectedTypeBien.isNotEmpty) {
        rows.add(_buildReviewRow('Type de bien', _selectedTypeBien.join(', ')));
      }
      if (_prixInitialController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Budget min',
            '${_prixInitialController.text.trim()} €',
          ),
        );
      }
      if (_prixFinalController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Budget max',
            '${_prixFinalController.text.trim()} €',
          ),
        );
      }
      if (_surfaceHabitableMinController.text.trim().isNotEmpty ||
          _surfaceHabitableMaxController.text.trim().isNotEmpty) {
        final shMin = _surfaceHabitableMinController.text.trim();
        final shMax = _surfaceHabitableMaxController.text.trim();

        String surfaceText;
        if (shMin.isNotEmpty && shMax.isNotEmpty) {
          surfaceText = 'Min: $shMin m² - Max: $shMax m²';
        } else if (shMin.isNotEmpty) {
          surfaceText = 'Min: $shMin m²';
        } else {
          surfaceText = 'Max: $shMax m²';
        }

        rows.add(_buildReviewRow('Surface habitable', surfaceText));
      }
      if (_surfaceTerrainMinController.text.trim().isNotEmpty ||
          _surfaceTerrainMaxController.text.trim().isNotEmpty) {
        final stMin = _surfaceTerrainMinController.text.trim();
        final stMax = _surfaceTerrainMaxController.text.trim();

        String terrainText;
        if (stMin.isNotEmpty && stMax.isNotEmpty) {
          terrainText = 'Min: $stMin m² - Max: $stMax m²';
        } else if (stMin.isNotEmpty) {
          terrainText = 'Min: $stMin m²';
        } else {
          terrainText = 'Max: $stMax m²';
        }

        rows.add(_buildReviewRow('Surface terrain', terrainText));
      }
      if (_nbPieces != null) {
        rows.add(_buildReviewRow('Nombre de pièces', _nbPieces!));
      }
      if (_nbChambres != null) {
        rows.add(_buildReviewRow('Nombre de chambres', _nbChambres!));
      }
      if (_meuble != null) {
        rows.add(_buildReviewRow('Meublé', _meuble!));
      }
    }
    // ─── Défaut (autres catégories) ───
    else {
      if (_selectedType != null) {
        rows.add(
          _buildReviewRow(
            'Type',
            _getLabelFromCode(_typeOptions, _selectedType),
          ),
        );
      }
      rows.add(_buildReviewRow('Urgent', _acceptDemand ? 'Oui' : 'Non'));
      if (!_acceptDemand) {
        rows.add(_buildReviewRow('À partir du', _formatDate(_startDate)));
        rows.add(_buildReviewRow('Jusqu\'au', _formatDate(_endDate)));
      }
      if (_prixInitialController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Budget min',
            '${_prixInitialController.text.trim()} €',
          ),
        );
      }
      if (_prixFinalController.text.trim().isNotEmpty) {
        rows.add(
          _buildReviewRow(
            'Budget max',
            '${_prixFinalController.text.trim()} €',
          ),
        );
      }
    }

    return rows;
  }

  // ─── STEP 4: Review ───
  Widget _buildStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkmark
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6F7EF),
            ),
            child: const Icon(Icons.check, color: Color(0xFF3AAE5E), size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _isEditMode
                ? 'Vérifiez vos modifications'
                : 'Vérifiez votre demande',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Center(
          child: Text(
            _isEditMode
                ? 'Relisez les informations avant de sauvegarder'
                : 'Relisez les informations avant de publier votre demande',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Étape 1 - Nature
        _buildReviewSection(
          title: 'Étape 1 — Nature',
          onEdit: () => setState(() => _currentStep = 0),
          rows: [
            _buildReviewRow(
              'Nature',
              _natureOptions.firstWhere(
                    (o) => o['code'] == _selectedCategory,
                    orElse: () => {'label': '-'},
                  )['label'] ??
                  '-',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Étape 2 - Détails (dynamique selon la catégorie)
        _buildReviewSection(
          title: 'Étape 2 — Détails',
          onEdit: () => setState(() => _currentStep = 1),
          rows: _buildReviewRowsForCategory(),
        ),
        if (_selectedDocumentFiles.isNotEmpty) const SizedBox(height: 8),
        if (_selectedDocumentFiles.isNotEmpty) _buildDocumentReviewCards(),
        const SizedBox(height: 12),

        // Étape 3 - Localisation
        _buildReviewSection(
          title: 'Étape 3 — Localisation',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            if (_touteLaFrance) _buildReviewRow('Toute la France', 'Oui'),
            if (!_touteLaFrance) ...[
              _buildReviewRow(
                'Ville / Adresse',
                _disponibleChezController.text.trim().isEmpty
                    ? '-'
                    : _disponibleChezController.text.trim(),
              ),
            ],
            _buildReviewRow(
              'Utiliser ma position',
              _useCurrentLocation ? 'Oui' : 'Non',
            ),
            if (!_touteLaFrance)
              _buildReviewRow(
                'Rayon de recherche',
                _rayonRecherche > 0 ? '${_rayonRecherche.toInt()} km' : '-',
              ),
            _buildReviewRow(
              'Afficher localisation',
              _showGoogleLocation ? 'Oui' : 'Non',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Étape 4 - Photos
        _buildReviewSection(
          title: 'Étape 4 — Photos',
          onEdit: () => setState(() => _currentStep = 3),
          rows: [
            _buildReviewRow(
              'Photos',
              (_existingMediaUrls.isEmpty && _selectedMediaFiles.isEmpty)
                  ? 'Aucune photo ajoutée'
                  : '${_existingMediaUrls.length + _selectedMediaFiles.length} photo(s)',
            ),
          ],
        ),
        if (_selectedMediaFiles.isNotEmpty || _existingMediaUrls.isNotEmpty)
          const SizedBox(height: 8),
        if (_selectedMediaFiles.isNotEmpty || _existingMediaUrls.isNotEmpty)
          _buildPhotoReviewCards(),
        const SizedBox(height: 20),

        // Accept messages
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7EF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Text(
                'Accepter de recevoir des messages à propos de cette demande',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les utilisateurs intéressés pourront vous écrire pour clarifier un besoin ou proposer une solution adaptée.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCheckOption('Oui', _acceptMessages, () {
                    setState(() => _acceptMessages = true);
                  }),
                  const SizedBox(width: 40),
                  _buildCheckOption('Non', !_acceptMessages, () {
                    setState(() => _acceptMessages = false);
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Publish button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDemande,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isEditMode
                        ? 'Enregistrer les modifications'
                        : 'Publier la demande',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildInlineErrorBanner(String message, {VoidCallback? onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Réessayer',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required IconData icon,
    required String title,
    List<Widget> children = const [],
    String? subtitle,
    bool noDivider = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF3AAE5E), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                  fontFamily: 'Manjari',
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
          if (!noDivider) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 0.5),
          ],
          if (children.isNotEmpty) ...[const SizedBox(height: 14), ...children],
        ],
      ),
    );
  }

  Widget _buildDropdownFieldWithMap({
    required String label,
    required String? value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    Widget? hint,
    Color? backgroundColor,
    bool useLabelAsValue = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: hint,
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: useLabelAsValue ? item['label'] : item['code'],
                      child: Text(item['label'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredHint(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
          fontFamily: 'Manjari',
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperText(String? fieldKey, String helperText) {
    if (_focusedField != fieldKey) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              helperText,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2E7D32),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichTextEditor({
    required String label,
    required QuillController controller,
    String? fieldKey,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (fieldKey != null) setState(() => _focusedField = fieldKey);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 10),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: QuillSimpleToolbar(
                    controller: controller,
                    config: const QuillSimpleToolbarConfig(
                      toolbarSize: 28,
                      multiRowsDisplay: false,
                      showBoldButton: true,
                      showItalicButton: true,
                      showUnderLineButton: true,
                      showStrikeThrough: true,
                      showLink: true,
                      showUndo: true,
                      showRedo: true,
                      showListBullets: true,
                      showListNumbers: true,
                      showListCheck: false,
                      showCodeBlock: false,
                      showQuote: false,
                      showIndent: false,
                      showHeaderStyle: false,
                      showFontFamily: false,
                      showFontSize: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showClearFormat: false,
                      showAlignmentButtons: false,
                      showDirection: false,
                      showSearchButton: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showSmallButton: false,
                      showInlineCode: false,
                      showLineHeightButton: false,
                    ),
                  ),
                ),
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: QuillEditor.basic(
                    controller: controller,
                    config: const QuillEditorConfig(
                      placeholder: 'Saisissez votre texte ici...',
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (fieldKey != null && helperText != null)
          _buildHelperText(fieldKey, helperText),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int? maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    String? suffix,
    String? fieldKey,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            onTap: () {
              if (fieldKey != null) setState(() => _focusedField = fieldKey);
            },
            onTapOutside: (_) {
              if (fieldKey != null && _focusedField == fieldKey) {
                setState(() => _focusedField = null);
              }
            },
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixText: suffix,
              suffixStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
          ),
        ),
        if (fieldKey != null && helperText != null)
          _buildHelperText(fieldKey, helperText),
      ],
    );
  }

  Widget _buildRadioGroup<T>({
    required String title,
    required List<T> values,
    required T? selectedValue,
    required Function(T?) onChanged,
    required String Function(T) labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
            fontFamily: 'Manjari',
          ),
        ),
        ...values.map(
          (value) => Theme(
            data: ThemeData(visualDensity: const VisualDensity(vertical: -4)),
            child: RadioListTile<T>(
              dense: true,
              activeColor: const Color(0xFF3AAE5E),
              contentPadding: EdgeInsets.zero,
              title: Text(
                labelBuilder(value),
                style: const TextStyle(fontSize: 15),
              ),
              value: value,
              groupValue: selectedValue,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxGroup({
    required String title,
    required List<Map<String, String>> options,
    required List<String> selectedValues,
    required Function(String, bool) onChanged,
    bool scrollable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
            fontFamily: 'Manjari',
          ),
        ),
        const SizedBox(height: 8),
        if (scrollable)
          Container(
            height: 300, // Shows ~5 items, scrollable for more
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: options
                    .map(
                      (option) => Theme(
                        data: ThemeData(
                          visualDensity: const VisualDensity(vertical: -4),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          activeColor: const Color(0xFF3AAE5E),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            option['label']!,
                            style: const TextStyle(fontSize: 15),
                          ),
                          value: selectedValues.contains(option['code']),
                          onChanged: (checked) {
                            onChanged(option['code']!, checked ?? false);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
        else
          ...options.map(
            (option) => Theme(
              data: ThemeData(visualDensity: const VisualDensity(vertical: -4)),
              child: CheckboxListTile(
                dense: true,
                activeColor: const Color(0xFF3AAE5E),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  option['label']!,
                  style: const TextStyle(fontSize: 15),
                ),
                value: selectedValues.contains(option['code']),
                onChanged: (checked) {
                  onChanged(option['code']!, checked ?? false);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFFF9800),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(selectedDate)
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: selectedDate != null
                      ? Colors.black87
                      : Colors.grey[400],
                ),
              ),
            ),
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberChip(
    String label,
    String? selectedValue,
    Function(String) onSelected,
  ) {
    final isSelected = selectedValue == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? label : '');
      },
      selectedColor: const Color(0xFFFF9800).withOpacity(0.2),
      checkmarkColor: const Color(0xFFFF9800),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFFFF9800) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFFFF9800) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDocumentChip(String label, String type) {
    final isSelected = _selectedCvOptions.contains(type);
    return ActionChip(
      label: Text(label),
      avatar: Icon(
        isSelected ? Icons.check_circle : Icons.add_circle_outline,
        size: 20,
        color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[600],
      ),
      onPressed: () async {
        if (isSelected) {
          setState(() {
            _selectedCvOptions.remove(type);
          });
        } else {
          await _pickDocumentFile(type, label);
        }
      },
      backgroundColor: isSelected
          ? const Color(0xFF3AAE5E).withOpacity(0.1)
          : Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Future<void> _pickDocumentFile(String type, String label) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() {
        _selectedCvOptions.add(type);
        final file = result.files.first;
        _selectedDocumentFiles.add(file);
        _documentFilesByType[type] = file;
      });

      _showSnack('$label ajouté avec succès');
    } catch (e) {
      _showSnack('Impossible de sélectionner le fichier', isError: true);
    }
  }

  void _removeDocument(int index) {
    setState(() {
      final file = _selectedDocumentFiles[index];

      // Find and remove the type from _selectedCvOptions BEFORE removing from _documentFilesByType
      final typeToRemove = _documentFilesByType.entries
          .where((entry) => entry.value == file)
          .map((entry) => entry.key)
          .toList();
      for (final type in typeToRemove) {
        _selectedCvOptions.remove(type);
      }

      // Remove from _selectedDocumentFiles
      _selectedDocumentFiles.removeAt(index);

      // Remove from _documentFilesByType
      _documentFilesByType.removeWhere((key, value) => value == file);
    });
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9800),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Suivant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF3AAE5E),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoReviewCards() {
    if (_selectedMediaFiles.isEmpty && _existingMediaUrls.isEmpty)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Photos', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Existing photos from URLs
            ..._existingMediaUrls.map((url) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            }),
            // New photos from files
            ..._selectedMediaFiles.map((file) {
              if (file.bytes != null) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(file.bytes!, fit: BoxFit.cover),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentReviewCards() {
    if (_selectedDocumentFiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Documents ajoutés',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedDocumentFiles.map((file) {
            final ext = file.extension?.toLowerCase();
            final isPdf = ext == 'pdf';
            final isDoc = ext == 'doc' || ext == 'docx';
            final isImage = ['jpg', 'jpeg', 'png'].contains(ext);

            Widget content;

            if (isImage && file.bytes != null) {
              // Afficher le preview de l'image
              content = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  file.bytes!,
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                ),
              );
            } else {
              // Afficher l'icône pour les autres types
              IconData iconData;
              Color iconColor;
              if (isPdf) {
                iconData = Icons.picture_as_pdf;
                iconColor = Colors.red;
              } else if (isDoc) {
                iconData = Icons.description;
                iconColor = Colors.blue;
              } else if (isImage) {
                iconData = Icons.image;
                iconColor = Colors.green;
              } else {
                iconData = Icons.insert_drive_file;
                iconColor = Colors.grey;
              }

              content = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, size: 32, color: iconColor),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                color: Colors.grey[50],
              ),
              child: content,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3AAE5E)
                    : Colors.grey.withOpacity(0.4),
                width: 1.5,
              ),
              color: isSelected
                  ? const Color(0xFF3AAE5E).withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Color(0xFF3AAE5E), size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
