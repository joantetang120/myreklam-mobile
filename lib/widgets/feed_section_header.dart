import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A clear entry to Reels beside the feed, away from account actions.
class FeedSectionHeader extends StatelessWidget {
  final VoidCallback onOpenReels;

  const FeedSectionHeader({super.key, required this.onOpenReels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              "Fil d'actualités",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onOpenReels,
            icon: const Icon(Icons.smart_display_outlined, size: 22),
            label: const Text('Reels'),
            style: TextButton.styleFrom(
              foregroundColor: AdaptiveColors.foreground(
                context,
                const Color(0xFF2A8143),
              ),
              backgroundColor: AdaptiveColors.surface(
                context,
                const Color(0xFFEAF6EE),
              ),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
