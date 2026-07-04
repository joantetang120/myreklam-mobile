import 'package:flutter/material.dart';

/// Structured story overlay elements (stickers, location chips, freehand
/// drawing). Stored as a JSON list in `stories.overlays` and rendered on top
/// of the media in both the editor (interactive) and the viewer (read-only).
///
/// Positioned elements use normalized coordinates: [x]/[y] are the center of
/// the element in the 0..1 range relative to the media area, [scale] is a
/// multiplier and [rotation] is in radians. Drawing strokes store their points
/// in the same normalized 0..1 space.
abstract class StoryOverlay {
  String get type;
  Map<String, dynamic> toJson();

  static StoryOverlay? fromJson(Map<String, dynamic> j) {
    switch (j['type']?.toString()) {
      case 'sticker':
        return StickerOverlay.fromJson(j);
      case 'location':
        return LocationOverlay.fromJson(j);
      case 'drawing':
        return DrawingOverlay.fromJson(j);
    }
    return null;
  }

  static List<StoryOverlay> listFromJson(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => StoryOverlay.fromJson(Map<String, dynamic>.from(m)))
        .whereType<StoryOverlay>()
        .toList();
  }

  static List<Map<String, dynamic>> listToJson(List<StoryOverlay> items) =>
      items.map((e) => e.toJson()).toList();
}

double _toDouble(dynamic v, double fallback) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

/// Base for overlays anchored at a normalized position with scale + rotation.
abstract class PositionedOverlay extends StoryOverlay {
  double x;
  double y;
  double scale;
  double rotation;

  PositionedOverlay({
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

class StickerOverlay extends PositionedOverlay {
  String emoji;

  StickerOverlay({
    required this.emoji,
    super.x,
    super.y,
    super.scale,
    super.rotation,
  });

  @override
  String get type => 'sticker';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'sticker',
        'emoji': emoji,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
      };

  factory StickerOverlay.fromJson(Map<String, dynamic> j) => StickerOverlay(
        emoji: j['emoji']?.toString() ?? '⭐',
        x: _toDouble(j['x'], 0.5),
        y: _toDouble(j['y'], 0.5),
        scale: _toDouble(j['scale'], 1.0),
        rotation: _toDouble(j['rotation'], 0.0),
      );
}

class LocationOverlay extends PositionedOverlay {
  String name;
  double? lat;
  double? lng;

  LocationOverlay({
    required this.name,
    this.lat,
    this.lng,
    super.x,
    super.y,
    super.scale,
    super.rotation,
  });

  @override
  String get type => 'location';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'location',
        'name': name,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'x': x,
        'y': y,
        'scale': scale,
        'rotation': rotation,
      };

  factory LocationOverlay.fromJson(Map<String, dynamic> j) => LocationOverlay(
        name: j['name']?.toString() ?? '',
        lat: j['lat'] == null ? null : _toDouble(j['lat'], 0),
        lng: j['lng'] == null ? null : _toDouble(j['lng'], 0),
        x: _toDouble(j['x'], 0.5),
        y: _toDouble(j['y'], 0.85),
        scale: _toDouble(j['scale'], 1.0),
        rotation: _toDouble(j['rotation'], 0.0),
      );
}

/// A single freehand stroke. [points] are normalized (0..1) offsets.
class DrawStroke {
  final int color;
  final double width;
  final List<Offset> points;

  DrawStroke({required this.color, required this.width, required this.points});

  Map<String, dynamic> toJson() => {
        'color': color,
        'width': width,
        // Flat [x1, y1, x2, y2, ...] for compactness.
        'points': [
          for (final p in points) ...[p.dx, p.dy],
        ],
      };

  factory DrawStroke.fromJson(Map<String, dynamic> j) {
    final raw = (j['points'] as List?) ?? const [];
    final pts = <Offset>[];
    for (var i = 0; i + 1 < raw.length; i += 2) {
      pts.add(Offset(_toDouble(raw[i], 0), _toDouble(raw[i + 1], 0)));
    }
    return DrawStroke(
      color: j['color'] is int
          ? j['color']
          : int.tryParse(j['color']?.toString() ?? '') ?? 0xFFFFFFFF,
      width: _toDouble(j['width'], 4.0),
      points: pts,
    );
  }
}

class DrawingOverlay extends StoryOverlay {
  final List<DrawStroke> strokes;

  DrawingOverlay({required this.strokes});

  @override
  String get type => 'drawing';

  @override
  Map<String, dynamic> toJson() => {
        'type': 'drawing',
        'strokes': strokes.map((s) => s.toJson()).toList(),
      };

  factory DrawingOverlay.fromJson(Map<String, dynamic> j) => DrawingOverlay(
        strokes: ((j['strokes'] as List?) ?? const [])
            .whereType<Map>()
            .map((s) => DrawStroke.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
      );
}

/// Paints normalized drawing strokes onto a sized canvas.
class StoryDrawingPainter extends CustomPainter {
  final List<DrawStroke> strokes;

  StoryDrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.color)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.dx * size.width, first.dy * size.height);
      if (stroke.points.length == 1) {
        // A dot: draw a tiny line so the cap shows.
        canvas.drawCircle(
          Offset(first.dx * size.width, first.dy * size.height),
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StoryDrawingPainter old) =>
      old.strokes != strokes;
}

/// Read-only renderer used by the story viewer to paint overlays over media.
class StoryOverlaysView extends StatelessWidget {
  final List<StoryOverlay> overlays;

  const StoryOverlaysView({super.key, required this.overlays});

  @override
  Widget build(BuildContext context) {
    if (overlays.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            for (final overlay in overlays)
              if (overlay is DrawingOverlay)
                Positioned.fill(
                  child: CustomPaint(
                    painter: StoryDrawingPainter(overlay.strokes),
                  ),
                )
              else if (overlay is PositionedOverlay)
                Positioned(
                  left: overlay.x * w,
                  top: overlay.y * h,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Transform.rotate(
                      angle: overlay.rotation,
                      child: Transform.scale(
                        scale: overlay.scale,
                        child: buildOverlayChild(overlay),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// Visual content of a positioned overlay (shared by editor + viewer).
Widget buildOverlayChild(PositionedOverlay overlay) {
  if (overlay is StickerOverlay) {
    return Text(
      overlay.emoji,
      style: const TextStyle(fontSize: 64),
    );
  }
  if (overlay is LocationOverlay) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              overlay.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  return const SizedBox.shrink();
}
