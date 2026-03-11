import 'package:flutter/material.dart';

class ProFollowScreen extends StatefulWidget {
  final int initialTab;

  const ProFollowScreen({super.key, this.initialTab = 0});

  @override
  State<ProFollowScreen> createState() => _ProFollowScreenState();
}

class _ProFollowScreenState extends State<ProFollowScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kristin Watson',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF757575),
              indicatorWeight: 3,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: '1000 Follower(s)'),
                Tab(text: '10 Suivie(s)'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFollowersList(), _buildFollowingList()],
      ),
    );
  }

  Widget _buildFollowersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 10,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Recherche',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Divider(color: Colors.grey[300]),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Tous les followers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFollowerItem(
                name: 'Darrell Steward veeeeeeveeveev',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 10.png',
                isFollowing: true,
              ),
              _buildFollowerItem(
                name: 'Bessie Cooper',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 11.png',
                isFollowing: true,
              ),
              _buildFollowerItem(
                name: 'Darrell Steward',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 10.png',
                isFollowing: true,
              ),
              _buildFollowerItem(
                name: 'Courtney Henry',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 11.png',
                isFollowing: true,
              ),
              _buildFollowerItem(
                name: 'Darrell Steward',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 10.png',
                isFollowing: true,
              ),
              _buildFollowerItem(
                name: 'Esther Howard',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 11.png',
                isFollowing: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowingList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 10,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Recherche',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Divider(color: Colors.grey[300]),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Suivie(s)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFollowingItem(
                name: 'Darrell Steward evevevevev',
                username: 'DarrelStew 10',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 10.png',
              ),
              _buildFollowingItem(
                name: 'Robert Fox',
                username: 'Robertfox',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 11.png',
              ),
              _buildFollowingItem(
                name: 'Robert Fox',
                username: 'Robertfox',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 10.png',
              ),
              _buildFollowingItem(
                name: 'Robert Fox',
                username: 'Robertfox',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 11.png',
              ),
              _buildFollowingItem(
                name: 'Robert Fox',
                username: 'Robertfox',
                imageUrl: 'assets/images/dashboard_particulier/Ellipse 10.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowerItem({
    required String name,
    required String username,
    required String imageUrl,
    required bool isFollowing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundImage: AssetImage(imageUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF04BC7B).withOpacity(0.2),
              foregroundColor: const Color(0xFF2E9B5B),
              side: const BorderSide(color: Color(0xFF2E9B5B)),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Suivre en retour',
              style: TextStyle(fontSize: 11),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: InkWell(
              onTap: () {},
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingItem({
    required String name,
    required String username,
    required String imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(radius: 26, backgroundImage: AssetImage(imageUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF04BC7B).withOpacity(0.2),
              foregroundColor: const Color(0xFF2E9B5B),
              side: const BorderSide(color: Color(0xFF2E9B5B)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Voir le profil', style: TextStyle(fontSize: 11)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: InkWell(
              onTap: () {},
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
