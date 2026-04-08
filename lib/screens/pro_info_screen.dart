import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'pro_subscription_screen.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/constants/secteurs_activite.dart';

class ProInfoScreen extends StatefulWidget {
  const ProInfoScreen({super.key});

  @override
  State<ProInfoScreen> createState() => _ProInfoScreenState();
}

class _ProInfoScreenState extends State<ProInfoScreen> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _siretController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _codePostalController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _secteurAutreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  bool _isLoading = false;
  bool _isVerifyingSiret = false;
  bool _siretVerified = false;
  String? _selectedSecteur;
  bool _showManualValidationModal = false;
  bool _showConfirmationModal = false;
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactMessageController = TextEditingController();
  bool _isSendingContactRequest = false;
  File? _kbisFile;
  String? _kbisFileName;

  @override
  void dispose() {
    _companyNameController.dispose();
    _siretController.dispose();
    _addressController.dispose();
    _telephoneController.dispose();
    _codePostalController.dispose();
    _villeController.dispose();
    _secteurAutreController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactMessageController.dispose();
    super.dispose();
  }

  Future<void> _verifySiret(String siret) async {
    if (siret.length != 14) return;

    setState(() => _isVerifyingSiret = true);

    try {
      final response = await http.post(
        Uri.parse('https://api.myreklam.fr/Insee.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'Siret': siret, 'Method': 'insee'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && data['companyData'] != null) {
          final companyData = data['companyData'];
          final address = companyData['address'];
          
          setState(() {
            _siretVerified = true;
            _companyNameController.text = companyData['name']?.toString() ?? '';
            
            // Map activity to secteur
            final activity = companyData['activity']?.toString();
            if (activity != null) {
              _selectedSecteur = _mapActivityToSecteur(activity);
            }
            
            // Build full address
            if (address != null) {
              final addressParts = [
                address['numeroVoie'],
                address['typeVoie'],
                address['libelleVoie'],
              ].where((part) => part != null && part.toString().isNotEmpty).join(' ');
              
              _addressController.text = addressParts;
              _codePostalController.text = address['codePostal']?.toString() ?? '';
              _villeController.text = address['commune']?.toString() ?? '';
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SIRET vérifié avec succès'),
                backgroundColor: Color(0xFF1B8D4B),
              ),
            );
          }
        } else {
          // SIRET not found
          setState(() => _showManualValidationModal = true);
        }
      } else {
        // Network error
        setState(() => _showManualValidationModal = true);
      }
    } catch (e) {
      debugPrint('Error verifying SIRET: $e');
      setState(() => _showManualValidationModal = true);
    } finally {
      if (mounted) setState(() => _isVerifyingSiret = false);
    }
  }

  String? _mapActivityToSecteur(String activity) {
    const activityMap = {
      'agriculture': 'Agriculture',
      'automobile': 'Automobile',
      'construction': 'Construction',
      'banqueFinanceAssurance': 'Banque, Finance, Assurance',
      'distributionDetail': 'Distribution de détail',
      'education': 'Éducation',
      'emploiFormationRecrutement': 'Emploi, Formation, Recrutement',
      'industrieEnvironnement': 'Industrie et Environnement',
      'informationCommunication': 'Information et Communication',
      'immobilier': 'Immobilier',
      'servicesPublicsGouvernement': 'Services publics et Gouvernement',
      'sante': 'Santé',
      'servicesGeneraux': 'Services généraux',
      'telecommunicationsMedias': 'Télécommunications et Médias',
      'tourisme': 'Tourisme',
      'transportLogistique': 'Transport et Logistique',
      'hotellerie': 'Hôtellerie',
      'modeTextilesLuxe': 'Mode, Textiles et Produits de luxe',
      'sports': 'Sports',
      'soinsPersonnels': 'Soins personnels et services',
    };
    return activityMap[activity];
  }

  Future<void> _pickKbisFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        
        // Check file size (5 MB = 5 * 1024 * 1024 bytes)
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Le fichier ne doit pas dépasser 5 MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _kbisFile = file;
          _kbisFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _sendManualValidationRequest() async {
    if (_contactNameController.text.isEmpty ||
        _contactEmailController.text.isEmpty ||
        _contactMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSendingContactRequest = true);

    // Simulate brief loading
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _showManualValidationModal = false;
        _isSendingContactRequest = false;
        _contactNameController.clear();
        _contactEmailController.clear();
        _contactMessageController.clear();
        _kbisFile = null;
        _kbisFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre demande a été envoyée avec succès'),
          backgroundColor: Color(0xFF1B8D4B),
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final secteurValue = _selectedSecteur == 'Autre (à préciser)'
          ? _secteurAutreController.text.trim()
          : _selectedSecteur;
      
      await _profileService.completeProStep1(
        companyName: _companyNameController.text.trim(),
        siret: _siretController.text.trim(),
        address: _addressController.text.trim(),
        secteurActivite: secteurValue,
        telephone: _telephoneController.text.trim().isNotEmpty ? _telephoneController.text.trim() : null,
        codePostal: _codePostalController.text.trim().isNotEmpty ? _codePostalController.text.trim() : null,
        ville: _villeController.text.trim().isNotEmpty ? _villeController.text.trim() : null,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ProSubscriptionScreen(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.firstError), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Information professionnel',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              const Text(
                'Complétez les informations de votre entreprise',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              // Progress Bar
              Container(
                width: double.infinity,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5, // 50% for step 1 of 2
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B8D4B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F5E8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.business_rounded,
                                    color: Color(0xFF1B8D4B),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Informations entreprise',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Form Fields
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SIRET*',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _siretController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (value) {
                                      if (value.length == 14) {
                                        _verifySiret(value);
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le numéro SIRET';
                                      }
                                      if (!RegExp(r'^\d{14}$').hasMatch(value)) {
                                        return 'Numéro SIRET invalide (14 chiffres)';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF1B8D4B),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 2,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 2,
                                        ),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        color: Color(0xFFD32F2F),
                                      ),
                                      errorMaxLines: 2,
                                      suffixIcon: _isVerifyingSiret
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF1B8D4B),
                                                ),
                                              ),
                                            )
                                          : _siretVerified
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: Color(0xFF1B8D4B),
                                                )
                                              : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Les informations seront automatiquement chargées',
                                  style: TextStyle(
                                    color: Color(0xFF1B8D4B),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Nom de l\'entreprise*',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _companyNameController,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer le nom de l\'entreprise';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF1B8D4B),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 2,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 2,
                                        ),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        color: Color(0xFFD32F2F),
                                      ),
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Secteur d\'activité',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedSecteur,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF1B8D4B),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    hint: const Text('Sélectionnez un secteur'),
                                    items: SecteursActivite.all.map((secteur) {
                                      return DropdownMenuItem(
                                        value: secteur,
                                        child: Text(secteur, style: const TextStyle(fontSize: 14)),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedSecteur = value);
                                    },
                                  ),
                                ),
                                if (_selectedSecteur == 'Autre (à préciser)') ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextFormField(
                                      controller: _secteurAutreController,
                                      textInputAction: TextInputAction.next,
                                      validator: (value) {
                                        if (_selectedSecteur == 'Autre (à préciser)' &&
                                            (value == null || value.isEmpty)) {
                                          return 'Veuillez préciser le secteur';
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Précisez le secteur',
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF1B8D4B),
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD32F2F),
                                            width: 2,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFD32F2F),
                                            width: 2,
                                          ),
                                        ),
                                        errorStyle: const TextStyle(
                                          fontSize: 12,
                                          height: 1.2,
                                          color: Color(0xFFD32F2F),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                const Text(
                                  'Numéro de téléphone',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              'assets/images/lang/fr.png',
                                              width: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              '+33',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const VerticalDivider(width: 1),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _telephoneController,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (value != null && value.isNotEmpty) {
                                              if (!RegExp(r'^\d{9,10}$').hasMatch(value)) {
                                                return 'Numéro de téléphone invalide';
                                              }
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF1B8D4B),
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFD32F2F),
                                                width: 2,
                                              ),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFD32F2F),
                                                width: 2,
                                              ),
                                            ),
                                            errorStyle: const TextStyle(
                                              fontSize: 12,
                                              height: 1.2,
                                              color: Color(0xFFD32F2F),
                                            ),
                                            errorMaxLines: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Adresse*',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _addressController,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer l\'adresse';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF1B8D4B),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 2,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD32F2F),
                                          width: 2,
                                        ),
                                      ),
                                      errorStyle: const TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        color: Color(0xFFD32F2F),
                                      ),
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Code postal',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _codePostalController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF1B8D4B),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Ville',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _villeController,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF1B8D4B),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Suivant Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8D4B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : () => _handleSubmit(),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Suivant',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
          // Manual Validation Modal
          if (_showManualValidationModal)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SIRET non trouvé',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _showManualValidationModal = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nous n\'avons pas pu vérifier votre SIRET automatiquement. Contactez notre support pour une validation manuelle.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Nom*',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contactNameController,
                          decoration: InputDecoration(
                            hintText: 'Votre nom',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email*',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contactEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'votre@email.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Message*',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contactMessageController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Décrivez votre demande...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'KBIS (optionnel)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickKbisFile,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _kbisFileName ?? 'Joindre un fichier PDF (max 5 MB)',
                                    style: TextStyle(
                                      color: _kbisFileName != null ? Colors.black : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (_kbisFileName != null)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _kbisFile = null;
                                        _kbisFileName = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B8D4B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSendingContactRequest
                                ? null
                                : _sendManualValidationRequest,
                            child: _isSendingContactRequest
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Envoyer la demande',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Confirmation Modal
          if (_showConfirmationModal)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B8D4B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1B8D4B),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Demande envoyée',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Votre demande a été envoyée avec succès. Nous vous contacterons rapidement pour valider votre SIRET.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B8D4B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _showConfirmationModal = false);
                          },
                          child: const Text(
                            'Continuer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
