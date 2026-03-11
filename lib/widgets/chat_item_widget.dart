import 'package:flutter/material.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';

class ChatItemWidget extends StatelessWidget {
  final String image;
  final String name;
  final String text;
  final String time;
  final bool isRead;

  const ChatItemWidget({
    super.key,
    required this.image,
    required this.name,
    required this.text,
    required this.time,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              name: name,
              avatar: image,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with unread indicator border
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRead ? Colors.transparent : const Color(0xFF3AAE5E),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: AssetImage(image),
                radius: 24,
              ),
            ),
            
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: isRead ? const Color(0xFF616161) : Colors.black,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: isRead ? const Color(0xFF9E9E9E) : const Color(0xFF3AAE5E),
                          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
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
                            color: isRead ? const Color(0xFF9E9E9E) : Colors.black,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRead)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.done_all,
                            size: 16,
                            color: Color(0xFF2196F3), // Blue color for read messages
                          ),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3AAE5E),
                          ),
                        ),
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