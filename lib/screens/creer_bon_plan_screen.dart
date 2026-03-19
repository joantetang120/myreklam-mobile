import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class _CategoryLoadResult {
  final List<String> categories;
  final Map<String, List<String>> subCategories;

  _CategoryLoadResult({required this.categories, required this.subCategories});
}

class CreerBonPlanScreen extends StatefulWidget {
  final String? bonPlanId;
  final Map<String, dynamic>? initialData;

  const CreerBonPlanScreen({super.key, this.bonPlanId, this.initialData});

  bool get isEditMode => bonPlanId != null;

  @override
  State<CreerBonPlanScreen> createState() => _CreerBonPlanScreenState();
}

class _CreerBonPlanScreenState extends State<CreerBonPlanScreen> {
  static const String _categoriesApiUrl =
      'https://api.myreklam.fr/Categorie.php';
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Step 1 - Informations
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedType;
  List<String> _availableSubCategories = [];

  // Step 2 - Description
  final TextEditingController _titleController = TextEditingController();
  final QuillController _descriptionQuillController = QuillController.basic();
  final TextEditingController _disponibleChezController =
      TextEditingController();
  String? _selectedDisponibleLocation;

  // Step 3 - Lien
  final TextEditingController _linkController = TextEditingController();

  // Step 4 - Prix et détails
  final TextEditingController _siteWebController = TextEditingController();
  final TextEditingController _prixAvantReductionController =
      TextEditingController();
  final TextEditingController _prixFinalController = TextEditingController();
  final FocusNode _prixAvantFocusNode = FocusNode();
  final FocusNode _prixFinalFocusNode = FocusNode();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  String _validityType = 'permanent'; // 'permanent' or 'dates'
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _touteFrance = false;
  bool _afficherGoogleLocation = false;
  bool _moyenRetraitMagasin = false;
  bool _moyenRetraitEnLigne = false;
  bool _moyenRetraitDrive = false;
  String _discountMode = 'percent';
  double? _calculatedDiscount;

  // Shipping options for online availability
  String _shippingOption = 'free'; // 'free' or 'paid'
  final TextEditingController _shippingCostController = TextEditingController();

  bool _acceptMessages = false;
  final ApiClient _apiClient = ApiClient();
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;
  final List<PlatformFile> _selectedMediaFiles = [];
  final List<String> _existingMediaUrls = [];

  // Focus tracking for helper text
  String? _focusedField;

  List<String> _categories = [];
  Map<String, List<String>> _categorySubCategories = {};
  List<String> _types = [];
  List<String> _locationOptions = [];
  bool _isMetaLoading = true;
  String? _metaError;

  bool get _isEditMode => widget.isEditMode;
  bool get _isFreeType => (_selectedType ?? '').toLowerCase() == 'gratuit';
  bool get _isOnlineOnly =>
      (_selectedDisponibleLocation ?? '').toLowerCase() == 'en ligne';

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    if (_isEditMode) {
      _prefillFromInitialData();
    } else {
      _checkForSavedProgress();
    }

