import 'package:flutter/material.dart';
import 'package:myreklam/widgets/avatars_story.dart';
import 'package:myreklam/widgets/chat_item_widget.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/add_story_screen.dart';
import 'package:myreklam/screens/my_stories_screen.dart';
import 'package:myreklam/screens/story_viewer_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/models/chat_conversation.dart';
import 'package:myreklam/services/story_store.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/api_chat_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:intl/intl.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  bool _showAllMessages = true;
  final StoryStore _storyStore = StoryStore();
  final ConversationService _conversationService = ConversationService();
  final ApiChatService _chatService = ApiChatService();
  final TextEditingController _searchController = TextEditingController();

  int? _currentUserId;
  List<ChatConversation> _allConversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await ApiClient().authenticatedGet('/user');
      final userId = response['data']?['id'] as int?;
      if (mounted && userId != null) {
        setState(() {
          _currentUserId = userId;
        });
        await _loadConversations();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _conversationService.getConversations();
      if (mounted) {
        setState(() {
          _allConversations = conversations;
          _filteredConversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ChatConversation> get _displayedConversations {
    if (_showAllMessages) {
      return _filteredConversations;
    } else {
      return _filteredConversations.where((conv) {
        return conv.unreadCount > 0;
      }).toList();
    }
  }

  int get _unreadCount {
    return _allConversations.where((conv) {
      return conv.unreadCount > 0;
    }).length;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredConversations = _allConversations;
      } else {
        _filteredConversations = _allConversations.where((conv) {
          final otherUserName = conv.getOtherUserName().toLowerCase();
          final lastMessage = conv.lastMessage?.toLowerCase() ?? '';
          return otherUserName.contains(query.toLowerCase()) ||
              lastMessage.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}j';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  void _openConversation(ChatConversation conversation) async {
    if (_currentUserId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(
          conversationId: conversation.id.toString(),
          name: conversation.getOtherUserName(),
          avatar: conversation.getOtherUserAvatar(),
        ),
      ),
    );

    // Marquer les messages comme lus
    await _chatService.markAsRead(conversation.id);

    // Recharger les conversations pour mettre à jour le compteur
    await _loadConversations();
  }

  Future<void> _handleStoryEntryTap() async {
    if (_storyStore.stories.isEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddStoryScreen()),
      );
      if (result is StoryModel) {
        _storyStore.addStory(result);
      }
    } else {
      final updatedStories = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyStoriesScreen(
            stories: _storyStore.stories,
            userName: 'Vous',
            userAvatar: 'assets/images/dashboard_particulier/Ellipse 10.png',
          ),
        ),
      );
      if (updatedStories is List<StoryModel>) {
        _storyStore.replaceStories(updatedStories);
      }
    }
  }

  void _openStory(BuildContext context, String name, String avatar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          name: name,
          avatar: avatar,
          stories: const [
            {
              'image': 'assets/images/story/Rectangle 113.png',
              'text':
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              'time': 'Aujourd\'hui 10 : 30',
            },
            {
              'image': 'assets/images/story/Rectangle 113.png',
              'text':
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              'time': 'Aujourd\'hui 11 : 00',
            },
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 10),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Color(0xFF616161),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ParticulierMainScreen(initialIndex: 0),
              ),
            );
          },
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Faites une recherche...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Story Section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ValueListenableBuilder<List<StoryModel>>(
                  valueListenable: _storyStore.storiesNotifier,
                  builder: (_, userStories, __) {
                    final hasStories = userStories.isNotEmpty;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _handleStoryEntryTap,
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: _handleStoryEntryTap,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        hasStories ? 2 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFE6F7EF),
                                        border: Border.all(
                                          color: const Color(0xFF3AAE5E),
                                          width: hasStories ? 2.5 : 1,
                                        ),
                                      ),
                                      child: hasStories
                                          ? const CircleAvatar(
                                              radius: 22,
                                              backgroundImage: AssetImage(
                                                'assets/images/dashboard_particulier/Ellipse 10.png',
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.add,
                                                color: Color(0xFF3AAE5E),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (hasStories)
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AddStoryScreen(),
                                            ),
                                          );
                                          if (result is StoryModel) {
                                            _storyStore.addStory(result);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3AAE5E),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                "Votre story",
                                style: TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AvatarsStory(
                          name: "Selena",
                          imageName:
                              'assets/images/dashboard_particulier/Ellipse 10.png',
                          onTap: () => _openStory(
                            context,
                            'Selena',
                            'assets/images/dashboard_particulier/Ellipse 10.png',
                          ),
                        ),
                        const SizedBox(width: 12),
                        AvatarsStory(
                          name: "Slime",
                          imageName:
                              'assets/images/dashboard_particulier/Ellipse 10 (1).png',
                          onTap: () => _openStory(
                            context,
                            'Slime',
                            'assets/images/dashboard_particulier/Ellipse 10 (1).png',
                          ),
                        ),
                        const SizedBox(width: 12),
                        AvatarsStory(
                          name: "Joe",
                          imageName:
                              'assets/images/dashboard_particulier/Ellipse 10 (2).png',
                          onTap: () => _openStory(
                            context,
                            'Joe',
                            'assets/images/dashboard_particulier/Ellipse 10 (2).png',
                          ),
                        ),
                        const SizedBox(width: 12),
                        AvatarsStory(
                          name: "Joe",
                          imageName:
                              'assets/images/dashboard_particulier/Ellipse 10 (3).png',
                          onTap: () => _openStory(
                            context,
                            'Joe',
                            'assets/images/dashboard_particulier/Ellipse 10 (3).png',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Messages Label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Messages",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Filter Tabs
              Row(
                children: [
                  _buildTab(
                    'Tout (${_allConversations.length})',
                    _showAllMessages,
                    () {
                      setState(() => _showAllMessages = true);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildTab('Non-lues ($_unreadCount)', !_showAllMessages, () {
                    setState(() => _showAllMessages = false);
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Chat List with Firebase StreamBuilder
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_currentUserId == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Erreur de chargement',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final displayedConvs = _displayedConversations;

                    if (displayedConvs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _showAllMessages
                                ? 'Aucune conversation'
                                : 'Aucun message non lu',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedConvs.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF0F0F0),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final conversation = displayedConvs[index];
                          final otherUserName = conversation.getOtherUserName();
                          final otherUserAvatar = conversation
                              .getOtherUserAvatar();
                          final unreadCount = conversation.unreadCount;

                          return GestureDetector(
                            onTap: () => _openConversation(conversation),
                            child: ChatItemWidget(
                              image:
                                  otherUserAvatar ??
                                  'assets/images/dashboard_particulier/Ellipse 10.png',
                              name: otherUserName,
                              text: conversation.lastMessage ?? 'Aucun message',
                              time: _formatTime(conversation.lastMessageTime),
                              isRead: unreadCount == 0,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3AAE5E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
