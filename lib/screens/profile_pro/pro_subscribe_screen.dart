import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myreklam/services/subscription_service.dart';
import 'package:myreklam/screens/pro_subscription_screen.dart';

class ProSubscribeScreen extends StatefulWidget {
  const ProSubscribeScreen({super.key});

  @override
  State<ProSubscribeScreen> createState() => _ProSubscribeScreenState();
}

class _ProSubscribeScreenState extends State<ProSubscribeScreen> {
  final _subscriptionService = SubscriptionService();
  Map<String, dynamic>? _subscription;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final response = await _subscriptionService.getCurrentSubscription();
      if (mounted) {
        setState(() {
          _subscription = response['subscription'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getPlanDisplayName() {
    if (_subscription == null) return 'Aucun abonnement';
    final plan = _subscription!['plan'] as String?;
    final billingCycle = _subscription!['billing_cycle'] as String?;

    if (plan == 'premium') {
      return billingCycle == 'annual' ? 'Premium annuel' : 'Premium mensuel';
    }
    return 'Gratuit';
  }

  String _getRenewalDate() {
    if (_subscription == null) return '-';
    final endDate = _subscription!['end_date'];
    if (endDate == null) return 'Sans renouvellement';

    final date = DateTime.tryParse(endDate.toString());
    if (date == null) return '-';

    return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isCancelling = true);
    Navigator.of(context).pop(); // Close dialog

    try {
      await _subscriptionService.cancelSubscription();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement résilié avec succès.'),
            backgroundColor: Color(0xFFEF8A40),
          ),
        );

        // Navigate back to subscription screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProSubscriptionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la résiliation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Résilier l\'abonnement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          content: const Text(
            'Êtes-vous sûr de vouloir résilier votre abonnement ? Vous perdrez l\'accès à toutes les fonctionnalités premium à la fin de la période en cours.',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isCancelling ? null : _cancelSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirmer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Avantages from pro_subscription_screen.dart
  final List<String> _advantages = const [
    'Consulter les annonces (illimité)',
    'Commenter et réagir aux annonces (illimité)',
    'Obtenir un numéro ou email de contact',
    'Voir les documents partagés',
    'Télécharger les programmes de formations',
    'Poster une annonce (illimité)',
    'Partager mes coordonnées sur mes annonces',
    'Accès à la messagerie',
    'Convertir mes My\'s en récompense',
    'Profil (Premium)',
    'Badge "Profil vérifié"',
    'Répondre aux avis',
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          'Abonnement',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscription,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sous-titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gérez votre abonnement premium et accédez à toutes vos factures en un clic.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),

              // Section Mon Abonnement actuel
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(-2, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/profil_pro/subscribe-icon.png',
                            width: 25,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mon Abonnement actuel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 5),
                    // Plan badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Image.asset(
                                'assets/images/profil_pro/subscribe-plan.png',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getPlanDisplayName(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 5),

                    // Prochain renouvellement
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/profil_pro/subscribe-calendar.png',
                            width: 24,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prochain renouvellement',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                _getRenewalDate(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Avantages inclus
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 2,
                      offset: const Offset(-2, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/profil_pro/subscribe-icon2.png',
                          width: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avantages inclus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._advantages.map((text) => _buildAdvantageItem(text)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Résilier l'abonnement (only show if has active subscription)
              if (_subscription != null && _subscription!['plan'] != 'free')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _isCancelling ? null : _showCancelDialog,
                    icon: const Icon(Icons.close, size: 18),
                    label: _isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Résilier l\'abonnement',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF8A40),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvantageItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Image.asset(
            'assets/images/profil_pro/subscribe-check.png',
            width: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
