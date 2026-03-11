# Guide d'intégration Frontend – Bon Plans API

## 1. Vue d'ensemble

- **Base URL API** : `https://api.myreklam.com/api`
- **Authentification** : jeton Bearer (Sanctum). Toutes les routes sont protégées.
- **Format** : JSON pour les requêtes/réponses. Upload média en `multipart/form-data`.
- **Statuts Bon Plan** : `draft`, `pending_review`, `published`, `rejected`.

## 2. Parcours front conseillé

1. Récupérer les métadonnées (catégories, sous-catégories, types, options). `GET /bonplans/meta`
2. Construire le formulaire multi-step côté UI avec ces données dynamiques.
3. Soumettre le bon plan (brouillon ou publication directe). `POST /bonplans`
4. Uploader les médias (images/vidéos). `POST /bonplans/{id}/media`
5. Laisser l'utilisateur modifier avant publication si nécessaire. `PUT /bonplans/{id}`
6. Afficher la fiche après création. `GET /bonplans/{id}`

## 3. Endpoints détaillés

### 3.1 GET /bonplans/meta

Obtient les listes nécessaires pour les sélecteurs.

**Réponse 200**
```json
{
  "categories": {
    "High-Tech": ["Photographie", "Informatique", "Téléphonie", "Audio", "Gaming"],
    "Contact & Jeux vidéo": ["Consoles", "Jeux vidéo", "Accessoires gaming", "PC gaming"],
    "Épicerie & Courses": ["Alimentation", "Boissons", "Produits frais", "Surgelés", "Bio"],
    "Mode & Accessoires": ["Vêtements homme", "Vêtements femme", "Chaussures", "Sacs", "Bijoux", "Montres"],
    "Santé & Cosmetique": ["Soins visage", "Soins corps", "Maquillage", "Parfums", "Compléments alimentaires"],
    "Familles & Enfants": ["Vêtements enfants", "Jouets", "Puériculture", "Livres enfants", "Loisirs créatifs"],
    "Finances & Assurances": ["Banque", "Assurance auto", "Assurance habitation", "Crédit", "Épargne"],
    "Maison & Habitat": ["Meubles", "Décoration", "Électroménager", "Literie", "Cuisine"],
    "Jardin & Bricolage": ["Outillage", "Jardinage", "Piscine", "Barbecue", "Mobilier jardin"],
    "Automobile": ["Pièces auto", "Accessoires auto", "Entretien", "Pneus", "GPS"],
    "Culture & Divertissement": ["Livres", "Musique", "Films", "Spectacles", "Streaming"],
    "Sport & Plein air": ["Fitness", "Running", "Cyclisme", "Sports nautiques", "Camping", "Ski"],
    "Forfait mobiles & internet": ["Forfait mobile", "Box internet", "Téléphonie fixe", "Fibre"],
    "voyage": ["Vols", "Hôtels", "Locations vacances", "Croisières", "Voyages organisés"],
    "Autre": ["Divers"]
  },
  "types": [
    "Code promo",
    "Réduction / Remises",
    "Bon de réduction",
    "Offre spéciale / Vente flash",
    "Gratuit",
    "Infos pouvoir d'achat"
  ],
  "location_options": ["En magasin", "En ligne"],
  "statuses": ["draft", "pending_review", "published", "rejected"]
}
```

### 3.2 POST /bonplans

Crée un bon plan. Tous les champs sont décrits ci-dessous. Passer `status` à `draft` pour sauvegarder sans publication.

**Corps JSON**
```json
{
  "category": "High-Tech",
  "sub_category": "Téléphonie",
  "type": "Code promo",
  "title": "iPhone -20%",
  "description": "Profitez de -20% sur iPhone 15",
  "available_at_name": "Amazon",
  "available_location_type": "En ligne",
  "link": "https://amazon.fr/promo",
  "brand_website": "https://amazon.fr",
  "validity_type": "permanent", // ou "dates"
  "valid_from": null,
  "valid_until": null,
  "location_search": "Paris",
  "nationwide": true,
  "show_google_location": false,
  "pickup_methods": {
    "in_store": false,
    "delivery": true
  },
  "conditions": "Nouveaux membres uniquement",
  "accept_messages": true,
  "status": "published"
}
```

**Réponse 201**
```json
{
  "success": true,
  "data": {
    "id": "a9c8c157-...",
    "status": "published"
  }
}
```

