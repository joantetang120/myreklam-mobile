import 'package:flutter/material.dart';
import 'package:myreklam/services/share_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icons_launcher/cli_commands.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/screens/creer_demande_screen.dart';
import 'package:myreklam/screens/profile_particulier/particulier_public_view_screen.dart';
import 'package:myreklam/screens/profile_pro/pro_publicView_Screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/reaction_cache_service.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/demande_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/conversation_service.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/mys_earning_service.dart';
import 'package:myreklam/utils/user_session.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myreklam/widgets/custom_bottom_bar.dart';

class _ReactionData {
  int likesCount;
  int commentsCount;
  String? userReaction;
  _ReactionData({
    this.likesCount = 0,
    this.commentsCount = 0,
    this.userReaction,
  });
}

class DemandeDetailScreen extends StatefulWidget {
  final List<String> images;
  final String avatar;
  final String username;
  final String demandeTitle;
  final String description;
  final List<PostTag> tags;
  final PostTag? subtags;
  final String timeAgo;
  // Demande-specific fields
  final String? nature;
  final String? type;
  final bool urgent;
  final String? budgetMax;
  final String? location;
  final String? locationCity;
  final String? locationPostalCode;
  final bool nationwide;
  final int? searchRadiusKm;
  final bool showGoogleLocation;
  final bool acceptMessages;
  final bool isOwner;
  final String? demandeId;
  final Map<String, dynamic>? demandeData;
  final bool returnToListingOnEdit;
  final String userType;
  final int? commentsCount;

  const DemandeDetailScreen({
    super.key,
    this.images = const [],
    required this.avatar,
    required this.username,
    required this.demandeTitle,
    required this.description,
    this.tags = const [],
    this.subtags,
    this.timeAgo = '',
    this.nature,
    this.type,
    this.urgent = false,
    this.budgetMax,
    this.location,
    this.locationCity,
    this.locationPostalCode,
    this.nationwide = false,
    this.searchRadiusKm,
    this.showGoogleLocation = false,
    this.acceptMessages = false,
    this.isOwner = false,
    this.demandeId,
    this.demandeData,
    this.returnToListingOnEdit = false,
    this.userType = 'Particulier',
    this.commentsCount,
  });

  @override
  State<DemandeDetailScreen> createState() => _DemandeDetailScreenState();
}

