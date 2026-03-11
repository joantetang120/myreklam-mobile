# Events API - Frontend Integration Guide

> Complete API reference for creating and managing events (événements) in the mobile app.

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

### `GET /events/meta`

Returns constants to populate dropdowns and pickers.

```json
{
  "success": true,
  "data": {
    "format_types": {
      "Présentielonline": "Présentielonline",
      "En ligne": "En ligne",
      "Hybride": "Hybride"
    },
    "price_types": {
      "gratuit": "Gratuit",
      "payant": "Payant"
    },
    "reservation_modes": {
      "sans_inscription": "Sans inscription",
      "inscription": "Inscription requise",
      "achat_billet": "Achat de billet obligatoire"
    },
    "duration_types": {
      "one_day": "Sur une journée",
      "multi_day": "Sur plusieurs jours",
      "permanent": "Permanent"
    },
    "statuses": ["draft", "pending", "published", "rejected", "archived"]
  }
}
```

> **Tip:** You can send either the key (`"one_day"`) or display value (`"Sur une journée"`). The backend normalizes both.

---

## CRUD Endpoints

All under `Bearer` auth.

### 1. List Events — `GET /events`

Query params:
- `status` (optional): filter by workflow status.
- `per_page` (1-50, default 15)
- `page`

Response: paginated array of events owned by the user. Each event includes `media_files` URLs.

### 2. Create Event — `POST /events`

Body fields follow the spec:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `category_code` | string | ✅ | Must exist in `event_categories`. |
| `sub_category_code` | string | ✅ | Must be child of category. |
| `format_type` | string | ✅ | See metadata. |
| `title` | string (≤160) | ✅ | |
| `description` | string | ✅ | HTML/Quill output. |
| `description_delta` | array | ❌ | Raw Quill delta. |
| `landing_url` | url | ❌ | |
| `is_organizer` | bool | ❌ (default true) | When false, `organizer_name` required. |
| `organizer_name` | string | conditional | |
| `coverage_area` | string | ❌ | City/region text. |
| `is_nationwide` | bool | ❌ | "Toute la France" toggle. |
| `location_country` | string(2) | ❌ | ISO code if available. |
| `price_type` | enum | ✅ | `gratuit` or `payant`. |
| `price_amount` | number | conditional | Required >0 when payant. Must be null when gratuit. |
| `reservation_mode` | enum | ✅ | |
| `website_url` | url | ❌ | |
| `duration_type` | enum | ✅ | `one_day`, `multi_day`, `permanent`. |
| `event_date` | date | conditional | Required if `one_day`. |
| `start_date`/`end_date` | date | conditional | Both required if `multi_day`. End ≥ start. |
| `start_time`/`end_time` | `HH:MM` | optional | If either provided, both required and end must be after start. |
| `initial_price` / `final_price` / `discount_value` | number | ❌ | Optional commercial data. |
| `accept_messages` | bool | ❌ | Default false. |
| `status` | enum | ❌ | Defaults to `draft`. |

Response:
```json
{
  "success": true,
  "message": "Événement créé avec succès",
  "data": {
    "id": "uuid",
    "status": "draft",
    "created_at": "2026-03-06T11:00:00.000000Z"
  }
}
```

### 3. Get Event — `GET /events/{id}`

Returns the full record (same fields as create) + `media_files` + `stats` (view/click counts) and timestamps.

### 4. Update Event — `PUT /events/{id}`

Body: same as create, all fields optional. Validation rules (price/dates/times) still apply.

### 5. Delete Event — `DELETE /events/{id}`

Soft-deletes the record.

---

## Media Uploads

### `POST /events/{id}/media`

- `multipart/form-data`
- Field: `media[]`
- Allowed types: `jpg,jpeg,png,gif,mp4,mov,avi`
- Max size: 50MB per file
- Response returns uploaded items (`id`, `url`, `type`, `size`). Use returned `id` to delete.

### `DELETE /events/{id}/media/{mediaId}`

Removes a specific media file.

---

## Validation Rules & Notes

1. **Category linkage:** `sub_category_code` must belong to `category_code`. Backend enforces this.
2. **Organizer logic:** if `is_organizer` is `false`, `organizer_name` becomes required.
3. **Pricing:**
   - `payant` ⇒ `price_amount > 0`
   - `gratuit` ⇒ `price_amount` must be null/omitted
4. **Duration types:**
   - `one_day` ⇒ `event_date` required.
   - `multi_day` ⇒ `start_date` and `end_date` required, end ≥ start.
   - `permanent` ⇒ dates optional.
5. **Times:** start/end times must both be supplied, end strictly greater than start.
6. **Labels or codes:** For enums you can send either the machine code or the French display label; backend normalizes.

---

## Request/Response Examples

### Create Event (JSON)

```json
{
  "category_code": "ProfessionalNetworking",
  "sub_category_code": "AfterworkTeamBuilding",
  "format_type": "Offre spéciale",
  "title": "Afterwork inclusive Lyon",
  "description": "<p>Rencontre ouverte...</p>",
  "description_delta": {
    "ops": [
      {"insert": "Rencontre ouverte...\n"}
    ]
  },
  "landing_url": "https://example.com",
  "is_organizer": false,
  "organizer_name": "Collectif Diversité",
  "coverage_area": "Lyon et région",
  "is_nationwide": false,
  "price_type": "payant",
  "price_amount": 25,
  "reservation_mode": "inscription",
  "duration_type": "multi_day",
  "start_date": "2026-05-10",
  "end_date": "2026-05-12",
  "start_time": "18:00",
  "end_time": "22:00",
  "accept_messages": true,
  "status": "draft"
}
```

### Show Event (response excerpt)

```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "category_code": "ProfessionalNetworking",
    "sub_category_code": "AfterworkTeamBuilding",
    "format_type": "offre_speciale",
    "title": "Afterwork inclusive Lyon",
    "description": "<p>Rencontre ouverte...</p>",
    "is_organizer": false,
    "organizer_name": "Collectif Diversité",
    "coverage_area": "Lyon et région",
    "is_nationwide": false,
    "price_type": "payant",
    "price_amount": "25.00",
    "duration_type": "multi_day",
    "start_date": "2026-05-10",
    "end_date": "2026-05-12",
    "start_time": "18:00:00",
    "end_time": "22:00:00",
    "accept_messages": true,
    "status": "pending",
    "media_files": [
      {"id": "uuid", "url": "https://.../image.jpg", "type": "image", "size": 153600}
    ],
    "stats": {
      "view_count": 0,
      "click_count": 0,
      "contact_requests": 0
    },
    "created_at": "2026-03-06T11:00:00.000000Z",
    "updated_at": "2026-03-06T11:00:00.000000Z"
  }
}
```

---

## Frontend Checklist

1. Fetch `/events/meta` on form load.
2. Fetch categories/subcategories via existing `Categorie.php` integration.
3. Normalize booleans before sending (true/false, not strings).
4. For enums, send backend keys when possible; labels also accepted.
5. Ensure multipart uploads use `media[]`.
6. Handle validation errors from API (422) to highlight offending fields.

This API mirrors the trainings flow, so you can reuse pagination, editing, and media upload components with minor adjustments.
