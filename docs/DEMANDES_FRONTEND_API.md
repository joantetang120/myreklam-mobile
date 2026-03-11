# Demandes API - Frontend Integration Guide

> Complete API reference for creating and managing demandes (requests/demands) in the mobile app.

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Metadata](#metadata)
4. [CRUD Endpoints](#crud-endpoints)
5. [Media Uploads](#media-uploads)
6. [Validation Rules & Notes](#validation-rules--notes)
7. [Request/Response Examples](#requestresponse-examples)

---

## Overview

**Base URL:** `http://<server>:8000/api`

All endpoints require authentication via Bearer token (Sanctum).

---

## Authentication

Reuse the same auth flow as other modules (login, refresh token, etc.). Include:

```
Authorization: Bearer {token}
Accept: application/json
```

---

## Metadata

### `GET /demandes/meta`

Returns constants to populate dropdowns and pickers.

```json
{
  "success": true,
  "data": {
    "types": [
      "Code promo",
      "Réduction",
      "Bon de réduction",
      "Offre spéciale",
      "Vente flash"
    ],
    "validite_options": [
      "Offre permanente",
      "1 semaine",
      "1 mois",
      "3 mois",
      "6 mois"
    ],
    "moyen_retrait_options": [
      "magasin",
      "en ligne",
      "les deux"
    ],
    "location_options": [
      "France",
      "Belgique",
      "Suisse",
      "Canada",
      "Autre"
    ],
    "statuses": ["draft", "pending", "published", "rejected", "archived"]
  }
}
```

### Categories Endpoint

**External API:** `https://api.myreklam.fr/Categorie.php`

```http
POST https://api.myreklam.fr/Categorie.php
Content-Type: application/x-www-form-urlencoded

Method=getByType&type=demandes
```

Response structure:
```json
{
  "status": "success",
  "data": {
    "main": [
      {
        "id": 101,
        "type": "inquiry",
        "parentId": null,
        "code": "SearchJob",
        "label": "Recherche d'emploi",
        "labelEn": "Job Search",
        "order": 1,
        "isActive": true,
        "createdAt": "2025-11-21 17:34:37.181906",
        "updatedAt": "2025-11-21 17:34:37.181906"
      },
      {
        "id": 103,
        "type": "inquiry",
        "parentId": null,
        "code": "RealEstate",
        "label": "Immobilier",
        "labelEn": "Real Estate",
        "order": 3,
        "isActive": true,
        "createdAt": "2025-11-21 17:34:37.183115",
        "updatedAt": "2025-11-21 17:34:37.183115"
      }
    ],
    "subs": {
      "103": [
        {
          "id": 3147,
          "type": "inquiry",
          "parentId": 103,
          "code": "RealEstateInvestment",
          "label": "Investissement immobilier",
          "labelEn": "Real Estate Investment",
          "order": 1,
          "isActive": true,
          "createdAt": "2025-11-22 18:25:19.69233",
          "updatedAt": "2025-11-22 18:25:19.69233"
        },
        {
          "id": 3148,
          "type": "inquiry",
          "parentId": 103,
          "code": "LookingForRental",
          "label": "Cherche location",
          "labelEn": "Looking For Rental",
          "order": 2,
          "isActive": true,
          "createdAt": "2025-11-22 18:25:19.695664",
          "updatedAt": "2025-11-22 18:25:19.695664"
        }
      ]
    }
  }
}
```

**Note:** The `subs` object is keyed by the parent category `id` (as string). Each category may have 0 or more subcategories.

---

## CRUD Endpoints

All under `Bearer` auth.

### 1. List Demandes — `GET /demandes`

Query params:
- `status` (optional): filter by workflow status.
- `per_page` (1-50, default 15)
- `page`

Response: paginated array of demandes owned by the user. Each demande includes `media_files` URLs.

### 2. Create Demande — `POST /demandes`

Body fields follow the spec:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `nature` | string | ✅ | Category code from external API (e.g., "RealEstate", "ServiceHelp"). |
| `type` | string | ✅ | Subcategory code from external API (e.g., "LookingForRental", "Carpooling"). Depends on selected nature. |
| `title` | string (≤160) | ✅ | Title of the request. |
| `description` | string | ✅ | Detailed description. |
| `urgent` | boolean | ❌ | "Dans l'immédiat" checkbox. Default: false |
| `budget_max` | decimal | ❌ | Maximum budget in euros. |
| `location` | string | ❌ | Location/address for the request. |
| `use_current_location` | boolean | ❌ | Use user's current GPS location. Default: false |
| `nationwide` | boolean | ❌ | "Toute la France" checkbox. Default: false |
| `search_radius_km` | integer | ❌ | Search radius in kilometers (0-200). |
| `show_google_location` | boolean | ❌ | Display Google Maps location on listing. Default: false |
| `accept_messages` | boolean | ❌ | Allow users to send messages. Default: false |

**Response (201 Created):**

```json
{
  "success": true,
  "message": "Demande créée avec succès.",
  "data": {
    "id": 123,
    "nature": "Services",
    "type": "Code promo",
    "title": "Recherche plombier urgent",
    "description": "Besoin d'un plombier pour...",
    "urgent": true,
    "budget_max": 150.00,
    "location": "Paris, 75001",
    "use_current_location": false,
    "nationwide": false,
    "search_radius_km": 50,
    "show_google_location": true,
    "accept_messages": true,
    "status": "pending",
    "user_id": 456,
    "created_at": "2024-03-06T15:30:00.000000Z",
    "updated_at": "2024-03-06T15:30:00.000000Z"
  }
}
```

### 3. Get Single Demande — `GET /demandes/{id}`

Returns full details including media.

### 4. Update Demande — `PUT /demandes/{id}`

Same fields as create. Only owner can update.

### 5. Delete Demande — `DELETE /demandes/{id}`

Soft-deletes or archives the demande.

---

## Media Uploads

### `POST /demandes/{id}/media`

Upload photos/videos after creating the demande.

**Content-Type:** `multipart/form-data`

**Fields:**
- `media[]` — one or more files (jpg, jpeg, png, gif, mp4, mov, avi)

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
        "url": "/storage/demandes/019cc3a6-c6b5-7136-a3ac-435fcef4d241/photo1.jpg",
        "type": "image",
        "size": 245678
      },
      {
        "id": 2,
        "url": "/storage/demandes/019cc3a6-c6b5-7136-a3ac-435fcef4d241/photo2.jpg",
        "type": "image",
        "size": 189234
      }
    ]
  }
}
```

---

## Validation Rules & Notes

### Required Fields
- `nature` (from categories API)
- `type` (from metadata)
- `title` (max 160 chars)
- `description` (min 10 chars recommended)

### Optional Fields
- All location-related fields are optional
- Budget is optional but recommended
- `urgent` defaults to false if not provided
- `accept_messages` defaults to false if not provided

### Business Rules

1. **Location Logic:**
   - If `nationwide` is true, ignore `location` and `search_radius_km`
   - If `use_current_location` is true, backend should capture GPS coordinates
   - `search_radius_km` only applies when specific location is set

2. **Budget:**
   - Must be positive number if provided
   - Stored as decimal(10,2)

3. **Media:**
   - Max 10 files per demande
   - Max 10MB per file
   - Supported formats: jpg, jpeg, png, gif, mp4, mov, avi

4. **Status Workflow:**
   - `draft` → `pending` → `published` or `rejected`
   - User can archive published demandes

---

## Request/Response Examples

### Example 1: Create Simple Demande

**Request:**
```http
POST /api/demandes
Authorization: Bearer {token}
Content-Type: application/json

{
  "nature": "Services",
  "type": "Offre spéciale",
  "title": "Recherche plombier qualifié",
  "description": "Besoin d'un plombier pour réparer une fuite d'eau dans la salle de bain. Intervention rapide souhaitée.",
  "urgent": true,
  "budget_max": 200.00,
  "location": "Lyon, 69001",
  "search_radius_km": 30,
  "accept_messages": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Demande créée avec succès.",
  "data": {
    "id": 789,
    "nature": "Services",
    "type": "Offre spéciale",
    "title": "Recherche plombier qualifié",
    "description": "Besoin d'un plombier pour réparer une fuite d'eau dans la salle de bain. Intervention rapide souhaitée.",
    "urgent": true,
    "budget_max": 200.00,
    "location": "Lyon, 69001",
    "use_current_location": false,
    "nationwide": false,
    "search_radius_km": 30,
    "show_google_location": false,
    "accept_messages": true,
    "status": "pending",
    "user_id": 456,
    "created_at": "2024-03-06T16:45:00.000000Z",
    "updated_at": "2024-03-06T16:45:00.000000Z"
  }
}
```

### Example 2: Create Nationwide Demande

**Request:**
```http
POST /api/demandes
Authorization: Bearer {token}
Content-Type: application/json

{
  "nature": "Produits",
  "type": "Code promo",
  "title": "Recherche code promo Amazon",
  "description": "Je cherche un code promo valide pour Amazon, tous produits confondus.",
  "nationwide": true,
  "accept_messages": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Demande créée avec succès.",
  "data": {
    "id": 790,
    "nature": "Produits",
    "type": "Code promo",
    "title": "Recherche code promo Amazon",
    "description": "Je cherche un code promo valide pour Amazon, tous produits confondus.",
    "urgent": false,
    "budget_max": null,
    "location": null,
    "use_current_location": false,
    "nationwide": true,
    "search_radius_km": null,
    "show_google_location": false,
    "accept_messages": true,
    "status": "pending",
    "user_id": 456,
    "created_at": "2024-03-06T16:50:00.000000Z",
    "updated_at": "2024-03-06T16:50:00.000000Z"
  }
}
```

### Example 3: Upload Media to Demande

**Request:**
```http
POST /api/demandes/789/media
Authorization: Bearer {token}
Content-Type: multipart/form-data

media[]: (binary file data - photo1.jpg)
media[]: (binary file data - photo2.jpg)
```

**Response:**
```json
{
  "success": true,
  "message": "Médias téléchargés avec succès.",
  "data": {
    "uploaded": 2,
    "files": [
      {
        "id": 101,
        "url": "/storage/demandes/019cc3a6-c6b5-7136-a3ac-435fcef4d241/photo1.jpg",
        "type": "image",
        "size": 245678
      },
      {
        "id": 102,
        "url": "/storage/demandes/019cc3a6-c6b5-7136-a3ac-435fcef4d241/photo2.jpg",
        "type": "image",
        "size": 189234
      }
    ]
  }
}
```

### Example 4: List User's Demandes

**Request:**
```http
GET /api/demandes?status=published&per_page=10&page=1
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 789,
        "nature": "Services",
        "type": "Offre spéciale",
        "title": "Recherche plombier qualifié",
        "description": "Besoin d'un plombier pour réparer une fuite d'eau...",
        "urgent": true,
        "budget_max": 200.00,
        "location": "Lyon, 69001",
        "search_radius_km": 30,
        "status": "published",
        "media_files": [
          {
            "id": 101,
            "url": "/storage/demandes/019cc3a6-c6b5-7136-a3ac-435fcef4d241/photo1.jpg",
            "type": "image"
          }
        ],
        "created_at": "2024-03-06T16:45:00.000000Z",
        "updated_at": "2024-03-06T16:45:00.000000Z"
      }
    ],
    "first_page_url": "http://localhost:8000/api/demandes?page=1",
    "from": 1,
    "last_page": 1,
    "last_page_url": "http://localhost:8000/api/demandes?page=1",
    "next_page_url": null,
    "path": "http://localhost:8000/api/demandes",
    "per_page": 10,
    "prev_page_url": null,
    "to": 1,
    "total": 1
  }
}
```

### Error Response Example

**Request:**
```http
POST /api/demandes
Authorization: Bearer {token}
Content-Type: application/json

