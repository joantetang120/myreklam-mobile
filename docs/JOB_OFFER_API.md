# Job Offer API Documentation

## Overview
This document describes the API endpoints required for creating and managing job offers (Offres d'emploi) in the MyReklam application.

---

## Authentication
All endpoints require Bearer token authentication (Laravel Sanctum).

```
Authorization: Bearer {token}
```

---

## Endpoints

### 1. Create Job Offer

**POST** `/api/job-offers`

Creates a new job offer.

#### Request Headers
```
Content-Type: application/json
Authorization: Bearer {token}
```

#### Request Body

```json
{
  "category": "string (required)",
  "function": "string (required)",
  "link": "string|null (optional)",
  "title": "string (required)",
  "description": "string (required)",
  "contract_type": "string (required)",
  "work_time": "string (required)",
  "salary_type": "string (required)",
  "salary_min": "number|null (conditional)",
  "salary_max": "number|null (conditional)",
  "salary_exact": "number|null (conditional)",
  "salary_payment_type": "string|null (conditional)",
  "salary_period": "string|null (conditional)",
  "availability_type": "string (required)",
  "available_from": "date|null (conditional)",
  "available_until": "date|null (optional)",
  "advantages": ["string"] (optional),
  "remote_work": "boolean (optional, default: false)",
  "location": "string|null (optional)",
  "all_france": "boolean (optional, default: false)",
  "show_google_location": "boolean (optional, default: false)",
  "company_name": "string (required)",
  "show_company_presentation": "boolean (optional, default: false)",
  "company_website": "string|null (optional)",
  "education_level": "string (required)",
  "experience_level": "string (required)",
  "profile_description": "string|null (optional)",
  "accept_messages": "boolean (required)"
}
```

#### Example Request

```json
{
  "category": "Informatique",
  "function": "Développeur",
  "link": "https://example.com/job-details",
  "title": "Développeur Full Stack",
  "description": "Nous recherchons un développeur full stack expérimenté...",
  "contract_type": "cdi",
  "work_time": "temps_plein",
  "salary_type": "tranche_salariale",
  "salary_min": 35000,
  "salary_max": 45000,
  "salary_payment_type": "brut",
  "salary_period": "annuel",
  "availability_type": "immediatement",
  "available_from": null,
  "available_until": "2025-06-30",
  "advantages": ["Titre restaurant", "RTT", "Télétravail"],
  "remote_work": true,
  "location": "Paris",
  "all_france": false,
  "show_google_location": true,
  "company_name": "Tech Company SAS",
  "show_company_presentation": true,
  "company_website": "https://techcompany.fr",
  "education_level": "bac_plus_5",
  "experience_level": "3_5_ans",
  "profile_description": "Profil recherché avec expérience en React et Node.js...",
  "accept_messages": true
}
```

#### Response (Success - 201)

```json
{
  "success": true,
  "message": "Offre d'emploi créée avec succès",
  "data": {
    "id": 123,
    "status": "pending_review",
    "created_at": "2025-02-27T10:00:00Z"
  }
}
```

#### Response (Error - 422)

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "title": ["Le champ titre est obligatoire."],
    "category": ["La catégorie sélectionnée est invalide."]
  }
}
```

---

### 2. Get Job Offer Metadata

**GET** `/api/job-offers/meta`

Returns all available options for dropdowns and select fields.

#### Request Headers
```
Authorization: Bearer {token}
```

#### Response (Success - 200)

```json
{
  "success": true,
  "data": {
    "categories": {
      "Achatrs": ["Acheteur", "Approvisionneur", "Responsable achats"],
      "Administratif": ["Assistant administratif", "Secrétaire", "Agent administratif", "Gestionnaire administratif"],
      "Aeronautique": ["Ingénieur aéronautique", "Technicien aéronautique", "Pilote", "Mécanicien aéronautique"],
      "Agriculture": ["Agriculteur", "Technicien agricole", "Ingénieur agronome", "Ouvrier agricole"],
      "Agroalimentaire": ["Technicien agroalimentaire", "Ingénieur agroalimentaire", "Responsable qualité", "Opérateur de production"],
      "Architecture": ["Architecte", "Dessinateur", "Chef de projet", "Urbaniste"],
      "Artisanat": ["Artisan", "Menuisier", "Plombier", "Électricien", "Maçon"],
      "Assurances": ["Agent d'assurance", "Courtier", "Gestionnaire sinistres", "Souscripteur"],
      "Audiovisuel": ["Réalisateur", "Cadreur", "Monteur", "Ingénieur du son", "Producteur"],
      "Audit": ["Auditeur", "Contrôleur de gestion", "Consultant audit", "Responsable audit"],
      "Automobile": ["Mécanicien", "Carrossier", "Vendeur automobile", "Chef d'atelier"],
      "BTP": ["Chef de chantier", "Conducteur de travaux", "Maçon", "Électricien", "Plombier"],
      "Banque": ["Conseiller bancaire", "Chargé de clientèle", "Analyste crédit", "Directeur d'agence"],
      "Beaute": ["Esthéticienne", "Coiffeur", "Maquilleur", "Spa manager"],
      "Biotechnologie": ["Chercheur", "Technicien de laboratoire", "Ingénieur R&D", "Bio-informaticien"],
      "Chimie": ["Chimiste", "Technicien chimie", "Ingénieur chimiste", "Laborantin"],
      "Commerce": ["Commercial", "Vendeur", "Responsable commercial", "Chef des ventes"],
      "Communication": ["Chargé de communication", "Attaché de presse", "Community manager", "Directeur communication"],
      "Comptabilite": ["Comptable", "Expert-comptable", "Aide-comptable", "Contrôleur de gestion"],
      "Culture": ["Médiateur culturel", "Conservateur", "Chargé de production", "Régisseur"],
      "Direction": ["Directeur général", "Directeur adjoint", "Responsable de département", "Manager"],
      "Gestion": ["Gestionnaire", "Responsable administratif", "Office manager", "Assistant de gestion"],
      "Distribution": ["Chef de rayon", "Responsable logistique", "Magasinier", "Préparateur de commandes"],
      "Defense": ["Militaire", "Agent de sécurité", "Analyste défense", "Ingénieur défense"],
      "Edition": ["Éditeur", "Correcteur", "Maquettiste", "Responsable éditorial"],
      "Electronique": ["Ingénieur électronique", "Technicien électronique", "Concepteur", "Testeur"],
      "Environment": ["Ingénieur environnement", "Chargé d'études", "Technicien environnement", "Écologue"],
      "Ferroviare": ["Conducteur de train", "Agent SNCF", "Technicien ferroviaire", "Ingénieur ferroviaire"],
      "Finance": ["Analyste financier", "Contrôleur financier", "Trésorier", "Directeur financier"],
      "Formation": ["Formateur", "Responsable formation", "Ingénieur pédagogique", "Conseiller formation"],
      "Administration": ["Agent administratif", "Rédacteur", "Attaché d'administration", "Secrétaire administratif"],
      "Graphisme": ["Graphiste", "Directeur artistique", "Webdesigner", "Illustrateur"],
      "Hopital": ["Médecin", "Infirmier", "Aide-soignant", "Brancardier", "Secrétaire médical"],
      "Hotellerie": ["Réceptionniste", "Concierge", "Directeur d'hôtel", "Gouvernant"],
      "Immobilier": ["Agent immobilier", "Négociateur", "Gestionnaire de biens", "Promoteur"],
      "Industrie": ["Technicien de maintenance", "Opérateur", "Ingénieur de production", "Chef d'équipe"],
      "Informatique": ["Développeur", "DevOps", "Administrateur système", "Chef de projet IT", "Data analyst"],
      "Ingenierie": ["Ingénieur", "Technicien", "Chef de projet", "Consultant"],
      "Juridique": ["Juriste", "Avocat", "Notaire", "Assistant juridique"],
      "Logistique": ["Logisticien", "Responsable logistique", "Cariste", "Préparateur de commandes"],
      "Marketing": ["Chef de produit", "Responsable marketing", "Chargé d'études", "Community manager"],
      "Navigation de plaisance": ["Skipper", "Matelot", "Capitaine", "Mécanicien naval"],
      "Nautisme": ["Moniteur nautique", "Vendeur nautique", "Technicien naval", "Guide nautique"],
      "Nettoyage": ["Agent de nettoyage", "Chef d'équipe", "Responsable propreté", "Laveur de vitres"],
      "Production": ["Responsable production", "Opérateur", "Chef d'atelier", "Technicien de production"],
      "Publiicite": ["Chef de publicité", "Concepteur-rédacteur", "Directeur de création", "Media planner"],
      "Qualite": ["Responsable qualité", "Technicien qualité", "Auditeur qualité", "Ingénieur qualité"],
      "Recherche": ["Chercheur", "Ingénieur R&D", "Technicien de recherche", "Doctorant"],
      "Resources Humaines": ["Chargé RH", "Responsable RH", "Recruteur", "Gestionnaire paie"],
      "Restauration": ["Cuisinier", "Chef de cuisine", "Serveur", "Responsable de salle"],
      "Services apres-vente": ["Technicien SAV", "Responsable SAV", "Conseiller client", "Hotliner"],
      "Sante": ["Médecin", "Infirmier", "Pharmacien", "Kinésithérapeute", "Aide-soignant"],
      "Secretariat": ["Secrétaire", "Assistant de direction", "Secrétaire médical", "Secrétaire juridique"],
      "Service": ["Agent d'accueil", "Hôte/Hôtesse", "Conseiller clientèle", "Chargé de relation client"],
      "Service publique": ["Fonctionnaire", "Agent territorial", "Attaché d'administration", "Rédacteur"],
      "Social": ["Éducateur", "Assistant social", "Conseiller en insertion", "Animateur"],
      "Securite": ["Agent de sécurité", "Responsable sécurité", "Vigile", "Agent de surveillance"],
      "Telecommunications": ["Technicien télécom", "Ingénieur télécom", "Installateur", "Responsable réseau"],
      "Tourisme": ["Agent de voyage", "Guide touristique", "Responsable tourisme", "Animateur"],
      "Transport": ["Chauffeur", "Conducteur", "Responsable transport", "Logisticien transport"],
      "Vente": ["Vendeur", "Responsable de magasin", "Chef de rayon", "Conseiller de vente"]
    },
    "contract_types": [
      {"value": "cdi", "label": "CDI"},
      {"value": "cdd", "label": "CDD"},
      {"value": "interim", "label": "Intérim"},
      {"value": "stage", "label": "Stage"},
      {"value": "alternance", "label": "Alternance"},
      {"value": "freelance", "label": "Freelance"},
      {"value": "saisonnier", "label": "Saisonnier"}
    ],
    "work_times": [
      {"value": "temps_plein", "label": "Temps plein"},
      {"value": "temps_partiel", "label": "Temps partiel"},
      {"value": "temps_partiel_ou_plein", "label": "Temps partiel ou plein"}
    ],
    "salary_types": [
      {"value": "tranche_salariale", "label": "Tranche salariale"},
      {"value": "salaire_exact", "label": "Salaire exact"},
      {"value": "selon_profil", "label": "Salaire selon le profil"}
    ],
    "salary_payment_types": [
      {"value": "brut", "label": "Brut"},
      {"value": "net", "label": "Net"}
    ],
    "salary_periods": [
      {"value": "horaire", "label": "Par heure"},
      {"value": "mensuel", "label": "Par mois"},
      {"value": "annuel", "label": "Par an"}
    ],
    "availability_types": [
      {"value": "immediatement", "label": "Immédiatement"},
      {"value": "a_partir_de", "label": "À partir de"}
    ],
    "advantages": [
      "Pourboires",
      "Commissions",
      "Participation au transport",
      "Titre restaurant",
      "Véhicule de fonction/service",
      "RTT",
      "Épargne salariale",
      "Horaires flexibles",
      "Travail à domicile",
      "Réductions tarifaires"
    ],
    "education_levels": [
      {"value": "sans_diplome", "label": "Sans diplôme"},
      {"value": "cap_bep", "label": "CAP / BEP"},
      {"value": "bac", "label": "Baccalauréat"},
      {"value": "bac_plus_2", "label": "Bac +2 (BTS, DUT)"},
      {"value": "bac_plus_3", "label": "Bac +3 (Licence)"},
      {"value": "bac_plus_5", "label": "Bac +5 (Master, Ingénieur)"},
      {"value": "doctorat", "label": "Doctorat"}
    ],
    "experience_levels": [
      {"value": "debutant", "label": "Débutant accepté"},
      {"value": "moins_1_an", "label": "Moins de 1 an"},
      {"value": "1_3_ans", "label": "1 à 3 ans"},
      {"value": "3_5_ans", "label": "3 à 5 ans"},
      {"value": "5_10_ans", "label": "5 à 10 ans"},
      {"value": "plus_10_ans", "label": "Plus de 10 ans"}
    ]
  }
}
```

---

### 3. Upload Job Offer Media

**POST** `/api/job-offers/{id}/media`

Uploads images or videos for a job offer.

#### Request Headers
```
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

