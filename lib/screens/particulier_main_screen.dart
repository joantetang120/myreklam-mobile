import 'package:flutter/material.dart';
import 'package:myreklam/screens/particulier_dashboard_screen.dart';
import 'package:myreklam/screens/message_screen.dart';
import 'package:myreklam/screens/publier_screen.dart';
import 'package:myreklam/screens/publish_options_screen.dart';
import 'package:myreklam/screens/create_post_screen.dart';
import 'package:myreklam/screens/search_screen.dart';
import 'package:myreklam/screens/search_results_screen.dart';
import 'package:myreklam/screens/profile_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_profile_screen.dart';
import 'package:myreklam/services/chat_notification_service.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:provider/provider.dart';

class ParticulierMainScreen extends StatefulWidget {
  static const String routeName = '/particulier_main';
  final int initialIndex;
  final bool showPublishOptions;
  final bool showCreatePost;
  final bool showSearchResults;
  final String? searchQuery;
  final String? searchCategory;
  final String? searchLocation;
  final double? searchRadius;
  final bool? searchAllFrance;
  const ParticulierMainScreen({
    super.key,
    this.initialIndex = 0,
    this.showPublishOptions = false,
    this.showCreatePost = false,
    this.showSearchResults = false,
    this.searchQuery,
    this.searchCategory,
    this.searchLocation,
    this.searchRadius,
    this.searchAllFrance,
  });

  @override
  State<ParticulierMainScreen> createState() => _ParticulierMainScreenState();
}

class _ParticulierMainScreenState extends State<ParticulierMainScreen> {
  late int _currentIndex;
  late bool _showPublishOptions;
  late bool _showCreatePost;
  late bool _showSearchResults;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _showPublishOptions = widget.showPublishOptions;
    _showCreatePost = widget.showCreatePost;
    _showSearchResults = widget.showSearchResults;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatNotificationService.instance.init();
    });
  }

  List<Widget> get _pages => [
    const ParticulierDashboardScreen(),
    const MessageScreen(),
    const Scaffold(body: Center(child: Text('Publier Screen'))),
    const SearchScreen(),
    UserSession().isPro ? const ProfileProScreen() : const ProfileScreen(),
  ];

  void _handleTabTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PublierScreen(),
          fullscreenDialog: true,
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
        _showPublishOptions = false;
        _showCreatePost = false;
        _showSearchResults = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    int displayIndex = _currentIndex;

    if (_showPublishOptions) {
      body = const PublishOptionsScreen();
      displayIndex = 2;
    } else if (_showCreatePost) {
      body = const CreatePostScreen();
      displayIndex = 2;
    } else if (_showSearchResults) {
      body = SearchResultsScreen(
        query: widget.searchQuery ?? '',
        category: widget.searchCategory,
        location: widget.searchLocation ?? '',
        radius: widget.searchRadius ?? 0,
        allFrance: widget.searchAllFrance ?? false,
      );
      displayIndex = 3;
    } else {
      body = IndexedStack(index: _currentIndex, children: _pages);
    }

    return AppLayout(
      currentIndex: displayIndex,
      onTabTapped: _handleTabTapped,
      body: body,
    );
  }
}
