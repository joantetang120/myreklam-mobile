import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/models/location_data.dart';
import 'package:myreklam/widgets/location_picker_field.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/config/api_config.dart';

class CreerOffreEmploiScreen extends StatefulWidget {
  final String? jobOfferId;
  final Map<String, dynamic>? initialData;

  const CreerOffreEmploiScreen({super.key, this.jobOfferId, this.initialData});

  bool get isEditMode => jobOfferId != null;

  @override
  State<CreerOffreEmploiScreen> createState() => _CreerOffreEmploiScreenState();
}

class _CreerOffreEmploiScreenState extends State<CreerOffreEmploiScreen> {
  static const String _categoriesApiUrl = 'https://api.myreklam.fr/Categorie.php';
  int _currentStep = 0;
  final int _totalSteps = 5;

  // API & Loading states
  bool _isMetaLoading = true;
  String? _metaError;
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;

  // Metadata from API
  List<Map<String, dynamic>> _categoriesFromApi = [];
  List<Map<String, dynamic>> _functionsForCategory = [];
  Map<int, List<Map<String, dynamic>>> _categoryFunctionsMap = {};
  List<String> _contractTypes = [];
  List<String> _workTimes = [];
  List<String> _salaryTypes = [];
  List<String> _salaryPeriods = [];
  List<String> _availabilityTypes = [];
  List<String> _advantagesFromApi = [];
  List<String> _educationLevels = [];
  List<String> _experienceLevels = [];

  // Step 1 - Informations
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedFunctionId;
  String? _selectedFunctionName;

  // Step 2 - Lien
  final TextEditingController _linkController = TextEditingController();

  // Step 3 - Description
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionQuillController = QuillController.basic();
  String? _selectedContractType;
  String? _selectedWorkTime;
  String? _selectedSalaryType;
  final TextEditingController _salaryMinController = TextEditingController();
  final TextEditingController _salaryMaxController = TextEditingController();
  final TextEditingController _salaryExactController = TextEditingController();
  bool _isSalaryGross = true;
  String? _selectedSalaryPeriod;
  String? _selectedAvailabilityType;
  DateTime? _availableFromDate;
  DateTime? _availableUntilDate;
  List<String> _selectedAdvantages = [];
  bool _teleworkPossible = false;
  LocationData? _selectedLocation;
  bool _nationwide = false;
  bool _showGoogleMap = false;
  final TextEditingController _companyNameController = TextEditingController();
  bool _showCompanyProfile = false;
  final TextEditingController _companyWebsiteController = TextEditingController();

  // Step 4 - Profil
  String? _selectedEducationLevel;
  String? _selectedExperienceLevel;
  final QuillController _profileDescQuillController = QuillController.basic();

  // Step 5 - Media
  List<PlatformFile> _selectedMediaFiles = [];
  final List<String> _existingMediaUrls = [];
  List<Map<String, dynamic>> _uploadedMedia = [];

  // Settings
  bool _acceptMessages = false;
  
  // Focus tracking for helper text
  String? _focusedField;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
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
    _linkController.text = (data['external_link'] ?? data['link'])?.toString() ?? '';
    _companyNameController.text = (data['company_name'] ?? (data['company'] is Map ? data['company']['name'] : null))?.toString() ?? '';
    _companyWebsiteController.text = (data['company_website'] ?? (data['company'] is Map ? data['company']['website'] : null))?.toString() ?? '';
    _showCompanyProfile = (data['show_company_presentation'] ?? (data['company'] is Map ? data['company']['show_company_profile'] : null)) == true;
    // Profile description will be restored in _restoreProfileDescription after frame
    final profileDescPlain = (data['profile_description'] ?? (data['profile'] is Map ? data['profile']['description'] : null))?.toString() ?? '';
    final profileDescDelta = data['profile_description_delta'] ?? (data['profile'] is Map ? data['profile']['description_delta'] : null);
    // Restore location data
    if (data['location'] is Map) {
      final locationMap = data['location'] as Map<String, dynamic>;
      _selectedLocation = LocationData(
        address: locationMap['city']?.toString() ?? '',
        latitude: locationMap['lat'] != null
            ? double.tryParse(locationMap['lat'].toString())
            : null,
        longitude: locationMap['lng'] != null
            ? double.tryParse(locationMap['lng'].toString())
            : null,
        city: locationMap['location_city']?.toString(),
        postalCode: locationMap['location_postal_code']?.toString(),
      );
    } else if (data['location'] != null) {
      // Legacy location string
      _selectedLocation = LocationData(address: data['location'].toString());
    }
    _nationwide = (data['all_france'] ?? data['nationwide'] ?? (data['location'] is Map ? data['location']['nationwide'] : null)) == true;
    _showGoogleMap = (data['show_google_location'] ?? (data['location'] is Map ? data['location']['show_google_map'] : null)) == true;
    _teleworkPossible = (data['remote_work'] ?? data['telework_possible']) == true;
    _acceptMessages = data['accept_messages'] == true;

    // Contract type & work time
    final contractRaw = data['contract_type'];
    _selectedContractType = contractRaw is Map ? (contractRaw['value'] ?? contractRaw['name'])?.toString() : contractRaw?.toString();
    final workTimeRaw = data['work_time'];
    _selectedWorkTime = workTimeRaw is Map ? (workTimeRaw['value'] ?? workTimeRaw['name'])?.toString() : workTimeRaw?.toString();

    // Salary
    final salaryRaw = data['salary'];
    if (salaryRaw is Map) {
      _selectedSalaryType = salaryRaw['type']?.toString();
      _isSalaryGross = salaryRaw['is_gross'] == true;
      _selectedSalaryPeriod = salaryRaw['period']?.toString();
      if (_selectedSalaryType == 'RANGE') {
        _salaryMinController.text = salaryRaw['min']?.toString() ?? '';
        _salaryMaxController.text = salaryRaw['max']?.toString() ?? '';
      } else if (_selectedSalaryType == 'EXACT') {
        _salaryExactController.text = (salaryRaw['min'] ?? salaryRaw['exact'])?.toString() ?? '';
      }
    } else {
      _selectedSalaryType = data['salary_type']?.toString();
      if (data['salary_min'] != null) _salaryMinController.text = data['salary_min'].toString();
      if (data['salary_max'] != null) _salaryMaxController.text = data['salary_max'].toString();
      if (data['salary_exact'] != null) _salaryExactController.text = data['salary_exact'].toString();
      _selectedSalaryPeriod = data['salary_period']?.toString();
      final paymentType = data['salary_payment_type']?.toString();
      if (paymentType != null) _isSalaryGross = paymentType.toLowerCase().contains('brut') || paymentType == 'brut';
    }

