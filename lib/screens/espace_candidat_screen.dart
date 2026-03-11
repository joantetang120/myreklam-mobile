import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';

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
        body: SingleChildScrollView(
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
                        onChanged: (val) => setState(() => _showOnProfile = val),
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
            status: 'Aucun document',
            buttonLabel: 'Ajouter votre CV',
            buttonIcon: Icons.upload_file_outlined,
            visibilityValue: _cvVisibility,
            onVisibilityChanged: (val) =>
                setState(() => _cvVisibility = val),
          ),

          const SizedBox(height: 20),

          // Lettre de motivation Section
          _buildDocumentSection(
            title: 'Lettre de motivation',
            status: 'Aucun document',
            buttonLabel: 'Ajouter une lettre de motivation',
            buttonIcon: Icons.upload_file_outlined,
            visibilityValue: _lettreVisibility,
            onVisibilityChanged: (val) =>
                setState(() => _lettreVisibility = val),
          ),

          const SizedBox(height: 20),

          // Portfolio Section
          _buildDocumentSection(
            title: 'Portfolio',
            status: 'Aucun document',
            buttonLabel: 'Ajouter un document ou lien',
            buttonIcon: Icons.upload_file_outlined,
            visibilityValue: _portfolioVisibility,
            onVisibilityChanged: (val) =>
                setState(() => _portfolioVisibility = val),
          ),
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
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {},
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
