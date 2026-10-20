import 'package:myreklam/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Full-width, uncropped photos. The existing detail viewer handles zooming.
class FeedPhotoGallery extends StatefulWidget {
  const FeedPhotoGallery({
    super.key,
    required this.urls,
    required this.onOpen,
    this.imageProviderFor,
  });
  final List<String> urls;
  final ValueChanged<int> onOpen;
  final ImageProvider Function(String)? imageProviderFor;

  @override
  State<FeedPhotoGallery> createState() => _FeedPhotoGalleryState();
}

class _FeedPhotoGalleryState extends State<FeedPhotoGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 1.15).clamp(280.0, 520.0);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: AdaptiveColors.surface(
                    context,
                    const Color(0xFFF3F5F4),
                  ),
                  child: PageView.builder(
                    key: ValueKey(widget.urls.join('|')),
                    controller: _controller,
                    itemCount: widget.urls.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => widget.onOpen(index),
                      child: Image(
                        image:
                            widget.imageProviderFor?.call(widget.urls[index]) ??
                            NetworkImage(widget.urls[index]),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: height,
                        semanticLabel:
                            'Photo ${index + 1} sur ${widget.urls.length}. Ouvrir en plein écran',
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.urls.length > 1)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AdaptiveColors.surface(context, Colors.black87),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.urls.length}',
                      style: TextStyle(
                        color: AdaptiveColors.foreground(context, Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
