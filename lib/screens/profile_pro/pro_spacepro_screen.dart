import 'package:flutter/material.dart';

class ProSpaceProScreen extends StatefulWidget {
  const ProSpaceProScreen({super.key});

  @override
  State<ProSpaceProScreen> createState() => _ProSpaceProScreenState();
}

class _ProSpaceProScreenState extends State<ProSpaceProScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = 'Tout';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                        ? 'Total : 2 offre(s) publiée(s)'
                        : 'Total : 2 Candidature(s) envoyée(s)',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sélectionner la catégorie',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('Tout', selectedCategory == 'Tout'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Emploi', selectedCategory == 'Emploi'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    'Formations',
                    selectedCategory == 'Formations',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_tabController.index == 0) ...[
              _buildOffreCard(
                companyName: 'Dyson Sarl',
                isPro: true,
                jobTitle: 'Operateur téléphonique',
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                category: 'Offre d\'emploi',
                date: '11 novembre 2025',
                candidatures: 3,
                views: 201,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Candidatures (3)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      'Tout afficher',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 20),
                    child: Column(
                      children: [
                        _buildCandidatureItem(
                          name: 'Jacob Jones',
                          email: 'jacobjones@gmail.com',
                          avatarPath:
                              'assets/images/dashboard_particulier/Ellipse 10.png',
                          jobTitle: 'Operateur téléphonique',
                          submissionDate: '11 Décembre 2025',
                        ),
                        _buildCandidatureItem(
                          name: 'Brooklyn Simmons',
                          email: 'sara.cruz@example.com',
                          avatarPath:
                              'assets/images/dashboard_particulier/Ellipse 10.png',
                          jobTitle: 'Operateur téléphonique',
                          submissionDate: '11 Décembre 2025',
                        ),
                        _buildCandidatureItem(
                          name: 'Jean Pierr',
                          email: 'jeanpierr@gmail.com',
                          avatarPath:
                              'assets/images/dashboard_particulier/Ellipse 10.png',
                          jobTitle: 'Operateur téléphonique',
                          submissionDate: '04 Septembre 2025',
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 7,
                    child: Container(
                      height: MediaQuery.of(context).size.height - 310,
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
              const SizedBox(height: 20),
              _buildOffreCard(
                companyName: 'Dyson Sarl',
                isPro: true,
                jobTitle: 'Comptable Senior',
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. Duis aute irure dolor in reprehenderit in voluptate velit',
                category: 'Offre d\'emploi',
                date: '11 novembre 2025',
                candidatures: 1,
                views: 150,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Candidatures (1)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      'Tout afficher',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 20),
                    child: Column(
                      children: [
                        _buildCandidatureItem(
                          name: 'Leslie Alexandra',
                          email: 'lesliealexandra@gmail.com',
                          avatarPath:
                              'assets/images/dashboard_particulier/Ellipse 10.png',
                          jobTitle: 'Comptable Senior',
                          submissionDate: '12 Décembre 2025',
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 7,
                    child: Container(
                      height: MediaQuery.of(context).size.height - 310,
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
            ] else ...[
              _buildCandidatureCard(
                icon: 'assets/images/profil_pro/space-pro-cand.png',
                jobTitle: 'Plombier(e)',
                companyDescription: 'Description de l\'entreprise',
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad.',
                date: '10 décembre 2025',
                status: 'actif',
              ),
              const SizedBox(height: 12),
              _buildCandidatureCard(
                icon: 'assets/images/profil_pro/space-pro-cand.png',
                jobTitle: 'Plombier(e)',
                companyDescription: 'Description de l\'entreprise',
                description:
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad.',
                date: '10 décembre 2025',
                status: 'actif',
              ),
            ],

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2A8143) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOffreCard({
    required String companyName,
    required bool isPro,
    required String jobTitle,
    required String description,
    required String category,
    required String date,
    required int candidatures,
    required int views,
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/profil_pro/space-pro-offer.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'dyson',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
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
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/images/profil_pro/btn-edit.png'),
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
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/images/profil_pro/btn-delete.png'),
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
              CircleAvatar(radius: 24, backgroundImage: AssetImage(avatarPath)),
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
              Text(
                jobTitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
