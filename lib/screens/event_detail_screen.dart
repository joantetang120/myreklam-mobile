import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_evenement_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final List<String> images;
  final String avatar;
  final String username;
  final String userType;
  final String eventTitle;
  final String description;
  final dynamic descriptionDelta;
  final List<PostTag> tags;
  final String timeAgo;
  // Event-specific fields
  final String? categoryCode;
  final String? subCategoryCode;
  final String? formatType;
  final String? durationType;
  final String? eventDate;
  final String? startDate;
  final String? endDate;
  final String? startTime;
  final String? endTime;
  final String? priceType;
  final String? pricingMode;
  final String? priceAmount;
  final List<Map<String, dynamic>> priceCategories;
  final String? reservationMode;
  final String? coverageArea;
  final bool isNationwide;
  final String? organizerName;
  final bool isOrganizer;
  final String? websiteUrl;
  final String? landingUrl;
  final bool acceptMessages;
  final bool isOwner;
  final String? eventId;
  final Map<String, dynamic>? eventData;
  final bool returnToListingOnEdit;

  const EventDetailScreen({
    super.key,
    this.images = const [],
    required this.avatar,
    required this.username,
    this.userType = 'Évènement',
    required this.eventTitle,
    required this.description,
    this.descriptionDelta,
    this.tags = const [],
    this.timeAgo = '',
    this.categoryCode,
    this.subCategoryCode,
    this.formatType,
    this.durationType,
    this.eventDate,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.priceType,
    this.pricingMode,
    this.priceAmount,
    this.priceCategories = const [],
    this.reservationMode,
    this.coverageArea,
    this.isNationwide = false,
    this.organizerName,
    this.isOrganizer = true,
    this.websiteUrl,
    this.landingUrl,
    this.acceptMessages = false,
    this.isOwner = false,
    this.eventId,
    this.eventData,
    this.returnToListingOnEdit = false,
  });

  @override
  Widget build(BuildContext context) {
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
          'Details Évènements',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF616161)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF616161)),
            onPressed: () {},
          ),
          if (isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF616161), size: 24),
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreerEvenementScreen(
                        eventId: eventId,
                        initialData: eventData,
                        shouldReturnToListingOnSuccess: returnToListingOnEdit,
                      ),
                    ),
                  );
                } else if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20, color: Color(0xFF616161)),
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
            )
          else
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
                child: const Icon(Icons.notifications, color: Color(0xFF2A8143), size: 18),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Carousel
            if (images.isNotEmpty) ...[
              ImageCarousel(images: images),
              const SizedBox(height: 16),
            ],

            // 2. User Detail Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: UserDetailCard(
                avatar: avatar,
                name: username,
                userType: userType,
                onSubscribe: () {},
              ),
            ),
            const SizedBox(height: 16),

            // 3. Post Content Card (Tags & Title)
            PostContentCard(
              tags: tags,
              title: eventTitle,
              time: timeAgo,
              onLike: () {},
              onShare: () {},
            ),
            const SizedBox(height: 16),

            // 4. "À propos de cet événement" - Description Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'À propos de cet événement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDescription(),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 5. Info icons row (Date, Reservation, etc.)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconInfo(Icons.event_outlined, 'Date'),
                      _buildIconInfo(Icons.phone_outlined, 'Contacter'),
                      _buildIconInfo(Icons.bookmark_border, 'Favoris'),
                      _buildIconInfo(Icons.confirmation_num_outlined, 'Reservation'),
                      _buildIconInfo(Icons.notifications_outlined, 'Alertes'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 6. Date Section
            if (_hasDateInfo())
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF3AAE5E), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _buildDateDisplay(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (reservationMode != null && reservationMode!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_num_outlined,
                                size: 16, color: Color(0xFFFF9800)),
                            const SizedBox(width: 6),
                            Text(
                              'Réservation: ${_reservationLabel(reservationMode)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // 7. Horaires Section
            if (startTime != null || endTime != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Color(0xFF3AAE5E), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Horaires',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _buildTimeDisplay(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // 8. "Participer à l'événement?"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Participer à l\'événement?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 9. Price Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.euro_outlined, color: Color(0xFF3AAE5E), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tarification',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (priceType == 'gratuit')
                    const Text(
                      'Gratuit',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3AAE5E),
                      ),
                    )
                  else if (pricingMode == 'categories' && priceCategories.isNotEmpty) ...[
                    ...priceCategories.map((cat) {
                      final name = cat['name']?.toString() ?? '-';
                      final price = cat['price'];
                      final priceStr = price != null
                          ? '${price.toString().replaceAll(RegExp(r'\.0+$'), '')} €'
                          : '-';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3AAE5E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              priceStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3AAE5E),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    Text(
                      _buildPriceDisplay(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3AAE5E),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 10. "Je participe" button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final url = websiteUrl ?? landingUrl;
                    if (url != null && url.isNotEmpty) {
                      _launchUrl(url);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AAE5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Je participe'),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 11. Localisation Card
            if (coverageArea != null && coverageArea!.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF3AAE5E),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Localisation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/details_bon_plans/Rectangle 128 (1).png',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.map, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Color(0xFF3AAE5E)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isNationwide
                                ? 'Toute la France'
                                : (coverageArea ?? 'Non spécifié'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF616161),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 12. Commentaires Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined,
                          color: Color(0xFF616161), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Commentaires',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Comment input placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'Laisser votre avis',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // "..." icon
                  const Center(
                    child: Icon(Icons.more_horiz, color: Colors.grey, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Aucun commentaire pour le moment',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 13. Similar events header
            const Center(
              child: Text(
                'Événements similaires',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(height: 1, color: Colors.grey[300]),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (eventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cet événement')),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Supprimer l\'événement',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cet événement ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
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
                            Uri.parse('${ApiConfig.baseUrl}/events/$eventId'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 && response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Événement supprimé avec succès'),
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
                              content: Text('Erreur: ${e.toString().replaceFirst("Exception: ", "")}'),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Supprimer'),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.withOpacity(0.15)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    if (descriptionDelta != null && descriptionDelta.toString().isNotEmpty) {
      try {
        dynamic rawData;
        if (descriptionDelta is List) {
          rawData = descriptionDelta;
        } else if (descriptionDelta is Map) {
          rawData = descriptionDelta;
        } else {
          String jsonString = descriptionDelta.toString();
          jsonString = jsonString.replaceAllMapped(
            RegExp(r'(\{|,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*:'),
            (match) => '${match.group(1)}"${match.group(2)}":',
          );
          jsonString = jsonString.replaceAllMapped(
            RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_\s]*?)(\s*[,\}\]])'),
            (match) {
              final value = match.group(1)!.trim();
              if (value == 'true' || value == 'false' || value == 'null') {
                return ': $value${match.group(2)}';
              }
              return ': "$value"${match.group(2)}';
            },
          );
          rawData = jsonDecode(jsonString);
        }

        List opsList;
        if (rawData is List) {
          opsList = rawData;
        } else if (rawData is Map && rawData['ops'] is List) {
          opsList = rawData['ops'] as List;
        } else {
          throw Exception('Unknown delta format');
        }

        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();

        if (filteredOps.isEmpty) throw Exception('No valid ops');

        final lastInsert = filteredOps.last['insert'];
        if (lastInsert is String && !lastInsert.endsWith('\n')) {
          filteredOps.add({'insert': '\n'});
        }

        final doc = quill.Document.fromJson(filteredOps);
        final controller = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );

        return quill.QuillEditor.basic(
          controller: controller,
          config: quill.QuillEditorConfig(
            padding: EdgeInsets.zero,
            onLaunchUrl: (url) async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        );
      } catch (e) {
        debugPrint('Error rendering rich text in event detail: $e');
      }
    }

    return Text(
      description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF3AAE5E)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  bool _hasDateInfo() {
    return eventDate != null || startDate != null || endDate != null ||
        durationType == 'permanent';
  }

  String _buildDateDisplay() {
    if (durationType == 'permanent') return 'Permanent';
    if (durationType == 'one_day' && eventDate != null) {
      return _formatDate(eventDate!);
    }
    if (durationType == 'multi_day') {
      final start = startDate != null ? _formatDate(startDate!) : '';
      final end = endDate != null ? _formatDate(endDate!) : '';
      if (start.isNotEmpty && end.isNotEmpty) {
        return 'Du $start au $end';
      }
      if (start.isNotEmpty) return 'À partir du $start';
      if (end.isNotEmpty) return "Jusqu'au $end";
    }
    if (eventDate != null) return _formatDate(eventDate!);
    if (startDate != null) return 'À partir du ${_formatDate(startDate!)}';
    return 'Date non spécifiée';
  }

  String _buildTimeDisplay() {
    final parts = <String>[];
    if (startTime != null && startTime!.isNotEmpty) {
      parts.add('De ${_formatTime(startTime!)}');
    }
    if (endTime != null && endTime!.isNotEmpty) {
      parts.add('à ${_formatTime(endTime!)}');
    }
    return parts.isNotEmpty ? parts.join(' ') : 'Horaires non spécifiés';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    // Handle "HH:MM:SS" or "HH:MM"
    final parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}h${parts[1]}';
    return timeStr;
  }

  String _buildPriceDisplay() {
    if (priceType == 'gratuit') return 'Gratuit';
    if (priceAmount != null && priceAmount!.isNotEmpty) {
      return '${priceAmount} €';
    }
    return 'Gratuit';
  }

  String _reservationLabel(String? mode) {
    switch (mode) {
      case 'sans_inscription': return 'Sans inscription';
      case 'inscription': return 'Inscription requise';
      case 'achat_billet': return 'Achat de billet obligatoire';
      default: return mode ?? '';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
