import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/chat_conversation_screen.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/services/conversation_service.dart';
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

  // Candidatures data
  List<dynamic> _candidatures = [];
  bool _isLoadingCandidatures = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadCandidatures();
  }

  Future<void> _loadCandidatures() async {
    setState(() => _isLoadingCandidatures = true);
    
    List<dynamic> allCandidatures = [];
    
    // Fetch training subscriptions independently
    try {
      debugPrint('Fetching training subscriptions...');
      final trainingResponse = await ApiClient().authenticatedGet('/trainings/my-subscriptions');
      debugPrint('Training response: $trainingResponse');
      if (trainingResponse['success'] == true) {
        final trainings = trainingResponse['data'] as List<dynamic>? ?? [];
        debugPrint('Found ${trainings.length} training subscriptions');
        allCandidatures.addAll(trainings);
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading training subscriptions: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    // Fetch event participations independently
    try {
      debugPrint('Fetching event participations...');
      final eventResponse = await ApiClient().authenticatedGet('/events/my-participations');
      debugPrint('Event response: $eventResponse');
      if (eventResponse['success'] == true) {
        final events = eventResponse['data'] as List<dynamic>? ?? [];
        debugPrint('Found ${events.length} event participations');
        allCandidatures.addAll(events);
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading event participations: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    // Sort by date
    allCandidatures.sort((a, b) {
      final dateA = a['subscribed_at'] ?? a['participated_at'] ?? '';
      final dateB = b['subscribed_at'] ?? b['participated_at'] ?? '';
      return dateB.toString().compareTo(dateA.toString());
    });

    debugPrint('Total candidatures: ${allCandidatures.length}');
    setState(() {
      _candidatures = allCandidatures;
      _isLoadingCandidatures = false;
    });
  }

  Future<void> _startChatWithOwner(int ownerId) async {
    if (ownerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer la conversation')),
      );
      return;
    }

    try {
      final conversation = await ConversationService().getOrCreateConversation(ownerId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              conversationId: conversation.id.toString(),
              name: conversation.otherUserName ?? 'Utilisateur',
              avatar: conversation.otherUserAvatar,
              status: 'En ligne',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadDocuments(), _loadCandidatures()]);
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

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Try to request storage permission (permission_handler handles Android version differences)
    // On Android 13+, this will use READ_MEDIA_IMAGES/READ_MEDIA_VIDEO
    // On Android 12 and below, this uses READ_EXTERNAL_STORAGE
    PermissionStatus status = await Permission.storage.status;
    
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    // Handle permission results
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionSettingsDialog();
      }
      return false;
    }

    if (status.isDenied) {
      if (mounted) {
        _showPermissionRationaleDialog();
      }
      return false;
    }

    return true;
  }

  void _showPermissionRationaleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'Pour sélectionner des fichiers, l\'application a besoin d\'accéder à votre stockage. Cette permission est nécessaire pour uploader votre CV, lettre de motivation ou portfolio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestStoragePermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAE5E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accorder la permission'),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission bloquée'),
        content: const Text(
          'La permission de stockage a été refusée définitivement. Pour sélectionner des fichiers, veuillez accorder la permission dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3AAE5E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadDocument(String type) async {
    try {
      // Request permission with proper handling
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        // User denied permission - show explanation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de stockage nécessaire pour sélectionner des fichiers'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

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
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFFFF9800),
          child: _isLoadingDocuments
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9800)))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
    if (_isLoadingCandidatures) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFFF9800))),
      );
    }

    // Filter candidatures based on selected filter
    final filteredCandidatures = _candidatures.where((c) {
      if (_selectedCandidatureFilter == 'Tout') return true;
      if (_selectedCandidatureFilter == 'Emploi') return c['type'] == 'emploi';
      if (_selectedCandidatureFilter == 'Formations') return c['type'] == 'formation';
      if (_selectedCandidatureFilter == 'Événements') return c['type'] == 'evenement';
      return true;
    }).toList();

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
                'Total : ${filteredCandidatures.length} Candidature(s) envoyée(s)',
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
              const SizedBox(width: 6),
              _buildFilterChip('Formations'),
              const SizedBox(width: 6),
              _buildFilterChip('Événements'),
            ],
          ),
          const SizedBox(height: 20),

          // Candidature cards
          if (filteredCandidatures.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aucune candidature',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...filteredCandidatures.map((candidature) {
              final type = candidature['type'] as String;
              final title = candidature['title'] as String? ?? 'Sans titre';
              final status = candidature['status'] as String? ?? 'pending';
              final owner = candidature['owner'] as Map<String, dynamic>?;
              final ownerName = owner?['name'] as String? ?? 'Utilisateur';
              final date = candidature['subscribed_at'] ?? candidature['participated_at'] ?? '';

              String displayType;
              IconData typeIcon;
              if (type == 'formation') {
                displayType = 'Formation';
                typeIcon = Icons.school_outlined;
              } else if (type == 'evenement') {
                displayType = 'Événement';
                typeIcon = Icons.event_outlined;
              } else {
                displayType = 'Offre d\'emploi';
                typeIcon = Icons.work_outline;
              }

              String statusText;
              Color statusColor;
              switch (status) {
                case 'confirmed':
                case 'active':
                  statusText = 'Candidature acceptée';
                  statusColor = const Color(0xFF4CAF50);
                  break;
                case 'rejected':
                  statusText = 'Candidature refusée';
                  statusColor = const Color(0xFFE53935);
                  break;
                case 'pending':
                default:
                  statusText = 'Candidature envoyée';
                  statusColor = const Color(0xFFFF9800);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCandidatureCard(
                  title: title,
                  status: statusText,
                  statusColor: statusColor,
                  ownerId: owner?['id'] as int? ?? 0,
                  ownerName: ownerName,
                  ownerAvatarUrl: owner?['avatar_url'] as String?,
                  type: displayType,
                  typeIcon: typeIcon,
                  date: _formatDate(date),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
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
    required Color statusColor,
    required int ownerId,
    required String ownerName,
    String? ownerAvatarUrl,
    required String type,
    required IconData typeIcon,
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
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  image: ownerAvatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(ApiConfig.resolveMediaUrl(ownerAvatarUrl)!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: ownerAvatarUrl == null
                    ? Icon(Icons.person, color: Colors.grey[400], size: 22)
                    : null,
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
                      ownerName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Action icons
              GestureDetector(
                onTap: () => _startChatWithOwner(ownerId),
                child: Container(
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
                  Icon(typeIcon, size: 14, color: Colors.grey[400]),
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
