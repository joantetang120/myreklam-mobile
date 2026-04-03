import 'dart:io';
import 'package:dio/dio.dart';
import 'package:myreklam/widgets/job_announcement_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:myreklam/config/api_config.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/screens/creer_offre_emploi_screen.dart';
import 'package:myreklam/screens/profile_pro/pdf_viewer_screen.dart';
import 'package:myreklam/screens/job_detail_screen.dart';
import 'package:myreklam/widgets/post_content_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ProSpaceProScreen extends StatefulWidget {
  const ProSpaceProScreen({super.key});

  @override
  State<ProSpaceProScreen> createState() => _ProSpaceProScreenState();
}

class _ProSpaceProScreenState extends State<ProSpaceProScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'Tout';

  String? _currentUserId;
  bool _isLoadingJobOffers = true;
  String? _jobOffersError;
  List<Map<String, dynamic>> _myJobOffers = [];

  bool _isLoadingEvents = true;
  String? _eventsError;
  List<Map<String, dynamic>> _myEvents = [];

  bool _isLoadingTrainings = true;
  String? _trainingsError;
  List<Map<String, dynamic>> _myTrainings = [];

  bool _isLoadingMyApplications = true;
  String? _myApplicationsError;
  List<Map<String, dynamic>> _myApplications = [];
  int _myApplicationsTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  Future<void> _loadMyApplications() async {
    setState(() {
      _isLoadingMyApplications = true;
      _myApplicationsError = null;
    });
    try {
      final response = await ApiClient().authenticatedGet(
        '/job-offers/my-applications',
      );
      final data = response['data'];

      List<Map<String, dynamic>> items;
      if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        items = List<Map<String, dynamic>>.from(data['data']);
      } else {
        items = [];
      }

      final meta = response['meta'];
      final totalRaw = meta is Map ? meta['total'] : null;
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse(totalRaw?.toString() ?? '') ?? items.length;

      if (!mounted) return;
      setState(() {
        _myApplications = items;
        _myApplicationsTotal = total;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _myApplicationsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _myApplicationsError = 'Erreur de chargement');
    } finally {
      if (mounted) setState(() => _isLoadingMyApplications = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _ensureCurrentUserId();
    await _loadMyJobOffers();
    await _loadMyEvents();
    await _loadMyTrainings();
    await _loadMyApplications();
  }

  Future<String?> _ensureCurrentUserId() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final id = response['user']?['id']?.toString();
      if (!mounted) return id;
      setState(() => _currentUserId = id);
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadMyJobOffers() async {
    setState(() {
      _isLoadingJobOffers = true;
      _jobOffersError = null;
    });
    try {
      final response = await ApiClient().authenticatedGet('/job-offers');
      final data = response['data'];

      List<Map<String, dynamic>> all;
      if (data is List) {
        all = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        all = List<Map<String, dynamic>>.from(data['data']);
      } else {
        all = [];
      }

      final myId = _currentUserId;
      final filtered = myId == null
          ? all
          : all
                .where(
                  (o) =>
                      o['user_id']?.toString() == myId ||
                      (o['user'] is Map &&
                          (o['user']['id']?.toString() == myId)),
                )
                .toList();

      if (!mounted) return;
      setState(() => _myJobOffers = filtered);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _jobOffersError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _jobOffersError = 'Erreur de chargement');
    } finally {
      if (mounted) setState(() => _isLoadingJobOffers = false);
    }
  }

  Future<void> _loadMyEvents() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });
    try {
      final response = await ApiClient().authenticatedGet('/events');
      final data = response['data'];
      debugPrint(
        'Events response: ${response.toString().length > 500 ? response.toString().substring(0, 500) : response.toString()}',
      );

      List<Map<String, dynamic>> all;
      if (data is List) {
        all = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        all = List<Map<String, dynamic>>.from(data['data']);
      } else {
        all = [];
      }

      final myId = _currentUserId;
      final filtered = myId == null
          ? all
          : all
                .where(
                  (o) =>
                      o['user_id']?.toString() == myId ||
                      (o['user'] is Map &&
                          (o['user']['id']?.toString() == myId)),
                )
                .toList();

      debugPrint('Filtered events count: ${filtered.length}');
      if (filtered.isNotEmpty) {
        debugPrint('First event user data: ${filtered.first['user']}');
        debugPrint(
          'First event participations: ${filtered.first['participations'] ?? filtered.first['participants']}',
        );
      }

      if (!mounted) return;
      setState(() => _myEvents = filtered);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _eventsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _eventsError = 'Erreur de chargement');
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _loadMyTrainings() async {
    setState(() {
      _isLoadingTrainings = true;
      _trainingsError = null;
    });
    try {
      final response = await ApiClient().authenticatedGet('/trainings');
      final data = response['data'];

      List<Map<String, dynamic>> all;
      if (data is List) {
        all = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        all = List<Map<String, dynamic>>.from(data['data']);
      } else {
        all = [];
      }

      final myId = _currentUserId;
      final filtered = myId == null
          ? all
          : all
                .where(
                  (o) =>
                      o['user_id']?.toString() == myId ||
                      (o['user'] is Map &&
                          (o['user']['id']?.toString() == myId)),
                )
                .toList();

      if (!mounted) return;
      setState(() => _myTrainings = filtered);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _trainingsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _trainingsError = 'Erreur de chargement');
    } finally {
      if (mounted) setState(() => _isLoadingTrainings = false);
    }
  }

  int _applicationsCountForOffer(Map<String, dynamic> offer) {
    final candidatesRaw =
        offer['applications'] ?? offer['candidatures'] ?? offer['candidates'];
    if (candidatesRaw is List) return candidatesRaw.length;

    final directCount = offer['applications_count'];
    if (directCount is int) return directCount;
    return int.tryParse(directCount?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _applicationsForOffer(Map<String, dynamic> offer) {
    final candidatesRaw = offer['applications'] ?? offer['candidatures'];
    if (candidatesRaw is List) {
      return candidatesRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  int _participantsCountForEvent(Map<String, dynamic> event) {
    final participantsRaw =
        event['participations'] ??
        event['participants'] ??
        event['registrations'];
    if (participantsRaw is List) return participantsRaw.length;

    final directCount =
        event['participants_count'] ?? event['registrations_count'];
    if (directCount is int) return directCount;
    return int.tryParse(directCount?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _participantsForEvent(Map<String, dynamic> event) {
    final participantsRaw =
        event['participations'] ??
        event['participants'] ??
        event['registrations'];
    if (participantsRaw is List) {
      return participantsRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  int _subscribersCountForTraining(Map<String, dynamic> training) {
    final subscribersRaw =
        training['subscriptions'] ??
        training['subscribers'] ??
        training['registrations'];
    if (subscribersRaw is List) return subscribersRaw.length;

    final directCount =
        training['subscriptions_count'] ?? training['registrations_count'];
    if (directCount is int) return directCount;
    return int.tryParse(directCount?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _subscribersForTraining(
    Map<String, dynamic> training,
  ) {
    final subscribersRaw =
        training['subscriptions'] ??
        training['subscribers'] ??
        training['registrations'];
    if (subscribersRaw is List) {
      return subscribersRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  String _extractParticipantName(Map<String, dynamic> participant) {
    final user = participant['user'];
    if (user is Map) {
      final particulierProfile = user['particulier_profile'];
      final proProfile = user['pro_profile'];

      if (particulierProfile is Map) {
        return particulierProfile['pseudo']?.toString() ??
            user['name']?.toString() ??
            user['email']?.toString().split('@').first ??
            'Utilisateur';
      } else if (proProfile is Map) {
        return proProfile['company_name']?.toString() ??
            user['name']?.toString() ??
            user['email']?.toString().split('@').first ??
            'Utilisateur';
      }
      return user['name']?.toString() ??
          user['email']?.toString().split('@').first ??
          'Utilisateur';
    }
    return participant['name']?.toString() ??
        participant['email']?.toString().split('@').first ??
        'Utilisateur';
  }

  String _extractParticipantEmail(Map<String, dynamic> participant) {
    final user = participant['user'];
    if (user is Map) {
      return user['email']?.toString() ??
          participant['email']?.toString() ??
          '';
    }
    return participant['email']?.toString() ?? '';
  }

  String _extractParticipantAvatar(Map<String, dynamic> participant) {
    final user = participant['user'];
    if (user is Map) {
      final particulierProfile = user['particulier_profile'];
      final proProfile = user['pro_profile'];

      if (particulierProfile is Map) {
        return particulierProfile['avatar_url']?.toString() ?? '';
      } else if (proProfile is Map) {
        return proProfile['avatar_url']?.toString() ??
            proProfile['logo_url']?.toString() ??
            '';
      }
      return user['avatar']?.toString() ?? '';
    }
    return participant['avatar']?.toString() ?? '';
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _applicationStatusLabel(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return 'actif';
    return raw;
  }

  String _companyNameForOffer(Map<String, dynamic> offer) {
    final company = offer['company'] ?? offer['company_name'];
    if (company is Map) {
      return (company['name'] ?? company['title'] ?? 'Entreprise').toString();
    }
    final fromUser = offer['user'] is Map
        ? (offer['user']['name'] ?? offer['user']['username'])
        : null;
    return (company ?? fromUser ?? 'Entreprise').toString();
  }

  Future<void> _editJobOffer(Map<String, dynamic> offer) async {
    final id = offer['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Offre invalide")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreerOffreEmploiScreen(jobOfferId: id, initialData: offer),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      await _loadMyJobOffers();
    }
  }

  Future<void> _deleteJobOffer(Map<String, dynamic> offer) async {
    final id = offer['id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Offre invalide")));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'offre'),
        content: const Text('Voulez-vous vraiment supprimer cette offre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiClient().authenticatedDelete('/job-offers/$id');
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offre supprimée')));
      await _loadMyJobOffers();
    } on ApiException catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur de suppression')));
    }
  }

  Future<void> _handleRefresh() async {
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E9B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Espace professionnel',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFFEF8A40),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Faire une recherche',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF8A40).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFEF8A40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Mes offres'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 16),
                            SizedBox(width: 6),
                            Text('Mes Candidatures'),
                          ],
                        ),
                      ),
                    ],
                    onTap: (index) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/profil_pro/space-pro-job.png',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tabController.index == 0
                          ? 'Total : ${_myJobOffers.length} offre(s) publiée(s)'
                          : 'Total : $_myApplicationsTotal Candidature(s) envoyée(s)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Text(
              //     'Sélectionner la catégorie',
              //     style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              //   ),
              // ),
              // const SizedBox(height: 12),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Row(
              //     children: [
              //       _buildCategoryChip('Tout', selectedCategory == 'Tout'),
              //       const SizedBox(width: 8),
              //       _buildCategoryChip('Emploi', selectedCategory == 'Emploi'),
              //       const SizedBox(width: 8),
              //       _buildCategoryChip(
              //         'Formations',
              //         selectedCategory == 'Formations',
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 20),
              if (_tabController.index == 0) ...[
                if (_isLoadingJobOffers)
                  const Center(child: CircularProgressIndicator())
                else if (_jobOffersError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _jobOffersError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadMyJobOffers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF8A40),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else if (_myJobOffers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 40,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune offre d\'emploi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vous n\'avez pas encore publié d\'offre d\'emploi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (int index = 0; index < _myJobOffers.length; index++) ...[
                    Builder(
                      builder: (context) {
                        final offer = _myJobOffers[index];
                        final jobTitle = offer['title']?.toString() ?? '';
                        final description =
                            (offer['description'] ?? offer['summary'] ?? '')
                                .toString();
                        final date = _formatDate(
                          offer['created_at'] ?? offer['published_at'],
                        );
                        final views =
                            int.tryParse(
                              (offer['views'] ??
                                      offer['view_count'] ??
                                      offer['views_count'] ??
                                      0)
                                  .toString(),
                            ) ??
                            0;
                        final appsCount = _applicationsCountForOffer(offer);
                        final companyName = _companyNameForOffer(offer);

                        final avatarRaw =
                            (offer['user']['particulier_profile'] is Map
                            ? offer['user']['particulier_profile']['avatar_url']
                            : offer['user']['pro_profile']['avatar_url']);
                        final avatar = avatarRaw?.toString() ?? '';

                        final applications = _applicationsForOffer(offer);

                        return Column(
                          children: [
                            _buildOffreCard(
                              avatar: avatar,
                              companyName: companyName,
                              isPro: true,
                              jobTitle: jobTitle,
                              description: description,
                              category: "Offre d'emploi",
                              date: date,
                              candidatures: appsCount,
                              views: views,
                              onEdit: () => _editJobOffer(offer),
                              onDelete: () => _deleteJobOffer(offer),
                            ),
                            const SizedBox(height: 12),
                            appsCount > 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 35,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Candidatures ($appsCount)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Tout afficher',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox.shrink(),
                            appsCount > 0
                                ? const SizedBox(height: 12)
                                : SizedBox.shrink(),
                            Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 14,
                                    bottom: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      for (final app in applications.take(3))
                                        _buildCandidatureItem(
                                          userId:
                                              int.tryParse(
                                                app['user']?['id']
                                                        ?.toString() ??
                                                    '0',
                                              ) ??
                                              0,
                                          name:
                                              (app['user'] is Map
                                                      ? (app['user']['particulier_profile']['pseudo'] ??
                                                            app['user']['pro_profile']['company_name'] ??
                                                            '')
                                                      : ('assets/images/details_bon_plans/Ellipse 11 (6).png'))
                                                  .toString(),
                                          email:
                                              (app['user'] is Map
                                                      ? (app['user']['email'] ??
                                                            '')
                                                      : (app['email'] ?? ''))
                                                  .toString(),
                                          avatarPath:
                                              app['user']['particulier_profile']['avatar_url'] ??
                                              app['user']['pro_profile']['avatar_url'] ??
                                              '',
                                          jobTitle: jobTitle,
                                          submissionDate: _formatDate(
                                            app['created_at'] ??
                                                app['submitted_at'],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 7,
                                  child: Container(
                                    height:
                                        MediaQuery.of(context).size.height -
                                        310,
                                    width: 1.5,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 25,
                                  right: 25,
                                  child: Container(
                                    height: 1,
                                    width: 500,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 7,
                                  right: 25,
                                  child: Container(
                                    height: 1,
                                    width: 500,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                            if (index != _myJobOffers.length - 1)
                              const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ],
                  // EVENTS SECTION
                  if (_myEvents.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: const Color(0xFFEF8A40),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mes Événements (${_myEvents.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (int index = 0; index < _myEvents.length; index++) ...[
                      Builder(
                        builder: (context) {
                          final event = _myEvents[index];
                          final eventTitle = event['title']?.toString() ?? '';
                          final description = (event['description'] ?? '')
                              .toString();
                          final date = _formatDate(event['created_at']);
                          final views =
                              int.tryParse(
                                (event['views'] ?? event['view_count'] ?? 0)
                                    .toString(),
                              ) ??
                              0;
                          final participantsCount = _participantsCountForEvent(
                            event,
                          );

                          // Extract owner info - same pattern as job offers
                          final eventUser = event['user'];
                          String avatar = '';
                          String companyName = 'Organisateur';

                          if (eventUser is Map) {
                            final particulierProfile =
                                eventUser['particulier_profile'];
                            final proProfile = eventUser['pro_profile'];

                            if (particulierProfile is Map) {
                              avatar =
                                  particulierProfile['avatar_url']
                                      ?.toString() ??
                                  '';
                              companyName =
                                  particulierProfile['pseudo']?.toString() ??
                                  'Organisateur';
                            } else if (proProfile is Map) {
                              avatar =
                                  proProfile['avatar_url']?.toString() ??
                                  proProfile['logo_url']?.toString() ??
                                  '';
                              companyName =
                                  proProfile['company_name']?.toString() ??
                                  'Organisateur';
                            }
                          }

                          final participants = _participantsForEvent(event);

                          return Column(
                            children: [
                              _buildOffreCard(
                                avatar: avatar,
                                companyName: companyName.toString(),
                                isPro: true,
                                jobTitle: eventTitle,
                                description: description,
                                category: 'Événement',
                                date: date,
                                candidatures: participantsCount,
                                views: views,
                                onEdit: null,
                                onDelete: null,
                              ),
                              const SizedBox(height: 12),
                              participantsCount > 0
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 35,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Participants ($participantsCount)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Tout afficher',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox.shrink(),
                              participantsCount > 0
                                  ? const SizedBox(height: 12)
                                  : SizedBox.shrink(),
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 14,
                                      bottom: 20,
                                    ),
                                    child: Column(
                                      children: [
                                        for (final participant
                                            in participants.take(3))
                                          _buildCandidatureItem(
                                            userId:
                                                int.tryParse(
                                                  participant['user']?['id']
                                                          ?.toString() ??
                                                      '0',
                                                ) ??
                                                0,
                                            name: _extractParticipantName(
                                              participant,
                                            ),
                                            email: _extractParticipantEmail(
                                              participant,
                                            ),
                                            avatarPath:
                                                _extractParticipantAvatar(
                                                  participant,
                                                ),
                                            jobTitle: eventTitle,
                                            submissionDate: _formatDate(
                                              participant['created_at'] ??
                                                  participant['registered_at'] ??
                                                  participant['participated_at'],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 7,
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.height -
                                          310,
                                      width: 1.5,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 25,
                                    right: 25,
                                    child: Container(
                                      height: 1,
                                      width: 500,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 7,
                                    right: 25,
                                    child: Container(
                                      height: 1,
                                      width: 500,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                              if (index != _myEvents.length - 1)
                                const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                  // TRAININGS SECTION
                  if (_myTrainings.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: const Color(0xFF2E9B5B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mes Formations (${_myTrainings.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (
                      int index = 0;
                      index < _myTrainings.length;
                      index++
                    ) ...[
                      Builder(
                        builder: (context) {
                          final training = _myTrainings[index];
                          final trainingTitle =
                              training['title']?.toString() ?? '';
                          final description = (training['description'] ?? '')
                              .toString();
                          final date = _formatDate(training['created_at']);
                          final views =
                              int.tryParse(
                                (training['views'] ??
                                        training['view_count'] ??
                                        0)
                                    .toString(),
                              ) ??
                              0;
                          final subscribersCount = _subscribersCountForTraining(
                            training,
                          );

                          // Extract owner info - same pattern as job offers
                          final trainingUser = training['user'];
                          String avatar = '';
                          String companyName = 'Organisateur';

                          if (trainingUser is Map) {
                            final particulierProfile =
                                trainingUser['particulier_profile'];
                            final proProfile = trainingUser['pro_profile'];

                            if (particulierProfile is Map) {
                              avatar =
                                  particulierProfile['avatar_url']
                                      ?.toString() ??
                                  '';
                              companyName =
                                  particulierProfile['pseudo']?.toString() ??
                                  'Organisateur';
                            } else if (proProfile is Map) {
                              avatar =
                                  proProfile['avatar_url']?.toString() ??
                                  proProfile['logo_url']?.toString() ??
                                  '';
                              companyName =
                                  proProfile['company_name']?.toString() ??
                                  'Organisateur';
                            }
                          }

                          final subscribers = _subscribersForTraining(training);

                          return Column(
                            children: [
                              _buildOffreCard(
                                avatar: avatar,
                                companyName: companyName.toString(),
                                isPro: true,
                                jobTitle: trainingTitle,
                                description: description,
                                category: 'Formation',
                                date: date,
                                candidatures: subscribersCount,
                                views: views,
                                onEdit: null,
                                onDelete: null,
                              ),
                              const SizedBox(height: 12),
                              subscribersCount > 0
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 35,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Inscrits ($subscribersCount)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Tout afficher',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox.shrink(),
                              subscribersCount > 0
                                  ? const SizedBox(height: 12)
                                  : SizedBox.shrink(),
                              Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 14,
                                      bottom: 20,
                                    ),
                                    child: Column(
                                      children: [
                                        for (final subscriber
                                            in subscribers.take(3))
                                          _buildCandidatureItem(
                                            userId:
                                                int.tryParse(
                                                  subscriber['user']?['id']
                                                          ?.toString() ??
                                                      '0',
                                                ) ??
                                                0,
                                            name: _extractParticipantName(
                                              subscriber,
                                            ),
                                            email: _extractParticipantEmail(
                                              subscriber,
                                            ),
                                            avatarPath:
                                                _extractParticipantAvatar(
                                                  subscriber,
                                                ),
                                            jobTitle: trainingTitle,
                                            submissionDate: _formatDate(
                                              subscriber['created_at'] ??
                                                  subscriber['subscribed_at'] ??
                                                  subscriber['registered_at'],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    left: 7,
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.height -
                                          310,
                                      width: 1.5,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 25,
                                    right: 25,
                                    child: Container(
                                      height: 1,
                                      width: 500,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 7,
                                    right: 25,
                                    child: Container(
                                      height: 1,
                                      width: 500,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                ],
                              ),
                              if (index != _myTrainings.length - 1)
                                const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ] else ...[
                if (_isLoadingMyApplications)
                  const Center(child: CircularProgressIndicator())
                else if (_myApplicationsError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _myApplicationsError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadMyApplications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF8A40),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else if (_myApplications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 40,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune candidature',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vous n\'avez postulé à aucune offre d\'emploi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  for (int i = 0; i < _myApplications.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final app = _myApplications[i];
                        final jobOffer = app['job_offer'] is Map
                            ? app['job_offer'] as Map<String, dynamic>
                            : null;

                        final jobTitle =
                            (jobOffer?['title'] ?? app['job_title'] ?? '')
                                .toString();
                        final description =
                            (jobOffer?['description'] ??
                                    app['description'] ??
                                    '')
                                .toString();

                        final companyName =
                            (jobOffer?['company_name'] ??
                                    (jobOffer?['user'] is Map
                                        ? (jobOffer?['user']['pro_profile']
                                                  is Map
                                              ? (jobOffer?['user']['pro_profile']['company_name'] ??
                                                    '')
                                              : '')
                                        : '') ??
                                    '')
                                .toString();

                        final date = _formatDate(
                          app['created_at'] ?? app['submitted_at'],
                        );
                        final status = _applicationStatusLabel(app['status']);

                        final jobOfferId = jobOffer?['id'] ?? null;
                        final applicationIdInt = app['id'];
                        final companyPhone = jobOffer?['user'] is Map
                            ? (jobOffer?['user']['pro_profile'] is Map
                                  ? (jobOffer?['user']['pro_profile']['phone'] ??
                                        '')
                                  : '')
                            : '';

                        return Column(
                          children: [
                            _buildCandidatureCard(
                              icon:
                                  'assets/images/profil_pro/space-pro-cand.png',
                              jobTitle: jobTitle,
                              companyDescription: companyName.isNotEmpty
                                  ? companyName
                                  : "Description de l'entreprise",
                              description: description,
                              date: date,
                              status: status,
                              jobOfferId: jobOfferId,
                              applicationId: applicationIdInt,
                              companyPhone: companyPhone,
                            ),
                            if (i != _myApplications.length - 1)
                              const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ],

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildCategoryChip(String label, bool isSelected) {
  //   return GestureDetector(
  //     onTap: () => setState(() => selectedCategory = label),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
  //       decoration: BoxDecoration(
  //         color: isSelected ? Color(0xFF2A8143) : Colors.white,
  //         borderRadius: BorderRadius.circular(14),
  //         border: Border.all(
  //           color: isSelected ? Colors.green : Colors.grey[300]!,
  //         ),
  //       ),
  //       child: Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 12,
  //           color: isSelected ? Colors.white : Colors.grey[600],
  //           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildOffreCard({
    required String avatar,
    required String companyName,
    required bool isPro,
    required String jobTitle,
    required String description,
    required String category,
    required String date,
    required int candidatures,
    required int views,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        avatar.isNotEmpty &&
                            (avatar.startsWith('http://') ||
                                avatar.startsWith('https://'))
                        ? NetworkImage(avatar) as ImageProvider
                        : avatar.startsWith('assets/')
                        ? AssetImage(avatar) as ImageProvider
                        : NetworkImage(ApiConfig.resolveMediaUrl(avatar) ?? '')
                              as ImageProvider,
                    onBackgroundImageError:
                        (Object exception, StackTrace? stackTrace) {
                          // keep fallback
                        },
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 1),
                    if (isPro)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'Pro',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9B5B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/images/profil_pro/btn-edit.png'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/profil_pro/btn-delete.png',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            jobTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.black, height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.sell_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 1),
              Text(
                category,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              const SizedBox(width: 2),
              const SizedBox(width: 5, child: Text('|')),
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              const SizedBox(width: 2),
              const SizedBox(width: 5, child: Text('|')),
              Icon(
                Icons.person_2_outlined,
                size: 14,
                color: const Color(0xFFEF8A40),
              ),
              const SizedBox(width: 4),
              Text(
                '$candidatures Candidature(s)',
                style: const TextStyle(fontSize: 9.5, color: Color(0xFFEF8A40)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: Color(0xFF2E9B5B),
              ),
              const SizedBox(width: 4),
              Text(
                '$views vue(s)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF2E9B5B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatureCard({
    required String jobTitle,
    required String companyDescription,
    required String description,
    required String date,
    required String status,
    required String icon,
    required String? jobOfferId,
    required int? applicationId,
    String? companyPhone,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(-2, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF8A40).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(icon, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E9B5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF2E9B5B).withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'Offre d\'emploi',
                          style: TextStyle(
                            color: Color(0xFF2E9B5B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: companyPhone != null && companyPhone.isNotEmpty
                      ? () => _makePhoneCall(companyPhone)
                      : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: companyPhone != null && companyPhone.isNotEmpty
                          ? const Color(0xFF8A38F5)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/profil_pro/space-pro-phone.png',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteApplication(applicationId),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/profil_pro/btn-delete.png',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              companyDescription,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.black, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Container(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: jobOfferId != null
                        ? () => _navigateToJobOfferDetail(jobOfferId)
                        : null,
                    icon: Image.asset(
                      'assets/images/profil_pro/space-pro-job-white.png',
                    ),
                    label: const Text(
                      'Voir l\'offre d\'emploi',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF8A40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                'Statut : $status',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCandidateDocuments(int userId, String candidateName) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/candidate-documents?user_id=$userId',
      );
      if (!mounted) return;
      Navigator.pop(context);

      final docs = response['data'] is List
          ? List<Map<String, dynamic>>.from(response['data'])
          : [];

      // Filter only visible documents
      final visibleDocs = docs
          .where((d) => d['is_visible'] == true || d['is_visible'] == 1)
          .toList();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 400,
            constraints: const BoxConstraints(maxHeight: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEF8A40).withOpacity(0.1),
                      child: const Icon(
                        Icons.folder_shared_outlined,
                        color: Color(0xFFEF8A40),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documents de',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            candidateName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: visibleDocs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_off_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun document visible',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: visibleDocs.length,
                          itemBuilder: (context, index) {
                            final doc = visibleDocs[index];
                            final fileUrl = ApiConfig.resolveMediaUrl(
                              doc['file_path'] ?? '',
                            );
                            final fileName =
                                doc['original_name'] ?? 'Document ${index + 1}';
                            final fileType = doc['type'] ?? 'document';
                            final fileSize = _formatFileSize(
                              doc['file_size'] ?? 0,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Icon + File info
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: _getFileTypeColor(
                                              fileType,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            _getFileTypeIcon(fileType),
                                            color: _getFileTypeColor(fileType),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF333333),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getFileTypeColor(
                                                        fileType,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _getFileTypeLabel(
                                                        fileType,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            _getFileTypeColor(
                                                              fileType,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    fileSize,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Row 2: Action buttons (full width)
                                    if (fileUrl != null) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.visibility_outlined,
                                              color: const Color(0xFF2E9B5B),
                                              onTap: () => _viewDocument(
                                                fileUrl,
                                                fileName,
                                              ),
                                              label: 'Voir',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.download_outlined,
                                              color: const Color(0xFFEF8A40),
                                              onTap: () => _downloadDocument(
                                                fileUrl,
                                                fileName,
                                              ),
                                              label: 'Télécharger',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _viewDocument(String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(url: url, fileName: fileName),
      ),
    );
  }

  void _downloadDocument(String url, String fileName) async {
    // Check and request storage permission
    var status = await Permission.storage.request();

    if (!status.isGranted) {
      // Permission denied, show dialog to ask user
      final bool? shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission requise'),
          content: const Text(
            'L\'application a besoin d\'accéder au stockage pour télécharger les fichiers. Voulez-vous accorder cette permission ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui'),
            ),
          ],
        ),
      );

      if (shouldRequest == true) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission refusée. Impossible de télécharger.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        return;
      }
    }

    // Show downloading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Téléchargement...'),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      // Get Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (!downloadsDir!.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final savePath = '${downloadsDir.path}/${timestamp}_$cleanFileName';

      // Download file using Dio
      final dio = Dio();
      await dio.download(url, savePath);

      if (!mounted) return;

      // Hide loading snackbar and show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Téléchargé dans Téléchargements')),
            ],
          ),
          backgroundColor: const Color(0xFF2E9B5B),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileTypeIcon(String type) {
    switch (type) {
      case 'cv':
        return Icons.description_outlined;
      case 'lettre':
      case 'cover_letter':
        return Icons.mail_outline;
      case 'portfolio':
        return Icons.folder_open_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileTypeColor(String type) {
    switch (type) {
      case 'cv':
        return const Color(0xFF2E9B5B);
      case 'lettre':
      case 'cover_letter':
        return const Color(0xFFEF8A40);
      case 'portfolio':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF666666);
    }
  }

  String _getFileTypeLabel(String type) {
    switch (type) {
      case 'cv':
        return 'CV';
      case 'lettre':
      case 'cover_letter':
        return 'LETTRE';
      case 'portfolio':
        return 'PORTFOLIO';
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidatureItem({
    required int userId,
    required String name,
    required String email,
    required String avatarPath,
    required String jobTitle,
    required String submissionDate,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(-3, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    avatarPath.isNotEmpty &&
                        (avatarPath.startsWith('http') ||
                            avatarPath.startsWith('https'))
                    ? NetworkImage(avatarPath) as ImageProvider
                    : avatarPath.startsWith('assets/')
                    ? AssetImage(avatarPath) as ImageProvider
                    : NetworkImage(ApiConfig.resolveMediaUrl(avatarPath) ?? '')
                          as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset('assets/images/profil_pro/btn-delete.png'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Image.asset(
                'assets/images/profil_pro/space-pro-job.png',
                width: 15,
                height: 15,
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: Text(
                  jobTitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              const Spacer(),
              Container(
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () => _showCandidateDocuments(userId, name),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text(
                    'Voir les documents',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF8A40),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Image.asset(
                'assets/images/profil_pro/space-pro-calendar.png',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Date de soumission : $submissionDate',
                style: const TextStyle(fontSize: 11, color: Color(0xFFEF8A40)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApplication(int? applicationId) async {
    if (applicationId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la candidature'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette candidature ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient().authenticatedDelete(
        '/job-offers/applications/$applicationId',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature supprimée'),
            backgroundColor: Color(0xFF2E9B5B),
          ),
        );
        _loadMyApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'appeler ce numéro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToJobOfferDetail(String jobOfferId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().authenticatedGet(
        '/job-offers/$jobOfferId',
      );
      if (!mounted) return;
      Navigator.pop(context);

      final data = response['data'] as Map<String, dynamic>? ?? response;

      final title = data['title']?.toString() ?? '';
      final descriptionRaw = data['description'];
      final description = descriptionRaw?.toString() ?? '';
      final descriptionDelta =
          data['description_delta'] ??
          (descriptionRaw is List ? descriptionRaw : null);
      final profileDescription = data['profile_description']?.toString();
      final companyName = data['company_name']?.toString() ?? 'Entreprise';
      final companyWebsite = data['company_website']?.toString() ?? '';

      final contractTypeRaw = data['contract_type'];
      final contractType = contractTypeRaw is Map
          ? (contractTypeRaw['name'] ?? contractTypeRaw.toString())
          : (contractTypeRaw?.toString() ?? '');

      final workTimeRaw = data['work_time'];
      final workTime = workTimeRaw is Map
          ? (workTimeRaw['name'] ?? workTimeRaw.toString())
          : (workTimeRaw?.toString() ?? '');

      final locationRaw = data['location'];
      final location = locationRaw is Map
          ? (locationRaw['city'] ??
                locationRaw['name'] ??
                locationRaw.toString())
          : (locationRaw?.toString() ?? '');

      final categoryRaw = data['category'];
      final category = categoryRaw is Map
          ? (categoryRaw['name'] ?? categoryRaw.toString())
          : (categoryRaw?.toString() ?? '');

      final salaryMin = data['salary_min'];
      final salaryMax = data['salary_max'];
      final remoteWork = data['remote_work'] == true;

      final educationLevelRaw = data['education_level'];
      final educationLevel = educationLevelRaw is Map
          ? (educationLevelRaw['name'] ?? educationLevelRaw.toString())
          : educationLevelRaw?.toString();

      final experienceLevelRaw = data['experience_level'];
      final experienceLevel = experienceLevelRaw is Map
          ? (experienceLevelRaw['name'] ?? experienceLevelRaw.toString())
          : experienceLevelRaw?.toString();

      final advantagesRaw = data['advantages'];
      final advantages = advantagesRaw is List
          ? advantagesRaw
                .map(
                  (a) => a is Map ? (a['name'] ?? a.toString()) : a.toString(),
                )
                .toList()
          : <String>[];

      final createdAt = data['created_at']?.toString();
      final mediaRaw =
          data['media'] as List? ?? data['media_files'] as List? ?? [];

      final images = mediaRaw
          .where((m) => m is Map && m['url'] != null)
          .map((m) => _buildImageUrl(m['url']?.toString() ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();

      if (images.isEmpty) {
        images.add('assets/images/dashboard_particulier/Rectangle 13.png');
      }

      final tags = <JobDetailTag>[
        if (contractType.isNotEmpty)
          JobDetailTag(icon: Icons.description_outlined, text: contractType),
        if (workTime.isNotEmpty)
          JobDetailTag(icon: Icons.access_time, text: _workTimeLabel(workTime)),
        if (location.isNotEmpty)
          JobDetailTag(icon: Icons.location_on_outlined, text: location),
        if (category.isNotEmpty)
          JobDetailTag(icon: Icons.category_outlined, text: category),
        if (educationLevel != null && educationLevel.isNotEmpty)
          JobDetailTag(icon: Icons.school_outlined, text: educationLevel),
        if (experienceLevel != null && experienceLevel.isNotEmpty)
          JobDetailTag(icon: Icons.trending_up_outlined, text: experienceLevel),
        if (salaryMin != null || salaryMax != null)
          JobDetailTag(
            icon: Icons.euro,
            text: _formatSalary(salaryMin, salaryMax),
            isSpecial: true,
          ),
      ];

      final advantagesList = advantages
          .take(3)
          .map((a) => a.toString())
          .toList();

      final currentUserId = await _ensureCurrentUserId();
      final jobUserId = data['user_id']?.toString();
      final isOwner =
          currentUserId != null &&
          jobUserId != null &&
          currentUserId == jobUserId;

      final authorData = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : null;
      final acceptMessages = data['accept_messages'] == true;

      final avatar = data['user']?['avatar_url'];

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(
            images: images,
            companyLogo:
                avatar ??
                'assets/images/dashboard_particulier/Rectangle 13.png',
            companyName: companyName,
            companyWebsite: companyWebsite,
            jobTitle: title,
            description: description,
            descriptionDelta: descriptionDelta,
            profileDescription: profileDescription,
            tags: tags,
            postTags: <PostTag>[
              if (workTime.isNotEmpty)
                PostTag(
                  title: workTime,
                  icon: Icons.access_time,
                  color: Colors.grey,
                ),
            ],
            subtags: contractType.isNotEmpty
                ? PostTag(
                    title: contractType,
                    icon: Icons.description_outlined,
                    color: const Color(0xFF27A5FF),
                  )
                : null,
            advantages: advantagesList,
            timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
            location: location,
            remoteWork: remoteWork,
            educationLevel: educationLevel,
            experienceLevel: experienceLevel,
            isOwner: isOwner,
            jobOfferId: jobOfferId.toString(),
            jobOfferData: data,
            acceptMessages: acceptMessages,
            authorData: authorData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
    if (url.startsWith('http')) return url;
    return '$serverBase/storage/$url';
  }

  String _formatSalary(dynamic min, dynamic max) {
    if (min != null && max != null) {
      return '${min}€ - ${max}€';
    } else if (min != null) {
      return 'À partir de ${min}€';
    } else if (max != null) {
      return 'Jusqu\'à ${max}€';
    }
    return 'Salaire non spécifié';
  }

  String _workTimeLabel(String val) {
    switch (val) {
      case 'FULL_TIME':
        return 'Temps plein';
      case 'PART_TIME':
        return 'Temps partiel';
      case 'INTERIM':
        return 'Intérim';
      case 'FREELANCE':
        return 'Freelance';
      case 'ALTERNANCE':
        return 'Alternance';
      case 'STAGE':
        return 'Stage';
      default:
        return val;
    }
  }

  String _timeAgo(String isoDate) {
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
}
