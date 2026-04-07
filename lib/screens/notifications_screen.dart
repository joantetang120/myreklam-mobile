import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().authenticatedGet('/notifications?page=1&per_page=20');
      if (response['success'] == true) {
        final data = response['notifications'];
        if (data is Map && data.containsKey('data')) {
          _notifications = List<Map<String, dynamic>>.from(data['data']);
          _hasMorePages = (data['current_page'] ?? 1) < (data['last_page'] ?? 1);
          _currentPage = data['current_page'] ?? 1;
        } else if (data is List) {
          _notifications = List<Map<String, dynamic>>.from(data);
          _hasMorePages = false;
        }
        _unreadCount = response['unread_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMorePages) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await ApiClient().authenticatedGet('/notifications?page=$nextPage&per_page=20');
      if (response['success'] == true) {
        final data = response['notifications'];
        if (data is Map && data.containsKey('data')) {
          final newItems = List<Map<String, dynamic>>.from(data['data']);
          setState(() {
            _notifications.addAll(newItems);
            _hasMorePages = (data['current_page'] ?? 1) < (data['last_page'] ?? 1);
            _currentPage = data['current_page'] ?? _currentPage;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more notifications: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await ApiClient().authenticatedPut('/notifications/$notificationId/read', body: {});
      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiClient().authenticatedPut('/notifications/read-all', body: {});
      setState(() {
        for (var n in _notifications) {
          n['read_at'] = DateTime.now().toIso8601String();
        }
        _unreadCount = 0;
      });
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedTab == 0) return _notifications;
    return _notifications.where((n) => n['read_at'] == null).toList();
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications(List<Map<String, dynamic>> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final notif in notifications) {
      final createdAt = DateTime.tryParse(notif['created_at'] ?? '');
      if (createdAt == null) continue;

      final notifDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      String label;

      if (notifDate == today) {
        label = "Aujourd'hui";
      } else if (notifDate == yesterday) {
        label = 'Hier';
      } else if (now.difference(createdAt).inDays < 7) {
        label = 'Cette semaine';
      } else {
        label = DateFormat('dd/MM/yyyy').format(createdAt);
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(notif);
    }

    return groups;
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return "À l'instant";
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  IconData _getNotificationIcon(String? type) {
    return switch (type) {
      'welcome' => Icons.celebration,
      'mys_earned' => Icons.emoji_events,
      'new_follower' => Icons.person_add,
      'new_candidate' => Icons.work,
      'content_published' => Icons.check_circle,
      'event_participation' => Icons.event_available,
      'training_subscription' => Icons.school,
      _ => Icons.notifications,
    };
  }

  Color _getNotificationColor(String? type) {
    return switch (type) {
      'welcome' => const Color(0xFF9C27B0),
      'mys_earned' => const Color(0xFFFF9800),
      'new_follower' => const Color(0xFF2196F3),
      'new_candidate' => const Color(0xFF4CAF50),
      'content_published' => const Color(0xFF3AAE5E),
      'event_participation' => const Color(0xFFE91E63),
      'training_subscription' => const Color(0xFF00BCD4),
      _ => const Color(0xFF757575),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;
    final grouped = _groupNotifications(filtered);

    return AppLayout(
      backgroundColor: const Color(0xFFF9F9FB),
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back arrow and title
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 12, bottom: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF616161), size: 24),
                    ),
                  ),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Manjari',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  if (_unreadCount > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _markAllAsRead,
                        child: const Icon(
                          Icons.done_all,
                          color: Color(0xFF3AAE5E),
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('Tout (${_notifications.length})', 0),
                  const SizedBox(width: 10),
                  _buildTab('Non-lues ($_unreadCount)', 1),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Notification list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTab == 0
                                    ? 'Aucune notification'
                                    : 'Aucune notification non lue',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: grouped.keys.length +
                                (_hasMorePages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == grouped.keys.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }

                              final groupLabel =
                                  grouped.keys.elementAt(index);
                              final groupItems = grouped[groupLabel]!;

                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    groupLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...groupItems.map((notif) =>
                                      _buildNotificationTile(notif)),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AAE5E) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3AAE5E)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    final bool isRead = notif['read_at'] != null;
    final String type = notif['type'] ?? '';
    final Color color = _getNotificationColor(type);
    final IconData icon = _getNotificationIcon(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notif['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: const Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif['body'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notif['created_at']),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
