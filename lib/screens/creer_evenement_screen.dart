import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EventMediaFile {
  final String? id;
  final String url;
  final String? type;

  const _EventMediaFile({
    this.id,
    required this.url,
    this.type,
  });
}

class CreerEvenementScreen extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? initialData;
  final bool shouldReturnToListingOnSuccess;

  const CreerEvenementScreen({
    super.key,
    this.eventId,
    this.initialData,
    this.shouldReturnToListingOnSuccess = false,
  });

  @override
  State<CreerEvenementScreen> createState() => _CreerEvenementScreenState();
}

class _CreerEvenementScreenState extends State<CreerEvenementScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Step 1 - Informations
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedType;

  final String _categoriesApiUrl = 'https://api.myreklam.fr/Categorie.php';
  bool _isCategoryLoading = false;
  String? _categoryLoadError;
  List<Map<String, String>> _categoryOptions = [];
  List<Map<String, String>> _subCategoryOptions = [];
  final Map<String, String> _categoryCodeToId = {};
  final Map<String, List<Map<String, String>>> _subsByParentId = {};

  // Step 3 - Lien
  final TextEditingController _linkController = TextEditingController();

  // Step 3 - Description
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionQuillController = QuillController.basic();

  // Focus tracking for helper text
  String? _focusedField;
  final TextEditingController _organizerNameController = TextEditingController();
  final TextEditingController _disponibleChezController =
      TextEditingController();
  String? _selectedDisponibleLocation;
  String? selectedOptionOrg = "Oui";
  bool _touteLaFrance = false;
  String? _selectedPrixEntree = "Gratuit";
  String? _selectedPricingMode; // 'Prix unique' or 'Catégories'
  final TextEditingController _prixEntreeController = TextEditingController();
  List<Map<String, TextEditingController>> _priceCategories = [];
  String? _selectedModeReservation = "Sans inscription";
  final TextEditingController _siteWebController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitError;

  // Media
  final List<PlatformFile> _selectedMediaFiles = [];
  List<_EventMediaFile> _existingMedia = [];
  final Set<String> _deletingMediaKeys = {};

  // Step 4 - Informations
  final TextEditingController _prixInitialController = TextEditingController();
  final TextEditingController _prixFinalController = TextEditingController();
  final TextEditingController _reductionController = TextEditingController();
  String? _selectedValidite;
  String? _selectedMoyenRetrait;
  String? _selectedTimeEvenement = "Sur une journée";
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? selectedDate;

  bool _acceptMessages = false;
  List<String> _selectedDaysOfWeek = [];

  bool get _isEditMode => widget.eventId != null && widget.eventId!.isNotEmpty;

  final List<String> _types = [
    'Présentiel',
    'En ligne',
    'Hybride',
  ];

  final List<String> _validiteOptions = [
    'Offre permanente',
    '1 semaine',
    '1 mois',
    '3 mois',
    '6 mois',
  ];

  final List<String> _moyenRetraitOptions = ['magasin', 'en ligne', 'les deux'];

  final List<String> _locationOptions = [
    'France',
    'Belgique',
    'Suisse',
    'Canada',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadEventCategories();
    if (_isEditMode && widget.initialData != null) {
      _prefillFromInitialData(widget.initialData!);
    } else {
      _checkForSavedProgress();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionQuillController.dispose();
    _organizerNameController.dispose();
    _disponibleChezController.dispose();
    _linkController.dispose();
    _prixInitialController.dispose();
    _prixFinalController.dispose();
    _reductionController.dispose();
    _prixEntreeController.dispose();
    for (final cat in _priceCategories) {
      cat['name']!.dispose();
      cat['price']!.dispose();
    }
    _siteWebController.dispose();
    super.dispose();
  }

  void _addPriceCategory() {
    setState(() {
      _priceCategories.add({
        'name': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removePriceCategory(int index) {
    setState(() {
      _priceCategories[index]['name']!.dispose();
      _priceCategories[index]['price']!.dispose();
      _priceCategories.removeAt(index);
    });
  }

  void _toggleDayOfWeek(String day) {
    setState(() {
      if (_selectedDaysOfWeek.contains(day)) {
        _selectedDaysOfWeek.remove(day);
      } else {
        _selectedDaysOfWeek.add(day);
      }
    });
  }

  void _clearDaysOfWeek() {
    setState(() {
      _selectedDaysOfWeek.clear();
    });
  }

  Future<void> _checkForSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('evenement_draft');

    if (savedData != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showContinueOrNewModal();
      });
    }
  }

  void _prefillFromInitialData(Map<String, dynamic> data) {
    debugPrint('Prefilling event form with data keys: ${data.keys.toList()}');

    setState(() {
      _titleController.text = data['title']?.toString() ?? '';
      _linkController.text = data['landing_url']?.toString() ?? '';

      // Category & SubCategory
      _selectedCategory = data['category_code']?.toString();
      _selectedSubCategory = data['sub_category_code']?.toString();

      // Format type
      _selectedType = data['format_type']?.toString();

      // Organizer
      final isOrganizer = data['is_organizer'];
      if (isOrganizer == false || isOrganizer == 0 || isOrganizer == '0' || isOrganizer == 'false') {
        selectedOptionOrg = 'Non';
        _organizerNameController.text = data['organizer_name']?.toString() ?? '';
      } else {
        selectedOptionOrg = 'Oui';
      }

      // Coverage
      _disponibleChezController.text = data['coverage_area']?.toString() ?? '';
      _touteLaFrance = data['is_nationwide'] == true || data['is_nationwide'] == 1;

      // Price
      final priceType = data['price_type']?.toString();
      if (priceType == 'payant') {
        _selectedPrixEntree = 'Payant';
        final pricingMode = data['pricing_mode']?.toString();
        if (pricingMode == 'categories') {
          _selectedPricingMode = 'Catégories';
          final cats = data['price_categories'] as List? ?? [];
          _priceCategories = cats.map<Map<String, TextEditingController>>((c) {
            return {
              'name': TextEditingController(text: c['name']?.toString() ?? ''),
              'price': TextEditingController(text: c['price']?.toString().replaceAll(RegExp(r'\.00$'), '') ?? ''),
            };
          }).toList();
        } else {
          _selectedPricingMode = 'Prix unique';
          final amount = data['price_amount'];
          if (amount != null) {
            _prixEntreeController.text = amount.toString().replaceAll(RegExp(r'\.00$'), '');
          }
        }
      } else {
        _selectedPrixEntree = 'Gratuit';
        _selectedPricingMode = null;
      }

      // Reservation mode
      final resMode = data['reservation_mode']?.toString();
      if (resMode == 'inscription') {
        _selectedModeReservation = 'Inscription requise';
      } else if (resMode == 'achat_billet') {
        _selectedModeReservation = 'Achat de billet obligatoire';
      } else {
        _selectedModeReservation = 'Sans inscription';
      }

      // Website
      _siteWebController.text = data['website_url']?.toString() ?? '';

      // Duration type
      final durationType = data['duration_type']?.toString();
      if (durationType == 'multi_day') {
        _selectedTimeEvenement = 'Sur plusieurs jours';
      } else if (durationType == 'permanent') {
        _selectedTimeEvenement = 'Permanent';
      } else {
        _selectedTimeEvenement = 'Sur une journée';
      }

      // Dates
      final eventDate = data['event_date']?.toString();
      final startDate = data['start_date']?.toString();
      if (eventDate != null && eventDate.isNotEmpty) {
        try { selectedDate = DateTime.parse(eventDate); } catch (_) {}
      } else if (startDate != null && startDate.isNotEmpty) {
        try { selectedDate = DateTime.parse(startDate); } catch (_) {}
      }

      // Times
      final st = data['start_time']?.toString();
      final et = data['end_time']?.toString();
      if (st != null && st.isNotEmpty) {
        final parts = st.split(':');
        if (parts.length >= 2) {
          _startTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      if (et != null && et.isNotEmpty) {
        final parts = et.split(':');
        if (parts.length >= 2) {
          _endTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }

      // Commercial data
      final initPrice = data['initial_price'];
      if (initPrice != null) {
        _prixInitialController.text = initPrice.toString().replaceAll(RegExp(r'\.00$'), '');
      }
      final finalPrice = data['final_price'];
      if (finalPrice != null) {
        _prixFinalController.text = finalPrice.toString().replaceAll(RegExp(r'\.00$'), '');
      }
      final discount = data['discount_value'];
      if (discount != null) {
        _reductionController.text = discount.toString().replaceAll(RegExp(r'\.00$'), '');
      }

      _acceptMessages = data['accept_messages'] == true || data['accept_messages'] == 1;

      // Days of week
      final daysOfWeek = data['days_of_week'] as List? ?? [];
      _selectedDaysOfWeek = daysOfWeek.map<String>((d) => d.toString()).toList();

      // Existing media
      final mediaFiles = data['media_files'] as List? ?? [];
      _existingMedia = mediaFiles
          .whereType<Map>()
          .map<_EventMediaFile?>(
            (m) {
              final resolvedUrl = _buildMediaUrl(m['url']?.toString());
              if (resolvedUrl.isEmpty) return null;
              return _EventMediaFile(
                id: m['id']?.toString(),
                url: resolvedUrl,
                type: m['type']?.toString(),
              );
            },
          )
          .whereType<_EventMediaFile>()
          .toList();
    });

    // Restore rich text description after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDescription(data);
    });
  }

  void _restoreDescription(Map<String, dynamic> data) {
    final descDelta = data['description_delta'];
    debugPrint('EVENT EDIT _restoreDescription: descDelta type=${descDelta?.runtimeType}');
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
        debugPrint('Error restoring event description delta: $e');
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
  }

  String _buildMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url.replaceFirst(RegExp(r'^https?://[^/]+'), serverBase);
    }

    if (url.startsWith('/')) {
      return '$serverBase$url';
    }

    return '$serverBase/$url';
  }

  Future<void> _showContinueOrNewModal() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Formulaire en cours'),
        content: const Text(
          'Vous avez un formulaire d\'événement non terminé. Voulez-vous continuer où vous vous êtes arrêté ?',
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
        'title': _titleController.text,
        'description_delta': jsonEncode(_descriptionQuillController.document.toDelta().toJson()),
        'category': _selectedCategory,
        'sub_category': _selectedSubCategory,
        'type': _selectedType,
        'link': _linkController.text,
        'organizer': selectedOptionOrg,
        'organizer_name': _organizerNameController.text,
        'disponible_chez': _disponibleChezController.text,
        'toute_la_france': _touteLaFrance,
        'prix_entree': _selectedPrixEntree,
        'pricing_mode': _selectedPricingMode,
        'prix_entree_montant': _prixEntreeController.text,
        'price_categories': _priceCategories.map((c) => {
          'name': c['name']!.text,
          'price': c['price']!.text,
        }).toList(),
        'mode_reservation': _selectedModeReservation,
        'site_web': _siteWebController.text,
        'duree': _selectedTimeEvenement,
        'date': selectedDate?.toIso8601String(),
        'start_time_hour': _startTime?.hour,
        'start_time_minute': _startTime?.minute,
        'end_time_hour': _endTime?.hour,
        'end_time_minute': _endTime?.minute,
        'accept_messages': _acceptMessages,
        'days_of_week': _selectedDaysOfWeek,
      };
      await prefs.setString('evenement_draft', jsonEncode(formData));
    } catch (e) {
      debugPrint('Error saving form progress: $e');
    }
  }

  Future<void> _restoreFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('evenement_draft');
      if (savedData == null) return;

      final formData = jsonDecode(savedData) as Map<String, dynamic>;

      setState(() {
        _currentStep = formData['step'] ?? 0;
        _titleController.text = formData['title'] ?? '';
        _selectedCategory = formData['category'];
        _selectedSubCategory = formData['sub_category'];
        _selectedType = formData['type'];
        _linkController.text = formData['link'] ?? '';
        selectedOptionOrg = formData['organizer'] ?? 'Oui';
        _organizerNameController.text = formData['organizer_name'] ?? '';
        _disponibleChezController.text = formData['disponible_chez'] ?? '';
        _touteLaFrance = formData['toute_la_france'] ?? false;
        _selectedPrixEntree = formData['prix_entree'] ?? 'Gratuit';
        _selectedPricingMode = formData['pricing_mode'];
        _prixEntreeController.text = formData['prix_entree_montant'] ?? '';
        // Restore price categories
        for (final cat in _priceCategories) {
          cat['name']!.dispose();
          cat['price']!.dispose();
        }
        _priceCategories = [];
        final savedCats = formData['price_categories'] as List? ?? [];
        for (final c in savedCats) {
          _priceCategories.add({
            'name': TextEditingController(text: c['name']?.toString() ?? ''),
            'price': TextEditingController(text: c['price']?.toString() ?? ''),
          });
        }
        _selectedModeReservation = formData['mode_reservation'] ?? 'Sans inscription';
        _siteWebController.text = formData['site_web'] ?? '';
        _selectedTimeEvenement = formData['duree'] ?? 'Sur une journée';
        _acceptMessages = formData['accept_messages'] ?? false;
        _selectedDaysOfWeek = (formData['days_of_week'] as List? ?? []).map<String>((d) => d.toString()).toList();

        if (formData['date'] != null) {
          selectedDate = DateTime.parse(formData['date']);
        }
        if (formData['start_time_hour'] != null) {
          _startTime = TimeOfDay(hour: formData['start_time_hour'], minute: formData['start_time_minute'] ?? 0);
        }
        if (formData['end_time_hour'] != null) {
          _endTime = TimeOfDay(hour: formData['end_time_hour'], minute: formData['end_time_minute'] ?? 0);
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

      // Refresh subcategories for the restored category (categories may already be loaded)
      if (_selectedCategory != null && _categoryCodeToId.isNotEmpty) {
        setState(() {
          _subCategoryOptions = _getSubCategoriesForCode(_selectedCategory);
          if (_subCategoryOptions.isEmpty ||
              !_subCategoryOptions.any((sub) => sub['code'] == _selectedSubCategory)) {
            _selectedSubCategory = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error restoring form data: $e');
    }
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('evenement_draft');
    } catch (e) {
      debugPrint('Error clearing saved progress: $e');
    }
  }

  Future<void> _handleBackButton() async {
    if (_isEditMode) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Arrêter la modification ?'),
          content: const Text(
            'Êtes-vous sûr de vouloir quitter ? Les modifications non enregistrées seront perdues.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuer'),
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
      if (confirm == true && mounted) {
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

  Future<void> _pickMediaFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedMediaFiles.addAll(result.files);
        });
      }
    } catch (e) {
      debugPrint('Error picking media files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sélection des fichiers.')),
      );
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
    });
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
          return 'Veuillez sélectionner une catégorie.';
        }
        if (_selectedSubCategory == null) {
          return 'Veuillez sélectionner une sous-catégorie.';
        }
        break;
      
      case 1: // Step 2: Lien (optional)
        break;
      
      case 2: // Step 3: Description
        if (_titleController.text.trim().length < 5) {
          return 'Le titre doit contenir au moins 5 caractères.';
        }
        if (_descriptionQuillController.document.toPlainText().trim().length < 20) {
          return 'La description doit contenir au moins 20 caractères.';
        }
        if (_disponibleChezController.text.trim().isEmpty) {
          return 'Indiquez le lieu de l\'événement.';
        }
        if (_selectedPrixEntree == null) {
          return 'Précisez si l\'événement est gratuit ou payant.';
        }
        if (_selectedPrixEntree == 'Payant') {
          if (_selectedPricingMode == null) {
            return 'Veuillez choisir un type de tarification.';
          }
          if (_selectedPricingMode == 'Prix unique' && _prixEntreeController.text.trim().isEmpty) {
            return 'Indiquez le prix d\'entrée.';
          }
          if (_selectedPricingMode == 'Catégories') {
            if (_priceCategories.isEmpty) {
              return 'Ajoutez au moins une catégorie de prix.';
            }
            for (int i = 0; i < _priceCategories.length; i++) {
              if (_priceCategories[i]['name']!.text.trim().isEmpty) {
                return 'Indiquez le nom de la catégorie de prix ${i + 1}.';
              }
              if (_priceCategories[i]['price']!.text.trim().isEmpty) {
                return 'Indiquez le prix de la catégorie "${_priceCategories[i]['name']!.text.trim()}".';
              }
            }
          }
        }
        break;
      
      case 3: // Step 4: Dates et horaires
        // Only require date for one_day and multi_day, not for permanent
        if (_selectedTimeEvenement != 'Permanent' && selectedDate == null) {
          return 'Sélectionnez une date pour l\'événement.';
        }
        break;
      
      case 4: // Step 5: Médias (optional)
        break;
    }
    return null;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF3AAE5E),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEF8A40),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF424242),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                    Navigator.pop(context); // Pop dialog
                    Navigator.pop(context); // Pop CreerEvenementScreen
                    if (widget.shouldReturnToListingOnSuccess) {
                      Navigator.pop(context); // Pop EventDetailScreen
                    }
                  },
                  child: const Icon(Icons.close, color: Colors.grey, size: 22),
                ),
              ),
              const SizedBox(height: 8),
              Image.asset("assets/images/imagepop.png"),
              const SizedBox(height: 20),
              Text(
                _isEditMode ? 'Evenement mis à jour' : 'Evenement publié',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3AAE5E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isEditMode
                    ? 'Votre événement a été mis à jour avec succès'
                    : 'Vous pouvez consulter cela au niveau de votre espace professionnel',
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

  Map<String, dynamic> _buildEventPayload() {
    final durationType = _selectedTimeEvenement == 'Sur plusieurs jours'
        ? 'multi_day'
        : _selectedTimeEvenement == 'Sur une journée'
            ? 'one_day'
            : 'permanent';

    final priceType = _selectedPrixEntree == 'Payant' ? 'payant' : 'gratuit';
    final reservationMode = _selectedModeReservation == 'Inscription requise'
        ? 'inscription'
        : _selectedModeReservation == 'Achat de billet obligatoire'
            ? 'achat_billet'
            : 'sans_inscription';

    return {
      'category_code': _selectedCategory,
      'sub_category_code': _selectedSubCategory,
      'format_type': _selectedType,
      'title': _titleController.text.trim(),
      'description': _descriptionQuillController.document.toPlainText().trim(),
      'description_delta': _descriptionQuillController.document.toDelta().toJson(),
      'landing_url': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
      'is_organizer': selectedOptionOrg == 'Oui',
      'organizer_name': selectedOptionOrg == 'Non' ? _organizerNameController.text.trim() : null,
      'coverage_area': _disponibleChezController.text.trim(),
      'is_nationwide': _touteLaFrance,
      'price_type': priceType,
      'price_amount': priceType == 'payant' && _selectedPricingMode == 'Prix unique'
          ? double.tryParse(_prixEntreeController.text.replaceAll(',', '.'))
          : null,
      // New pricing fields — only sent when using categories
      if (priceType == 'payant') ...{
        'pricing_mode': _selectedPricingMode == 'Catégories' ? 'categories' : 'unique',
      },
      if (priceType == 'payant' && _selectedPricingMode == 'Catégories') ...{
        'price_categories': _priceCategories.map((c) => {
              'name': c['name']!.text.trim(),
              'price': double.tryParse(c['price']!.text.replaceAll(',', '.')),
            }).toList(),
      },
      'reservation_mode': reservationMode,
      'website_url': _siteWebController.text.trim().isEmpty ? null : _siteWebController.text.trim(),
      'duration_type': durationType,
      'event_date': durationType == 'one_day' && selectedDate != null
          ? selectedDate!.toIso8601String().split('T').first
          : null,
      'start_date': durationType == 'multi_day' && selectedDate != null
          ? selectedDate!.toIso8601String().split('T').first
          : null,
      'end_date': durationType == 'multi_day' && selectedDate != null
          ? selectedDate!.toIso8601String().split('T').first
          : null,
      'start_time': _startTime != null ? _formatTime(_startTime) : null,
      'end_time': _endTime != null ? _formatTime(_endTime) : null,
      'days_of_week': (durationType == 'multi_day' || durationType == 'permanent') && _selectedDaysOfWeek.isNotEmpty
          ? _selectedDaysOfWeek
          : null,
      'initial_price': _prixInitialController.text.trim().isNotEmpty
          ? double.tryParse(_prixInitialController.text.replaceAll(',', '.'))
          : null,
      'final_price': _prixFinalController.text.trim().isNotEmpty
          ? double.tryParse(_prixFinalController.text.replaceAll(',', '.'))
          : null,
      'discount_value': _reductionController.text.trim().isNotEmpty
          ? double.tryParse(_reductionController.text.replaceAll(',', '.'))
          : null,
      'accept_messages': _acceptMessages,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));
  }

  Future<void> _submitEvent() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final payload = _buildEventPayload();
      debugPrint('========== EVENT SUBMIT PAYLOAD ==========');
      payload.forEach((key, value) {
        debugPrint('  $key: $value (${value.runtimeType})');
      });
      debugPrint('==========================================');
      Map<String, dynamic> response;

      if (_isEditMode) {
        response = await ApiClient().put(
          '/events/${widget.eventId}',
          body: payload,
          auth: true,
        );
      } else {
        response = await ApiClient().post(
          '/events',
          body: payload,
          auth: true,
        );
      }

      if ((response['success'] ?? false) == true) {
        final eventId = _isEditMode
            ? widget.eventId
            : (response['data'] as Map<String, dynamic>?)?['id']?.toString();

        if (eventId != null && _selectedMediaFiles.isNotEmpty) {
          await _uploadMedia(eventId);
        }

        if (!_isEditMode) await _clearSavedProgress();
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog();
        }
      } else {
        throw ApiException(
          statusCode: response['status'] ?? 500,
          message: response['message']?.toString() ?? (_isEditMode ? 'Erreur lors de la mise à jour' : 'Une erreur est survenue.'),
        );
      }
    } on ApiException catch (e) {
      setState(() => _submitError = e.firstError);
      if (mounted) setState(() => _isSubmitting = false);
    } catch (e) {
      setState(() => _submitError = _isEditMode
          ? 'Impossible de mettre à jour l\'événement. Veuillez réessayer.'
          : 'Impossible de publier l\'événement. Veuillez réessayer.');
      debugPrint('Error submitting event: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteExistingMedia(String mediaId) async {
    final eventId = widget.eventId;
    if (eventId == null) return;

    final key = mediaId;
    setState(() => _deletingMediaKeys.add(key));

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/events/$eventId/media/$mediaId');
      final token = await TokenStorage.getAccessToken();
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _existingMedia.removeWhere((m) => m.id == mediaId);
          _deletingMediaKeys.remove(key);
        });
      } else {
        throw Exception('Failed to delete media');
      }
    } catch (e) {
      debugPrint('Error deleting media: $e');
      if (mounted) {
        setState(() => _deletingMediaKeys.remove(key));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression du média.')),
        );
      }
    }
  }

  Future<void> _uploadMedia(String eventId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/events/$eventId/media');
    final request = http.MultipartRequest('POST', uri);
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    for (final file in _selectedMediaFiles) {
      if (file.bytes == null) continue;
      request.files.add(
        http.MultipartFile.fromBytes(
          'media[]',
          file.bytes!,
          filename: file.name,
          contentType: _inferMediaContentType(file.extension),
        ),
      );
    }

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      final responseBody = await streamedResponse.stream.bytesToString();
      debugPrint('Media upload failed: ${streamedResponse.statusCode} -> $responseBody');
      throw Exception('Échec du téléchargement des médias.');
    }
  }

  MediaType? _inferMediaContentType(String? extension) {
    if (extension == null) return null;
    final lowerExt = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(lowerExt)) {
      return MediaType('image', lowerExt == 'jpg' ? 'jpeg' : lowerExt);
    }
    if (['mp4', 'mov', 'avi'].contains(lowerExt)) {
      return MediaType('video', lowerExt);
    }
    return null;
  }

  Future<void> _loadEventCategories() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryLoadError = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_categoriesApiUrl),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: const {'Method': 'getByType', 'type': 'evenements'},
      );

      if (response.statusCode != 200) {
        throw Exception('Status code ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']?.toString() ?? 'Réponse invalide du service des catégories.'
            : 'Réponse invalide du service des catégories.';
        throw Exception(message);
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Structure de données inattendue.');
      }

      final mainRaw = data['main'];
      final subsRaw = data['subs'];

      final parsedCategories = <Map<String, String>>[];
      final parsedCodeToId = <String, String>{};

      if (mainRaw is List) {
        for (final item in mainRaw) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString();
            final code = item['code']?.toString();
            final label = (item['label'] ?? item['labelEn'])?.toString();
            if (id != null && code != null && label != null) {
              parsedCategories.add({'id': id, 'code': code, 'label': label});
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

      final nextSubCategories = _getSubCategoriesForCode(_selectedCategory, parsedCodeToId, parsedSubs);

      setState(() {
        _categoryOptions = parsedCategories;
        _categoryCodeToId
          ..clear()
          ..addAll(parsedCodeToId);
        _subsByParentId
          ..clear()
          ..addAll(parsedSubs);
        _subCategoryOptions = nextSubCategories;
        if (_subCategoryOptions.isEmpty ||
            !_subCategoryOptions.any((sub) => sub['code'] == _selectedSubCategory)) {
          _selectedSubCategory = null;
        }
        _isCategoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading event categories: $e');
      setState(() {
        _categoryLoadError = 'Impossible de charger les catégories. Veuillez réessayer.';
        _isCategoryLoading = false;
      });
    }
  }

  List<Map<String, String>> _getSubCategoriesForCode(
    String? categoryCode,
    [Map<String, String>? codeToId,
    Map<String, List<Map<String, String>>>? subsMap,]
  ) {
    final effectiveCodeToId = codeToId ?? _categoryCodeToId;
    final effectiveSubs = subsMap ?? _subsByParentId;
    if (categoryCode == null) return [];
    final parentId = effectiveCodeToId[categoryCode];
    if (parentId == null) return [];
    final subs = effectiveSubs[parentId];
    if (subs == null) return [];
    return List<Map<String, String>>.from(subs);
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
                    _isEditMode ? 'Modifier l\'événement' : 'Créer un événement',
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
                'Partagez vos événements avec la communauté',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
        value: (_currentStep + 1) / (_totalSteps + 1),
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
        minHeight: 6,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Categories();
      case 1:
        return _buildStep2Lien();
      case 2:
        return _buildStep3Description();
      case 3:
        return _buildStep4Informations();
      case 4:
        return _buildStepPhoto();
      case 5:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
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
                'Ajoutez des photos de votre événement pour donner envie aux participants et mettre l’ambiance en avant.',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: 1 + _existingMedia.length + _selectedMediaFiles.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddPhotoButton();
              }
              final existingIndex = index - 1;
              if (existingIndex < _existingMedia.length) {
                return _buildExistingMediaCard(_existingMedia[existingIndex]);
              }
              final newIndex = existingIndex - _existingMedia.length;
              return _buildPhotoPreviewCard(_selectedMediaFiles[newIndex], newIndex);
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildNextButton(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickMediaFiles,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3AAE5E),
            width: 2,
            style: BorderStyle.solid,
          ),
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
              'Ajouter ${_selectedMediaFiles.isEmpty ? "" : "des "}photos',
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

  Widget _buildPhotoPreviewCard(PlatformFile file, int index) {
    final isCoverPhoto = index == 0;

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
          if (isCoverPhoto)
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

  bool _isImageUrl(String url, String? type) {
    if (type != null && type.toLowerCase().contains('image')) return true;
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif');
  }

  bool _isVideoUrl(String url, String? type) {
    if (type != null && type.toLowerCase().contains('video')) return true;
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi');
  }

  Widget _buildBrokenMediaPlaceholder() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: const Center(
        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildExistingMediaCard(_EventMediaFile media) {
    final key = media.id ?? media.url;
    final isDeleting = _deletingMediaKeys.contains(key);
    final isImage = _isImageUrl(media.url, media.type);
    final isVideo = _isVideoUrl(media.url, media.type);

    Widget content;
    if (isImage) {
      content = Image.network(
        media.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildBrokenMediaPlaceholder(),
      );
    } else if (isVideo) {
      content = Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white),
        ),
      );
    } else {
      content = _buildBrokenMediaPlaceholder();
    }

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
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: content,
            ),
          ),
          if (isDeleting)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          if (!isDeleting)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  if (media.id != null) {
                    _deleteExistingMedia(media.id!);
                  }
                },
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

  Widget _buildMediaPreview(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
    final isVideo = ['mp4', 'mov', 'avi'].contains(extension);

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
          child: Icon(
            Icons.play_circle_outline,
            size: 40,
            color: Colors.white,
          ),
        ),
      );
    } else {
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
  }

  // ─── STEP 1: Informations ───
  Widget _buildStep1Categories() {
    final categoryItems = _categoryOptions
        .map(
          (category) => DropdownMenuItem<String>(
            value: category['code'],
            child: Text(category['label'] ?? '--', style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList();

    final subCategoryItems = _subCategoryOptions
        .map(
          (sub) => DropdownMenuItem<String>(
            value: sub['code'],
            child: Text(sub['label'] ?? '--', style: const TextStyle(fontSize: 13)),
          ),
        )
        .toList();

    final hasCategories = categoryItems.isNotEmpty;
    final hasSubCategories = subCategoryItems.isNotEmpty;
    final selectedCategoryValue = hasCategories &&
            categoryItems.any((item) => item.value == _selectedCategory)
        ? _selectedCategory
        : null;
    final selectedSubCategoryValue = hasSubCategories &&
            subCategoryItems.any((item) => item.value == _selectedSubCategory)
        ? _selectedSubCategory
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.info_outline,
          title: 'Catégorie',
          children: [
            if (_isCategoryLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_categoryLoadError != null)
              _buildInlineErrorBanner(
                _categoryLoadError!,
                onRetry: _loadEventCategories,
              )
            else
              _buildDropdownField(
                label: 'Choisissez la catégorie d\'événement*',
                value: selectedCategoryValue,
                items: const [],
                menuItems: categoryItems,
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                    _selectedSubCategory = null;
                    _subCategoryOptions = _getSubCategoriesForCode(val);
                  });
                },
                hint: _buildRequiredHint('Choisissez la catégorie d\'événement'),
                backgroundColor: const Color(0xFFF9FAFB),
                enabled: hasCategories,
              ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Type d\'événement*',
              value: selectedSubCategoryValue,
              items: const [],
              menuItems: subCategoryItems,
              onChanged: (val) => setState(() => _selectedSubCategory = val),
              hint: _buildRequiredHint('Type d\'événement'),
              backgroundColor: const Color(0xFFF9FAFB),
              enabled: hasSubCategories,
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: "Format de l'evenement*",
              value: _selectedType,
              items: _types,
              onChanged: (val) => setState(() => _selectedType = val),
              hint: _buildRequiredHint("Format de l'evenement"),
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

  // ─── STEP 2: Lien ───
  Widget _buildStep2Lien() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.link,
          title: 'Lien',
          subtitle:
              "Collez le lien de la page de l'événement. Nous l'utiliserons pour récupérer automatiquement les informations et pré-remplir votre annonce.",
          children: [
            _buildTextField(
              label: 'Ajouter un lien',
              controller: _linkController,
              fieldKey: 'link',
              helperText: 'Le lien permettra d\'extraire automatiquement le titre, la description, les dates, le lieu et autres détails de l\'événement pour faciliter la création de votre annonce.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _nextStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF9800),
              side: const BorderSide(color: Color(0xFFFF9800)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "je n'ai pas de lien",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 3: Description ───
  Widget _buildStep3Description() {
    return Column(
      children: [
        _buildFormCard(
          icon: Icons.description_outlined,
          title: 'Description',
          children: [
            _buildTextField(
              label: 'Quel est votre titre?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Saisissez un titre accrocheur et descriptif pour votre événement (ex: "Conférence développement durable 2026").',
            ),
            const SizedBox(height: 12),
            _buildRichTextEditor(
              label: 'Décrivez l\'évènement*',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail votre événement. Utilisez les outils de mise en forme pour mettre en évidence les informations importantes.',
            ),
            const SizedBox(height: 12),
            _buildRadioGroup(
              title: "Etes-vous l'organisateur de cet évènement ?",
              values: ["Oui", "Non"],
              selectedValue: selectedOptionOrg,
              onChanged: (val) => setState(() => selectedOptionOrg = val),
              labelBuilder: (value) => value,
            ),
            if (selectedOptionOrg == "Non") const SizedBox(height: 8),
            if (selectedOptionOrg == "Non")
              _buildTextField(
                label: 'Nom de l\'organisateur',
                controller: _organizerNameController,
                fieldKey: 'organizer_name',
                helperText: 'Indiquez le nom de la personne ou de l\'organisme qui organise cet événement.',
              ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Précisez la ville/région où cette offre est valide',
              controller: _disponibleChezController,
              fieldKey: 'disponible_chez',
              helperText: 'Indiquez la ville, la région ou le lieu précis de l\'événement.',
              enabled: !_touteLaFrance,
              onChanged: (value) {
                if (value.trim().isNotEmpty && _touteLaFrance) {
                  setState(() => _touteLaFrance = false);
                }
              },
            ),
            const SizedBox(height: 16),
            // Toute la France switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toute la France',
                    style: TextStyle(fontSize: 14, color: Color(0xFF424242)),
                  ),
                  Switch(
                    value: _touteLaFrance,
                    onChanged: _disponibleChezController.text.trim().isEmpty
                        ? (val) {
                            setState(() {
                              _touteLaFrance = val;
                              if (val) {
                                _disponibleChezController.clear();
                              }
                            });
                          }
                        : null,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFFEF8A40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildRadioGroup(
              title: "Prix d'entrée: *",
              values: ["Gratuit", "Payant"],
              selectedValue: _selectedPrixEntree,
              onChanged: (val) => setState(() {
                _selectedPrixEntree = val;
                if (val == 'Gratuit') {
                  _selectedPricingMode = null;
                }
              }),
              labelBuilder: (value) => value,
            ),
            if (_selectedPrixEntree == "Payant") ...[
              const SizedBox(height: 16),
              _buildRadioGroup(
                title: "Type de tarification: *",
                values: ["Prix unique", "Catégories"],
                selectedValue: _selectedPricingMode,
                onChanged: (val) => setState(() {
                  _selectedPricingMode = val;
                  if (val == 'Catégories' && _priceCategories.isEmpty) {
                    _addPriceCategory();
                  }
                }),
                labelBuilder: (value) => value,
              ),
              const SizedBox(height: 12),
              // Prix unique input
              if (_selectedPricingMode == "Prix unique")
                Row(
                  children: [
                    Container(
                      width: 250,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _prixEntreeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Prix',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '€',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E9B5B),
                        ),
                      ),
                    ),
                  ],
                ),
              // Catégories de prix
              if (_selectedPricingMode == "Catégories") ...[
                ...List.generate(_priceCategories.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: _priceCategories[index]['name'],
                              decoration: InputDecoration(
                                hintText: 'ex: Enfant, VIP...',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: _priceCategories[index]['price'],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '€',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('€', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E9B5B))),
                        if (_priceCategories.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 22),
                            onPressed: () => _removePriceCategory(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addPriceCategory,
                    icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFFEF8A40)),
                    label: const Text(
                      'Ajouter une catégorie de prix',
                      style: TextStyle(color: Color(0xFFEF8A40), fontSize: 13),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),
            // Mode de reservation
            _buildRadioGroup(
              title: "Mode de reservation: *",
              values: [
                "Sans inscription",
                "Inscription requise",
                "Achat de billet obligatoire",
              ],
              selectedValue: _selectedModeReservation,
              onChanged: (val) =>
                  setState(() => _selectedModeReservation = val),
              labelBuilder: (value) => value,
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Entrer le site web',
              controller: _siteWebController,
              keyboardType: TextInputType.url,
              fieldKey: 'site_web',
              helperText: 'Saisissez l\'adresse du site web officiel de l\'événement ou de l\'organisateur.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 4: Informations ───
  Widget _buildStep4Informations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.description_outlined,
          title: 'Informations',
          children: [
            _buildRadioGroup(
              title: "Durée de l'évènement :*",
              values: ['Sur une journée', 'Sur plusieurs jours', 'Permanent'],
              selectedValue: _selectedTimeEvenement,
              onChanged: (val) {
                setState(() {
                  _selectedTimeEvenement = val;
                  // Clear days of week when selecting "Sur une journée"
                  if (val == 'Sur une journée') {
                    _selectedDaysOfWeek.clear();
                  }
                });
              },
              labelBuilder: (value) => value,
            ),
            const SizedBox(height: 10),
            _selectedTimeEvenement == 'Sur une journée'
                ? _buildDateField(
                    title: "Date:",
                    selectedDate: selectedDate,
                    onDateSelected: (date) =>
                        setState(() => selectedDate = date),
                  )
                : const SizedBox(),
            _selectedTimeEvenement != 'Sur plusieurs jours'
                ? const SizedBox(height: 14)
                : const SizedBox(),
            _selectedTimeEvenement == 'Sur plusieurs jours'
                ? Column(
                    children: [
                      _buildDateField(
                        title: "A partir de:",
                        selectedDate: selectedDate,
                        onDateSelected: (date) =>
                            setState(() => selectedDate = date),
                      ),
                      const SizedBox(height: 14),
                      _buildDateField(
                        title: "Jusqu'à:",
                        selectedDate: selectedDate,
                        onDateSelected: (date) =>
                            setState(() => selectedDate = date),
                      ),
                      const SizedBox(height: 14),
                    ],
                  )
                : const SizedBox(),
            // Horaires
            const Text(
              'Horaires :',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'De',
                  style: TextStyle(fontSize: 14, color: Color(0xFF424242)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_startTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: _startTime != null
                                  ? const Color(0xFF424242)
                                  : Colors.grey[400],
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  'À',
                  style: TextStyle(fontSize: 14, color: Color(0xFF424242)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(_endTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: _endTime != null
                                  ? const Color(0xFF424242)
                                  : Colors.grey[400],
                            ),
                          ),
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week selection (for multi_day and permanent)
            if (_selectedTimeEvenement == 'Sur plusieurs jours' || _selectedTimeEvenement == 'Permanent') ...[
              const Text(
                'Jours de la semaine :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              _buildDaysOfWeekSelector(),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 5: Review ───
  Widget _buildStep5Review() {
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
        const Center(
          child: Text(
            'Vérifiez votre évènement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Center(
          child: Text(
            'Relisez les informations avant de publier votre événement',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Step 1: Catégorie
        _buildReviewSection(
          title: 'Étape 1 - Catégorie',
          onEdit: () => setState(() => _currentStep = 0),
          rows: [
            _buildReviewRow('Catégorie', _selectedCategory ?? '-'),
            _buildReviewRow('Sous-catégorie', _selectedSubCategory ?? '-'),
            _buildReviewRow('Format', _selectedType ?? '-'),
          ],
        ),
        const SizedBox(height: 16),

        // Step 2: Lien
        _buildReviewSection(
          title: 'Étape 2 - Lien',
          onEdit: () => setState(() => _currentStep = 1),
          rows: [
            _buildReviewRow(
              'Lien',
              _linkController.text.isEmpty ? 'Aucun lien' : _linkController.text,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 3: Description
        _buildReviewSection(
          title: 'Étape 3 - Description',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow(
              'Titre',
              _titleController.text.isEmpty ? '-' : _titleController.text,
            ),
            _buildReviewRow(
              'Description',
              _descriptionQuillController.document.toPlainText().trim().isEmpty
                  ? '-'
                  : _descriptionQuillController.document.toPlainText().trim(),
            ),
            _buildReviewRow(
              'Organisateur',
              selectedOptionOrg == 'Oui'
                  ? 'Vous'
                  : (_organizerNameController.text.isEmpty ? '-' : _organizerNameController.text),
            ),
            _buildReviewRow(
              'Lieu',
              _disponibleChezController.text.isEmpty ? '-' : _disponibleChezController.text,
            ),
            _buildReviewRow('Toute la France', _touteLaFrance ? 'Oui' : 'Non'),
            _buildReviewRow('Prix d\'entrée', _selectedPrixEntree ?? '-'),
            if (_selectedPrixEntree == 'Payant') ...[
              _buildReviewRow('Type de tarification', _selectedPricingMode ?? '-'),
              if (_selectedPricingMode == 'Prix unique')
                _buildReviewRow('Montant', '${_prixEntreeController.text} €'),
              if (_selectedPricingMode == 'Catégories')
                ..._priceCategories.map((c) =>
                  _buildReviewRow(c['name']!.text.isEmpty ? '-' : c['name']!.text, '${c['price']!.text} €'),
                ),
            ],
            _buildReviewRow('Mode de réservation', _selectedModeReservation ?? '-'),
            _buildReviewRow(
              'Site web',
              _siteWebController.text.isEmpty ? '-' : _siteWebController.text,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 4: Informations
        _buildReviewSection(
          title: 'Étape 4 - Informations',
          onEdit: () => setState(() => _currentStep = 3),
          rows: [
            _buildReviewRow('Durée', _selectedTimeEvenement ?? '-'),
            if (selectedDate != null)
              _buildReviewRow(
                'Date',
                '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
              ),
            _buildReviewRow('Horaire', '${_formatTime(_startTime)} - ${_formatTime(_endTime)}'),
            if ((_selectedTimeEvenement == 'Sur plusieurs jours' || _selectedTimeEvenement == 'Permanent') &&
                _selectedDaysOfWeek.isNotEmpty)
              _buildReviewRow('Jours', _formatSelectedDaysOfWeek()),
          ],
        ),
        const SizedBox(height: 16),

        // Step 5: Médias
        _buildReviewSection(
          title: 'Étape 5 - Médias',
          onEdit: () => setState(() => _currentStep = 4),
          rows: [
            _buildReviewRow(
              'Fichiers',
              _selectedMediaFiles.isEmpty
                  ? 'Aucun média sélectionné'
                  : '${_selectedMediaFiles.length} fichier(s)',
            ),
          ],
        ),
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
                'Accepter de recevoir des messages à propos de cet événement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les intéressés pourront vous contacter pour connaître le programme, l’accès ou les modalités pratiques de l’événement.',
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
            onPressed: _isSubmitting ? null : _submitEvent,
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
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_isEditMode ? 'Mise à jour en cours...' : 'Publication en cours...'),
                    ],
                  )
                : Text(
                    _isEditMode ? 'Mettre à jour l\'événement' : 'Publier l\'événement',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            _submitError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildDateField({
    required String title,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withOpacity(0.8),
                fontFamily: 'Manjari',
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isRequired)
              const Text(" *", style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime(2100),
            );

            if (pickedDate != null) {
              onDateSelected(pickedDate);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedDate != null
                  ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"
                  : "Sélectionner une date",
              style: TextStyle(
                color: selectedDate != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    List<String> items = const [],
    List<DropdownMenuItem<String>>? menuItems,
    required ValueChanged<String?> onChanged,
    Widget? hint,
    Color? backgroundColor,
    bool enabled = true,
  }) {
    final dropdownItems = menuItems ??
        items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint:
            hint ??
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
        isExpanded: true,
        items: dropdownItems,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  Widget _buildInlineErrorBanner(String message, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF57C00), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6D4C41)),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
        ],
      ),
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
      margin: const EdgeInsets.only(top: 8, bottom: 8),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffix,
    IconData? prefixIcon,
    String? fieldKey,
    String? helperText,
    bool enabled = true,
    ValueChanged<String>? onChanged,
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
            keyboardType: keyboardType,
            enabled: enabled,
            onChanged: onChanged,
            onTap: () {
              if (fieldKey != null) {
                setState(() => _focusedField = fieldKey);
              }
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
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[400]) : null,
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
            if (fieldKey != null) {
              setState(() => _focusedField = fieldKey);
            }
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
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildDaysOfWeekSelector() {
    final days = [
      {'code': 'monday', 'label': 'L', 'name': 'Lundi'},
      {'code': 'tuesday', 'label': 'Ma', 'name': 'Mardi'},
      {'code': 'wednesday', 'label': 'Me', 'name': 'Mercredi'},
      {'code': 'thursday', 'label': 'J', 'name': 'Jeudi'},
      {'code': 'friday', 'label': 'V', 'name': 'Vendredi'},
      {'code': 'saturday', 'label': 'S', 'name': 'Samedi'},
      {'code': 'sunday', 'label': 'D', 'name': 'Dimanche'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final isSelected = _selectedDaysOfWeek.contains(day['code']);
        return GestureDetector(
          onTap: () => _toggleDayOfWeek(day['code']!),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3AAE5E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                day['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF424242),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatSelectedDaysOfWeek() {
    final dayNames = {
      'monday': 'Lun',
      'tuesday': 'Mar',
      'wednesday': 'Mer',
      'thursday': 'Jeu',
      'friday': 'Ven',
      'saturday': 'Sam',
      'sunday': 'Dim',
    };
    final days = _selectedDaysOfWeek.map((d) => dayNames[d] ?? d).toList();
    return days.join(', ');
  }
}