    // Availability
    final availRaw = data['availability'];
    if (availRaw is Map) {
      _selectedAvailabilityType = availRaw['type']?.toString();
      if (availRaw['start_date'] != null) _availableFromDate = DateTime.tryParse(availRaw['start_date'].toString());
      if (availRaw['end_date'] != null) _availableUntilDate = DateTime.tryParse(availRaw['end_date'].toString());
    } else {
      _selectedAvailabilityType = data['availability_type']?.toString();
      if (data['available_from'] != null) _availableFromDate = DateTime.tryParse(data['available_from'].toString());
      if (data['available_until'] != null) _availableUntilDate = DateTime.tryParse(data['available_until'].toString());
    }

    // Advantages
    final advantagesRaw = data['advantages'];
    if (advantagesRaw is List) {
      _selectedAdvantages = advantagesRaw.map((a) => a is Map ? (a['name'] ?? a['value'] ?? a.toString()).toString() : a.toString()).toList();
    }

    // Education & experience
    final eduRaw = data['education_level'] ?? (data['profile'] is Map ? data['profile']['education_level'] : null);
    _selectedEducationLevel = eduRaw is Map ? (eduRaw['value'] ?? eduRaw['name'])?.toString() : eduRaw?.toString();
    final expRaw = data['experience_level'] ?? (data['profile'] is Map ? data['profile']['experience_level'] : null);
    _selectedExperienceLevel = expRaw is Map ? (expRaw['value'] ?? expRaw['name'])?.toString() : expRaw?.toString();

    // Category & function - set names, IDs will be resolved after metadata loads
    final categoryRaw = data['category'];
    _selectedCategoryName = categoryRaw is Map ? (categoryRaw['name'] ?? categoryRaw.toString()) : categoryRaw?.toString();
    if (data['category_id'] != null) _selectedCategoryId = int.tryParse(data['category_id'].toString());
    final functionRaw = data['function'];
    _selectedFunctionName = functionRaw is Map ? (functionRaw['name'] ?? functionRaw.toString()) : functionRaw?.toString();
    if (data['function_id'] != null) _selectedFunctionId = int.tryParse(data['function_id'].toString());

