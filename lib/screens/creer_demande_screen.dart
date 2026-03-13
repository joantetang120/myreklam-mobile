import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/services/api_client.dart';
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

  // Step 1 - Nature
  String? _selectedCategory;
  String? _selectedType;

  // Step 2 - Details
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionQuillController = QuillController.basic();
  bool _acceptDemand = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _prixInitialController = TextEditingController();
  final TextEditingController _prixFinalController = TextEditingController();

  // Step 3 - Localisation
  final TextEditingController _disponibleChezController = TextEditingController();
  bool _touteLaFrance = false;
  bool _useCurrentLocation = false;
  bool _showGoogleLocation = false;
  double _rayonRecherche = 0;

  // Media
  final List<PlatformFile> _selectedMediaFiles = [];
  final List<String> _existingMediaUrls = [];
  bool _isUploadingMedia = false;

  // Review
  bool _acceptMessages = false;

  // Submission state
  bool _isSubmitting = false;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    _loadDemandeCategories();
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
    if (data['start_date'] != null) _startDate = DateTime.tryParse(data['start_date'].toString());
    if (data['end_date'] != null) _endDate = DateTime.tryParse(data['end_date'].toString());
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
      _rayonRecherche = (radius is int) ? radius.toDouble() : (double.tryParse(radius.toString()) ?? 0);
    }

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
        _titleController.text = formData['title'] ?? '';
        _prixInitialController.text = formData['budget_min'] ?? '';
        _prixFinalController.text = formData['budget_max'] ?? '';
        _disponibleChezController.text = formData['location'] ?? '';
        _acceptDemand = formData['urgent'] ?? false;
        if (formData['start_date'] != null) _startDate = DateTime.tryParse(formData['start_date'].toString());
        if (formData['end_date'] != null) _endDate = DateTime.tryParse(formData['end_date'].toString());
        _touteLaFrance = formData['toute_la_france'] ?? false;
        _useCurrentLocation = formData['use_current_location'] ?? false;
        _showGoogleLocation = formData['show_google_location'] ?? false;
        _rayonRecherche = (formData['rayon'] ?? 0).toDouble();
        _acceptMessages = formData['accept_messages'] ?? false;
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

      setState(() {
        _natureOptions = parsedNatures;
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
          final hasNatureCode = parsedNatures.any((o) => o['code'] == _selectedCategory);
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
        _categoryLoadError = 'Impossible de charger les natures. Veuillez réessayer.';
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

  void _onNatureChanged(String? code) {
    setState(() {
      _selectedCategory = code;
      _selectedType = null;
      _typeOptions = _getSubCategoriesForCode(code);
    });
  }

  Future<void> _submitDemande() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Session expirée. Veuillez vous reconnecter.');

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
          if (_selectedMediaFiles.isNotEmpty && demandeId != null) {
            await _uploadMediaFiles(demandeId);
          }
          await _clearSavedProgress();
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          _showSuccessDialog();
          return;
        }
      }
      final errorMsg = _extractErrorMessage(response.body) ??
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
    final description = _descriptionQuillController.document.toPlainText().trim();
    final descriptionDelta = _descriptionQuillController.document.toDelta().toJson();
    final payload = <String, dynamic>{
      'nature': _selectedCategory,
      'type': _selectedType,
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
    };
    if (_prixInitialController.text.trim().isNotEmpty) {
      final v = double.tryParse(_prixInitialController.text.replaceAll(',', '.'));
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

  void _removeMedia(int index) {
    setState(() => _selectedMediaFiles.removeAt(index));
  }

  Widget _buildMediaPreview(PlatformFile file) {
    final ext = file.extension?.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
    final isVideo = ['mp4', 'mov'].contains(ext);
    if (isImage && file.bytes != null) {
      return Image.memory(file.bytes!, fit: BoxFit.cover, width: 100, height: 100);
    } else if (isVideo) {
      return Container(
        color: Colors.black87,
        child: const Center(child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white)),
      );
    }
    return Container(
      color: const Color(0xFFF9FAFB),
      child: const Center(child: Icon(Icons.insert_drive_file, size: 40, color: Color(0xFF3AAE5E))),
    );
  }

  Future<bool> _uploadMediaFiles(String demandeId) async {
    if (_selectedMediaFiles.isEmpty) return true;
    setState(() => _isUploadingMedia = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return false;
      final uri = Uri.parse('${ApiConfig.baseUrl}/demandes/$demandeId/media');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';
      for (final file in _selectedMediaFiles) {
        if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath('media[]', file.path!, filename: file.name));
        } else if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes('media[]', file.bytes!, filename: file.name ?? 'media'));
        }
      }
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        setState(() => _selectedMediaFiles.clear());
        return true;
      }
      final msg = _extractErrorMessage(body) ?? 'Impossible d\'envoyer les médias (${streamed.statusCode}).';
      _showSnack(msg, isError: true);
      return false;
    } catch (_) {
      _showSnack('Échec de l\'upload des médias. Veuillez réessayer.', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF3AAE5E),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
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
        if (_selectedType == null) {
          return 'Veuillez sélectionner un type de demande.';
        }
        break;
      
      case 1: // Step 2: Description
        if (_titleController.text.trim().length < 5) {
          return 'Le titre doit contenir au moins 5 caractères.';
        }
        if (_descriptionQuillController.document.toPlainText().trim().length < 20) {
          return 'La description doit contenir au moins 20 caractères.';
        }
        break;
      
      case 2: // Step 3: Détails
        if (_startDate == null) {
          return 'Sélectionnez une date de début.';
        }
        if (_endDate == null) {
          return 'Sélectionnez une date de fin.';
        }
        if (_endDate!.isBefore(_startDate!)) {
          return 'La date de fin doit être postérieure à la date de début.';
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
              _buildInlineErrorBanner(_categoryLoadError!, onRetry: _loadDemandeCategories)
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
              helperText: 'Saisissez un titre clair et précis pour votre demande (ex: "Recherche plombier pour fuite d\'eau urgente").',
            ),
            const SizedBox(height: 12),
            _buildRichTextEditor(
              label: 'Description de votre demande*',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText: 'Décrivez en détail ce que vous recherchez : contexte, contraintes, attentes particulières. Plus vous êtes précis, meilleures seront les réponses.',
            ),
            const SizedBox(height: 16),
            Text(
              "Quel serait le délai idéal pour répondre à votre demande ?",
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.8)),
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
                        const Text('À partir du :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) setState(() => _startDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
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
                                      color: _startDate != null ? Colors.black87 : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[500]),
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
                        const Text('Jusqu\'au (facultatif) :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? _startDate ?? DateTime.now(),
                              firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) setState(() => _endDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
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
                                      color: _endDate != null ? Colors.black87 : Colors.grey[400],
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today, size: 18, color: Colors.grey[500]),
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
              style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.8)),
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
              helperText: 'Indiquez le montant minimum que vous êtes prêt à investir.',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Budget maximum (€)',
              controller: _prixFinalController,
              keyboardType: TextInputType.number,
              suffix: '€',
              fieldKey: 'budget_max',
              helperText: 'Indiquez le montant maximum que vous ne souhaitez pas dépasser.',
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
                helperText: 'Indiquez la ville ou l\'adresse où vous souhaitez que la prestation soit réalisée.',
              ),
              const SizedBox(height: 8),
              _buildCheckOption(
                'Utiliser ma position actuelle',
                _useCurrentLocation,
                () => setState(() => _useCurrentLocation = !_useCurrentLocation),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rayon de recherche',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF424242)),
              ),
              Text(
                '${_rayonRecherche.toInt()} km',
                style: const TextStyle(fontSize: 13, color: Color(0xFFFF9800), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFEF8A40),
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: const Color(0xFFEF8A40),
                  overlayColor: const Color(0xFFEF8A40).withOpacity(0.2),
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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
                      .map((t) => Text(t, style: TextStyle(fontSize: 11, color: Colors.grey[500])))
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
              ),
              SizedBox(height: 8),
              Text(
                'Illustrez votre demande avec des photos pour attirer plus de réponses pertinentes.',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4),
              ),
              SizedBox(height: 20),
              Text(
                'Vos photos (non-obligatoires)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF424242)),
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
              return _buildExistingPhotoCard(_existingMediaUrls[index - 1], index - 1);
            }
            final newIndex = index - 1 - existingCount;
            return _buildPhotoPreviewCard(_selectedMediaFiles[newIndex], newIndex);
          },
        ),
        const SizedBox(height: 24),
        _buildNextButton(),
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
              child: const Icon(Icons.camera_alt, size: 40, color: Color(0xFF3AAE5E)),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMediaFiles.isEmpty ? 'Ajouter des photos' : 'Ajouter plus',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3AAE5E)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800)),
                  );
                },
              ),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: const Text('Photo de couverture', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _existingMediaUrls.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF666666)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
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
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF3AAE5E),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                ),
                child: const Text('Photo de couverture', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: () => _removeMedia(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF666666)),
              ),
            ),
          ),
        ],
      ),
    );
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
            _isEditMode ? 'Vérifiez vos modifications' : 'Vérifiez votre demande',
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
              )['label'] ?? '-',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Étape 2 - Détails
        _buildReviewSection(
          title: 'Étape 2 — Détails',
          onEdit: () => setState(() => _currentStep = 1),
          rows: [
            _buildReviewRow(
              'Type',
              _typeOptions.firstWhere(
                (o) => o['code'] == _selectedType,
                orElse: () => {'label': '-'},
              )['label'] ?? '-',
            ),
            _buildReviewRow(
              'Titre',
              _titleController.text.trim().isEmpty ? '-' : _titleController.text.trim(),
            ),
            _buildReviewRow(
              'Description',
              _descriptionQuillController.document.toPlainText().trim().isEmpty
                  ? '-'
                  : _descriptionQuillController.document.toPlainText().trim(),
            ),
            _buildReviewRow('Urgent', _acceptDemand ? 'Oui' : 'Non'),
            if (!_acceptDemand) ...[
              _buildReviewRow('À partir du', _startDate != null ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}' : '-'),
              _buildReviewRow('Jusqu\'au', _endDate != null ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}' : '-'),
            ],
            _buildReviewRow(
              'Budget min',
              _prixInitialController.text.trim().isEmpty ? '-' : '${_prixInitialController.text.trim()} €',
            ),
            _buildReviewRow(
              'Budget max',
              _prixFinalController.text.trim().isEmpty ? '-' : '${_prixFinalController.text.trim()} €',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Étape 3 - Localisation
        _buildReviewSection(
          title: 'Étape 3 — Localisation',
          onEdit: () => setState(() => _currentStep = 2),
          rows: [
            _buildReviewRow('Toute la France', _touteLaFrance ? 'Oui' : 'Non'),
            _buildReviewRow(
              'Ville / Adresse',
              _disponibleChezController.text.trim().isEmpty ? '-' : _disponibleChezController.text.trim(),
            ),
            _buildReviewRow('Utiliser ma position', _useCurrentLocation ? 'Oui' : 'Non'),
            _buildReviewRow('Rayon de recherche', _rayonRecherche > 0 ? '${_rayonRecherche.toInt()} km' : '-'),
            _buildReviewRow('Afficher localisation', _showGoogleLocation ? 'Oui' : 'Non'),
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
                    _isEditMode ? 'Enregistrer les modifications' : 'Publier la demande',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 13,
              ),
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
                  .map((item) => DropdownMenuItem(
                        value: item['code'],
                        child: Text(item['label'] ?? ''),
                      ))
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4),
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
                  child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
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
}
