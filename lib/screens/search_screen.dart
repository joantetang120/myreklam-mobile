import 'package:flutter/material.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/models/location_data.dart';
import 'package:myreklam/widgets/location_picker_field.dart';
import 'package:myreklam/services/saved_search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  LocationData? _selectedLocation;
  double _searchRadius = 0;
  bool _searchAllFrance = false;
  String? _selectedCategory;
  String _searchType = 'annonces'; // 'annonces' or 'users'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ParticulierMainScreen(initialIndex: 0),
              ),
            );
          },
        ),
        title: const Text(
          'Trouvez ce que vous cherchez',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bons plans, emplois, formations, événements et plus encore',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Que recherchez-vous?',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _searchType = 'annonces'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _searchType == 'annonces'
                                ? const Color(0xFF3AAE5E)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Annonces',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _searchType == 'annonces'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _searchType = 'users'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _searchType == 'users'
                                ? const Color(0xFF3AAE5E)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Utilisateurs',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _searchType == 'users'
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category and Location filters - only for annonces
              if (_searchType == 'annonces') ...[
                GestureDetector(
                  onTap: () {
                    _showCategoryBottomSheet(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_outlined, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategory ?? 'Toutes les catégories',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedCategory != null
                                  ? Colors.black
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LocationPickerField(
                  initialLocation: _selectedLocation,
                  label: 'Localisation',
                  helperText: 'Recherchez une ville ou adresse précise',
                  onLocationSelected: (location) {
                    setState(() {
                      _selectedLocation = location;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Rayon de recherche',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF3AAE5E),
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: const Color(0xFF3AAE5E),
                    overlayColor: const Color(0xFF3AAE5E).withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
                  child: Slider(
                    value: _searchRadius,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        _searchRadius = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '20 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '50 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '75 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '100 km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _searchAllFrance,
                      onChanged: (value) {
                        setState(() {
                          _searchAllFrance = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF3AAE5E),
                    ),
                    Text(
                      'Rechercher dans toute la France',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer un terme de recherche'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParticulierMainScreen(
                          initialIndex: 3,
                          showSearchResults: true,
                          searchQuery: query,
                          searchCategory: _selectedCategory,
                          searchLocation: _selectedLocation?.address ?? '',
                          searchLocationLat: _selectedLocation?.latitude,
                          searchLocationLng: _selectedLocation?.longitude,
                          searchLocationCity: _selectedLocation?.city,
                          searchLocationPostalCode:
                              _selectedLocation?.postalCode,
                          searchRadius: _searchRadius,
                          searchAllFrance: _searchAllFrance,
                          searchType: _searchType,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3AAE5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Rechercher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _showSaveSearchDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF9800),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFFF9800), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.bookmark_border, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sauvegarder cette recherche',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSaveSearchDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - fixed
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sauvegarder cette recherche',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sauvegardez vos critères pour les retrouver plus tard.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name field
                      const Text(
                        'Nom de la recherche',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'EX: Bons plans vêtements',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Criteria preview
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Critères de la recherche',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF424242),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCriteriaRow(
                              'Terme',
                              _searchController.text.isEmpty
                                  ? 'Bons plans'
                                  : _searchController.text,
                            ),
                            const SizedBox(height: 4),
                            _buildCriteriaRow(
                              'Catégorie',
                              _selectedCategory ?? 'Toutes',
                            ),
                            const SizedBox(height: 4),
                            _buildCriteriaRow(
                              'Lieu',
                              _selectedLocation?.city ?? 'France',
                            ),
                            const SizedBox(height: 4),
                            _buildCriteriaRow(
                              'Rayon',
                              '${_searchRadius.toInt()}km',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Footer buttons - fixed
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF9800),
                          side: const BorderSide(color: Color(0xFFFF9800)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            Navigator.pop(context);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez entrer un nom pour la recherche',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Capture scaffold context before closing dialog
                          final scaffoldContext = this.context;
                          
                          // Show loading indicator (replace current dialog)
                          Navigator.pop(context);
                          
                          // Use a new context for loading dialog - wait for frame to ensure clean context
                          await Future.microtask(() {});
                          if (!mounted) return;

                          showDialog(
                            context: scaffoldContext,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            // Save to backend
                            final result = await SavedSearchService()
                                .saveSearch(
                                  name: name,
                                  searchType: _searchType,
                                  searchQuery:
                                      _searchController.text.trim().isEmpty
                                      ? null
                                      : _searchController.text.trim(),
                                  category: _selectedCategory,
                                  locationAddress: _selectedLocation?.address,
                                  locationLat: _selectedLocation?.latitude,
                                  locationLng: _selectedLocation?.longitude,
                                  locationCity: _selectedLocation?.city,
                                  locationPostalCode:
                                      _selectedLocation?.postalCode,
                                  searchRadius: _searchRadius,
                                  searchAllFrance: _searchAllFrance,
                                );

                            // Close loading indicator
                            if (!mounted) return;
                            Navigator.of(scaffoldContext, rootNavigator: true).pop();

                            // Show success/error message
                            if (result != null) {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Recherche sauvegardée !'),
                                  backgroundColor: Color(0xFF3AAE5E),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Erreur lors de la sauvegarde'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            // Close loading indicator on error
                            if (!mounted) return;
                            Navigator.of(scaffoldContext, rootNavigator: true).pop();

                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Sauvegarder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sélectionner une catégorie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              _buildCategoryOption('Toutes les catégories'),
              _buildCategoryOption('Bons plans'),
              _buildCategoryOption('Emplois'),
              _buildCategoryOption('Formations'),
              _buildCategoryOption('Événements'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(String category) {
    return ListTile(
      title: Text(category),
      onTap: () {
        setState(() {
          _selectedCategory = category == 'Toutes les catégories'
              ? null
              : category;
        });
        Navigator.pop(context);
      },
    );
  }
}
