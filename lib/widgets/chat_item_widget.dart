import 'package:flutter/material.dart';

class ChatItemWidget extends StatelessWidget {
  final String image;
  final String name;
  final String text;
  final String time;
  final bool isRead;
  final bool isFromMe;
  final VoidCallback? onTap;
  final String? userType;
  final bool isPro;
  final int unreadCount;

  const ChatItemWidget({
    super.key,
    required this.image,
    required this.name,
    required this.text,
    required this.time,
    required this.isRead,
    this.isFromMe = false,
    this.onTap,
    this.userType,
    this.isPro = false,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with unread count badge
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    backgroundImage: image.startsWith("assets")
                        ? AssetImage(image)
                        : NetworkImage(image),
                    radius: 24,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3AAE5E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: isRead
                                      ? const Color(0xFF616161)
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (userType != null && userType!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPro
                                      ? const Color(0xFF2E9B5B)
                                      : const Color(0xFF3AAE5E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  userType!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isRead
                              ? const Color(0xFF9E9E9E)
                              : const Color(0xFF3AAE5E),
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            color: isRead
                                ? const Color(0xFF9E9E9E)
                                : Colors.black,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (text.startsWith('Commencer a discuter avec'))
                        SizedBox.shrink()
                      else if (isFromMe && isRead)
                        // Double coche seulement pour nos messages lus
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.done_all,
                            size: 16,
                            color: Color(
                              0xFF2196F3,
                            ), // Blue color for read messages
                          ),
                        )
                      else if (isFromMe && !isRead)
                        // Simple coche seulement pour nos messages non lus
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.done_all,
                            size: 16,
                            color: Colors.grey, // Blue color for read messages
                          ),
                        )
                      else if (!isFromMe && !isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3AAE5E),
                          ),
                        )
                      else
                        // Pas d'icône pour les messages des autres utilisateurs
                        SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
