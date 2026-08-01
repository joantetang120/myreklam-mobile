import 'package:myreklam/constants/api_label_dictionary.g.dart';

/// Entry point for turning an API code into French display text.
///
/// Resolution order used across the app:
/// 1. the curated table for the field (natures, sub-categories, job enums...),
/// 2. [lookup] in the dictionary shared with the web app,
/// 3. [humanize], so an unknown code is never shown verbatim.
///
/// Step 2 is what keeps mobile and web in sync: both read the same labels, so a
/// training sector shows "Second œuvre" here exactly as it does on the website.
class ApiLabels {
  const ApiLabels._();

  /// Case-insensitive index over [kApiLabelDictionary], built on first use.
  static final Map<String, String> _byLowerCaseKey = {
    for (final entry in kApiLabelDictionary.entries)
      entry.key.toLowerCase(): entry.value,
  };

  /// French label for [code] from the shared dictionary, or null when unknown.
  static String? lookup(String? code) {
    if (code == null) return null;
    final raw = code.trim();
    if (raw.isEmpty) return null;
    return kApiLabelDictionary[raw] ?? _byLowerCaseKey[raw.toLowerCase()];
  }

  /// Dictionary lookup, falling back to [humanize].
  static String resolve(String value) => lookup(value) ?? humanize(value);

  /// Turns a raw API code (`secteur_realEstate`, `FinishingWorks`) into readable
  /// text. Last resort only: the result stays in the code's own language, so a
  /// hit in [lookup] is always preferable.
  static String humanize(String value) {
    final spaced = value
        .trim()
        .replaceAll(RegExp(r'^secteur[_-]'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-zà-ÿ])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ');
    if (spaced.isEmpty) return value;
    return '${spaced[0].toUpperCase()}${spaced.substring(1).toLowerCase()}';
  }
}
