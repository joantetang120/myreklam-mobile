import 'package:flutter/material.dart';
import 'package:myreklam/theme/theme_controller.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key, this.controller});
  final ThemeController? controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller ?? ThemeController.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        children: [
          const ListTile(
            leading: Icon(Icons.brightness_6_outlined),
            title: Text('Apparence'),
            subtitle: Text('Automatique : suit le thème du téléphone'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<ThemeMode>(
              isExpanded: true,
              value: settings.mode,
              onChanged: settings.saving
                  ? null
                  : (mode) async {
                      if (mode == null) return;
                      try {
                        await settings.setMode(mode);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Impossible de mémoriser le thème. Réessayez.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Automatique'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
