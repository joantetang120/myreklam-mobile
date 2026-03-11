# Events Backend Specification

This document translates every input captured in `lib/screens/creer_evenement_screen.dart` into a backend-ready schema. It lists required tables, fields, types, and enum constraints so that the API team can expose `POST /events`, `GET /events`, etc., with full coverage of the current UI.

## 1. Form Overview → Domain Fields

| UI Step | Field / Control | Description | Suggested Backend Field | Type / Enum |
| --- | --- | --- | --- | --- |
| Step 1 – Catégorie | Catégorie d'événement | Main category selected from `Categorie.php` (`type=evenements`, codes like `ProfessionalNetworking`) | `category_code` | `VARCHAR(64)` FK to `event_categories.code` |
| | Type d'événement | Sub-category depending on main category | `sub_category_code` | `VARCHAR(64)` FK to `event_subcategories.code` |
| | Format de l'événement | One of `Code promo`, `Réduction`, `Bon de réduction`, `Offre spéciale`, `Vente flash` | `format_type` | `ENUM('code_promo','reduction','bon_reduction','offre_speciale','vente_flash')` |
| Step 2 – Lien | Lien principal | Optional external link | `landing_url` | `VARCHAR(255)` |
| Step 3 – Description | Titre | Event title | `title` | `VARCHAR(160)` |
| | Description | Long description/body | `description` | `TEXT` |
| | Êtes-vous l'organisateur ? | `Oui` / `Non`; controls conditional organizer field | `is_organizer` | `BOOLEAN` |
| | Nom de l'organisateur (si Non) | Free text | `organizer_name` | `VARCHAR(160)` nullable |
| | Ville / région | Free text about geographic availability | `coverage_area` | `VARCHAR(160)` |
| | Toute la France switch | Indicates nationwide availability | `is_nationwide` | `BOOLEAN` |
| | Prix d'entrée | `Gratuit` / `Payant` | `price_type` | `ENUM('gratuit','payant')` |
| | Prix (si payant) | Numeric amount in euros | `price_amount` | `DECIMAL(10,2)` nullable |
| | Mode de réservation | `Sans inscription`, `Inscription requise`, `Achat de billet obligatoire` | `reservation_mode` | `ENUM('sans_inscription','inscription','achat_billet')` |
| | Site web | Optional URL | `website_url` | `VARCHAR(255)` |
| Step 4 – Informations | Durée de l'événement | `Sur une journée`, `Sur plusieurs jours`, `Permanent` | `duration_type` | `ENUM('one_day','multi_day','permanent')` |
| | Date (one day) | Single date picker | `event_date` | `DATE` nullable |
| | Date début / fin (multi-day) | Range of dates | `start_date`, `end_date` | `DATE` |
| | Horaires | Time-of-day pickers (`De` / `À`) | `start_time`, `end_time` | `TIME` |
| Step 4 (planned) | Prix initial / Prix final / Réduction | Controllers exist for promotions; keep backend-ready | `initial_price`, `final_price`, `discount_value` | `DECIMAL(10,2)` |
| Step 3 (checkbox) | Accept messages (UI bool) | `accept_messages` | `BOOLEAN` (default false) |
| Step 5 | Media uploads | Images/videos via `_buildUploadButton` | See `event_media` table | |

> **Note:** `_selectedValidite`, `_selectedMoyenRetrait`, `_prixInitial/Final`, `_reduction` controllers are declared but not wired yet. Include columns so the API remains forward-compatible.

## 2. Database Tables

### 2.1 `event_categories`
Stores the master data pulled from `Categorie.php` for type `evenements`.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `INT PK` | Matches remote `id` |
| `code` | `VARCHAR(64) UNIQUE` | e.g., `ProfessionalNetworking` |
| `label_fr` | `VARCHAR(160)` | `label` from API |
| `label_en` | `VARCHAR(160)` | `labelEn` |
| `order_index` | `SMALLINT` | `order` from API |
| `is_active` | `BOOLEAN` | `isActive` |
| `type` | `VARCHAR(32)` | always `event` but stored for completeness |
| `created_at`, `updated_at` | `TIMESTAMP` | from API when available |

### 2.2 `event_subcategories`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `INT PK` | matches remote `id` |
| `parent_id` | `INT FK -> event_categories.id` | |
| `code` | `VARCHAR(64) UNIQUE` | e.g., `AfterworkTeamBuilding` |
| `label_fr` / `label_en` | `VARCHAR(160)` | |
| `order_index` | `SMALLINT` | |
| `is_active` | `BOOLEAN` | |
| `created_at`, `updated_at` | `TIMESTAMP` | |

