import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myreklam/services/announcement_ai_service.dart';
import 'package:myreklam/services/api_client.dart';
import 'package:myreklam/utils/gallery_picker.dart';
import 'package:myreklam/models/location_data.dart';

LocationData? announcementAiLocation(Map<String, dynamic> fields) {
  final street = fields['locationAddress']?.toString().trim();
  final city = fields['locationCity']?.toString().trim();
  final address = street != null && street.isNotEmpty ? street : city;
  if (address == null || address.isEmpty) return null;
  return LocationData(
    address: address,
    city: city,
    postalCode: fields['locationPostalCode']?.toString(),
  );
}

/// Shared image/link analysis. All AI credentials remain on the backend.
class AnnouncementAiPanel extends StatefulWidget {
  final String kind;
  final void Function(Map<String, dynamic>, List<GalleryMedia>) onResult;
  final Map<String, List<String>> Function()? categories;
  final TextEditingController? linkController;
  final AnnouncementAiService? service;
  const AnnouncementAiPanel({
    super.key,
    required this.kind,
    required this.onResult,
    this.categories,
    this.linkController,
    this.service,
  });
  @override
  State<AnnouncementAiPanel> createState() => _AnnouncementAiPanelState();
}

class _AnnouncementAiPanelState extends State<AnnouncementAiPanel> {
  late final AnnouncementAiService _service =
      widget.service ?? AnnouncementAiService();
  bool _busy = false;
  String? _message;
  GalleryMedia? _image;
  Future<void> _analyze({required bool fromImage}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      GalleryMedia? image;
      if (fromImage) {
        final selected = await GalleryPicker.pickImagesFromGallery(
          allowMultiple: false,
        );
        if (!mounted || selected == null || selected.isEmpty) return;
        image = selected.first;
        setState(() => _image = image);
      }
      final result = await _service.extract(
        kind: widget.kind,
        url: widget.linkController?.text.trim(),
        image: image,
        categories: widget.categories?.call() ?? {},
      );
      if (!mounted) return;
      final apply = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Appliquer les informations ?'),
          content: const Text(
            'Les champs récupérés remplaceront les valeurs correspondantes. Vérifiez les informations avant publication.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      );
      if (!mounted || apply != true) return;
      final images = <GalleryMedia>[if (image != null) image];
      final warnings = [...result.warnings];
      try {
        images.addAll(await _service.materializeImages(result.media));
      } catch (_) {
        warnings.add(
          'Les photos récupérées n’ont pas pu être chargées. Ajoutez-les manuellement.',
        );
      }
      if (result.media.isNotEmpty && images.isEmpty)
        warnings.add('Aucune photo valide. Ajoutez une image manuellement.');
      if (!mounted) return;
      widget.onResult(result.fields, images);
      setState(
        () => _message = [
          'Informations récupérées. Vérifiez chaque étape avant de publier.',
          ...warnings,
          if (result.missingFields.isNotEmpty)
            'Certains champs restent à compléter.',
        ].join('\n'),
      );
    } on TimeoutException {
      if (mounted)
        setState(() => _message = 'L’analyse dépasse deux minutes. Réessayez.');
    } on ApiException catch (e) {
      if (mounted)
        setState(
          () => _message = e.statusCode == 429
              ? 'Trop de demandes. Réessayez dans une minute.'
              : e.firstError,
        );
    } catch (_) {
      if (mounted)
        setState(
          () => _message =
              'Impossible de terminer l’analyse. Vérifiez votre connexion puis réessayez.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xffeafaf5),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Préremplir avec l’IA',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Importez une affiche, une photo ou le lien de votre annonce. Vous gardez la main sur tous les champs.',
          ),
          if (widget.linkController != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: widget.linkController,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Lien de la page',
                hintText: 'https://…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _analyze(fromImage: false),
              icon: const Icon(Icons.link),
              label: const Text('Analyser le lien'),
            ),
          ],
          if (_image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_image!.path),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            Text(_image!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : () => _analyze(fromImage: true),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _busy ? 'Analyse en cours…' : 'Choisir une image et analyser',
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    ),
  );
}
