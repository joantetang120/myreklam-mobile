import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/main.dart';
import 'package:myreklam/screens/demande_detail_screen.dart';
import 'package:myreklam/screens/event_detail_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/screens/pro_post_detail_screen.dart';
import 'package:myreklam/screens/training_detail_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/user_session.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:myreklam/widgets/formation_card.dart';

/// Handles incoming deep links of the form:
///   myreklam://s/{type}/{id}
///   https://myreklam.fr/s/{type}/{id}
///
/// Fetches the entity from the API and navigates to the correct detail screen.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Call once from main() after Firebase is ready.
  Future<void> init() async {
    // Handle links when app is already running
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (e) => debugPrint('DeepLinkService stream error: $e'),
    );
    // Handle the link that launched the app (cold start)
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handleUri(initial);
  }

  void dispose() => _sub?.cancel();

  void _handleUri(Uri uri) {
    debugPrint('DeepLinkService: received $uri');
    final segments = uri.pathSegments;
    // Expected: ['s', '{type}', '{id}']  (scheme or https host stripped)
    final idx = segments.indexOf('s');
    if (idx < 0 || idx + 2 >= segments.length) return;
    final type = segments[idx + 1];
    final id   = segments[idx + 2];
    _navigate(type, id);
  }

  Future<void> _navigate(String type, String id) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    try {
      switch (type) {
        case 'bons-plans':
          await _openBonPlan(ctx, id);
          break;
        case 'emplois':
          await _openJobOffer(ctx, id);
          break;
        case 'formations':
          await _openTraining(ctx, id);
          break;
        case 'evenements':
          await _openEvent(ctx, id);
          break;
        case 'demandes':
          await _openDemande(ctx, id);
          break;
        default:
          debugPrint('DeepLinkService: unknown type "$type"');
      }
    } catch (e) {
      debugPrint('DeepLinkService: error navigating to $type/$id: $e');
    }
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  static List<String> _extractImages(List? mediaFiles) {
    if (mediaFiles == null) return [];
    return mediaFiles
        .whereType<Map>()
        .where((m) => m['url'] != null)
        .map((m) {
          final url = m['url'].toString();
          return ApiConfig.resolveMediaUrl(url) ?? url;
        })
        .where((u) => u.isNotEmpty)
        .toList();
  }

  static String _timeAgo(String? raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
      if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
      return 'À l\'instant';
    } catch (_) {
      return '';
    }
  }

  static int? _tryInt(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static String _stripHtml(String html) => html.isEmpty
      ? ''
      : html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // ─── entity openers ───────────────────────────────────────────────────────

  Future<void> _openBonPlan(BuildContext ctx, String id) async {
    final response = await ApiClient().authenticatedGet('/bonplans/$id');
    final data = response['data'] as Map<String, dynamic>? ?? response as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>?;
    final images = _extractImages(data['media_files'] as List?);
    final tags = <PostTag>[
      if (data['category']?.toString().isNotEmpty == true)
        PostTag(title: data['category'].toString(), icon: Icons.local_offer_outlined, color: Colors.orange),
      if (data['sub_category']?.toString().isNotEmpty == true)
        PostTag(title: data['sub_category'].toString(), icon: Icons.grid_view_outlined, color: Colors.grey),
    ];
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProPostDetailScreen(
      images: images,
      discount: data['reduction_label']?.toString(),
      avatar: user?['avatar_url']?.toString() ?? user?['avatar']?.toString() ?? '',
      name: user?['display_name']?.toString() ?? user?['name']?.toString() ?? 'Utilisateur',
      userType: user?['account_type']?.toString() ?? 'Particulier',
      title: data['title']?.toString() ?? 'Bon plan',
      description: _stripHtml(data['description']?.toString() ?? ''),
      descriptionDelta: data['description_delta'],
      tags: tags,
      time: _timeAgo(data['created_at']?.toString()),
      availability: data['available_at_name']?.toString() ?? 'Non spécifié',
      validityType: data['validity_type']?.toString() ?? 'permanent',
      validFrom: data['valid_from']?.toString(),
      validUntil: data['valid_until']?.toString(),
      location: _buildLocation(data['location_city']?.toString(), data['location_postal_code']?.toString()),
      locationCity: data['location_city']?.toString(),
      locationPostalCode: data['location_postal_code']?.toString(),
      link: data['brand_website']?.toString(),
      isOwner: data['user_id']?.toString() == UserSession().id,
      bonPlanId: id,
      bonPlanData: data,
      acceptMessages: data['accept_messages'] == true,
      authorData: user,
      price: data['prix_final']?.toString(),
      originalPrice: data['prix_avant_reduction']?.toString(),
      shippingOption: data['shipping_option']?.toString(),
      shippingCost: data['shipping_cost']?.toString(),
      availableLocationType: data['available_location_type']?.toString(),
      conditions: data['conditions']?.toString(),
      commentsCount: _tryInt(data['comments_count']),
      deliveryInfo: _buildDelivery(data['pickup_methods'] as Map<String, dynamic>?),
    )));
  }

  Future<void> _openJobOffer(BuildContext ctx, String id) async {
    final response = await ApiClient().authenticatedGet('/job-offers/$id');
    final data = response['data'] as Map<String, dynamic>? ?? response as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>?;
    final contractType = data['contract_type'] is Map
        ? data['contract_type']['name']?.toString()
        : data['contract_type']?.toString();
    final workTime = data['work_time'] is Map
        ? data['work_time']['name']?.toString()
        : data['work_time']?.toString();
    final location = data['location'] is Map
        ? data['location']['city']?.toString()
        : data['location']?.toString();
    final tags = <JobDetailTag>[
      if (contractType?.isNotEmpty == true) JobDetailTag(icon: Icons.description_outlined, text: contractType!),
      if (workTime?.isNotEmpty == true) JobDetailTag(icon: Icons.access_time, text: workTime!),
      if (location?.isNotEmpty == true) JobDetailTag(icon: Icons.location_on_outlined, text: location!),
    ];
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => JobDetailScreen(
      jobOfferId: id,
      companyLogo: user?['avatar_url']?.toString() ?? '',
      companyName: data['company_name']?.toString() ?? user?['display_name']?.toString() ?? 'Entreprise',
      jobTitle: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      descriptionDelta: data['description_delta'],
      tags: tags,
      advantages: const [],
      timeAgo: _timeAgo(data['created_at']?.toString()),
      location: location ?? '',
      locationCity: data['location_city']?.toString(),
      locationPostalCode: data['location_postal_code']?.toString(),
      isOwner: data['user_id']?.toString() == UserSession().id,
      jobOfferData: data,
      acceptMessages: data['accept_messages'] == true,
      authorData: user,
      commentsCount: _tryInt(data['comments_count']),
    )));
  }

  Future<void> _openTraining(BuildContext ctx, String id) async {
    final response = await ApiClient().authenticatedGet('/trainings/$id');
    final data = response['data'] as Map<String, dynamic>? ?? response as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>?;
    final images = _extractImages(data['media_files'] as List?);
    final tags = <FormationTag>[
      if (data['category']?.toString().isNotEmpty == true)
        FormationTag(icon: Icons.school_outlined, text: data['category'].toString()),
    ];
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => TrainingDetailScreen(
      trainingId: id,
      companyLogo: user?['avatar_url']?.toString() ?? 'assets/images/Formation.png',
      companyName: data['organizer_name']?.toString() ?? user?['display_name']?.toString() ?? 'Organisateur',
      trainingTitle: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      descriptionDelta: data['description_delta'],
      images: images,
      tags: tags,
      timeAgo: _timeAgo(data['created_at']?.toString()),
      locationCity: data['location_city']?.toString(),
      locationPostalCode: data['location_postal_code']?.toString(),
      isOwner: data['user_id']?.toString() == UserSession().id,
      trainingData: data,
      authorData: user,
      commentsCount: _tryInt(data['comments_count']),
    )));
  }

  Future<void> _openEvent(BuildContext ctx, String id) async {
    final response = await ApiClient().authenticatedGet('/events/$id');
    final data = response['data'] as Map<String, dynamic>? ?? response as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>?;
    final images = _extractImages(data['media_files'] as List?);
    final tags = <PostTag>[
      if (data['category']?.toString().isNotEmpty == true)
        PostTag(title: data['category'].toString(), icon: Icons.category_outlined, color: Colors.blue),
    ];
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => EventDetailScreen(
      eventId: id,
      avatar: user?['avatar_url']?.toString() ?? 'assets/images/default_avatar.png',
      username: user?['display_name']?.toString() ?? user?['name']?.toString() ?? 'Utilisateur',
      eventTitle: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      descriptionDelta: data['description_delta'],
      images: images,
      tags: tags,
      timeAgo: _timeAgo(data['created_at']?.toString()),
      eventDate: data['start_date']?.toString() ?? data['event_date']?.toString(),
      coverageArea: data['coverage_area']?.toString() ?? data['location']?.toString(),
      locationCity: data['location_city']?.toString(),
      locationPostalCode: data['location_postal_code']?.toString(),
      isOwner: data['user_id']?.toString() == UserSession().id,
      eventData: data,
      acceptMessages: data['accept_messages'] == true,
      authorData: user,
      commentsCount: _tryInt(data['comments_count']),
    )));
  }

  Future<void> _openDemande(BuildContext ctx, String id) async {
    final response = await ApiClient().authenticatedGet('/demandes/$id');
    final data = response['data'] as Map<String, dynamic>? ?? response as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>?;
    final images = _extractImages(data['media_files'] as List?);
    final tags = <PostTag>[
      if (data['category']?.toString().isNotEmpty == true)
        PostTag(title: data['category'].toString(), icon: Icons.category_outlined, color: Colors.purple),
    ];
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => DemandeDetailScreen(
      demandeId: id,
      avatar: user?['avatar_url']?.toString() ?? 'assets/images/default_avatar.png',
      username: user?['display_name']?.toString() ?? user?['name']?.toString() ?? 'Utilisateur',
      demandeTitle: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      images: images,
      tags: tags,
      timeAgo: _timeAgo(data['created_at']?.toString()),
      location: data['location_city']?.toString() ?? '',
      locationCity: data['location_city']?.toString(),
      locationPostalCode: data['location_postal_code']?.toString(),
      budgetMax: data['budget']?.toString(),
      nationwide: data['nationwide'] == true,
      nature: data['nature']?.toString(),
      type: data['type']?.toString(),
      isOwner: data['user_id']?.toString() == UserSession().id,
      demandeData: data,
      acceptMessages: data['accept_messages'] == true,
      authorData: user,
      commentsCount: _tryInt(data['comments_count']),
    )));
  }

  static String _buildLocation(String? city, String? postal) {
    if (city != null && postal != null) return '$city ($postal)';
    return city ?? postal ?? '';
  }

  static String _buildDelivery(Map<String, dynamic>? m) {
    if (m == null) return 'Non spécifié';
    final inStore = m['in_store'] == true;
    final delivery = m['delivery'] == true;
    if (inStore && delivery) return 'En magasin et livraison';
    if (inStore) return 'En magasin uniquement';
    if (delivery) return 'Livraison disponible';
    return 'Non spécifié';
  }
}
