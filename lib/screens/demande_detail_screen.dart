import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_demande_screen.dart';

class DemandeDetailScreen extends StatelessWidget {
  final List<String> images;
  final String avatar;
  final String username;
  final String userType;
  final String demandeTitle;
  final String description;
  final List<PostTag> tags;
  final String timeAgo;
  // Demande-specific fields
  final String? nature;
  final String? type;
  final bool urgent;
  final String? budgetMax;
  final String? location;
  final bool nationwide;
  final int? searchRadiusKm;
  final bool showGoogleLocation;
  final bool acceptMessages;
  final bool isOwner;
  final String? demandeId;
  final Map<String, dynamic>? demandeData;
  final bool returnToListingOnEdit;

  const DemandeDetailScreen({
    super.key,
    this.images = const [],
    required this.avatar,
    required this.username,
    this.userType = 'Demande',
    required this.demandeTitle,
    required this.description,
    this.tags = const [],
    this.timeAgo = '',
    this.nature,
    this.type,
    this.urgent = false,
    this.budgetMax,
    this.location,
    this.nationwide = false,
    this.searchRadiusKm,
    this.showGoogleLocation = false,
    this.acceptMessages = false,
    this.isOwner = false,
    this.demandeId,
    this.demandeData,
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
          'Details Demande',
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
                  if (demandeId != null && demandeData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreerDemandeScreen(
                          demandeId: demandeId,
                          initialData: demandeData,
                          shouldReturnToListingOnSuccess: returnToListingOnEdit,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Impossible de modifier cette demande')),
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
            ImageCarousel(
              images: images.isNotEmpty
                  ? images
                  : const ['assets/images/default_event.png'],
            ),
            const SizedBox(height: 16),

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
              title: demandeTitle,
              time: timeAgo,
              onLike: () {},
              onShare: () {},
            ),
            const SizedBox(height: 16),

            // 4. Urgent badge
            if (urgent)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Demande urgente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            if (urgent) const SizedBox(height: 16),

            // 5. Description Section
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
                        'Description de la demande',
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
                  Text(
                    description.isNotEmpty
                        ? description
                        : 'Aucune description fournie.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 6. Details Section (Nature, Type, Budget, Radius)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt_outlined, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Informations',
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
                  if (nature != null && nature!.isNotEmpty)
                    _buildInfoRow(Icons.category_outlined, 'Catégorie', nature!),
                  if (type != null && type!.isNotEmpty)
                    _buildInfoRow(Icons.label_outline, 'Type', type!),
                  if (budgetMax != null && budgetMax!.isNotEmpty)
                    _buildInfoRow(Icons.euro, 'Budget max', '$budgetMax €'),
                  if (searchRadiusKm != null && searchRadiusKm! > 0)
                    _buildInfoRow(
                      Icons.radar_outlined,
                      'Rayon de recherche',
                      '$searchRadiusKm km',
                    ),
                  if (acceptMessages)
                    _buildInfoRow(
                      Icons.message_outlined,
                      'Messages',
                      'Accepte les messages',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 7. "Répondre à la demande" button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
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
            ),
            const SizedBox(height: 16),

            // 8. Localisation Card
            if (_hasLocation())
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
                          color: Color(0xFFFF9800),
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
                    if (showGoogleLocation)
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
                    if (showGoogleLocation) const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 16, color: Color(0xFFFF9800)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nationwide
                                ? 'Toute la France'
                                : (location ?? 'Non spécifié'),
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

            // 9. Commentaires Section
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

            // 10. Similar demandes header
            const Center(
              child: Text(
                'Demandes similaires',
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

  void _showDeleteDialog(BuildContext context) {
    if (demandeId == null) {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Supprimer la demande',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette demande ? Cette action est irréversible.',
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
                            Uri.parse('${ApiConfig.baseUrl}/demandes/$demandeId'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 && response.statusCode < 300) {
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF9800)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasLocation() {
    return nationwide || (location != null && location!.isNotEmpty);
  }
}
