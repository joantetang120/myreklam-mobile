/// Formats announcement addresses consistently across detail screens & feed.
///
/// Rules:
///  - street + postal + city  → "59 rue des platanes 54300 REHAINVILLER"
///  - postal + city           → "54300 REHAINVILLER"
///  - city only               → "REHAINVILLER"
/// City is always upper-cased; empty/missing parts are skipped. Returns '' when
/// nothing usable is provided.
class AddressFormatter {
  static String format({String? address, String? postalCode, String? city}) {
    final street = (address ?? '').trim();
    final cp = (postalCode ?? '').trim();
    final town = (city ?? '').trim();

    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (cp.isNotEmpty) parts.add(cp);
    if (town.isNotEmpty) parts.add(town.toUpperCase());
    return parts.join(' ');
  }

  /// A geocoding query string for the map (street + postal + city + country).
  static String query({String? address, String? postalCode, String? city}) {
    final parts = <String>[
      if ((address ?? '').trim().isNotEmpty) address!.trim(),
      if ((postalCode ?? '').trim().isNotEmpty) postalCode!.trim(),
      if ((city ?? '').trim().isNotEmpty) city!.trim(),
    ];
    if (parts.isEmpty) return '';
    return '${parts.join(', ')}, France';
  }
}
