import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small OpenStreetMap view (no API key) for announcement locations.
///
/// Uses [latitude]/[longitude] when provided, otherwise geocodes [query]
/// (e.g. "59 rue des platanes, 54300, REHAINVILLER, France"). Shows a graceful
/// placeholder while resolving or when the location can't be determined.
class LocationMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? query;
  final double height;

  const LocationMap({
    super.key,
    this.latitude,
    this.longitude,
    this.query,
    this.height = 180,
  });

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  LatLng? _center;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant LocationMap old) {
    super.didUpdateWidget(old);
    if (old.latitude != widget.latitude ||
        old.longitude != widget.longitude ||
        old.query != widget.query) {
      _loading = true;
      _center = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (widget.latitude != null && widget.longitude != null) {
      _center = LatLng(widget.latitude!, widget.longitude!);
      if (mounted) setState(() => _loading = false);
      return;
    }

    final q = (widget.query ?? '').trim();
    if (q.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final locations = await locationFromAddress(q);
      if (locations.isNotEmpty) {
        _center = LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {
      // Geocoding unavailable / address not found → placeholder.
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Opens the location in a navigation app. On Android a `geo:` URI lets the
  /// user pick Google Maps / Waze / etc.; falls back to the Google Maps URL.
  Future<void> _openInMaps() async {
    final c = _center;
    if (c == null) return;
    final coords = '${c.latitude},${c.longitude}';
    final label = (widget.query ?? '').trim();

    final geoUri = Uri.parse(
      'geo:$coords?q=$coords'
      '${label.isNotEmpty ? '(${Uri.encodeComponent(label)})' : ''}',
    );
    final gmapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$coords',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    try {
      await launchUrl(gmapsUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_center == null) {
      return Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.map_outlined, color: Colors.grey, size: 40),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: _center!,
            initialZoom: 14,
            // Tapping the map opens the location in a navigation app.
            onTap: (_, __) => _openInMaps(),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.myreklam.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _center!,
                  width: 44,
                  height: 44,
                  alignment: Alignment.topCenter,
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFFE53935),
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        // "Itinéraire" affordance — also opens the navigation app.
        Positioned(
          right: 10,
          bottom: 10,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _openInMaps,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions, size: 16, color: Color(0xFF1B8D4B)),
                    SizedBox(width: 5),
                    Text(
                      'Itinéraire',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B8D4B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
