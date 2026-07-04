import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';
import 'package:myreklam/widgets/mys_reward_modal.dart';

/// Onboarding modal for new pro users
/// 4-step flow: Welcome -> Profile Picture -> Complete Profile -> Presentation
/// Total My's: 0.5 (picture) + 0.5 (phone if not already added) + 1 (social) + 1 (presentation) = 3 or 2.5
class ProOnboardingModal extends StatefulWidget {
  final bool needsPhone; // true if phone was not provided during registration
  final bool hasExistingPhone; // true if user already has a phone number
  final VoidCallback onComplete;

  const ProOnboardingModal({
    super.key,
    required this.needsPhone,
    this.hasExistingPhone = false,
    required this.onComplete,
  });

  @override
  State<ProOnboardingModal> createState() => _ProOnboardingModalState();
}

class _ProOnboardingModalState extends State<ProOnboardingModal>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 2: Profile Picture
  File? _selectedImage;
  bool _isUploadingImage = false;
  bool _hasAwardedPicture = false;

  // Step 3: Complete Profile
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedSocialPlatform;
  final TextEditingController _socialLinkController = TextEditingController();
  bool _hasAwardedSocial = false;

  // Step 4: Presentation
  final TextEditingController _presentationController = TextEditingController();
  bool _hasAwardedPresentation = false;

  bool _isSavingProfile = false;

  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _phoneController.dispose();
    _socialLinkController.dispose();
    _presentationController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    // Save progress for current step before moving
    if (_currentStep == 1 && _selectedImage != null && !_hasAwardedPicture) {
      await _uploadAndAwardProfilePicture();
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _slideController.reset();
      _slideController.forward();
    } else {
      // Final step - save profile data and complete
      await _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  void _skipOnboarding() {
    widget.onComplete();
    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _uploadAndAwardProfilePicture() async {
    if (_selectedImage == null || _hasAwardedPicture) return;

    setState(() => _isUploadingImage = true);

    try {
      final response = await ProfileService().uploadAvatar(_selectedImage!);

      if (response['success'] == true) {
        _hasAwardedPicture = true;

        // Update bottom bar avatar immediately
        if (response['avatar_url'] != null) {
          CustomBottomBar.avatarNotifier.value = response['avatar_url'];
        }

        // Backend already awards My's when uploading avatar
        // Update balance from response if available
        if (response['mys_awarded'] != null && response['mys_awarded'] > 0) {
          final newBalance = response['new_mys_balance'];
          if (newBalance != null) {
            UserSession().updateMys(newBalance.toDouble());
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isSavingProfile = true);

    try {
      final Map<String, dynamic> updateData = {};

      // Add phone if provided AND user doesn't already have one
      if (widget.needsPhone && !widget.hasExistingPhone && _phoneController.text.isNotEmpty) {
        updateData['phone'] = _phoneController.text;

        // Award 0.5 My's for phone
        try {
          await MysEarningService().awardMys(actionType: 'phone_added');
        } catch (e) {
          debugPrint('Error awarding My\'s for phone: $e');
        }
      }

      // Add social media if provided
      if (_selectedSocialPlatform != null && _socialLinkController.text.isNotEmpty) {
        updateData['social_links'] = {
          _selectedSocialPlatform!: _socialLinkController.text,
        };

        if (!_hasAwardedSocial) {
          try {
            final mysResponse = await MysEarningService().awardMys(
              actionType: 'social_media',
            );
            if (mysResponse['success'] == true) {
              _hasAwardedSocial = true;
              final newBalance = mysResponse['earning']?['new_balance'];
              if (newBalance != null) {
                UserSession().updateMys(newBalance);
              }
            }
          } catch (e) {
            debugPrint('Error awarding My\'s for social media: $e');
          }
        }
      }

      // Add presentation if provided
      if (_presentationController.text.isNotEmpty) {
        updateData['bio'] = _presentationController.text;
        updateData['presentation'] = _presentationController.text;

        if (!_hasAwardedPresentation) {
          try {
            final mysResponse = await MysEarningService().awardMys(
              actionType: 'presentation',
            );
            if (mysResponse['success'] == true) {
              _hasAwardedPresentation = true;
              final newBalance = mysResponse['earning']?['new_balance'];
              if (newBalance != null) {
                UserSession().updateMys(newBalance);
              }
            }
          } catch (e) {
            debugPrint('Error awarding My\'s for presentation: $e');
          }
        }
      }

      // Update profile if there's data to save
      if (updateData.isNotEmpty) {
        await ApiClient().authenticatedPut('/profile/me', body: updateData);
      }

      // Award onboarding_complete and show success modal
      try {
        final mysResponse = await MysEarningService().awardMys(
          actionType: 'onboarding_complete',
        );
        if (mysResponse['success'] == true && mounted) {
          final newBalance = mysResponse['earning']?['new_balance'];
          if (newBalance != null) {
            UserSession().updateMys(newBalance);
          }

          widget.onComplete();
          Navigator.of(context).pop();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              MysRewardModal.show(
                context,
                amount: 3, // Total: 0.5 + 0.5 (if phone) + 1 + 1
                actionType: 'onboarding_complete',
              );
            }
          });

          return;
        }
      } catch (e) {
        debugPrint('Error awarding onboarding complete My\'s: $e');
      }

      if (mounted) {
        widget.onComplete();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProgressBar(),

                if (_currentStep < _totalSteps - 1)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 8),
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text(
                          'le faire plus tard',
                          style: TextStyle(
                            color: Color(0xFF3AAE5E),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: _buildStepContent(),
                    );
                  },
                ),

                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.grey[200],
      child: Row(
        children: List.generate(_totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              color: index <= _currentStep
                  ? const Color(0xFF3AAE5E)
                  : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildProfilePictureStep();
      case 2:
        return _buildCompleteProfileStep();
      case 3:
        return _buildPresentationStep();
      default:
        return _buildWelcomeStep();
    }
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/home_modal/Sans-titre---1 1.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 24),
          const Text(
            'Bienvenue sur MyReklam!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8C42),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Découvrez comment tirer le meilleur parti de votre compte professionnel en quelques étapes simples.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildDotsIndicator(),
        ],
      ),
    );
  }

  Widget _buildProfilePictureStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/home_modal/solar_camera-bold.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ajoutez votre logo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8C42),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Une photo ou un logo augmente la confiance et rend votre profil plus attractif.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Color(0xFF3AAE5E),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Gagnez 1 My\'s',
                  style: TextStyle(
                    color: const Color(0xFF3AAE5E),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cliquez pour ajouter',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDotsIndicator(),
        ],
      ),
    );
  }

  Widget _buildCompleteProfileStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/images/home_modal/solar_user-linear.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Complétez votre profil',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8C42),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Plus votre profil est complet, plus vous êtes visible et crédible auprès des autres utilisateurs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 24),

          // Phone input (if needed and not already present)
          if (widget.needsPhone && !widget.hasExistingPhone) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars,
                    color: Color(0xFF3AAE5E),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ajoutez votre numéro (+0.5 My)',
                    style: TextStyle(
                      color: const Color(0xFF3AAE5E),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+33 6 12 34 56 78',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3AAE5E)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (widget.hasExistingPhone) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7EF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF3AAE5E), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Numéro de téléphone déjà ajouté',
                    style: TextStyle(
                      color: const Color(0xFF3AAE5E),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars,
                      color: Color(0xFF3AAE5E),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajoutez un réseau social (+0.5 My)',
                      style: TextStyle(
                        color: const Color(0xFF3AAE5E),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSocialRadio('Facebook', 'facebook'),
                  _buildSocialRadio('Instagram', 'instagram'),
                  _buildSocialRadio('LinkedIn', 'linkedin'),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedSocialPlatform != null)
                TextField(
                  controller: _socialLinkController,
                  decoration: InputDecoration(
                    labelText: 'Lien $_selectedSocialPlatform',
                    hintText: 'https://...',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3AAE5E)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDotsIndicator(),
        ],
      ),
    );
  }

  Widget _buildPresentationStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 40,
              color: Color(0xFFFF8C42),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Présentez votre activité',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8C42),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Décrivez votre activité professionnelle pour attirer plus de clients.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  color: Color(0xFF3AAE5E),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gagnez 1 My\'s',
                  style: TextStyle(
                    color: const Color(0xFF3AAE5E),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _presentationController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Votre présentation (Qui sommes nous ?)',
              hintText: 'Décrivez votre activité, vos services, votre expérience...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3AAE5E)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDotsIndicator(),
        ],
      ),
    );
  }

  Widget _buildSocialRadio(String label, String value) {
    final isSelected = _selectedSocialPlatform == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSocialPlatform = isSelected ? null : value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7EF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3AAE5E) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentStep
                ? const Color(0xFF3AAE5E)
                : index < _currentStep
                    ? const Color(0xFF3AAE5E).withOpacity(0.5)
                    : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _currentStep > 0
                ? OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Précédent',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (_currentStep > 0) const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed: _isUploadingImage || _isSavingProfile
                  ? null
                  : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isUploadingImage || _isSavingProfile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == _totalSteps - 1
                              ? 'Terminer'
                              : 'Suivant',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (_currentStep < _totalSteps - 1) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