### 3.3 POST /bonplans/{id}/media

Uploader un ou plusieurs fichiers **directement vers le backend** (pas de stockage externe).

- **Méthode** : `multipart/form-data`
- **Paramètres** : `files[]` (obligatoire). Formats : jpg, jpeg, png, gif, mp4, mov.
- **Limites** : 20MB max / fichier.
- **Stockage** : les fichiers sont sauvegardés sur le disque Laravel `public/bon-plans/{bonPlanId}`. L'API renvoie l'URL publique générée par `Storage::disk('public')` (ex: `https://api.myreklam.com/storage/bon-plans/{id}/media.jpg`). Aucune configuration CDN externe n'est nécessaire pour cette phase.

**Réponse 201**
```json
{
  "success": true,
  "media": [
    { "id": "uuid", "url": "https://api.myreklam.com/storage/bon-plans/123/file.jpg", "type": "image" }
  ]
}
```

### 3.4 PUT /bonplans/{id}

Modifie un bon plan appartenant à l'utilisateur. Payload identique à la création (tous les champs `optional`).

**Réponse 200**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "pending_review"
  }
}
```

### 3.5 GET /bonplans/{id}

Retourne les détails complets (y compris médias).

**Réponse 200**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "category": "High-Tech",
    "sub_category": "Téléphonie",
    "type": "Code promo",
    "title": "iPhone -20%",
    "description": "...",
    "available_at_name": "Amazon",
    "available_location_type": "En ligne",
    "link": "https://...",
    "brand_website": "https://amazon.fr",
    "validity_type": "permanent",
    "valid_from": null,
    "valid_until": null,
    "location_search": "Paris",
    "nationwide": true,
    "show_google_location": false,
    "pickup_methods": {
      "in_store": false,
      "delivery": true
    },
    "conditions": "Nouveaux membres uniquement",
    "accept_messages": true,
    "status": "published",
    "media_files": [
      { "id": "uuid", "url": "https://cdn.../iphone.jpg", "type": "image" }
    ],
    "created_at": "2026-02-26T09:12:00Z"
  }
}
```

## 4. Rappels validation côté backend

| Champ | Contraintes |
| --- | --- |
| `category` | requis, doit appartenir à la liste meta |
| `sub_category` | requis, doit exister dans la catégorie sélectionnée |
| `type` | requis, doit être dans la liste meta |
| `title` | requis, min 5 caractères |
| `description` | requis, min 20 caractères |
| `available_at_name` | requis |
| `available_location_type` | requis, `En magasin` ou `En ligne` |
| `validity_type` | `permanent` ou `dates` |
| `valid_from` & `valid_until` | requis si `validity_type = dates`, et `valid_until ≥ valid_from` |
| `pickup_methods` | si présent, au moins un de `in_store` ou `delivery` doit être `true` |
| `accept_messages` | requis (booléen) |
| `status` | optionnel, valeurs : `draft`, `pending_review`, `published`, `rejected` |

## 5. Codes d'erreur

- `401` : Token invalide/expiré.
- `404` : Bon plan introuvable ou non autorisé.
- `422` : Erreurs de validation (renvoie `errors` détaillés par champ).
- `413` : Fichier trop volumineux lors de l'upload média.

**Exemple d'erreur 422**
```json
{
  "success": false,
  "message": "Les données envoyées sont invalides.",
  "errors": {
    "title": ["Le titre doit comporter au moins 5 caractères."],
    "pickup_methods": ["Sélectionnez au moins un mode de retrait."]
  }
}
```

## 6. Bonnes pratiques Frontend

1. **Autosave brouillon** : envoyer `status = "draft"` après chaque étape pour préserver la saisie.
2. **Préparer l'upload** : limiter la taille des fichiers et proposer un compresseur pour les images.
3. **Affichage statuts** : utiliser des badges/coleurs distinctes (ex: brouillon gris, pending jaune, publié vert, rejeté rouge).
4. **Gestion offline** : stocker le brouillon localement si la connexion est instable, puis synchroniser.
5. **Pagination/listing** : côté futur listing, prévoir une pagination par `page` + `per_page`.

---
Ce document peut être partagé directement avec l'équipe mobile/web pour implémenter l'assistant de création de Bon Plans. Toute évolution (nouveau champ ou validation) sera ajoutée ici.
