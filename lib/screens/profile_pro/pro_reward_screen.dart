import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/utils/user_session.dart';

class ProRewardScreen extends StatefulWidget {
  const ProRewardScreen({super.key});

  @override
  State<ProRewardScreen> createState() => _ProRewardScreenState();
}

class _ProRewardScreenState extends State<ProRewardScreen> {
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 4,
      onTabTapped: (index) {
        if (index != 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParticulierMainScreen(initialIndex: index),
            ),
          );
        }
      },
      body: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF616161),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Vos récompenses',
            style: TextStyle(
              color: Color(0xFF2D2D2D),
              fontFamily: 'Manjari',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 4),
              Text(
                'Gagnez des My\'s en parrainant vos amis et débloquez des\nrécompenses exclusives',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Balance card
              _buildBalanceCard(),

              const SizedBox(height: 12),

              Text(
                'Echangez vos My\'s contre des avantages exclusifs',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),

              const SizedBox(height: 12),

              // Convert button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text(
                      'Convertir en récompenses',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tier badges row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTierBadge(
                      icon: Icons.show_chart,
                      label: '10%',
                      sublabel: 'Progression',
                      color: const Color(0xFF2196F3),
                      borderColor: const Color(0xFFBBDEFB),
                      iconBg: const Color(0xFFE3F2FD),
                    ),
                    const SizedBox(width: 8),
                    _buildTierBadge(
                      icon: Icons.emoji_events_outlined,
                      label: 'Gold',
                      sublabel: 'Niveau actuel',
                      color: const Color(0xFFFF9800),
                      borderColor: const Color(0xFFFFE0B2),
                      iconBg: const Color(0xFFFFF3E0),
                    ),
                    const SizedBox(width: 8),
                    _buildTierBadge(
                      icon: Icons.diamond_outlined,
                      label: 'Platinum',
                      sublabel: 'Prochain niveau',
                      color: const Color(0xFFFFD600),
                      borderColor: const Color(0xFFFFF9C4),
                      iconBg: const Color(0xFFFFFDE7),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ambassador section with tier cards
              _buildAmbassadorSection(),

              const SizedBox(height: 24),

              // Tab bar (moved or adjusted if needed, but the user image shows history below)
              _buildHistoriqueTab(),

              const SizedBox(height: 24),

              // How to earn more section
              _buildEarnMoreSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC80), width: 1),
            ),
            child: Column(
              children: [
                Text(
                  'Votre Solde',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      UserSession().mys.toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child:  Image.asset('assets/images/image-removebg-preview 2.png', width: 14, height: 14)
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Niveau Gold',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      '30 My\'s jusqu\'au PLATINUM',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.6,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF9800),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '22 My\'s',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      '200 My\'s',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: -24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required Color borderColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbassadorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: Color(0xFFFF9800),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Votre Statut ambassadeur',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Large White Circle
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Orange ring
                  Container(
                    width: 165,
                    height: 165,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF9800).withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gold coin image/icon
                      Image.asset(
                        'assets/images/image-removebg-preview 2.png',
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${UserSession().mys} My\'s',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Silver Card
            _buildTierStatusCard(
              title: 'Silver',
              subtitle: '0 - 50 My\'s',
              icon: Icons.check_circle,
              color: Colors.grey[400]!,
              bgColor: const Color(0xFFF0F0F0),
              borderColor: Colors.grey[300]!,
            ),
            const SizedBox(height: 12),

            // Gold Card (Active)
            _buildActiveTierCard(),

            const SizedBox(height: 12),

            // Platinum Card
            _buildTierStatusCard(
              title: 'PLATINUM',
              subtitle: '201+ My\'s',
              icon: Icons.check_circle,
              color: const Color(0xFF4DB6AC),
              bgColor: const Color(0xFFE8F5F3),
              borderColor: const Color(0xFFB2DFDB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color == const Color(0xFF4DB6AC)
                      ? const Color(0xFF26A69A)
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTierCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7EE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFF9800),
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gold',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '51My\'s - 200 My\'s',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.7,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF9800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Plus que 56 My\'s pour PLATINUM',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Plan Actuel',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoriqueTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historique de Recompenses',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '24 My\'s gagnés',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3AAE5E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Tout',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 16),

            // History rows
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 8),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 8),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 8),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 8),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),

            const SizedBox(height: 16),

            // Voir plus
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: const Text(
                  'Voir plus',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    String name,
    String date,
    String amount,
    String type,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[350]?.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.grey[500], size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                type,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnMoreSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9800), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFFCCBC),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Comment gagner plus de My\'s',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            ),
            // Tips row
            Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tips',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),

            _buildEarnItem(
              icon: Icons.person_outline,
              title: 'Compléter son profil',
              subtitle: 'Un profil complet, c\'est toujours plus avantageux.',
              reward: '2 My\'s',
              index: 0,
            ),
            _buildEarnItem(
              icon: Icons.campaign_outlined,
              title: 'Publication d\'une annonce',
              subtitle:
                  'Publiez une annonce et recevez une récompense immédiate !',
              reward: '2 My\'s',
              index: 1,
            ),
            _buildEarnItem(
              icon: Icons.chat_bubble_outline,
              title: 'Commenter une annonce',
              subtitle:
                  'Laissez un commentaire et gagnez des points à chaque interaction !',
              reward: '1 My\'s',
              index: 2,
            ),
            _buildEarnItem(
              icon: Icons.star_outline,
              title: 'Laisser un avis sur un profil entreprise',
              subtitle:
                  'Donnez votre avis sur une entreprise et soyez récompensé pour votre contribution !',
              reward: '1 My\'s',
              index: 3,
            ),
            _buildEarnItem(
              icon: Icons.smartphone_outlined,
              title: 'Recommander une annonce',
              subtitle:
                  'Partagez une annonce sur vos réseaux et empochez des points en un clic !',
              reward: '1 My\'s',
              index: 4,
            ),
            _buildEarnItem(
              icon: Icons.email_outlined,
              title: 'Postuler à une offre d\'emploi ou de formation',
              subtitle:
                  'Postulez à une offre et recevez des points pour chaque candidature !',
              reward: '1 My\'s',
              index: 5,
            ),
            _buildEarnItem(
              icon: Icons.calendar_today_outlined,
              title: 'Participer à un événement',
              subtitle:
                  'Inscrivez-vous à un événement et gagnez des récompenses en participant !',
              reward: '1 My\'s',
              index: 6,
            ),
            _buildEarnItem(
              icon: Icons.group_outlined,
              title: 'Parrainage particulier',
              subtitle:
                  'Parrainez un particulier et gagnez à chaque nouvelle inscription !',
              reward: '2 My\'s',
              index: 7,
            ),
            _buildEarnItem(
              icon: Icons.card_giftcard_outlined,
              title: 'Parrainage d\'entreprise version gratuite',
              subtitle:
                  'Parrainez une entreprise et gagnez vos premiers My\'s dès son inscription !',
              reward: '2 My\'s',
              index: 8,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String reward,
    required int index,
    bool isLast = false,
  }) {
    final bool isEven = index % 2 == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFFFF3E0).withOpacity(0.3) : Colors.white,
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF9800), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            reward,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }
}
