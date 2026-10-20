import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myreklam/utils/social_url.dart';
import 'package:myreklam/services/share_service.dart';

class AdditionalSocialLinks extends StatelessWidget {
  const AdditionalSocialLinks({super.key, required this.links, this.profileId});
  final Map<String, dynamic> links;
  final String? profileId;

  @override
  Widget build(BuildContext context) {
    const labels = {
      'website': 'Site web',
      'x': 'X',
      'tiktok': 'TikTok',
      'dribbble': 'Dribbble',
    };
    final entries = <MapEntry<String, String>>[];
    for (final entry in labels.entries) {
      try {
        final url = normalizeSocialUrl(
          entry.key,
          links[entry.key]?.toString() ?? '',
        );
        if (url.isNotEmpty) entries.add(MapEntry(entry.value, url));
      } on FormatException {
        // Do not expose an unsafe legacy URL as a clickable link.
      }
    }
    if (entries.isEmpty && profileId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (profileId?.isNotEmpty == true)
            OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Partager ce profil'),
              onPressed: () => ShareService.shareEntity('profiles', profileId!),
            ),
          ...entries.map(
            (entry) => OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(entry.key),
              onPressed: () async {
                var opened = false;
                try {
                  opened = await launchUrl(
                    Uri.parse(entry.value),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  opened = false;
                }
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible d’ouvrir ce lien.'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
