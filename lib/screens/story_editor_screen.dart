import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:myreklam/models/story_model.dart';

class StoryEditorScreen extends StatefulWidget {
  final AssetEntity asset;

  const StoryEditorScreen({super.key, required this.asset});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          FutureBuilder<Uint8List?>(
            future: widget.asset.originBytes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Text('Erreur de chargement', style: TextStyle(color: Colors.white)));
              }
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              );
            },
          ),

          // Top Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 2,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                Column(
                  children: [
                    _buildCircleIconButton(icon: Icons.text_fields, label: 'Aa'),
                    const SizedBox(height: 12),
                    _buildCircleIconButton(icon: Icons.emoji_emotions_outlined),
                    const SizedBox(height: 12),
                    _buildCircleIconButton(icon: Icons.music_note),
                    const SizedBox(height: 12),
                    _buildCircleIconButton(icon: Icons.grid_view_rounded),
                    const SizedBox(height: 12),
                    _buildCircleIconButton(icon: Icons.keyboard_arrow_down),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Ajouter une légende...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundImage: AssetImage('assets/images/dashboard_particulier/Ellipse 10.png'),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Votre Story',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.public, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Public',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final imageBytes = await widget.asset.originBytes;
                          if (imageBytes != null) {
                            final story = StoryModel(
                              imageBytes: imageBytes,
                              caption: _captionController.text.trim(),
                              timestamp: DateTime.now(),
                            );
                            Navigator.pop(context, story);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard_arrow_right, color: Colors.black, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({required IconData icon, String? label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
