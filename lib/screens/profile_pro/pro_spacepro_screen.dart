import 'package:flutter/material.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/screens/creer_offre_emploi_screen.dart';

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
    await _loadMyApplications();
  }

  Future<void> _ensureCurrentUserId() async {
    try {
      final response = await ApiClient().authenticatedGet('/profile/me');
      final id = response['user']?['id']?.toString();
      if (!mounted) return;
      setState(() => _currentUserId = id);
    } catch (_) {
      // Keep null; UI will show error if job offers fail.
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
      body: SingleChildScrollView(
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
                        style: TextStyle(fontSize: 12, color: Colors.red[400]),
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
                                          color: Colors.black.withOpacity(0.5),
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
                                      MediaQuery.of(context).size.height - 310,
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
                        style: TextStyle(fontSize: 12, color: Colors.red[400]),
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
                          (jobOffer?['description'] ?? app['description'] ?? '')
                              .toString();

                      final companyName =
                          (jobOffer?['company_name'] ??
                                  (jobOffer?['user'] is Map
                                      ? (jobOffer?['user']['pro_profile'] is Map
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

                      return Column(
                        children: [
                          _buildCandidatureCard(
                            icon: 'assets/images/profil_pro/space-pro-cand.png',
                            jobTitle: jobTitle,
                            companyDescription: companyName.isNotEmpty
                                ? companyName
                                : "Description de l'entreprise",
                            description: description,
                            date: date,
                            status: status,
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
                        ? NetworkImage(avatar)
                        : const AssetImage(
                            'assets/images/profil_pro/space-pro-offer.png',
                          ),
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A38F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/profil_pro/space-pro-phone.png',
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
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/profil_pro/btn-delete.png',
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
                    onPressed: () {},
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

  Widget _buildCandidatureItem({
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
                    ? NetworkImage(avatarPath)
                    : AssetImage(avatarPath),
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
                  onPressed: () {},
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
}
