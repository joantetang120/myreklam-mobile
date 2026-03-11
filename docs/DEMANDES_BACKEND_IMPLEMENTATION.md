# Demandes Backend Implementation Documentation

> Complete backend implementation reference for the Demandes API module.

---

## Table of Contents

1. [Overview](#overview)
2. [Database Schema](#database-schema)
3. [Models](#models)
4. [Validation](#validation)
5. [API Endpoints](#api-endpoints)
6. [Business Logic](#business-logic)
7. [Media Handling](#media-handling)
8. [Integration Notes](#integration-notes)

---

## Overview

The Demandes module allows authenticated users to create and manage requests/demands for products, services, or opportunities. Each demande can have:
- Category and type classification
- Location-based search capabilities
- Budget constraints
- Media attachments (images/videos)
- Status workflow management

**Key Features:**
- Full CRUD operations
- Media upload/delete
- Location-based filtering (nationwide, radius-based)
- GPS coordinate storage
- Soft deletes
- Status workflow (draft → pending → published/rejected → archived)

---

## Database Schema

### `demandes` Table

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint unsigned | NO | AUTO | Primary key |
| `user_id` | bigint unsigned | NO | - | Foreign key to users table |
| `nature` | varchar(64) | NO | - | Category code (from external API) |
| `type` | varchar(64) | NO | - | Type/subcategory |
| `title` | varchar(160) | NO | - | Request title |
| `description` | text | NO | - | Detailed description |
| `urgent` | boolean | NO | false | Immediate need flag |
| `budget_max` | decimal(10,2) | YES | null | Maximum budget in euros |
| `location` | varchar(255) | YES | null | Address/location string |
| `use_current_location` | boolean | NO | false | Use GPS coordinates |
| `nationwide` | boolean | NO | false | Available across France |
| `search_radius_km` | integer | YES | null | Search radius (0-200 km) |
| `show_google_location` | boolean | NO | false | Display location on map |
| `latitude` | decimal(10,8) | YES | null | GPS latitude |
| `longitude` | decimal(11,8) | YES | null | GPS longitude |
| `accept_messages` | boolean | NO | false | Allow messaging |
| `status` | enum | NO | draft | Workflow status |
| `published_at` | timestamp | YES | null | Publication timestamp |
| `created_at` | timestamp | NO | - | Creation timestamp |
| `updated_at` | timestamp | NO | - | Last update timestamp |
| `deleted_at` | timestamp | YES | null | Soft delete timestamp |

**Indexes:**
- Primary key on `id`
- Foreign key on `user_id` → `users(id)` CASCADE ON DELETE
- Index on `status` for filtering
- Index on `created_at` for sorting

**Status Values:**
- `draft` - Initial state
- `pending` - Submitted for review
- `published` - Approved and visible
- `rejected` - Declined by admin
- `archived` - User archived

### `demande_media` Table

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| `id` | bigint unsigned | NO | AUTO | Primary key |
| `demande_id` | bigint unsigned | NO | - | Foreign key to demandes |
| `file_path` | varchar(500) | NO | - | Storage path |
| `file_type` | varchar(20) | NO | - | image or video |
| `file_size` | bigint unsigned | YES | null | File size in bytes |
| `order_index` | smallint | NO | 0 | Display order |
| `created_at` | timestamp | NO | - | Upload timestamp |
| `updated_at` | timestamp | NO | - | Last update timestamp |

**Indexes:**
- Primary key on `id`
- Foreign key on `demande_id` → `demandes(id)` CASCADE ON DELETE
- Index on `order_index` for sorting

---

## Models

### `Demande` Model

**Location:** `app/Models/Demande.php`

**Relationships:**
- `user()` - BelongsTo User
- `media()` - HasMany DemandeMedia (ordered by `order_index`)

**Fillable Fields:**
```php
[
    'user_id', 'nature', 'type', 'title', 'description',
    'urgent', 'budget_max', 'location', 'use_current_location',
    'nationwide', 'search_radius_km', 'show_google_location',
    'latitude', 'longitude', 'accept_messages', 'status', 'published_at'
]
```

**Casts:**
```php
[
    'urgent' => 'boolean',
    'budget_max' => 'decimal:2',
    'use_current_location' => 'boolean',
    'nationwide' => 'boolean',
    'search_radius_km' => 'integer',
    'show_google_location' => 'boolean',
    'latitude' => 'decimal:8',
    'longitude' => 'decimal:8',
    'accept_messages' => 'boolean',
    'published_at' => 'datetime',
]
```

**Traits:**
- `HasFactory`
- `SoftDeletes`

### `DemandeMedia` Model

**Location:** `app/Models/DemandeMedia.php`

**Relationships:**
- `demande()` - BelongsTo Demande

**Fillable Fields:**
```php
['demande_id', 'file_path', 'file_type', 'file_size', 'order_index']
```

**Appends:**
- `url` - Full storage URL via `Storage::url()`

---

## Validation

### Request Classes

**Location:** `app/Http/Requests/Demande/`

#### `DemandeBaseRequest`

Base validation logic shared between store and update operations.

**Rules:**
- `nature` - required (on create), string, max 64 chars
- `type` - required (on create), string, max 64 chars
- `title` - required (on create), string, max 160 chars
- `description` - required (on create), string
- `urgent` - optional, boolean
- `budget_max` - optional, numeric, min 0
- `location` - optional, string, max 255 chars
- `use_current_location` - optional, boolean
- `nationwide` - optional, boolean
- `search_radius_km` - optional, integer, 0-200
- `show_google_location` - optional, boolean
- `latitude` - optional, numeric, -90 to 90
- `longitude` - optional, numeric, -180 to 180
- `accept_messages` - optional, boolean
- `status` - optional, enum (draft, pending, published, rejected, archived)

**Custom Validation:**
1. **Budget Validation:**
   - If provided, must be > 0

2. **Location Validation:**
   - If `search_radius_km` is set without `nationwide` or `use_current_location`, `location` is required

**Normalization:**
- Boolean fields are normalized from string/int to true boolean
- Config-driven fields (type) accept both keys and labels

#### `DemandeStoreRequest`

Extends `DemandeBaseRequest` with `isUpdate() = false`.

#### `DemandeUpdateRequest`

Extends `DemandeBaseRequest` with `isUpdate() = true` (all fields become optional).

---

## API Endpoints

All endpoints require `Authorization: Bearer {token}` header.

### 1. Get Metadata — `GET /api/demandes/meta`

**Controller:** `DemandeController@meta`

**Response:**
```json
{
  "success": true,
  "data": {
    "types": ["Code promo", "Réduction", "Bon de réduction", "Offre spéciale", "Vente flash"],
    "validite_options": ["Offre permanente", "1 semaine", "1 mois", "3 mois", "6 mois"],
    "moyen_retrait_options": ["magasin", "en ligne", "les deux"],
    "location_options": ["France", "Belgique", "Suisse", "Canada", "Autre"],
    "statuses": ["draft", "pending", "published", "rejected", "archived"]
  }
}
```

### 2. List Demandes — `GET /api/demandes`

**Controller:** `DemandeController@index`

**Query Parameters:**
- `status` (optional) - Filter by status
- `per_page` (optional, 1-50, default 15) - Items per page
- `page` (optional) - Page number

**Response:** Paginated list of user's demandes with media loaded.

### 3. Create Demande — `POST /api/demandes`

**Controller:** `DemandeController@store`

**Request Body:** JSON with validated fields

**Response:** 201 Created with demande object

**Auto-set Fields:**
- `user_id` - From authenticated user
- `status` - Defaults to 'pending' if not provided

### 4. Get Single Demande — `GET /api/demandes/{id}`

**Controller:** `DemandeController@show`

**Authorization:** Only owner can view

**Response:** Full demande object with media

### 5. Update Demande — `PUT /api/demandes/{id}`

**Controller:** `DemandeController@update`

**Authorization:** Only owner can update

**Request Body:** JSON with fields to update

**Response:** Updated demande object with media

### 6. Delete Demande — `DELETE /api/demandes/{id}`

**Controller:** `DemandeController@destroy`

**Authorization:** Only owner can delete

**Response:** 200 OK with success message

**Note:** Soft delete - record remains in database with `deleted_at` timestamp

### 7. Upload Media — `POST /api/demandes/{id}/media`

**Controller:** `DemandeController@uploadMedia`

**Authorization:** Only owner can upload

**Content-Type:** `multipart/form-data`

**Request Fields:**
- `media[]` - Array of files (max 10)

**File Validation:**
- Types: jpg, jpeg, png, gif, mp4, mov, avi
- Max size: 10MB per file

**Response:**
```json
{
  "success": true,
  "message": "Médias téléchargés avec succès.",
  "data": {
    "uploaded": 2,
    "files": [
      {
        "id": 1,
        "url": "/storage/demandes/123/uuid.jpg",
        "type": "image",
        "size": 245678
      }
    ]
  }
}
```

### 8. Delete Media — `DELETE /api/demandes/{id}/media/{mediaId}`

**Controller:** `DemandeController@deleteMedia`

**Authorization:** Only owner can delete

**Response:** 200 OK with success message

**Note:** Deletes file from storage and database record

---

## Business Logic

### Location Handling

**Priority Order:**
1. If `nationwide` is true → ignore location and radius
2. If `use_current_location` is true → use `latitude`/`longitude`
3. Otherwise → use `location` string with optional `search_radius_km`

**GPS Coordinates:**
- Stored in `latitude` and `longitude` fields
- Precision: 8 decimal places for latitude, 8 for longitude
- Can be used for geolocation-based matching

### Status Workflow

```
draft → pending → published
                 ↓
              rejected
                 ↓
              archived
```

**Transitions:**
- User creates: `draft` or `pending`
- Admin reviews: `pending` → `published` or `rejected`
- User can archive: any status → `archived`

### Budget Validation

- Optional field
- If provided, must be positive number
- Stored as decimal(10,2) for currency precision

### Media Management

**Storage Structure:**
```
storage/app/public/demandes/{demande_id}/{uuid}.{ext}
```

**File Types:**
- Images: jpg, jpeg, png, gif
- Videos: mp4, mov, avi

**Limits:**
- Max 10 files per demande
- Max 10MB per file

**Order:**
- Files are ordered by `order_index`
- Index assigned during upload based on array position

---

## Integration Notes

### External Categories API

**Endpoint:** `https://api.myreklam.fr/Categorie.php`

**Method:** POST

**Body:** `Method=getByType&type=demandes`

**Response Structure:**
```json
{
  "status": "success",
  "data": {
    "main": [/* category objects */],
    "subs": {
      "parentId": [/* subcategory objects */]
    }
  }
}
```

**Backend Handling:**
- `nature` field stores the category `code` (e.g., "RealEstate")
- `type` field stores the subcategory `code` (e.g., "LookingForRental")
- No foreign key constraints - accepts any string values
- Frontend is responsible for fetching and validating categories

### Config-Driven Enums

**Location:** `config/demandes.php`

**Available Configs:**
- `types` - Demande types
- `validite_options` - Validity periods
- `moyen_retrait_options` - Pickup methods
- `location_options` - Location presets

**Validation:**
- Accepts both config keys and values (labels)
- Normalizes to keys before storage

### User Relationship

**Model:** `User::demandes()`

**Cascade Behavior:**
- When user is deleted → all demandes are deleted
- When demande is deleted → all media files are deleted

---

## Configuration Files

### `config/demandes.php`

```php
return [
    'types' => [
        'Code promo' => 'Code promo',
        'Réduction' => 'Réduction',
        'Bon de réduction' => 'Bon de réduction',
        'Offre spéciale' => 'Offre spéciale',
        'Vente flash' => 'Vente flash',
    ],
    'validite_options' => [
        'Offre permanente' => 'Offre permanente',
        '1 semaine' => '1 semaine',
        '1 mois' => '1 mois',
        '3 mois' => '3 mois',
        '6 mois' => '6 mois',
    ],
    'moyen_retrait_options' => [
        'magasin' => 'magasin',
        'en ligne' => 'en ligne',
        'les deux' => 'les deux',
    ],
    'location_options' => [
        'France' => 'France',
        'Belgique' => 'Belgique',
        'Suisse' => 'Suisse',
        'Canada' => 'Canada',
        'Autre' => 'Autre',
    ],
];
```

---

## Routes

**File:** `routes/api.php`

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::prefix('demandes')->group(function () {
        Route::get('/meta', [DemandeController::class, 'meta']);
        Route::get('/', [DemandeController::class, 'index']);
        Route::post('/', [DemandeController::class, 'store']);
        Route::get('/{id}', [DemandeController::class, 'show']);
        Route::put('/{id}', [DemandeController::class, 'update']);
        Route::delete('/{id}', [DemandeController::class, 'destroy']);
        Route::post('/{id}/media', [DemandeController::class, 'uploadMedia']);
        Route::delete('/{id}/media/{mediaId}', [DemandeController::class, 'deleteMedia']);
    });
});
```

---

## Testing Checklist

- [ ] Create demande with all required fields
- [ ] Create demande with optional fields
- [ ] Update demande (partial update)
- [ ] List demandes with pagination
- [ ] Filter demandes by status
- [ ] Upload single media file
- [ ] Upload multiple media files (max 10)
- [ ] Delete media file
- [ ] Delete demande (soft delete)
- [ ] Verify authorization (non-owner cannot access)
- [ ] Test nationwide vs location-based demandes
- [ ] Test GPS coordinate storage
- [ ] Test budget validation (positive numbers only)
- [ ] Test file type validation
- [ ] Test file size validation (10MB limit)

---

## Migration Commands

```bash
# Run migrations
php artisan migrate

# Rollback demandes migrations
php artisan migrate:rollback --step=2

# Fresh migration (WARNING: drops all tables)
php artisan migrate:fresh
```

---

**Last Updated:** March 6, 2026  
**Version:** 1.0  
**Maintained by:** Development Team
