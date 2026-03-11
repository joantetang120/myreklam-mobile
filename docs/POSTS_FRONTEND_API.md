# Posts API - Frontend Integration Guide

> Complete API reference for creating and managing posts (publications) in the mobile app.
> Derived from `lib/screens/create_post_screen.dart`.

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Data Model](#data-model)
4. [CRUD Endpoints](#crud-endpoints)
5. [Media Uploads](#media-uploads)
6. [Validation Rules & Notes](#validation-rules--notes)
7. [Request/Response Examples](#requestresponse-examples)

---

## Overview

**Base URL:** `http://<server>:8000/api`

All endpoints require authentication via Bearer token (Sanctum).

The **Posts** module allows authenticated users to publish short-form content ("quoi de neuf?") visible to their community. A post consists of:
- A text body (required)
- A privacy/visibility setting
- Optional media attachments (photos / videos)
- Optional location tag

---

## Authentication

Include in all requests:

```
Authorization: Bearer {token}
Accept: application/json
```

---

## Data Model

### Post Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | integer | — | Auto-generated primary key |
| `user_id` | integer | — | Author (set server-side from token) |
| `content` | string (max 5000) | **Yes** | The post text body |
| `visibility` | enum | **Yes** | `public`, `friends`, `private` — defaults to `public` |
| `location_label` | string (max 255) | No | Human-readable place name (e.g. "Paris, France") |
| `latitude` | decimal(10,8) | No | GPS latitude of the location tag |
| `longitude` | decimal(11,8) | No | GPS longitude of the location tag |
| `status` | enum | — | `draft`, `published` — server-managed |
| `created_at` | timestamp | — | Creation timestamp |
| `updated_at` | timestamp | — | Last update timestamp |

### Post Media Object (joined)

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Media record ID |
| `post_id` | integer | Parent post |
| `url` | string | Publicly accessible URL of the file |
| `file_type` | enum | `image` or `video` |
| `file_size` | integer | File size in bytes |
| `order_index` | integer | Display order (0-based) |

### Visibility Options

| Value | Label (FR) |
|-------|-----------|
| `public` | Public |
| `friends` | Amis |
| `private` | Privé |

---

## CRUD Endpoints

### Create a Post

```
POST /posts
Content-Type: application/json
Authorization: Bearer {token}
```

**Request body:**

```json
{
  "content": "Quoi de neuf aujourd'hui ! 🎉",
  "visibility": "public",
  "location_label": "Paris, France",
  "latitude": 48.8566,
  "longitude": 2.3522
}
```

> `location_label`, `latitude`, and `longitude` are **optional**. Include all three or none.

**Success response `201`:**

```json
{
  "success": true,
  "message": "Post publié avec succès.",
  "data": {
    "id": 42,
    "user_id": 7,
    "content": "Quoi de neuf aujourd'hui ! 🎉",
    "visibility": "public",
    "location_label": "Paris, France",
    "latitude": "48.85660000",
    "longitude": "2.35220000",
    "status": "published",
    "media_files": [],
    "created_at": "2026-03-07T14:00:00.000000Z",
    "updated_at": "2026-03-07T14:00:00.000000Z"
  }
}
```

---

### List My Posts

```
GET /posts
Authorization: Bearer {token}
```

**Query parameters (all optional):**

| Param | Type | Description |
|-------|------|-------------|
| `page` | integer | Page number for pagination (default: 1) |
| `per_page` | integer | Items per page (default: 15, max: 50) |
| `visibility` | string | Filter by visibility: `public`, `friends`, `private` |

**Success response `200`:**

```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 42,
        "content": "Quoi de neuf aujourd'hui ! 🎉",
        "visibility": "public",
        "location_label": "Paris, France",
        "status": "published",
        "media_files": [
          {
            "id": 5,
            "url": "/storage/posts/42/photo.jpg",
            "file_type": "image",
            "order_index": 0
          }
        ],
        "created_at": "2026-03-07T14:00:00.000000Z"
      }
    ],
    "current_page": 1,
    "last_page": 3,
    "total": 38
  }
}
```

---

### Get a Single Post

```
GET /posts/{id}
Authorization: Bearer {token}
```

**Success response `200`:** same shape as a single item in the list above.

---

### Update a Post

```
PUT /posts/{id}
Content-Type: application/json
Authorization: Bearer {token}
```

**Request body** (all fields optional — send only what changed):

```json
{
  "content": "Contenu mis à jour.",
  "visibility": "friends",
  "location_label": null,
  "latitude": null,
  "longitude": null
}
```

> Pass `null` for location fields to remove a previously set location.

**Success response `200`:**

```json
{
  "success": true,
  "message": "Post mis à jour.",
  "data": { "...updated post object..." }
}
```

---

### Delete a Post

```
DELETE /posts/{id}
Authorization: Bearer {token}
```

**Success response `200`:**

```json
{
  "success": true,
  "message": "Post supprimé."
}
```

---

## Media Uploads

Media is uploaded **after** the post is created, using the post `id`.

### Upload Media

```
POST /posts/{id}/media
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

**Form fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `files[]` | file (multiple) | **Yes** | One or more image/video files |
| `order_index` | integer | No | Starting order index (default: 0) |

**Accepted MIME types:**
- Images: `image/jpeg`, `image/png`, `image/gif`, `image/webp`
- Videos: `video/mp4`, `video/quicktime`, `video/x-msvideo`

**Max file size:** 20 MB per file

**Success response `201`:**

```json
{
  "success": true,
  "message": "Médias ajoutés.",
  "data": [
    {
      "id": 5,
      "post_id": 42,
      "url": "/storage/posts/42/photo.jpg",
      "file_type": "image",
      "file_size": 204800,
      "order_index": 0
    }
  ]
}
```

---

### Delete a Media File

```
DELETE /posts/{id}/media/{mediaId}
Authorization: Bearer {token}
```

**Success response `200`:**

```json
{
  "success": true,
  "message": "Média supprimé."
}
```

---

## Validation Rules & Notes

| Field | Rule |
|-------|------|
| `content` | Required, string, min 1 char, max 5000 chars |
| `visibility` | Required, one of: `public`, `friends`, `private` |
| `location_label` | Optional, string, max 255 chars |
| `latitude` | Optional, numeric, between -90 and 90. Required if `longitude` is provided |
| `longitude` | Optional, numeric, between -180 and 180. Required if `latitude` is provided |

**Business rules:**
- A post can have a maximum of **10 media files**.
- Deleting a post also deletes all its associated media files (cascade).
- Only the post author can update or delete their post.
- `location_label` is the display string shown in the UI (e.g. "Paris, France"). GPS coordinates are optional on top of it.

---

## Request/Response Examples

### Flutter — Create Post (text only)

```dart
final response = await ApiClient().authenticatedPost(
  '/posts',
  body: {
    'content': _postController.text.trim(),
    'visibility': _selectedPrivacy.toLowerCase(),
  },
);
```

### Flutter — Create Post with Location

```dart
final response = await ApiClient().authenticatedPost(
  '/posts',
  body: {
    'content': _postController.text.trim(),
    'visibility': _selectedPrivacy.toLowerCase(),
    'location_label': _locationLabel,
    'latitude': _latitude,
    'longitude': _longitude,
  },
);
```

### Flutter — Upload Media after Post Creation

```dart
final postId = response['data']['id'];
final request = http.MultipartRequest(
  'POST',
  Uri.parse('${ApiConfig.baseUrl}/posts/$postId/media'),
);
request.headers['Authorization'] = 'Bearer $token';
for (final file in _selectedMediaFiles) {
  request.files.add(
    await http.MultipartFile.fromPath('files[]', file.path),
  );
}
final streamedResponse = await request.send();
```

### Error Response — Validation Failure `422`

```json
{
  "success": false,
  "message": "Les données fournies sont invalides.",
  "errors": {
    "content": ["Le contenu est obligatoire."],
    "latitude": ["La latitude est requise quand la longitude est fournie."]
  }
}
```

### Error Response — Unauthorized `401`

```json
{
  "success": false,
  "message": "Non authentifié."
}
```

### Error Response — Not Found `404`

```json
{
  "success": false,
  "message": "Post introuvable."
}
```
