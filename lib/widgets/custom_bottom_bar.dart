import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:myreklam/services/profile_service.dart';

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

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

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final response = await ProfileService().getProfile();
      if (!mounted) return;
      setState(() {
        _avatarUrl = response['profile']?['avatar_url'];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildItem(0, Icons.home_outlined, Icons.home_outlined, 'Accueil'),
            _buildItem(
              1,
              Icons.chat_bubble_outline,
              Icons.chat_bubble_outline,
              'Chat',
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
        ),
      ),
    );
  }

  Widget _buildItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
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
                      color: const Color(0xFF2E9B5B).withOpacity(0.15),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Icon(icon, color: color, size: 26),
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
            Container(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E9B5B)
                        : Colors.transparent,
                    width: 2,
                  ),
                  image: _avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(
                            "${ApiConfig.baseUrl.replaceFirst('/api', '')}/storage/${_avatarUrl!}",
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _avatarUrl == null
                    ? Icon(
                        UserSession().isPro ? Icons.business : Icons.person,
                        size: 20,
                        color: Colors.white,
                      )
                    : null,
              ),
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
