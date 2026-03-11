import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class ProAffiliateScreen extends StatefulWidget {
  const ProAffiliateScreen({super.key});

  @override
  State<ProAffiliateScreen> createState() => _ProAffiliateScreenState();
}

class _ProAffiliateScreenState extends State<ProAffiliateScreen> {
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
            'Parrainage',
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
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Invitez vos amis à rejoindre Myreklam et gagnez des My\'s à chaque inscription réussie',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Summary cards row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      icon: Icons.group,
                      label: 'Particulier parrainé',
                      reward: '2 My\'s',
                      color: const Color(0xFF2196F3),
                      bgColor: const Color(0xFFE3F2FD),
                      borderColor: const Color(0xFFBBDEFB),
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      icon: Icons.card_giftcard,
                      label: 'Entreprise gratuite',
                      reward: '2 My\'s',
                      color: const Color(0xFFFF9800),
                      bgColor: const Color(0xFFFFF3E0),
                      borderColor: const Color(0xFFFFE0B2),
                    ),
                    const SizedBox(width: 10),
                    _buildSummaryCard(
                      icon: Icons.stars,
                      label: 'Entreprise Premium',
                      reward: '5 My\'s',
                      color: const Color(0xFF4CAF50),
                      bgColor: const Color(0xFFE8F5E9),
                      borderColor: const Color(0xFFC8E6C9),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Referral Code Section
              _buildReferralSection(
                icon: Icons.group_outlined,
                title: 'Votre code de parrainage',
                content: '33587869',
                buttonLabel: 'Copier le code',
                description:
                    'Partagez ce code avec vos amis pour qu\'ils puissent s\'inscrire et vous faire gagner des My\'s',
              ),

              const SizedBox(height: 16),

              // Referral Link Section
              _buildReferralSection(
                icon: Icons.sell_outlined,
                title: 'Votre lien de parrainage',
                content: 'https://www.myreklam.fr/?ref-parrain=38684657',
                buttonLabel: 'Copier le lien',
                description:
                    'Partagez ce code avec vos amis pour qu\'ils puissent s\'inscrire et vous faire gagner des My\'s',
              ),

              const SizedBox(height: 16),

              // Share Message Section
              _buildShareMessageSection(),

              const SizedBox(height: 24),

              // History list at bottom
              _buildHistorySection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String reward,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reward,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection({
    required IconData icon,
    required String title,
    required String content,
    required String buttonLabel,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[100]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.copy,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        buttonLabel,
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareMessageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD).withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.share, color: Color(0xFF2196F3), size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Message de partage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Text(
                  'Bonjour, j\'utilise myreklam et j\'en suis vraiment satisfait. Voici un lien de parrainage qui te permet de t\'inscrire et de bénéficier de nombreux avantages. En utilisant ce lien, tu m\'aideras à gagner des points My\'s que je pourrai échanger contre des récompenses ! Merci d\'avance ! https://www.myreklam.fr/?ref-parrain=38684657',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text(
                    'Copier le message',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF3E0),
                    foregroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
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
          children: [
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 12),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 12),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 12),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
            ),
            const SizedBox(height: 12),
            _buildHistoryRow(
              'Enterprise Sarl',
              '30/12/2025',
              '+ 2 My\'s',
              'Particulier',
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
}
