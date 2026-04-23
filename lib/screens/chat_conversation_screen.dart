import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myreklam/widgets/message_bubble.dart';
import 'package:myreklam/models/chat_message.dart';
import 'package:myreklam/providers/conversation_provider.dart';
import 'package:myreklam/services/api_client.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String? avatar;
  final String status;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.name,
    this.avatar,
    this.status = 'En ligne',
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  late ConversationProvider _conversationProvider;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    // Écouter les changements de messages pour auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _conversationProvider = Provider.of<ConversationProvider>(
        context,
        listen: false,
      );
      _conversationProvider.addListener(_onMessagesChanged);
    });
  }

  void _onMessagesChanged() {
    // Auto-scroll quand nouveau message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final userData = response['user'];
      if (mounted && userData != null) {
        setState(() {
          _currentUserId = int.tryParse(userData['id']);
          _isLoading = false;
        });

        // Charger les messages de la conversation
        final conversationProvider = Provider.of<ConversationProvider>(
          context,
          listen: false,
        );
        final conversationId = int.tryParse(widget.conversationId);
        print("DEBUG: Conversation ID: $conversationId");
        if (conversationId != null) {
          try {
            print("DEBUG: Starting to load messages...");
            await conversationProvider.loadMessages(conversationId);
            print("DEBUG: Messages loaded successfully");
          } catch (e) {
            print("DEBUG: Error loading messages: $e");
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null)
      return;

    // Prevent duplicate sends with synchronous check
    if (_isSending) return;
    _isSending = true;

    final messageText = _messageController.text.trim();
    _messageController.clear();
    setState(() {});

    try {
      final conversationId = int.tryParse(widget.conversationId);

      if (conversationId != null) {
        await _conversationProvider.sendMessage(conversationId, messageText);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Echec de l\'envoi'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isSending = false;
        setState(() {});
      }
    }
  }

  Future<void> _sendImage() async {
    // TODO: Implémenter l'envoi d'images via l'API Laravel
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Envoi d\'images bientôt disponible'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Aujourd\'hui';
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool _shouldShowDateHeader(int index, List<dynamic> messages) {
    if (index == 0) return true;
    final currentDate = DateTime(
      messages[index].createdAt.year,
      messages[index].createdAt.month,
      messages[index].createdAt.day,
    );
    final previousDate = DateTime(
      messages[index - 1].createdAt.year,
      messages[index - 1].createdAt.month,
      messages[index - 1].createdAt.day,
    );
    return currentDate != previousDate;
  }

  void _showMessageOptions(ChatMessage message) {
    final conversationId = int.tryParse(widget.conversationId);
    if (conversationId == null) return;

    final canEdit =
        message.isMe &&
        DateTime.now().difference(message.createdAt).inMinutes <= 2;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF3AAE5E)),
                  title: const Text('Modifier'),
                  subtitle: const Text(
                    'Disponible dans les 2 premi\u00e8res minutes',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(conversationId, message);
                  },
                ),
              if (message.isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Supprimer pour tout le monde'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(conversationId, message.id, 'for_everyone');
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.grey[700],
                ),
                title: const Text('Supprimer pour moi'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(conversationId, message.id, 'for_me');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(int conversationId, ChatMessage message) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Nouveau message...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isEmpty || newText == message.text) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              try {
                await _conversationProvider.editMessage(
                  conversationId,
                  message.id,
                  newText,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text(
              'Modifier',
              style: TextStyle(color: Color(0xFF3AAE5E)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    int conversationId,
    int messageId,
    String deleteType,
  ) async {
    try {
      await _conversationProvider.deleteMessage(
        conversationId,
        messageId,
        deleteType,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    // Utiliser la référence sauvegardée au lieu d'accéder à Provider
    try {
      _conversationProvider.removeListener(_onMessagesChanged);

      // final conversationId = int.tryParse(widget.conversationId);
      // if (conversationId != null) {
      //   _conversationProvider.unsubscribeFromConversation(conversationId);
      // }
    } catch (e) {
      // Ignorer les erreurs lors du dispose
      debugPrint('Error in dispose: $e');
    }

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3AAE5E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image:
                    widget.avatar != null &&
                        (widget.avatar!.startsWith('https') ||
                            (widget.avatar!.startsWith('http')))
                    ? DecorationImage(
                        image: NetworkImage("${widget.avatar}"),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(
                        image: NetworkImage(
                          "${ApiConfig.baseUrl.replaceFirst('/api', '')}/storage/${widget.avatar}",
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
              child: widget.avatar == null
                  ? Image.asset(
                      "assets/images/dashboard_particulier/Ellipse 10.png",
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    widget.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Shared Post Card
          // Container(
          //   margin: const EdgeInsets.all(16),
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(12),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(0.05),
          //         blurRadius: 8,
          //         offset: const Offset(0, 2),
          //       ),
          //     ],
          //   ),
          //   child: Row(
          //     children: [
          //       ClipRRect(
          //         borderRadius: BorderRadius.circular(8),
          //         child: Image.asset(
          //           'assets/images/dashboard_particulier/Rectangle 12 (1).png',
          //           width: 70,
          //           height: 70,
          //           fit: BoxFit.cover,
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             const Text(
          //               'Catégorie : Bons Plans',
          //               style: TextStyle(
          //                 fontSize: 12,
          //                 fontWeight: FontWeight.w600,
          //                 color: Color(0xFF616161),
          //               ),
          //             ),
          //             const SizedBox(height: 4),
          //             const Text(
          //               'Promo Appareil photo Hybride Sony A6400 Noir + Objectif E PZ 16-50 mm...',
          //               style: TextStyle(fontSize: 11, color: Colors.grey),
          //               maxLines: 2,
          //               overflow: TextOverflow.ellipsis,
          //             ),
          //             const SizedBox(height: 6),
          //             Row(
          //               children: [
          //                 Icon(
          //                   Icons.access_time,
          //                   size: 12,
          //                   color: Colors.grey[600],
          //                 ),
          //                 const SizedBox(width: 4),
          //                 Text(
          //                   'Publié il y a 1 semaine',
          //                   style: TextStyle(
          //                     fontSize: 10,
          //                     color: Colors.grey[600],
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // Messages List with ChatProvider
          Expanded(
            child: _isLoading || _currentUserId == null
                ? const Center(child: CircularProgressIndicator())
                : Consumer<ConversationProvider>(
                    builder: (context, chatProvider, child) {
                      final conversationId = int.tryParse(
                        widget.conversationId,
                      );
                      if (conversationId == null) {
                        return const Center(
                          child: Text(
                            'ID de conversation invalide',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final messages = chatProvider.getMessages(conversationId);

                      if (chatProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'Commencer a discuter avec ${widget.name}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isSent = message.isMe;

                          // Calculer si supprimé pour moi
                          final isDeletedForMe = isSent
                              ? message.deletedForSender
                              : message.deletedForReceiver;

                          // Vérifier si on doit afficher l'en-tête de date
                          final showDateHeader = _shouldShowDateHeader(
                            index,
                            messages,
                          );

                          // Afficher le message avec en-tête de date si nécessaire
                          return Column(
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatDateHeader(message.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              MessageBubble(
                                message: message.text,
                                time: _formatMessageTime(message.createdAt),
                                isSent: isSent,
                                isRead: message.isRead,
                                attachments: message.attachments,
                                isEdited: message.isEdited,
                                deletedForEveryone: message.deletedForEveryone,
                                isDeletedForMe: isDeletedForMe,
                                onLongPress: () => _showMessageOptions(message),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendImage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.image, color: Colors.grey[700], size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : const Color(0xFF3AAE5E),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
