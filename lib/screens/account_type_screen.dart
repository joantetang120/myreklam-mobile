import 'package:flutter/material.dart';
import 'package:myreklam/services/auth_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'particulier_info_screen.dart';
import 'pro_info_screen.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _selectAccountType(String type) async {
    setState(() => _isLoading = true);

    try {
      await _authService.setAccountType(accountType: type);

      if (!mounted) return;

      Widget destination;
      if (type == 'particulier') {
        destination = const ParticulierInfoScreen();
      } else {
        destination = const ProInfoScreen();
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
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
          // Background Illustration (Green Header)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
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

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Myreklam',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Êtes-vous une entreprise ou un particulier ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 30),

                // Selection Cards
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildAccountTypeCard(
                            context,
                            title: 'Particulier',
                            description:
                                'je souhaite découvrir et partager des bons plans, évènement et opportunités',
                            buttonText: 'Continuer en tant que particulier',
                            icon: Icons.person_outline_rounded,
                            primaryColor: const Color(0xFFFF9800), // Orange
                            onTap: _isLoading ? () {} : () => _selectAccountType('particulier'),
                          ),
                          const SizedBox(height: 24),
                          _buildAccountTypeCard(
                            context,
                            title: 'professionnel',
                            description:
                                'je représente une entreprise et souhaite promouvoir mes services et offres',
                            buttonText: 'Continuer en tant que Professionnel',
                            icon: Icons.business_rounded,
                            primaryColor: const Color(0xFF1B8D4B), // Green
                            onTap: _isLoading ? () {} : () => _selectAccountType('pro'),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
