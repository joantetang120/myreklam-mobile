import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProProfileEntrepriseScreen extends StatefulWidget {
  const ProProfileEntrepriseScreen({super.key});

  @override
  State<ProProfileEntrepriseScreen> createState() =>
      _ProProfileEntrepriseScreenState();
}

class _ProProfileEntrepriseScreenState extends State<ProProfileEntrepriseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers pour les champs
  final TextEditingController _nomSocieteController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _codePostalController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _paysController = TextEditingController();
  final TextEditingController _presentationController = TextEditingController(
    text:
        '''C’est un espace dynamique pensé pour connecter les particuliers, les professionnels et les entreprises autour d’opportunités concrètes : bons plans, offres d’emploi, formations, événements, ou encore services sur mesure.
Notre objectif est simple : favoriser la mise en relation locale et nationale, tout en valorisant chaque publication, chaque interaction et chaque membre de la communauté. Chez MyReklam, chaque action compte et peut être récompensée via un système de points (les "MY’s"), renforçant l’engagement et la fidélité de nos utilisateurs.

Une vision collaborative et équitable
Nous croyons en une plateforme utile, équitable et accessible à tous. Que vous soyez un particulier à la recherche d’une formation, une entreprise souhaitant publier une annonce, ou un professionnel en quête de visibilité, MyReklam vous accompagne à chaque étape.''',
  );

  // Controllers pour les réseaux sociaux
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _snapchatController = TextEditingController();

  String? _selectedSecteur;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomSocieteController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _codePostalController.dispose();
    _villeController.dispose();
    _paysController.dispose();
    _presentationController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _youtubeController.dispose();
    _snapchatController.dispose();
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
          'Profil entreprise',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // TabBar
          Container(
            margin: const EdgeInsets.only(left: 14, right: 14, bottom: 4),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEF8A40).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: EdgeInsets.zero,
              indicator: BoxDecoration(
                color: const Color(0xFFEF8A40),
                borderRadius: BorderRadius.circular(6),
              ),
              tabs: const [
                Tab(text: 'Informations générales'),
                Tab(text: 'Medias'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildInformationsGeneralesTab(), _buildMediasTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET 1: INFORMATIONS GÉNÉRALES ====================
  Widget _buildInformationsGeneralesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Informations de l'entreprise
          _buildSectionCard(
            icon: Icons.business_outlined,
            title: 'Informations de l\'entreprise',
            child: Column(
              children: [
                _buildLabeledTextField(
                  icon: Icons.business_outlined,
                  label: 'Nom de la société',
                  controller: _nomSocieteController,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  icon: Icons.category_outlined,
                  label: 'Secteur d\'activité',
                  value: _selectedSecteur,
                  items: ['Commerce', 'Services', 'Industrie', 'Tech', 'Autre'],
                  onChanged: (val) => setState(() => _selectedSecteur = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Coordonnés
          _buildSectionCard(
            icon: Icons.mail_outline,
            title: 'Coordonnés',
            child: Column(
              children: [
                _buildLabeledTextField(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  controller: _telephoneController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  controller: _emailController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Adresse
          _buildSectionCard(
            icon: Icons.location_on_outlined,
            title: 'Adresse',
            child: Column(
              children: [
                _buildLabeledTextField(
                  icon: Icons.location_on_outlined,
                  label: 'Adresse complète',
                  controller: _adresseController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.markunread_mailbox_outlined,
                  label: 'Code postal',
                  controller: _codePostalController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.location_city_outlined,
                  label: 'Ville',
                  controller: _villeController,
                ),
                const SizedBox(height: 16),
                _buildLabeledTextField(
                  icon: Icons.public_outlined,
                  label: 'Pays',
                  controller: _paysController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Presentation
          _buildSectionCard(
            icon: Icons.description_outlined,
            title: 'Presentation',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _presentationController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Décrivez votre entreprise...',
                ),
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Enregistrer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Enregistrer les modifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF8A40),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== ONGLET 2: MEDIAS ====================
  Widget _buildMediasTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Réseaux sociaux
          _buildSectionCard(
            icon: Icons.share_outlined,
            title: 'Réseaux sociaux',
            child: Column(
              children: [
                _buildSocialField(
                  iconWidget: const Icon(
                    Icons.facebook,
                    color: Color(0xFF1877F2),
                    size: 20,
                  ),
                  label: 'facebook',
                  controller: _facebookController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.squareInstagram,
                    color: Color(0xFF0077B5),
                    size: 20,
                  ),
                  label: 'instagram',
                  controller: _instagramController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.linkedin,
                    color: Color(0xFF0077B5),
                    size: 20,
                  ),
                  label: 'Linkedin',
                  controller: _linkedinController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.youtube,
                    color: Color(0xFFFF0000),
                    size: 20,
                  ),
                  label: 'Youtube',
                  controller: _youtubeController,
                ),
                const SizedBox(height: 12),
                _buildSocialField(
                  iconWidget: const Icon(
                    FontAwesomeIcons.snapchat,
                    color: Color(0xFFFFFC00),
                    size: 20,
                  ),
                  label: 'Snapchat',
                  controller: _snapchatController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section Bannière de l'entreprise
          _buildSectionCard(
            icon: Icons.image_outlined,
            title: 'Bannière de l\'entreprise',
            child: _buildUploadButton(
              label: 'Importer une bannière',
              color: const Color(0xFF2E9B5B),
            ),
          ),
          const SizedBox(height: 16),

          // Section Galerie de medias
          _buildSectionCard(
            icon: Icons.photo_library_outlined,
            title: 'Galerie de medias',
            child: _buildUploadButton(
              label: 'Ajouter un media',
              color: const Color(0xFF2E9B5B),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton Enregistrer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Enregistrer les modifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF8A40),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== WIDGETS HELPERS ====================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(-2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledTextField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2E9B5B)),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('', style: TextStyle(color: Colors.grey[400])),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialField({
    required Widget iconWidget,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2E9B5B)),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton({required String label, required Color color}) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label - Fonctionnalité bientôt disponible'),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifications enregistrées avec succès !'),
        backgroundColor: Color(0xFF2E9B5B),
      ),
    );
  }
}
