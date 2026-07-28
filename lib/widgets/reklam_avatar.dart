import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/utils/avatar_resolver.dart';

class ReklamAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? displayName;
  final double radius;
  final String? accountType;
  final Color? backgroundColor;
  final Color? textColor;
  final double textSize;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const ReklamAvatar({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.radius = 20,
    this.accountType,
    this.backgroundColor,
    this.textColor,
    this.textSize = 16,
    this.border,
    this.onTap,
  });

  bool get _hasValidAvatar {
    return AvatarResolver.resolve(avatarUrl) != null;
  }

  String? get _initial {
    if (displayName == null || displayName!.isEmpty) return null;
    return displayName![0].toUpperCase();
  }

  ImageProvider _buildImageProvider() {
    final url = AvatarResolver.resolve(avatarUrl)!;
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    final resolved = ApiConfig.resolveMediaUrl(url);
    if (resolved != null && resolved.isNotEmpty) {
      return NetworkImage(resolved);
    }
    return const AssetImage(
      'assets/images/dashboard_particulier/Ellipse 10.png',
    );
  }

  Color _defaultBackgroundColor() {
    if (backgroundColor != null) return backgroundColor!;
    if (_initial == null) {
      return accountType == 'pro'
          ? const Color(0xFF2E9B5B).withValues(alpha: 0.2)
          : Colors.grey[300]!;
    }
    final colors = [
      const Color(0xFF2E9B5B),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];
    final index = _initial!.codeUnitAt(0) % colors.length;
    return colors[index].withValues(alpha: 0.2);
  }

  Color _defaultTextColor() {
    if (textColor != null) return textColor!;
    if (_initial == null) return Colors.white;
    final colors = [
      const Color(0xFF2E9B5B),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
    ];
    final index = _initial!.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  Widget _buildFallbackContent() {
    if (_initial != null) {
      return Text(
        _initial!,
        style: TextStyle(
          color: _defaultTextColor(),
          fontSize: textSize,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Icon(
      accountType == 'pro' ? Icons.business : Icons.person,
      size: radius * 0.8,
      color: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Center(child: _buildFallbackContent());
    final avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _defaultBackgroundColor(),
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasValidAvatar
          ? Image(
              image: _buildImageProvider(),
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (_, __, ___) => fallback,
            )
          : fallback,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatarWidget);
    }

    return avatarWidget;
  }
}
