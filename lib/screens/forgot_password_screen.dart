import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            illustrationAsset:
                'assets/images/auth/password/illustration-du-concept-cadenas-ouvert_114360-21934 1.png',
            email: _emailController.text.trim(),
            purpose: 'password_reset',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.firstError),
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AdaptiveColors.border(context, const Color(0xFFE0E0E0)),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AdaptiveColors.foreground(context, Color(0xFF1B8D4B)),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        backgroundColor: AdaptiveColors.surface(context, Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Illustration
            Image.asset(
              'assets/images/auth/password/illustration-du-concept-cadenas-ouvert_114360-21934 1.png',
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            // Title
            Text(
              'Mot de passe oublié',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.foreground(context, Color(0xFF1B8D4B)),
              ),
            ),
            const SizedBox(height: 15),
            // Subtitle
            Text(
              'Saisissez votre adresse e-mail. Un code de réinitialisation vous sera envoyé pour votre mot de passe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AdaptiveColors.foreground(context, Colors.grey),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Form(
              key: _formKey,
              child: _buildTextFormField(
                controller: _emailController,
                hint: 'votre@email.com',
                icon: Icons.email_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
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
                    const Color(0xFF1B8D4B),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : () => _handleForgotPassword(),
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
                    : Text(
                        'Suivant',
                        style: TextStyle(
                          color: AdaptiveColors.foreground(
                            context,
                            Colors.white,
                          ),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: AdaptiveColors.foreground(context, Colors.grey),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: AdaptiveColors.foreground(context, Colors.grey),
        ),
        filled: true,
        fillColor: AdaptiveColors.surface(context, const Color(0xFFF5F5F5)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AdaptiveColors.border(context, Color(0xFF1B8D4B)),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AdaptiveColors.border(context, Color(0xFFD32F2F)),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AdaptiveColors.border(context, Color(0xFFD32F2F)),
            width: 2,
          ),
        ),
        errorStyle: TextStyle(
          fontSize: 12,
          height: 1.2,
          color: AdaptiveColors.foreground(context, Color(0xFFD32F2F)),
        ),
        errorMaxLines: 2,
      ),
    );
  }
}
