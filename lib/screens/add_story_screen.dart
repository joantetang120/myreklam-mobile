import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:myreklam/screens/story_editor_screen.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen>
    with WidgetsBindingObserver {
  static const PermissionRequestOption _permissionRequestOption =
      PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      );

  bool _isLoading = true;
  bool _hasAccess = false;
  List<AssetEntity> _assets = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGallery();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionState();
    }
  }

  Future<void> _initGallery() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final PermissionState status = await PhotoManager.requestPermissionExtend(
      requestOption: _permissionRequestOption,
    );
    if (status.hasAccess) {
      await _loadRecentAssets();
    } else {
      if (!mounted) return;
      setState(() {
        _hasAccess = false;
        _assets = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPermissionState() async {
    final PermissionState status = await PhotoManager.getPermissionState(
      requestOption: _permissionRequestOption,
    );
    if (!mounted) return;

    if (status.hasAccess) {
      await _loadRecentAssets();
      return;
    }

    setState(() {
      _hasAccess = false;
      _assets = [];
      _isLoading = false;
    });
  }

  Future<void> _loadRecentAssets() async {
    try {
      final filterOption = FilterOptionGroup()
        ..addOrderOption(
          const OrderOption(
            type: OrderOptionType.createDate,
            asc: false,
          ),
        );

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: filterOption,
      );

      if (!mounted) return;
      if (albums.isEmpty) {
        setState(() {
          _assets = [];
          _hasAccess = true;
          _isLoading = false;
        });
        return;
      }

      final AssetPathEntity recentAlbum = albums.first;
      final List<AssetEntity> assets = await recentAlbum.getAssetListPaged(
        page: 0,
        size: 40,
      );

      if (!mounted) return;
      setState(() {
        _assets = assets;
        _hasAccess = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load gallery assets: $e');
      if (!mounted) return;
      setState(() {
        _assets = [];
        _hasAccess = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF616161)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter une storie',
          style: TextStyle(
            color: Color(0xFF616161),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoryModes(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Récents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF616161),
              ),
            ),
          ),
          Expanded(child: _buildGallerySection()),
        ],
      ),
    );
  }

  Widget _buildStoryModes() {
    final List<_StoryMode> modes = [
      _StoryMode('Texte', Icons.text_fields_outlined),
      _StoryMode('Galerie', Icons.photo_library_outlined),
      _StoryMode('Videos', Icons.video_collection_outlined),
      _StoryMode('Photos', Icons.camera_alt_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: modes
            .map(
              (mode) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: mode.label == 'Galerie'
                        ? const Color(0xFF2E9B5B).withValues(alpha: 0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mode.icon,
                        size: 22,
                        color: mode.label == 'Galerie'
                            ? const Color(0xFF2E9B5B)
                            : const Color(0xFF616161),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mode.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: mode.label == 'Galerie'
                              ? const Color(0xFF2E9B5B)
                              : const Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGallerySection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasAccess) {
      return _PermissionPrompt(onRetry: _initGallery);
    }

    if (_assets.isEmpty) {
      return const Center(
        child: Text(
          'Aucune photo trouvée dans votre galerie.',
          style: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _assets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCameraTile();
        }
        final asset = _assets[index - 1];
        return _GalleryAssetTile(asset: asset);
      },
    );
  }

  Widget _buildCameraTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.photo_camera_outlined, color: Color(0xFF2E9B5B)),
          SizedBox(height: 6),
          Text(
            'Caméra',
            style: TextStyle(
              color: Color(0xFF616161),
              fontSize: 12,
            ),
          )
        ],
      ),
    );
  }
}

class _StoryMode {
  final String label;
  final IconData icon;

  const _StoryMode(this.label, this.icon);
}

class _PermissionPrompt extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _PermissionPrompt({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 48, color: Color(0xFF2E9B5B)),
          const SizedBox(height: 16),
          const Text(
            'Autorisez l\'accès à votre galerie pour ajouter une storie.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF616161)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await PhotoManager.openSetting();
              await onRetry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E9B5B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Ouvrir les réglages'),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Ressayer'),
          )
        ],
      ),
    );
  }
}

class _GalleryAssetTile extends StatelessWidget {
  final AssetEntity asset;

  const _GalleryAssetTile({required this.asset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryEditorScreen(asset: asset),
          ),
        );
        if (result != null && context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Uint8List?>(
          future: asset.thumbnailDataWithSize(const ThumbnailSize(400, 400)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(color: Colors.grey[200]);
            }
            final data = snapshot.data;
            if (data == null) {
              return Container(color: Colors.grey[300]);
            }
            return Image.memory(
              data,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}
