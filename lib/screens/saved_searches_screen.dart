import 'package:flutter/material.dart';
import 'package:myreklam/widgets/app_layout.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/screens/profile_screen.dart';
import 'package:myreklam/services/saved_search_service.dart';

class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  final SavedSearchService _savedSearchService = SavedSearchService();
  List<Map<String, dynamic>> _savedSearches = [];
  bool _isLoading = true;

  // Filter state
  String? _selectedDate;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    setState(() => _isLoading = true);
    final searches = await _savedSearchService.getSavedSearches(
      date: _selectedDate,
      sortBy: _sortBy,
      order: _sortOrder,
    );
    if (mounted) {
      setState(() {
        _savedSearches = searches;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF9800)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
      await _loadSavedSearches();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadSavedSearches();
  }

  void _setSortOrder(String sortBy, String order) {
    setState(() {
      _sortBy = sortBy;
      _sortOrder = order;
    });
    _loadSavedSearches();
  }

  Future<void> _deleteSearch(int searchId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la recherche'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette recherche ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _savedSearchService.deleteSearch(searchId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recherche supprimée'),
            backgroundColor: Color(0xFF3AAE5E),
          ),
        );
        await _loadSavedSearches();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewSearch(Map<String, dynamic> search) {
    // Navigate to search screen with pre-filled data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ParticulierMainScreen(
          initialIndex: 3,
          showSearchResults: true,
          searchQuery: search['search_query'] ?? '',
          searchCategory: search['category'],
          searchLocation: search['location_address'] ?? '',
          searchLocationLat: search['location_lat'] != null
              ? double.tryParse(search['location_lat'].toString())
              : null,
          searchLocationLng: search['location_lng'] != null
              ? double.tryParse(search['location_lng'].toString())
              : null,
          searchLocationCity: search['location_city'],
          searchLocationPostalCode: search['location_postal_code'],
          searchRadius: search['search_radius']?.toDouble() ?? 0,
          searchAllFrance: search['search_all_france'] ?? false,
          searchType: search['search_type'] ?? 'annonces',
        ),
      ),
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> search) {
    final criteria = <String, String>{};

    if (search['search_query'] != null &&
        search['search_query'].toString().isNotEmpty) {
      criteria['Terme'] = search['search_query'];
    }
    if (search['category'] != null) {
      criteria['Catégorie'] = search['category'];
    }
    if (search['location_address'] != null &&
        search['location_address'].toString().isNotEmpty) {
      final city = search['location_city'] ?? '';
      final postalCode = search['location_postal_code'] ?? '';
      final locationDisplay = city.isNotEmpty || postalCode.isNotEmpty
          ? '${search['location_address']} ($postalCode)'
          : search['location_address'];
      criteria['Lieu'] = locationDisplay;
    }
    if (search['search_radius'] != null && search['search_radius'] > 0) {
      criteria['Rayon'] = '${search['search_radius']}km';
    }
    if (search['search_all_france'] == true) {
      criteria['Zone'] = 'Toute la France';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    search['name'] ?? 'Recherche',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Color(0xFF2196F3),
                  ),
                  onPressed: () => _viewSearch(search),
                  tooltip: 'Voir',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteSearch(search['id']),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: criteria.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF9800)),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9800),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 4, // Profile tab active
      onTabTapped: (index) {
        if (index != 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParticulierMainScreen(initialIndex: index),
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
            icon: const Icon(Icons.arrow_back, color: Color(0xFF616161)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          title: const Text(
            'Mes recherches sauvegardées',
            style: TextStyle(
              color: Color(0xFF616161),
              fontFamily: 'Manjari',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Gérez vos recherches et recevez des alertes pour les nouvelles annonces correspondantes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Filter Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Date filter button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _selectedDate != null ? 'Filtré' : 'Tri par date',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _selectedDate != null
                                ? Colors.white
                                : const Color(0xFFFF9800),
                            backgroundColor: _selectedDate != null
                                ? const Color(0xFFFF9800)
                                : null,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            side: const BorderSide(color: Color(0xFFFF9800)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Effacer le filtre de date',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sort order buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _setSortOrder('created_at', 'desc'),
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('Plus récents'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _sortBy == 'created_at' && _sortOrder == 'desc'
                                ? const Color(0xFFFF9800)
                                : Colors.white,
                            foregroundColor:
                                _sortBy == 'created_at' && _sortOrder == 'desc'
                                ? Colors.white
                                : const Color(0xFFFF9800),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFFF9800)),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _setSortOrder('created_at', 'asc'),
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          label: const Text('Plus anciens'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _sortBy == 'created_at' && _sortOrder == 'asc'
                                ? const Color(0xFFFF9800)
                                : Colors.white,
                            foregroundColor:
                                _sortBy == 'created_at' && _sortOrder == 'asc'
                                ? Colors.white
                                : const Color(0xFFFF9800),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFFF9800)),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total recherche : ${_savedSearches.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF616161),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedSearches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune recherche sauvegardée',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _savedSearches.length,
                      itemBuilder: (context, index) {
                        final search = _savedSearches[index];
                        return _buildSearchCard(search);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to search or home
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ParticulierMainScreen(initialIndex: 0),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Parcourir les annonces',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
