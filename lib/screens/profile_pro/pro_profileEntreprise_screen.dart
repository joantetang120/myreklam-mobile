import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/constants/secteurs_activite.dart';

class ProProfileEntrepriseScreen extends StatefulWidget {
  const ProProfileEntrepriseScreen({super.key});

  @override
  State<ProProfileEntrepriseScreen> createState() =>
      _ProProfileEntrepriseScreenState();
}

class _ProProfileEntrepriseScreenState extends State<ProProfileEntrepriseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();
  bool _isLoading = true;

  // Controllers pour les champs
  final TextEditingController _nomSocieteController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _codePostalController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _paysController = TextEditingController();
  final TextEditingController _presentationController = TextEditingController();

  // Controllers pour les réseaux sociaux
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();

  String? _selectedSecteur;
  String? _bannerUrl;
  List<String> _gallery = [];
  bool _isUploadingBanner = false;
  bool _isUploadingGallery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _profileService.getProfile();
      if (!mounted) return;

      // Debug: Log the full profile response
      print('📋 Profile response: ${response.keys}');
      if (response['profile'] != null) {
        print('📋 Profile data: ${response['profile'].keys}');
        print('📋 secteur_activite value: ${response['profile']['secteur_activite']}');
      }

      if (response['profile'] != null) {
        final profile = response['profile'];
        setState(() {
          _nomSocieteController.text = profile['company_name'] ?? '';
          _telephoneController.text = profile['telephone'] ?? '';
          if (profile['contact_email'] != null &&
              profile['contact_email'].isNotEmpty) {
            _emailController.text = profile['contact_email'];
          } else {
            _emailController.text = response['user']['email'] ?? '';
          }
          _adresseController.text = profile['address'] ?? '';
          _codePostalController.text = profile['code_postal'] ?? '';
          _villeController.text = profile['ville'] ?? '';
          _paysController.text = profile['pays'] ?? '';
          _presentationController.text = profile['presentation'] ?? '';
          
          // Only set secteur if it exists in the new list
          final savedSecteur = profile['secteur_activite'];
          if (savedSecteur != null && 
              savedSecteur.toString().isNotEmpty &&
              SecteursActivite.all.contains(savedSecteur)) {
            _selectedSecteur = savedSecteur;
          }

          // Load banner and gallery
          _bannerUrl = profile['banner_url'];
          if (profile['gallery'] != null) {
            _gallery = List<String>.from(profile['gallery']);
          }

          if (profile['social_links'] != null) {
            final links = profile['social_links'];
            _facebookController.text = links['facebook'] ?? '';
            _instagramController.text = links['instagram'] ?? '';
            _linkedinController.text = links['linkedin'] ?? '';
            _youtubeController.text = links['youtube'] ?? '';
            _snapchatController.text = links['snapchat'] ?? '';
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomSocieteController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _codePostalController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    _presentationController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _youtubeController.dispose();
    _snapchatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E9B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil entreprise',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                // TabBar
                Container(
                  margin: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF8A40).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF666666),
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    labelPadding: EdgeInsets.zero,
                    indicator: BoxDecoration(
                      color: const Color(0xFFEF8A40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    tabs: const [
                      Tab(text: 'Informations générales'),
                      Tab(text: 'Medias'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInformationsGeneralesTab(),
                      _buildMediasTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== ONGLET 1: INFORMATIONS GÉNÉRALES ====================
  Widget _buildInformationsGeneralesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Informations de l'entreprise
          _buildSectionCard(
            icon: Icons.business_outlined,
            title: 'Informations de l\'entreprise',
            child: Column(
              children: [
                _buildLabeledTextField(
                  icon: Icons.business_outlined,
                  label: 'Nom de la société',
                  controller: _nomSocieteController,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  icon: Icons.category_outlined,
                  label: 'Secteur d\'activité',
                  value: _selectedSecteur,
                  items: SecteursActivite.all,
                  onChanged: (val) => setState(() => _selectedSecteur = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Coordonnés
          _buildSectionCard(
            icon: Icons.mail_outline,
            title: 'Coordonnés',
            child: Column(
              children: [
                _buildLabeledTextField(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  controller: _telephoneController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  controller: _emailController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Adresse
          _buildSectionCard(
            icon: Icons.location_on_outlined,
            title: 'Adresse',
            child: Column(
              children: [
                _buildLabeledTextField(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse complète',
                  controller: _adresseController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.markunread_mailbox_outlined,
                  label: 'Code postal',
                  controller: _codePostalController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.location_city_outlined,
                  label: 'Ville',
                  controller: _villeController,
                ),
                
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Presentation
          _buildSectionCard(
            icon: Icons.description_outlined,
            title: 'Presentation (Qui sommes nous ?)',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _presentationController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Décrivez votre entreprise...',
                ),
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Enregistrer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Enregistrer les modifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF8A40),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== ONGLET 2: MEDIAS ====================
  Widget _buildMediasTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Réseaux sociaux
          _buildSectionCard(
            icon: Icons.share_outlined,
            title: 'Réseaux sociaux',
            child: Column(
              children: [
                _buildSocialField(
                  iconWidget: const Icon(
                    Icons.facebook,
                    color: Color(0xFF1877F2),
                    size: 20,
                  ),
                  label: 'facebook',
                  controller: _facebookController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.squareInstagram,
                    color: Color(0xFF0077B5),
                    size: 20,
                  ),
                  label: 'instagram',
                  controller: _instagramController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.linkedin,
                    color: Color(0xFF0077B5),
                    size: 20,
                  ),
                  label: 'Linkedin',
                  controller: _linkedinController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.youtube,
                    color: Color(0xFFFF0000),
                    size: 20,
                  ),
                  label: 'Youtube',
                  controller: _youtubeController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.snapchat,
                    color: Color(0xFFFFFC00),
                    size: 20,
                  ),
                  label: 'Snapchat',
                  controller: _snapchatController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Bannière de l'entreprise
          _buildSectionCard(
            icon: Icons.image_outlined,
            title: 'Bannière de l\'entreprise',
            child: Column(
              children: [
                if (_bannerUrl != null && _bannerUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _buildImageUrl(_bannerUrl),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildUploadButton(
                  label: _bannerUrl != null && _bannerUrl!.isNotEmpty
                      ? 'Changer la bannière'
                      : 'Importer une bannière',
                  color: const Color(0xFF2E9B5B),
                  onTap: _pickAndUploadBanner,
                  isLoading: _isUploadingBanner,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Galerie de medias
          _buildSectionCard(
            icon: Icons.photo_library_outlined,
            title: 'Galerie de medias',
            child: Column(
              children: [
                if (_gallery.isNotEmpty) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _gallery.length,
                    itemBuilder: (context, index) {
                      return _buildGalleryItem(_gallery[index], index);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _buildUploadButton(
                  label: 'Ajouter un media',
                  color: const Color(0xFF2E9B5B),
                  onTap: _showMediaPickerChoice,
                  isLoading: _isUploadingGallery,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Enregistrer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Enregistrer les modifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF8A40),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== WIDGETS HELPERS ====================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(-2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2E9B5B)),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('', style: TextStyle(color: Colors.grey[400])),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialField({
    required Widget iconWidget,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2E9B5B)),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadBanner() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    // Verify file exists and is readable
    final originalFile = File(pickedFile.path);
    if (!await originalFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier introuvable'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check file size
    final fileSize = await originalFile.length();
    if (fileSize == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichier vide'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Copy file to temp directory to avoid issues with same image selection
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      tempFile = await originalFile.copy('${tempDir.path}/$fileName');
    } catch (e) {
      debugPrint('Error copying file: $e');
      // If copy fails, use original file
      tempFile = originalFile;
    }

    setState(() => _isUploadingBanner = true);

    try {
      debugPrint('Uploading banner: ${tempFile.path}, size: $fileSize bytes');
      final response = await _profileService.uploadBanner(tempFile);

      if (response['success'] == true) {
        setState(() {
          _bannerUrl = response['banner_url'];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bannière mise à jour avec succès !'),
              backgroundColor: Color(0xFF2E9B5B),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Banner upload error: $e');
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'upload';
        if (e.toString().contains('must be an image')) {
          errorMessage =
              'Format d\'image non reconnu. Essayez une autre image (JPEG, PNG).';
        } else if (e.toString().contains('too large')) {
          errorMessage = 'Image trop lourde (max 20Mo)';
        } else {
          errorMessage = 'Erreur: ${e.toString().split('\n').first}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Clean up temp file if it was created and is different from original
      if (tempFile != null &&
          tempFile.path != originalFile.path &&
          await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      }
      setState(() => _isUploadingBanner = false);
    }
  }

  Future<void> _showMediaPickerChoice() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2E9B5B),
                ),
                title: const Text('Importer des images'),
                subtitle: const Text('Sélectionner plusieurs photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadMultipleImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFFEF8A40)),
                title: const Text('Importer une vidéo'),
                subtitle: const Text('Sélectionner une vidéo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadVideo();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadMultipleImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFiles.isEmpty) return;

    setState(() => _isUploadingGallery = true);

    try {
      final files = pickedFiles.map((f) => File(f.path)).toList();
      final response = await _profileService.uploadGalleryImages(files);

      if (response['success'] == true) {
        setState(() {
          if (response['gallery'] != null) {
            _gallery = List<String>.from(response['gallery']);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${pickedFiles.length} image(s) ajoutée(s) à la galerie !',
              ),
              backgroundColor: const Color(0xFF2E9B5B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingGallery = true);

    try {
      final file = File(pickedFile.path);
      final response = await _profileService.uploadGalleryVideo(file);

      if (response['success'] == true) {
        setState(() {
          if (response['gallery'] != null) {
            _gallery = List<String>.from(response['gallery']);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vidéo ajoutée à la galerie !'),
              backgroundColor: Color(0xFF2E9B5B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _deleteGalleryImage(int index) async {
    try {
      final response = await _profileService.deleteGalleryImage(index);

      if (response['success'] == true) {
        setState(() {
          if (response['gallery'] != null) {
            _gallery = List<String>.from(response['gallery']);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image supprimée de la galerie'),
              backgroundColor: Color(0xFF2E9B5B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isVideo(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.mkv'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  Widget _buildGalleryItem(String url, int index) {
    final isVideo = _isVideo(url);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                )
              : Image.network(
                  _buildImageUrl(url),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _deleteGalleryImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
        // Video indicator
        if (isVideo)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'VIDÉO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http') || url.startsWith('https')) return url;
    return '$serverBase/storage/$url';
  }

  Widget _buildUploadButton({
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(Icons.image_outlined, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final data = {
        'company_name': _nomSocieteController.text,
        'telephone': _telephoneController.text,
        'contact_email': _emailController.text,
        'address': _adresseController.text,
        'code_postal': _codePostalController.text,
        'ville': _villeController.text,
        'pays': _paysController.text,
        'presentation': _presentationController.text,
        'secteur_activite': _selectedSecteur,
        'social_links': {
          'facebook': _facebookController.text,
          'instagram': _instagramController.text,
          'linkedin': _linkedinController.text,
          'youtube': _youtubeController.text,
          'snapchat': _snapchatController.text,
        },
      };

      await _profileService.updateProfile(data);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modifications enregistrées avec succès !'),
          backgroundColor: Color(0xFF2E9B5B),
        ),
      );
      setState(() => _isLoading = false);

      // Check if ALL required fields are filled (except pictures)
      final allFieldsFilled = _areAllFieldsFilled();
      
      if (allFieldsFilled) {
        // Award My's for completing profile
        try {
          final mysResponse = await MysEarningService().awardMys(
            actionType: 'profile_complete',
            referenceId: UserSession().id?.toString(),
          );
          
          if (mysResponse['success'] == true && mounted) {
            // Update UserSession with new balance
            final newBalance = mysResponse['earning']?['new_balance'];
            if (newBalance != null) {
              UserSession().updateMys(newBalance);
            }
            
            // Show reward modal after a short delay
            Future.microtask(() async {
              if (mounted) {
                await MysRewardModal.show(
                  context,
                  amount: mysResponse['earning']?['amount'] ?? 2,
                  actionType: 'profile_complete',
                );
              }
            });
          }
        } catch (e) {
          debugPrint("Error awarding My's for profile completion: $e");
          // Don't block the user if awarding fails
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Check if all required profile fields are filled (except pictures)
  bool _areAllFieldsFilled() {
    // Required fields for pro profile
    final requiredFields = [
      _nomSocieteController.text.trim(),
      _telephoneController.text.trim(),
      _emailController.text.trim(),
      _adresseController.text.trim(),
      _codePostalController.text.trim(),
      _villeController.text.trim(),
      _paysController.text.trim(),
      _presentationController.text.trim(),
      _selectedSecteur,
    ];
    
    // Check that all required fields have content
    for (final field in requiredFields) {
      if (field == null || field.toString().isEmpty) {
        return false;
      }
    }
    
    // Check that at least one social link is filled (optional but counts toward completion)
    final socialLinks = [
      _facebookController.text.trim(),
      _instagramController.text.trim(),
      _linkedinController.text.trim(),
      _youtubeController.text.trim(),
      _snapchatController.text.trim(),
    ];
    
    // Profile is considered complete if all required fields + at least one social link
    final hasSocialLink = socialLinks.any((link) => link.isNotEmpty);
    
    return hasSocialLink;
  }
}
