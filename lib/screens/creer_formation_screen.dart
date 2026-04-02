import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/training_service.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class _TrainingMediaFile {
  final String? id;
  final String url;
  final String? type;

  const _TrainingMediaFile({
    this.id,
    required this.url,
    this.type,
  });
}

class _TrainingDocumentFile {
  final String? id;
  final String url;
  final String? fileName;
  final String? fileType;

  const _TrainingDocumentFile({
    required this.url,
    this.id,
    this.fileName,
    this.fileType,
  });
}

class CreerFormationScreen extends StatefulWidget {
  final String? trainingId;
  final Map<String, dynamic>? initialData;
  final bool shouldReturnToListingOnSuccess;

  const CreerFormationScreen({
    super.key,
    this.trainingId,
    this.initialData,
    this.shouldReturnToListingOnSuccess = false,
  });

  @override
  State<CreerFormationScreen> createState() => _CreerFormationScreenState();
}

class _CreerFormationScreenState extends State<CreerFormationScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _focusedField;

  final TrainingService _trainingService = TrainingService();

  // Categories from API
  List<Map<String, dynamic>> _categoriesFromApi = [];
  List<Map<String, dynamic>> _subCategoriesForCategory = [];
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedSubCategoryId;
  String? _selectedSubCategoryName;

  // Metadata from API
  Map<String, dynamic> _metadata = {};
  Map<String, String> _trainingTypesMap = {};
  List<String> _trainingTypes = [];
  List<String> _requiredLevels = [];
  List<String> _certifications = [];
  Map<String, String> _priceTypes = {};
  Map<String, String> _publicTypes = {};
  Map<String, String> _tempoTypes = {};
  Map<String, String> _durationUnits = {};

  // Step 1 - Type & Category
  String? _selectedTrainingType;

  // Step 2 - Link (optional)
  final TextEditingController _linkController = TextEditingController();

  // Step 3 - Description & Details
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionQuillController = QuillController.basic();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _addressCityController = TextEditingController();
  final TextEditingController _addressZipcodeController = TextEditingController();

  List<String> _selectedTeachingStyles = [];
  List<String> _selectedTargetPublics = [];
  List<String> _selectedRequiredLevels = [];
  List<String> _selectedFunding = [];
  List<String> _selectedCertifications = [];

  // Custom values for Niveau requis and Certifications
  final TextEditingController _customLevelController = TextEditingController();
  final TextEditingController _customCertificationController = TextEditingController();
  List<String> _customRequiredLevels = [];
  List<String> _customCertifications = [];

  String? _selectedPriceType;
  String? _selectedPublicType;
  String? _selectedTempo;
  String? _selectedDurationUnit;

  bool _dateToDefine = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showLocation = true;
  bool _acceptMessages = true;

  // Step 4 - Media & Documents
  List<PlatformFile> _selectedMediaFiles = [];
  List<PlatformFile> _selectedDocumentFiles = [];
  List<_TrainingMediaFile> _existingMedia = [];
  List<_TrainingDocumentFile> _existingDocuments = [];
  final Set<String> _deletingMediaKeys = {};
  final Set<String> _deletingDocumentKeys = {};

  bool get _isEditMode => widget.trainingId != null && widget.trainingId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadCategories();
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
    _linkController.dispose();
    _websiteController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _addressCityController.dispose();
    _addressZipcodeController.dispose();
    _customLevelController.dispose();
    _customCertificationController.dispose();
    super.dispose();
  }

  void _prefillFromInitialData(Map<String, dynamic> data) {
    debugPrint('Prefilling training form with data keys: ${data.keys.toList()}');

    setState(() {
      _titleController.text = data['title']?.toString() ?? '';
      _websiteController.text = data['website']?.toString() ?? '';
      _linkController.text = data['link']?.toString() ?? '';

      // Training type
      _selectedTrainingType = data['training_type']?.toString();

      // Category & SubCategory - will be matched after categories load
      _selectedCategoryName = data['training_category']?.toString();
      _selectedSubCategoryName = data['training_sub_category']?.toString();

      // Multi-select fields
      _selectedTeachingStyles = List<String>.from(data['training_style'] ?? []);
      _selectedTargetPublics = List<String>.from(data['training_public'] ?? []);
      _selectedRequiredLevels = List<String>.from(data['required_levels'] ?? []);
      _selectedFunding = List<String>.from(data['training_funding'] ?? []);
      _selectedCertifications = List<String>.from(data['certification'] ?? []);

      // Price
      final price = data['price'];
      if (price != null) {
        _priceController.text = price.toString().replaceAll(RegExp(r'\.00$'), '');
      }
      _selectedPriceType = data['price_type']?.toString();
      _selectedPublicType = data['public_type']?.toString();
      _selectedTempo = data['tempo']?.toString();

      // Duration
      final duration = data['duration_in_h'];
      if (duration != null) {
        _durationController.text = duration.toString();
      }
      _selectedDurationUnit = data['duration_unit']?.toString();

      // Dates
      _dateToDefine = data['date_to_define'] == true;
      if (data['start_date'] != null) {
        try { _startDate = DateTime.parse(data['start_date'].toString()); } catch (_) {}
      }
      if (data['end_date'] != null) {
        try { _endDate = DateTime.parse(data['end_date'].toString()); } catch (_) {}
      }

      // Location
      _addressLine1Controller.text = data['address_line1']?.toString() ?? '';
      _addressLine2Controller.text = data['address_line2']?.toString() ?? '';
      _addressCityController.text = data['address_city']?.toString() ?? '';
      _addressZipcodeController.text = data['address_zipcode']?.toString() ?? '';
      _showLocation = data['show_location'] != false;
      _acceptMessages = data['accept_messages'] != false;

      // Existing media
      final mediaFiles = data['media_files'] as List? ?? [];
      _existingMedia = mediaFiles
          .whereType<Map>()
          .map<_TrainingMediaFile?>(
            (m) {
              final resolvedUrl = _buildMediaUrl(m['url']?.toString());
              if (resolvedUrl.isEmpty) return null;
              return _TrainingMediaFile(
                id: m['id']?.toString(),
                url: resolvedUrl,
                type: m['type']?.toString(),
              );
            },
          )
          .whereType<_TrainingMediaFile>()
          .toList();
      final docFiles = data['document_files'] as List? ?? [];
      _existingDocuments = docFiles
          .whereType<Map>()
          .where((d) => d['url'] != null)
          .map(
            (d) => _TrainingDocumentFile(
              id: d['id']?.toString(),
              url: d['url'].toString(),
              fileName: d['file_name']?.toString(),
              fileType: d['file_type']?.toString(),
            ),
          )
          .toList();
    });

    // Restore rich text description after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreDescription(data);
    });
  }

  void _restoreDescription(Map<String, dynamic> data) {
    final descDelta = data['description_delta'];
    debugPrint('TRAINING EDIT _restoreDescription: descDelta type=${descDelta?.runtimeType}');
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
        debugPrint('Error restoring training description delta: $e');
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

  Future<void> _loadMetadata() async {
    try {
      final data = await _trainingService.getMetadata();
      final normalizedData = Map<String, dynamic>.from(data);
      final trainingTypesMap = _normalizeStringMap(normalizedData['training_types']);
      final teachingTypesMap = _normalizeStringMap(normalizedData['teaching_types']);
      final targetPublicsMap = _normalizeStringMap(normalizedData['target_publics']);
      final fundingOptionsMap = _normalizeStringMap(normalizedData['funding_options']);
      final priceTypesMap = _normalizeStringMap(normalizedData['price_types']);
      final publicTypesMap = _normalizeStringMap(normalizedData['public_types']);
      final tempoTypesMap = _normalizeStringMap(normalizedData['tempo_types']);
      final durationUnitsMap = _normalizeStringMap(normalizedData['duration_units']);

      normalizedData['training_types'] = trainingTypesMap;
      normalizedData['teaching_types'] = teachingTypesMap;
      normalizedData['target_publics'] = targetPublicsMap;
      normalizedData['funding_options'] = fundingOptionsMap;
      normalizedData['price_types'] = priceTypesMap;
      normalizedData['public_types'] = publicTypesMap;
      normalizedData['tempo_types'] = tempoTypesMap;
      normalizedData['duration_units'] = durationUnitsMap;

      // Service already unwraps the response, so data is the actual metadata
      setState(() {
        _metadata = normalizedData;
        _trainingTypesMap = trainingTypesMap;
        _trainingTypes = _trainingTypesMap.keys.toList();
        _requiredLevels = List<String>.from(data['required_levels'] ?? []);
        _certifications = List<String>.from(data['certifications'] ?? []);
        _priceTypes = priceTypesMap;
        _publicTypes = publicTypesMap;
        _tempoTypes = tempoTypesMap;
        _durationUnits = durationUnitsMap;
      });
      debugPrint('Loaded duration units: $_durationUnits');
    } catch (e) {
      debugPrint('Error loading metadata: $e');
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _trainingService.getCategories();
      setState(() {
        _categoriesFromApi = categories;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateSubCategoriesForCategory(int? categoryId) {
    if (categoryId == null) {
      setState(() {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
        _subCategoriesForCategory = [];
        _selectedSubCategoryId = null;
        _selectedSubCategoryName = null;
      });
      return;
    }

    final category = _categoriesFromApi.firstWhere(
      (c) => c['id'] == categoryId,
      orElse: () => <String, dynamic>{},
    );

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = category['name']?.toString();
      _subCategoriesForCategory = category['subcategories'] != null
          ? List<Map<String, dynamic>>.from(category['subcategories'])
          : [];
      _selectedSubCategoryId = null;
      _selectedSubCategoryName = null;
    });
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formData = {
        'step': _currentStep,
        'title': _titleController.text,
        'description_delta': jsonEncode(_descriptionQuillController.document.toDelta().toJson()),
        'category_id': _selectedCategoryId,
        'subcategory_id': _selectedSubCategoryId,
        'training_type': _selectedTrainingType,
        'teaching_styles': _selectedTeachingStyles,
        'target_publics': _selectedTargetPublics,
        'required_levels': _selectedRequiredLevels,
        'funding': _selectedFunding,
        'certifications': _selectedCertifications,
        'price': _priceController.text,
        'price_type': _selectedPriceType,
        'public_type': _selectedPublicType,
        'tempo': _selectedTempo,
        'duration': _durationController.text,
        'duration_unit': _selectedDurationUnit,
        'website': _websiteController.text,
        'link': _linkController.text,
        'date_to_define': _dateToDefine,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'address_line1': _addressLine1Controller.text,
        'address_line2': _addressLine2Controller.text,
        'address_city': _addressCityController.text,
        'address_zipcode': _addressZipcodeController.text,
        'show_location': _showLocation,
        'accept_messages': _acceptMessages,
      };
      await prefs.setString('training_draft', jsonEncode(formData));
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  Future<void> _checkForSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('training_draft');

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
          'Vous avez un formulaire de formation non terminé. Voulez-vous continuer où vous vous êtes arrêté ?',
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
      await _loadDraft();
    } else {
      await _clearDraft();
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
      await _saveDraft();
      if (mounted) Navigator.pop(context);
    } else if (result == 'discard') {
      await _clearDraft();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString('training_draft');
      if (draftJson != null) {
        final formData = jsonDecode(draftJson);
        setState(() {
          _currentStep = formData['step'] ?? 0;
          _titleController.text = formData['title'] ?? '';
          _selectedCategoryId = formData['category_id'];
          _selectedSubCategoryId = formData['subcategory_id'];
          _selectedTrainingType = formData['training_type'];
          _selectedTeachingStyles = List<String>.from(formData['teaching_styles'] ?? []);
          _selectedTargetPublics = List<String>.from(formData['target_publics'] ?? []);
          _selectedRequiredLevels = List<String>.from(formData['required_levels'] ?? []);
          _selectedFunding = List<String>.from(formData['funding'] ?? []);
          _selectedCertifications = List<String>.from(formData['certifications'] ?? []);
          _priceController.text = formData['price'] ?? '';
          _selectedPriceType = formData['price_type'];
          _selectedPublicType = formData['public_type'];
          _selectedTempo = formData['tempo'];
          _durationController.text = formData['duration'] ?? '';
          _selectedDurationUnit = formData['duration_unit'];
          _websiteController.text = formData['website'] ?? '';
          _linkController.text = formData['link'] ?? '';
          _dateToDefine = formData['date_to_define'] ?? false;
          _addressLine1Controller.text = formData['address_line1'] ?? '';
          _addressLine2Controller.text = formData['address_line2'] ?? '';
          _addressCityController.text = formData['address_city'] ?? '';
          _addressZipcodeController.text = formData['address_zipcode'] ?? '';
          _showLocation = formData['show_location'] ?? true;
          _acceptMessages = formData['accept_messages'] ?? true;
        });

        if (formData['description_delta'] != null) {
          try {
            final delta = jsonDecode(formData['description_delta']);
            _descriptionQuillController.document = Document.fromJson(delta);
          } catch (e) {
            debugPrint('Error restoring description: $e');
          }
        }

        if (formData['start_date'] != null) {
          _startDate = DateTime.parse(formData['start_date']);
        }
        if (formData['end_date'] != null) {
          _endDate = DateTime.parse(formData['end_date']);
        }
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('training_draft');
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  bool _isPriceAmountRequired(String? priceTypeKey) {
    if (priceTypeKey == null) return true;
    final label = _priceTypes[priceTypeKey]?.toString().toLowerCase();
    if (label == null) return true;
    if (label.contains('gratuit')) return false;
    if (label.contains('devis')) return false;
    return true;
  }

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        final validFiles = result.files.where((file) {
          final extension = file.extension?.toLowerCase();
          return ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'].contains(extension);
        }).toList();

        setState(() {
          _selectedMediaFiles.addAll(validFiles);
        });
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
    });
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedDocumentFiles.addAll(result.files);
        });
      }
    } catch (e) {
      debugPrint('Error picking documents: $e');
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _selectedDocumentFiles.removeAt(index);
    });
  }

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }
    _saveDraft();
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
      case 0: // Step 1: Type
        if (_selectedTrainingType == null) {
          return 'Veuillez sélectionner un type de formation.';
        }
        break;
      
      case 1: // Step 2: Lien France Travail (optional)
        break;
      
      case 2: // Step 3: Description
        return _validateStep3();
      
      case 3: // Step 4: Médias et documents (optional)
        break;
      
      case 4: // Step 5: Review (no validation needed)
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

  String? _validateStep3() {
    if (_titleController.text.trim().length < 5) {
      return 'Le titre doit contenir au moins 5 caractères.';
    }
    if (_descriptionQuillController.document.toPlainText().trim().length < 20) {
      return 'La description doit contenir au moins 20 caractères.';
    }
    if (_selectedTeachingStyles.isEmpty) {
      return 'Veuillez sélectionner au moins un type d\'enseignement.';
    }
    if (_selectedTargetPublics.isEmpty) {
      return 'Veuillez sélectionner au moins un public visé.';
    }
    if (_selectedRequiredLevels.isEmpty) {
      return 'Veuillez sélectionner au moins un niveau requis.';
    }
    if (_selectedFunding.isEmpty) {
      return 'Veuillez sélectionner au moins une option de financement.';
    }
    return null;
  }

  Future<void> _submitTraining() async {
    final validationError = _validateStep3();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) {
      setState(() => _isSubmitting = true);
    }

    try {
      final descriptionDelta = _descriptionQuillController.document.toDelta().toJson();
      final descriptionHtml = _descriptionQuillController.document.toPlainText();

      final trainingData = {
        'title': _titleController.text.trim(),
        'description': descriptionHtml,
        'description_delta': descriptionDelta,
        'training_type': _selectedTrainingType,
        'training_category': _selectedCategoryName,
        'training_sub_category': _selectedSubCategoryName,
        'training_style': _selectedTeachingStyles,
        'training_public': _selectedTargetPublics,
        'required_levels': _selectedRequiredLevels,
        'training_funding': _selectedFunding,
        'price_type': _selectedPriceType ?? '4',
        'accept_messages': _acceptMessages,
        'status': 'draft',
      };

      if (_websiteController.text.trim().isNotEmpty) {
        trainingData['website'] = _websiteController.text.trim();
      }

      if (_priceController.text.trim().isNotEmpty) {
        trainingData['price'] = double.tryParse(_priceController.text.trim());
      }

      if (_selectedPublicType != null) {
        trainingData['public_type'] = _selectedPublicType;
      }

      if (_selectedTempo != null) {
        trainingData['tempo'] = _selectedTempo;
      }

      if (_durationController.text.trim().isNotEmpty) {
        trainingData['duration_in_h'] = int.tryParse(_durationController.text.trim());
      }

      if (_selectedDurationUnit != null) {
        trainingData['duration_unit'] = _selectedDurationUnit;
      }

      trainingData['date_to_define'] = _dateToDefine;

      if (!_dateToDefine) {
        if (_startDate != null) {
          trainingData['start_date'] = _startDate!.toIso8601String().split('T')[0];
        }
        if (_endDate != null) {
          trainingData['end_date'] = _endDate!.toIso8601String().split('T')[0];
        }
      }

      if (_addressLine1Controller.text.trim().isNotEmpty) {
        trainingData['address_line1'] = _addressLine1Controller.text.trim();
      }
      if (_addressLine2Controller.text.trim().isNotEmpty) {
        trainingData['address_line2'] = _addressLine2Controller.text.trim();
      }
      if (_addressCityController.text.trim().isNotEmpty) {
        trainingData['address_city'] = _addressCityController.text.trim();
      }
      if (_addressZipcodeController.text.trim().isNotEmpty) {
        trainingData['address_zipcode'] = _addressZipcodeController.text.trim();
      }
      trainingData['address_country'] = 'FR';
      trainingData['show_location'] = _showLocation;

      if (_selectedCertifications.isNotEmpty) {
        trainingData['certification'] = _selectedCertifications;
      }

      debugPrint('Submitting training payload (${_isEditMode ? 'edit' : 'create'}): ${jsonEncode(trainingData)}');

      final Map<String, dynamic> response;
      if (_isEditMode) {
        response = await _trainingService.updateTraining(widget.trainingId!, trainingData);
      } else {
        response = await _trainingService.createTraining(trainingData);
      }

      if (response['success'] == true) {
        final trainingId = _isEditMode
            ? widget.trainingId
            : (response['data']?['id'])?.toString();

        if (trainingId != null) {
          if (_selectedMediaFiles.isNotEmpty) {
            try {
              final mediaFiles = _selectedMediaFiles
                  .where((f) => f.path != null)
                  .map((f) => File(f.path!))
                  .toList();
              if (mediaFiles.isNotEmpty) {
                await _trainingService.uploadMedia(trainingId, mediaFiles);
              }
            } catch (e) {
              debugPrint('Error uploading media: $e');
            }
          }

          if (_selectedDocumentFiles.isNotEmpty) {
            try {
              final docFiles = _selectedDocumentFiles
                  .where((f) => f.path != null)
                  .map((f) => File(f.path!))
                  .toList();
              if (docFiles.isNotEmpty) {
                await _trainingService.uploadDocuments(trainingId, docFiles);
              }
            } catch (e) {
              debugPrint('Error uploading documents: $e');
            }
          }
        }

        if (!_isEditMode) await _clearDraft();
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
        _showSuccessDialog();

        // Award My's for creating a formation (only on create, not edit)
        if (!_isEditMode) {
          try {
            final mysResponse = await MysEarningService().awardMys(
              actionType: 'formation',
              referenceId: trainingId,
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
                    actionType: 'formation',
                  );
                }
              });
            }
          } catch (e) {
            debugPrint("Error awarding My's for formation: $e");
            // Don't block the user if awarding fails
          }
        }
      } else {
        throw Exception(response['message'] ?? (_isEditMode ? 'Erreur lors de la mise à jour' : 'Erreur lors de la création'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    Navigator.pop(context);
                    Navigator.pop(context);
                    if (widget.shouldReturnToListingOnSuccess) {
                      Navigator.pop(context);
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
                _isEditMode ? 'Formation mise à jour' : 'Formation publié',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3AAE5E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isEditMode
                    ? 'Votre formation a été mise à jour avec succès'
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

  String _buildMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');

    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Force host to the current backend server in case the API returns localhost/old IPs
      return url.replaceFirst(RegExp(r'^https?://[^/]+'), serverBase);
    }

    if (url.startsWith('/')) {
      return '$serverBase$url';
    }

    return '$serverBase/$url';
  }

  Widget _buildExistingMediaCard(_TrainingMediaFile media) {
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
            child: SizedBox.expand(child: content),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: isDeleting ? null : () => _removeExistingMedia(media),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: isDeleting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red[300]),
                      )
                    : const Icon(
                        Icons.close,
                        size: 16,
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
    final ext = url.split('.').lastOrNull?.toLowerCase();
    final mime = type?.toLowerCase();
    return (ext != null && ['jpg', 'jpeg', 'png', 'gif'].contains(ext)) || (mime != null && mime.contains('image'));
  }

  bool _isVideoUrl(String url, String? type) {
    final ext = url.split('.').lastOrNull?.toLowerCase();
    final mime = type?.toLowerCase();
    return (ext != null && ['mp4', 'mov', 'avi'].contains(ext)) || (mime != null && mime.contains('video'));
  }

  Widget _buildBrokenMediaPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
      ),
    );
  }

  Future<void> _removeExistingMedia(_TrainingMediaFile media) async {
    final key = media.id ?? media.url;
    if (_deletingMediaKeys.contains(key)) return;

    if (mounted) {
      setState(() => _deletingMediaKeys.add(key));
    }

    try {
      if (_isEditMode && widget.trainingId != null && media.id != null) {
        await _trainingService.deleteMedia(widget.trainingId!, media.id!);
      }
      if (mounted) {
        setState(() {
          _existingMedia.removeWhere((m) => m.url == media.url && m.id == media.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression du média impossible: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingMediaKeys.remove(key));
      }
    }
  }

  Widget _buildExistingDocumentList({bool compact = false}) {
    if (_existingDocuments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _existingDocuments.map((doc) {
        final displayName = doc.fileName ?? doc.url.split('/').last;
        final key = doc.id ?? doc.url;
        final isDeleting = _deletingDocumentKeys.contains(key);

        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 8 : 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF3AAE5E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (doc.fileType != null)
                        Text(
                          doc.fileType!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _openDocumentUrl(doc.url),
                      child: const Text('Ouvrir'),
                    ),
                    if (isDeleting)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red[300]),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _removeExistingDocument(doc),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _removeExistingDocument(_TrainingDocumentFile doc) async {
    final key = doc.id ?? doc.url;
    if (_deletingDocumentKeys.contains(key)) return;

    if (mounted) {
      setState(() => _deletingDocumentKeys.add(key));
    }

    try {
      if (_isEditMode && widget.trainingId != null && doc.id != null) {
        await _trainingService.deleteDocument(widget.trainingId!, doc.id!);
      }

      if (mounted) {
        setState(() {
          _existingDocuments.removeWhere((d) => d.url == doc.url && d.id == doc.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression impossible: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _deletingDocumentKeys.remove(key));
      }
    }
  }

  Future<void> _openDocumentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir ce document')),
        );
      }
    }
  }

  Widget _buildDocumentList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _selectedDocumentFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final file = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: Color(0xFF3AAE5E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      file.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeDocument(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, String> _normalizeStringMap(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    if (raw is List) {
      final map = <String, String>{};
      for (final item in raw) {
        if (item is Map) {
          final keyCandidate = item['key'] ?? item['code'] ?? item['id'] ?? item['value'] ?? item['label'] ?? item['name'];
          final labelCandidate = item['label'] ?? item['name'] ?? item['value'] ?? item['code'] ?? keyCandidate;
          final key = keyCandidate?.toString();
          final label = labelCandidate?.toString();
          if (key != null && label != null) {
            map[key] = label;
          }
        } else if (item != null) {
          map[item.toString()] = item.toString();
        }
      }
      return map;
    }
    return {};
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
                    _isEditMode ? 'Modifier la formation' : 'Créer une formation',
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
                    ? 'Modifiez les informations de votre formation'
                    : 'Partagez une opportunité de formation avec la communauté',
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
        return _buildStep1Type();
      case 1:
        return _buildStep2FranceTravail();
      case 2:
        return _buildStep3Description();
      case 3:
        return _buildStep4MediaDocuments();
      case 4:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 4: Media & Documents ───
  Widget _buildStep4MediaDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7EF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.perm_media_outlined,
                      color: Color(0xFF3AAE5E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Photos et vidéos (non-obligatoires)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ajoutez des visuels de votre formation (salles, intervenants, participants) pour projeter les apprenants dans l’expérience.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                return _buildAddMediaButton();
              }
              if (index <= _existingMedia.length) {
                final media = _existingMedia[index - 1];
                return _buildExistingMediaCard(media);
              }
              final fileIndex = index - 1 - _existingMedia.length;
              return _buildMediaPreviewCard(_selectedMediaFiles[fileIndex], fileIndex);
            },
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF3AAE5E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Documents',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Programme de formation, règlement intérieur, etc.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: _pickDocuments,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3AAE5E),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.upload_file,
                    size: 32,
                    color: Color(0xFF3AAE5E),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajouter des documents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3AAE5E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, Word, Excel, PowerPoint',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_existingDocuments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildExistingDocumentList(compact: true),
          ),
        ],
        if (_selectedDocumentFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDocumentList(),
        ],
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildNextButton(),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAddMediaButton() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3AAE5E),
            width: 2,
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
                size: 32,
                color: Color(0xFF3AAE5E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajouter ${_selectedMediaFiles.isEmpty ? "des" : "plus de"} photos',
              style: const TextStyle(
                fontSize: 13,
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

  Widget _buildMediaPreviewCard(PlatformFile file, int index) {
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
                    fontSize: 11,
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
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
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

  // ─── STEP 1: Type & Category ───
  Widget _buildStep1Type() {
    final categoryNames = _categoriesFromApi.map((c) => c['name'].toString()).toList();
    final subCategoryNames = _subCategoriesForCategory.map((s) => s['name'].toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.school_outlined,
          title: 'Catégorie et Type',
          subtitle: 'Sélectionnez la catégorie, le secteur et le type de formation correspondant à votre offre.',
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (categoryNames.isEmpty)
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
                    _updateSubCategoriesForCategory(category['id'] as int?);
                  }
                },
                hint: _buildRequiredHint('Choisissez une catégorie'),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
            if (_selectedCategoryId != null && subCategoryNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Choisissez un secteur*',
                value: _selectedSubCategoryName,
                items: subCategoryNames,
                onChanged: (val) {
                  if (val == null) return;
                  final subCategory = _subCategoriesForCategory.firstWhere(
                    (s) => s['name'] == val,
                    orElse: () => <String, dynamic>{},
                  );
                  setState(() {
                    _selectedSubCategoryId = subCategory['id'] as int?;
                    _selectedSubCategoryName = val;
                  });
                },
                hint: _buildRequiredHint('Choisissez un secteur'),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
            ],
            if (_trainingTypes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDropdownField(
                label: 'Type de formation*',
                value: _selectedTrainingType,
                items: _trainingTypes,
                onChanged: (val) => setState(() => _selectedTrainingType = val),
                hint: _buildRequiredHint('Choisissez le type de formation'),
                backgroundColor: const Color(0xFFF9FAFB),
                labelBuilder: (value) => _trainingTypesMap[value] ?? value,
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

  // ─── STEP 2: Link (Optional) ───
  Widget _buildStep2FranceTravail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.link,
          title: 'Lien ',
          subtitle:
              "Collez le lien France Travail de la formation. Nous l'utiliserons pour récupérer automatiquement les informations et pré-remplir votre annonce.",
          children: [
            _buildTextField(
              label: 'Ajouter un lien',
              controller: _linkController,
              keyboardType: TextInputType.url,
              fieldKey: 'link',
              helperText: 'Le lien permettra d\'extraire automatiquement le titre, la description, les dates, le lieu, le prix et autres détails de la formation pour faciliter la création de votre annonce.',
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
              "Je n'ai pas de lien",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── STEP 3: Description & Details ───
  Widget _buildStep3Description() {
    final teachingTypesMap = _metadata['teaching_types'] as Map<String, dynamic>? ?? {};
    final targetPublicsMap = _metadata['target_publics'] as Map<String, dynamic>? ?? {};
    final fundingOptionsMap = _metadata['funding_options'] as Map<String, dynamic>? ?? {};

    final teachingTypeLabels = teachingTypesMap.values.map((v) => v.toString()).toList();
    final targetPublicLabels = targetPublicsMap.values.map((v) => v.toString()).toList();
    final fundingLabels = fundingOptionsMap.values.map((v) => v.toString()).toList();
    final isPriceInputEnabled = _isPriceAmountRequired(_selectedPriceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title ──
        _buildSectionLabel('Quel est votre titre ?', isRequired: true),
        const SizedBox(height: 6),
        _buildTextField(
          label: 'ex : formation title courte et percutant',
          controller: _titleController,
          fieldKey: 'title',
          helperText: 'Saisissez un titre accrocheur et descriptif pour votre formation (max 100 caractères).',
        ),

        const SizedBox(height: 20),

        // ── Type d'enseignement ──
        if (teachingTypeLabels.isNotEmpty) ...[
          _buildCheckboxGroup(
            title: "Type d'enseignement : Choix multiple possible *",
            options: teachingTypeLabels,
            selectedValues: _selectedTeachingStyles.map((key) {
              return teachingTypesMap[key]?.toString() ?? key;
            }).toList(),
            onChanged: (updatedList) {
              final reverseMap = {for (final e in teachingTypesMap.entries) e.value.toString(): e.key};
              final keys = updatedList.map((label) => reverseMap[label] ?? label).toList();
              final toutKey = reverseMap.entries
                  .where((e) => e.key.toLowerCase() == 'tout')
                  .map((e) => e.value)
                  .firstOrNull;
              if (toutKey != null && keys.contains(toutKey)) {
                setState(() => _selectedTeachingStyles = teachingTypesMap.keys.toList());
              } else {
                setState(() => _selectedTeachingStyles = keys..remove(toutKey));
              }
            },
          ),
          const SizedBox(height: 20),
        ],

        // ── Public visé ──
        if (targetPublicLabels.isNotEmpty) ...[
          _buildCheckboxGroup(
            title: "Public visé : Choix multiple possible *",
            options: targetPublicLabels,
            selectedValues: _selectedTargetPublics.map((key) {
              return targetPublicsMap[key]?.toString() ?? key;
            }).toList(),
            onChanged: (updatedList) {
              final reverseMap = {for (final e in targetPublicsMap.entries) e.value.toString(): e.key};
              final keys = updatedList.map((label) => reverseMap[label] ?? label).toList();
              final toutKey = reverseMap.entries
                  .where((e) => e.key.toLowerCase() == 'tout public')
                  .map((e) => e.value)
                  .firstOrNull;
              if (toutKey != null && keys.contains(toutKey)) {
                setState(() => _selectedTargetPublics = targetPublicsMap.keys.toList());
              } else {
                setState(() => _selectedTargetPublics = keys..remove(toutKey));
              }
            },
          ),
          const SizedBox(height: 20),
        ],

        // ── Niveau requis ──
          _buildCheckboxGroupWithCustom(
            title: "Niveau requis : Choix multiple possible *",
            options: _requiredLevels,
            selectedValues: _selectedRequiredLevels,
            onChanged: (updatedList) {
              setState(() => _selectedRequiredLevels = updatedList);
            },
            customValues: _customRequiredLevels,
            onCustomValuesChanged: (val) => setState(() => _customRequiredLevels = val),
            customController: _customLevelController,
          ),
          const SizedBox(height: 20),

        // ── Prix de la formation ──
        _buildSectionLabel('Prix de la formation', isRequired: true),
        const SizedBox(height: 6),
        _buildTextField(
          label: 'Prix',
          controller: _priceController,
          keyboardType: TextInputType.number,
          suffix: '€',
          fieldKey: 'price',
          helperText: isPriceInputEnabled
              ? 'Indiquez le prix de votre formation. Laissez vide si gratuit ou sur devis.'
              : 'Aucun montant requis pour ce type de tarif.',
          enabled: isPriceInputEnabled,
        ),
        const SizedBox(height: 10),
        if (_priceTypes.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _priceTypes.entries.map((entry) {
              final isSelected = _selectedPriceType == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriceType = entry.key;
                    if (!_isPriceAmountRequired(entry.key)) {
                      _priceController.clear();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3AAE5E).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 16,
                        color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 20),

        // ── Tarif appliqué + Temporalité (side by side) ──
        if (_publicTypes.isNotEmpty || _tempoTypes.isNotEmpty)
          Row(
            children: [
              if (_publicTypes.isNotEmpty)
                Expanded(
                  child: _buildDropdownField(
                    label: 'Tarif appliqué',
                    value: _selectedPublicType,
                    items: _publicTypes.keys.toList(),
                    onChanged: (val) => setState(() => _selectedPublicType = val),
                    labelBuilder: (key) => _publicTypes[key] ?? key,
                    backgroundColor: const Color(0xFFF9FAFB),
                  ),
                ),
              if (_publicTypes.isNotEmpty && _tempoTypes.isNotEmpty)
                const SizedBox(width: 12),
              if (_tempoTypes.isNotEmpty)
                Expanded(
                  child: _buildDropdownField(
                    label: 'Temporalité',
                    value: _selectedTempo,
                    items: _tempoTypes.keys.toList(),
                    onChanged: (val) => setState(() => _selectedTempo = val),
                    labelBuilder: (key) => _tempoTypes[key] ?? key,
                    backgroundColor: const Color(0xFFF9FAFB),
                  ),
                ),
            ],
          ),

        const SizedBox(height: 20),

        // ── Financement ──
        if (fundingLabels.isNotEmpty) ...[
          _buildCheckboxGroup(
            title: "Financement : Choix multiple possible *",
            options: fundingLabels,
            selectedValues: _selectedFunding.map((key) {
              return fundingOptionsMap[key]?.toString() ?? key;
            }).toList(),
            onChanged: (updatedList) {
              final reverseMap = {for (final e in fundingOptionsMap.entries) e.value.toString(): e.key};
              final keys = updatedList.map((label) => reverseMap[label] ?? label).toList();
              setState(() => _selectedFunding = keys);
            },
          ),
          const SizedBox(height: 20),
        ],

        // ── Durée + Temporalité (side by side) ──
        _buildSectionLabel('Durée'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Durée',
                controller: _durationController,
                keyboardType: TextInputType.number,
                fieldKey: 'duration',
                helperText: 'Indiquez la durée totale de la formation.',
              ),
            ),
            const SizedBox(width: 12),
            if (_durationUnits.isNotEmpty)
              Expanded(
                child: _buildDropdownField(
                  label: 'Temporalité',
                  value: _selectedDurationUnit,
                  items: _durationUnits.keys.toList(),
                  onChanged: (val) => setState(() {
                    _selectedDurationUnit = val;
                    debugPrint('Duration unit changed to: $_selectedDurationUnit');
                  }),
                  labelBuilder: (key) => _durationUnits[key] ?? key,
                  backgroundColor: const Color(0xFFF9FAFB),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Dates ──
        Row(
          children: [
            _buildCheckOption(
              'Dates définies',
              !_dateToDefine,
              () => setState(() => _dateToDefine = false),
            ),
            const SizedBox(width: 24),
            _buildCheckOption(
              'Dates à définir',
              _dateToDefine,
              () => setState(() => _dateToDefine = true),
            ),
          ],
        ),
        if (!_dateToDefine) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  title: "Date de début",
                  selectedDate: _startDate,
                  onDateSelected: (date) => setState(() => _startDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  title: "Date de fin",
                  selectedDate: _endDate,
                  onDateSelected: (date) => setState(() => _endDate = date),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // ── Rich text description ──
        _buildSectionLabel('Décrivez votre offre', isRequired: true),
        const SizedBox(height: 6),
        _buildRichTextEditor(
          label: 'Description',
          controller: _descriptionQuillController,
          fieldKey: 'description',
          helperText: 'Décrivez en détail votre formation. Utilisez les outils de mise en forme pour mettre en évidence les informations importantes.',
        ),

        const SizedBox(height: 20),

        // ── Document upload ──
        _buildSectionLabel('Ajouter un document', isRequired: false),
        Text(
          '(programme de la formation, le règlement intérieur, etc.)',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        _buildUploadButton2(
          label: 'Ajouter un fichier',
          color: const Color(0xFFFF9800),
          onTap: _pickDocuments,
        ),
        if (_existingDocuments.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildExistingDocumentList(),
        ],
        if (_selectedDocumentFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDocumentList(),
        ],

        const SizedBox(height: 20),

        // ── Site web ──
        _buildSectionLabel('Site web de l\'organisme'),
        const SizedBox(height: 6),
        _buildTextField(
          label: 'ex : https://www.workshop-provider-com-fr',
          controller: _websiteController,
          keyboardType: TextInputType.url,
          fieldKey: 'website',
          helperText: 'Ajoutez le lien vers le site de votre organisme de formation.',
        ),

        const SizedBox(height: 20),

        // ── Certifications ──
          _buildCheckboxGroupWithCustom(
            title: "Êtes-vous certifié ?",
            options: _certifications,
            selectedValues: _selectedCertifications,
            onChanged: (updatedList) {
              setState(() => _selectedCertifications = updatedList);
            },
            customValues: _customCertifications,
            onCustomValuesChanged: (val) => setState(() => _customCertifications = val),
            customController: _customCertificationController,
          ),
          const SizedBox(height: 20),

        // ── Lieu ──
        _buildSectionLabel('Lieu', isRequired: true),
        Text(
          'Indiquez le lieu/adresse de cette offre est valide.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          label: 'Rechercher par ville ou code postal...',
          controller: _addressCityController,
          prefixIcon: Icons.search,
          fieldKey: 'location',
          helperText: 'Saisissez le nom de la ville ou le code postal où la formation se déroule.',
        ),
        const SizedBox(height: 12),
        _buildCheckOption(
          'Afficher la newsletter Google sur l\'annonce',
          _showLocation,
          () => setState(() => _showLocation = !_showLocation),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: RichText(
            text: TextSpan(
              text: '* ',
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: 'Champ Obligatoire',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildNextButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSectionLabel(String text, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 15,
          color: Colors.black.withOpacity(0.8),
          fontFamily: 'Manjari',
          fontWeight: FontWeight.bold,
        ),
        children: isRequired
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : null,
      ),
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
            'Vérifiez votre annonce',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
        ),
        Center(
          child: Text(
            'Relisez les informations avant de publier formation',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        // Informations générales
        _buildReviewSection(
          title: 'Catégorie et Type',
          onEdit: () => setState(() => _currentStep = 0),
          rows: [
            _buildReviewRow('Catégorie', _selectedCategoryName ?? '-'),
            _buildReviewRow('Secteur', _selectedSubCategoryName ?? '-'),
            _buildReviewRow('Type de formation', _selectedTrainingType ?? '-'),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        _buildReviewSection(
          title: 'Informations générales',
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
                  : _descriptionQuillController.document.toPlainText().trim().substring(
                      0,
                      _descriptionQuillController.document.toPlainText().trim().length > 100
                          ? 100
                          : _descriptionQuillController.document.toPlainText().trim().length,
                    ) + (_descriptionQuillController.document.toPlainText().trim().length > 100 ? '...' : ''),
            ),
            _buildReviewRow(
              'Site web',
              _websiteController.text.isEmpty ? '-' : _websiteController.text,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Modalités
        _buildReviewSection(
          title: 'Modalités',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow(
              'Type d\'enseignement',
              _selectedTeachingStyles.isEmpty ? '-' : _selectedTeachingStyles.length.toString() + ' sélectionné(s)',
            ),
            _buildReviewRow(
              'Public visé',
              _selectedTargetPublics.isEmpty ? '-' : _selectedTargetPublics.length.toString() + ' sélectionné(s)',
            ),
            _buildReviewRow(
              'Niveau requis',
              _selectedRequiredLevels.isEmpty ? '-' : _selectedRequiredLevels.join(', '),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tarification
        _buildReviewSection(
          title: 'Tarification',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow(
              'Type de tarif',
              _selectedPriceType != null ? (_priceTypes[_selectedPriceType] ?? _selectedPriceType!) : '-',
            ),
            if (_priceController.text.isNotEmpty)
              _buildReviewRow(
                'Prix',
                _priceController.text + ' €',
              ),
            _buildReviewRow(
              'Financement',
              _selectedFunding.isEmpty ? '-' : _selectedFunding.length.toString() + ' option(s)',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Durée et dates
        _buildReviewSection(
          title: 'Durée et dates',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow(
              'Durée',
              _durationController.text.isEmpty
                  ? '-'
                  : _durationController.text + ' ' + (_selectedDurationUnit != null ? (_durationUnits[_selectedDurationUnit] ?? '') : ''),
            ),
            _buildReviewRow(
              'Dates',
              _dateToDefine
                  ? 'À définir'
                  : (_startDate != null || _endDate != null
                      ? '${_startDate != null ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}" : "-"} - ${_endDate != null ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}" : "-"}'
                      : '-'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Localisation
        _buildReviewSection(
          title: 'Localisation',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow(
              'Adresse',
              _addressLine1Controller.text.isEmpty && _addressCityController.text.isEmpty
                  ? '-'
                  : '${_addressLine1Controller.text}${_addressCityController.text.isNotEmpty ? ", " + _addressCityController.text : ""}',
            ),
            _buildReviewRow(
              'Afficher localisation',
              _showLocation ? 'Oui' : 'Non',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Certifications
        if (_selectedCertifications.isNotEmpty)
          _buildReviewSection(
            title: 'Certifications',
            onEdit: () => setState(() => _currentStep = 2),
            rows: [
              _buildReviewRow(
                'Certifications',
                _selectedCertifications.join(', '),
              ),
            ],
          ),
        if (_selectedCertifications.isNotEmpty) const SizedBox(height: 16),

        // Médias et documents
        _buildReviewSection(
          title: 'Médias et documents',
          onEdit: () => setState(() => _currentStep = 3),
          rows: [
            _buildReviewRow(
              'Photos/Vidéos',
              _selectedMediaFiles.isEmpty
                  ? 'Aucun média'
                  : '${_selectedMediaFiles.length} fichier(s)',
            ),
            _buildReviewRow(
              'Documents',
              _selectedDocumentFiles.isEmpty
                  ? 'Aucun document'
                  : '${_selectedDocumentFiles.length} fichier(s)',
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
                'Accepter de recevoir des messages à propos de cette formation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les candidats pourront vous écrire pour obtenir des précisions sur le programme, les financements ou les modalités d’inscription.',
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
            onPressed: _isSubmitting ? null : _submitTraining,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              _isEditMode ? 'Mettre à jour la formation' : 'Publier la formation',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int? maxLines = 1,
    TextInputType? keyboardType,
    String? suffix,
    String? fieldKey,
    String? helperText,
    IconData? prefixIcon,
    bool enabled = true,
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
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: Colors.grey[400]) : null,
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

  Widget _buildUploadButton2({required String label, required Color color, VoidCallback? onTap}) {
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

  Widget _buildCheckboxGroupWithCustom({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
    required List<String> customValues,
    required Function(List<String>) onCustomValuesChanged,
    required TextEditingController customController,
  }) {
    final allOptions = [...options, ...customValues];

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
            children: [
              // Standard options (no × button, use normal CheckboxListTile)
              ...options.map((option) {
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
                      final updatedList = List<String>.from(selectedValues);
                      if (value == true) {
                        updatedList.add(option);
                      } else {
                        updatedList.remove(option);
                      }
                      onChanged(updatedList);
                    },
                  ),
                );
              }),

              // Custom options — row-based layout to avoid tap propagation issues
              ...customValues.map((option) {
                final isSelected = selectedValues.contains(option);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Checkbox(
                          value: isSelected,
                          side: const BorderSide(color: Colors.grey, width: 1),
                          activeColor: const Color(0xFF3AAE5E),
                          onChanged: (bool? value) {
                            final updatedList = List<String>.from(selectedValues);
                            if (value == true) {
                              updatedList.add(option);
                            } else {
                              updatedList.remove(option);
                            }
                            onChanged(updatedList);
                          },
                        ),
                      ),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // × button — completely separate from checkbox tap area
                      InkWell(
                        onTap: () {
                          final newCustom = List<String>.from(customValues)..remove(option);
                          final newSelected = List<String>.from(selectedValues)..remove(option);
                          onCustomValuesChanged(newCustom);
                          onChanged(newSelected);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.close, size: 16, color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Divider before custom input
              const Divider(height: 12, thickness: 0.5),

              // Custom input row — hidden once a custom value has been added
              if (customValues.isEmpty)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: customController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ajouter une valeur personnalisée...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (val) {
                          final trimmed = val.trim();
                          if (trimmed.isEmpty || allOptions.contains(trimmed)) return;
                          final newCustom = List<String>.from(customValues)..add(trimmed);
                          final newSelected = List<String>.from(selectedValues)..add(trimmed);
                          onCustomValuesChanged(newCustom);
                          onChanged(newSelected);
                          customController.clear();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final trimmed = customController.text.trim();
                      if (trimmed.isEmpty || allOptions.contains(trimmed)) return;
                      final newCustom = List<String>.from(customValues)..add(trimmed);
                      final newSelected = List<String>.from(selectedValues)..add(trimmed);
                      onCustomValuesChanged(newCustom);
                      onChanged(newSelected);
                      customController.clear();
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3AAE5E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Ajouter',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Widget? hint,
    Color? backgroundColor,
    String Function(String value)? labelBuilder,
  }) {
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
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  labelBuilder != null ? labelBuilder(item) : item,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
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
