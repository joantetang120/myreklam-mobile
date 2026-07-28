import 'package:flutter/material.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/profile_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/widgets/reklam_avatar.dart';

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// Global notifier to update the avatar from anywhere (e.g. profile screens)
  static final ValueNotifier<String?> avatarNotifier = ValueNotifier<String?>(
    null,
  );

  /// Global notifier to trigger avatar reload from backend
  static final ValueNotifier<bool> refreshAvatarNotifier = ValueNotifier<bool>(
    false,
  );

  /// Global notifier for notification count
  static final ValueNotifier<int> notificationCountNotifier =
      ValueNotifier<int>(0);

  /// Global notifier to trigger notification count refresh
  static final ValueNotifier<bool> refreshNotificationNotifier =
      ValueNotifier<bool>(false);

  /// Global notifier for chat unread count
  static final ValueNotifier<int> chatCountNotifier = ValueNotifier<int>(0);

  /// Global notifier to trigger chat count refresh
  static final ValueNotifier<bool> refreshChatNotifier = ValueNotifier<bool>(
    false,
  );

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  String? _avatarUrl;
  String? _displayName;
  int _unreadNotifCount = 0;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUnreadCount();
    _loadChatUnreadCount();
    CustomBottomBar.avatarNotifier.addListener(_onAvatarChanged);
    CustomBottomBar.refreshAvatarNotifier.addListener(_onRefreshAvatar);
    CustomBottomBar.notificationCountNotifier.addListener(
      _onNotificationCountChanged,
    );
    CustomBottomBar.refreshNotificationNotifier.addListener(
      _onRefreshNotificationCount,
    );
    CustomBottomBar.chatCountNotifier.addListener(_onChatCountChanged);
    CustomBottomBar.refreshChatNotifier.addListener(_onRefreshChatCount);
  }

  @override
  void dispose() {
    CustomBottomBar.avatarNotifier.removeListener(_onAvatarChanged);
    CustomBottomBar.refreshAvatarNotifier.removeListener(_onRefreshAvatar);
    CustomBottomBar.notificationCountNotifier.removeListener(
      _onNotificationCountChanged,
    );
    CustomBottomBar.refreshNotificationNotifier.removeListener(
      _onRefreshNotificationCount,
    );
    CustomBottomBar.chatCountNotifier.removeListener(_onChatCountChanged);
    CustomBottomBar.refreshChatNotifier.removeListener(_onRefreshChatCount);
    super.dispose();
  }

  void _onNotificationCountChanged() {
    if (!mounted) return;
    setState(() {
      _unreadNotifCount = CustomBottomBar.notificationCountNotifier.value;
    });
  }

  void _onRefreshNotificationCount() {
    if (!mounted) return;
    _loadUnreadCount();
  }

  void _onChatCountChanged() {
    if (!mounted) return;
    setState(() {
      _unreadChatCount = CustomBottomBar.chatCountNotifier.value;
    });
  }

  void _onRefreshChatCount() {
    if (!mounted) return;
    _loadChatUnreadCount();
  }

  Future<void> _loadChatUnreadCount() async {
    if (UserSession().isGuest) return;

    try {
      final count = await ConversationService().getUnreadCount();
      if (mounted) {
        setState(() => _unreadChatCount = count);
        CustomBottomBar.chatCountNotifier.value = count;
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadCount() async {
    if (UserSession().isGuest) return;

    try {
      final response = await ApiClient().authenticatedGet(
        '/notifications/unread-count',
      );
      if (mounted && response['success'] == true) {
        final count = response['unread_count'] ?? 0;
        setState(() => _unreadNotifCount = count);
        CustomBottomBar.notificationCountNotifier.value = count;
      }
    } catch (_) {}
  }

  void _onAvatarChanged() {
    if (!mounted) return;
    setState(() {
      _avatarUrl = CustomBottomBar.avatarNotifier.value;
    });
  }

  void _onRefreshAvatar() {
    if (!mounted) return;
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    if (UserSession().isGuest) {
      if (mounted) {
        setState(() {
          _avatarUrl = null;
          _displayName = null;
        });
      }
      return;
    }

    try {
      final response = await ProfileService().getProfile();
      if (!mounted) return;
      final profile = response['profile'];
      setState(() {
        _avatarUrl = profile?['avatar_url'];
        if (profile != null) {
          if (UserSession().isParticulier) {
            _displayName = profile['pseudo'];
          } else {
            _displayName = profile['company_name'] ?? profile['first_name'];
          }
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Get bottom system insets for gesture navigation (Samsung, etc.)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: UserSession().isGuest
          ? 0
          : (85 + (bottomPadding > 0 ? bottomPadding - 8 : 0)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: bottomPadding > 0 ? 8 : 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (!UserSession().isGuest) ...[
              _buildItem(
                0,
                Icons.home_outlined,
                Icons.home_outlined,
                'Accueil',
              ),
              _buildItem(
                1,
                Icons.chat_bubble_outline,
                Icons.chat_bubble_outline,
                'Chat',
                badgeCount: _unreadChatCount,
              ),
              _buildItem(
                2,
                Icons.article_outlined,
                Icons.article_outlined,
                'Publier',
              ),
              _buildItem(
                3,
                Icons.search_outlined,
                Icons.search_outlined,
                'Recherche',
              ),
              _buildProfileItem(4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected
        ? const Color(0xFF2E9B5B)
        : const Color(0xFF9E9E9E);
    final icon = isSelected ? selectedIcon : unselectedIcon;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9B5B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: isSelected
                  ? BoxDecoration(
                      color: const Color(0xFF2E9B5B).withValues(alpha: 0.15),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 26),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(int index) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected
        ? const Color(0xFF2E9B5B)
        : const Color(0xFF9E9E9E);

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9B5B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  child: ReklamAvatar(
                    avatarUrl: _avatarUrl,
                    displayName: _displayName,
                    radius: 17.5,
                    accountType: UserSession().isPro ? 'pro' : 'particulier',
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E9B5B)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                if (_unreadNotifCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 1.5),
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          _unreadNotifCount > 99 ? '99+' : '$_unreadNotifCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              'Vous',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