### 2.3 `events`
Primary record representing the announcement.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `UUID PK` | |
| `user_id` | `UUID FK -> users.id` | Author of the event |
| `category_code` | `VARCHAR(64)` | FK -> `event_categories.code` |
| `sub_category_code` | `VARCHAR(64)` | FK -> `event_subcategories.code` |
| `format_type` | `ENUM('code_promo','reduction','bon_reduction','offre_speciale','vente_flash')` | Maps `_types` |
| `title` | `VARCHAR(160)` | |
| `description` | `TEXT` | |
| `landing_url` | `VARCHAR(255)` | Step 2 link |
| `is_organizer` | `BOOLEAN` | |
| `organizer_name` | `VARCHAR(160)` | Nullable |
| `coverage_area` | `VARCHAR(160)` | Free text city/region |
| `is_nationwide` | `BOOLEAN` | `_touteLaFrance` |
| `location_country` | `VARCHAR(2)` | Optional ISO country (derived from dropdown if added) |
| `price_type` | `ENUM('gratuit','payant')` | |
| `price_amount` | `DECIMAL(10,2)` | Nullable unless payant |
| `reservation_mode` | `ENUM('sans_inscription','inscription','achat_billet')` | |
| `website_url` | `VARCHAR(255)` | |
| `duration_type` | `ENUM('one_day','multi_day','permanent')` | |
| `event_date` | `DATE` | For one-day mode |
| `start_date` | `DATE` | For multi-day mode |
| `end_date` | `DATE` | |
| `start_time` | `TIME` | |
| `end_time` | `TIME` | |
| `initial_price` | `DECIMAL(10,2)` | optional promo reference |
| `final_price` | `DECIMAL(10,2)` | |
| `discount_value` | `DECIMAL(10,2)` | Could store reduction amount or percent |
| `accept_messages` | `BOOLEAN DEFAULT FALSE` | |
| `status` | `ENUM('draft','pending','published','rejected','archived')` | Workflow |
| `published_at` | `TIMESTAMP` | |
| `created_at` / `updated_at` | `TIMESTAMP` | |

### 2.4 `event_media`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | `UUID PK` | |
| `event_id` | `UUID FK -> events.id` | |
| `media_type` | `ENUM('image','video')` | Align with upload widget |
| `storage_path` | `VARCHAR(255)` | URL or storage key |
| `thumbnail_path` | `VARCHAR(255)` | optional |
| `position` | `SMALLINT` | Display order |
| `uploaded_at` | `TIMESTAMP` | |

### 2.5 `event_stats` (optional but recommended)
Tracks aggregated metrics (views, clicks) for future analytics.

| Column | Type | Notes |
| --- | --- | --- |
| `event_id` | `UUID PK/FK` | |
| `view_count` | `INT` | |
| `click_count` | `INT` | |
| `contact_requests` | `INT` | |
| `updated_at` | `TIMESTAMP` | |

## 3. Enumerations / Reference Data

```text
format_type        = { code_promo, reduction, bon_reduction, offre_speciale, vente_flash }
price_type         = { gratuit, payant }
reservation_mode   = { sans_inscription, inscription, achat_billet }
duration_type      = { one_day, multi_day, permanent }
```

Store enums either as native DB enum types or lookup tables (`event_formats`, `reservation_modes`) if the tech stack favors FK references.

## 4. API Considerations

### 4.1 Create Event – `POST /events`
- Authenticated endpoint.
- Accepts JSON body with fields listed in the `events` table.
- Validations:
  - `category_code` and `sub_category_code` must exist and be linked.
  - `price_amount` required when `price_type='payant'`.
  - Date/time constraints depending on `duration_type`.
  - Enforce max lengths for textual fields.
- Media uploads handled via multipart or separate `/events/{id}/media` endpoint referencing `event_media`.

### 4.2 List Events – `GET /events`
- Filters: `status`, `category_code`, `sub_category_code`, `user_id`, date ranges.
- Paginated response returning event plus derived tags (price label, duration summary) matching `FormationCard` style used elsewhere in the app.

### 4.3 Update / Publish Workflow
- `PUT /events/{id}` for edits while in draft/pending.
- `POST /events/{id}/publish` toggles status once moderation is complete.

### 4.4 Metadata Endpoints
- `GET /event-categories` caches `event_categories` + `event_subcategories` so mobile clients don’t have to hit `Categorie.php` directly.
- `GET /event-formats`, `GET /reservation-modes`, etc., if the enum sets ever diverge from hard-coded Flutter lists.

## 5. Field Mapping Checklist

- [x] Categories / subcategories loaded from API → stored in dedicated tables.
- [x] Format type, pricing, reservation options captured as enums.
- [x] Location coverage (city text + nationwide boolean).
- [x] Temporal data (duration type, dates, times).
- [x] Organizer metadata and optional external URLs.
- [x] Media placeholders for future upload functionality.
- [x] Optional promotional price fields already wired in backend, ready for future UI updates.

With this schema, the backend team can implement full CRUD plus moderation on events without re-reading the Flutter implementation each time.
