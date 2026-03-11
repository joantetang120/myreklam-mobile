# Guide d'intégration Frontend – Offres d'emploi

## 1. Vue d'ensemble
- **Base URL** : `https://api.myreklam.com/api`
- **Auth** : Token Bearer (Sanctum). Toutes les routes `pro/job-offers` requièrent un utilisateur PRO connecté.
- **Flux général** :
  1. Charger les métadonnées (catégories, fonctions, enums).
  2. Uploader les médias (images/vidéos) vers le backend pour obtenir des `media_ids`.
  3. Construire les 5 étapes du formulaire côté app.
  4. Soumettre l'offre complète (`POST /pro/job-offers`).
  5. Consulter l'offre (`GET /pro/job7-offers/{id}`) si besoin.

## 2. Métadonnées dynamiques
### GET `/api/pro/job-offers/meta`
Réponse 200 :
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "Informatique",
        "functions": [
          { "id": 12, "job_category_id": 1, "name": "Développeur" },
          { "id": 13, "job_category_id": 1, "name": "DevOps" }
        ]
      },
      {
        "id": 2,
        "name": "Marketing",
        "functions": [ { "id": 15, "job_category_id": 2, "name": "Community Manager" } ]
      }
    ],
    "contract_types": ["CDI", "CDD", "FREELANCE", ...],
    "work_times": ["FULL_TIME", "PART_TIME", ...],
    "salary_types": ["RANGE", "EXACT", "DEPENDING_ON_PROFILE"],
    "salary_periods": ["YEAR", "MONTH", "DAY", "HOUR"],
    "availability_types": ["IMMEDIATE", "FROM_DATE"],
    "advantages": ["TRANSPORT", "MEAL_VOUCHERS", ...],
    "education_levels": ["NONE", "CAP", ... "DOCTORATE"],
    "experience_levels": ["JUNIOR", "1_3_YEARS", ... "EXPERT"],
    "statuses": ["DRAFT", "PENDING_REVIEW", "PUBLISHED", "REJECTED", "ARCHIVED"]
  }
}
```
**UI** : stocker ces valeurs en mémoire locale et les recharger périodiquement, jamais hardcoder.

## 3. Upload des médias
### POST `/api/pro/job-offers/media`
- **Form-data** : `files[]` (1..n fichiers). Formats: `jpg,jpeg,png,gif,mp4,mov`. Taille max 20 MB / fichier.
- **Stockage** : backend sauvegarde dans `storage/app/public/job-offers/{userId}` et renvoie l'URL publique (`/storage/...`).

Réponse 201 :
```json
{
  "success": true,
  "media": [
    { "id": "6d6c...", "url": "https://api.myreklam.com/storage/job-offers/42/photo.jpg", "type": "image" }
  ]
}
```
Conserver les `media[].id` pour les passer dans `media_ids` lors de la création.

## 4. Création d'une offre
### POST `/api/pro/job-offers`
Headers: `Authorization: Bearer {token}`

Payload JSON :
```json
{
  "category_id": 1,
  "function_id": 12,
  "external_link": "https://entreprise.com/job/123",

  "title": "Développeur Flutter Senior",
  "description": "Nous recherchons...",
  "contract_type": "CDI",
  "work_time": "FULL_TIME",

  "salary": {
    "type": "RANGE",
    "min": 35000,
    "max": 45000,
    "currency": "EUR",
    "is_gross": true,
    "period": "YEAR"
  },

  "availability": {
    "type": "FROM_DATE",
    "start_date": "2026-04-01",
    "end_date": null
  },

  "advantages": ["TRANSPORT", "REMOTE_WORK"],
  "telework_possible": true,

  "location": {
    "country": "FR",
    "city": "Paris",
    "region": "Île-de-France",
    "nationwide": false,
    "show_google_map": true
  },

  "company": {
    "name": "Tech Solutions",
    "website": "https://techsolutions.com",
    "show_company_profile": true
  },

  "profile": {
    "education_level": "MASTER",
    "experience_level": "3_5_YEARS",
    "description": "Autonome, esprit d'équipe..."
  },

  "accept_messages": true,
  "media_ids": ["6d6c..."]
}
```

Réponse 201 :
```json
{
  "success": true,
  "message": "Offre d'emploi créée avec succès",
  "data": {
    "id": "c4ab...",
    "status": "PENDING_REVIEW"
  }
}
```

## 5. Récupération d'une offre
### GET `/api/pro/job-offers/{id}`
- Vérifie que l'offre appartient à l'utilisateur courant.
- Renvoie toutes les sections prêtes pour l'affichage (catégorie, fonction, salaire détaillé, avantages, médias, etc.).

Réponse 200 (extrait) :
```json
{
  "success": true,
  "data": {
    "id": "c4ab...",
    "category": { "id": 1, "name": "Informatique" },
    "function": { "id": 12, "name": "Développeur" },
    "title": "Développeur Flutter Senior",
    "salary": {
      "type": "RANGE",
      "min": "35000.00",
      "max": "45000.00",
      "currency": "EUR",
      "is_gross": true,
      "period": "YEAR"
    },
    "advantages": ["TRANSPORT", "REMOTE_WORK"],
    "media_files": [
      { "id": "6d6c...", "url": "https://api.myreklam.com/storage/job-offers/42/photo.jpg", "type": "image" }
    ],
    "status": "PENDING_REVIEW"
  }
}
```

## 6. Validation backend (résumé)
| Champ | Contrôle |
| --- | --- |
| `category_id`, `function_id` | requis, existent en base, fonction doit appartenir à la catégorie |
| `title` | requis, max 150 caractères |
| `description` | requis |
| `contract_type`, `work_time` | requis, doivent être dans les listes meta |
| `salary.type` | requis, + règles : `min` & `max` selon `type`, `period` requis sauf `DEPENDING_ON_PROFILE`, `max >= min` |
| `availability` | `type` requis, `start_date` requis si `FROM_DATE`, `end_date >= start_date` |
| `location.country` | requis |
| `profile.education_level` / `experience_level` | requis, dans les listes meta |
| `advantages.*` | doivent figurer dans la liste autorisée |
| `media_ids.*` | UUID appartenant à l'utilisateur (upload préalable) |

Erreurs 422 :
```json
{
  "success": false,
  "message": "Les données envoyées sont invalides.",
  "errors": {
    "function_id": ["La fonction ne correspond pas à la catégorie sélectionnée."],
    "salary.max": ["Le montant maximum est requis pour une plage."]
  }
}
```

## 7. Recommandations UX
1. **Autosave** : Conserver localement les champs par étape (catégorie, lien, description, profil, médias) puis envoyer un bloc unique.
2. **Feedback sur médias** : afficher des vignettes dès la réponse `media` pour confirmer l'upload local.
3. **Validation progressive** : avant d'envoyer l'offre, vérifier côté app les contraintes principales (longueur titre, type de salaire, dates).
4. **Statuts** : badge couleur (brouillon gris, pending jaune, publié vert, rejeté rouge). Aujourd'hui le backend force `PENDING_REVIEW` à la création.
5. **Suppression / édition** : non couvert ici ; prévoir plus tard un endpoint update/archive.

## 8. Checklist côté frontend
- [ ] Appeler `GET /pro/job-offers/meta` au démarrage.
- [ ] Empêcher l'accès à la création si l'utilisateur n'est pas PRO (ou forcer upgrade).
- [ ] Limiter la taille des fichiers avant upload et informer l'utilisateur.
- [ ] Utiliser `media_ids` exacts renvoyés par l'API.
- [ ] Sur échec 401, rediriger vers login.
- [ ] Sur 422, afficher les messages de `errors` champ par champ.
- [ ] Sur succès, afficher un écran de confirmation avec le statut `PENDING_REVIEW` et proposer de consulter le détail.

---
Ce guide peut être remis tel quel à l'équipe mobile/web pour intégrer la création d'offres d'emploi. Toute évolution backend (nouvelles enums, update endpoints) sera ajoutée dans ce fichier.