{
  "nature": "Services",
  "title": "Too short"
}
```

**Response (422 Unprocessable Entity):**
```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {
    "type": ["The type field is required."],
    "description": ["The description field is required."],
    "title": ["The title must be at least 10 characters."]
  }
}
```

---

## Frontend Implementation Notes

### Screen Flow (creer_demande_screen.dart)

**Step 1 - Nature:**
- Fetch categories from `https://api.myreklam.fr/Categorie.php` (Method=getByType, type=demandes)
- Display nature dropdown with loading/error states
- Store selected nature in `_selectedCategory`

**Step 2 - Details:**
- Type dropdown (`_selectedType` from `_types` list)
- Title input (`_titleController`)
- Description textarea (`_descriptionController`)
- Urgent checkbox (`_acceptDemand`)
- Budget input (`_prixFinalController`)

**Step 3 - Localisation:**
- "Toute la France" checkbox
- Location input (`_descriptionController` - note: appears to be reused, should use dedicated controller)
- "Use current location" checkbox
- Search radius slider (`_rayonRecherche`, 0-200 km)
- "Show Google location" checkbox

**Step 4 - Photos:**
- Media file picker (jpg, jpeg, png, gif, mp4, mov, avi)
- Multiple file selection
- Store in `_selectedMediaFiles`

