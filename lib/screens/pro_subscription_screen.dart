import 'package:flutter/material.dart';
import 'package:myreklam/models/delegation.dart';
import 'package:myreklam/services/delegation_manager.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/stripe_payment_service.dart';
import 'package:myreklam/services/paypal_payment_service.dart';
import 'package:myreklam/services/subscription_service.dart';

class ProSubscriptionScreen extends StatelessWidget {
  /// When true (e.g. right after creating a pro account), the user MUST pick a
  /// plan (free or premium) — back navigation is disabled.
  final bool forceChoice;

  const ProSubscriptionScreen({super.key, this.forceChoice = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceChoice,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: forceChoice
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'Choisissez votre abonnement',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manjari',
            ),
          ),
          centerTitle: true,
        ),
        body: const Column(
        children: [
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Développez votre activité avec Myreklam : choisissez l\'offre qui correspond à vos ambitions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8D8D8D)),
            ),
          ),
          SizedBox(height: 18),
          Expanded(child: _PremiumPlan()),
        ],
        ),
      ),
    );
  }
}

class _PremiumPlan extends StatefulWidget {
  const _PremiumPlan();

  @override
  State<_PremiumPlan> createState() => _PremiumPlanState();
}

enum _BillingCycle { monthly, annual }

class _PremiumPlanState extends State<_PremiumPlan> {
  _BillingCycle _cycle = _BillingCycle.annual;
  final StripePaymentService _stripeService = StripePaymentService();
  final PayPalPaymentService _paypalService = PayPalPaymentService();
  bool _isProcessingPayment = false;

  // Promo code (Stripe promotion code) state.
  final TextEditingController _promoController = TextEditingController();
  String? _appliedPromoCode;
  String? _promoFeedback; // success or error message shown under the field
  bool _promoValid = false;
  bool _checkingPromo = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _resetPromo() {
    _appliedPromoCode = null;
    _promoFeedback = null;
    _promoValid = false;
  }

