import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MyPostItem extends StatelessWidget {
  final String image;
  final String content;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCommentsTap;

  const MyPostItem({
    super.key,
    required this.image,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.onEdit,
    this.onDelete,
    this.onCommentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdaptiveColors.border(context, Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Publier il y a 2h',
                style: TextStyle(
                  fontSize: 12,
                  color: AdaptiveColors.foreground(context, Colors.grey[600]),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdaptiveColors.surface(
                          context,
                          const Color(0xFF3AAE5E),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AdaptiveColors.foreground(context, Colors.white),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdaptiveColors.surface(context, Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: AdaptiveColors.foreground(context, Colors.white),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: AdaptiveColors.foreground(context, Colors.grey[700]),
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(
                context,
                Icons.thumb_up_alt_outlined,
                likeCount.toString(),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onCommentsTap,
                child: _buildStat(
                  context,
                  Icons.chat_bubble_outline,
                  commentCount.toString(),
                ),
              ),
              // Bouton partager masqué
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String count) {
    return Row(
      children: [
        Icon(
          icon,
          color: AdaptiveColors.foreground(context, Colors.grey[600]),
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            color: AdaptiveColors.foreground(context, Colors.grey[600]),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