    _prixAvantFocusNode.addListener(_onPriceFocusChanged);
    _prixFinalFocusNode.addListener(_onPriceFocusChanged);
  }

  void _onPriceFocusChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildGreenHelperBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF1B5E20),
          height: 1.4,
        ),
      ),
    );
  }

  void _handleTypeChanged(String? newType) {
    setState(() {
      _selectedType = newType;
      if (_isFreeType) {
        _prixAvantReductionController.clear();
        _prixFinalController.clear();
        _calculatedDiscount = null;
      }
    });
  }

  void _prefillFromInitialData() {
    final data = widget.initialData;
    if (data == null) return;

    _titleController.text = data['title']?.toString() ?? '';
    _disponibleChezController.text =
        data['available_at_name']?.toString() ?? '';
    _linkController.text = data['link']?.toString() ?? '';
    _siteWebController.text = data['brand_website']?.toString() ?? '';
    _locationController.text = data['location_search']?.toString() ?? '';
    _conditionsController.text = data['conditions']?.toString() ?? '';

    _selectedCategory = data['category']?.toString();
    _selectedSubCategory = data['sub_category']?.toString();
    _selectedType = data['type']?.toString();
    _selectedDisponibleLocation = data['available_location_type']?.toString();

    _validityType = data['validity_type']?.toString() ?? 'permanent';
    if (data['valid_from'] != null) {
      try {
        _validFrom = DateTime.parse(data['valid_from'].toString());
      } catch (_) {}
    }
    if (data['valid_until'] != null) {
      try {
        _validUntil = DateTime.parse(data['valid_until'].toString());
      } catch (_) {}
    }

    _touteFrance = data['nationwide'] == true;
    _afficherGoogleLocation = data['show_google_location'] == true;
    _acceptMessages = data['accept_messages'] == true;

    final pickupMethods = data['pickup_methods'];
    if (pickupMethods is Map) {
      _moyenRetraitMagasin = pickupMethods['in_store'] == true;
      _moyenRetraitEnLigne = pickupMethods['delivery'] == true;
      _moyenRetraitDrive = pickupMethods['drive'] == true;
    }

    // Price fields
    final prixAvant = data['prix_avant_reduction'];
    final prixFinal = data['prix_final'];
    if (prixAvant != null)
      _prixAvantReductionController.text = prixAvant.toString();
    if (prixFinal != null) _prixFinalController.text = prixFinal.toString();
    _discountMode = data['discount_type']?.toString() ?? 'percent';

    // Shipping fields
    _shippingOption = data['shipping_option']?.toString() ?? 'free';
    final shippingCost = data['shipping_cost'];
    if (shippingCost != null)
      _shippingCostController.text = shippingCost.toString();

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
            // Replace any localhost/127.0.0.1 or old IP with current server base
            fullUrl = url.replaceFirst(RegExp(r'https?://[^/]+'), serverBase);
          } else {
            fullUrl = '$serverBase$url';
          }
          _existingMediaUrls.add(fullUrl);
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recalculateDiscount();
      // Restore rich text description after the widget tree is built
      _restoreDescription(data);
    });
  }

  void _restoreDescription(Map<String, dynamic> data) {
    final descDelta = data['description_delta'];
    debugPrint(
      'Edit mode description_delta type: ${descDelta.runtimeType}, value: $descDelta',
    );
    bool deltaRestored = false;

    if (descDelta != null) {
      try {
        List opsList;

        if (descDelta is List) {
          // Already a List<dynamic> of Dart maps — use directly
          opsList = descDelta;
        } else if (descDelta is Map && descDelta['ops'] is List) {
          opsList = descDelta['ops'] as List;
        } else if (descDelta is String && descDelta.isNotEmpty) {
          // Try JSON string parsing
          String jsonString = descDelta;

          // Handle unquoted keys
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
            throw Exception('Unknown delta format: ${rawData.runtimeType}');
          }
        } else {
          throw Exception(
            'Unsupported descDelta type: ${descDelta.runtimeType}',
          );
        }

        // Filter out operations with null insert values
        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();

        if (filteredOps.isNotEmpty) {
          // Ensure last op ends with newline (Quill requirement)
          final lastInsert = filteredOps.last['insert'];
          if (lastInsert is String && !lastInsert.endsWith('\n')) {
            filteredOps.add({'insert': '\n'});
          }

          _descriptionQuillController.document = Document.fromJson(filteredOps);
          deltaRestored = true;
          debugPrint('Description delta restored successfully');
        }
      } catch (e) {
        debugPrint('Error restoring description delta in edit mode: $e');
      }
    }

    // Fallback: use plain description text if delta didn't load
    if (!deltaRestored) {
      final plainDesc = data['description']?.toString() ?? '';
      debugPrint('Falling back to plain description: $plainDesc');
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
    final savedData = prefs.getString('bon_plan_draft');

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
          'Vous avez un formulaire de bon plan non terminé. Voulez-vous continuer où vous vous êtes arrêté ?',
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
        'description_delta': jsonEncode(
          _descriptionQuillController.document.toDelta().toJson(),
        ),
        'category': _selectedCategory,
        'sub_category': _selectedSubCategory,
        'type': _selectedType,
        'available_at_name': _disponibleChezController.text,
        'link': _linkController.text,
        'site_web': _siteWebController.text,
        'prix_avant_reduction': _prixAvantReductionController.text,
        'prix_final': _prixFinalController.text,
        'discount_mode': _discountMode,
        'available_location_type': _selectedDisponibleLocation,
        'location': _locationController.text,
        'conditions': _conditionsController.text,
        'validity_type': _validityType,
        'valid_from': _validFrom?.toIso8601String(),
        'valid_until': _validUntil?.toIso8601String(),
      };

      await prefs.setString('bon_plan_draft', jsonEncode(formData));
    } catch (e) {
      debugPrint('Error saving form progress: $e');
    }
  }

  Future<void> _restoreFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('bon_plan_draft');

      if (savedData == null) return;

      final formData = jsonDecode(savedData) as Map<String, dynamic>;

      setState(() {
        _currentStep = formData['step'] ?? 0;
        _titleController.text = formData['title'] ?? '';
        _selectedCategory = formData['category'];
        _selectedSubCategory = formData['sub_category'];
        _selectedType = formData['type'];
        _disponibleChezController.text = formData['available_at_name'] ?? '';
        _linkController.text = formData['link'] ?? '';
        _siteWebController.text = formData['site_web'] ?? '';
        _prixAvantReductionController.text =
            formData['prix_avant_reduction'] ?? '';
        _prixFinalController.text = formData['prix_final'] ?? '';
        _discountMode = formData['discount_mode'] ?? 'percent';
        _selectedDisponibleLocation = formData['available_location_type'];
        _locationController.text = formData['location'] ?? '';
        _conditionsController.text = formData['conditions'] ?? '';
        _validityType = formData['validity_type'] ?? 'permanent';

        if (formData['valid_from'] != null) {
          _validFrom = DateTime.parse(formData['valid_from']);
        }
        if (formData['valid_until'] != null) {
          _validUntil = DateTime.parse(formData['valid_until']);
        }

        // Restore rich text description
        if (formData['description_delta'] != null) {
          try {
            final delta = jsonDecode(formData['description_delta']);
            _descriptionQuillController.document = Document.fromJson(delta);
          } catch (e) {
            debugPrint('Error restoring description: $e');
          }
        }
      });

      _recalculateDiscount();
    } catch (e) {
      debugPrint('Error restoring form data: $e');
    }
  }

  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bon_plan_draft');
    } catch (e) {
      debugPrint('Error clearing saved progress: $e');
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

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prix :',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPriceInput(
                controller: _prixAvantReductionController,
                label: "Prix avant réduction",
                focusNode: _prixAvantFocusNode,
                onChanged: (_) => _recalculateDiscount(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  _discountMode == 'percent'
                      ? '${_calculatedDiscount?.toStringAsFixed(2) ?? '--'} %'
                      : '${_calculatedDiscount?.toStringAsFixed(2) ?? '--'} €',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_prixAvantFocusNode.hasFocus) ...[
          const SizedBox(height: 8),
          _buildGreenHelperBox(
            'Indiquez le prix public avant toute réduction. Cela nous permet de calculer automatiquement le pourcentage d\'économie.',
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                value: 'percent',
                groupValue: _discountMode,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _discountMode = val;
                    _recalculateDiscount();
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF3AAE5E),
                title: const Text('%'),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                value: 'amount',
                groupValue: _discountMode,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _discountMode = val;
                    _recalculateDiscount();
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF3AAE5E),
                title: const Text('€'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Prix final',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 6),
        _buildPriceInput(
          controller: _prixFinalController,
          label: 'Prix final',
          focusNode: _prixFinalFocusNode,
          onChanged: (_) => _recalculateDiscount(),
        ),
        if (_prixFinalFocusNode.hasFocus) ...[
          const SizedBox(height: 8),
          _buildGreenHelperBox(
            'Saisissez le montant réellement payé après l\'offre. Ce prix apparaîtra dans la fiche visible par les utilisateurs.',
          ),
        ],
      ],
    );
  }

  Widget _buildPriceInput({
    required TextEditingController controller,
    required String label,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixText: '€',
          suffixStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      ),
    );
  }

  void _recalculateDiscount() {
    final prixAvant = _parsePrice(_prixAvantReductionController.text);
    final prixFinal = _parsePrice(_prixFinalController.text);

    if (prixAvant == null ||
        prixFinal == null ||
        prixAvant <= 0 ||
        prixFinal < 0) {
      setState(() => _calculatedDiscount = null);
      return;
    }

    double? value;
    if (_discountMode == 'percent') {
      final diff = prixAvant - prixFinal;
      value = diff <= 0 ? 0 : (diff / prixAvant) * 100;
    } else {
      value = prixAvant - prixFinal;
      if (value < 0) value = 0;
    }

    setState(
      () => _calculatedDiscount = double.parse(value!.toStringAsFixed(2)),
    );
  }

  double? _parsePrice(String text) {
    final sanitized = text.replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
        if (decoded['errors'] is Map && (decoded['errors'] as Map).isNotEmpty) {
          final first = (decoded['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<bool> _uploadMediaFiles(String bonPlanId) async {
    if (_selectedMediaFiles.isEmpty) return true;

    setState(() => _isUploadingMedia = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        _showSnack(
          'Session expirée. Veuillez vous reconnecter.',
          isError: true,
        );
        return false;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/bonplans/$bonPlanId/media');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      for (final file in _selectedMediaFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files[]',
              file.path!,
              filename: file.name,
            ),
          );
        } else if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'files[]',
              file.bytes!,
              filename: file.name ?? 'media',
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        setState(() => _selectedMediaFiles.clear());
        return true;
      }

      final message =
          _extractErrorMessage(responseBody) ??
          'Impossible d\'envoyer les médias (code ${streamedResponse.statusCode}).';
      _showSnack(message, isError: true);
      return false;
    } catch (_) {
      _showSnack(
        'Échec de l\'upload des médias. Veuillez réessayer.',
        isError: true,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _isMetaLoading = true;
      _metaError = null;
    });

    try {
      final categoriesFuture = _fetchDealCategories();
      final metaFuture = _apiClient.authenticatedGet('/bonplans/meta');

      final categoryResult = await categoriesFuture;
      final response = await metaFuture;
      final meta = response['data'] is Map ? response['data'] as Map : response;
      final typesRaw = meta['types'] ?? [];
      final locationsRaw = meta['location_options'] ?? [];

      final updatedCategories = List<String>.from(categoryResult.categories);
      final updatedSubCategories = <String, List<String>>{};
      categoryResult.subCategories.forEach((key, value) {
        updatedSubCategories[key] = List<String>.from(value);
      });

      final hasValidSelectedCategory =
          _selectedCategory != null &&
          updatedCategories.contains(_selectedCategory);
      final newAvailableSubCategories =
          hasValidSelectedCategory && _selectedCategory != null
          ? List<String>.from(
              updatedSubCategories[_selectedCategory] ?? const <String>[],
            )
          : <String>[];
      final hasValidSelectedSubCategory =
          hasValidSelectedCategory &&
          newAvailableSubCategories.contains(_selectedSubCategory);

      setState(() {
        _categorySubCategories = updatedSubCategories;
        _categories = updatedCategories;
        _types = _toStringList(typesRaw);
        _locationOptions = _toStringList(locationsRaw);
        _availableSubCategories = newAvailableSubCategories;

        if (!hasValidSelectedCategory) {
          _selectedCategory = null;
          _selectedSubCategory = null;
        } else if (!hasValidSelectedSubCategory) {
          _selectedSubCategory = null;
        }

        if (_selectedDisponibleLocation != null &&
            !_locationOptions.contains(_selectedDisponibleLocation)) {
          _selectedDisponibleLocation = null;
        }

        _isMetaLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _metaError = e.firstError;
        _isMetaLoading = false;
      });
    } catch (_) {
      setState(() {
        _metaError = 'Impossible de charger les données. Veuillez réessayer.';
        _isMetaLoading = false;
      });
    }
  }

  Future<_CategoryLoadResult> _fetchDealCategories() async {
    try {
      final response = await http.post(
        Uri.parse(_categoriesApiUrl),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: const {'Method': 'getByType', 'type': 'bons_plans'},
      );

      if (response.statusCode != 200) {
        throw ApiException(
          statusCode: response.statusCode,
          message:
              'Impossible de charger les catégories (code ${response.statusCode}).',
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
        final message =
            decoded['message']?.toString() ??
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

      final categories = <String>[];
      final subCategories = <String, List<String>>{};

      for (final category in mainList) {
        final label = category['label']?.toString();
        if (label == null || label.trim().isEmpty) {
          continue;
        }

        final parentId = category['id']?.toString();
        final subList = parentId != null ? subsMap[parentId] : null;
        final subLabels = <String>[];

        if (subList != null) {
          subList.sort(_compareCategoryMaps);
          for (final sub in subList) {
            final subLabel = sub['label']?.toString();
            if (subLabel == null || subLabel.trim().isEmpty) {
              continue;
            }
            subLabels.add(subLabel);
          }
        }

        categories.add(label);
        subCategories[label] = subLabels;
      }

      return _CategoryLoadResult(
        categories: categories,
        subCategories: subCategories,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        statusCode: 0,
        message: 'Impossible de récupérer les catégories.',
      );
    }
  }

  int _compareCategoryMaps(Map<String, dynamic> a, Map<String, dynamic> b) {
    final orderComparison = _parseOrder(
      a['order'],
    ).compareTo(_parseOrder(b['order']));
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

  List<String> _toStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toList();
    }
    return <String>[];
  }

  void _updateSubCategories(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedSubCategory = null;
      _availableSubCategories = category != null
          ? List<String>.from(
              _categorySubCategories[category] ?? const <String>[],
            )
          : <String>[];
    });
  }

  Future<void> _selectDate({required bool isStart}) async {
    final initialDate = isStart
        ? _validFrom ?? DateTime.now()
        : _validUntil ??
              _validFrom ??
              DateTime.now().add(const Duration(days: 1));
    final firstDate = DateTime.now().subtract(const Duration(days: 1));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isStart
          ? 'Sélectionnez la date de début'
          : 'Sélectionnez la date de fin',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF9800)),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _validFrom = picked;
        if (_validUntil != null && _validUntil!.isBefore(picked)) {
          _validUntil = picked;
        }
      } else {
        _validUntil = picked;
      }
    });
  }

  void _setValidityType(String type) {
    setState(() {
      _validityType = type;
      if (type == 'permanent') {
        _validFrom = null;
        _validUntil = null;
      }
    });
  }

  @override
  void dispose() {
    _prixAvantFocusNode.removeListener(_onPriceFocusChanged);
    _prixFinalFocusNode.removeListener(_onPriceFocusChanged);
    _prixAvantFocusNode.dispose();
    _prixFinalFocusNode.dispose();
    _titleController.dispose();
    _descriptionQuillController.dispose();
    _disponibleChezController.dispose();
    _linkController.dispose();
    _siteWebController.dispose();
    _prixAvantReductionController.dispose();
    _prixFinalController.dispose();
    _locationController.dispose();
    _conditionsController.dispose();
    super.dispose();
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
        if (_selectedCategory == null) {
          return 'Veuillez sélectionner une catégorie.';
        }
        if (_selectedSubCategory == null) {
          return 'Veuillez sélectionner une sous-catégorie.';
        }
        if (_selectedType == null) {
          return 'Veuillez choisir un type de bon plan.';
        }
        break;

      case 1: // Step 2: Lien (optional)
        break;

      case 2: // Step 3: Description
        if (_titleController.text.trim().length < 5) {
          return 'Le titre doit contenir au moins 5 caractères.';
        }
        if (_descriptionQuillController.document.toPlainText().trim().length <
            20) {
          return 'La description doit contenir au moins 20 caractères.';
        }
        if (_disponibleChezController.text.trim().isEmpty) {
          return 'Indiquez chez qui le bon plan est disponible.';
        }
        if (_selectedDisponibleLocation == null) {
          return 'Précisez où est disponible cette offre.';
        }
        break;

      case 3: // Step 4: Prix et détails
        if (_selectedType != 'Gratuit') {
          final prixAvant = _parsePrice(_prixAvantReductionController.text);
          final prixFinal = _parsePrice(_prixFinalController.text);
          if (prixAvant != null && prixFinal != null && prixFinal > prixAvant) {
            return 'Le prix final doit être inférieur ou égal au prix avant réduction.';
          }
        }
        if (_validityType == 'dates') {
          if (_validFrom == null || _validUntil == null) {
            return 'Sélectionnez une date de début et une date de fin.';
          }
          if (_validUntil!.isBefore(_validFrom!)) {
            return 'La date de fin doit être postérieure à la date de début.';
          }
        }
        if (!_isOnlineOnly) {
          if (_locationController.text.trim().isEmpty && !_touteFrance) {
            return 'Renseignez une ville ou activez "Toute la France".';
          }
          if (!_moyenRetraitMagasin &&
              !_moyenRetraitEnLigne &&
              !_moyenRetraitDrive) {
            return 'Sélectionnez au moins un moyen de retrait.';
          }
        }
        break;

      case 4: // Step 5: Médias (optional)
        break;
    }
    return null;
  }

  String? _validateForm() {
    if (_selectedCategory == null) {
      return 'Veuillez sélectionner une catégorie.';
    }
    if (_selectedSubCategory == null) {
      return 'Veuillez sélectionner une sous-catégorie.';
    }
    if (_selectedType == null) {
      return 'Veuillez choisir un type de bon plan.';
    }
    if (_titleController.text.trim().length < 5) {
      return 'Le titre doit contenir au moins 5 caractères.';
    }
    if (_descriptionQuillController.document.toPlainText().trim().length < 20) {
      return 'La description doit contenir au moins 20 caractères.';
    }
    if (_disponibleChezController.text.trim().isEmpty) {
      return 'Indiquez chez qui le bon plan est disponible.';
    }
    if (_selectedDisponibleLocation == null) {
      return 'Précisez où est disponible cette offre.';
    }
    final prixAvant = _parsePrice(_prixAvantReductionController.text);
    final prixFinal = _parsePrice(_prixFinalController.text);
    if (prixAvant != null && prixFinal != null && prixFinal > prixAvant) {
      return 'Le prix final doit être inférieur ou égal au prix avant réduction.';
    }
    if (_validityType == 'dates') {
      if (_validFrom == null || _validUntil == null) {
        return 'Sélectionnez une date de début et une date de fin.';
      }
      if (_validUntil!.isBefore(_validFrom!)) {
        return 'La date de fin doit être postérieure à la date de début.';
      }
    }
    // if (_locationController.text.trim().isEmpty && !_touteFrance) {
    //   return 'Renseignez une ville ou activez "Toute la France".';
    // }
    if (!_touteFrance) {
      return 'Renseignez une ville ou activez "Toute la France".';
    }
    if (!_moyenRetraitMagasin && !_moyenRetraitEnLigne && !_moyenRetraitDrive) {
      return 'Sélectionnez au moins un moyen de retrait.';
    }
    return null;
  }

  Future<void> _submitBonPlan() async {
    final validationError = _validateForm();
    if (validationError != null) {
      _showSnack(validationError, isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final title = _titleController.text.trim();
    final descriptionDelta = _descriptionQuillController.document
        .toDelta()
        .toJson();
    final descriptionPlainText = _descriptionQuillController.document
        .toPlainText()
        .trim();
    final disponibleChez = _disponibleChezController.text.trim();
    final link = _linkController.text.trim();
    final brandWebsite = _siteWebController.text.trim();
    final location = _locationController.text.trim();
    final conditions = _conditionsController.text.trim();
    final prixAvant = _parsePrice(_prixAvantReductionController.text);
    final prixFinal = _parsePrice(_prixFinalController.text);

    final payload = {
      'category': _selectedCategory,
      'sub_category': _selectedSubCategory,
      'type': _selectedType,
      'title': title,
      'description': descriptionPlainText,
      'description_delta': descriptionDelta,
      'available_at_name': disponibleChez,
      'available_location_type': _selectedDisponibleLocation,
      'link': link.isEmpty ? null : link,
      'brand_website': brandWebsite.isEmpty ? null : brandWebsite,
      'validity_type': _validityType,
      'valid_from': _validFrom?.toIso8601String(),
      'valid_until': _validUntil?.toIso8601String(),
      'location_search': location,
      'nationwide': _touteFrance,
      'show_google_location': _afficherGoogleLocation,
      'pickup_methods': {
        'in_store': _moyenRetraitMagasin,
        'delivery': _moyenRetraitEnLigne,
        'drive': _moyenRetraitDrive,
      },
      'prix_avant_reduction': prixAvant,
      'prix_final': prixFinal,
      'discount_type': _discountMode,
      'discount_value': _calculatedDiscount,
      'conditions': conditions.isEmpty ? null : conditions,
      'accept_messages': _acceptMessages,
      'status': 'published',
    };

    try {
      final Map<String, dynamic> response;
      if (_isEditMode) {
        response = await _apiClient.authenticatedPut(
          '/bonplans/${widget.bonPlanId}',
          body: payload,
        );
      } else {
        response = await _apiClient.authenticatedPost(
          '/bonplans',
          body: payload,
        );
      }
      final bonPlanData = response['data'] is Map
          ? response['data'] as Map
          : response;
      final bonPlanId = bonPlanData['id']?.toString() ?? widget.bonPlanId;

      bool mediaSuccess = true;
      if (_selectedMediaFiles.isNotEmpty && bonPlanId != null) {
        mediaSuccess = await _uploadMediaFiles(bonPlanId);
      }

      if (!mounted) return;

      if (!mediaSuccess) {
        _showSnack(
          _isEditMode
              ? 'Bon plan modifié mais l\'upload des médias a échoué.'
              : 'Bon plan créé mais l\'upload des médias a échoué. Réessayez depuis vos brouillons.',
          isError: true,
        );
      }

      // Clear saved progress after successful submission
      if (!_isEditMode) {
        await _clearSavedProgress();
      }

      _showSuccessDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnack(e.firstError, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Impossible de publier le bon plan. Veuillez réessayer.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // pop edit/create screen
                    if (_isEditMode) {
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
                _isEditMode ? 'Bon plan modifié' : 'Bon plan publié',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3AAE5E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isEditMode
                    ? 'Votre bon plan a été mis à jour avec succès'
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

  Widget _buildSelectedMediaList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _selectedMediaFiles.length,
      itemBuilder: (context, index) {
        return _buildPhotoPreviewCard(_selectedMediaFiles[index], index);
      },
    );
  }

  Widget _buildExistingMediaReviewList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _existingMediaUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            _existingMediaUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF5F5F5),
              child: const Center(
                child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
              ),
            ),
          ),
        );
      },
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

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov'],
        withData: true,
      );

      if (result == null) return;

      setState(() {
        _selectedMediaFiles.addAll(result.files);
      });
    } catch (_) {
      _showSnack('Impossible d\'accéder aux fichiers.', isError: true);
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaFiles.removeAt(index);
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, color: Color(0xFFFF9800), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value != null ? _formatSingleDate(value) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null
                      ? const Color(0xFF424242)
                      : Colors.grey[500],
                  fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatSingleDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Offre avec dates';
    return '${_formatSingleDate(start)} - ${_formatSingleDate(end)}';
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
                      _isEditMode
                          ? 'Modifier le bon plan'
                          : 'Créer un bon plan',
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
                      ? 'Modifiez les informations de votre bon plan'
                      : 'Partagez vos meilleures trouvailles avec la communauté',
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
        value: (_currentStep + 1) / (_totalSteps + 1),
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
        minHeight: 6,
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_isMetaLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9800)),
        ),
      );
    }

    if (_metaError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 40),
            const SizedBox(height: 12),
            Text(
              _metaError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMetadata,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
        return _buildStep4PrixDetails();
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
                'Ajoutez des photos de votre bon plan pour le rendre plus attractif et inspirer confiance.',
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
            itemCount:
                _existingMediaUrls.length + _selectedMediaFiles.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddPhotoButton();
              }
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
    final isCoverPhoto = index == 0 && _existingMediaUrls.isEmpty;

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
    final isCoverPhoto = index == 0 && _selectedMediaFiles.isEmpty;

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
              onTap: () => _removeExistingMedia(index),
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

  void _removeExistingMedia(int index) {
    setState(() {
      _existingMediaUrls.removeAt(index);
    });
  }

  // ─── STEP 1: Informations ───
  Widget _buildStep1Informations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.info_outline,
          title: 'Informations',
          children: [
            _buildDropdownField(
              label: 'Choisissez la catégorie*',
              value: _selectedCategory,
              items: _categories,
              onChanged: _updateSubCategories,
              hint: _buildRequiredHint('Choisissez la catégorie'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Choisissez la sous-catégorie*',
              value: _selectedSubCategory,
              items: _availableSubCategories,
              onChanged: _selectedCategory != null
                  ? (val) => setState(() => _selectedSubCategory = val)
                  : null,
              hint: _buildRequiredHint('Choisissez la sous-catégorie'),
              backgroundColor: const Color(0xFFF9FAFB),
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: "De quel type de bon plan s'agit-il?*",
              value: _selectedType,
              items: _types,
              onChanged: _handleTypeChanged,
              hint: _buildRequiredHint("De quel type de bon plan s'agit-il?"),
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
              "Collez le lien de la page du bon plan. Nous l'utiliserons pour récupérer automatiquement les informations et pré-remplir votre annonce.",
          children: [
            _buildTextField(
              label: 'Ajouter un lien',
              controller: _linkController,
              fieldKey: 'link',
              helperText:
                  'Le lien permettra d\'extraire automatiquement le titre, la description, les prix et autres détails du bon plan pour faciliter la création de votre annonce.',
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
              label: 'Quel est votre titre?*',
              controller: _titleController,
              fieldKey: 'title',
              helperText:
                  'Saisissez un titre accrocheur et descriptif pour votre bon plan (ex: "Réduction de 50% sur tous les produits").',
            ),
            const SizedBox(height: 12),
            _buildRichTextEditor(
              label: 'Décrivez votre offre*',
              controller: _descriptionQuillController,
              fieldKey: 'description',
              helperText:
                  'Décrivez en détail votre bon plan. Utilisez les outils de mise en forme pour mettre en évidence les informations importantes.',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Bon plan disponible chez?*',
              controller: _disponibleChezController,
              fieldKey: 'disponible_chez',
              helperText:
                  'Indiquez le nom de l\'enseigne ou du commerce où ce bon plan est disponible.',
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Ou est disponible cette offre*',
              value: _selectedDisponibleLocation,
              items: _locationOptions,
              onChanged: (val) =>
                  setState(() => _selectedDisponibleLocation = val),
              hint: _buildRequiredHint('Ou est disponible cette offre'),
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

  // ─── STEP 4: Prix et détails ───
  Widget _buildStep4PrixDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormCard(
          icon: Icons.location_on_outlined,
          title: 'Localisation et validité',
          children: [
            if (!_isFreeType) ...[
              _buildPriceSection(),
              const SizedBox(height: 20),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Cette offre est gratuite, aucune information tarifaire n\'est requise.',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Site web de l'enseigne
            _buildTextField(
              label: 'Site web de l\'enseigne',
              controller: _siteWebController,
              keyboardType: TextInputType.url,
              fieldKey: 'site_web',
              helperText:
                  'Saisissez l\'adresse du site web officiel de l\'enseigne.',
            ),
            const SizedBox(height: 16),

            // Validity type radio buttons
            const Text(
              'Quand cette offre est-elle valide ?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text(
                'Offre permanente',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Aucune date, toute l\'année',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: 'permanent',
              groupValue: _validityType,
              onChanged: (val) => _setValidityType(val!),
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF3AAE5E),
            ),
            RadioListTile<String>(
              title: const Text(
                'Offre avec dates',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Définir une période de validité',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              value: 'dates',
              groupValue: _validityType,
              onChanged: (val) => _setValidityType(val!),
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF3AAE5E),
            ),
            if (_validityType == 'dates') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Date de début',
                      value: _validFrom,
                      onTap: () => _selectDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: 'Date de fin',
                      value: _validUntil,
                      onTap: () => _selectDate(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Location section (hidden when 'En ligne' is selected)
            if (!_isOnlineOnly) ...[
              const Text(
                'Lieu :',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                label: 'Rechercher par ville ou code postal...',
                controller: _locationController,
                prefixIcon: Icons.search,
                fieldKey: 'location',
                helperText:
                    'Entrez la ville ou le code postal où ce bon plan est valable.',
                enabled: !_touteFrance,
                onChanged: (value) {
                  if (value.trim().isNotEmpty && _touteFrance) {
                    setState(() => _touteFrance = false);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Toute la France toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Toute la France',
                      style: TextStyle(fontSize: 13, color: Color(0xFF424242)),
                    ),
                    Switch(
                      value: _touteFrance,
                      onChanged: _locationController.text.trim().isEmpty
                          ? (val) {
                              setState(() {
                                _touteFrance = val;
                                if (val) {
                                  _locationController.clear();
                                }
                              });
                            }
                          : null,
                      activeColor: const Color(0xFF3AAE5E),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Google location toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Afficher la localisation Google sur l\'annonce.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    Switch(
                      value: _afficherGoogleLocation,
                      onChanged: (val) =>
                          setState(() => _afficherGoogleLocation = val),
                      activeColor: const Color(0xFF3AAE5E),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Moyen de retrait checkboxes (hidden when 'En ligne')
              const Text(
                'Moyen de retrait :',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            'En magasin',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _moyenRetraitMagasin,
                          onChanged: (val) => setState(
                            () => _moyenRetraitMagasin = val ?? false,
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF3AAE5E),
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text(
                            'En livraison',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: _moyenRetraitEnLigne,
                          onChanged: (val) => setState(
                            () => _moyenRetraitEnLigne = val ?? false,
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF3AAE5E),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    title: const Text('Drive', style: TextStyle(fontSize: 13)),
                    value: _moyenRetraitDrive,
                    onChanged: (val) =>
                        setState(() => _moyenRetraitDrive = val ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF3AAE5E),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Livraison section (shown when 'En ligne' is selected)
              const Text(
                'Livraison :',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text(
                  'Livraison gratuite',
                  style: TextStyle(fontSize: 13),
                ),
                value: 'free',
                groupValue: _shippingOption,
                onChanged: (val) {
                  setState(() {
                    _shippingOption = val!;
                    if (val == 'free') {
                      _shippingCostController.clear();
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF3AAE5E),
              ),
              RadioListTile<String>(
                title: const Text(
                  'Frais de port',
                  style: TextStyle(fontSize: 13),
                ),
                value: 'paid',
                groupValue: _shippingOption,
                onChanged: (val) => setState(() => _shippingOption = val!),
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF3AAE5E),
              ),
              if (_shippingOption == 'paid') ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _shippingCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Montant des frais de port',
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                      suffixText: '€',
                      suffixStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424242),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),

            // Conditions field
            const Text(
              'Conditions pour profiter de cette offre :',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              label: 'ex : nouveaux membres uniquement',
              controller: _conditionsController,
              maxLines: 3,
              fieldKey: 'conditions',
              helperText:
                  'Précisez les conditions d\'utilisation du bon plan (ex: valable pour les nouveaux clients uniquement).',
            ),
            const SizedBox(height: 8),
            Text(
              'Facultatif',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                : 'Vérifiez votre annonce',
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
                ? 'Relisez les informations avant de mettre à jour votre bon plan'
                : 'Relisez les informations avant de publier votre bon plan',
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
            _buildReviewRow('Catégorie', _selectedCategory ?? '-'),
            _buildReviewRow('Sous-catégorie', _selectedSubCategory ?? '-'),
            _buildReviewRow('Type', _selectedType ?? '-'),
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
              _linkController.text.isEmpty
                  ? 'Aucun lien'
                  : _linkController.text,
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
              'Disponible chez',
              _disponibleChezController.text.isEmpty
                  ? '-'
                  : _disponibleChezController.text,
            ),
            _buildReviewRow(
              'Où est disponible',
              _selectedDisponibleLocation ?? '-',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 4: Prix et détails
        _buildReviewSection(
          title: 'Étape 4 - Prix et détails',
          onEdit: () => setState(() => _currentStep = 3),
          rows: [
            _buildReviewRow(
              'Prix avant réduction',
              _prixAvantReductionController.text.isEmpty
                  ? '-'
                  : '${_prixAvantReductionController.text} €',
            ),
            _buildReviewRow(
              'Prix final',
              _prixFinalController.text.isEmpty
                  ? '-'
                  : '${_prixFinalController.text} €',
            ),
            _buildReviewRow(
              'Réduction',
              _calculatedDiscount != null
                  ? _discountMode == 'percent'
                        ? '${_calculatedDiscount!.toStringAsFixed(2)} %'
                        : '${_calculatedDiscount!.toStringAsFixed(2)} €'
                  : '-',
            ),
            _buildReviewRow(
              'Site web de l\'enseigne',
              _siteWebController.text.isEmpty ? '-' : _siteWebController.text,
            ),
            _buildReviewRow(
              'Validité',
              _validityType == 'permanent'
                  ? 'Offre permanente'
                  : _formatDateRange(_validFrom, _validUntil),
            ),
            _buildReviewRow(
              'Lieu',
              _locationController.text.isEmpty ? '-' : _locationController.text,
            ),
            _buildReviewRow('Toute la France', _touteFrance ? 'Oui' : 'Non'),
            _buildReviewRow(
              'Afficher localisation Google',
              _afficherGoogleLocation ? 'Oui' : 'Non',
            ),
            _buildReviewRow(
              'Moyen de retrait',
              [
                    if (_moyenRetraitMagasin) 'Magasin',
                    if (_moyenRetraitEnLigne) 'Livraison',
                    if (_moyenRetraitDrive) 'Drive',
                  ].isEmpty
                  ? '-'
                  : [
                      if (_moyenRetraitMagasin) 'Magasin',
                      if (_moyenRetraitEnLigne) 'Livraison',
                      if (_moyenRetraitDrive) 'Drive',
                    ].join(', '),
            ),
            if (_conditionsController.text.isNotEmpty)
              _buildReviewRow('Conditions', _conditionsController.text),
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
              (_existingMediaUrls.isEmpty && _selectedMediaFiles.isEmpty)
                  ? 'Aucun média sélectionné'
                  : '${_existingMediaUrls.length + _selectedMediaFiles.length} fichier(s)',
            ),
          ],
        ),
        if (_existingMediaUrls.isNotEmpty ||
            _selectedMediaFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (_existingMediaUrls.isNotEmpty) _buildExistingMediaReviewList(),
          if (_selectedMediaFiles.isNotEmpty) _buildSelectedMediaList(),
        ],
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
                'Accepter de recevoir des messages à propos de ce bon plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Les intéressés pourront vous écrire pour en savoir plus sur les conditions ou la disponibilité de votre bon plan.',
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
            onPressed: (_isSubmitting || _isUploadingMedia)
                ? null
                : _submitBonPlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: (_isSubmitting || _isUploadingMedia)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isUploadingMedia
                            ? 'Upload des médias...'
                            : 'Publication en cours...',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _isEditMode
                        ? 'Mettre à jour le bon plan'
                        : 'Publier le bon plan',
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

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF3AAE5E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildUploadButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
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
            onTap: onTap,
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
    required ValueChanged<String?>? onChanged,
    Widget? hint,
    Color? backgroundColor,
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
                child: Text(item, style: const TextStyle(fontSize: 13)),
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
    int? maxLines = 1,
    int? minLines,
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
            minLines: minLines,
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
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.grey[400])
                  : null,
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
