import 'package:flutter/material.dart';

/// Fixed carousel widget that properly tracks page changes for dot indicators.
/// This is used in particulier_dashboard_screen.dart and other screens showing
/// bons plans with image carousels.
class BonPlanCarousel extends StatefulWidget {
  final List<String> urls;
  final double height;

  const BonPlanCarousel({super.key, required this.urls, this.height = 220});

  @override
  State<BonPlanCarousel> createState() => _BonPlanCarouselState();
}

class _BonPlanCarouselState extends State<BonPlanCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Image.network(
                widget.urls[index],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: widget.height,
                    color: Colors.grey[100],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, error, ___) => Container(
                  height: widget.height,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator
        if (widget.urls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.urls.length, (index) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage
                      ? const Color(0xFFFF9800)
                      : Colors.grey[300],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
