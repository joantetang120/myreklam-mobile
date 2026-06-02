import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/config/api_config.dart';

class ParrainageScreen extends StatefulWidget {
  const ParrainageScreen({super.key});

  @override
  State<ParrainageScreen> createState() => _ParrainageScreenState();
}

class _ParrainageScreenState extends State<ParrainageScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _history = [];
  String? _parrainageCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get parrainage code from user session
      _parrainageCode = UserSession().parrainageCode;

      // Fetch stats and history in parallel
      final results = await Future.wait([
        ApiClient().authenticatedGet('/referral/stats'),
        ApiClient().authenticatedGet('/referral/history'),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0]['stats'] ?? {};
          _history = results[1]['history'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String get _referralLink {
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl?ref-parrain=$_parrainageCode';
  }

  Future<void> _copyToClipboard(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF3AAE5E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 4,
      onTabTapped: (index) {
        if (index != 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ParticulierMainScreen(initialIndex: index),
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

              // Summary stats row
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: Color(0xFF3AAE5E)),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Erreur: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadReferralData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        icon: Icons.group,
                        label: 'Parrainés',
                        value: '${_stats['total_referred'] ?? 0}',
                        color: const Color(0xFF2196F3),
                        bgColor: const Color(0xFFE3F2FD),
                        borderColor: const Color(0xFFBBDEFB),
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        icon: Icons.check_circle,
                        label: 'Complétés',
                        value: '${_stats['completed'] ?? 0}',
                        color: const Color(0xFF4CAF50),
                        bgColor: const Color(0xFFE8F5E9),
                        borderColor: const Color(0xFFC8E6C9),
                      ),
                      const SizedBox(width: 10),
                      _buildSummaryCard(
                        icon: Icons.stars,
                        label: 'My\'s gagnés',
                        value: '${_stats['rewards_points'] ?? 0}',
                        color: const Color(0xFFFF9800),
                        bgColor: const Color(0xFFFFF3E0),
                        borderColor: const Color(0xFFFFE0B2),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Referral Code Section
              _buildReferralSection(
                icon: Icons.group_outlined,
                title: 'Votre code de parrainage',
                content: _parrainageCode ?? 'Chargement...',
                buttonLabel: 'Copier le code',
                description: 'Partagez ce code avec vos amis pour qu\'ils puissent s\'inscrire et vous faire gagner des My\'s',
                onCopy: () {
                  if (_parrainageCode != null) {
                    _copyToClipboard(_parrainageCode!, 'Code copié !');
                  }
                },
              ),

              const SizedBox(height: 16),

              // Referral Link Section
              _buildReferralSection(
                icon: Icons.link_outlined,
                title: 'Votre lien de parrainage',
                content: _referralLink,
                buttonLabel: 'Copier le lien',
                description: 'Partagez ce lien avec vos amis pour qu\'ils puissent s\'inscrire et vous faire gagner des My\'s',
                onCopy: () => _copyToClipboard(_referralLink, 'Lien copié !'),
              ),


              const SizedBox(height: 24),

              // History list at bottom
              if (!_isLoading && _error == null)
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
    required String value,
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
              value,
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
    required VoidCallback onCopy,
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  GestureDetector(
                    onTap: onCopy,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.copy, color: Color(0xFFFF9800), size: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          buttonLabel,
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.grey[400], height: 1.4),
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
          children: _history.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Aucun parrainage pour le moment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ]
              : _history.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final row = _buildHistoryRow(
                    item['referred_name'] ?? 'Utilisateur',
                    item['created_at'] ?? '',
                    '+ ${item['reward_points'] ?? 0} My\'s',
                    item['account_type'] == 'pro' ? 'Pro' : 'Particulier',
                    status: item['status'] ?? 'pending',
                  );
                  if (index < _history.length - 1) {
                    return Column(
                      children: [
                        row,
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return row;
                }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String name, String date, String amount, String type, {String status = 'pending'}) {
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
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
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
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