#### Request Body (multipart/form-data)

| Field | Type | Description |
|-------|------|-------------|
| `media[]` | file (multiple) | Image or video files |

#### Constraints
- **Max file size**: 20 MB per file
- **Accepted formats**: jpg, jpeg, png, gif, mp4, mov

#### Response (Success - 200)

```json
{
  "success": true,
  "message": "Médias uploadés avec succès",
  "data": {
    "media": [
      {
        "id": 1,
        "url": "https://storage.myreklam.com/job-offers/123/image1.jpg",
        "type": "image",
        "size": 1024000
      }
    ]
  }
}
```

---

### 4. Get Job Offer Details

**GET** `/api/job-offers/{id}`

Returns details of a specific job offer.

#### Response (Success - 200)

```json
{
  "success": true,
  "data": {
    "id": 123,
    "category": "Informatique",
    "function": "Développeur",
    "title": "Développeur Full Stack",
    "description": "...",
    "contract_type": "cdi",
    "work_time": "temps_plein",
    "salary_type": "tranche_salariale",
    "salary_min": 35000,
    "salary_max": 45000,
    "salary_payment_type": "brut",
    "salary_period": "annuel",
    "availability_type": "immediatement",
    "available_from": null,
    "available_until": "2025-06-30",
    "advantages": ["Titre restaurant", "RTT"],
    "remote_work": true,
    "location": "Paris",
    "all_france": false,
    "show_google_location": true,
    "company_name": "Tech Company SAS",
    "company_website": "https://techcompany.fr",
    "education_level": "bac_plus_5",
    "experience_level": "3_5_ans",
    "profile_description": "...",
    "accept_messages": true,
    "status": "published",
    "media": [],
    "user": {
      "id": 1,
      "name": "John Doe"
    },
    "created_at": "2025-02-27T10:00:00Z",
    "updated_at": "2025-02-27T10:00:00Z"
  }
}
```

