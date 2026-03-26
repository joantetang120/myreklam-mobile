import 'package:flutter/material.dart';

class EvenementCard extends StatelessWidget {
  final String profileImage;
  final String username;
  final String userType;
  final String eventTitle;
  final String eventImage;
  final String? badge;
  final List<String> categories;
  final String eventDate;
  final String location;
  final String timeAgo;
  final String price;
  final int likesCount;
  final int commentsCount;
  final VoidCallback? onTapCTA;
  final Widget? reactionBar;

  const EvenementCard({
    super.key,
    required this.profileImage,
    required this.username,
    required this.userType,
    required this.eventTitle,
    required this.eventImage,
    this.badge,
    required this.categories,
    required this.eventDate,
    required this.location,
    required this.timeAgo,
    required this.price,
    required this.likesCount,
    required this.commentsCount,
    this.onTapCTA,
    this.reactionBar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(profileImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF616161),
                      ),
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
                      child: Text(
                        userType,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF3AAE5E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 15),
          // Event Title
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              children: [
                TextSpan(text: eventTitle),
                const TextSpan(
                  text: '...plus',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Event Image with Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: eventImage.startsWith('http://') || eventImage.startsWith('https://')
                    ? Image.network(
                        eventImage,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Image non disponible',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        eventImage,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[200],
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Image par défaut',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_offer_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              cat,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            if (categories.indexOf(cat) <
                                categories.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text('|',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Date tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7EF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF3AAE5E).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_month,
                    size: 16, color: Color(0xFF3AAE5E)),
                const SizedBox(width: 6),
                Text(
                  eventDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3AAE5E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Location and time
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                timeAgo,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Price and CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onTapCTA,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: const Text("Voir l'évènement"),
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
          if (reactionBar != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 10),
            reactionBar!,
            const SizedBox(height: 10),
            const Divider(height: 1),
          ],
          const SizedBox(height: 10),
        ],
      ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2196F3), const Color(0xFF2196F3).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Événement',
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
}