**Step 5 - Review:**
- Display all entered information
- Accept messages toggle (`_acceptMessages`)
- Submit button

### Payload Construction

```dart
Map<String, dynamic> _buildDemandePayload() {
  return {
    'nature': _selectedCategory,
    'type': _selectedType,
    'title': _titleController.text.trim(),
    'description': _descriptionController.text.trim(),
    'urgent': _acceptDemand,
    'budget_max': _prixFinalController.text.trim().isNotEmpty
        ? double.tryParse(_prixFinalController.text.replaceAll(',', '.'))
        : null,
    'location': _disponibleChezController.text.trim(),
    'use_current_location': _useCurrentLocation,
    'nationwide': _touteLaFrance,
    'search_radius_km': _rayonRecherche.toInt(),
    'show_google_location': _showGoogleLocation,
    'accept_messages': _acceptMessages,
  }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));
}
```

### Submission Flow

1. Validate required fields
2. POST to `/api/demandes` with payload
3. If successful and media files exist, POST to `/api/demandes/{id}/media`
4. Show success dialog
5. Navigate back or to demandes list

---

## Status Codes

- `200 OK` — Successful GET/PUT
- `201 Created` — Successful POST
- `204 No Content` — Successful DELETE
- `400 Bad Request` — Invalid request format
- `401 Unauthorized` — Missing or invalid token
- `403 Forbidden` — Not owner of resource
- `404 Not Found` — Resource doesn't exist
- `422 Unprocessable Entity` — Validation errors
- `500 Internal Server Error` — Server error

---

## Notes for Backend Implementation

1. **Categories Integration:**
   - Nature values come from external API (Categorie.php)
   - Backend should validate that submitted nature exists in categories
   - Consider caching category data

2. **Location Handling:**
   - If `use_current_location` is true, expect GPS coordinates in separate fields
   - Store both address string and lat/lng if available
   - Implement geolocation search based on `search_radius_km`

3. **Search & Matching:**
   - Demandes should be searchable by nature, type, title, description
   - Implement matching algorithm based on location radius
   - Consider notification system for matching offers

4. **Media Storage:**
   - Use UUID-based folder structure
   - Implement image optimization/resizing
   - Generate thumbnails for faster loading
   - Clean up orphaned media files

5. **Privacy:**
   - Respect `accept_messages` setting
   - Don't expose exact location unless `show_google_location` is true
   - Allow users to hide/archive demandes

---

**Last Updated:** March 6, 2024  
**Version:** 1.0  
**Maintained by:** Development Team
