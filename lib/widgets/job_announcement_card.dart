import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';

class JobAnnouncementCard extends StatelessWidget {
  final String companyLogo;
  final String companyName;
  final String jobTitle;
  final String description;
  final List<JobDetailTag> tags;
  final List<String>? advantages;
  final String timeAgo;
  final VoidCallback? onApply;
  final Widget? reactionBar;
  final VoidCallback? onAvatarTap;
  final bool isFavorited;
  final VoidCallback? onFavoriteToggle;
  final bool isLoadingFavorite;
  final VoidCallback? onReport;

  const JobAnnouncementCard({
    super.key,
    required this.companyLogo,
    required this.companyName,
    required this.jobTitle,
    required this.description,
    required this.tags,
    this.advantages = const [],
    required this.timeAgo,
    this.onApply,
    this.reactionBar,
    this.onAvatarTap,
    this.isFavorited = false,
    this.onFavoriteToggle,
    this.isLoadingFavorite = false,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context, Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AdaptiveColors.border(
            context,
            Colors.grey,
          ).withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AdaptiveColors.surface(
                          context,
                          const Color(0xFFE6F7EF),
                        ),
                        border: Border.all(
                          color: AdaptiveColors.border(
                            context,
                            const Color(0xFF3AAE5E),
                          ).withValues(alpha: 0.2),
                        ),
                        image: companyLogo.isNotEmpty
                            ? DecorationImage(
                                image: companyLogo.startsWith('http')
                                    ? NetworkImage(companyLogo)
                                    : AssetImage(companyLogo) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: companyLogo.isEmpty
                          ? Icon(
                              Icons.business_rounded,
                              color: AdaptiveColors.foreground(
                                context,
                                Color(0xFF1B8D4B),
                              ),
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: onAvatarTap,
                                child: Text(
                                  companyName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AdaptiveColors.foreground(
                                      context,
                                      Color(0xFF616161),
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (onReport != null) ...[
                              IconButton(
                                tooltip: 'Signaler',
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: onReport,
                                icon: Icon(
                                  Icons.report_outlined,
                                  color: AdaptiveColors.foreground(
                                    context,
                                    Colors.redAccent,
                                  ),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            // Favorite heart button
                            GestureDetector(
                              onTap: isLoadingFavorite
                                  ? null
                                  : onFavoriteToggle,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AdaptiveColors.surface(
                                    context,
                                    Colors.white,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isLoadingFavorite
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AdaptiveColors.foreground(
                                            context,
                                            Colors.grey[600],
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        isFavorited
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorited
                                            ? AdaptiveColors.foreground(
                                                context,
                                                Colors.red,
                                              )
                                            : AdaptiveColors.foreground(
                                                context,
                                                Colors.grey[600],
                                              ),
                                        size: 18,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AdaptiveColors.surface(
                              context,
                              const Color(0xFFE6F7EF),
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AdaptiveColors.border(
                                context,
                                const Color(0xFF3AAE5E),
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'Pro',
                            style: TextStyle(
                              fontSize: 10,
                              color: AdaptiveColors.foreground(
                                context,
                                Color(0xFF3AAE5E),
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.surface(
                      context,
                      const Color(0xFF3AAE5E),
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AdaptiveColors.border(
                        context,
                        const Color(0xFF3AAE5E),
                      ).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 14,
                        color: AdaptiveColors.foreground(
                          context,
                          Color(0xFF3AAE5E),
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Offre d\'emploi',
                        style: TextStyle(
                          color: AdaptiveColors.foreground(
                            context,
                            Color(0xFF3AAE5E),
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Job Title
              Text(
                jobTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AdaptiveColors.foreground(context, Color(0xFF757575)),
                ),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1),
              const SizedBox(height: 15),
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags
                    .map((tag) => _buildDetailTag(context, tag))
                    .toList(),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1),
              const SizedBox(height: 15),
              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AdaptiveColors.foreground(context, Color(0xFF616161)),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1),
              const SizedBox(height: 15),
              // Avantages (only show if not null and not empty)
              if (advantages?.isNotEmpty == true) ...[
                Text(
                  'Avantages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AdaptiveColors.foreground(
                      context,
                      Color(0xFF616161),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: advantages!
                      .map((adv) => _buildAdvantageTag(context, adv))
                      .toList(),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1),
                const SizedBox(height: 15),
              ],
              // Footer - button only (timeAgo moved below)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.work_outline, size: 18),
                  label: const Text("Voir l'offre d'emploi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdaptiveColors.surface(
                      context,
                      const Color(0xFFFF9800),
                    ),
                    foregroundColor: AdaptiveColors.foreground(
                      context,
                      Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              if (reactionBar != null) ...[
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 10),
                reactionBar!,
                const SizedBox(height: 10),
                const Divider(height: 1),
              ],
              // Time ago below reaction section
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 4, right: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AdaptiveColors.foreground(
                        context,
                        Colors.grey,
                      ).withValues(alpha: 0.7),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: AdaptiveColors.foreground(context, Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTag(BuildContext context, JobDetailTag tag) {
    final isSpecial = tag.isSpecial;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSpecial
            ? AdaptiveColors.surface(context, const Color(0xFFE6F7EF))
            : AdaptiveColors.surface(context, const Color(0xFFF5F5F5)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSpecial
              ? AdaptiveColors.border(
                  context,
                  const Color(0xFF3AAE5E),
                ).withValues(alpha: 0.5)
              : AdaptiveColors.border(
                  context,
                  Colors.grey,
                ).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 16,
            color: isSpecial
                ? AdaptiveColors.foreground(context, const Color(0xFF3AAE5E))
                : AdaptiveColors.foreground(context, Colors.grey),
          ),
          const SizedBox(width: 6),
          Text(
            tag.text,
            style: TextStyle(
              fontSize: 12,
              color: isSpecial
                  ? AdaptiveColors.foreground(context, const Color(0xFF3AAE5E))
                  : AdaptiveColors.foreground(context, Colors.grey),
              fontWeight: isSpecial ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context, const Color(0xFFE6F7EF)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AdaptiveColors.border(
            context,
            const Color(0xFF3AAE5E),
          ).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AdaptiveColors.foreground(context, Color(0xFF3AAE5E)),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class JobDetailTag {
  final IconData icon;
  final String text;
  final bool isSpecial;

  const JobDetailTag({
    required this.icon,
    required this.text,
    this.isSpecial = false,
  });
}