---

### 5. List User's Job Offers

**GET** `/api/job-offers`

Returns all job offers created by the authenticated user.

#### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status: `draft`, `pending_review`, `published`, `rejected` |
| `page` | integer | Page number for pagination |
| `per_page` | integer | Items per page (default: 15) |

#### Response (Success - 200)

```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "title": "Développeur Full Stack",
      "category": "Informatique",
      "function": "Développeur",
      "status": "published",
      "created_at": "2025-02-27T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 72
  }
}
```

---

### 6. Update Job Offer

**PUT** `/api/job-offers/{id}`

Updates an existing job offer. Same body as POST.

---

### 7. Delete Job Offer

**DELETE** `/api/job-offers/{id}`

Deletes a job offer.

#### Response (Success - 200)

```json
{
  "success": true,
  "message": "Offre d'emploi supprimée avec succès"
}
```

---

## Field Validation Rules

### Required Fields

| Field | Validation |
|-------|------------|
| `category` | Required, must be in categories list |
| `function` | Required, must match category's functions |
| `title` | Required, string, max 255 characters |
| `description` | Required, string, max 5000 characters |
| `contract_type` | Required, must be in contract_types list |
| `work_time` | Required, must be in work_times list |
| `salary_type` | Required, must be in salary_types list |
| `availability_type` | Required, must be in availability_types list |
| `company_name` | Required, string, max 255 characters |
| `education_level` | Required, must be in education_levels list |
| `experience_level` | Required, must be in experience_levels list |
| `accept_messages` | Required, boolean |

