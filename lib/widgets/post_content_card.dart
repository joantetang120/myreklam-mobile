import 'package:flutter/material.dart';

class PostTag {
  final String title;
  final IconData icon;
  final Color color;

  PostTag({required this.title, required this.icon, required this.color});
}

class PostContentCard extends StatelessWidget {
  final List<PostTag> tags;
  final PostTag? subtags;
  final String title;
  final String time;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final String? imageUrl;
  final List<String>? imageUrls;
  final VoidCallback? onMorePressed;

  const PostContentCard({
    super.key,
    required this.tags,
    this.subtags,
    required this.title,
    required this.time,
    this.onLike,
    this.onShare,
    this.imageUrl,
    this.imageUrls,
    this.onMorePressed,
  });

  List<String> get _effectiveUrls {
    if (imageUrls != null && imageUrls!.isNotEmpty) return imageUrls!;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (subtags != null) _buildTag(subtags!),
                ...tags.map((tag) => _buildTag(tag)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF616161),
              height: 1.4,
            ),
          ),
          // Post image(s)
          if (_effectiveUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMediaGrid(_effectiveUrls),
          ],
          const SizedBox(height: 16),
          // Divider
          Container(height: 1, color: Colors.grey.withOpacity(0.1)),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // IconButton(
                  //   onPressed: onLike,
                  //   icon: Icon(
                  //     Icons.favorite_border,
                  //     color: Colors.grey[500],
                  //     size: 20,
                  //   ),
                  //   padding: EdgeInsets.zero,
                  //   constraints: const BoxConstraints(),
                  // ),
                  // IconButton(
                  //   onPressed: onShare,
                  //   icon: Icon(Icons.reply, color: Colors.grey[500], size: 20),
                  //   padding: EdgeInsets.zero,
                  //   constraints: const BoxConstraints(),
                  // ),
                  if (onMorePressed != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onMorePressed,
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          urls[0],
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }
    if (urls.length == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: Image.network(
                  urls[0],
                  fit: BoxFit.cover,
                  height: 160,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Image.network(
                  urls[1],
                  fit: BoxFit.cover,
                  height: 160,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (urls.length == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Image.network(
                  urls[0],
                  fit: BoxFit.cover,
                  height: 180,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        urls[1],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Image.network(
                        urls[2],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 4+ images: 2x2 grid with overflow counter on the last cell
    final int remaining = urls.length - 4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Image.network(
                      urls[0],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Image.network(
                      urls[1],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Image.network(
                      urls[2],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          urls[3],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        if (remaining > 0)
                          Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: Text(
                              '+$remaining',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(PostTag tag) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tag.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tag.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 14, color: tag.color),
          const SizedBox(width: 6),
          Text(
            tag.title,
            style: TextStyle(
              color: tag.color,
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
