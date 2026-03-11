# Système de Récompenses My's

## Vue d'ensemble

Le système de récompenses My's encourage les utilisateurs à être actifs sur la plateforme en les récompensant pour diverses actions. Les utilisateurs gagnent des **My's** pour chaque action accomplie.

## Fonctionnalités

### 1. Guide d'Onboarding (`OnboardingGuide`)

Le guide s'affiche automatiquement dans le dashboard et montre :
- **Progression visuelle** : Barre de progression avec pourcentage
- **Liste des étapes** : Chaque étape avec son statut (complétée ou non)
- **Récompenses** : Nombre de My's gagnés pour chaque étape

#### Étapes pour les Particuliers (2 My's total) :
- ✅ Pseudo (+0.5 My's)
- ✅ Téléphone (+0.5 My's)
- ✅ Photo de profil (+0.5 My's)
- ✅ Présentation (+0.5 My's)

#### Étapes supplémentaires pour les Professionnels :
- ✅ Infos entreprise (bonus de complétion)
- ✅ Réseaux sociaux (bonus de complétion)

**Total possible :**
- Particuliers : 2 My's
- Professionnels : 2 My's

### 2. Guide des Récompenses (`RewardsGuide`)

Un guide complet affichant toutes les actions possibles pour gagner des My's :

#### Actions disponibles :

| Action | Description | Récompense |
|--------|-------------|------------|
| ✅ **Compléter son profil** | Un profil complet, c'est toujours plus avantageux | **2 My's** |
| 📢 **Publication d'une annonce** | Publiez une annonce et recevez une récompense immédiate | **2 My's** |
| 💬 **Commenter une annonce** | Laissez un commentaire et gagnez des points | **1 My's** |
| ⭐ **Laisser un avis** | Donnez votre avis sur une entreprise | **1 My's** |
| 📲 **Recommander une annonce** | Partagez une annonce sur vos réseaux | **1 My's** |
| 📩 **Postuler à une offre** | Postulez à une offre d'emploi ou de formation | **1 My's** |
| 📆 **Participer à un événement** | Inscrivez-vous à un événement | **1 My's** |
| 👥 **Parrainage particulier** | Parrainez un particulier | **2 My's** |
| 🎁 **Parrainage entreprise gratuite** | Parrainez une entreprise (version gratuite) | **2 My's** |
| 🚀 **Parrainage entreprise Premium** | Parrainez une entreprise Premium | **5 My's** |

**Total maximum possible : 18 My's** (hors parrainages multiples)

### 3. Popup de Récompense (`RewardPopup`)

Lorsqu'un utilisateur complète une étape, un popup animé apparaît avec :
- 🎉 Animation de confettis
- 💰 Montant de My's gagnés
- ✨ Message de félicitations
- 🎨 Design moderne avec gradients

Le popup :
- S'affiche automatiquement lors de la complétion d'une étape
- Se ferme automatiquement après 5 secondes
- Peut être fermé manuellement par l'utilisateur

## Comment ça fonctionne

### Détection des étapes complétées

Le système vérifie automatiquement :
1. **Au chargement du dashboard** : Compare les données actuelles avec les étapes enregistrées
2. **Nouvelles complétions** : Détecte les étapes nouvellement complétées
3. **Récompenses** : Déclenche le popup pour chaque nouvelle étape

### Stockage local

Les étapes complétées sont sauvegardées dans `localStorage` :
```javascript
localStorage.getItem("completedOnboardingSteps") // ["pseudo", "phone", "photo"]
```

Cela permet de :
- Ne pas récompenser deux fois la même étape
- Garder la trace de la progression
- Afficher correctement l'état du guide

## Utilisation

### Dans le Dashboard

Le guide s'affiche automatiquement si :
- L'utilisateur est connecté
- Toutes les étapes ne sont pas complétées
- Le guide n'a pas été fermé manuellement

### Fermer le guide

L'utilisateur peut fermer le guide en cliquant sur le bouton ❌ en haut à droite. Le guide peut être réaffiché en rechargeant la page.

## Personnalisation

### Ajouter une nouvelle étape

Dans `components/dashboard/onboarding-guide.tsx` :

```typescript
{
  id: "nouvelle_etape",
  title: "Titre de l'étape",
  description: "Description de l'étape",
  icon: IconComponent,
  completed: !!userData?.champ_a_verifier,
  reward: 20 // Nombre de My's
}
```

### Modifier les récompenses

Changez simplement la valeur `reward` dans la définition de l'étape.

### Personnaliser le popup

Modifiez `components/dashboard/reward-popup.tsx` pour changer :
- Les couleurs (gradients)
- Les animations (framer-motion)
- La durée d'affichage (timeout)
- Les effets de confettis

## Dépendances

- `framer-motion` : Animations du popup
- `canvas-confetti` : Effet de confettis
- `lucide-react` : Icônes
- Composants shadcn/ui : Card, Button, Progress, Badge

## Notes techniques

- Le guide se met à jour automatiquement quand `userData` change
- Les récompenses sont déclenchées avec un délai de 500ms pour une meilleure UX
- Le popup utilise un z-index élevé (9999) pour s'afficher au-dessus de tout
- Les confettis sont optimisés pour ne pas surcharger le navigateur

## Améliorations futures possibles

- 💾 Sauvegarder les My's dans la base de données
- 🏆 Système de badges pour les profils 100% complétés
- 📊 Statistiques de progression dans le profil
- 🎁 Récompenses bonus pour complétion rapide
- 📧 Notifications email pour encourager la complétion