### Conditional Fields

| Field | Condition |
|-------|-----------|
| `salary_min` | Required if `salary_type` = `tranche_salariale` |
| `salary_max` | Required if `salary_type` = `tranche_salariale` |
| `salary_exact` | Required if `salary_type` = `salaire_exact` |
| `salary_payment_type` | Required if `salary_type` != `selon_profil` |
| `salary_period` | Required if `salary_type` != `selon_profil` |
| `available_from` | Required if `availability_type` = `a_partir_de` |

### Optional Fields

| Field | Validation |
|-------|------------|
| `link` | URL format, max 500 characters |
| `available_until` | Date, must be after `available_from` or today |
| `advantages` | Array of strings from advantages list |
| `remote_work` | Boolean, default false |
| `location` | String, max 255 characters |
| `all_france` | Boolean, default false |
| `show_google_location` | Boolean, default false |
| `show_company_presentation` | Boolean, default false |
| `company_website` | URL format, max 500 characters |
| `profile_description` | String, max 2000 characters |

---

## Status Flow

```
draft → pending_review → published
                      ↘ rejected
```

| Status | Description |
|--------|-------------|
| `draft` | Saved but not submitted |
| `pending_review` | Submitted, awaiting moderation |
| `published` | Approved and visible |
| `rejected` | Rejected by moderator |

