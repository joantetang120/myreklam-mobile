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
import 'package:myreklam/widgets/formation_card.dart';
import 'package:myreklam/screens/creer_formation_screen.dart';

class TrainingDetailScreen extends StatelessWidget {
  final List<String> images;
  final String companyLogo;
  final String companyName;
  final String trainingTitle;
  final String description;
  final dynamic descriptionDelta;
  final List<FormationTag> tags;
  final String timeAgo;
  // Training-specific fields
  final String? website;
  final String? trainingType;
  final String? trainingCategory;
  final String? trainingSubCategory;
  final List<String> trainingStyle;
  final List<String> trainingPublic;
  final List<String> requiredLevels;
  final String? price;
  final String? priceType;
  final String? publicType;
  final String? tempo;
  final List<String> trainingFunding;
  final int? durationInH;
  final String? durationUnit;
  final String? startDate;
  final String? endDate;
  final bool dateToDefine;
  final String? addressCity;
  final String? addressZipcode;
  final String? addressLine1;
  final bool showLocation;
  final List<String> certification;
  final bool isOwner;
  final String? trainingId;
  final Map<String, dynamic>? trainingData;
  final bool returnToListingOnEdit;

  const TrainingDetailScreen({
    super.key,
    this.images = const [],
    required this.companyLogo,
    required this.companyName,
    required this.trainingTitle,
    required this.description,
    this.descriptionDelta,
    required this.tags,
    required this.timeAgo,
    this.website,
    this.trainingType,
    this.trainingCategory,
    this.trainingSubCategory,
    this.trainingStyle = const [],
    this.trainingPublic = const [],
    this.requiredLevels = const [],
    this.price,
    this.priceType,
    this.publicType,
    this.tempo,
    this.trainingFunding = const [],
    this.durationInH,
    this.durationUnit,
    this.startDate,
    this.endDate,
    this.dateToDefine = false,
    this.addressCity,
    this.addressZipcode,
    this.addressLine1,
    this.showLocation = false,
    this.certification = const [],
    this.isOwner = false,
    this.trainingId,
    this.trainingData,
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
          'Details Formation',
          style: TextStyle(
            color: Color(0xFF616161),
            fontFamily: 'Manjari',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
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
                      builder: (_) => CreerFormationScreen(
                        trainingId: trainingId,
                        initialData: trainingData,
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
            ImageCarousel(
              images: images.isNotEmpty
                  ? images
                  : const ['assets/images/Formation.png'],
              discount: 'Formation',
            ),
            const SizedBox(height: 16),

            // 2. User Detail Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: UserDetailCard(
                avatar: companyLogo,
                name: companyName,
                userType: 'Pro',
                onSubscribe: () {},
              ),
            ),
            const SizedBox(height: 16),

            // 3. Post Content Card (Title & Info)
            PostContentCard(
              tags: [
                if (trainingCategory != null && trainingCategory!.isNotEmpty)
                  PostTag(
                    title: trainingCategory!,
                    icon: Icons.category_outlined,
                    color: Colors.blue,
                  ),
                if (trainingType != null && trainingType!.isNotEmpty)
                  PostTag(
                    title: _formatEnumLabel(trainingType!),
                    icon: Icons.school_outlined,
                    color: Colors.purple,
                  ),
              ],
              title: trainingTitle,
              time: timeAgo,
              onLike: () {},
              onShare: () {},
            ),

            const SizedBox(height: 16),

            // 4. Description Section (rich text)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined, color: Colors.grey[600], size: 20),
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
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildDescription(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 5. Training Info Section
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
                  if (trainingStyle.isNotEmpty)
                    _buildInfoRow(Icons.laptop_chromebook, 'Type d\'enseignement',
                        trainingStyle.map(_formatEnumLabel).join(', ')),
                  if (trainingStyle.isNotEmpty) const SizedBox(height: 10),
                  if (durationInH != null)
                    _buildInfoRow(Icons.timer_outlined, 'Durée',
                        '$durationInH ${_durationUnitLabel(durationUnit)}'),
                  if (durationInH != null) const SizedBox(height: 10),
                  if (!dateToDefine && (startDate != null || endDate != null))
                    _buildInfoRow(Icons.calendar_today_outlined, 'Dates',
                        _formatDates(startDate, endDate)),
                  if (dateToDefine)
                    _buildInfoRow(Icons.calendar_today_outlined, 'Dates', 'À définir'),
                  if (startDate != null || endDate != null || dateToDefine)
                    const SizedBox(height: 10),
                  if (requiredLevels.isNotEmpty)
                    _buildInfoRow(Icons.school, 'Prérequis', requiredLevels.join(', ')),
                  if (requiredLevels.isNotEmpty) const SizedBox(height: 10),
                  if (trainingPublic.isNotEmpty)
                    _buildInfoRow(Icons.people_outline, 'Public cible',
                        trainingPublic.map(_formatEnumLabel).join(', ')),
                  if (trainingPublic.isNotEmpty) const SizedBox(height: 10),
                  if (certification.isNotEmpty)
                    _buildInfoRow(Icons.verified_outlined, 'Certifications',
                        certification.join(', ')),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 6. Tags
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => _buildTag(tag)).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // 7. Interested / Apply section
            if (website != null && website!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Intéressé par cette formation?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 8. Price section
            if (price != null || priceType != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.euro, color: Color(0xFF3AAE5E), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatPrice(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3AAE5E),
                            ),
                          ),
                          if (trainingFunding.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Financements: ${trainingFunding.map(_formatEnumLabel).join(', ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // 9. Apply button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (website != null && website!.isNotEmpty) {
                      _launchUrl(website!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("S'inscrire maintenant"),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 10. Localisation Card
            if (showLocation && (addressCity != null || addressLine1 != null))
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _buildLocationString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // 11. Comments section (0 comments)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.comment_outlined, color: Color(0xFF616161), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '0 commentaires',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 12. Similar formations header
            const Center(
              child: Text(
                'Autres formations qui pourraient vous intéresser',
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
              child: Container(
                height: 1,
                color: Colors.grey[300],
              ),
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
          // Handle JavaScript object notation
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
        debugPrint('Error rendering rich text in training detail: $e');
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
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
    );
  }

  Widget _buildTag(FormationTag tag) {
    final isSpecial = tag.isSpecial;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSpecial ? const Color(0xFFE6F7EF) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSpecial
              ? const Color(0xFF3AAE5E).withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tag.icon,
            size: 16,
            color: isSpecial ? const Color(0xFF3AAE5E) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            tag.text,
            style: TextStyle(
              fontSize: 12,
              color: isSpecial ? const Color(0xFF3AAE5E) : Colors.grey,
              fontWeight: isSpecial ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatEnumLabel(String value) {
    // Convert PascalCase / camelCase to readable
    return value
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
  }

  void _showDeleteDialog(BuildContext context) {
    if (trainingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer cette formation')),
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
              'Supprimer la formation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette formation ? Cette action est irréversible.',
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
                            Uri.parse('${ApiConfig.baseUrl}/trainings/$trainingId'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Accept': 'application/json',
                            },
                          );
                          if (response.statusCode >= 200 && response.statusCode < 300) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Formation supprimée avec succès'),
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

  String _durationUnitLabel(String? unit) {
    switch (unit) {
      case '0': return 'heures';
      case '1': return 'jours';
      case '2': return 'semaines';
      case '3': return 'mois';
      case '4': return 'années';
      default: return 'heures';
    }
  }

  String _formatDates(String? start, String? end) {
    if (start != null && end != null) return 'Du $start au $end';
    if (start != null) return 'À partir du $start';
    if (end != null) return "Jusqu'au $end";
    return 'À définir';
  }

  String _formatPrice() {
    if (priceType == '4') return 'Gratuit';
    if (priceType == '5') return 'Sur devis';
    if (price != null) {
      final priceLabel = _priceTypeLabel(priceType);
      final tempoLabel = _tempoLabel(tempo);
      final publicLabel = _publicTypeLabel(publicType);
      return '${price} € $priceLabel $publicLabel $tempoLabel'.trim();
    }
    return 'Prix non spécifié';
  }

  String _priceTypeLabel(String? type) {
    switch (type) {
      case '1': return 'NET';
      case '2': return 'HT';
      case '3': return 'TTC';
      default: return '';
    }
  }

  String _tempoLabel(String? t) {
    switch (t) {
      case 'heure': return '/ heure';
      case 'jour': return '/ jour';
      case 'semaine': return '/ semaine';
      case 'mois': return '/ mois';
      case 'an': return '/ an';
      case 'all': return '';
      default: return '';
    }
  }

  String _publicTypeLabel(String? type) {
    switch (type) {
      case 'personne': return '/ personne';
      case 'groupe': return '/ groupe';
      default: return '';
    }
  }

  String _buildLocationString() {
    final parts = <String>[];
    if (addressLine1 != null && addressLine1!.isNotEmpty) parts.add(addressLine1!);
    if (addressZipcode != null && addressZipcode!.isNotEmpty) parts.add(addressZipcode!);
    if (addressCity != null && addressCity!.isNotEmpty) parts.add(addressCity!);
    return parts.isNotEmpty ? parts.join(', ') : 'Localisation non spécifiée';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
