# Mise à jour forcée

L'application vérifie Firebase Remote Config avant d'afficher le splash de
connexion. Si la version installée est inférieure à la version minimale active,
un écran non fermable redirige l'utilisateur vers le store.

## Paramètres Firebase Remote Config

| Clé | Type | Exemple |
| --- | --- | --- |
| `force_update_android` | Booléen | `true` |
| `minimum_android_build_number` | Nombre | `12` |
| `android_store_url` | Texte | `https://play.google.com/store/apps/details?id=com.myreklam.app` |
| `force_update_ios` | Booléen | `true` |
| `minimum_ios_build_number` | Nombre | `12` |
| `ios_store_url` | Texte | `https://apps.apple.com/app/idVOTRE_APP_ID` |
| `force_update_title` | Texte | `Mise à jour requise` |
| `force_update_message` | Texte | Message affiché à l'utilisateur |

Le build actuellement déclaré dans `pubspec.yaml` est `11`
(`version: 1.0.6+11`).

## Activation

1. Publier la nouvelle version sur Google Play et/ou l'App Store.
2. Renseigner l'URL exacte du store et son nouveau numéro de build.
3. Publier les paramètres Remote Config.
4. Activer `force_update_android` ou `force_update_ios`.

Toujours publier la nouvelle application sur le store avant d'activer le
blocage. Pour désactiver immédiatement la mise à jour forcée, remettre le
booléen de la plateforme à `false` et publier la configuration.
