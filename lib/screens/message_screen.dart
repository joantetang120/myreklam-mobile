import 'package:flutter/material.dart';
import 'package:myreklam/widgets/avatars_story.dart';
import 'package:myreklam/widgets/chat_item_widget.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/add_story_screen.dart';
import 'package:myreklam/screens/my_stories_screen.dart';
import 'package:myreklam/screens/story_viewer_screen.dart';
import 'package:myreklam/models/story_model.dart';
import 'package:myreklam/services/story_store.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  bool _showAllMessages = true;
  final StoryStore _storyStore = StoryStore();

  // Sample chat data
  final List<Map<String, dynamic>> _allChats = [
    {
      'name': 'Theresa Webb',
      'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
      'image': 'assets/images/dashboard_particulier/Ellipse 10.png',
      'time': '27 min',
      'isRead': true,
    },
    {
      'name': 'Jenny Wilson',
      'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
      'image': 'assets/images/dashboard_particulier/Ellipse 10 (1).png',
      'time': '30 min',
      'isRead': false,
    },
    {
      'name': 'Devon Lane',
      'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
      'image': 'assets/images/dashboard_particulier/Ellipse 10 (2).png',
      'time': '45min',
      'isRead': true,
    },
    {
      'name': 'Darrell Steward',
      'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
      'image': 'assets/images/dashboard_particulier/Ellipse 10 (3).png',
      'time': '1h',
      'isRead': false,
    },
    {
      'name': 'Kathryn Murphy',
      'message': 'Lorem ipsum dolor sit amet, consectetur adipiscing...',
      'image': 'assets/images/dashboard_particulier/Ellipse 11.png',
      'time': '2h',
      'isRead': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredChats {
    if (_showAllMessages) {
      return _allChats;
    } else {
      return _allChats.where((chat) => !chat['isRead']).toList();
    }
  }

  int get _unreadCount {
    return _allChats.where((chat) => !chat['isRead']).length;
  }

  Future<void> _handleStoryEntryTap() async {
    if (_storyStore.stories.isEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddStoryScreen(),
        ),
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
                builder: (context) => const ParticulierMainScreen(
                  initialIndex: 0,
                ),
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
                  child: const TextField(
                    decoration: InputDecoration(
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
                                      padding: EdgeInsets.all(hasStories ? 2 : 10),
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
                                              builder: (_) => const AddStoryScreen(),
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
                  _buildTab('Tout (${_allChats.length})', _showAllMessages, () {
                    setState(() => _showAllMessages = true);
                  }),
                  const SizedBox(width: 12),
                  _buildTab('Non-lues ($_unreadCount)', !_showAllMessages, () {
                    setState(() => _showAllMessages = false);
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Chat List with dividers
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredChats.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF0F0F0),
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final chat = _filteredChats[index];
                    return ChatItemWidget(
                      image: chat['image'],
                      name: chat['name'],
                      text: chat['message'],
                      time: chat['time'],
                      isRead: chat['isRead'],
                    );
                  },
                ),
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