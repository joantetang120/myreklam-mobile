import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';
import 'package:myreklam/widgets/company_picker.dart';

class MonProfilParticulierScreen extends StatefulWidget {
  const MonProfilParticulierScreen({super.key});

  @override
  State<MonProfilParticulierScreen> createState() =>
      _MonProfilParticulierScreenState();
}

class _MonProfilParticulierScreenState extends State<MonProfilParticulierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileService = ProfileService();
  bool _isLoading = true;

  // Pseudo validation state
  Timer? _pseudoDebounceTimer;
  bool _isCheckingPseudo = false;
  bool? _pseudoIsAvailable;
  String _pseudoErrorMessage = '';
  List<String> _pseudoSuggestions = [];
  int _pseudoChangeCount = 0;
  int _maxPseudoChanges = 3;
  bool _pseudoChangeLimitReached = false;
  String? _originalPseudo;

  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _presentationController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();

  // Company (Entreprise) selection
  int? _companyId;
  String? _companyName;

  // Social media controllers
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();

  bool _showEmailPublic = false;
  bool _showPhonePublic = false;

  // Gallery state
  List<String> _gallery = [];
  bool _isUploadingGallery = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
    _loadPseudoChangeLimit();
    _pseudoController.addListener(_onPseudoChanged);
  }

  Future<void> _loadPseudoChangeLimit() async {
    try {
      final response = await _profileService.getPseudoChangeLimit();
      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        setState(() {
          _pseudoChangeCount = data['current_changes'] ?? 0;
          _maxPseudoChanges = data['max_changes'] ?? 3;
          _pseudoChangeLimitReached = data['can_change'] == false;
        });
      }
    } catch (e) {
      // Silent fail - use defaults
    }
  }

  void _onPseudoChanged() {
    // Cancel any pending timer
    _pseudoDebounceTimer?.cancel();

    final newPseudo = _pseudoController.text.trim();

    // Skip if empty or same as original
    if (newPseudo.isEmpty || newPseudo == _originalPseudo) {
      setState(() {
        _pseudoIsAvailable = null;
        _pseudoErrorMessage = '';
        _pseudoSuggestions = [];
      });
      return;
    }

    // Set debounce timer
    _pseudoDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkPseudoAvailability(newPseudo);
    });
  }

  Future<void> _checkPseudoAvailability(String pseudo) async {
    if (pseudo.isEmpty) return;

    setState(() => _isCheckingPseudo = true);

    try {
      final response = await _profileService.checkPseudo(pseudo);
      if (!mounted) return;

      final available = response['available'] ?? false;
      final suggestions =
          (response['suggestions'] as List?)
              ?.map((s) => s.toString())
              .toList() ??
          [];

      setState(() {
        _isCheckingPseudo = false;
        _pseudoIsAvailable = available;
        _pseudoErrorMessage = available ? '' : 'Ce pseudo est déjà utilisé.';
        _pseudoSuggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingPseudo = false;
        _pseudoIsAvailable = null;
        _pseudoErrorMessage = '';
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _pseudoController.text = suggestion;
    setState(() {
      _pseudoIsAvailable = true;
      _pseudoErrorMessage = '';
      _pseudoSuggestions = [];
    });
  }

  Future<void> _loadProfileData() async {
    try {
      final response = await _profileService.getProfile();
      if (!mounted) return;

      if (response['profile'] != null) {
        final profile = response['profile'];
        final user = response['user'];
        setState(() {
          _originalPseudo = profile['pseudo']?.toString() ?? '';
          _pseudoController.text = _originalPseudo ?? '';
          _emailController.text = user != null ? (user['email'] ?? '') : '';
          _phoneController.text = profile['phone']?.toString() ?? '';
          _presentationController.text = profile['bio'] ?? '';
          _jobController.text = profile['job_title']?.toString() ?? '';
          _companyId = profile['company_id'] is int
              ? profile['company_id']
              : int.tryParse(profile['company_id']?.toString() ?? '');
          _companyName = profile['company_name']?.toString();
          _showEmailPublic =
              profile['show_email_public'] == 1 ||
              profile['show_email_public'] == true;
          _showPhonePublic =
              profile['show_phone_public'] == 1 ||
              profile['show_phone_public'] == true;

          // Social media
          if (profile['social_links'] != null) {
            final links = profile['social_links'];
            _facebookController.text = links['facebook'] ?? '';
            _instagramController.text = links['instagram'] ?? '';
            _linkedinController.text = links['linkedin'] ?? '';
            _youtubeController.text = links['youtube'] ?? '';
            _snapchatController.text = links['snapchat'] ?? '';
          }

          // Load gallery
          if (profile['gallery'] != null) {
            _gallery = List<String>.from(profile['gallery']);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = {
        'pseudo': _pseudoController.text,
        'email': _emailController.text,
        'bio': _presentationController.text,
        'phone': _phoneController.text,
        'job_title': _jobController.text,
        'company_id': _companyId,
        'company_name': _companyName,
        'show_email_public': _showEmailPublic ? 1 : 0,
        'show_phone_public': _showPhonePublic ? 1 : 0,
        'social_links': {
          'facebook': _facebookController.text,
          'instagram': _instagramController.text,
          'linkedin': _linkedinController.text,
          'youtube': _youtubeController.text,
          'snapchat': _snapchatController.text,
        },
      };

      final response = await _profileService.updateProfile(data);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
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
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Check if all required profile fields are filled (except pictures)
  bool _areAllFieldsFilled() {
    // Required fields for particulier profile
    final requiredFields = [
      _pseudoController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
      _presentationController.text.trim(),
    ];

    // Check that all required fields have content
    for (final field in requiredFields) {
      if (field.isEmpty) {
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

  @override
  void dispose() {
    _pseudoDebounceTimer?.cancel();
    _tabController.dispose();
    _pseudoController.removeListener(_onPseudoChanged);
    _pseudoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _presentationController.dispose();
    _jobController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _youtubeController.dispose();
    _snapchatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      backgroundColor: const Color(0xFFF9F9FB),
      currentIndex: 4,
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF616161),
                              size: 24,
                            ),
                          ),
                        ),
                        const Text(
                          'Mon profil',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Manjari',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Custom TabBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFFEF8A40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[400],
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Informations générales'),
                          Tab(text: 'Médias'),
                        ],
                        onTap: (index) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [_buildGeneralInfoTab(), _buildMediaTab()],
                    ),
                  ),

                  // Bottom Action Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF8A40),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGeneralInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.person_outline, 'Informations Personnelle'),
          const SizedBox(height: 16),
          _buildPseudoField(),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Adresse email',
            controller: _emailController,
            icon: Icons.email_outlined,
          ),
          _buildCheckboxTile(
            'Afficher sur le profil public',
            _showEmailPublic,
            (val) {
              setState(() => _showEmailPublic = val!);
            },
          ),
          const SizedBox(height: 8),
          _buildTextField(
            label: 'Téléphone',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _buildCheckboxTile(
            'Afficher sur le profil public',
            _showPhonePublic,
            (val) {
              setState(() => _showPhonePublic = val!);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.work_outline, 'Profession'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Emploi',
            controller: _jobController,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Entreprise',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                CompanyPickerField(
                  companyId: _companyId,
                  companyName: _companyName,
                  onChanged: (id, name) {
                    setState(() {
                      _companyId = id;
                      _companyName = name;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(Icons.description_outlined, 'Bio'),
          const SizedBox(height: 16),
          _buildTextArea(
            controller: _presentationController,
            hint: 'Décrivez-vous en quelques mots...',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPseudoField() {
    // Determine border color based on validation state
    Color borderColor = Colors.grey.withOpacity(0.2);
    if (_pseudoIsAvailable == true) {
      borderColor = const Color(0xFF3AAE5E);
    } else if (_pseudoIsAvailable == false) {
      borderColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              'Pseudo',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const Spacer(),
            // Change limit indicator
            if (_pseudoChangeCount > 0)
              Text(
                '$_pseudoChangeCount/$_maxPseudoChanges changements',
                style: TextStyle(
                  fontSize: 11,
                  color: _pseudoChangeLimitReached
                      ? Colors.red
                      : Colors.grey[500],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Pseudo input field
        Container(
          decoration: BoxDecoration(
            color: _pseudoChangeLimitReached ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _pseudoIsAvailable != null ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _pseudoController,
            enabled: !_pseudoChangeLimitReached,
            style: TextStyle(
              fontSize: 14,
              color: _pseudoChangeLimitReached
                  ? Colors.grey
                  : const Color(0xFF424242),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              suffixIcon: _isCheckingPseudo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _pseudoIsAvailable == true
                  ? const Icon(Icons.check_circle, color: Color(0xFF3AAE5E))
                  : _pseudoIsAvailable == false
                  ? const Icon(Icons.error, color: Colors.red)
                  : null,
            ),
          ),
        ),

        // Error message
        if (_pseudoErrorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _pseudoErrorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        // Suggestions when pseudo is taken
        if (_pseudoSuggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggestions disponibles:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3AAE5E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _pseudoSuggestions.map((suggestion) {
                    return GestureDetector(
                      onTap: () => _selectSuggestion(suggestion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7EF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3AAE5E)),
                        ),
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            color: Color(0xFF3AAE5E),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Change limit warning
        if (_pseudoChangeLimitReached)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous avez atteint la limite de $_maxPseudoChanges changements de pseudo.',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.share_outlined, 'Réseaux sociaux'),
          const SizedBox(height: 16),
          _buildSocialField(
            'facebook',
            _facebookController,
            Icons.facebook,
            const Color(0xFF1877F2),
          ),
          const SizedBox(height: 12),
          _buildSocialField(
            'instagram',
            _instagramController,
            Icons.camera_alt_outlined,
            const Color(0xFFE4405F),
          ),
          const SizedBox(height: 12),
          _buildSocialField(
            'LinkedIn',
            _linkedinController,
            Icons.link_outlined,
            const Color(0xFF0A66C2),
          ),
          const SizedBox(height: 12),
          _buildSocialField(
            'Youtube',
            _youtubeController,
            Icons.play_circle_outline,
            const Color(0xFFFF0000),
          ),
          const SizedBox(height: 12),
          _buildSocialField(
            'Snapchat',
            _snapchatController,
            Icons.chat_bubble_outline,
            const Color(0xFFFEE101),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF616161)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF616161),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF3AAE5E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF424242),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSocialField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: Color(0xFF424242)),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaUploadBox() {
    return Column(
      children: [
        // Gallery grid
        if (_gallery.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        // Upload button
        _buildUploadButton(
          label: 'Ajouter un media',
          color: const Color(0xFF3AAE5E),
          onTap: _showMediaPickerChoice,
          isLoading: _isUploadingGallery,
        ),
      ],
    );
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
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
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
    final serverBase = ApiConfig.baseUrl.replaceAll("/api", "");
    if (url.startsWith('http') || url.startsWith('https')) return url;
    return '$serverBase/storage/$url';
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
                  color: Color(0xFF3AAE5E),
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
              backgroundColor: const Color(0xFF3AAE5E),
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
              backgroundColor: Color(0xFF3AAE5E),
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
          } else {
            _gallery.removeAt(index);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Média supprimé'),
              backgroundColor: Color(0xFF3AAE5E),
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
}