  void _showPaymentMethodModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Choisir votre méthode de paiement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Abonnement Premium - ${_cycle == _BillingCycle.monthly ? 'Mensuel' : 'Annuel'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Promo / reduction code
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        enabled: !_promoValid,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Code de réduction',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: _promoValid
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _promoController.clear();
                                    setModalState(() {
                                      setState(_resetPromo);
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8D4B),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: (_checkingPromo || _promoValid)
                            ? null
                            : () => _applyPromo(setModalState),
                        child: _checkingPromo
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
                if (_promoFeedback != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _promoFeedback!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _promoValid ? const Color(0xFF1B8D4B) : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _PaymentOptionTile(
                  icon: Icons.payment,
                  label: 'PayPal',
                  color: const Color(0xFF0070BA),
                  onTap: () {
                    Navigator.pop(ctx);
                    _processPayPalPayment();
                  },
                ),
                const SizedBox(height: 12),
                _PaymentOptionTile(
                  icon: Icons.credit_card,
                  label: 'Stripe (Carte bancaire)',
                  color: const Color(0xFF635BFF),
                  onTap: () {
                    Navigator.pop(ctx);
                    _processStripePayment();
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Future<void> _applyPromo(StateSetter setModalState) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    setModalState(() => setState(() => _checkingPromo = true));

    final billingCycle = _cycle == _BillingCycle.monthly ? 'monthly' : 'annual';
    final result = await _stripeService.validatePromo(
      billingCycle: billingCycle,
      code: code,
    );

    setModalState(() {
      setState(() {
        _checkingPromo = false;
        if (result['valid'] == true) {
          _promoValid = true;
          _appliedPromoCode = code;
          final disc = result['discount'] as Map<String, dynamic>?;
          final amount = result['discounted_amount'];
          final label = disc?['label']?.toString();
          _promoFeedback =
              '✓ Code appliqué${label != null && label.isNotEmpty ? ' ($label)' : ''} — nouveau prix : ${amount}€';
        } else {
          _promoValid = false;
          _appliedPromoCode = null;
          _promoFeedback = result['error']?.toString() ?? 'Code invalide';
        }
      });
    });
  }

  bool _ensureCanManageSubscription() {
    if (DelegationManager.instance
        .can(DelegationPermission.manageSubscription)) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            "Vous n'avez pas l'autorisation de gérer l'abonnement de ce compte."),
      ),
    );
    return false;
  }

  Future<void> _processStripePayment() async {
    if (!_ensureCanManageSubscription()) return;
    if (_isProcessingPayment) return;

    setState(() => _isProcessingPayment = true);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final billingCycle = _cycle == _BillingCycle.monthly ? 'monthly' : 'annual';

    try {
      final success = await _stripeService.processPayment(
        billingCycle: billingCycle,
        context: context,
        promoCode: _appliedPromoCode,
      );

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement réussi ! Abonnement Premium activé.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ParticulierMainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  Future<void> _processPayPalPayment() async {
    if (!_ensureCanManageSubscription()) return;
    if (_isProcessingPayment) return;

    setState(() => _isProcessingPayment = true);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final billingCycle = _cycle == _BillingCycle.monthly ? 'monthly' : 'annual';

    try {
      final success = await _paypalService.processPayment(
        billingCycle: billingCycle,
        context: context,
      );

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement réussi ! Abonnement Premium activé.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ParticulierMainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de paiement PayPal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  static final Map<_BillingCycle, _PremiumPricing> _pricing = {
    _BillingCycle.monthly: const _PremiumPricing(
      price: '6,99€',
      cadence: '/mois',
      subLabel: 'Facturé mensuellement',
      savingsLabel: null,
    ),
    _BillingCycle.annual: const _PremiumPricing(
      price: '4,99€',
      cadence: '/mois',
      subLabel: 'Facturé 59,90€/an',
      savingsLabel: 'Économisez 22,90€',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final pricing = _pricing[_cycle]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2F3EA)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E9B5B).withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PremiumPlanHeader(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(30, 36, 30, 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BillingToggle(
                          activeCycle: _cycle,
                          onChanged: (cycle) => setState(() => _cycle = cycle),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    pricing.price,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E9B5B),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      pricing.cadence,
                                      style: const TextStyle(
                                        color: Color(0xFF6D7278),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pricing.subLabel,
                                style: const TextStyle(
                                  color: Color(0xFF6D7278),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (pricing.savingsLabel != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F7EA),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    pricing.savingsLabel!,
                                    style: const TextStyle(
                                      color: Color(0xFF2E9B5B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _CenteredPremiumIntro(),
                        const SizedBox(height: 24),
                        _buildFeatureGroup(
                          title: 'TROUVER',
                          items: const [
                            FeatureItem(
                              'Consulter les annonces (illimité)',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Commenter et réagir aux annonces (illimité)',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Obtenir un numéro ou email de contact',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Voir les documents partagés',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Télécharger les programmes de formations',
                              FeatureStatus.available,
                            ),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        _buildFeatureGroup(
                          title: 'PROMOUVOIR',
                          items: const [
                            FeatureItem(
                              'Poster une annonce (illimité)',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Partager mes coordonnées sur mes annonces',
                              FeatureStatus.available,
                            ),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        _buildFeatureGroup(
                          title: 'COMMUNIQUER',
                          items: const [
                            FeatureItem(
                              'Accès à la messagerie',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Convertir mes My\'s en récompense',
                              FeatureStatus.available,
                            ),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        _buildFeatureGroup(
                          title: 'DIFFUSER',
                          items: const [
                            FeatureItem(
                              'Profil (Premium)',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Badge "Profil vérifié"',
                              FeatureStatus.available,
                            ),
                            FeatureItem(
                              'Répondre aux avis',
                              FeatureStatus.available,
                            ),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          label: 'Continuer en Premium',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF04BC7B), Color(0xFF03CD85)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          onTap: _showPaymentMethodModal,
                        ),
                        const SizedBox(height: 10),
                        // Free plan option (limited features).
                        Center(
                          child: TextButton(
                            onPressed: _isProcessingPayment ? null : _continueFree,
                            child: const Text(
                              'Continuer avec la version gratuite',
                              style: TextStyle(
                                color: Color(0xFF616161),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "Gratuit : consultez les annonces. Publier et commenter sont possibles 30 jours, puis réservés au Premium. Messagerie, contacts et documents restent Premium.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF9E9E9E),
                                height: 1.4,
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
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _continueFree() async {
    if (!_ensureCanManageSubscription()) return;
    if (_isProcessingPayment) return;

    setState(() => _isProcessingPayment = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await SubscriptionService().subscribe(plan: 'free');
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Version gratuite activée.'),
            backgroundColor: Color(0xFF3AAE5E),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ParticulierMainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }
}

class _PremiumPricing {
  const _PremiumPricing({
    required this.price,
    required this.cadence,
    required this.subLabel,
    this.savingsLabel,
  });

  final String price;
  final String cadence;
  final String subLabel;
  final String? savingsLabel;
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.activeCycle, required this.onChanged});

  final _BillingCycle activeCycle;
  final ValueChanged<_BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          _buildOption(
            label: 'Mensuel',
            isActive: activeCycle == _BillingCycle.monthly,
            onTap: () => onChanged(_BillingCycle.monthly),
          ),
          const SizedBox(width: 8),
          _buildOption(
            label: 'Annuel',
            isActive: activeCycle == _BillingCycle.annual,
            onTap: () => onChanged(_BillingCycle.annual),
          ),
        ],
      ),
    );
  }

  Expanded _buildOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isActive
                    ? const Color(0xFF2E9B5B)
                    : const Color(0xFF6D7278),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredPremiumIntro extends StatelessWidget {
  const _CenteredPremiumIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Choisissez une formule et un moyen de paiement pour activer Premium.',
          style: TextStyle(color: Color(0xFF6D7278)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        const _PremiumHighlights(),
      ],
    );
  }
}

class _PremiumHighlights extends StatelessWidget {
  const _PremiumHighlights({Key? key}) : super(key: key);

  static const List<_HighlightItem> _items = [
    _HighlightItem(Icons.visibility_outlined, 'Visibilité maximale'),
    _HighlightItem(Icons.trending_up_outlined, 'Croissance accélérée'),
    _HighlightItem(Icons.headset_mic_outlined, 'Support dédié'),
    _HighlightItem(Icons.verified_outlined, 'Profil vérifié'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F9F0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB8E4CF)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 2.8,
        ),
        itemBuilder: (context, index) => _HighlightTile(item: _items[index]),
      ),
    );
  }
}

class _HighlightItem {
  const _HighlightItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.item});

  final _HighlightItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF5E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2E9B5B).withOpacity(0.25),
            ),
          ),
          child: Icon(item.icon, color: const Color(0xFF24A05B), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1F4830),
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.last.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumPlanHeader extends StatelessWidget {
  const _PremiumPlanHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        height: 170,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF04BC7B), Color(0xFF03CD85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -20,
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(painter: _SwirlPainter(opacity: 0.18)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/solar_star-fall-line-duotone.png',
                        width: 18,
                        height: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Recommandée pour les pros',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '| Version PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Maximisez votre visibilité et développez votre activité sans limites.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwirlPainter extends CustomPainter {
  _SwirlPainter({this.opacity = 0.3});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(opacity);

    final center = Offset(size.width / 2, size.height / 2);
    double radius = size.width * 0.15;
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(center, radius, paint);
      radius += 22;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FeatureItem {
  const FeatureItem(this.label, this.status, {this.strike = false});

  final String label;
  final FeatureStatus status;
  final bool strike;
}

enum FeatureStatus { available, warning, unavailable }

Widget _buildFeatureGroup({
  required String title,
  required List<FeatureItem> items,
  required Color headerColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF04BC7B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(_buildFeatureLine),
      ],
    ),
  );
}

Widget _buildFeatureLine(FeatureItem item) {
  late final IconData icon;
  late final Color iconColor;
  late final Color backgroundColor;

  switch (item.status) {
    case FeatureStatus.available:
      icon = Icons.check_rounded;
      iconColor = Colors.white;
      backgroundColor = const Color(0xFFFFC433);
      break;
    case FeatureStatus.warning:
      icon = Icons.warning_amber_rounded;
      iconColor = const Color(0xFFB97B00);
      backgroundColor = const Color(0xFFFFF0D9);
      break;
    case FeatureStatus.unavailable:
      icon = Icons.close;
      iconColor = const Color(0xFFD32F2F);
      backgroundColor = const Color(0xFFFDE5E5);
      break;
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 22,
          width: 22,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF4A4A4A),
              decoration: item.strike
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ),
      ],
    ),
  );
}
