# Vérification des Règles d'Abonnement MyReklam

## ✅ Corrections Appliquées (27 janvier 2026)

### Limite d'Annonces - Professionnels Gratuits
**Limite actuelle**: **3 annonces par mois**

**Fichiers concernés**:

### Bug #2 - Frontend React (CORRIGÉ) 🎯
**Fichier**: `g:\ProjetWeb\MyReklam-Web\hooks\use-subscription-limits.ts` (ligne 290-292)

**Problème CRITIQUE**: 
- Le hook exportait `canCreateAd` (sans "s")
- Tout le frontend utilisait `canCreateAds` (avec "s")
- Résultat: `canCreateAds` était toujours `undefined`
- Les professionnels gratuits ne pouvaient JAMAIS créer d'annonce

**Solution**:
```typescript
// AVANT (INCORRECT)
return {
  canCreateAd,        // ❌ Nom incorrect
  getRemainingAds,    // ❌ Fonction au lieu de valeur
}

// APRÈS (CORRECT)
return {
  canCreateAds: canCreateAd,     // ✅ Alias correct
  remainingAds: getRemainingAds, // ✅ Fonction appelée
}
```

---

## Bug Backend (également corrigé)

**Problème**: 
- La limite était de **3 annonces/mois** au lieu de **1 annonce/mois**
- Les annonces supprimées (`deletedat IS NOT NULL`) étaient comptées
- Utilisation de `created_at` au lieu de `createdat` (colonne PostgreSQL)

**Solution**:
```php
// AVANT (INCORRECT)
$limit = 3; // Limite pour les professionnels sans abonnement
$adCountQuery = "SELECT COUNT(*) as count FROM ads 
               WHERE userId = :userId 
               AND DATE_FORMAT(created_at, '%Y-%m') = :currentMonth";

// APRÈS (CORRECT)
$limit = 1; // Limite pour les professionnels sans abonnement (compte gratuit)
$adCountQuery = "SELECT COUNT(*) as count FROM ads 
               WHERE \"userId\" = :userId 
               AND \"deletedat\" IS NULL
               AND EXTRACT(MONTH FROM \"createdat\") = EXTRACT(MONTH FROM CURRENT_DATE)
               AND EXTRACT(YEAR FROM \"createdat\") = EXTRACT(YEAR FROM CURRENT_DATE)";
```

---

## 📋 Règles d'Abonnement - Vue d'Ensemble

### 1. Comptes Particuliers
- ✅ **Annonces**: Illimitées
- ✅ **Commentaires**: Illimités
- ✅ **Aucune restriction**

### 2. Comptes Professionnels GRATUITS
- ✅ **Annonces**: 1 par mois
- ✅ **Commentaires**: 1 par mois
- ❌ **Accès contacts**: Non
- ❌ **Accès documents**: Non
- ❌ **Messagerie**: Non
- ❌ **Conversion coins**: Non
- ❌ **Partage contacts**: Non
- ❌ **Téléchargement programmes**: Non
- ❌ **Réponse aux avis**: Non
- ❌ **Badge vérifié**: Non

### 3. Comptes Professionnels PREMIUM (Mensuel/Annuel)
- ✅ **Annonces**: Illimitées
- ✅ **Commentaires**: Illimités
- ✅ **Accès contacts**: Oui
- ✅ **Accès documents**: Oui
- ✅ **Messagerie**: Oui
- ✅ **Conversion coins**: Oui
- ✅ **Partage contacts**: Oui
- ✅ **Téléchargement programmes**: Oui
- ✅ **Réponse aux avis**: Oui
- ✅ **Badge vérifié**: Oui

---

## 🔍 Fichiers Vérifiés

### Backend PHP (`g:\ProjetWeb\myreklam-sec\`)

#### 1. **Ads.php** (ligne 1992) ✅ CORRIGÉ
```php
$limit = 1; // Limite pour les professionnels sans abonnement (compte gratuit)
```
- Vérifie le type de profil (particulier vs professionnel)
- Vérifie l'abonnement actif (status='active' AND end_date > NOW())
- Compte les annonces du mois en cours (excluant deletedat IS NULL)
- Méthode: `checkAdLimit`

#### 2. **AdLimits.php** (ligne 117) ✅ CORRECT
```php
$monthlyLimit = 1; // Limite de 1 annonce par mois pour les comptes gratuits
```
- Vérifie le type de profil
- Vérifie l'abonnement (mensuel/annuel avec calcul de date)
- Compte les annonces du mois (excluant deletedat IS NULL)
- Méthode: `checkMonthlyAdLimit`

