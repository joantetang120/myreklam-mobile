import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/token_storage.dart';
import 'package:myreklam/widgets/image_carousel.dart';
import 'package:myreklam/widgets/pro_post_card.dart';
import 'package:myreklam/widgets/user_detail_card.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/creer_bon_plan_screen.dart';

class ProPostDetailScreen extends StatelessWidget {
  final List<String> images;
  final String? discount;
  final String avatar;
  final String name;
  final String userType;
  final String title;
  final String description;
  final dynamic descriptionDelta;
  final List<PostTag> tags;
  final String time;
  final String? price;
  final String? originalPrice;
  final String availability;
  final String validityType;
  final String? validFrom;
  final String? validUntil;
  final String deliveryInfo;
  final String? location;
  final String? link;
  final bool isOwner;
  final String? bonPlanId;
  final Map<String, dynamic>? bonPlanData;

  const ProPostDetailScreen({
    super.key,
    this.images = const [
      'assets/images/details_bon_plans/Rectangle 35.png',
    ],
    this.discount,
    required this.avatar,
    required this.name,
    required this.userType,
    required this.title,
    this.description = '',
    this.descriptionDelta,
    this.tags = const [],
    this.time = '',
    this.price,
    this.originalPrice,
    this.availability = 'Non spécifié',
    this.validityType = 'Offre permanente',
    this.validFrom,
    this.validUntil,
    this.deliveryInfo = 'Non spécifié',
    this.location,
    this.link,
    this.isOwner = false,
    this.bonPlanId,
    this.bonPlanData,
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
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios,
                size: 18,
                color: Color(0xFF616161),
              ),
            ),
          ),
        ),
        title: const Text(
          'Details Bons Plans',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isOwner)
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
                    if (bonPlanId != null && bonPlanData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreerBonPlanScreen(
                            bonPlanId: bonPlanId,
                            initialData: bonPlanData,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Impossible de modifier ce bon plan')),
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
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications activées')),
                  );
                },
                child: Container(
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
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageCarousel(images: images, discount: discount),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: UserDetailCard(
                avatar: avatar,
                name: name,
                userType: userType,
                onSubscribe: () {},
              ),
            ),
            const SizedBox(height: 16),
            PostContentCard(
              tags: tags.isEmpty
                  ? [
                      PostTag(
                        title: 'High-Tech',
                        icon: Icons.local_offer_outlined,
                        color: Colors.orange,
                      ),
                      PostTag(
                        title: 'Photographie',
                        icon: Icons.grid_view_outlined,
                        color: Colors.grey,
                      ),
                      PostTag(
                        title: 'Bons plans',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                    ]
                  : tags,
              title: title,
              time: time,
              onLike: () {},
              onShare: () {},
            ),
            const SizedBox(height: 16),
            // Offer Details Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Details du bons plans',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),

                  // 2x2 Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridItem(
                          icon: Icons.euro_symbol,
                          iconColor: Colors.orange,
                          bgColor: Colors.orange.withOpacity(0.1),
                          label: 'Prix',
                          value: price ?? 'Gratuit',
                          originalValue: originalPrice,
                        ),
                      ),
                      Expanded(
                        child: _buildGridItem(
                          icon: Icons.public,
                          iconColor: const Color(0xFF3AAE5E),
                          bgColor: const Color(0xFFE6F7EF),
                          label: 'Disponibilité',
                          value: availability,
                          prefixValue: 'Chez ',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGridItem(
                          icon: Icons.calendar_month_outlined,
                          iconColor: Colors.lightBlue,
                          bgColor: Colors.lightBlue.withOpacity(0.1),
                          label: 'Validité',
                          value: _formatValidity(),
                        ),
                      ),
                      Expanded(
                        child: _buildGridItem(
                          icon: Icons.directions_bike,
                          iconColor: Colors.purpleAccent,
                          bgColor: Colors.purpleAccent.withOpacity(0.05),
                          label: 'Livraison',
                          value: deliveryInfo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Primary CTA
                  if (link != null && link!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(link!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Voir le bon plan'),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),
                  _buildDescription(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Localisation Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
              ),
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
                  if (location != null && location!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/details_bon_plans/Rectangle 128 (1).png',
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      location!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Text(
                      'Localisation non spécifiée',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Comments Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Commentaires',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // No comments message
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '0 commentaires',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                "Autres bons plans qui pourraient vous intéresser",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF616161),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ), // space on sides
              child: Container(
                height: 1, // thin line
                color: Colors.grey[300], // light gray
              ),
            ),

            ProPostCard(
              profileImage:
                  'assets/images/dashboard_particulier/Ellipse 10.png',
              username: 'Marvin McKinney',
              userType: 'Particulier',
              postText:
                  "Porsche : légendaire, luxueuse, sportive. Performances brutes et design iconique. Un rêve de vitesse....plus",
              postImage:
                  'assets/images/dashboard_particulier/Rectangle 12 (4).png',
              reductionPercentage: '-10%',
              categoryIcon: Icons.account_balance_outlined,
              categoryName: 'Finances & Assurances',
              merchantName: 'Go Pro',
              timeAgo: 'il y a 3 semaine',
              onTapCTA: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProPostDetailScreen(
                      avatar:
                          'assets/images/dashboard_particulier/Ellipse 10.png',
                      name: 'Floyd Miles',
                      userType: 'Particulier',
                      title: 'Porsche : légendaire, luxueuse, sportive',
                    ),
                  ),
                );
              },
              price: '50.000€',
              likesCount: 125,
              commentsCount: 0,
            ),
            ProPostCard(
              profileImage:
                  'assets/images/dashboard_particulier/Ellipse 12.png',
              username: 'Marvin McKinney',
              userType: 'Particulier',
              postText:
                  "Porsche : légendaire, luxueuse, sportive. Performances brutes et design iconique. Un rêve de vitesse....plus",
              postImage:
                  'assets/images/dashboard_particulier/Rectangle 12 (4).png',
              reductionPercentage: '-10%',
              categoryIcon: Icons.account_balance_outlined,
              categoryName: 'Finances & Assurances',
              merchantName: 'Go Pro',
              timeAgo: 'il y a 3 semaine',
              onTapCTA: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProPostDetailScreen(
                      avatar:
                          'assets/images/dashboard_particulier/Ellipse 10.png',
                      name: 'Floyd Miles',
                      userType: 'Particulier',
                      title: 'Bon plan automobile',
                    ),
                  ),
                );
              },
              price: '50.000€',
              likesCount: 125,
              commentsCount: 0,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatValidity() {
    if (validityType == 'permanent') {
      return 'Offre permanente';
    } else if (validityType == 'dates' && validFrom != null && validUntil != null) {
      try {
        final from = DateTime.parse(validFrom!);
        final until = DateTime.parse(validUntil!);
        return 'Du ${from.day}/${from.month}/${from.year} au ${until.day}/${until.month}/${until.year}';
      } catch (_) {
        return 'Dates spécifiées';
      }
    }
    return 'Offre permanente';
  }

  Widget _buildDescription() {
    // If we have rich text delta, render it with Quill
    if (descriptionDelta != null && descriptionDelta.toString().isNotEmpty) {
      try {
        List opsList;

        if (descriptionDelta is List) {
          // Already a List<dynamic> of Dart maps — use directly
          opsList = descriptionDelta as List;
        } else if (descriptionDelta is Map && (descriptionDelta as Map)['ops'] is List) {
          opsList = (descriptionDelta as Map)['ops'] as List;
        } else if (descriptionDelta is String) {
          String jsonString = descriptionDelta as String;

          // Handle unquoted keys
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

          dynamic rawData = jsonDecode(jsonString);
          if (rawData is String) rawData = jsonDecode(rawData);

          if (rawData is List) {
            opsList = rawData;
          } else if (rawData is Map && rawData['ops'] is List) {
            opsList = rawData['ops'] as List;
          } else {
            throw Exception('Unknown delta format');
          }
        } else {
          throw Exception('Unsupported descriptionDelta type: ${descriptionDelta.runtimeType}');
        }

        // Filter out operations with null insert values
        final filteredOps = opsList
            .where((op) => op is Map && op['insert'] != null)
            .map((op) => Map<String, dynamic>.from(op as Map))
            .toList();
        
        if (filteredOps.isEmpty) throw Exception('No valid ops');

        // Ensure last op ends with newline (Quill requirement)
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
        // Fall back to plain text if parsing fails
        debugPrint('Error rendering rich text: $e');
      }
    }

    // Fallback to plain text
    return Text(
      description.isNotEmpty ? description : 'Aucune description disponible.',
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[600],
        height: 1.5,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    if (bonPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer ce bon plan')),
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
              'Supprimer le bon plan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer ce bon plan ? Cette action est irréversible.',
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
                            Uri.parse('${ApiConfig.baseUrl}/bonplans/$bonPlanId'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 && response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bon plan supprimé avec succès'),
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

  Widget _buildGridItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    String? originalValue,
    String? prefixValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  children: [
                    if (prefixValue != null)
                      TextSpan(
                        text: prefixValue,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[500],
                        ),
                      ),
                    TextSpan(
                      text: value,
                      style: label == 'Prix'
                          ? const TextStyle(color: Colors.orange)
                          : null,
                    ),
                    if (originalValue != null)
                      TextSpan(
                        text: ' $originalValue',
                        style: TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
