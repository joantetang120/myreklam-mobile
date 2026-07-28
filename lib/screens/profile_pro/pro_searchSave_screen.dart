import 'package:flutter/material.dart';
import 'package:myreklam/screens/particulier_main_screen.dart';
import 'package:myreklam/services/saved_search_service.dart';

class ProSearchSaveScreen extends StatefulWidget {
  const ProSearchSaveScreen({super.key});

  @override
  State<ProSearchSaveScreen> createState() => _ProSearchSaveScreenState();
}

class _ProSearchSaveScreenState extends State<ProSearchSaveScreen> {
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFEF8A40)),
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
    Navigator.pushAndRemoveUntil(
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
      (route) => false,
    );
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
          'Mes recherches sauvegardées',
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
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 10, bottom: 16),
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Date filter row
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _pickDate,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedDate != null
                                              ? const Color(0xFFEF8A40)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEF8A40),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: _selectedDate != null
                                                  ? Colors.white
                                                  : const Color(0xFFEF8A40),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _selectedDate != null
                                                  ? 'Filtré'
                                                  : 'Tri par date',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: _selectedDate != null
                                                    ? Colors.white
                                                    : const Color(0xFFEF8A40),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectedDate != null) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _clearDateFilter,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: Colors.red,
                                        ),
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
                                    child: GestureDetector(
                                      onTap: () =>
                                          _setSortOrder('created_at', 'desc'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _sortBy == 'created_at' &&
                                                  _sortOrder == 'desc'
                                              ? const Color(0xFFEF8A40)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEF8A40),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_downward,
                                              size: 16,
                                              color:
                                                  _sortBy == 'created_at' &&
                                                      _sortOrder == 'desc'
                                                  ? Colors.white
                                                  : const Color(0xFFEF8A40),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Plus récents',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    _sortBy == 'created_at' &&
                                                        _sortOrder == 'desc'
                                                    ? Colors.white
                                                    : const Color(0xFFEF8A40),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          _setSortOrder('created_at', 'asc'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _sortBy == 'created_at' &&
                                                  _sortOrder == 'asc'
                                              ? const Color(0xFFEF8A40)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFEF8A40),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_upward,
                                              size: 16,
                                              color:
                                                  _sortBy == 'created_at' &&
                                                      _sortOrder == 'asc'
                                                  ? Colors.white
                                                  : const Color(0xFFEF8A40),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Plus anciens',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    _sortBy == 'created_at' &&
                                                        _sortOrder == 'asc'
                                                    ? Colors.white
                                                    : const Color(0xFFEF8A40),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Total recherche : ${_savedSearches.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _savedSearches.length,
                          itemBuilder: (context, index) {
                            final search = _savedSearches[index];
                            return _buildSearchCard(search);
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParticulierMainScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF8A40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Parcourir les anonces',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon, bool isOutlined) {
    if (isOutlined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFFEF8A40).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEF8A40)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFEF8A40)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFEF8A40),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEF8A40),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> search) {
    final tags = <String>[];

    if (search['search_query'] != null &&
        search['search_query'].toString().isNotEmpty) {
      tags.add('Terme: ${search['search_query']}');
    }
    if (search['category'] != null) {
      tags.add('Catégorie: ${search['category']}');
    }
    if (search['location_address'] != null &&
        search['location_address'].toString().isNotEmpty) {
      final city = search['location_city'] ?? '';
      final postalCode = search['location_postal_code'] ?? '';
      if (city.isNotEmpty || postalCode.isNotEmpty) {
        tags.add('Lieu: ${search['location_address']} ($postalCode)');
      } else {
        tags.add('Lieu: ${search['location_address']}');
      }
    }
    if (search['search_radius'] != null && search['search_radius'] > 0) {
      tags.add('Rayon: ${search['search_radius']}km');
    }
    if (search['search_all_france'] == true) {
      tags.add('Zone: Toute la France');
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    search['name'] ?? 'Recherche',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333).withValues(alpha: 0.5),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _viewSearch(search),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteSearch(search['id']),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF44336),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFEF8A40).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFEF8A40)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFFEF8A40),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
