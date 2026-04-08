import 'package:flutter/material.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:intl/intl.dart';

class MysHistoryScreen extends StatefulWidget {
  final double totalMys;
  
  const MysHistoryScreen({super.key, required this.totalMys});

  @override
  State<MysHistoryScreen> createState() => _MysHistoryScreenState();
}

class _MysHistoryScreenState extends State<MysHistoryScreen> {
  List<Map<String, dynamic>> _earnings = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEarningsHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _loadMoreEarnings();
    }
  }

  Future<void> _loadEarningsHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().authenticatedGet('/mys/history?page=1');
      if (response['success'] == true) {
        final earningsData = response['earnings'];
        if (earningsData is Map && earningsData.containsKey('data')) {
          _earnings = List<Map<String, dynamic>>.from(earningsData['data']);
          _hasMorePages = earningsData['current_page'] < (earningsData['last_page'] ?? 1);
          _currentPage = earningsData['current_page'] ?? 1;
        } else if (earningsData is List) {
          _earnings = List<Map<String, dynamic>>.from(earningsData);
          _hasMorePages = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading earnings history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreEarnings() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await ApiClient().authenticatedGet('/mys/history?page=$nextPage');
      if (response['success'] == true) {
        final earningsData = response['earnings'];
        if (earningsData is Map && earningsData.containsKey('data')) {
          final newEarnings = List<Map<String, dynamic>>.from(earningsData['data']);
          setState(() {
            _earnings.addAll(newEarnings);
            _hasMorePages = earningsData['current_page'] < (earningsData['last_page'] ?? 1);
            _currentPage = earningsData['current_page'] ?? _currentPage;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more earnings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
      'registration' => 'Inscription',
      'profile_picture' => 'Photo de profil',
      'phone_added' => 'Numéro de téléphone',
      'social_media' => 'Réseau social',
      _ => actionType,
    };
  }

  IconData _getActionIcon(String? actionType) {
    if (actionType == null) return Icons.star;
    return switch (actionType) {
      'bon_plan' => Icons.local_offer,
      'demande' => Icons.help_outline,
      'evenement' => Icons.event,
      'formation' => Icons.school,
      'job_offer' => Icons.work,
      'profile_complete' => Icons.person,
      'comment' => Icons.comment,
      'review' => Icons.rate_review,
      'share' => Icons.share,
      'event_participation' => Icons.event_available,
      'training_subscription' => Icons.book,
      'job_application' => Icons.work_outline,
      'referral_particulier' => Icons.group_add,
      'referral_pro' => Icons.business,
      'registration' => Icons.app_registration,
      'profile_picture' => Icons.camera_alt,
      'phone_added' => Icons.phone,
      'social_media' => Icons.link,
      _ => Icons.star,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Historique des My\'s',
          style: TextStyle(
            color: Color(0xFF2D2D2D),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarningsHistory,
              child: Column(
                children: [
                  // Summary card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total gagné',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${widget.totalMys}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'My\'s',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Earnings list
                  Expanded(
                    child: _earnings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun historique disponible',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _earnings.length + (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _earnings.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final earning = _earnings[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getActionIcon(earning['action_type']),
                                        color: const Color(0xFFFF9800),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            earning['description'] ??
                                                _getActionLabel(earning['action_type']),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2D2D2D),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(earning['created_at']),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '+${earning['amount']} My\'s',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFF9800),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
