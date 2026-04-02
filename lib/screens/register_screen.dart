import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isLoading = false;
  bool _isValidatingParrainage = false;
  bool? _isParrainageValid;
  String? _parrainageErrorMessage;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _couponController = TextEditingController();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _couponController.addListener(_onParrainageCodeChanged);
  }

  @override
  void dispose() {
    _couponController.removeListener(_onParrainageCodeChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _onParrainageCodeChanged() {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _isParrainageValid = null;
        _parrainageErrorMessage = null;
      });
      return;
    }
    _validateParrainageCode(code);
  }

  Future<void> _validateParrainageCode(String code) async {
    if (_isValidatingParrainage) return;
    
    setState(() => _isValidatingParrainage = true);
    
    try {
      final response = await _authService.validateParrainageCode(
        parrainageCode: code,
      );
      if (mounted) {
        setState(() {
          _isParrainageValid = response['success'] == true;
          _parrainageErrorMessage = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isParrainageValid = false;
          _parrainageErrorMessage = e.firstError;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isParrainageValid = false;
          _parrainageErrorMessage = 'Code invalide';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isValidatingParrainage = false);
      }
    }
  }

  bool get _canRegister {
    // Can register if parrainage code is empty OR valid
    final code = _couponController.text.trim();
    if (code.isEmpty) return true;
    return _isParrainageValid == true;
  }

  Color _getParrainageBorderColor() {
    if (_isParrainageValid == null) {
      return const Color(0xFF1B8D4B).withOpacity(0.4);
    }
    if (_isParrainageValid!) {
      return Colors.green;
    }
    return Colors.red;
  }

  Widget? _buildParrainageSuffixIcon() {
    if (_isValidatingParrainage) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF1B8D4B),
          ),
        ),
      );
    }
    if (_isParrainageValid == null) {
      return null;
    }
    if (_isParrainageValid!) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    }
    return const Icon(
      Icons.error,
      color: Colors.red,
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canRegister) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        parrainageCode: _couponController.text.trim().isEmpty
            ? null
            : _couponController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: _emailController.text.trim(),
            purpose: 'email_verification',
          ),
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
      body: Stack(
        children: [
          // Background Green and Illustration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              color: const Color(0xFF1B8D4B),
              child: Image.asset(
                'assets/images/auth/Rectangle 4.png',
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.1),
                colorBlendMode: BlendMode.dstIn,
              ),
            ),
          ),
          // Logo and Header
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Image.asset(
                    'assets/images/LOGO VERT.png',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          // White Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Inscription',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF616161),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Créez votre compte Myreklam gratuitement',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      // Email Field
                      _buildTextFormField(
                        controller: _emailController,
                        hint: 'votre@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                      const SizedBox(height: 15),
                      // Password Field
                      _buildTextFormField(
                        controller: _passwordController,
                        hint: 'Entrer votre mot de passe',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscureText,
                        textInputAction: TextInputAction.next,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      // Confirm Password Field
                      _buildTextFormField(
                        controller: _confirmPasswordController,
                        hint: 'Confirmer votre mot de passe',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscureConfirmText,
                        textInputAction: TextInputAction.done,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmText = !_obscureConfirmText;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer votre mot de passe';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Parrainage Code Field
                      TextFormField(
                        controller: _couponController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Entrer le Code de parrainage (Facultatif)',
                          hintStyle: TextStyle(
                            color: const Color(0xFF1B8D4B).withOpacity(0.6),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE8F5E9),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _getParrainageBorderColor(),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _getParrainageBorderColor(),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _getParrainageBorderColor(),
                              width: 2,
                            ),
                          ),
                          suffixIcon: _buildParrainageSuffixIcon(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Validation feedback text
                      if (_isParrainageValid != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            _isParrainageValid! ? 'Code valide ✓' : (_parrainageErrorMessage ?? 'Code invalide'),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isParrainageValid! ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 25),
                      // Register Button
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
                          onPressed: _isLoading || !_canRegister ? null : () => _handleRegister(),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Créer mon compte',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Déjà un compte? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Se Connecter',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
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
          borderSide: const BorderSide(
            color: Color(0xFF1B8D4B),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFD32F2F),
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
    );
  }

}
