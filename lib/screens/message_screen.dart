import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myreklam/config/api_config.dart';
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
import 'package:myreklam/services/story_service.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/providers/conversation_provider.dart';
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
  final ConversationService _chatService = ConversationService();
  final TextEditingController _searchController = TextEditingController();
  ConversationProvider? _conversationProvider;
  Timer? _refreshTimer;

  int? _currentUserId;
  String? _currentUserAvatar;
  List<ChatConversation> _allConversations = [];
  List<ChatConversation> _filteredConversations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Track which users' stories have been fully viewed
  Set<int> _fullyViewedUserIds = {};
  // Track if user has viewed their own stories (opened the story viewer)
  bool _hasViewedOwnStories = false;

  String _buildAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    // Handle relative paths like avatar/filename.jpg or /storage/avatar/filename.jpg
    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl/storage/$avatarUrl';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _storyStore.loadFeed();
    _loadViewedStatus();

    // Écouter les mises à jour du ConversationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _conversationProvider = Provider.of<ConversationProvider>(
          context,
          listen: false,
        );
        _conversationProvider?.addListener(_onConversationsUpdated);
      }
    });

    // Rafraîchissement automatique toutes les 30 secondes
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _currentUserId != null) {
        _loadConversations();
      } else if (!mounted) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _conversationProvider?.removeListener(_onConversationsUpdated);
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Timer? _debounceTimer;

  void _onConversationsUpdated() {
    if (mounted) {
      // Debounce pour éviter de spammer /api/conversations
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _loadConversations();
      });
    }
  }

  List<ChatConversation> _applySearch(List<ChatConversation> conversations) {
    if (_searchQuery.isEmpty) {
      return conversations;
    }
    return conversations.where((conv) {
      final otherUserName = conv.getOtherUserName().toLowerCase();
      final lastMessage = conv.lastMessage?.toLowerCase() ?? '';
      final searchLower = _searchQuery.toLowerCase();
      return otherUserName.contains(searchLower) ||
          lastMessage.contains(searchLower);
    }).toList();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final userId = int.tryParse(response['user']?['id']);
      final profile = response['profile'] as Map<String, dynamic>?;
      final avatarUrl =
          profile?['avatar_url']?.toString() ?? profile?['avatar']?.toString();

      if (mounted && userId != null) {
        setState(() {
          _currentUserId = userId;
          _currentUserAvatar = avatarUrl;
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
      final conversations = await _conversationService.getConversations(
        currentUserId: _currentUserId,
      );
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

  Future<void> _refreshConversations() async {
    await _loadConversations();
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
      _filteredConversations = _applySearch(_allConversations);
    });
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes == 0) {
      return "A l'instant";
    }
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
          avatar: conversation.otherUserAvatar,
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyStoriesScreen(
            stories: _storyStore.stories,
            userName: 'Vous',
            userAvatar: _currentUserAvatar ?? _defaultAvatar,
          ),
        ),
      );
    }
  }

  static const _defaultAvatar =
      'assets/images/dashboard_particulier/Ellipse 10.png';

  void _openStory(BuildContext context, StoryUserGroup group) {
    debugPrint('Opening story for user ${group.userId}, isOwn: ${group.isOwn}');
    final storyMaps = group.stories.map((s) {
      final resolvedImage = ApiConfig.resolveMediaUrl(s.mediaUrl);
      final diff = DateTime.now().difference(s.timestamp);
      String time;
      if (diff.inMinutes < 1) {
        time = "À l'instant";
      } else if (diff.inMinutes < 60) {
        time = "il y a ${diff.inMinutes} min";
      } else if (diff.inHours < 24) {
        time = "il y a ${diff.inHours}h";
      } else {
        time = "il y a ${diff.inDays}j";
      }
      return {
        'image': resolvedImage ?? '',
        'text': s.caption,
        'time': time,
        'id': s.id,
        'views_count': s.viewsCount,
      };
    }).toList();

    final resolvedAvatar = ApiConfig.resolveMediaUrl(group.userAvatar);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          name: group.userName,
          avatar: resolvedAvatar ?? _defaultAvatar,
          stories: storyMaps,
          isOwnStory: group.isOwn,
          ownerId: group.userId,
        ),
      ),
    ).then((_) {
      // Reload viewed status after watching stories
      debugPrint('Story viewer closed, reloading viewed status...');

      // If it was own story, mark as viewed locally
      if (group.isOwn) {
        debugPrint('Own story viewed, marking as viewed locally');
        setState(() {
          _hasViewedOwnStories = true;
        });
      }

      _loadViewedStatus();
    });
  }

  Future<void> _loadViewedStatus() async {
    try {
      debugPrint('Loading viewed status...');
      final viewedIds = await StoryService().getFullyViewedUserIds();
      debugPrint('Fully viewed user IDs: $viewedIds');
      if (mounted) {
        setState(() {
          _fullyViewedUserIds = viewedIds.toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading viewed status: $e');
    }
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
      body: RefreshIndicator(
        onRefresh: _refreshConversations,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: ValueListenableBuilder<List<StoryUserGroup>>(
                    valueListenable: _storyStore.feedNotifier,
                    builder: (context, feedGroups, __) {
                      final ownGroup = feedGroups
                          .where((g) => g.isOwn)
                          .toList();

                      // Separate viewed and unviewed groups
                      final otherGroups = feedGroups
                          .where((g) => !g.isOwn)
                          .toList();

                      final unviewedGroups = otherGroups
                          .where((g) => !_fullyViewedUserIds.contains(g.userId))
                          .toList();
                      final viewedGroups = otherGroups
                          .where((g) => _fullyViewedUserIds.contains(g.userId))
                          .toList();

                      // Combine: unviewed first, then viewed (WhatsApp-like behavior)
                      final sortedOtherGroups = [
                        ...unviewedGroups,
                        ...viewedGroups,
                      ];

                      final hasOwnStories =
                          ownGroup.isNotEmpty &&
                          ownGroup.first.stories.isNotEmpty;

                      // Check if current user's own stories have been fully viewed
                      // For own stories, we track locally since backend doesn't record own views
                      final currentUserId = _currentUserId;
                      final ownStoriesViewed =
                          currentUserId != null &&
                          (_fullyViewedUserIds.contains(currentUserId) ||
                              _hasViewedOwnStories);

                      return SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                            hasOwnStories ? 2 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                hasOwnStories &&
                                                    !ownStoriesViewed
                                                ? const Color(0xFFE6F7EF)
                                                : Colors.grey.shade200,
                                            border: Border.all(
                                              color:
                                                  hasOwnStories &&
                                                      !ownStoriesViewed
                                                  ? const Color(0xFF3AAE5E)
                                                  : Colors.grey.shade400,
                                              width: hasOwnStories ? 2.5 : 1.5,
                                            ),
                                          ),
                                          child: hasOwnStories
                                              ? CircleAvatar(
                                                  radius: 22,
                                                  backgroundImage:
                                                      _currentUserAvatar !=
                                                              null &&
                                                          _currentUserAvatar!
                                                              .isNotEmpty
                                                      ? NetworkImage(
                                                          _buildAvatarUrl(
                                                            _currentUserAvatar,
                                                          ),
                                                        )
                                                      : const AssetImage(
                                                              'assets/images/dashboard_particulier/Ellipse 10.png',
                                                            )
                                                            as ImageProvider,
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    color: Color(0xFF3AAE5E),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (hasOwnStories)
                                        Positioned(
                                          bottom: -2,
                                          right: -2,
                                          child: GestureDetector(
                                            onTap: () async {
                                              final result =
                                                  await Navigator.push(
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
                            // Other users' stories from API feed
                            ...sortedOtherGroups.map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: AvatarsStory(
                                  name: group.userName.split(' ').first,
                                  imageName: group.userAvatar ?? _defaultAvatar,
                                  onTap: () => _openStory(context, group),
                                  isViewed: _fullyViewedUserIds.contains(
                                    group.userId,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    _buildTab(
                      'Non-lues ($_unreadCount)',
                      !_showAllMessages,
                      () {
                        setState(() => _showAllMessages = false);
                      },
                    ),
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
                            final otherUserName = conversation
                                .getOtherUserName();
                            final otherUserAvatar = conversation
                                .getOtherUserAvatar();
                            final unreadCount = conversation.unreadCount;
                            final userType = conversation
                                .getFormattedUserType();
                            final isPro = conversation.isOtherUserPro;

                            return Dismissible(
                              key: Key('conversation_${conversation.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Supprimer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'Supprimer la conversation',
                                    ),
                                    content: const Text(
                                      'Cette conversation sera supprimée de votre liste. Vous ne verrez plus les messages précédents, mais vous pourrez recevoir de nouveaux messages.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                try {
                                  await _conversationService.deleteConversation(
                                    conversation.id,
                                  );
                                  setState(() {
                                    _allConversations.removeWhere(
                                      (c) => c.id == conversation.id,
                                    );
                                    _filteredConversations.removeWhere(
                                      (c) => c.id == conversation.id,
                                    );
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Conversation supprimée'),
                                        backgroundColor: Color(0xFF3AAE5E),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error deleting conversation: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  // Recharger les conversations en cas d'erreur
                                  await _loadConversations();
                                }
                              },
                              child: GestureDetector(
                                onTap: () => _openConversation(conversation),
                                child: ChatItemWidget(
                                  image:
                                      otherUserAvatar ??
                                      'assets/images/dashboard_particulier/Ellipse 10.png',
                                  name: otherUserName,
                                  text:
                                      conversation.lastMessage ??
                                      'Commencer a discuter avec $otherUserName',
                                  time: _formatTime(
                                    conversation.lastMessageTime,
                                  ),
                                  isRead: unreadCount == 0,
                                  isFromMe: conversation.isLastMessageFromMe,
                                  userType: userType.isNotEmpty
                                      ? userType
                                      : null,
                                  isPro: isPro,
                                  unreadCount: unreadCount,
                                ),
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
