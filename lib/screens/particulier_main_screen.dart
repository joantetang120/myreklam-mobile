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
  final double? searchLocationLat;
  final double? searchLocationLng;
  final String? searchLocationCity;
  final String? searchLocationPostalCode;
  final double? searchRadius;
  final bool? searchAllFrance;
  final String? searchType;
  const ParticulierMainScreen({
    super.key,
    this.initialIndex = 0,
    this.showPublishOptions = false,
    this.showCreatePost = false,
    this.showSearchResults = false,
    this.searchQuery,
    this.searchCategory,
    this.searchLocation,
    this.searchLocationLat,
    this.searchLocationLng,
    this.searchLocationCity,
    this.searchLocationPostalCode,
    this.searchRadius,
    this.searchAllFrance,
    this.searchType,
  });

  @override
  State<ParticulierMainScreen> createState() => _ParticulierMainScreenState();
}

class _ParticulierMainScreenState extends State<ParticulierMainScreen> {
  late int _currentIndex;
  late bool _showPublishOptions;
  late bool _showCreatePost;
  late bool _showSearchResults;
  int _dashboardRefreshKey = 0;
  int _profileRefreshKey = 0;

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

  void _handlePostCreated() {
    setState(() {
      _showCreatePost = false;
      _currentIndex = 0;
      _dashboardRefreshKey++;
    });
  }

  void _handleCreatePostBack() {
    setState(() {
      _showCreatePost = false;
      _currentIndex = 0;
    });
  }

  List<Widget> get _pages => [
    ParticulierDashboardScreen(key: ValueKey(_dashboardRefreshKey)),
    const MessageScreen(),
    const Scaffold(body: Center(child: Text('Publier Screen'))),
    const SearchScreen(),
    UserSession().isPro ? ProfileProScreen(key: ValueKey(_profileRefreshKey)) : ProfileScreen(key: ValueKey(_profileRefreshKey)),
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
    } else if (index == 0 && _currentIndex == 0) {
      // Refresh dashboard when Accueil is tapped again
      setState(() {
        _dashboardRefreshKey++;
      });
    } else if (index == 4 && _currentIndex == 4) {
      // Refresh profile when Profile is tapped again
      setState(() {
        _profileRefreshKey++;
      });
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
      body = CreatePostScreen(
        onPostCreated: _handlePostCreated,
        onBackPressed: _handleCreatePostBack,
      );
      displayIndex = 2;
    } else if (_showSearchResults) {
      body = SearchResultsScreen(
        query: widget.searchQuery ?? '',
        category: widget.searchCategory,
        location: widget.searchLocation ?? '',
        locationLat: widget.searchLocationLat,
        locationLng: widget.searchLocationLng,
        locationCity: widget.searchLocationCity,
        locationPostalCode: widget.searchLocationPostalCode,
        radius: widget.searchRadius ?? 0,
        allFrance: widget.searchAllFrance ?? false,
        searchType: widget.searchType,
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
