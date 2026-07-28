# Mise à jour obligatoire via Google Play

MyReklam utilise l’API officielle Google Play In-App Updates. Au démarrage,
l’application demande directement à Google Play si une version plus récente est
disponible pour l’utilisateur.

Lorsqu’une mise à jour est disponible :

- l’accès à l’application reste bloqué ;
- le bouton lance le flux Android de mise à jour immédiate ;
- si le flux immédiat n’est pas autorisé, le bouton ouvre la fiche Google Play ;
- aucune valeur Firebase ou backend ne doit être modifiée.

## Publication

1. Augmenter le `versionCode` dans `pubspec.yaml`.
2. Générer et téléverser le nouveau bundle sur Google Play.
3. Publier la version sur le canal souhaité.

Google Play détermine automatiquement quels utilisateurs disposent d’une mise à
jour. Pendant un déploiement progressif, seuls les utilisateurs inclus dans le
déploiement la verront.

## Test

Le mécanisme ne fonctionne pas avec un APK installé par câble ou avec
`flutter run`. Il doit être testé avec une application installée depuis Google
Play, idéalement via le partage interne d’applications ou une piste de test
interne, puis avec un second bundle ayant un `versionCode` supérieur.