class _DemandeDetailScreenState extends State<DemandeDetailScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  int? _localCommentsCount;
  List<Map<String, dynamic>> _similarDemandes = [];
  bool _isLoadingSimilar = false;

  /// Check if edit option should be shown
  /// Hide edit if: 1) post is older than 2 hours OR 2) people have favorited it
  bool get _canEdit {
    if (!widget.isOwner) return false;

    final data = widget.demandeData;
    if (data == null) return true; // Allow edit if no data (fallback)

    // Check if post is older than 2 hours
    final createdAtStr = data['created_at']?.toString();
    if (createdAtStr != null && createdAtStr.isNotEmpty) {
      final createdAt = DateTime.tryParse(createdAtStr);
      if (createdAt != null) {
        final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
        if (createdAt.isBefore(twoHoursAgo)) {
          return false; // Post is older than 2 hours
        }
      }
    }

    // Check if people have favorited this demande
    final favoritesCount = data['favorites_count'] ?? 0;
    if (favoritesCount is int && favoritesCount > 0) {
      return false; // People have favorited
    }

    return true;
  }

  // Categories API data for translating secteur/fonction
  Map<String, String> _sectorCodeToLabel = {};
  Map<String, String> _functionCodeToLabel = {};
  bool _categoriesLoaded = false;

  static const _natureLabels = {
    'searchjob': 'Recherche d\'emploi',
    'training': 'Formation',
    'realestate': 'Immobilier',
    'servicehelp': 'Services / Aide',
    'promaterial': 'Matériel pro',
    'house': 'Maison',
    'fashion': 'Mode',
    'vehicle': 'Véhicules',
    'holiday': 'Vacances',
    'multimedia': 'Multimédia',
    'hobbies': 'Loisirs',
    'animals': 'Animaux',
    'various': 'Divers',
    // Legacy mappings for backward compatibility
    'emploi': 'Recherche d\'emploi',
    'service': 'Services / Aide',
    'logement': 'Immobilier',
    'produit': 'Recherche de produit',
    'formation': 'Formation',
    'collaboration': 'Collaboration',
    'stage': 'Recherche de stage',
    'internship': 'Recherche de stage / alternance',
    'jobsearch': 'Recherche d\'emploi',
    'autre': 'Autre demande',
  };

  static const _typeLabels = {
    // Real Estate subcategories
    'RealEstateInvestment': 'Investissement immobilier',
    'LookingForRental': 'Cherche location',
    'LookingForSharedHousing': 'Cherche colocation',
    'LookingForProfessionalSpace': 'Cherche local professionnel',
    // Services subcategories
    'Ticketing': 'Billetterie',
    'ServiceProvision': 'Prestations de services',
    'Events': 'Événements',
    'Carpooling': 'Covoiturage',
    'PrivateLessons': 'Cours particuliers',
    // Pro Material subcategories
    'AgriculturalEquipment': 'Matériel agricole',
    'TransportHandling': 'Transport & Manutention',
    'ConstructionHeavyWork': 'Construction & Travaux lourds',
    'ToolsSecondaryWork': 'Outillage & Second œuvre',
    'IndustrialEquipment': 'Matériel industriel',
    'CateringHotel': 'Restauration & Hôtellerie',
    'OfficeSupplies': 'Fournitures de bureau',
    'ShopsMarkets': 'Commerces & Marchés',
    'MedicalEquipment': 'Matériel médical',
    // House subcategories
    'Furniture': 'Mobilier',
    'Appliances': 'Électroménager',
    'Tableware': 'Arts de la table',
    'Decoration': 'Décoration',
    'HomeLinen': 'Linge de maison',
    'DIY': 'Bricolage',
    'Gardening': 'Jardinage',
    // Fashion subcategories
    'Clothing': 'Vêtements',
    'Shoes': 'Chaussures',
    'AccessoriesLuggage': 'Accessoires & Bagages',
    'WatchesJewelry': 'Montres & Bijoux',
    'BabyGear': 'Équipement bébé',
    'BabyClothing': 'Vêtements bébé',
    'LuxuryTrendy': 'Luxe & Tendance',
    // Vehicle subcategories
    'Cars': 'Voitures',
    'Motorcycles': 'Motos',
    'Caravanning': 'Camping-car',
    'UtilityVehicles': 'Véhicules utilitaires',
    'Trucks': 'Poids lourds',
    'Boating': 'Bateaux',
    'CarEquipment': 'Équipement voiture',
    'MotorcycleEquipment': 'Équipement moto',
    'CaravanningEquipment': 'Équipement camping-car',
    'BoatingEquipment': 'Équipement bateau',
    // Holiday subcategories
    'RentalCottages': 'Location & Gîtes',
    'AirBnB': 'AirBnB',
    'GuestRooms': 'Chambres d\'hôtes',
    'Campings': 'Campings',
    'TrainTickets': 'Billets de train',
    'PlaneTickets': 'Billets d\'avion',
    'Hotels': 'Hôtels',
    'Stays': 'Séjours',
    // Multimedia subcategories
    'ImageSound': 'Image et son',
    'ConsolesVideoGames': 'Consoles & Jeux vidéo',
    'Phones': 'Téléphones',
    'Computing': 'Informatique',
    'DVDMovies': 'DVD - Film',
    'CDMusic': 'CD - Musique',
    'Books': 'Livres',
    // Hobbies subcategories
    'Bicycles': 'Vélos',
    'SportsHobbies': 'Sport & Loisirs',
    'MusicalInstruments': 'Instruments de musique',
    'Collections': 'Collections',
    'GamesToys': 'Jeux & Jouets',
    'WineGastronomy': 'Vin & Gastronomie',
    'Others': 'Autres',
  };

  String _getTypeLabel(String? type) {
    if (type == null || type.isEmpty) return '';
    return _typeLabels[type] ?? type;
  }

  String _getNatureLabel(String? nature) {
    if (nature == null || nature.isEmpty) return 'Demande';
    return _natureLabels[nature.toLowerCase()] ?? nature;
  }

  /// Resolves display name from demandeData['user'], falling back to widget.username.
  String _resolveOwnerName() {
    final user = widget.demandeData?['user'];
    if (user is! Map) return widget.username;
    // particulier pseudo
    if (user['particulier_profile'] is Map) {
      final pseudo =
          (user['particulier_profile'] as Map)['pseudo']?.toString() ?? '';
      if (pseudo.isNotEmpty) return pseudo;
    }
    // pro company name
    if (user['pro_profile'] is Map) {
      final company =
          (user['pro_profile'] as Map)['company_name']?.toString() ?? '';
      if (company.isNotEmpty) return company;
    }
    // generic name / email
    final name = user['name']?.toString() ?? '';
    if (name.isNotEmpty && name != 'Utilisateur') return name;
    final email = user['email']?.toString() ?? '';
    if (email.contains('@')) return email.split('@').first;
    return widget.username;
  }

  String _resolveUserType() {
    final user = _effectiveAuthorData();
    final accountType = user?['account_type']?.toString();
    if (accountType == 'pro') return 'Pro';
    if (accountType == 'particulier') return 'Particulier';
    return widget.userType;
  }

  /// Resolves avatar URL from demandeData['user'], falling back to widget.avatar.
  String _resolveOwnerAvatar() {
    final user = widget.demandeData?['user'];
    if (user is! Map) return widget.avatar;
    final candidates = [
      if (user['particulier_profile'] is Map)
        (user['particulier_profile'] as Map)['avatar_url'],
      if (user['pro_profile'] is Map) ...[
        (user['pro_profile'] as Map)['avatar_url'],
        (user['pro_profile'] as Map)['logo_url'],
      ],
      user['avatar_url'],
      user['avatar'],
      user['profile_picture'],
    ];
    for (final c in candidates) {
      final s = c?.toString() ?? '';
      if (s.isEmpty) continue;
      final resolved = ApiConfig.resolveMediaUrl(s);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return widget.avatar;
  }

  @override
  void initState() {
    super.initState();
    _localCommentsCount = widget.commentsCount;
    _fetchComments();
    _checkFollowStatus();
    _checkFavoriteStatus();
    _fetchSimilarDemandes();
    _loadCategoriesForTranslation();
  }

  /// Load categories from API to translate sector and function codes to French labels
  Future<void> _loadCategoriesForTranslation() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.myreklam.fr/Categorie.php'),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: const {'Method': 'getByType', 'type': 'offres_emploi'},
      );

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success')
        return;

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return;

      final sectorCodeToLabel = <String, String>{};
      final functionCodeToLabel = <String, String>{};

      // Parse main categories (secteurs)
      final mainRaw = data['main'];
      if (mainRaw is List) {
        for (final item in mainRaw) {
          if (item is Map<String, dynamic>) {
            final code = item['code']?.toString();
            final label = item['label']?.toString();
            if (code != null && label != null) {
              sectorCodeToLabel[code] = label;
            }
          }
        }
      }

      // Parse sub-categories (fonctions) grouped by parentId
      final subsRaw = data['subs'];
      if (subsRaw is Map) {
        subsRaw.forEach((key, value) {
          if (value is List) {
            for (final func in value) {
              if (func is Map<String, dynamic>) {
                final code = func['code']?.toString();
                final label = func['label']?.toString();
                if (code != null && label != null) {
                  functionCodeToLabel[code] = label;
                }
              }
            }
          }
        });
      }

      setState(() {
        _sectorCodeToLabel = sectorCodeToLabel;
        _functionCodeToLabel = functionCodeToLabel;
        _categoriesLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading categories for translation: $e');
    }
  }

  Future<void> _fetchComments() async {
    if (widget.demandeId == null) return;

    setState(() => _isLoadingComments = true);
    try {
      final response = await ApiClient().authenticatedGet(
        '/demandes/${widget.demandeId}/comments?per_page=50',
      );

      final data = response['data'];
      List<Map<String, dynamic>> fetched = [];
      if (data is List) {
        fetched = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        fetched = List<Map<String, dynamic>>.from(data['data']);
      }

      if (!mounted) return;
      setState(() {
        _comments = fetched;
      });
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _fetchSimilarDemandes() async {
    setState(() => _isLoadingSimilar = true);
    try {
      final token = await TokenStorage.getAccessToken();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/feed/latest?type=demande&per_type_limit=30',
      );
      final response = await http.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = (body['data']?['items'] as List?) ?? [];
        final nature = (widget.nature ?? '').toLowerCase();

        // Score similarity
        final scored = <Map<String, dynamic>>[];
        for (final item in items) {
          final resource = item['resource'] as Map<String, dynamic>?;
          if (resource == null) continue;
          final id = resource['id']?.toString() ?? item['id']?.toString();
          if (id == widget.demandeId) continue;

          int score = 0;
          final rNature = (resource['nature'] ?? '').toString().toLowerCase();
          if (rNature == nature) score += 3;
          final rLocation = (resource['location'] ?? '')
              .toString()
              .toLowerCase();
          final myLocation = (widget.location ?? '').toLowerCase();
          if (myLocation.isNotEmpty && rLocation.contains(myLocation))
            score += 1;

          scored.add({'resource': resource, 'score': score});
        }
        scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
        final top = scored
            .take(5)
            .map((e) => e['resource'] as Map<String, dynamic>)
            .toList();

        if (!mounted) return;
        setState(() => _similarDemandes = top);
      }
    } catch (e) {
      debugPrint('Error fetching similar demandes: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSimilar = false);
    }
  }

  void _showCommentsSheet(BuildContext context) async {
    if (widget.demandeId == null) return;
    await _getCurrentUserId();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final commentCtrl = TextEditingController();

            Future<void> submitComment() async {
              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/demandes/${widget.demandeId}/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/demandes/${widget.demandeId}/comments',
                    body: {'body': text},
                  );
                }

                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      final parent = _comments.firstWhere(
                        (c) => c['id'] == replyingToId,
                        orElse: () => <String, dynamic>{},
                      );
                      if (parent.isNotEmpty) {
                        final replies = List<Map<String, dynamic>>.from(
                          (parent['replies'] as List?) ?? [],
                        );
                        replies.add(newComment);
                        parent['replies'] = replies;
                        parent['replies_count'] =
                            (parent['replies_count'] as int? ?? 0) + 1;
                      }
                    } else {
                      _comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                  setState(() {
                    _localCommentsCount =
                        (_localCommentsCount ?? _comments.length) + 1;
                  });
                }

                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();

                // Refresh comments from API to ensure count is accurate
                await _fetchComments();

                // Award 1 My for posting a comment (silently, no modal)
                try {
                  final mysResponse = await MysEarningService().awardMys(
                    actionType: 'comment',
                    referenceId: newComment?['id']?.toString(),
                  );
                  if (mysResponse['success'] == true) {
                    final newBalance = mysResponse['earning']?['new_balance'];
                    if (newBalance != null) {
                      UserSession().updateMys(newBalance);
                    }
                  }
                } catch (e) {
                  debugPrint("Error awarding My's for comment: $e");
                }
              } catch (e) {
                debugPrint('Error posting comment: $e');
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'envoi')),
                  );
                }
              }
            }

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);
              final newText = await showDialog<String>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Modifier le commentaire'),
                  content: TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Votre commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, editController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (newText == null || newText.trim().isEmpty || newText == currentBody) return;
              try {
                final response = await ApiClient().authenticatedPut(
                  '/comments/$commentId',
                  body: {'body': newText.trim()},
                );
                final updatedComment = response['data'] as Map<String, dynamic>?;
                if (updatedComment != null) {
                  setState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });
                  modalSetState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la modification: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Future<void> deleteComment(Map<String, dynamic> comment, bool isReply) async {
              final commentId = comment['id'];
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text('Êtes-vous sûr de vouloir supprimer ce commentaire ?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await ApiClient().authenticatedDelete('/comments/$commentId');
                setState(() {
                  if (isReply) {
                    final parentId = comment['parent_id'] ?? comment['comment_id'];
                    final parent = _comments.firstWhere(
                      (c) => c['id'] == parentId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.removeWhere((r) => r['id'] == commentId);
                      parent['replies'] = replies;
                      parent['replies_count'] = replies.length;
                    }
                  } else {
                    _comments.removeWhere((c) => c['id'] == commentId);
                    if (_localCommentsCount != null && _localCommentsCount! > 0) {
                      _localCommentsCount = _localCommentsCount! - 1;
                    }
                  }
                });
                modalSetState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.85,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Commentaires (${_comments.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Manjari',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    if (replyingToName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Réponse à $replyingToName',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontFamily: 'Manjari',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                modalSetState(() {
                                  replyingToId = null;
                                  replyingToName = null;
                                });
                              },
                              child: const Text(
                                'Annuler',
                                style: TextStyle(fontFamily: 'Manjari'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 1),
                    Expanded(
                      child: _isLoadingComments
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _comments.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'Aucun commentaire. Soyez le premier !',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                    fontFamily: 'Manjari',
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                return _buildCommentItem(
                                  _comments[index],
                                  onReply: (id, name) {
                                    modalSetState(() {
                                      replyingToId = id;
                                      replyingToName = name;
                                    });
                                  },
                                  onEdit: editComment,
                                  onDelete: deleteComment,
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentCtrl,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Écrire un commentaire...',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3AAE5E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            child: const Icon(Icons.send, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _fetchComments();
    });
  }

  Widget _buildCommentItem(
    Map<String, dynamic> comment, {
    bool isReply = false,
    void Function(int id, String name)? onReply,
    void Function(Map<String, dynamic>)? onEdit,
    void Function(Map<String, dynamic>, bool)? onDelete,
  }) {
    final user = comment['user'] as Map<String, dynamic>?;

    String displayName = 'Utilisateur';
    if (user != null) {
      if (user['particulier_profile'] != null) {
        final profile = user['particulier_profile'] as Map<String, dynamic>;
        displayName =
            profile['pseudo']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else if (user['pro_profile'] != null) {
        final profile = user['pro_profile'] as Map<String, dynamic>;
        displayName =
            profile['company_name']?.toString() ??
            user['name']?.toString() ??
            'Utilisateur';
      } else {
        displayName = user['name']?.toString() ?? 'Utilisateur';
      }
    }

    String? rawAvatarUrl;
    if (user != null) {
      if (user['particulier_profile'] != null) {
        rawAvatarUrl = user['particulier_profile']['avatar_url']?.toString();
      } else if (user['pro_profile'] != null) {
        rawAvatarUrl = user['pro_profile']['avatar_url']?.toString();
      }
    }
    final avatarUrl = ApiConfig.resolveMediaUrl(rawAvatarUrl);

    final body = (comment['body'] ?? '').toString();
    final createdAt = comment['created_at'];
    String timeAgo = 'Il y a un moment';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt.toString());
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = 'Il y a ${diff.inDays}j';
        } else if (diff.inHours > 0) {
          timeAgo = 'Il y a ${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          timeAgo = 'Il y a ${diff.inMinutes}min';
        }
      } catch (_) {}
    }

    final replies = List<Map<String, dynamic>>.from(
      (comment['replies'] as List?) ?? [],
    );
    final userId = user?['id']?.toString();
    final isOwner = userId != null && userId == _currentUserId;

    final id = comment['id'];
    final idInt = id is int ? id : int.tryParse(id?.toString() ?? '');

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : const AssetImage(
                            'assets/images/dashboard_particulier/Ellipse 10.png',
                          )
                          as ImageProvider,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: isReply ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                            fontFamily: 'Manjari',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: isReply ? 10 : 11,
                            color: Colors.grey[500],
                            fontFamily: 'Manjari',
                          ),
                        ),
                        if (isOwner && (onEdit != null || onDelete != null)) ...[
                          const Spacer(),
                          GestureDetector(
                            onTapDown: (TapDownDetails details) {
                              showMenu<String>(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  details.globalPosition.dx,
                                  details.globalPosition.dy,
                                  details.globalPosition.dx,
                                  details.globalPosition.dy,
                                ),
                                items: [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Modifier'),
                                    ]),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                      SizedBox(width: 8),
                                      Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                                    ]),
                                  ),
                                ],
                              ).then((value) {
                                if (value == 'edit') onEdit?.call(comment);
                                else if (value == 'delete') onDelete?.call(comment, isReply);
                              });
                            },
                            child: Icon(Icons.more_horiz, size: 18, color: Colors.grey[400]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: isReply ? 12 : 13,
                        color: Colors.grey[700],
                        height: 1.4,
                        fontFamily: 'Manjari',
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (!isReply && idInt != null && onReply != null)
                      GestureDetector(
                        onTap: () => onReply(idInt, displayName),
                        child: Text(
                          'Répondre',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Manjari',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isReply && replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...replies.map(
              (r) => _buildCommentItem(r, isReply: true, onReply: onReply, onEdit: onEdit, onDelete: onDelete),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic>? _effectiveAuthorData() {
    final user = widget.demandeData?['user'];
    if (user is Map<String, dynamic>) return user;
    if (user is String) {
      try {
        final decoded = jsonDecode(user);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _checkFollowStatus() async {
    final author = _effectiveAuthorData();
    if (author == null) return;
    final authorId = author['id']?.toString();
    if (authorId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/profile/$authorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_following'] == true) {
          setState(() => _isFollowing = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final author = _effectiveAuthorData();
    if (author == null) return;
    final authorId = author['id']?.toString();
    if (authorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de suivre cet utilisateur')),
      );
      return;
    }

    setState(() => _isLoadingFollow = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      if (_isFollowing) {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/unfollow'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() => _isFollowing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous ne suivez plus cet utilisateur'),
            ),
          );
        }
      } else {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/profile/$authorId/follow'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() => _isFollowing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous suivez maintenant cet utilisateur'),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingFollow = false);
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (widget.demandeId == null) return;

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/demandes/${widget.demandeId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']?['is_favorited'] == true) {
          setState(() => _isFavorite = true);
        }
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (widget.demandeId == null) return;

    setState(() => _isLoadingFavorite = true);

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter')),
        );
        return;
      }

      if (_isFavorite) {
        // Unfavorite
        final response = await http.delete(
          Uri.parse(
            '${ApiConfig.baseUrl}/demandes/${widget.demandeId}/favorite',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          setState(() => _isFavorite = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Retiré des favoris')));
        }
      } else {
        // Favorite
        final response = await http.post(
          Uri.parse(
            '${ApiConfig.baseUrl}/demandes/${widget.demandeId}/favorite',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() => _isFavorite = true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ajouté aux favoris')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _startConversationWithAuthor(
    BuildContext context,
    Map<String, dynamic> authorData,
  ) async {
    final authorId = authorData['id']?.toString();

    String authorName = 'Utilisateur';
    if (authorData['particulier_profile'] != null) {
      final particulierProfile =
          authorData['particulier_profile'] as Map<String, dynamic>;
      authorName =
          particulierProfile['pseudo']?.toString() ??
          authorData['email']?.toString().split('@').first ??
          'Utilisateur';
    } else if (authorData['pro_profile'] != null) {
      final proProfile = authorData['pro_profile'] as Map<String, dynamic>;
      authorName =
          proProfile['company_name']?.toString() ??
          (proProfile['first_name']?.toString() != null &&
                  proProfile['last_name']?.toString() != null
              ? '${proProfile['first_name']} ${proProfile['last_name']}'
              : authorData['email']?.toString().split('@').first) ??
          'Utilisateur';
    }

    String? authorAvatar;
    if (authorData['particulier_profile'] != null) {
      final particulierProfile =
          authorData['particulier_profile'] as Map<String, dynamic>;
      authorAvatar = particulierProfile['avatar_url']?.toString();
    } else if (authorData['pro_profile'] != null) {
      final proProfile = authorData['pro_profile'] as Map<String, dynamic>;
      authorAvatar =
          proProfile['avatar_url']?.toString() ??
          proProfile['logo_url']?.toString();
    }

    if (authorId == null || authorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de démarrer la conversation'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final otherUserId = int.tryParse(authorId);
    if (otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID utilisateur invalide'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final conversationService = ConversationService();
      final conversation = await conversationService.getOrCreateConversation(
        otherUserId,
      );

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation.id.toString(),
              name: authorName,
              avatar:
                  authorAvatar ??
                  'assets/images/dashboard_particulier/Ellipse 10.png',
              status: 'En ligne',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        String errorMessage = 'Échec, veuillez réessayer';
        final exceptionString = e.toString();
        if (exceptionString.startsWith('Exception: ')) {
          errorMessage = exceptionString.substring('Exception: '.length);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Extracts and resolves image URLs from demandeData as fallback
  List<String> _extractImagesFromDemandeData() {
    if (widget.images.isNotEmpty) return widget.images;

    final data = widget.demandeData;
    if (data == null) return [];

    final mediaFiles = data['media'] ?? data['media_files'];
    if (mediaFiles is! List) return [];

    final List<String> imageUrls = [];
    final serverBase = ApiConfig.baseUrl.replaceFirst('/api', '');

    for (final item in mediaFiles) {
      if (item is Map<String, dynamic>) {
        final url = item['url']?.toString();
        if (url != null && url.isNotEmpty) {
          if (url.startsWith('http')) {
            imageUrls.add(url);
          } else if (url.startsWith('/storage/')) {
            // URL already has /storage/ prefix, just prepend server base
            imageUrls.add('$serverBase$url');
          } else if (url.startsWith('/')) {
            imageUrls.add('$serverBase$url');
          } else {
            // Relative path without leading /
            imageUrls.add('$serverBase/$url');
          }
        }
      }
    }

    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveImages = _extractImagesFromDemandeData();
    return AppLayout(
      backgroundColor: const Color(0xFFF9F9FB),
      onTabTapped: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ParticulierMainScreen(initialIndex: index),
          ),
          (route) => false,
        );
      },
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 10),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Color(0xFF616161),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails de la demande',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF616161),
                  size: 24,
                ),
                offset: const Offset(0, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    if (widget.demandeId != null &&
                        widget.demandeData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreerDemandeScreen(
                            demandeId: widget.demandeId,
                            initialData: widget.demandeData,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de modifier cette demande'),
                        ),
                      );
                    }
                  } else if (value == 'delete') {
                    _showDeleteDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Color(0xFF616161),
                        ),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications activées')),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE6F7EF),
                border: Border.all(color: const Color(0xFF2A8143), width: 1.5),
              ),
              child: const Icon(
                Icons.notifications,
                color: Color(0xFF2A8143),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Carousel - full width
            if (effectiveImages.isNotEmpty)
              ImageCarousel(images: effectiveImages),

            // 2. Tags + Title + Urgent
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nature tag
                  if (widget.type != null && widget.type!.isNotEmpty)
                    _buildTag(
                      _getTypeLabel(widget.type!),
                      Icons.description_outlined,
                      const Color(0xFF3AAE5E),
                    ),
                  if (widget.type != null && widget.type!.isNotEmpty)
                    const SizedBox(height: 10),
                  // Urgent badge
                  if (widget.urgent)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Demande urgente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Title
                  Text(
                    widget.demandeTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Manjari',
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // 3. Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Manjari',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.description.isNotEmpty
                        ? widget.description
                        : 'Aucune description fournie.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.6,
                      fontFamily: 'Manjari',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Informations section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Manjari',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildDetailsGrid(),
                  // Date (only when both start_date and end_date exist)
                  if (widget.demandeData != null &&
                      widget.demandeData!['start_date'] != null &&
                      widget.demandeData!['end_date'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      icon: Icons.calendar_today_outlined,
                      iconColor: const Color(0xFF2196F3),
                      bgColor: const Color(0xFFE3F2FD),
                      label: 'Date Souhaitée',
                      value:
                          'Du ${formatDate(widget.demandeData!['start_date'])} jusqu\'au ${formatDate(widget.demandeData!['end_date'])}',
                    ),
                  ],
                  // Lieu
                  if (_hasLocation()) ...[
                    const SizedBox(height: 4),
                    _buildDetailItem(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF3AAE5E),
                      bgColor: const Color(0xFFE6F7EF),
                      label: 'Localisation',
                      value: widget.nationwide
                          ? 'Toute la France'
                          : (widget.location != null &&
                                    widget.location!.isNotEmpty
                                ? (widget.searchRadiusKm != null
                                      ? '${widget.searchRadiusKm}km autour de ${widget.location}'
                                      : widget.location!)
                                : 'Non spécifié'),
                    ),
                  ],
                  // Budget
                  if (widget.demandeData != null &&
                      (widget.demandeData!['budget_min'] != null ||
                          widget.demandeData!['budget_max'] != null)) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF2A8143),
                      bgColor: const Color(0xFFE6F7EF),
                      label: 'Budget',
                      value: _buildBudgetText(),
                    ),
                  ],

                  // Date (only when both start_date and end_date exist)
                  const SizedBox(height: 5),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. CTA buttons
            if (!widget.isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Reply button
                    if (widget.acceptMessages)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final author = widget.demandeData?['user'];
                            if (author is Map<String, dynamic>) {
                              _startConversationWithAuthor(context, author);
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Impossible de démarrer la conversation',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                          icon: const Icon(Icons.reply_outlined, size: 20),
                          label: const Text('Répondre à la demande'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    if (widget.acceptMessages) const SizedBox(height: 12),

                    // Documents button
                    if (((formatBool(
                                  widget.demandeData?['use_candidate_documents'] ??
                                      widget.demandeData?['doc_cand'],
                                ) ==
                                'Oui') ||
                            (widget.demandeData?['media_files'] as List? ??
                                    widget.demandeData?['media'] as List? ??
                                    [])
                                .isNotEmpty) &&
                        !(widget.nature?.toLowerCase().contains('immobilier') ??
                            false))
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ouverture des documents...'),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.description_outlined,
                            size: 20,
                          ),
                          label: const Text('Voir les documents'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3AAE5E),
                            side: const BorderSide(color: Color(0xFF3AAE5E)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (((formatBool(
                                  widget.demandeData?['use_candidate_documents'] ??
                                      widget.demandeData?['doc_cand'],
                                ) ==
                                'Oui') ||
                            (widget.demandeData?['media_files'] as List? ??
                                    widget.demandeData?['media'] as List? ??
                                    [])
                                .isNotEmpty) &&
                        !(widget.nature?.toLowerCase().contains('immobilier') ??
                            false))
                      const SizedBox(height: 16),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 6. Action row (Favoris - Share button commented out)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: _isLoadingFavorite
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: _isFavorite
                                  ? Colors.red
                                  : Colors.grey[600],
                              size: 24,
                            ),
                    ),
                    Text(
                      'Favoris',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFavorite ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _shareDemande,
                      icon: Icon(Icons.share_outlined, color: Colors.grey[600], size: 24),
                    ),
                    Text(
                      'Partager',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Manjari',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7. Owner section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: _resolveOwnerAvatar().startsWith('http')
                        ? NetworkImage(_resolveOwnerAvatar()) as ImageProvider
                        : const AssetImage(
                            'assets/images/dashboard_particulier/Ellipse 12.png',
                          ),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resolveOwnerName(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            fontFamily: 'Manjari',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7EF),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFF3AAE5E).withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            _resolveUserType(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF3AAE5E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isOwner)
                    _isLoadingFollow
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : OutlinedButton(
                            onPressed: _toggleFollow,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isFollowing
                                  ? Colors.grey
                                  : const Color(0xFF3AAE5E),
                              side: BorderSide(
                                color: _isFollowing
                                    ? Colors.grey
                                    : const Color(0xFF3AAE5E),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              _isFollowing ? 'Suivi' : 'Suivre',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 8. Posted time (at bottom, like on events detail)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.timeAgo.isNotEmpty ? widget.timeAgo : 'Posté récemment',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontFamily: 'Manjari',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 9. Comments section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.comment_outlined,
                        color: Color(0xFF616161),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Commentaires',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Manjari',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_localCommentsCount ?? _comments.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontFamily: 'Manjari',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_comments.isEmpty &&
                      (_localCommentsCount == null || _localCommentsCount == 0))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Aucun commentaire. Soyez le premier !',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Manjari',
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _comments
                          .take(2)
                          .map((c) => _buildCommentItem(c, onReply: null))
                          .toList(),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCommentsSheet(context),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: Text(
                        _comments.isEmpty
                            ? 'Ajouter un commentaire'
                            : 'Voir tous les commentaires',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3AAE5E),
                        side: const BorderSide(color: Color(0xFF3AAE5E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 10. Demandes similaires
            const Center(
              child: Text(
                'Autres demandes similaires qui pourraient vous interesser',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                  fontFamily: 'Manjari',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(height: 1, color: Colors.grey[300]),
            ),
            if (_isLoadingSimilar)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_similarDemandes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Text(
                    'Aucune demande similaire trouvée.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontFamily: 'Manjari',
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: _similarDemandes
                      .map((d) => _buildSimilarDemandeCard(d))
                      .toList(),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _shareDemande() {
    final title = widget.demandeTitle;
    final nature = widget.nature ?? 'Général';
    final type = widget.type ?? '';
    final location = widget.locationCity ?? (widget.nationwide ? 'Toute la France' : 'Lieu non précisé');
    final description = widget.description;
    final demandeId = widget.demandeId;
    final budget = widget.budgetMax;

    // Deep link URL
    final String deepLink = ShareService.buildUrl('demandes', demandeId ?? '');

    final String budgetText = budget != null && budget.isNotEmpty ? '\n💰 Budget max: $budget' : '';

    final String shareText = '''📋 $title

🏷️ $nature${type.isNotEmpty ? ' • $type' : ''}
📍 $location$budgetText

$description

$deepLink'''
        .trim();

    Share.share(shareText, subject: title);
  }

  void _showDeleteDialog(BuildContext context) {
    if (widget.demandeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cette demande')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Supprimer la demande',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Manjari',
              ),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette demande ? Cette action est irréversible.',
              style: TextStyle(fontFamily: 'Manjari'),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          final token = await TokenStorage.getAccessToken();
                          if (token == null) throw Exception('Session expirée');
                          final response = await http.delete(
                            Uri.parse(
                              '${ApiConfig.baseUrl}/demandes/${widget.demandeId}',
                            ),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 &&
                              response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Demande supprimée avec succès'),
                                backgroundColor: Color(0xFF3AAE5E),
                              ),
                            );
                            Navigator.pop(context, 'deleted');
                          } else {
                            throw Exception('Erreur ${response.statusCode}');
                          }
                        } catch (e) {
                          setDialogState(() => isDeleting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erreur: ${e.toString().replaceFirst("Exception: ", "")}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Supprimer',
                        style: TextStyle(fontFamily: 'Manjari'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manjari',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'Manjari',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Manjari',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasLocation() {
    return widget.nationwide ||
        (widget.location != null && widget.location!.isNotEmpty);
  }

  String _buildBudgetText() {
    final data = widget.demandeData ?? const <String, dynamic>{};
    final budgetMin = data['budget_min'];
    final budgetMax = data['budget_max'];

    final bool hasMin = budgetMin != null;
    final bool hasMax = budgetMax != null;

    // Format min value
    String? minStr;
    if (hasMin) {
      final minNum = double.tryParse(budgetMin.toString()) ?? 0;
      minStr = '${minNum.round()} €';
    }

    // Format max value
    String? maxStr;
    if (hasMax) {
      final maxNum = double.tryParse(budgetMax.toString()) ?? 0;
      maxStr = '${maxNum.round()} €';
    }

    // Return appropriate format based on which values exist
    if (hasMin && hasMax) {
      return 'Min: $minStr - Max: $maxStr';
    } else if (hasMin) {
      return 'Min: $minStr';
    } else if (hasMax) {
      return 'Max: $maxStr';
    }

    return 'Non spécifié';
  }

  List<Widget> _buildDetailsGrid() {
    final tiles = _buildDetailTiles();
    if (tiles.isEmpty) return [];
    return tiles
        .map(
          (t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: t),
        )
        .toList();
  }

  String? str(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  List<String> listStr(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  String? formatDate(dynamic v) {
    final raw = str(v);
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  String? formatBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v ? 'Oui' : 'Non';
    final s = v.toString().toLowerCase();
    if (s == '1' || s == 'true') return 'Oui';
    if (s == '0' || s == 'false') return 'Non';
    return null;
  }

  List<Widget> _buildDetailTiles() {
    final data = widget.demandeData ?? const <String, dynamic>{};

    final n = (widget.nature ?? '').toString().trim().toLowerCase();
    final isFormation =
        n.contains('formation') ||
        n.contains('training') ||
        n.contains('searchtraining');
    final isImmobilier = n.contains('immobilier') || n.contains('realestate');
    final isStage = n.contains('stage') || n.contains('internship');
    final isEmploi =
        n.contains("emploi") ||
        n.contains("searchjob") ||
        n.contains("jobsearch");
    final isAlternance = n.contains('alternance');

    final tiles = <Widget>[];

    void addTile({
      required IconData icon,
      required Color iconBg,
      required Color iconColor,
      required String title,
      String? value,
      String? subtitle,
    }) {
      final v = value ?? subtitle;
      if (v == null || v.trim().isEmpty) return;
      tiles.add(
        _buildDetailItem(
          icon: icon,
          bgColor: iconBg,
          iconColor: iconColor,
          label: title,
          value: v,
        ),
      );
    }

    if (isFormation) {
      const educationLabels = {
        'aucun': 'Aucun diplôme',
        'brevet': 'Brevet des collèges',
        'cap_bep': 'CAP / BEP',
        'bac': 'Baccalauréat',
        'bac_2': 'Bac +2 (BTS, DUT)',
        'bac_3_4': 'Bac +3/4 (Licence, Master 1)',
        'bac_5': 'Bac +5 (Master 2, Ingénieur)',
        'doctorat': 'Doctorat',
      };

      const experienceLabels = {
        'junior': 'Débutant (0-2 ans)',
        'intermediaire': 'Intermédiaire (2-5 ans)',
        'confirme': 'Confirmé (5-10 ans)',
        'senior': 'Sénior (+10 ans)',
      };

      // final fCategory =
      //     data['training_category'] ??
      //     data['category'] ??
      //     data['category_label'] ??
      //     data['training']?['category'] ??
      //     data['details']?['category'];
      // addTile(
      //   icon: Icons.school_outlined,
      //   iconBg: const Color(0xFFEDE7F6),
      //   iconColor: const Color(0xFF673AB7),
      //   title: 'Catégorie de formation souhaité',
      //   value: str(fCategory)?.replaceAll('_', ' ').capitalize(),
      // );

      final fSector =
          data['training_sector'] ??
          data['sector'] ??
          data['sector_label'] ??
          data['training']?['sector'] ??
          data['details']?['sector'];
      addTile(
        icon: Icons.hub_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Secteur de formation',
        value: str(fSector),
      );

      final fType =
          data['training_type'] ??
          data['type'] ??
          data['type_label'] ??
          data['training']?['type'] ??
          data['details']?['type'];
      addTile(
        icon: Icons.auto_stories_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Type de formation souhaité',
        value: 'Formation ${str(fType)?.capitalize()}',
      );

      const teachingLabels = {
        'tout': 'Tout',
        'entreprise': 'En entreprise',
        'alternance': 'En alternance',
        'centre': 'En centre',
        'distance': 'À distance',
      };

      const financingLabels = {
        'tout': 'Tout',
        'conseil_regional': 'Conseil régional',
        'opco': 'OPCO',
        'mission_locale': 'Mission Locale',
        'auto_financement': 'Auto-Financement',
        'agefiph': 'AGEFIPH',
        'pole_emploi': 'Pôle Emploi',
        'cpf': 'CPF',
      };

      final tRaw =
          data['teaching_types'] ??
          data['teaching'] ??
          data['teaching_type'] ??
          data['training']?['teaching_types'] ??
          data['details']?['teaching_types'];
      final teaching = listStr(
        tRaw,
      ).map((c) => teachingLabels[c] ?? c).toList();
      addTile(
        icon: Icons.cast_for_education_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Type d\'enseignement souhaité',
        value: teaching.isNotEmpty ? teaching.join(', ') : null,
      );

      final fRaw =
          data['financing_types'] ??
          data['financing'] ??
          data['financing_type'] ??
          data['training']?['financing_types'] ??
          data['details']?['financing_types'];
      final financing = listStr(
        fRaw,
      ).map((c) => financingLabels[c] ?? c).toList();
      addTile(
        icon: Icons.payments_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Financement possible',
        value: financing.isNotEmpty ? financing.join(', ') : null,
      );

      final immediate = formatBool(
        data['dans_immediat'] ?? data['immediate_availability'],
      );
      if (immediate == 'Oui') {
        addTile(
          icon: Icons.flash_on_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          title: 'Disponibilité',
          value: 'Immédiate',
        );
      } else {
        final start = formatDate(
          data['start_date'] ??
              data['start'] ??
              data['training']?['start_date'],
        );
        final end = formatDate(
          data['end_date'] ?? data['end'] ?? data['training']?['end_date'],
        );
        addTile(
          icon: Icons.event_available_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF2A8143),
          title: 'Dates de formation souhaitées',
          value: start != null
              ? (end != null ? 'Du $start au $end' : 'À partir du $start')
              : null,
        );
      }

      final roleStr =
          str(data['user_type']) ??
          str(data['user_role']) ??
          str(data['user']?['role']) ??
          '';
      final isProUser = roleStr.contains('pro') || roleStr.contains('business');
      final hasProData =
          (str(data['nb_personnes']) != null ||
              str(data['nb_personnes']) != null) ||
          (str(data['nb_groupes']) != null || str(data['nb_groupes']) == null);

      if (isProUser || hasProData) {
        final nbP = str(
          data['nb_personnes'] ??
              data['training']?['nb_personnes'] ??
              data['details']?['nb_personnes'],
        );
        final nbG = str(
          data['nb_groupes'] ??
              data['training']?['nb_groupes'] ??
              data['details']?['nb_groupes'],
        );
        String? targetValue;
        if (nbP != null && nbG != null) {
          targetValue = '$nbP personne(s) / $nbG groupe(s)';
        } else if (nbP != null) {
          targetValue = '$nbP personne(s)';
        } else if (nbG != null) {
          targetValue = '$nbG groupe(s)';
        } else {
          targetValue = 'À définir';
        }
        addTile(
          icon: Icons.people_outline,
          iconBg: const Color(0xFFF5F5F5),
          iconColor: const Color(0xFF616161),
          title: 'Public à former',
          value: targetValue,
        );
      } else if (UserSession().isParticulier) {
        final edRaw =
            data['education_level'] ??
            data['level_education'] ??
            data['training']?['education_level'] ??
            data['details']?['education_level'];
        addTile(
          icon: Icons.school_outlined,
          iconBg: Colors.orange.withValues(alpha: 0.1),
          iconColor: Colors.orange,
          title: 'Niveau d\'étude',
          value: educationLabels[str(edRaw)] ?? str(edRaw) ?? 'À définir',
        );
        final exRaw =
            data['experience_level'] ??
            data['level_experience'] ??
            data['training']?['experience_level'] ??
            data['details']?['experience_level'];
        addTile(
          icon: Icons.work_history_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF3AAE5E),
          title: 'Niveau d\'expérience',
          value: experienceLabels[str(exRaw)] ?? str(exRaw) ?? 'À définir',
        );
      }
    } else if (isImmobilier) {
      final props = listStr(data['property_types']);
      addTile(
        icon: Icons.home_work_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Type de bien souhaité',
        value: props.isNotEmpty ? props.join(', ') : null,
      );
      final shMin = str(data['surface_habitable_min']);
      final shMax = str(data['surface_habitable_max']);
      String? surfaceHabitableValue;
      if (shMin != null && shMax != null) {
        surfaceHabitableValue = 'Min: $shMin m² - Max: $shMax m²';
      } else if (shMin != null) {
        surfaceHabitableValue = 'Min: $shMin m²';
      } else if (shMax != null) {
        surfaceHabitableValue = 'Max: $shMax m²';
      }
      addTile(
        icon: Icons.square_foot_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Surface habitable',
        value: surfaceHabitableValue,
      );
      final stMin = str(data['surface_terrain_min']);
      final stMax = str(data['surface_terrain_max']);
      String terrainValue;

      final stMinNum = double.tryParse(stMin ?? '0') ?? 0;
      final stMaxNum = double.tryParse(stMax ?? '0') ?? 0;

      if (stMinNum > 0 && stMaxNum > 0) {
        terrainValue = 'Min: $stMinNum m² - Max: $stMaxNum m²';
      } else if (stMinNum > 0) {
        terrainValue = 'Min: $stMinNum m²';
      } else if (stMaxNum > 0) {
        terrainValue = 'Max: $stMaxNum m²';
      } else {
        terrainValue = 'indifférent';
      }

      addTile(
        icon: Icons.terrain_outlined,
        iconBg: const Color(0xFFEDE7F6),
        iconColor: const Color(0xFF673AB7),
        title: 'Terrain',
        value: terrainValue,
      );
      addTile(
        icon: Icons.meeting_room_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Nombre de Pièces',
        value: str(data['nb_pieces']) ?? "indifférent",
      );
      addTile(
        icon: Icons.bed_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Nombre de Chambres',
        value: str(data['nb_chambres']) ?? "indifférent",
      );
    } else if (isEmploi || isStage || isAlternance) {
      // Translation maps
      const educationLabels = {
        'sans_diplome': 'Sans diplome',
        'cap_bep': 'CAP/BEP',
        'bac_employe': 'BAC/Employé/Ouvrier spécialisé',
        'bac2_technicien': 'BAC+2/Technicien/Employé',
        'bac3_agent_maitrise': 'BAC+3/Agent de maîtrise',
        'bac5_ingenieur': 'BAC+5 ou plus/Ingénieur/Cadre',
      };

      const experienceLabels = {
        'debutant': 'Débutant : de 0 a 1 annee',
        'intermediaire': 'Intermédiaire : de 2 a 4 annee',
        'confirme': 'Confirme : de 5 a 9 annee',
        'senior': 'Senior : de 10 annee ou plus',
      };

      const contractLabels = {
        'cdi': 'CDI',
        'cdd': 'CDD',
        'interim': 'Intérim',
        'independant': 'Indépendant / Freelance',
        'benevolat': 'Bénévolat',
        'apprentissage': 'Apprentissage',
        'stage': 'Stage',
      };

      const sectorLabels = {
        'secteur_achats': 'Achats',
        'secteur_administratif': 'Administratif',
        'secteur_aeronautique': 'Aéronautique',
        'secteur_agriculture': 'Agriculture',
        'secteur_agroalimentaire': 'Agroalimentaire',
        'secteur_architecture': 'Architecture',
        'secteur_artisanat': 'Artisanat',
        'secteur_assurances': 'Assurances',
        'secteur_audiovisuel': 'Audiovisuel',
        'secteur_audit': 'Audit',
        'secteur_automobile': 'Automobile',
        'secteur_banque': 'Banque',
        'secteur_batiment': 'Bâtiment',
        'secteur_beaute': 'Beauté',
        'secteur_bois': 'Bois',
        'secteur_chimie': 'Chimie',
        'secteur_commerce': 'Commerce',
        'secteur_communication': 'Communication',
        'secteur_comptabilite': 'Comptabilité',
        'secteur_conseil': 'Conseil',
        'secteur_construction': 'Construction',
        'secteur_culture': 'Culture',
        'secteur_defense': 'Défense',
        'secteur_design': 'Design',
        'secteur_distribution': 'Distribution',
        'secteur_droit': 'Droit',
        'secteur_edition': 'Édition',
        'secteur_education': 'Éducation',
        'secteur_electronique': 'Électronique',
        'secteur_energie': 'Énergie',
        'secteur_enseignement': 'Enseignement',
        'secteur_environnement': 'Environnement',
        'secteur_evenementiel': 'Événementiel',
        'secteur_finance': 'Finance',
        'secteur_fonction_publique': 'Fonction publique',
        'secteur_hotellerie': 'Hôtellerie',
        'secteur_immobilier': 'Immobilier',
        'secteur_industrie': 'Industrie',
        'secteur_informatique': 'Informatique',
        'secteur_ingenierie': 'Ingénierie',
        'secteur_internet': 'Internet',
        'secteur_journalisme': 'Journalisme',
        'secteur_juridique': 'Juridique',
        'secteur_logistique': 'Logistique',
        'secteur_luxe': 'Luxe',
        'secteur_marketing': 'Marketing',
        'secteur_mecanique': 'Mécanique',
        'secteur_medical': 'Médical',
        'secteur_mode': 'Mode',
        'secteur_multimedia': 'Multimédia',
        'secteur_naval': 'Naval',
        'secteur_pharmaceutique': 'Pharmaceutique',
        'secteur_production': 'Production',
        'secteur_publicite': 'Publicité',
        'secteur_qualite': 'Qualité',
        'secteur_recherche': 'Recherche',
        'secteur_restauration': 'Restauration',
        'secteur_ressources_humaines': 'Ressources humaines',
        'secteur_sante': 'Santé',
        'secteur_securite': 'Sécurité',
        'secteur_services': 'Services',
        'secteur_social': 'Social',
        'secteur_sport': 'Sport',
        'secteur_telecommunication': 'Télécommunication',
        'secteur_textile': 'Textile',
        'secteur_tourisme': 'Tourisme',
        'secteur_transport': 'Transport',
        'secteur_travail_temporaire': 'Travail temporaire',
        'secteur_vente': 'Vente',
      };

      const functionLabels = {
        'administratif': 'Agent de bureau',
        'aeronautique': 'Agent de liaison',
        'agriculture': 'Adjoint DAF',
      };

      const workTypeLabels = {
        'temps_plein': 'Temps plein',
        'temps_partiel': 'Temps partiel',
      };

      final sectorKey = str(data['activity_sector']);
      final sectorLabel = _sectorCodeToLabel[sectorKey] ?? sectorKey;
      addTile(
        icon: Icons.work_outline,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1E88E5),
        title: 'Secteur d\'activité',
        value: sectorLabel,
      );
      final functionKey = str(data['function']);
      final functionLabel = _functionCodeToLabel[functionKey] ?? functionKey;
      addTile(
        icon: Icons.badge_outlined,
        iconBg: const Color(0xFFF5F5F5),
        iconColor: const Color(0xFF616161),
        title: 'Fonction recherchée',
        value: functionLabel,
      );
      final contracts = listStr(
        data['contract_types'],
      ).map((c) => contractLabels[c] ?? c).toList();
      addTile(
        icon: Icons.assignment_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF2A8143),
        title: 'Type de contrat souhaité',
        value: contracts.isNotEmpty ? contracts.join(', ') : null,
      );
      final workTypeKey = str(data['work_type']);
      addTile(
        icon: Icons.schedule_outlined,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFFF9800),
        title: 'Temps de travail souhaité',
        value: workTypeKey != null
            ? (workTypeLabels[workTypeKey] ?? workTypeKey)
            : null,
      );

      addTile(
        icon: Icons.school_outlined,
        iconBg: Colors.orange.withValues(alpha: 0.1),
        iconColor: Colors.orange,
        title: 'Niveau d\'étude',
        value:
            educationLabels[str(data['education_level'])] ??
            str(data['education_level']),
      );

      addTile(
        icon: Icons.work_history_outlined,
        iconBg: const Color(0xFFE6F7EF),
        iconColor: const Color(0xFF3AAE5E),
        title: 'Niveau d\'expérience',
        value:
            experienceLabels[str(data['experience_level'])] ??
            str(data['experience_level']),
      );

      addTile(
        icon: Icons.home_work_outlined,
        iconBg: Colors.blue.withValues(alpha: 0.1),
        iconColor: Colors.blue,
        title: 'Télétravail souhaité',
        value: formatBool(data['accept_remote_work']),
      );

      final immediate = formatBool(data['immediate_availability']);
      if (immediate == 'Oui') {
        addTile(
          icon: Icons.flash_on_outlined,
          iconBg: const Color(0xFFFFF3E0),
          iconColor: const Color(0xFFFF9800),
          title: 'Disponibilité',
          value: 'Immédiate',
        );
      }

      if (immediate == 'Non') {
        addTile(
          icon: Icons.event_available_outlined,
          iconBg: const Color(0xFFE6F7EF),
          iconColor: const Color(0xFF2A8143),
          title: 'Date de début souhaité',
          value: formatDate(data['start_date']),
        );
        addTile(
          icon: Icons.event_outlined,
          iconBg: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE53935),
          title: 'Fin',
          value: formatDate(data['end_date']),
        );
      }

      final salaryRange = str(data['salary_range']);
      final sMin = str(data['salary_min']);
      final sMax = str(data['salary_max']);
      final netOrBrut = str(data['salary_net_or_brut']);
      final indice = str(
        data['salary_indice_temporel'] ??
            data['salary_period'] ??
            data['period'],
      );

      String? salaryText() {
        final hasMinMax =
            (sMin != null && sMin.isNotEmpty) ||
            (sMax != null && sMax.isNotEmpty);

        String suffix = '';
        if (indice == 'annees' ||
            indice == 'annee' ||
            indice == 'an' ||
            indice == 'annuel') {
          suffix = ' / An';
        } else if (indice == 'mois' ||
            indice == 'mensuel' ||
            indice == 'mensualite') {
          suffix = ' / Mois';
        } else if (indice == 'heures' ||
            indice == 'heure' ||
            indice == 'horaire') {
          suffix = ' / Heure';
        } else if (indice == 'jours' ||
            indice == 'jour' ||
            indice == 'journalier') {
          suffix = ' / Jour';
        }

        if (hasMinMax) {
          var t = '${sMin ?? '-'} - ${sMax ?? '-'} €';
          if (netOrBrut == 'Net' || netOrBrut == 'net') t += ' (Net)';
          if (netOrBrut == 'Brut' || netOrBrut == 'brut') t += ' (Brut)';
          t += suffix;
          return t;
        }

        if (salaryRange != null &&
            salaryRange.toLowerCase() != 'aucune' &&
            salaryRange.toLowerCase() != 'none') {
          return salaryRange + suffix;
        }
        return null;
      }

      addTile(
        icon: Icons.euro,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFE53935),
        title: 'Prétention salariale',
        value: salaryText(),
      );
    }

    return tiles;
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return 'il y a ${diff.inDays ~/ 7} semaine(s)';
      if (diff.inDays > 0) return 'il y a ${diff.inDays} jour(s)';
      if (diff.inHours > 0) return 'il y a ${diff.inHours} heure(s)';
      return 'il y a ${diff.inMinutes} min';
    } catch (_) {
      return '';
    }
  }

  String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  // --- Reaction infrastructure for similar items ---
  final Map<String, _ReactionData> _reactions = {};
  String _rKey(String s, String id) => '${s}_$id';
  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  _ReactionData _getReaction(String s, String id) =>
      _reactions.putIfAbsent(_rKey(s, id), () => _ReactionData());
  void _seedReaction(String s, String id, Map<String, dynamic> r) {
    _reactions.putIfAbsent(
      _rKey(s, id),
      () => _ReactionData(
        likesCount: _asInt(r['likes_count']),
        commentsCount: _asInt(r['comments_count']),
        userReaction: r['user_reaction']?.toString(),
      ),
    );
  }

  Future<void> _toggleReaction(
    String apiSlug,
    String entityId,
    String type,
  ) async {
    final data = _getReaction(apiSlug, entityId);

    // Optimistic update
    final oldReaction = data.userReaction;
    final oldLikes = data.likesCount;

    setState(() {
      if (oldReaction == type) {
        data.userReaction = null;
        if (type == 'like') data.likesCount--;
      } else {
        if (oldReaction == 'like') data.likesCount--;
        data.userReaction = type;
        if (type == 'like') data.likesCount++;
      }
    });

    try {
      final response = await ApiClient().authenticatedPost(
        '/$apiSlug/$entityId/reactions',
        body: {'type': type},
      );
      final respData = response['data'] as Map<String, dynamic>?;
      if (respData != null && mounted) {
        final newReaction = respData['user_reaction']?.toString();
        setState(() {
          data.likesCount = _asInt(respData['likes_count']);
          data.userReaction = newReaction;
        });
        ReactionCacheService.save(apiSlug, entityId, newReaction);
        ReactionCacheService.saveCount(apiSlug, entityId, data.likesCount);
      }
    } catch (e) {
      debugPrint('Reaction error: $e');
      if (mounted) {
        setState(() {
          data.likesCount = oldLikes;
          data.userReaction = oldReaction;
        });
      }
    }
  }

  void _showEntityCommentsSheet(String apiSlug, String entityId) async {
    await _getCurrentUserId();
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    String? error;
    final commentCtrl = TextEditingController();
    int? replyingToId;
    String? replyingToName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, modalSetState) {
            // Load on first build
            if (isLoading && comments.isEmpty && error == null) {
              ApiClient()
                  .authenticatedGet('/$apiSlug/$entityId/comments?per_page=50')
                  .then((response) {
                    final data = response['data'];
                    List<Map<String, dynamic>> fetched = [];
                    if (data is Map && data['data'] is List) {
                      fetched = List<Map<String, dynamic>>.from(
                        data['data'] as List,
                      );
                    } else if (data is List) {
                      fetched = List<Map<String, dynamic>>.from(data);
                    }
                    modalSetState(() {
                      comments = fetched;
                      isLoading = false;
                    });
                  })
                  .catchError((e) {
                    modalSetState(() {
                      error = e.toString();
                      isLoading = false;
                    });
                  });
            }

            Future<void> submitComment() async {
              final text = commentCtrl.text.trim();
              if (text.isEmpty) return;

              try {
                Map<String, dynamic> response;
                if (replyingToId != null) {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments/$replyingToId/reply',
                    body: {'body': text},
                  );
                } else {
                  response = await ApiClient().authenticatedPost(
                    '/$apiSlug/$entityId/comments',
                    body: {'body': text},
                  );
                }
                final newComment = response['data'] as Map<String, dynamic>?;
                if (newComment != null) {
                  modalSetState(() {
                    if (replyingToId != null) {
                      final parent = comments.firstWhere(
                        (c) => c['id'] == replyingToId,
                        orElse: () => <String, dynamic>{},
                      );
                      if (parent.isNotEmpty) {
                        final replies = List<Map<String, dynamic>>.from(
                          (parent['replies'] as List?) ?? [],
                        );
                        replies.add(newComment);
                        parent['replies'] = replies;
                        parent['replies_count'] =
                            (parent['replies_count'] as int? ?? 0) + 1;
                      }
                    } else {
                      comments.insert(0, newComment);
                    }
                    replyingToId = null;
                    replyingToName = null;
                  });
                  // Update local comments count in feed
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    data.commentsCount++;
                    ReactionCacheService.saveCommentsCount(
                      apiSlug,
                      entityId,
                      data.commentsCount,
                    );
                  });
                }
                commentCtrl.clear();
                FocusScope.of(ctx).unfocus();

                // Award 1 My for posting a comment (silently, no modal)
                try {
                  final mysResponse = await MysEarningService().awardMys(
                    actionType: 'comment',
                    referenceId: newComment?['id']?.toString(),
                  );
                  if (mysResponse['success'] == true) {
                    final newBalance = mysResponse['earning']?['new_balance'];
                    if (newBalance != null) {
                      UserSession().updateMys(newBalance);
                    }
                  }
                } catch (e) {
                  debugPrint("Error awarding My's for comment: $e");
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            }

            Future<void> toggleCommentReaction(
              Map<String, dynamic> comment,
              String type,
            ) async {
              final commentId = comment['id'];
              try {
                final response = await ApiClient().authenticatedPost(
                  '/comments/$commentId/reactions',
                  body: {'type': type},
                );
                final respData = response['data'] as Map<String, dynamic>?;
                if (respData != null) {
                  modalSetState(() {
                    comment['likes_count'] = respData['likes_count'];
                    comment['user_reaction'] = respData['user_reaction'];
                  });
                }
              } catch (e) {
                debugPrint('Comment reaction error: $e');
              }
            }

            Future<void> editComment(Map<String, dynamic> comment) async {
              final commentId = comment['id'];
              final currentBody = comment['body']?.toString() ?? '';
              final editController = TextEditingController(text: currentBody);

              final newText = await showDialog<String>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Modifier le commentaire'),
                  content: TextField(
                    controller: editController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Votre commentaire...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, editController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AAE5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (newText == null ||
                  newText.trim().isEmpty ||
                  newText == currentBody)
                return;

              try {
                final response = await ApiClient().authenticatedPut(
                  '/comments/$commentId',
                  body: {'body': newText.trim()},
                );
                final updatedComment =
                    response['data'] as Map<String, dynamic>?;
                if (updatedComment != null) {
                  modalSetState(() {
                    comment['body'] = updatedComment['body'];
                    comment['updated_at'] = updatedComment['updated_at'];
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la modification: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Future<void> deleteComment(
              Map<String, dynamic> comment,
              bool isReply,
            ) async {
              final commentId = comment['id'];
              final confirmed = await showDialog<bool>(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le commentaire'),
                  content: const Text(
                    'Êtes-vous sûr de vouloir supprimer ce commentaire ?',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Annuler',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              try {
                await ApiClient().authenticatedDelete('/comments/$commentId');

                // Update local comments count in feed
                if (!isReply) {
                  setState(() {
                    final data = _getReaction(apiSlug, entityId);
                    if (data.commentsCount > 0) data.commentsCount--;
                  });
                }

                modalSetState(() {
                  if (isReply) {
                    final parentId =
                        comment['parent_id'] ?? comment['comment_id'];
                    final parent = comments.firstWhere(
                      (c) => c['id'] == parentId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (parent.isNotEmpty) {
                      final replies = List<Map<String, dynamic>>.from(
                        (parent['replies'] as List?) ?? [],
                      );
                      replies.removeWhere((r) => r['id'] == commentId);
                      parent['replies'] = replies;
                      parent['replies_count'] = replies.length;
                    }
                  } else {
                    comments.removeWhere((c) => c['id'] == commentId);
                  }
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Erreur lors de la suppression: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            }

            Widget buildCommentItem(
              Map<String, dynamic> comment, {
              bool isReply = false,
            }) {
              final user = comment['user'] as Map<String, dynamic>? ?? {};
              final userId = user['id']?.toString(); // Convertir en String
              final email = user['email']?.toString() ?? '';
              final displayName = (userId != null && userId == _currentUserId)
                  ? 'Vous'
                  : (user['display_name']?.toString() ??
                        user['name']?.toString() ??
                        (user['particulier_profile']
                                as Map<String, dynamic>?)?['pseudo']
                            ?.toString() ??
                        (user['pro_profile']
                                as Map<String, dynamic>?)?['company_name']
                            ?.toString() ??
                        email.split('@').first);
              final body = comment['body']?.toString() ?? '';
              final createdAt = comment['created_at']?.toString();
              final likes = _asInt(comment['likes_count']);
              final userReaction = comment['user_reaction']?.toString();
              final isOwner = userId != null && userId == _currentUserId;
              print("UserId: $userId");
              print("_currentUserId: $_currentUserId");
              print("isOwner: $isOwner");
              final replies =
                  (comment['replies'] as List?)
                      ?.map((r) => Map<String, dynamic>.from(r as Map))
                      .toList() ??
                  [];
              // Get avatar URL from user data - check nested profiles
              final particulierProfile =
                  user['particulier_profile'] as Map<String, dynamic>?;
              final proProfile = user['pro_profile'] as Map<String, dynamic>?;
              final avatarUrl =
                  particulierProfile?['avatar_url']?.toString() ??
                  proProfile?['avatar_url']?.toString() ??
                  proProfile?['logo_url']?.toString() ??
                  user['avatar_url']?.toString();

              return Padding(
                padding: EdgeInsets.only(left: isReply ? 32.0 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isReply ? 14 : 18,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(
                                  ApiConfig.resolveMediaUrl(avatarUrl) ??
                                      avatarUrl,
                                )
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: isReply ? 12 : 16,
                                  color: Colors.grey[600],
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: isReply ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _buildTimeAgo(createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTapDown: (TapDownDetails details) {
                                        showMenu<String>(
                                          context: context,
                                          position: RelativeRect.fromLTRB(
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                            details.globalPosition.dx,
                                            details.globalPosition.dy,
                                          ),
                                          items: [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Modifier'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Supprimer',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ).then((value) {
                                          if (value == 'edit') {
                                            editComment(comment);
                                          } else if (value == 'delete') {
                                            deleteComment(comment, isReply);
                                          }
                                        });
                                      },
                                      child: Icon(
                                        Icons.more_horiz,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4F4F4F),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        toggleCommentReaction(comment, 'like'),
                                    child: Row(
                                      children: [
                                        Icon(
                                          userReaction == 'like'
                                              ? Icons.thumb_up_alt
                                              : Icons.thumb_up_alt_outlined,
                                          size: 14,
                                          color: userReaction == 'like'
                                              ? const Color(0xFF3AAE5E)
                                              : Colors.grey[400],
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$likes',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: userReaction == 'like'
                                                ? const Color(0xFF3AAE5E)
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isReply) ...[
                                    const SizedBox(width: 14),
                                    GestureDetector(
                                      onTap: () {
                                        modalSetState(() {
                                          replyingToId = comment['id'] as int?;
                                          replyingToName = displayName;
                                        });
                                        FocusScope.of(
                                          ctx,
                                        ).requestFocus(FocusNode());
                                      },
                                      child: Text(
                                        'Répondre',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E9B5B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Nested replies
                    if (!isReply && replies.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...replies.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: buildCommentItem(r, isReply: true),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Commentaires',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A2A2A),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Comment list
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                          ? Center(
                              child: Text(
                                'Erreur: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun commentaire pour le moment.\nSoyez le premier à commenter !',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: comments.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (_, i) =>
                                  buildCommentItem(comments[i]),
                            ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    // Reply indicator
                    if (replyingToId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        color: const Color(0xFFF5F5F5),
                        child: Row(
                          children: [
                            Text(
                              'Répondre à $replyingToName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => modalSetState(() {
                                replyingToId = null;
                                replyingToName = null;
                              }),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: commentCtrl,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: InputBorder.none,
                                  hintText: 'Écrire un commentaire...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                  ),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => submitComment(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: submitComment,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3AAE5E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _buildStorageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Handle already complete URLs (both http:// and https://)
    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return url;
    }
    // Handle URLs that might incorrectly start with /storage/ followed by http
    if (url.startsWith('/storage/http')) {
      // Extract the actual URL after /storage/
      final actualUrl = url.substring(9); // Remove '/storage/'
      if (actualUrl.toLowerCase().startsWith('http://') ||
          actualUrl.toLowerCase().startsWith('https://')) {
        return actualUrl;
      }
    }
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    // Remove leading slash if present to avoid double slashes
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '$serverBase/storage/$cleanUrl';
  }

  static const _defaultAvatar =
      'assets/images/dashboard_particulier/Ellipse 10.png';

  String? _extractMediaUrl(Map<String, dynamic> resource) {
    final media = resource['media'] ?? resource['media_files'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) {
          // If URL is already complete (http/https), return it as-is
          if (url.startsWith('http')) return url;
          // Otherwise prepend the server base URL
          return "${ApiConfig.baseUrl.replaceFirst('/api', '')}$url";
        }
      }
    }
    final cover = resource['cover_url']?.toString();
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith('http')) return cover;
      return "${ApiConfig.baseUrl.replaceFirst('/api', '')}$cover";
    }
    return null;
  }

  Color _categoryColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('urgent')) return Colors.redAccent;
    if (lower.contains('emploi')) return const Color(0xFF3AAE5E);
    if (lower.contains('stage')) return const Color(0xFF2196F3);
    if (lower.contains('formation')) return const Color(0xFF9C27B0);
    if (lower.contains('immobilier')) return const Color(0xFFFF5722);
    if (lower.contains('service')) return const Color(0xFFFF9800);
    return const Color(0xFF3AAE5E);
  }

  String _buildTimeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final created = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 1) return "à l'instant";
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
      final weeks = (diff.inDays / 7).floor();
      if (weeks < 4) return 'il y a $weeks sem';
      final months = (diff.inDays / 30).floor();
      return 'il y a $months mois';
    } catch (_) {
      return '';
    }
  }

  /// Like _asInt but returns null instead of 0 for null/invalid values
  int? _tryAsInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _currentUserId;

  Future<String?> _getCurrentUserId({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentUserId != null) {
      return _currentUserId;
    }
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final data = response['user'] as Map<String, dynamic>?;
      final id = data?['id']?.toString();

      // Sync mys and parrainage_code to UserSession
      if (data != null) {
        final mys = data['mys'];
        final parrainageCode = data['parrainage_code'];
        if (mys != null) {
          UserSession().updateMys(mys);
        }
        if (parrainageCode != null) {
          UserSession().updateParrainageCode(parrainageCode);
        }
      }

      if (mounted) {
        setState(() => _currentUserId = id);
      } else {
        _currentUserId = id;
      }

      // Refresh bottom bar avatar when user data is fetched
      CustomBottomBar.refreshAvatarNotifier.value = true;

      return id;
    } catch (e) {
      debugPrint('Error fetching current user ID: $e');
      return _currentUserId;
    }
  }

  Future<void> _navigateToDemandeDetail(Map<String, dynamic> demande) async {
    final demandeId = demande['id']?.toString();
    if (demandeId == null || demandeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir cette demande')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/demandes/$demandeId',
      );
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final user = demande['user'] as Map<String, dynamic>?;
      final profileImage =
          _buildStorageUrl(user?['avatar']?.toString()) ?? _defaultAvatar;
      final userName = user?['name']?.toString() ?? 'Utilisateur';
      final userType = user?['account_type']?.toString() ?? 'particulier';

      final title = data['title']?.toString() ?? '';
      final description = data['description']?.toString() ?? '';
      final nature = data['nature']?.toString();
      // For formations, use training_category or training_type
      final type = data['training_category']?.toString();
      final urgent = data['urgent'] == true;
      final budgetMax = data['budget_max']?.toString();
      final location = data['location']?.toString();
      final nationwide = data['nationwide'] == true;
      final searchRadiusKm = data['search_radius_km'] is int
          ? data['search_radius_km'] as int
          : int.tryParse(data['search_radius_km']?.toString() ?? '');
      final showGoogleLocation = data['show_google_location'] == true;
      final acceptMessages = data['accept_messages'] == true;
      final createdAt = data['created_at']?.toString();
      final mediaFiles =
          data['media_files'] as List? ?? data['media'] as List? ?? [];

      final images = mediaFiles
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildStorageUrl(m['url']?.toString()) ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final categoryLabel = (type != null && type.isNotEmpty)
          ? type
          : (nature != null && nature.isNotEmpty ? nature : 'Demande');

      final tags = <PostTag>[
        PostTag(
          title: categoryLabel,
          icon: Icons.label_outline,
          color: Colors.orange,
        ),
        if (urgent)
          PostTag(
            title: 'Urgent',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        if (nationwide)
          PostTag(
            title: 'Toute la France',
            icon: Icons.public,
            color: Colors.blue,
          ),
      ];

      // Check ownership
      final demandeUserId =
          demande['user_id']?.toString() ?? data['user_id']?.toString();
      final currentUserId = await _getCurrentUserId();
      final isOwner =
          demandeUserId != null &&
          currentUserId != null &&
          demandeUserId == currentUserId;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DemandeDetailScreen(
            images: images,
            avatar: profileImage,
            username: userName,
            demandeTitle: title,
            description: description,
            tags: tags,
            timeAgo: createdAt != null ? _buildTimeAgo(createdAt) : '',
            nature: nature,
            type: type,
            urgent: urgent,
            budgetMax: budgetMax,
            location: location,
            nationwide: nationwide,
            searchRadiusKm: searchRadiusKm,
            showGoogleLocation: showGoogleLocation,
            acceptMessages: acceptMessages,
            isOwner: isOwner,
            demandeId: demandeId,
            demandeData: data,
            userType: userType,
            commentsCount: _tryAsInt(data['comments_count']),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Error fetching demande detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: ${e.toString()}')),
      );
    }
  }


  Widget _buildReactionBar(
    String apiSlug,
    String entityId, {
    bool? acceptedMessages,
    Map<String, dynamic>? authorData,
    Map<String, dynamic>? postData,
  }) {
    final data = _getReaction(apiSlug, entityId);
    final isLiked = data.userReaction == 'like';
    final isPost = apiSlug == 'posts';
    final isBonPlan = apiSlug == 'bon-plans';

    return Row(
      children: [
        // Like
        GestureDetector(
          onTap: () => _toggleReaction(apiSlug, entityId, 'like'),
          child: Row(
            children: [
              Icon(
                isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                size: 18,
                color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.likesCount.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isLiked ? const Color(0xFF3AAE5E) : Colors.grey[600],
                  fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        // Comments
        GestureDetector(
          onTap: () => _showEntityCommentsSheet(apiSlug, entityId),
          child: Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 17,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                data.commentsCount.toString(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Share icon
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => ShareService.shareEntity(apiSlug, entityId),
          child: Icon(Icons.share_outlined, size: 18, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildSimilarDemandeCard(Map<String, dynamic> demande) {
    final user = demande['user'] as Map<String, dynamic>?;

    // Extraire le profil particulier
    final particulierProfile =
        user?['particulier_profile'] as Map<String, dynamic>?;
    final proProfile = user?['pro_profile'] as Map<String, dynamic>?;

    // Avatar : particulier_profile.avatar_url ou pro_profile.logo_url
    final avatarUrl =
        particulierProfile?['avatar_url']?.toString() ??
        proProfile?['avatar_url']?.toString() ??
        proProfile?['logo_url']?.toString();
    final profileImage = _buildStorageUrl(avatarUrl) ?? _defaultAvatar;

    // Username : particulier_profile.pseudo ou pro_profile.company_name
    final username =
        particulierProfile?['pseudo']?.toString() ??
        proProfile?['company_name']?.toString() ??
        user?['email']?.toString() ??
        'Utilisateur';

    final title = demande['title']?.toString() ?? 'Demande';
    final description = _stripHtml(demande['description']?.toString() ?? '');

    // Nature de la demande (Internship, SearchJob, Training, RealEstate, etc.)
    final nature = demande['nature']?.toString() ?? 'Demande';
    final categoryLabel = _getNatureLabel(nature);

    // Location
    final nationwideRaw = demande['nationwide'];
    final nationwide =
        nationwideRaw == true ||
        nationwideRaw == 1 ||
        nationwideRaw?.toString() == '1' ||
        nationwideRaw?.toString().toLowerCase() == 'true';
    final locationRaw =
        demande['location']?.toString() ?? demande['city']?.toString() ?? '';
    final location = nationwide
        ? 'Toute la France'
        : (locationRaw.isNotEmpty ? locationRaw : 'Non spécifié');

    // Media
    final postImage = _extractMediaUrl(demande);

    final demandeId = demande['id']?.toString() ?? '';

    // Check if already favorited by current user
    final favoris = demande['demande_favorites'] as List? ?? [];
    final currentUserId = UserSession().id;
    final bool initialIsFavorited =
        currentUserId != null &&
        favoris.any(
          (f) =>
              f is Map &&
              (f['user_id']?.toString() == currentUserId ||
                  f['user']?['id']?.toString() == currentUserId),
        );

    // Use ValueNotifier for state that persists across rebuilds
    final isFavoritedNotifier = ValueNotifier<bool>(initialIsFavorited);

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoadingFavorite = false;

        Future<void> toggleFavorite() async {
          if (isLoadingFavorite || demandeId.isEmpty) return;

          // Toggle immediately for responsive UI
          isFavoritedNotifier.value = !isFavoritedNotifier.value;
          setState(() => isLoadingFavorite = true);

          try {
            if (!isFavoritedNotifier.value) {
              // Remove from favorites
              await ApiClient().authenticatedDelete(
                '/demandes/$demandeId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              if (demande['demande_favorites'] is List) {
                (demande['demande_favorites'] as List).removeWhere(
                  (f) =>
                      f is Map &&
                      (f['user_id']?.toString() == currentUserId ||
                          f['user']?['id']?.toString() == currentUserId),
                );
              }
            } else {
              // Add to favorites
              await ApiClient().authenticatedPost(
                '/demandes/$demandeId/favorite',
              );
              // Update underlying data to persist state across rebuilds
              if (demande['demande_favorites'] is! List) {
                demande['demande_favorites'] = [];
              }
              (demande['demande_favorites'] as List).add({
                'user_id': currentUserId,
                'user': {'id': currentUserId},
              });
            }

            setState(() {
              isLoadingFavorite = false;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavoritedNotifier.value
                        ? 'Ajouté aux favoris'
                        : 'Retiré des favoris',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            debugPrint('Favorite toggle error: $e');
            // Revert on error
            isFavoritedNotifier.value = !isFavoritedNotifier.value;
            setState(() => isLoadingFavorite = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        return DemandeCard(
          profileImage: profileImage,
          username: username,
          categoryLabel: categoryLabel,
          accountType: proProfile != null && proProfile!.isNotEmpty
              ? 'pro'
              : 'particulier',
          categoryColor: _categoryColor(categoryLabel),
          title: title,
          description: description.isNotEmpty
              ? description
              : 'Description non disponible.',
          location: location,
          postImage: postImage,
          likesCount: _asInt(demande['likes_count']),
          commentsCount: _asInt(demande['comments_count']),
          timeAgo: _buildTimeAgo(demande['created_at']?.toString()),
          onTapCTA: () => _navigateToDemandeDetail(demande),
          onAvatarTap: () {
            if (user?['id'] != null) {
              final isProUser =
                  user?['account_type']?.toString().toLowerCase() == 'pro';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isProUser
                      ? ProPublicViewScreen(userId: user!['id'].toString())
                      : ParticulierPublicViewScreen(
                          userId: user!['id'].toString(),
                        ),
                ),
              );
            }
          },
          isFavorited: isFavoritedNotifier.value,
          isLoadingFavorite: isLoadingFavorite,
          onFavoriteToggle: toggleFavorite,
          reactionBar: demandeId.isNotEmpty
              ? Builder(
                  builder: (ctx) {
                    _seedReaction('demandes', demandeId, demande);
                    return _buildReactionBar(
                      'demandes',
                      demandeId,
                      acceptedMessages: demande['accept_messages'] == true,
                      authorData: demande['user'],
                    );
                  },
                )
              : null,
        );
      },
    );
  }
}
