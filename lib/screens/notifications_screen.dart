import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0;

  final List<_NotificationGroup> _allNotifications = [
    _NotificationGroup(
      label: 'Récentes',
      items: [
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 10.png',
          name: 'Theresa Webb',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: "À l'instant",
        ),
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 10 (1).png',
          name: 'Leslie Alexander',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: "À l'instant",
        ),
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 10 (2).png',
          name: 'Annette Black',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: 'il y a 1 min',
          isRead: true,
        ),
      ],
    ),
    _NotificationGroup(
      label: "Aujourd'hui",
      items: [
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 10 (3).png',
          name: 'Wade Warren',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: 'il y a 09h',
          isRead: true,
        ),
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 10 (1).png',
          name: 'Leslie Alexander',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: 'il y a 09h',
          isRead: true,
        ),
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 11.png',
          name: 'Arlene McCoy',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: 'il y a 11h',
          isRead: true,
        ),
      ],
    ),
    _NotificationGroup(
      label: 'Hier',
      items: [
        _NotificationItem(
          avatar: 'assets/images/dashboard_particulier/Ellipse 10 (3).png',
          name: 'Wade Warren',
          text: 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
          time: 'il y a 09h',
          isRead: true,
        ),
      ],
    ),
  ];

  List<_NotificationGroup> get _filteredNotifications {
    if (_selectedTab == 0) return _allNotifications;
    return _allNotifications
        .map((group) => _NotificationGroup(
              label: group.label,
              items:
                  group.items.where((item) => !item.isRead).toList(),
            ))
        .where((group) => group.items.isNotEmpty)
        .toList();
  }

  int get _totalCount {
    int count = 0;
    for (final group in _allNotifications) {
      count += group.items.length;
    }
    return count;
  }

  int get _unreadCount {
    int count = 0;
    for (final group in _allNotifications) {
      count += group.items.where((item) => !item.isRead).length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('Tout ($_totalCount)', 0),
                  const SizedBox(width: 10),
                  _buildTab('Non-lues ($_unreadCount)', 1),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Notification list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredNotifications.length,
                itemBuilder: (context, groupIndex) {
                  final group = _filteredNotifications[groupIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        group.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...group.items.map((item) => _buildNotificationTile(item)),
                    ],
                  );
                },
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

  Widget _buildNotificationTile(_NotificationItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage(item.avatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        item.isRead ? FontWeight.w500 : FontWeight.bold,
                    color: const Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationGroup {
  final String label;
  final List<_NotificationItem> items;

  _NotificationGroup({required this.label, required this.items});
}

class _NotificationItem {
  final String avatar;
  final String name;
  final String text;
  final String time;
  final bool isRead;

  _NotificationItem({
    required this.avatar,
    required this.name,
    required this.text,
    required this.time,
    this.isRead = false,
  });
}