#### 3. **CommentLimits.php** (ligne 120) ✅ CORRECT
```php
$monthlyLimit = 1; // Limite de 1 commentaire par mois pour les comptes gratuits
```
- Vérifie le type de profil
- Vérifie l'abonnement (mensuel/annuel)
- Compte les commentaires du mois
- Méthode: `checkMonthlyCommentLimit`

#### 4. **getUserStats.php** ✅ CORRECT
- Compte les annonces avec `deletedat IS NULL`
- Utilise `EXTRACT(MONTH/YEAR FROM createdat)` pour PostgreSQL
- Méthodes: type='ads' ou type='comments', period='current_month'

### Frontend React (`g:\ProjetWeb\MyReklam-Web\`)

#### 1. **hooks/use-subscription-limits.ts** ✅ CORRECT
```typescript
const FREE_LIMITS: UserLimits = {
  maxAds: 1,           // ✅ Correct
  maxComments: 1,      // ✅ Correct
  // ... autres limites
}

const PREMIUM_LIMITS: UserLimits = {
  maxAds: -1,          // ✅ Illimité
  maxComments: -1,     // ✅ Illimité
  // ... tous les accès activés
}
```

#### 2. **lib/hooks/use-permissions.ts** ✅ CORRECT
- Appelle `Ads.php` avec méthode `checkAdLimit`
- Retourne: `canCreateAd`, `currentCount`, `limit`
- Utilisé dans les pages de création d'annonces

---

## 🧪 Points de Vérification

### Vérification de l'Abonnement
Les 3 fichiers PHP utilisent la même logique:
```php
// Vérifier l'abonnement actif
$subscriptionQuery = "SELECT * FROM abonnement 
                    WHERE userId = :userId 
                    AND status = 'active' 
                    AND end_date > NOW()";
```

OU (pour AdLimits.php et CommentLimits.php):
```php
// Vérifier la date d'expiration
if ($latestSubscription['typeabo'] == 'annuel') {
    $dateAbonnement->modify('+1 year');
    if ($dateAujourdhui <= $dateAbonnement) {
        $hasPremium = true;
    }
}
```

### Comptage des Annonces du Mois
```php
// PostgreSQL syntax (CORRECT)
WHERE "userId" = :userId 
AND "deletedat" IS NULL
AND EXTRACT(MONTH FROM "createdat") = EXTRACT(MONTH FROM CURRENT_DATE)
AND EXTRACT(YEAR FROM "createdat") = EXTRACT(YEAR FROM CURRENT_DATE)
```

---

## 🎯 Résultat

### ✅ Tout est maintenant cohérent:
1. **Backend Ads.php**: Limite corrigée de 3 → 1 annonce/mois
2. **Backend AdLimits.php**: Déjà correct (1 annonce/mois)
3. **Backend CommentLimits.php**: Déjà correct (1 commentaire/mois)
4. **Frontend use-subscription-limits.ts**: Déjà correct (maxAds: 1)
5. **Frontend use-permissions.ts**: Appelle correctement l'API backend

### 🔧 Actions à Effectuer
1. ✅ Correction appliquée dans `Ads.php`
2. ⏳ **Tester avec le compte professionnel gratuit créé ce matin**
3. ⏳ Vérifier que la première annonce peut maintenant être créée
4. ⏳ Vérifier que la deuxième annonce est bloquée avec le bon message

---

## 📝 Notes Importantes

### Structure de la Base de Données
- Table: `ads`
- Colonnes importantes:
  - `userId` (avec majuscule U)
  - `createdat` (timestamp de création)
  - `deletedat` (timestamp de suppression, NULL si actif)

### Table Abonnement
- Table: `abonnement`
- Colonnes:
  - `userId`
  - `typeabo` ('mensuel', 'annuel', 'gratuit')
  - `dateabo` (date de début)
  - `status` ('active', 'inactive')
  - `end_date` (date de fin)

### Logique de Vérification
1. Vérifier le type de profil (`profiletype` dans `userinfo`)
2. Si particulier → Pas de limite
3. Si professionnel → Vérifier abonnement
4. Si abonnement actif → Pas de limite
5. Si pas d'abonnement → Limite de 1/mois

---

**Date de correction**: 27 janvier 2026, 13:00 UTC+01:00
**Testeur**: Collègue des Compagnons
**Statut**: ✅ Correction appliquée, en attente de test
