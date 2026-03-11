import 'package:flutter/material.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/subscription_service.dart';
import 'package:myreklam/services/api_client.dart';

class ProSubscriptionScreen extends StatefulWidget {
  const ProSubscriptionScreen({super.key});

  @override
  State<ProSubscriptionScreen> createState() => _ProSubscriptionScreenState();
}

class _ProSubscriptionScreenState extends State<ProSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 40,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFFF8600),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FF8600),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF7E6B5C),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  tabs: const [
                    Tab(
                      child: SizedBox.expand(
                        child: Center(child: Text('Version GRATUITE')),
                      ),
                    ),
                    Tab(
                      child: SizedBox.expand(
                        child: Center(child: Text('Version PREMIUM')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Développez votre activité avec Myreklam : choisissez l\'offre qui correspond à vos ambitions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FreePlan(onContinue: () => _handleSubscribe('free')),
                _PremiumPlan(onContinue: (billingCycle) => _handleSubscribe('premium', billingCycle: billingCycle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubscribe(String plan, {String? billingCycle}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _subscriptionService.subscribe(
        plan: plan,
        billingCycle: billingCycle,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const ParticulierMainScreen(),
        ),
        (route) => false,
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
}

class _FreePlan extends StatelessWidget {
  const _FreePlan({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE9DED2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _FreePlanHeader(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              '0€',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                            SizedBox(width: 4),
                            Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text('/mois',
                                  style: TextStyle(color: Color(0xFF8D8D8D))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Gratuit à vie · sans engagement',
                          style: TextStyle(color: Color(0xFF8D8D8D)),
                        ),
                        const SizedBox(height: 26),
                        _buildFeatureGroup(
                          title: 'TROUVER',
                          items: const [
                            FeatureItem('Consulter les annonces (illimité)', FeatureStatus.warning),
                            FeatureItem('Commenter et réagir aux annonces (1 mois)', FeatureStatus.warning),
                            FeatureItem('Obtenir un numéro ou email de contact', FeatureStatus.unavailable, strike: true),
                            FeatureItem('Voir les documents partagés', FeatureStatus.unavailable, strike: true),
                            FeatureItem('Télécharger les programmes de formations', FeatureStatus.unavailable, strike: true),
                          ],
                          headerColor: const Color(0xFFFF9800),
                        ),
                        _buildFeatureGroup(
                          title: 'PROMOUVOIR',
                          items: const [
                            FeatureItem('Poster une annonce (1 mois)', FeatureStatus.warning),
                            FeatureItem('Partager mes coordonnées sur mes annonces', FeatureStatus.unavailable, strike: true),
                          ],
                          headerColor: const Color(0xFFFF9800),
                        ),
                        _buildFeatureGroup(
                          title: 'COMMUNIQUER',
                          items: const [
                            FeatureItem('Accès à la messagerie', FeatureStatus.unavailable, strike: true),
                            FeatureItem('Convertir mes My\'s en récompense', FeatureStatus.unavailable, strike: true),
                          ],
                          headerColor: const Color(0xFFFF9800),
                        ),
                        _buildFeatureGroup(
                          title: 'DIFFUSER',
                          items: const [
                            FeatureItem('Profil (Basique)', FeatureStatus.warning),
                            FeatureItem('Répondre aux avis', FeatureStatus.unavailable, strike: true),
                          ],
                          headerColor: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          label: 'Continuer en gratuit',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB347), Color(0xFFFF8C1A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          onTap: onContinue,
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
}

class _PremiumPlan extends StatefulWidget {
  const _PremiumPlan({required this.onContinue});

  final void Function(String billingCycle) onContinue;

  @override
  State<_PremiumPlan> createState() => _PremiumPlanState();
}

enum _BillingCycle { monthly, annual }

class _PremiumPlanState extends State<_PremiumPlan> {
  _BillingCycle _cycle = _BillingCycle.annual;

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
                                      style: const TextStyle(color: Color(0xFF6D7278)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pricing.subLabel,
                                style: const TextStyle(color: Color(0xFF6D7278)),
                                textAlign: TextAlign.center,
                              ),
                              if (pricing.savingsLabel != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                            FeatureItem('Consulter les annonces (illimité)', FeatureStatus.available),
                            FeatureItem('Commenter et réagir aux annonces (illimité)', FeatureStatus.available),
                            FeatureItem('Obtenir un numéro ou email de contact', FeatureStatus.available),
                            FeatureItem('Voir les documents partagés', FeatureStatus.available),
                            FeatureItem('Télécharger les programmes de formations', FeatureStatus.available),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        _buildFeatureGroup(
                          title: 'PROMOUVOIR',
                          items: const [
                            FeatureItem('Poster une annonce (illimité)', FeatureStatus.available),
                            FeatureItem('Partager mes coordonnées sur mes annonces', FeatureStatus.available),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        _buildFeatureGroup(
                          title: 'COMMUNIQUER',
                          items: const [
                            FeatureItem('Accès à la messagerie', FeatureStatus.available),
                            FeatureItem('Convertir mes My\'s en récompense', FeatureStatus.available),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        _buildFeatureGroup(
                          title: 'DIFFUSER',
                          items: const [
                            FeatureItem('Profil (Premium)', FeatureStatus.available),
                            FeatureItem('Badge "Profil vérifié"', FeatureStatus.available),
                            FeatureItem('Répondre aux avis', FeatureStatus.available),
                          ],
                          headerColor: const Color(0xFF2E9B5B),
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          label: 'Continuer en Premium',
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF04BC7B),
                              Color(0xFF03CD85),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          onTap: () => widget.onContinue(
                            _cycle == _BillingCycle.monthly ? 'monthly' : 'annual',
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
  const _BillingToggle({
    required this.activeCycle,
    required this.onChanged,
  });

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
                color: isActive ? const Color(0xFF2E9B5B) : const Color(0xFF6D7278),
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
      children: const [
        Text(
          '1 mois offert. Vous serez facturé à la fin du mois. Vous pouvez annuler à tout moment pendant la période d’essai.',
          style: TextStyle(color: Color(0xFF6D7278)),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 18),
        _PremiumHighlights(),
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
            border: Border.all(color: const Color(0xFF2E9B5B).withOpacity(0.25)),
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

class _FreePlanHeader extends StatelessWidget {
  const _FreePlanHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFB347), Color(0xFFFF8C1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _SwirlPainter(opacity: 0.25),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '| Version GRATUITE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Découvrez la plateforme avec des fonctionnalités de base.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
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
            colors: [
            Color(0xFF04BC7B),
            Color(0xFF03CD85),
          ],
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
                child: CustomPaint(
                  painter: _SwirlPainter(opacity: 0.18),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
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
              decoration:
                  item.strike ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
        ),
      ],
    ),
  );
}