---

## Error Codes

| Code | Description |
|------|-------------|
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - User doesn't own this resource |
| 404 | Not Found - Job offer doesn't exist |
| 422 | Validation Error - Invalid input data |
| 500 | Server Error |

---

## Database Schema Suggestion

```sql
CREATE TABLE job_offers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    
    -- Step 1: Category
    category VARCHAR(100) NOT NULL,
    function VARCHAR(100) NOT NULL,
    
    -- Step 2: Link
    link VARCHAR(500) NULL,
    
    -- Step 3: Description
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    contract_type VARCHAR(50) NOT NULL,
    work_time VARCHAR(50) NOT NULL,
    
    -- Salary
    salary_type VARCHAR(50) NOT NULL,
    salary_min DECIMAL(10,2) NULL,
    salary_max DECIMAL(10,2) NULL,
    salary_exact DECIMAL(10,2) NULL,
    salary_payment_type VARCHAR(20) NULL,
    salary_period VARCHAR(20) NULL,
    
    -- Availability
    availability_type VARCHAR(50) NOT NULL,
    available_from DATE NULL,
    available_until DATE NULL,
    
    -- Benefits
    advantages JSON NULL,
    remote_work BOOLEAN DEFAULT FALSE,
    
    -- Location
    location VARCHAR(255) NULL,
    all_france BOOLEAN DEFAULT FALSE,
    show_google_location BOOLEAN DEFAULT FALSE,
    
    -- Company
    company_name VARCHAR(255) NOT NULL,
    show_company_presentation BOOLEAN DEFAULT FALSE,
    company_website VARCHAR(500) NULL,
    
    -- Step 4: Profile
    education_level VARCHAR(50) NOT NULL,
    experience_level VARCHAR(50) NOT NULL,
    profile_description TEXT NULL,
    
    -- Settings
    accept_messages BOOLEAN DEFAULT FALSE,
    status ENUM('draft', 'pending_review', 'published', 'rejected') DEFAULT 'pending_review',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_category (category),
    INDEX idx_user_id (user_id)
);

CREATE TABLE job_offer_media (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    job_offer_id BIGINT UNSIGNED NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type ENUM('image', 'video') NOT NULL,
    file_size INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (job_offer_id) REFERENCES job_offers(id) ON DELETE CASCADE
);
```

---

## Notes for Backend Team

1. **Category-Function Relationship**: Functions are dependent on the selected category. The frontend sends both values, but the backend should validate that the function belongs to the selected category.

2. **Salary Logic**: 
   - If `salary_type` = `tranche_salariale`: require `salary_min` and `salary_max`
   - If `salary_type` = `salaire_exact`: require `salary_exact`
   - If `salary_type` = `selon_profil`: no salary fields required

3. **Availability Logic**:
   - If `availability_type` = `immediatement`: `available_from` should be null or today
   - If `availability_type` = `a_partir_de`: `available_from` is required

4. **Media Upload**: Should be called after the job offer is created, using the returned `id`.

5. **User Association**: Job offers should be automatically associated with the authenticated user.

6. **Moderation**: New job offers should default to `pending_review` status for admin approval.
