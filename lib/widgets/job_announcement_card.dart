import 'package:flutter/material.dart';

class JobAnnouncementCard extends StatelessWidget {
  final String companyLogo;
  final String companyName;
  final String jobTitle;
  final String description;
  final List<JobDetailTag> tags;
  final List<String> advantages;
  final String timeAgo;
  final VoidCallback? onApply;

  const JobAnnouncementCard({
    super.key,
    required this.companyLogo,
    required this.companyName,
    required this.jobTitle,
    required this.description,
    required this.tags,
    required this.advantages,
    required this.timeAgo,
    this.onApply,
  });

  Widget _buildHeaderIcon(IconData icon, {required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.grey.withOpacity(0.7), size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE6F7EF),
                  border: Border.all(color: const Color(0xFF3AAE5E).withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF1B8D4B),
                  size: 24,
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
                          child: Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF616161),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.orange,
                          size: 18,
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
                        color: const Color(0xFFE6F7EF),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF3AAE5E).withOpacity(0.2),
                        ),
                      ),
                      child: const Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3AAE5E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderIcon(Icons.favorite_border, onPressed: () {}),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(Icons.share_outlined, onPressed: () {}),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(Icons.close, onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Job Title
          Text(
            jobTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF616161),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => _buildDetailTag(tag)).toList(),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),
          // Avantages
          const Text(
            'Avantages',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: advantages.map((adv) => _buildAdvantageTag(adv)).toList(),
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 15),
          // Footer
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.work_outline, size: 18),
                label: const Text("Voir l'offre d'emploi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
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
            ],
          ),
        ],
      ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3AAE5E), const Color(0xFF3AAE5E).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3AAE5E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Offre d\'emploi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTag(JobDetailTag tag) {
    final isSpecial = tag.isSpecial;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSpecial ? const Color(0xFFE6F7EF) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSpecial
              ? const Color(0xFF3AAE5E).withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 16,
            color: isSpecial ? const Color(0xFF3AAE5E) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            tag.text,
            style: TextStyle(
              fontSize: 12,
              color: isSpecial ? const Color(0xFF3AAE5E) : Colors.grey,
              fontWeight: isSpecial ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3AAE5E).withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF3AAE5E),
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