    // Load existing media URLs
    final mediaFiles = data['media_files'] as List? ?? data['media'] as List? ?? [];
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDescription(data);
      _restoreProfileDescription(profileDescDelta, profileDescPlain);
    });
  }

  void _restoreDescription(Map<String, dynamic> data) {
    final descDelta = data['description_delta'];
    debugPrint('EDIT FORM _restoreDescription: descDelta type=${descDelta?.runtimeType}, value=$descDelta');
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
        debugPrint('Error restoring job offer description delta: $e');
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

  void _restoreProfileDescription(dynamic delta, String plainText) {
    bool restored = false;
    if (delta != null) {
      try {
        List opsList;
        if (delta is List) {
          opsList = delta;
        } else if (delta is Map && delta['ops'] is List) {
          opsList = delta['ops'] as List;
        } else if (delta is String && delta.isNotEmpty) {
          dynamic rawData = jsonDecode(delta);
          if (rawData is String) rawData = jsonDecode(rawData);
          if (rawData is List) {
            opsList = rawData;
          } else if (rawData is Map && rawData['ops'] is List) {
            opsList = rawData['ops'] as List;
          } else {
            throw Exception('Unknown delta format');
          }
        } else {
          throw Exception('Unsupported delta type');
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
          _profileDescQuillController.document = Document.fromJson(filteredOps);
          restored = true;
        }
      } catch (e) {
        debugPrint('Error restoring profile description delta: $e');
      }
    }

    if (!restored && plainText.isNotEmpty) {
      final doc = Document();
      doc.insert(0, plainText);
      _profileDescQuillController.document = doc;
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkForSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('job_offer_draft');
    
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
          'Vous avez un formulaire d\'offre d\'emploi non terminé. Voulez-vous continuer où vous vous êtes arrêté ?',
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
        'category_id': _selectedCategoryId,
        'category_name': _selectedCategoryName,
        'function_id': _selectedFunctionId,
        'function_name': _selectedFunctionName,
        'contract_type': _selectedContractType,
        'work_time': _selectedWorkTime,
        'salary_type': _selectedSalaryType,
        'company_name': _companyNameController.text,
        'company_website': _companyWebsiteController.text,
        'salary_min': _salaryMinController.text,
        'salary_max': _salaryMaxController.text,
        'salary_exact': _salaryExactController.text,
        'location': _selectedLocation?.toMap(),
        'education_level': _selectedEducationLevel,
        'experience_level': _selectedExperienceLevel,
        'profile_description': _profileDescQuillController.document.toPlainText().trim(),
        'profile_description_delta': jsonEncode(_profileDescQuillController.document.toDelta().toJson()),
      };
      
      await prefs.setString('job_offer_draft', jsonEncode(formData));
    } catch (e) {
      debugPrint('Error saving form progress: $e');
    }
  }

  Future<void> _restoreFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('job_offer_draft');
      
      if (savedData == null) return;
      
      final formData = jsonDecode(savedData) as Map<String, dynamic>;
      
      setState(() {
        _currentStep = formData['step'] ?? 0;
        _titleController.text = formData['title'] ?? '';
        _selectedCategoryId = formData['category_id'];
        _selectedCategoryName = formData['category_name'];
        _selectedFunctionId = formData['function_id'];
        _selectedFunctionName = formData['function_name'];
        _selectedContractType = formData['contract_type'];
        _selectedWorkTime = formData['work_time'];
        _selectedSalaryType = formData['salary_type'];
        _companyNameController.text = formData['company_name'] ?? '';
        _companyWebsiteController.text = formData['company_website'] ?? '';
        _salaryMinController.text = formData['salary_min'] ?? '';
        _salaryMaxController.text = formData['salary_max'] ?? '';
        _salaryExactController.text = formData['salary_exact'] ?? '';
        if (formData['location'] != null && formData['location'] is Map) {
          _selectedLocation = LocationData.fromMap(formData['location']);
        }
        _selectedEducationLevel = formData['education_level'];
        _selectedExperienceLevel = formData['experience_level'];
        // Restore rich text description
        if (formData['description_delta'] != null) {
          try {
            final delta = jsonDecode(formData['description_delta']);
            _descriptionQuillController.document = Document.fromJson(delta);
          } catch (e) {
            debugPrint('Error restoring description: $e');
          }
        }

        // Restore rich text profile description
        if (formData['profile_description_delta'] != null) {
          try {
            final delta = jsonDecode(formData['profile_description_delta']);
            _profileDescQuillController.document = Document.fromJson(delta);
          } catch (e) {
            debugPrint('Error restoring profile description: $e');
          }
        } else if ((formData['profile_description'] ?? '').toString().isNotEmpty) {
          final doc = Document();
          doc.insert(0, formData['profile_description']);
          _profileDescQuillController.document = doc;
        }
      });
    } catch (e) {
      debugPrint('Error restoring form data: $e');
    }
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('job_offer_draft');
    } catch (e) {
      debugPrint('Error clearing saved progress: $e');
    }
  }

  Future<void> _handleBackButton() async {
    if (_isEditMode) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  @override
  void dispose() {
    _linkController.dispose();
    _titleController.dispose();
    _descriptionQuillController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _salaryExactController.dispose();
    _companyNameController.dispose();
    _companyWebsiteController.dispose();
    _profileDescQuillController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _isMetaLoading = true;
      _metaError = null;
    });

    try {
      final categoriesFuture = _fetchJobCategories();
      final metaFuture = ApiClient().authenticatedGet('/job-offers/meta');

      final categoriesData = await categoriesFuture;
      final response = await metaFuture;
      debugPrint('Job offer meta response: $response');
      final data = response['data'] ?? response;

      setState(() {
        _categoriesFromApi = categoriesData['categories'];
        _categoryFunctionsMap = categoriesData['functions'];
        debugPrint('Loaded ${_categoriesFromApi.length} categories from API');

        // Enums
        debugPrint('contract_types raw: ${data['contract_types']}');
        debugPrint('work_times raw: ${data['work_times']}');
        debugPrint('education_levels raw: ${data['education_levels']}');
        debugPrint('experience_levels raw: ${data['experience_levels']}');
        _contractTypes = _parseStringList(data['contract_types']);
        _workTimes = _parseStringList(data['work_times']);
        _salaryTypes = _parseStringList(data['salary_types']);
        _salaryPeriods = _parseStringList(data['salary_periods']);
        _availabilityTypes = _parseStringList(data['availability_types']);
        _advantagesFromApi = _parseStringList(data['advantages']);
        _educationLevels = _parseStringList(data['education_levels']);
        _experienceLevels = _parseStringList(data['experience_levels']);

        _isMetaLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading job offer metadata: $e');
      setState(() {
        _isMetaLoading = false;
        _metaError = 'Erreur de chargement des données. Veuillez réessayer.';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchJobCategories() async {
    try {
      final response = await http.post(
        Uri.parse(_categoriesApiUrl),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: const {'Method': 'getByType', 'type': 'offres_emploi'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Impossible de charger les catégories (code ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: 0,
          message: 'Réponse invalide du service des catégories.',
        );
      }

      if (decoded['status'] != 'success') {
        final message = decoded['message']?.toString() ??
            'Impossible de charger les catégories.';
        throw ApiException(statusCode: 0, message: message);
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          statusCode: 0,
          message: 'Structure de données des catégories invalide.',
        );
      }

      final mainRaw = data['main'];
      final subsRaw = data['subs'];

      final mainList = <Map<String, dynamic>>[];
      if (mainRaw is List) {
        for (final item in mainRaw) {
          if (item is Map<String, dynamic>) {
            mainList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final subsMap = <String, List<Map<String, dynamic>>>{};
      if (subsRaw is Map<String, dynamic>) {
        subsRaw.forEach((key, value) {
          if (value is List) {
            final subList = <Map<String, dynamic>>[];
            for (final sub in value) {
              if (sub is Map<String, dynamic>) {
                subList.add(Map<String, dynamic>.from(sub));
              }
            }
            subsMap[key] = subList;
          }
        });
      }

      mainList.sort(_compareCategoryMaps);

      final categories = <Map<String, dynamic>>[];
      final functionsMap = <int, List<Map<String, dynamic>>>{};

      for (final category in mainList) {
        final id = category['id'];
        final label = category['label']?.toString();
        if (id == null || label == null || label.trim().isEmpty) {
          continue;
        }

        final categoryId = id is int ? id : int.tryParse(id.toString());
        if (categoryId == null) continue;

        final parentIdStr = category['id']?.toString();
        final subList = parentIdStr != null ? subsMap[parentIdStr] : null;
        final functions = <Map<String, dynamic>>[];

        if (subList != null) {
          subList.sort(_compareCategoryMaps);
          for (final sub in subList) {
            final subId = sub['id'];
            final subLabel = sub['label']?.toString();
            if (subId == null || subLabel == null || subLabel.trim().isEmpty) {
              continue;
            }
            final functionId = subId is int ? subId : int.tryParse(subId.toString());
            if (functionId == null) continue;

            functions.add({
              'id': functionId,
              'name': subLabel,
            });
          }
        }

        categories.add({
          'id': categoryId,
          'name': label,
        });
        functionsMap[categoryId] = functions;
      }

      return {
        'categories': categories,
        'functions': functionsMap,
      };
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Error fetching job categories: $e');
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de récupérer les catégories.',
      );
    }
  }

  int _compareCategoryMaps(Map<String, dynamic> a, Map<String, dynamic> b) {
    final orderComparison = _parseOrder(a['order']).compareTo(_parseOrder(b['order']));
    if (orderComparison != 0) {
      return orderComparison;
    }

    final labelA = a['label']?.toString().toLowerCase() ?? '';
    final labelB = b['label']?.toString().toLowerCase() ?? '';
    return labelA.compareTo(labelB);
  }

  int _parseOrder(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        // Handle if items are objects with 'name' or 'label' field
        if (e is Map) {
          return (e['name'] ?? e['label'] ?? e['value'] ?? e.toString()).toString();
        }
        return e.toString();
      }).toList();
    }
    // Handle if data is a Map (key-value pairs)
    if (data is Map) {
      return data.keys.map((e) => e.toString()).toList();
    }
    return [];
  }

  // Helper to convert display label back to API value
  String _toApiValue(String? displayLabel) {
    if (displayLabel == null) return '';
    
    // Direct mappings for known display labels
    const displayToApi = {
      // Work times
      'Temps plein': 'FULL_TIME',
      'Temps partiel': 'PART_TIME',
      // Salary periods
      'Par an': 'YEAR',
      'Annuel': 'YEAR',
      'Par mois': 'MONTH',
      'Mensuel': 'MONTH',
      'Par jour': 'DAY',
      'Par heure': 'HOUR',
      // Education levels
      'Sans diplôme': 'NONE',
      'CAP/BEP': 'CAP',
      'Baccalauréat': 'BAC',
      'Bac+2': 'BAC_2',
      'Bac +2': 'BAC_2',
      'Bac+3': 'BAC_3',
      'Bac +3': 'BAC_3',
      'Master/Bac+5': 'MASTER',
      'Bac+5': 'MASTER',
      'Bac +5': 'MASTER',
      'Doctorat': 'DOCTORATE',
      // Experience levels
      'Débutant': 'JUNIOR',
      '1-3 ans': '1_3_YEARS',
      '1 à 3 ans': '1_3_YEARS',
      '3-5 ans': '3_5_YEARS',
      '3 à 5 ans': '3_5_YEARS',
      '5-10 ans': '5_10_YEARS',
      '5 à 10 ans': '5_10_YEARS',
      'Expert (+10 ans)': 'EXPERT',
      '+10 ans': 'EXPERT',
      // Advantages
      'Transport': 'TRANSPORT',
      'Titre restaurant': 'MEAL_VOUCHERS',
      'RTT': 'RTT',
      'Télétravail': 'REMOTE_WORK',
      'Voiture de fonction': 'COMPANY_CAR',
      'Plan épargne': 'SAVINGS_PLAN',
      'Horaires flexibles': 'FLEXIBLE_HOURS',
      'Pourboires': 'TIPS',
      'Commissions': 'COMMISSIONS',
      // Contract types
      'Freelance': 'FREELANCE',
      'Intérim': 'INTERIM',
      'Stage': 'STAGE',
      'Alternance': 'ALTERNANCE',
      'Contrat à durée indéterminée': 'CDI',
      'CDI': 'CDI',
      'Contrat à durée déterminée': 'CDD',
      'CDD': 'CDD',
      'Saisonnier': 'SEASONAL',
      'Bénévolat': 'VOLUNTEER',
      'Volontariat': 'VOLUNTEER',
      // Education levels - additional mappings
      'BAC/Employé/Ouvrier spécialisé': 'BAC',
      'CAP-BEP/Employé qualifié': 'CAP',
      // Experience levels - additional mappings
      'Débutant : moins de 2 années': 'JUNIOR',
      'Intermédiaire : de 2 à 4 années': '1_3_YEARS',
      'Confirmé : de 5 à 9 années': '5_10_YEARS',
      'Expert : 10 années et plus': 'EXPERT',
      // Advantages - additional mappings
      '13ème mois': 'THIRTEENTH_MONTH',
      'Heures supp. majorée': 'OVERTIME_PAY',
      'Participation au transport': 'TRANSPORT',
    };
    
    return displayToApi[displayLabel] ?? displayLabel;
  }

  // Convert list of display labels to API values
  List<String> _toApiValues(List<String> displayLabels) {
    return displayLabels.map((label) => _toApiValue(label)).toList();
  }

  // Helper to get display label for enum values (for dropdowns)
  String _getDisplayLabel(String value, String type) {
    const apiToDisplay = {
      'FULL_TIME': 'Temps plein',
      'PART_TIME': 'Temps partiel',
      'YEAR': 'Par an',
      'MONTH': 'Par mois',
      'DAY': 'Par jour',
      'HOUR': 'Par heure',
      'NONE': 'Sans diplôme',
      'CAP': 'CAP/BEP',
      'BAC': 'Baccalauréat',
      'BAC_2': 'Bac+2',
      'BAC_3': 'Bac+3',
      'MASTER': 'Master/Bac+5',
      'DOCTORATE': 'Doctorat',
      'JUNIOR': 'Débutant',
      '1_3_YEARS': '1-3 ans',
      '3_5_YEARS': '3-5 ans',
      '5_10_YEARS': '5-10 ans',
      'EXPERT': 'Expert (+10 ans)',
      'VOLUNTEER': 'Bénévolat',
    };
    return apiToDisplay[value] ?? value;
  }

  void _updateFunctionsForCategory(int? categoryId) {
    if (categoryId == null) {
      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
        _selectedFunctionId = null;
        _selectedFunctionName = null;
        _functionsForCategory = [];
      });
      return;
    }

    final category = _categoriesFromApi.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => {},
    );
    if (category.isEmpty) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = category['name']?.toString();
      _functionsForCategory = List<Map<String, dynamic>>.from(_categoryFunctionsMap[categoryId] ?? []);
      _selectedFunctionId = null;
      _selectedFunctionName = null;
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
      case 0: // Step 1: Informations
        if (_selectedCategoryId == null) {
          return 'Veuillez sélectionner une catégorie.';
        }
        if (_selectedFunctionId == null) {
          return 'Veuillez sélectionner une fonction.';
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
        if (_selectedContractType == null) {
          return 'Veuillez sélectionner un type de contrat.';
        }
        if (_selectedWorkTime == null) {
          return 'Veuillez sélectionner un temps de travail.';
        }
        if (_selectedSalaryType == null) {
          return 'Veuillez indiquer le type de rémunération.';
        }
        if (_selectedSalaryType == 'RANGE') {
          if (_salaryMinController.text.trim().isEmpty) {
            return 'Veuillez indiquer le salaire minimum.';
          }
          if (_salaryMaxController.text.trim().isEmpty) {
            return 'Veuillez indiquer le salaire maximum.';
          }
        }
        if (_selectedSalaryType == 'EXACT' && _salaryExactController.text.trim().isEmpty) {
          return 'Veuillez indiquer le salaire exact.';
        }
        if (_selectedAvailabilityType == null) {
          return 'Veuillez préciser la disponibilité souhaitée.';
        }
        if (_selectedLocation == null && !_nationwide) {
          return 'Renseignez une ville ou activez "Toute la France".';
        }
        if (_companyNameController.text.trim().isEmpty) {
          return 'Veuillez indiquer le nom de l\'entreprise.';
        }
        break;
      
      case 3: // Step 4: Profil
        if (_selectedEducationLevel == null) {
          return 'Veuillez sélectionner un niveau d\'études requis.';
        }
        if (_selectedExperienceLevel == null) {
          return 'Veuillez sélectionner un niveau d\'expérience requis.';
        }
        break;
      
      case 4: // Step 5: Médias (optional)
        break;
    }
    return null;
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final validFiles = result.files.where((file) {
          final sizeInMB = (file.size) / (1024 * 1024);
          return sizeInMB <= 20;
        }).toList();

        if (validFiles.length < result.files.length) {
          _showSnack('Certains fichiers dépassent 20 MB et ont été ignorés', isError: true);
        }

        setState(() {
          _selectedMediaFiles.addAll(validFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      _showSnack('Erreur lors de la sélection des fichiers', isError: true);
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
    });
  }

  Future<void> _uploadMediaFilesToJobOffer(String jobOfferId) async {
    if (_selectedMediaFiles.isEmpty) return;

    setState(() => _isUploadingMedia = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Non authentifié');

      final uri = Uri.parse('${ApiConfig.baseUrl}/job-offers/$jobOfferId/media');
      debugPrint('Uploading media to: $uri');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      for (final file in _selectedMediaFiles) {
        if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath('media[]', file.path!));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final mediaList = data['media'] as List? ?? [];
        _uploadedMedia = List<Map<String, dynamic>>.from(mediaList);
        debugPrint('Uploaded ${mediaList.length} media files');
      } else {
        debugPrint('Media upload failed: ${response.statusCode} - ${response.body}');
        _showSnack('Médias non uploadés, mais offre créée', isError: false);
      }
    } catch (e) {
      debugPrint('Error uploading media: $e');
      _showSnack('Médias non uploadés, mais offre créée', isError: false);
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }

  Future<void> _submitJobOffer() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      // Build salary object - convert display labels to API values
      Map<String, dynamic>? salary;
      if (_selectedSalaryType != null && _selectedSalaryType != 'DEPENDING_ON_PROFILE') {
        salary = {
          'type': _selectedSalaryType,
          'currency': 'EUR',
          'is_gross': _isSalaryGross,
          'period': _toApiValue(_selectedSalaryPeriod),
        };
        if (_selectedSalaryType == 'RANGE') {
          salary['min'] = double.tryParse(_salaryMinController.text) ?? 0;
          salary['max'] = double.tryParse(_salaryMaxController.text) ?? 0;
        } else if (_selectedSalaryType == 'EXACT') {
          salary['min'] = double.tryParse(_salaryExactController.text) ?? 0;
          salary['max'] = double.tryParse(_salaryExactController.text) ?? 0;
        }
      } else if (_selectedSalaryType == 'DEPENDING_ON_PROFILE') {
        salary = {'type': 'DEPENDING_ON_PROFILE'};
      }

      // Build availability object
      final availability = {
        'type': _selectedAvailabilityType ?? 'IMMEDIATE',
        if (_selectedAvailabilityType == 'FROM_DATE' && _availableFromDate != null)
          'start_date': _availableFromDate!.toIso8601String().split('T')[0],
        if (_availableUntilDate != null)
          'end_date': _availableUntilDate!.toIso8601String().split('T')[0],
      };

      // Build request body - convert display labels to API values
      final body = {
        'category': _selectedCategoryName,
        'function': _selectedFunctionName,
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        if (_selectedFunctionId != null) 'function_id': _selectedFunctionId,
        if (_linkController.text.isNotEmpty) 'external_link': _linkController.text,
        'title': _titleController.text,
        'description': _descriptionQuillController.document.toPlainText().trim(),
        'description_delta': _descriptionQuillController.document.toDelta().toJson(),
        'contract_type': _toApiValue(_selectedContractType),
        'work_time': _toApiValue(_selectedWorkTime),
        if (salary != null) 'salary': salary,
        'availability': availability,
        if (_selectedAdvantages.isNotEmpty) 'advantages': _toApiValues(_selectedAdvantages),
        'telework_possible': _teleworkPossible,
        'location': {
          'country': 'FR',
          if (_selectedLocation?.address != null && _selectedLocation!.address.isNotEmpty) 'city': _selectedLocation!.address,
          if (_selectedLocation?.latitude != null) 'lat': _selectedLocation!.latitude,
          if (_selectedLocation?.longitude != null) 'lng': _selectedLocation!.longitude,
          if (_selectedLocation?.city != null) 'location_city': _selectedLocation!.city,
          if (_selectedLocation?.postalCode != null) 'location_postal_code': _selectedLocation!.postalCode,
          'nationwide': _nationwide,
          'show_google_map': _showGoogleMap,
        },
        'company': {
          'name': _companyNameController.text,
          if (_companyWebsiteController.text.isNotEmpty) 'website': _companyWebsiteController.text,
          'show_company_profile': _showCompanyProfile,
        },
        'profile': {
          'education_level': _toApiValue(_selectedEducationLevel),
          'experience_level': _toApiValue(_selectedExperienceLevel),
          if (_profileDescQuillController.document.toPlainText().trim().isNotEmpty)
            'description': _profileDescQuillController.document.toPlainText().trim(),
          if (_profileDescQuillController.document.toPlainText().trim().isNotEmpty)
            'description_delta': _profileDescQuillController.document.toDelta().toJson(),
        },
        'accept_messages': _acceptMessages,
      };

      debugPrint('Submitting job offer (${_isEditMode ? 'edit' : 'create'})...');
      final response = _isEditMode
          ? await ApiClient().authenticatedPut('/job-offers/${widget.jobOfferId}', body: body)
          : await ApiClient().authenticatedPost('/job-offers', body: body);
      debugPrint('Job offer ${_isEditMode ? 'updated' : 'created'} response: $response');
      
      // Upload media after job offer is created/updated (if endpoint exists)
      if (_selectedMediaFiles.isNotEmpty) {
        final jobOfferId = _isEditMode
            ? widget.jobOfferId
            : (response['data']?['id'] ?? response['id'] ?? response['job_offer']?['id'])?.toString();
        debugPrint('Job offer ID for media upload: $jobOfferId');
        if (jobOfferId != null) {
          // Try to upload media, but don't fail if endpoint doesn't exist
          try {
            await _uploadMediaFilesToJobOffer(jobOfferId.toString());
          } catch (e) {
            debugPrint('Media upload skipped: $e');
          }
        }
      }

      if (!mounted) return;
      
      // Clear saved progress after successful submission
      await _clearSavedProgress();
      
      // Get job offer ID for My's awarding
      final jobOfferId = _isEditMode
          ? widget.jobOfferId
          : (response['data']?['id'] ?? response['id'] ?? response['job_offer']?['id'])?.toString();
      
      _showSuccessDialog();

      // Award My's for creating a job offer (only on create, not edit)
      if (!_isEditMode && jobOfferId != null) {
        try {
          final mysResponse = await MysEarningService().awardMys(
            actionType: 'job_offer',
            referenceId: jobOfferId,
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
                  actionType: 'job_offer',
                );
              }
            });
          }
        } catch (e) {
          debugPrint("Error awarding My's for job offer: $e");
          // Don't block the user if awarding fails
        }
      }
    } on ApiException catch (e) {
      debugPrint('ApiException submitting job offer: ${e.message}');
      debugPrint('Validation errors: ${e.errors}');
      _showSnack(e.firstError, isError: true);
    } catch (e) {
      debugPrint('Error submitting job offer: $e');
      _showSnack('Erreur lors de la création de l\'offre: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validateForm() {
    if (_selectedCategoryId == null) {
      _showSnack('Veuillez sélectionner une catégorie', isError: true);
      return false;
    }
    if (_selectedFunctionId == null) {
      _showSnack('Veuillez sélectionner une fonction', isError: true);
      return false;
    }
    if (_titleController.text.isEmpty) {
      _showSnack('Veuillez saisir un intitulé de poste', isError: true);
      return false;
    }
    if (_descriptionQuillController.document.toPlainText().trim().isEmpty) {
      _showSnack('Veuillez saisir une description', isError: true);
      return false;
    }
    if (_selectedContractType == null) {
      _showSnack('Veuillez sélectionner un type de contrat', isError: true);
      return false;
    }
    if (_selectedWorkTime == null) {
      _showSnack('Veuillez sélectionner un temps de travail', isError: true);
      return false;
    }
    if (_companyNameController.text.isEmpty) {
      _showSnack('Veuillez saisir le nom de l\'entreprise', isError: true);
      return false;
    }
    if (_selectedEducationLevel == null) {
      _showSnack('Veuillez sélectionner un niveau d\'études', isError: true);
      return false;
    }
    if (_selectedExperienceLevel == null) {
      _showSnack('Veuillez sélectionner un niveau d\'expérience', isError: true);
      return false;
    }
    return true;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF3AAE5E),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                    if (_isEditMode) {
                      Navigator.pop(context); // pop detail screen back to listing
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
                _isEditMode ? 'Offre d\'emploi modifiée' : 'Offre d\'emploi publiée',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3AAE5E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vous pouvez consulter cela au niveau de votre espace ',
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
                    _isEditMode ? 'Modifier l\'offre d\'emploi' : 'Créer une offre d\'emploi',
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
                    ? 'Modifiez votre offre d\'emploi'
                    : 'Publiez votre offre et trouvez les meilleurs talents',
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
    // Show loading state
    if (_isMetaLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
      );
    }

    // Show error state with retry
    if (_metaError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_metaError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMetadata,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentStep) {
      case 0:
        return _buildStep1Informations();
      case 1:
        return _buildStep2Lien();
      case 2:
        return _buildStep3Description();
      case 3:
        return _buildStep4Profil();
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
                'Ajoutez des photos de votre entreprise ou de l’équipe pour donner un aperçu concret aux candidats.',
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
            itemCount: _existingMediaUrls.length + _selectedMediaFiles.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddPhotoButton();
              }
              final existingCount = _existingMediaUrls.length;
              if (index <= existingCount) {
                return _buildExistingPhotoCard(_existingMediaUrls[index - 1], index - 1);
              }
              final newIndex = index - 1 - existingCount;
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
      onTap: _pickMedia,
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
              'Ajouter ${_selectedMediaFiles.isEmpty ? "17" : "des"} photos',
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

  Widget _buildExistingPhotoCard(String url, int index) {
    final isVideo = url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov');
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
              child: isVideo
                  ? Container(
                      color: Colors.black87,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white),
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          if (index == 0 && _selectedMediaFiles.isEmpty)
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
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                child: const Icon(Icons.close, size: 18, color: Color(0xFF666666)),
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
    final isVideo = ['mp4', 'mov'].contains(extension);

    if (isImage && file.bytes != null) {
      return Image.memory(
        file.bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
  Widget _buildStep1Informations() {
    final categoryNames = _categoriesFromApi.map((c) => c['name'].toString()).toList();
    final functionNames = _functionsForCategory.map((f) => f['name'].toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.card_giftcard,
          title: 'Catégorie',
          children: [
            if (categoryNames.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Chargement des catégories...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              )
            else
              _buildDropdownField(
                label: 'Choisissez la catégorie*',
                value: _selectedCategoryName,
                items: categoryNames,
                onChanged: (val) {
                  if (val == null) return;
                  final category = _categoriesFromApi.firstWhere(
                    (c) => c['name'] == val,
                    orElse: () => <String, dynamic>{},
                  );
                  if (category.isNotEmpty) {
                    _updateFunctionsForCategory(category['id'] as int?);
                  }
                },
                hint: _buildRequiredHint('Choisissez une catégorie'),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
            const SizedBox(height: 16),
            if (_selectedCategoryId != null && functionNames.isNotEmpty)
              _buildDropdownField(
                label: 'Choisissez une fonction*',
                value: _selectedFunctionName,
                items: functionNames,
                onChanged: (val) {
                  if (val == null) return;
                  final func = _functionsForCategory.firstWhere(
                    (f) => f['name'] == val,
                    orElse: () => <String, dynamic>{},
                  );
                  if (func.isNotEmpty) {
                    setState(() {
                      _selectedFunctionId = func['id'] as int?;
                      _selectedFunctionName = val;
                    });
                  }
                },
                hint: _buildRequiredHint('Choisissez une fonction'),
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
              "Collez le lien de la page de l'offre d'emploi. Nous l'utiliserons pour récupérer automatiquement les informations et pré-remplir votre annonce.",
          children: [
            _buildTextField(
              label: 'Ajouter un lien',
              controller: _linkController,
              fieldKey: 'link',
              helperText: 'Le lien permettra d\'extraire automatiquement le titre, la description, le salaire, le type de contrat et autres détails de l\'offre pour faciliter la création de votre annonce.',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.description_outlined,
          title: 'Description',
          children: [
            _buildTextField(
              label: 'Intitulé du poste*',
              controller: _titleController,
              fieldKey: 'title',
              helperText: 'Saisissez un titre clair et précis pour le poste (ex: "Développeur Full Stack Senior").',
            ),
            const SizedBox(height: 12),
            _buildRichTextEditor(
              label: 'Description du poste*',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail les missions, responsabilités et environnement de travail. Utilisez les outils de mise en forme.',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Décrivez le poste, les missions et l\'environnement de travail.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Type de contrat*',
              value: _selectedContractType,
              items: _contractTypes.isNotEmpty ? _contractTypes : ['CDI', 'CDD', 'FREELANCE', 'INTERIM', 'STAGE', 'ALTERNANCE', 'VOLUNTEER'],
              onChanged: (val) => setState(() => _selectedContractType = val),
              hint: _buildRequiredHint('Type de contrat'),
              backgroundColor: const Color(0xFFF9FAFB),
              labelType: 'contract_types',
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Temps de travail*',
              value: _selectedWorkTime,
              items: _workTimes.isNotEmpty ? _workTimes : ['FULL_TIME', 'PART_TIME'],
              onChanged: (val) => setState(() => _selectedWorkTime = val),
              hint: _buildRequiredHint('Temps de travail'),
              backgroundColor: const Color(0xFFF9FAFB),
              labelType: 'work_times',
            ),
            const SizedBox(height: 12),
            _buildRadioGroup<String>(
              title: "Comment souhaitez-vous indiquer la rémunération ?",
              values: const ['RANGE', 'EXACT', 'DEPENDING_ON_PROFILE'],
              selectedValue: _selectedSalaryType,
              labelBuilder: (value) {
                switch (value) {
                  case 'RANGE': return 'Tranche salariale';
                  case 'EXACT': return 'Salaire exact';
                  case 'DEPENDING_ON_PROFILE': return 'Salaire selon le profil';
                  default: return value;
                }
              },
              onChanged: (value) => setState(() => _selectedSalaryType = value),
            ),
            const SizedBox(height: 4),
            if (_selectedSalaryType == 'RANGE') ...[
              _buildTextField(
                label: 'Salaire minimum (€)',
                controller: _salaryMinController,
                keyboardType: TextInputType.number,
                suffix: '€',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                label: 'Salaire maximum (€)',
                controller: _salaryMaxController,
                keyboardType: TextInputType.number,
                suffix: '€',
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedSalaryType == 'EXACT') ...[
              _buildTextField(
                label: 'Salaire exact (€)',
                controller: _salaryExactController,
                keyboardType: TextInputType.number,
                suffix: '€',
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedSalaryType != null && _selectedSalaryType != 'DEPENDING_ON_PROFILE') ...[
              _buildDropdownField(
                label: 'Type de salaire',
                value: _isSalaryGross ? 'Brut' : 'Net',
                items: const ['Brut', 'Net'],
                onChanged: (val) => setState(() => _isSalaryGross = val == 'Brut'),
                hint: const Text('Type de salaire', style: TextStyle(fontSize: 13, color: Colors.grey)),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Indice temporel',
                value: _selectedSalaryPeriod,
                items: _salaryPeriods.isNotEmpty ? _salaryPeriods : ['YEAR', 'MONTH', 'DAY', 'HOUR'],
                onChanged: (val) => setState(() => _selectedSalaryPeriod = val),
                hint: const Text('Indice temporel', style: TextStyle(fontSize: 13, color: Colors.grey)),
                backgroundColor: const Color(0xFFF9FAFB),
                labelType: 'salary_periods',
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            _buildRadioGroup<String>(
              title: "Offre à pourvoir :",
              values: const ['IMMEDIATE', 'FROM_DATE'],
              selectedValue: _selectedAvailabilityType,
              labelBuilder: (value) => value == 'IMMEDIATE' ? 'Immédiatement' : 'À partir de',
              onChanged: (value) => setState(() => _selectedAvailabilityType = value),
            ),
            const SizedBox(height: 4),
            if (_selectedAvailabilityType == 'FROM_DATE') ...[
              _buildDateField(
                title: "Date de début",
                selectedDate: _availableFromDate,
                onDateSelected: (date) => setState(() => _availableFromDate = date),
              ),
              const SizedBox(height: 12),
            ],
            _buildDateField(
              title: "Jusqu'au (optionnel)",
              selectedDate: _availableUntilDate,
              onDateSelected: (date) => setState(() => _availableUntilDate = date),
            ),
            const SizedBox(height: 16),
            _buildCheckboxGroup(
              title: "Avantages :",
              options: _advantagesFromApi.isNotEmpty ? _advantagesFromApi : [
                "TRANSPORT", "MEAL_VOUCHERS", "RTT", "REMOTE_WORK",
                "COMPANY_CAR", "SAVINGS_PLAN", "FLEXIBLE_HOURS", "TIPS", "COMMISSIONS"
              ],
              selectedValues: _selectedAdvantages,
              onChanged: (updatedList) => setState(() => _selectedAdvantages = updatedList),
            ),
            const SizedBox(height: 16),
            _buildCheckOption(
              'Télétravail possible',
              _teleworkPossible,
              () => setState(() => _teleworkPossible = !_teleworkPossible),
            ),
            const SizedBox(height: 16),
            AbsorbPointer(
              absorbing: _nationwide,
              child: Opacity(
                opacity: _nationwide ? 0.5 : 1.0,
                child: LocationPickerField(
                  initialLocation: _selectedLocation,
                  label: 'Précisez la ville/région où cette offre est valide',
                  helperText: 'Recherchez une ville, région ou adresse',
                  onLocationSelected: (location) {
                    setState(() {
                      _selectedLocation = location;
                      if (location != null && _nationwide) {
                        _nationwide = false;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCheckOption(
              'Toute la France',
              _nationwide,
              _selectedLocation?.address == null || _selectedLocation!.address.isEmpty
                  ? () {
                      setState(() {
                        _nationwide = !_nationwide;
                        if (_nationwide) {
                          _selectedLocation = null;
                        }
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            _buildCheckOption(
              'Afficher localisation Google sur l\'annonce',
              _showGoogleMap,
              () => setState(() => _showGoogleMap = !_showGoogleMap),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Nom de l\'entreprise*',
              controller: _companyNameController,
              fieldKey: 'company_name',
              helperText: 'Saisissez le nom officiel de votre entreprise.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB3D9F2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _showCompanyProfile,
                    onChanged: (val) => setState(() => _showCompanyProfile = val ?? false),
                    activeColor: const Color(0xFF3AAE5E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Afficher la présentation de mon entreprise (Qui sommes-nous ?) sur mon annonce depuis mon profil entreprise',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cette option affichera automatiquement la description de votre entreprise configurée dans votre tableau de bord',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Site web de l\'entreprise',
              controller: _companyWebsiteController,
              fieldKey: 'company_website',
              helperText: 'Ajoutez l\'URL du site web de votre entreprise.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 4: Profil───
  Widget _buildStep4Profil() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.person,
          title: 'Profil',
          children: [
            _buildDropdownField(
              label: 'Niveau d\'études requis*',
              value: _selectedEducationLevel,
              items: _educationLevels.isNotEmpty ? _educationLevels : [
                'NONE', 'CAP', 'BAC', 'BAC_2', 'BAC_3', 'MASTER', 'DOCTORATE'
              ],
              onChanged: (val) => setState(() => _selectedEducationLevel = val),
              hint: _buildRequiredHint('Niveau d\'études requis'),
              backgroundColor: const Color(0xFFF9FAFB),
              labelType: 'education_levels',
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Niveau d\'expérience requis*',
              value: _selectedExperienceLevel,
              items: _experienceLevels.isNotEmpty ? _experienceLevels : [
                'JUNIOR', '1_3_YEARS', '3_5_YEARS', '5_10_YEARS', 'EXPERT'
              ],
              onChanged: (val) => setState(() => _selectedExperienceLevel = val),
              hint: _buildRequiredHint('Niveau d\'expérience requis'),
              backgroundColor: const Color(0xFFF9FAFB),
              labelType: 'experience_levels',
            ),
            const SizedBox(height: 12),
            _buildRichTextEditor(
              label: 'Description du profil recherché',
              controller: _profileDescQuillController,
              fieldKey: 'profile_description',
              helperText: 'Décrivez les compétences, qualités et expériences recherchées pour ce poste.',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Décrivez le profil idéal pour ce poste: compétences techniques, qualités humaines, expériences spécifiques',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
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

  // ─── STEP 5: Review ───
  Widget _buildStep5Review() {
    String salaryDisplay = '-';
    if (_selectedSalaryType == 'RANGE' && _salaryMinController.text.isNotEmpty) {
      salaryDisplay = '${_salaryMinController.text} - ${_salaryMaxController.text} €';
    } else if (_selectedSalaryType == 'EXACT' && _salaryExactController.text.isNotEmpty) {
      salaryDisplay = '${_salaryExactController.text} €';
    } else if (_selectedSalaryType == 'DEPENDING_ON_PROFILE') {
      salaryDisplay = 'Selon profil';
    }

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
            _isEditMode ? 'Vérifiez vos modifications' : 'Vérifiez votre offre',
            style: const TextStyle(
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
                : 'Relisez les informations avant de publier votre offre d\'emploi',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Step 1: Informations générales
        _buildReviewSection(
          title: 'Étape 1 - Informations générales',
          onEdit: () => setState(() => _currentStep = 0),
          rows: [
            _buildReviewRow('Catégorie', _selectedCategoryName ?? '-'),
            _buildReviewRow('Fonction', _selectedFunctionName ?? '-'),
          ],
        ),
        const SizedBox(height: 16),

        // Step 2: Lien
        _buildReviewSection(
          title: 'Étape 2 - Lien',
          onEdit: () => setState(() => _currentStep = 1),
          rows: [
            _buildReviewRow(
              'Lien externe',
              _linkController.text.isEmpty ? 'Aucun lien' : _linkController.text,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 3: Description et détails
        _buildReviewSection(
          title: 'Étape 3 - Description et détails',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow('Titre', _titleController.text.isEmpty ? '-' : _titleController.text),
            _buildReviewRow('Description', _descriptionQuillController.document.toPlainText().trim().isEmpty ? '-' : _descriptionQuillController.document.toPlainText().trim()),
            _buildReviewRow('Type de contrat', _selectedContractType ?? '-'),
            _buildReviewRow('Temps de travail', _selectedWorkTime ?? '-'),
            _buildReviewRow('Type de rémunération', _selectedSalaryType ?? '-'),
            _buildReviewRow('Rémunération', salaryDisplay),
            if (_selectedSalaryType != null && _selectedSalaryType != 'DEPENDING_ON_PROFILE') ...[
              _buildReviewRow('Type de salaire', _isSalaryGross ? 'Brut' : 'Net'),
              _buildReviewRow('Indice temporel', _selectedSalaryPeriod ?? '-'),
            ],
            _buildReviewRow(
              'Disponibilité',
              _selectedAvailabilityType == 'IMMEDIATE'
                  ? 'Immédiatement'
                  : _selectedAvailabilityType == 'FROM_DATE' && _availableFromDate != null
                      ? 'À partir de ${_availableFromDate?.toString().split(' ')[0]}'
                      : '-',
            ),
            _buildReviewRow('Avantages', _selectedAdvantages.isEmpty ? '-' : _selectedAdvantages.join(', ')),
            _buildReviewRow('Télétravail possible', _teleworkPossible ? 'Oui' : 'Non'),
            _buildReviewRow('Localisation', _selectedLocation?.address ?? '-'),
            _buildReviewRow('Toute la France', _nationwide ? 'Oui' : 'Non'),
            _buildReviewRow('Afficher localisation Google', _showGoogleMap ? 'Oui' : 'Non'),
            _buildReviewRow('Nom de l\'entreprise', _companyNameController.text.isEmpty ? '-' : _companyNameController.text),
            _buildReviewRow('Afficher présentation entreprise', _showCompanyProfile ? 'Oui' : 'Non'),
            _buildReviewRow('Site web de l\'entreprise', _companyWebsiteController.text.isEmpty ? '-' : _companyWebsiteController.text),
          ],
        ),
        const SizedBox(height: 16),

        // Step 4: Profil recherché
        _buildReviewSection(
          title: 'Étape 4 - Profil recherché',
          onEdit: () => setState(() => _currentStep = 3),
          rows: [
            _buildReviewRow('Niveau d\'études', _selectedEducationLevel ?? '-'),
            _buildReviewRow('Expérience', _selectedExperienceLevel ?? '-'),
            _buildReviewRow('Description du profil', _profileDescQuillController.document.toPlainText().trim().isEmpty ? '-' : _profileDescQuillController.document.toPlainText().trim()),
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
              () {
                final total = _existingMediaUrls.length + _selectedMediaFiles.length;
                if (total == 0) return 'Aucun média sélectionné';
                final parts = <String>[];
                if (_existingMediaUrls.isNotEmpty) parts.add('${_existingMediaUrls.length} existant(s)');
                if (_selectedMediaFiles.isNotEmpty) parts.add('${_selectedMediaFiles.length} nouveau(x)');
                return '$total fichier(s) (${parts.join(' + ')})';
              }(),
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
                'Accepter de recevoir des messages à propos de cette offre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les candidats pourront vous contacter pour en savoir plus sur le poste, le processus de recrutement ou les conditions proposées.',
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
            onPressed: _isSubmitting ? null : _submitJobOffer,
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
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    _isEditMode ? 'Sauvegarder les modifications' : 'Publier l\'offre d\'emploi',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildUploadButton({required String label, required Color color, VoidCallback? onTap}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icône upload dans un cercle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(Icons.cloud_upload_outlined, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          // Texte principal
          const Text(
            'Glissez-déposez vos fichiers ici',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 6),
          Text('ou', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 12),
          // Bouton parcourir
          InkWell(
            onTap: onTap ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label - Fonctionnalité bientôt disponible'),
                  backgroundColor: color,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Formats acceptés
          Text(
            'Images (JPG, PNG, GIF) et vidéos (MP4, MOV) acceptées',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxGroup({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manjari',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);

              return Theme(
                data: ThemeData(
                  visualDensity: const VisualDensity(vertical: -4),
                ),
                child: CheckboxListTile(
                  side: const BorderSide(color: Colors.grey, width: 1),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option, style: const TextStyle(fontSize: 14)),
                  value: isSelected,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? value) {
                    List<String> updatedList = List.from(selectedValues);

                    if (value == true) {
                      updatedList.add(option);
                    } else {
                      updatedList.remove(option);
                    }

                    onChanged(updatedList);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

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
                  color: Colors.lightBlueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.lightBlueAccent, size: 20),
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
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    Widget? hint,
    Color? backgroundColor,
    String? labelType, // For display label mapping
  }) {
    // Ensure value is in items list, otherwise set to null
    final validValue = (value != null && items.contains(value)) ? value : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<String>(
        value: validValue,
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
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  labelType != null ? _getDisplayLabel(item, labelType) : item,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: items.isNotEmpty ? onChanged : null,
      ),
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

  Widget _buildCheckOption(String label, bool isSelected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap ?? () {},
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
