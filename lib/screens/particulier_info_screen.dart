import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/user_session.dart';

class ParticulierInfoScreen extends StatefulWidget {
  const ParticulierInfoScreen({super.key});

  @override
  State<ParticulierInfoScreen> createState() => _ParticulierInfoScreenState();
}

class _ParticulierInfoScreenState extends State<ParticulierInfoScreen> {
  final TextEditingController _pseudoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  bool _isLoading = false;

  @override
  void dispose() {
    _pseudoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _profileService.completeParticulierProfile(
        pseudo: _pseudoController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      UserSession().markProfileCompleted();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ParticulierMainScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      // Translate common validation errors to French
      String errorMessage = e.firstError;
      if (errorMessage.toLowerCase().contains('pseudo') &&
          (errorMessage.toLowerCase().contains('already') ||
              errorMessage.toLowerCase().contains('taken') ||
              errorMessage.toLowerCase().contains('unique'))) {
        errorMessage =
            'Ce pseudo est déjà utilisé. Veuillez en choisir un autre.';
      } else if (errorMessage.toLowerCase().contains('phone') &&
          (errorMessage.toLowerCase().contains('already') ||
              errorMessage.toLowerCase().contains('taken') ||
              errorMessage.toLowerCase().contains('unique'))) {
        errorMessage = 'Ce numéro de téléphone est déjà utilisé.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AdaptiveColors.surface(context, Colors.red),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue. Veuillez réessayer.'),
          backgroundColor: AdaptiveColors.surface(context, Colors.red),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdaptiveColors.surface(context, Colors.white),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AdaptiveColors.foreground(context, Colors.grey),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AdaptiveColors.surface(context, Colors.white),
        elevation: 0,
        title: Text(
          'Information particulier',
          style: TextStyle(
            color: AdaptiveColors.foreground(context, Colors.black),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            'Complétez les informations de votre Compte',
            style: TextStyle(
              color: AdaptiveColors.foreground(context, Colors.grey),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          // Progress Bar
          Container(
            width: double.infinity,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AdaptiveColors.surface(context, Colors.grey[200]),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 1.0, // Fully filled for this step in the image
              child: Container(
                decoration: BoxDecoration(
                  color: AdaptiveColors.surface(
                    context,
                    const Color(0xFFFF9800),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AdaptiveColors.surface(
                          context,
                          const Color(0xFFF5F5F5),
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                  decoration: BoxDecoration(
                                    color: AdaptiveColors.surface(
                                      context,
                                      Color(0xFFFFF3E0),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: AdaptiveColors.foreground(
                                      context,
                                      Color(0xFFFF9800),
                                    ),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Informations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AdaptiveColors.foreground(
                                      context,
                                      Colors.grey,
                                    ),
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
                                Text(
                                  'Votre Pseudo*',
                                  style: TextStyle(
                                    color: AdaptiveColors.foreground(
                                      context,
                                      Colors.grey,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AdaptiveColors.surface(
                                      context,
                                      Colors.white,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextFormField(
                                    controller: _pseudoController,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(20),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      final pseudo = value?.trim() ?? '';
                                      if (pseudo.isEmpty) {
                                        return 'Veuillez entrer votre pseudo';
                                      }
                                      if (pseudo.contains('@')) {
                                        return 'Une adresse e-mail ne peut pas être utilisée';
                                      }
                                      if (pseudo.length < 3 ||
                                          pseudo.length > 20) {
                                        return 'Le pseudo doit contenir entre 3 et 20 caractères';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                        borderSide: BorderSide(
                                          color: AdaptiveColors.border(
                                            context,
                                            Color(0xFFFF9800),
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AdaptiveColors.border(
                                            context,
                                            Color(0xFFD32F2F),
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: AdaptiveColors.border(
                                            context,
                                            Color(0xFFD32F2F),
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      errorStyle: TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        color: AdaptiveColors.foreground(
                                          context,
                                          Color(0xFFD32F2F),
                                        ),
                                      ),
                                      errorMaxLines: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Téléphone (recommande)',
                                  style: TextStyle(
                                    color: AdaptiveColors.foreground(
                                      context,
                                      Colors.grey,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AdaptiveColors.surface(
                                      context,
                                      Colors.white,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            Text(
                                              '+33',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    AdaptiveColors.foreground(
                                                      context,
                                                      Colors.grey,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const VerticalDivider(width: 1),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.done,
                                          validator: (value) {
                                            // Phone is optional - only validate if not empty
                                            if (value == null ||
                                                value.isEmpty) {
                                              return null; // Allow empty phone
                                            }
                                            if (!RegExp(
                                              r'^\d{9,10}$',
                                            ).hasMatch(value)) {
                                              return 'Numéro de téléphone invalide';
                                            }
                                            return null;
                                          },
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: AdaptiveColors.border(
                                                  context,
                                                  Color(0xFFFF9800),
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: AdaptiveColors.border(
                                                  context,
                                                  Color(0xFFD32F2F),
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: BorderSide(
                                                    color:
                                                        AdaptiveColors.border(
                                                          context,
                                                          Color(0xFFD32F2F),
                                                        ),
                                                    width: 2,
                                                  ),
                                                ),
                                            errorStyle: TextStyle(
                                              fontSize: 12,
                                              height: 1.2,
                                              color: AdaptiveColors.foreground(
                                                context,
                                                Color(0xFFD32F2F),
                                              ),
                                            ),
                                            errorMaxLines: 2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Suivant Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdaptiveColors.surface(
                          context,
                          const Color(0xFFFF9800),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : () => _handleSubmit(),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AdaptiveColors.foreground(
                                  context,
                                  Colors.white,
                                ),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Suivant',
                                  style: TextStyle(
                                    color: AdaptiveColors.foreground(
                                      context,
                                      Colors.white,
                                    ),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AdaptiveColors.foreground(
                                    context,
                                    Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
