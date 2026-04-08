import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/mys_history_screen.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:intl/intl.dart';

class ProRewardScreen extends StatefulWidget {
  const ProRewardScreen({super.key});

  @override
  State<ProRewardScreen> createState() => _ProRewardScreenState();
}

class _ProRewardScreenState extends State<ProRewardScreen> {
  // Historique state
  List<Map<String, dynamic>> _earnings = [];
  bool _isLoadingEarnings = true;
  double _currentMys = 0;

  // Level thresholds
  static const int SILVER_MIN = 0;
  static const int SILVER_MAX = 50;
  static const int GOLD_MIN = 51;
  static const int GOLD_MAX = 200;
  static const int PLATINUM_MIN = 201;

  // Calculate current level based on My's count
  Map<String, dynamic> _calculateLevel(double mys) {
    String level;
    Color color;
    int currentMin;
    int currentMax;
    int nextLevelMin;
    String nextLevel;

    if (mys <= SILVER_MAX) {
      level = 'Silver';
      color = Colors.grey[400]!;
      currentMin = SILVER_MIN;
      currentMax = SILVER_MAX;
      nextLevelMin = GOLD_MIN;
      nextLevel = 'Gold';
    } else if (mys <= GOLD_MAX) {
      level = 'Gold';
      color = const Color(0xFFFF9800);
      currentMin = GOLD_MIN;
      currentMax = GOLD_MAX;
      nextLevelMin = PLATINUM_MIN;
      nextLevel = 'Platinum';
    } else {
      level = 'Platinum';
      color = const Color(0xFF4DB6AC);
      currentMin = PLATINUM_MIN;
      currentMax = PLATINUM_MIN + 300; // Arbitrary max for display
      nextLevelMin = currentMax;
      nextLevel = 'Max';
    }

    // Calculate progress within current level
    double progress;
    double remaining;
    if (level == 'Platinum') {
      progress = 1.0;
      remaining = 0;
    } else {
      double levelRange = (currentMax - currentMin + 1).toDouble();
      double currentProgress = mys - currentMin;
      progress = currentProgress / levelRange;
      remaining = nextLevelMin - mys;
    }

    return {
      'level': level,
      'color': color,
      'progress': progress,
      'remaining': remaining,
      'nextLevel': nextLevel,
      'currentMin': currentMin,
      'currentMax': currentMax,
      'mys': mys,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadEarningsHistory();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      if (response['user'] != null) {
        final mys = response['user']['mys'];
        if (mys != null) {
          final mysValue = mys is int ? mys.toDouble() : double.tryParse(mys.toString()) ?? 0.0;
          setState(() => _currentMys = mysValue);
          UserSession().updateMys(mysValue);
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadEarningsHistory() async {
    setState(() => _isLoadingEarnings = true);
    try {
      final response = await ApiClient().authenticatedGet('/mys/history?per_page=5');
      if (response['success'] == true) {
        final earningsData = response['earnings'];
        if (earningsData is Map && earningsData.containsKey('data')) {
          _earnings = List<Map<String, dynamic>>.from(earningsData['data']);
        } else if (earningsData is List) {
          _earnings = List<Map<String, dynamic>>.from(earningsData);
        }
      }
    } catch (e) {
      debugPrint('Error loading earnings history: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEarnings = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getActionLabel(String? actionType) {
    if (actionType == null) return 'Action';
    return switch (actionType) {
      'bon_plan' => 'Bon plan',
      'demande' => 'Demande',
      'evenement' => 'Événement',
      'formation' => 'Formation',
      'job_offer' => 'Offre d\'emploi',
      'profile_complete' => 'Profil complété',
      'comment' => 'Commentaire',
      'review' => 'Avis',
      'share' => 'Partage',
      'event_participation' => 'Participation événement',
      'training_subscription' => 'Inscription formation',
      'job_application' => 'Candidature',
      'referral_particulier' => 'Parrainage particulier',
      'referral_pro' => 'Parrainage entreprise',
      _ => actionType,
    };
  }

  @override
  Widget build(BuildContext context) {
    final double userMys = _currentMys > 0 ? _currentMys : UserSession().mys;
    final levelInfo = _calculateLevel(userMys);
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
              _buildBalanceCard(levelInfo, userMys),

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
                      label: '${(levelInfo['progress'] * 100).toInt()}%',
                      sublabel: 'Progression',
                      color: const Color(0xFF2196F3),
                      borderColor: const Color(0xFFBBDEFB),
                      iconBg: const Color(0xFFE3F2FD),
                    ),
                    const SizedBox(width: 8),
                    _buildTierBadge(
                      icon: Icons.emoji_events_outlined,
                      label: levelInfo['level'],
                      sublabel: 'Niveau actuel',
                      color: levelInfo['color'],
                      borderColor: levelInfo['level'] == 'Silver' ? Colors.grey[300]! : (levelInfo['level'] == 'Gold' ? const Color(0xFFFFE0B2) : const Color(0xFFB2DFDB)),
                      iconBg: levelInfo['level'] == 'Silver' ? const Color(0xFFF0F0F0) : (levelInfo['level'] == 'Gold' ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5F3)),
                    ),
                    const SizedBox(width: 8),
                    _buildTierBadge(
                      icon: levelInfo['nextLevel'] == 'Max' ? Icons.star : Icons.diamond_outlined,
                      label: levelInfo['nextLevel'],
                      sublabel: levelInfo['nextLevel'] == 'Max' ? 'Niveau max' : 'Prochain niveau',
                      color: levelInfo['nextLevel'] == 'Max' ? const Color(0xFF4DB6AC) : const Color(0xFFFFD600),
                      borderColor: levelInfo['nextLevel'] == 'Max' ? const Color(0xFFB2DFDB) : const Color(0xFFFFF9C4),
                      iconBg: levelInfo['nextLevel'] == 'Max' ? const Color(0xFFE8F5F3) : const Color(0xFFFFFDE7),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ambassador section with tier cards
              _buildAmbassadorSection(levelInfo),

              const SizedBox(height: 24),

              // Tab bar (moved or adjusted if needed, but the user image shows history below)
              _buildHistoriqueTab(userMys),

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

  Widget _buildBalanceCard(Map<String, dynamic> levelInfo, double userMys) {
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
                      userMys.toString(),
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
                      'Niveau ${levelInfo['level']}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      levelInfo['remaining'] > 0 ? '${levelInfo['remaining']} My\'s jusqu\'au ${levelInfo['nextLevel'].toUpperCase()}' : 'Niveau maximum atteint',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: levelInfo['progress'],
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(levelInfo['color']),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${levelInfo['currentMin']} My\'s',
                      style: TextStyle(fontSize: 11, color: levelInfo['color'], fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${levelInfo['currentMax']} My\'s',
                      style: TextStyle(fontSize: 11, color: levelInfo['color'], fontWeight: FontWeight.w500),
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

  Widget _buildAmbassadorSection(Map<String, dynamic> levelInfo) {
    final double userMys = UserSession().mys;
    final String currentLevel = levelInfo['level'];
    final bool isSilver = currentLevel == 'Silver';
    final bool isGold = currentLevel == 'Gold';
    final bool isPlatinum = currentLevel == 'Platinum';
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
                        '$userMys My\'s',
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
            isSilver
                ? _buildActiveTierCard(levelInfo)
                : _buildTierStatusCard(
                    title: 'Silver',
                    subtitle: '0 - 50 My\'s',
                    icon: userMys > SILVER_MAX ? Icons.check_circle : Icons.lock_outline,
                    color: userMys > SILVER_MAX ? Colors.grey[400]! : Colors.grey[300]!,
                    bgColor: const Color(0xFFF0F0F0),
                    borderColor: Colors.grey[300]!,
                  ),
            const SizedBox(height: 12),

            // Gold Card
            isGold
                ? _buildActiveTierCard(levelInfo)
                : _buildTierStatusCard(
                    title: 'Gold',
                    subtitle: '51 - 200 My\'s',
                    icon: userMys > GOLD_MAX ? Icons.check_circle : Icons.lock_outline,
                    color: userMys > GOLD_MAX ? const Color(0xFFFF9800) : Colors.grey[300]!,
                    bgColor: userMys > GOLD_MAX ? const Color(0xFFFFF7EE) : const Color(0xFFF0F0F0),
                    borderColor: userMys > GOLD_MAX ? const Color(0xFFFFE0B2) : Colors.grey[300]!,
                  ),

            const SizedBox(height: 12),

            // Platinum Card
            isPlatinum
                ? _buildActiveTierCard(levelInfo)
                : _buildTierStatusCard(
                    title: 'PLATINUM',
                    subtitle: '201+ My\'s',
                    icon: Icons.lock_outline,
                    color: Colors.grey[300]!,
                    bgColor: const Color(0xFFF0F0F0),
                    borderColor: Colors.grey[300]!,
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

  Widget _buildActiveTierCard(Map<String, dynamic> levelInfo) {
    final String level = levelInfo['level'];
    final Color color = levelInfo['color'];
    final double progress = levelInfo['progress'];
    final double remaining = levelInfo['remaining'];
    final String nextLevel = levelInfo['nextLevel'];
    final int currentMin = levelInfo['currentMin'];
    final int currentMax = levelInfo['currentMax'];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: level == 'Silver' ? const Color(0xFFF0F0F0) : (level == 'Gold' ? const Color(0xFFFFF7EE) : const Color(0xFFE8F5F3)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level == 'Platinum' ? '201+ My\'s' : '$currentMin - $currentMax My\'s',
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
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                remaining > 0 ? 'Plus que $remaining My\'s pour ${nextLevel.toUpperCase()}' : 'Niveau maximum atteint !',
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
              color: color,
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

  Widget _buildHistoriqueTab(double userMys) {
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
                    Text(
                      '$userMys My\'s gagnés',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3AAE5E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 16),

            // History rows
            if (_isLoadingEarnings)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_earnings.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Aucun historique disponible',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              )
            else
              ..._earnings.asMap().entries.map((entry) {
                final earning = entry.value;
                final isLast = entry.key == _earnings.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: _buildHistoryRow(
                    earning['description'] ?? _getActionLabel(earning['action_type']),
                    _formatDate(earning['created_at']),
                    '+ ${earning['amount']} My\'s',
                    _getActionLabel(earning['action_type']),
                  ),
                );
              }).toList(),

            const SizedBox(height: 16),

            // Voir plus
            if (_earnings.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MysHistoryScreen(totalMys: userMys),
                      ),
                    );
                  },
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
