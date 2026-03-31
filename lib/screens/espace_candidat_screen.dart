import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/config/api_config.dart';

class EspaceCandidatScreen extends StatefulWidget {
  const EspaceCandidatScreen({super.key});

  @override
  State<EspaceCandidatScreen> createState() => _EspaceCandidatScreenState();
}

class _EspaceCandidatScreenState extends State<EspaceCandidatScreen> {
  bool _showDocuments = true;
  bool _showOnProfile = false;
  String _selectedCandidatureFilter = 'Tout';
  bool _cvVisibility = false;
  bool _lettreVisibility = false;
  bool _portfolioVisibility = false;

  // Documents data
  Map<String, dynamic>? _cvDocument;
  Map<String, dynamic>? _lettreDocument;
  Map<String, dynamic>? _portfolioDocument;
  bool _isLoadingDocuments = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocuments = true);
    try {
      final response = await ApiClient().authenticatedGet('/candidate-documents/settings');
      final data = response['data'];

      if (data != null) {
        setState(() {
          _showOnProfile = data['show_on_profile'] ?? false;
          final documents = data['documents'] as Map<String, dynamic>? ?? {};

          _cvDocument = documents['cv'];
          _lettreDocument = documents['lettre'];
          _portfolioDocument = documents['portfolio'];

          _cvVisibility = _cvDocument?['is_visible'] ?? false;
          _lettreVisibility = _lettreDocument?['is_visible'] ?? false;
          _portfolioVisibility = _portfolioDocument?['is_visible'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission de stockage nécessaire pour sélectionner des fichiers')),
          );
        }
        throw Exception('Storage permission denied');
      }
    }
  }

  Future<void> _pickAndUploadDocument(String type) async {
    try {
      await _requestStoragePermission();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('Chemin de fichier invalide');
      }

      setState(() => _isUploading = true);

      final filePath = file.path!;

      // Use ApiClient to upload with multipart
      final response = await ApiClient().authenticatedPostMultipart(
        '/candidate-documents',
        file: File(filePath),
        fileField: 'file',
        fields: {'type': type},
      );

      if (response['success'] == true) {
        final docData = response['data'];
        setState(() {
          switch (type) {
            case 'cv':
              _cvDocument = docData;
              _cvVisibility = docData['is_visible'] ?? false;
              break;
            case 'lettre':
              _lettreDocument = docData;
              _lettreVisibility = docData['is_visible'] ?? false;
              break;
            case 'portfolio':
              _portfolioDocument = docData;
              _portfolioVisibility = docData['is_visible'] ?? false;
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${type == 'cv' ? 'CV' : type == 'lettre' ? 'Lettre' : 'Portfolio'} ajouté avec succès'),
              backgroundColor: const Color(0xFF3AAE5E),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String type, dynamic docId) async {
    if (docId == null) return;

    try {
      final response = await ApiClient().authenticatedDelete('/candidate-documents/$docId');

      if (response['success'] == true) {
        setState(() {
          switch (type) {
            case 'cv':
              _cvDocument = null;
              _cvVisibility = false;
              break;
            case 'lettre':
              _lettreDocument = null;
              _lettreVisibility = false;
              break;
            case 'portfolio':
              _portfolioDocument = null;
              _portfolioVisibility = false;
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document supprimé avec succès'),
              backgroundColor: Color(0xFF3AAE5E),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDocumentVisibility(String type, dynamic docId, bool isVisible) async {
    if (docId == null) return;

    try {
      final response = await ApiClient().authenticatedPut(
        '/candidate-documents/$docId/visibility',
        body: {'is_visible': isVisible},
      );

      if (response['success'] == true) {
        setState(() {
          switch (type) {
            case 'cv':
              _cvVisibility = isVisible;
              if (_cvDocument != null) {
                _cvDocument!['is_visible'] = isVisible;
              }
              break;
            case 'lettre':
              _lettreVisibility = isVisible;
              if (_lettreDocument != null) {
                _lettreDocument!['is_visible'] = isVisible;
              }
              break;
            case 'portfolio':
              _portfolioVisibility = isVisible;
              if (_portfolioDocument != null) {
                _portfolioDocument!['is_visible'] = isVisible;
              }
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating visibility: $e');
    }
  }

  Future<void> _updateGlobalVisibility(bool showOnProfile) async {
    try {
      final response = await ApiClient().authenticatedPost(
        '/candidate-documents/visibility',
        body: {'show_on_profile': showOnProfile},
      );

      if (response['success'] == true) {
        setState(() {
          _showOnProfile = showOnProfile;
          _cvVisibility = showOnProfile;
          _lettreVisibility = showOnProfile;
          _portfolioVisibility = showOnProfile;
        });
      }
    } catch (e) {
      debugPrint('Error updating global visibility: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 4,
      onTabTapped: (index) {
        if (index != 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ParticulierMainScreen(initialIndex: index),
            ),
          );
        }
      },
      body: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF616161),
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Espace Candidat',
            style: TextStyle(
              color: Color(0xFF2D2D2D),
              fontFamily: 'Manjari',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoadingDocuments
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[400], size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Faire une recherche',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tab toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showDocuments = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _showDocuments
                                        ? const Color(0xFFFF9800)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                        color: _showDocuments
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Mes documents',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _showDocuments
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showDocuments = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_showDocuments
                                        ? const Color(0xFFFF9800)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.volume_up_outlined,
                                        size: 16,
                                        color: !_showDocuments
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Mes Candidatures',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: !_showDocuments
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_showDocuments) _buildDocumentsTab(),
                    if (!_showDocuments) _buildCandidaturesTab(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show on profile toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tout afficher sur le profil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.7,
                    child: SizedBox(
                      height: 24,
                      child: Switch(
                        value: _showOnProfile,
                        onChanged: (val) => _updateGlobalVisibility(val),
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFFFF9800),
                        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showOnProfile
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Activer ou désactiver la visibilité de ce document',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),

          const SizedBox(height: 20),

          // CV Section
          _buildDocumentSection(
            title: 'Votre CV',
            status: _cvDocument != null ? _cvDocument!['original_name'] ?? 'CV ajouté' : 'Aucun document',
            buttonLabel: _cvDocument != null ? 'Remplacer le CV' : 'Ajouter votre CV',
            buttonIcon: Icons.upload_file_outlined,
            visibilityValue: _cvVisibility,
            onVisibilityChanged: (val) => _updateDocumentVisibility('cv', _cvDocument?['id'], val),
            document: _cvDocument,
            onUpload: () => _pickAndUploadDocument('cv'),
            onDelete: () => _deleteDocument('cv', _cvDocument?['id']),
          ),

          const SizedBox(height: 20),

          // Lettre de motivation Section
          _buildDocumentSection(
            title: 'Lettre de motivation',
            status: _lettreDocument != null ? _lettreDocument!['original_name'] ?? 'Lettre ajoutée' : 'Aucun document',
            buttonLabel: _lettreDocument != null ? 'Remplacer la lettre' : 'Ajouter une lettre de motivation',
            buttonIcon: Icons.upload_file_outlined,
            visibilityValue: _lettreVisibility,
            onVisibilityChanged: (val) => _updateDocumentVisibility('lettre', _lettreDocument?['id'], val),
            document: _lettreDocument,
            onUpload: () => _pickAndUploadDocument('lettre'),
            onDelete: () => _deleteDocument('lettre', _lettreDocument?['id']),
          ),

          const SizedBox(height: 20),

          // Portfolio Section
          _buildDocumentSection(
            title: 'Portfolio',
            status: _portfolioDocument != null ? _portfolioDocument!['original_name'] ?? 'Portfolio ajouté' : 'Aucun document',
            buttonLabel: _portfolioDocument != null ? 'Remplacer le portfolio' : 'Ajouter un document ou lien',
            buttonIcon: Icons.upload_file_outlined,
            visibilityValue: _portfolioVisibility,
            onVisibilityChanged: (val) => _updateDocumentVisibility('portfolio', _portfolioDocument?['id'], val),
            document: _portfolioDocument,
            onUpload: () => _pickAndUploadDocument('portfolio'),
            onDelete: () => _deleteDocument('portfolio', _portfolioDocument?['id']),
          ),

          if (_isUploading) ...[
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF9800)),
                  SizedBox(height: 8),
                  Text('Upload en cours...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required String status,
    required String buttonLabel,
    required IconData buttonIcon,
    required bool visibilityValue,
    required ValueChanged<bool> onVisibilityChanged,
    Map<String, dynamic>? document,
    VoidCallback? onUpload,
    VoidCallback? onDelete,
  }) {
    final hasDocument = document != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activer ou désactiver la visibilité de ce document',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            Transform.scale(
              scale: 0.7,
              child: SizedBox(
                height: 24,
                child: Switch(
                  value: visibilityValue,
                  onChanged: onVisibilityChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFFF9800),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey[300],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasDocument ? const Color(0xFF3AAE5E) : Colors.grey[400],
                        fontWeight: hasDocument ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasDocument && onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : onUpload,
            icon: Icon(buttonIcon, size: 16),
            label: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3AAE5E),
              side: const BorderSide(color: Color(0xFF3AAE5E), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCandidaturesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total count
          Row(
            children: [
              Icon(Icons.list_alt, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Total : 2 Candidature(s) envoyé(es)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category label
          Text(
            'Sélectionner la catégorie',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          Row(
            children: [
              _buildFilterChip('Tout'),
              const SizedBox(width: 8),
              _buildFilterChip('Emploi'),
              const SizedBox(width: 8),
              _buildFilterChip('Formations'),
            ],
          ),
          const SizedBox(height: 20),

          // Candidature cards
          _buildCandidatureCard(
            title: 'Operateur téléphonique',
            status: 'Candidature envoyée',
            description:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
            type: 'Offre d\'emploi',
            date: '11 novembre 2025',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedCandidatureFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCandidatureFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9800) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF9800) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidatureCard({
    required String title,
    required String status,
    required String description,
    required String type,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.grey[400], size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Action icons
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey[200]),
          const SizedBox(height: 12),

          // Footer
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    type,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Voir les détails',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
