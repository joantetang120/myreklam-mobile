  # Posts API - Complete Documentation

> Full API reference for creating and managing posts in the MyReklam mobile application.

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Data Model](#data-model)
4. [Public Endpoints](#public-endpoints)
5. [Protected Endpoints](#protected-endpoints)
6. [Media Management](#media-management)
7. [Validation Rules](#validation-rules)
8. [Request/Response Examples](#requestresponse-examples)
9. [Error Handling](#error-handling)

---

## Overview

**Base URL:** `http://<server>:8000/api`

The Posts module enables authenticated users to publish short-form content ("Quoi de neuf?") visible to their community. Posts support:
- Text content (up to 5000 characters)
- Privacy/visibility settings (public, friends, private)
- Optional location tagging with GPS coordinates
- Media attachments (photos and videos)
- Soft deletes for data retention

---

## Authentication

All protected endpoints require Bearer token authentication via Laravel Sanctum.

**Headers:**
```
Authorization: Bearer {your_access_token}
Accept: application/json
Content-Type: application/json
```

For media uploads, use:
```
Authorization: Bearer {your_access_token}
Content-Type: multipart/form-data
```

---

## Data Model

### Post Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique post identifier |
| `user_id` | integer | Author's user ID (auto-set from token) |
| `content` | string | Post text content (1-5000 chars) |
| `visibility` | enum | `public`, `friends`, or `private` |
| `location_label` | string | Human-readable location (e.g., "Paris, France") |
| `latitude` | decimal(10,8) | GPS latitude coordinate |
| `longitude` | decimal(11,8) | GPS longitude coordinate |
| `status` | enum | `draft` or `published` (server-managed) |
| `media_files` | array | Array of attached media objects |
| `created_at` | timestamp | Creation date/time |
| `updated_at` | timestamp | Last modification date/time |

### Media Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Media file identifier |
| `post_id` | integer | Parent post ID |
| `url` | string | Public URL to access the file |
| `file_type` | string | `image` or `video` |
| `file_size` | integer | File size in bytes |
| `order_index` | integer | Display order (0-based) |

### Visibility Options

| Value | Label (French) | Description |
|-------|---------------|-------------|
| `public` | Public | Visible to everyone |
| `friends` | Amis | Visible to friends only |
| `private` | Privé | Visible only to author |

---

## Public Endpoints

### Get Latest Posts

Retrieve the 4 most recent public posts.

```http
GET /api/posts/latest
```

**Authentication:** Not required

**Response 200 OK:**
```json
{
  "success": true,
  "data": [
    {
      "id": 42,
      "user_id": 7,
      "content": "Quoi de neuf aujourd'hui ! 🎉",
      "visibility": "public",
      "location_label": "Paris, France",
      "latitude": "48.85660000",
      "longitude": "2.35220000",
      "status": "published",
      "media_files": [
        {
          "id": 5,
          "url": "/storage/posts/42/photo.jpg",
          "file_type": "image",
          "order_index": 0
        }
      ],
      "user": {
        "id": 7,
        "name": "John Doe",
        "email": "john@example.com"
      },
      "created_at": "2026-03-07T14:00:00.000000Z",
      "updated_at": "2026-03-07T14:00:00.000000Z"
    }
  ]
}
```

**Notes:**
- Returns only posts with `status = 'published'` and `visibility = 'public'`
- Ordered by creation date (newest first)
- Limited to 4 posts
- Includes user information and media files

---

## Protected Endpoints

All endpoints below require authentication.

### 1. List My Posts

Retrieve paginated list of posts created by the authenticated user.

```http
GET /api/posts
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number |
| `per_page` | integer | No | 15 | Items per page (max 50) |
| `visibility` | string | No | - | Filter by visibility: `public`, `friends`, `private` |

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 42,
        "content": "Quoi de neuf aujourd'hui ! 🎉",
        "visibility": "public",
        "location_label": "Paris, France",
        "latitude": "48.85660000",
        "longitude": "2.35220000",
        "status": "published",
        "media_files": [
          {
            "id": 5,
            "url": "/storage/posts/42/photo.jpg",
            "file_type": "image",
            "order_index": 0
          }
        ],
        "created_at": "2026-03-07T14:00:00.000000Z",
        "updated_at": "2026-03-07T14:00:00.000000Z"
      }
    ],
    "first_page_url": "http://localhost:8000/api/posts?page=1",
    "from": 1,
    "last_page": 3,
    "last_page_url": "http://localhost:8000/api/posts?page=3",
    "next_page_url": "http://localhost:8000/api/posts?page=2",
    "path": "http://localhost:8000/api/posts",
    "per_page": 15,
    "prev_page_url": null,
    "to": 15,
    "total": 38
  }
}
```

---

### 2. Create Post

Publish a new post.

```http
POST /api/posts
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "content": "Quoi de neuf aujourd'hui ! 🎉",
  "visibility": "public",
  "location_label": "Paris, France",
  "latitude": 48.8566,
  "longitude": 2.3522
}
```

**Required Fields:**
- `content` - Post text (1-5000 characters)
- `visibility` - One of: `public`, `friends`, `private`

**Optional Fields:**
- `location_label` - Location name (max 255 chars)
- `latitude` - GPS latitude (-90 to 90)
- `longitude` - GPS longitude (-180 to 180)
- `status` - Defaults to `published`

**Response 201 Created:**
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

### 3. Get Single Post

Retrieve details of a specific post.

```http
GET /api/posts/{id}
Authorization: Bearer {token}
```

**Path Parameters:**
- `id` - Post ID

**Authorization:** Only the post author can view their own posts

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
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
    "created_at": "2026-03-07T14:00:00.000000Z",
    "updated_at": "2026-03-07T14:00:00.000000Z"
  }
}
```

---

### 4. Update Post

Modify an existing post.

```http
PUT /api/posts/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters:**
- `id` - Post ID

**Request Body (all fields optional):**
```json
{
  "content": "Contenu mis à jour.",
  "visibility": "friends",
  "location_label": null,
  "latitude": null,
  "longitude": null
}
```

**Notes:**
- Send only the fields you want to update
- Pass `null` to remove location data
- Only the post author can update

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Post mis à jour.",
  "data": {
    "id": 42,
    "content": "Contenu mis à jour.",
    "visibility": "friends",
    "location_label": null,
    "latitude": null,
    "longitude": null,
    "status": "published",
    "media_files": [],
    "created_at": "2026-03-07T14:00:00.000000Z",
    "updated_at": "2026-03-07T15:30:00.000000Z"
  }
}
```

---

### 5. Delete Post

Permanently delete a post (soft delete).

```http
DELETE /api/posts/{id}
Authorization: Bearer {token}
```

**Path Parameters:**
- `id` - Post ID

**Authorization:** Only the post author can delete

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Post supprimé."
}
```

**Notes:**
- Post is soft-deleted (marked with `deleted_at` timestamp)
- All associated media files are also deleted from storage

---

## Media Management

### Upload Media Files

Add photos or videos to an existing post.

```http
POST /api/posts/{id}/media
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Path Parameters:**
- `id` - Post ID

**Form Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `files[]` | file | Yes | One or more media files (array) |
| `order_index` | integer | No | Starting order index (default: 0) |

**File Constraints:**
- **Accepted types:** jpg, jpeg, png, gif, webp, mp4, quicktime, x-msvideo
- **Max file size:** 20 MB per file
- **Max files:** 10 files per upload
- **Total limit:** 10 media files per post

**Response 201 Created:**
```json
{
  "success": true,
  "message": "Médias ajoutés.",
  "data": [
    {
      "id": 5,
      "post_id": 42,
      "url": "/storage/posts/42/abc123.jpg",
      "file_type": "image",
      "file_size": 204800,
      "order_index": 0
    },
    {
      "id": 6,
      "post_id": 42,
      "url": "/storage/posts/42/def456.mp4",
      "file_type": "video",
      "file_size": 1048576,
      "order_index": 1
    }
  ]
}
```

---

### Delete Media File

Remove a specific media file from a post.

```http
DELETE /api/posts/{id}/media/{mediaId}
Authorization: Bearer {token}
```

**Path Parameters:**
- `id` - Post ID
- `mediaId` - Media file ID

**Authorization:** Only the post author can delete media

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Média supprimé."
}
```

**Notes:**
- File is permanently deleted from storage
- Database record is also removed

---

## Validation Rules

### Post Fields

| Field | Validation |
|-------|-----------|
| `content` | Required, string, min 1 char, max 5000 chars |
| `visibility` | Required, one of: `public`, `friends`, `private` |
| `location_label` | Optional, string, max 255 chars |
| `latitude` | Optional, numeric, between -90 and 90 |
| `longitude` | Optional, numeric, between -180 and 180 |
| `status` | Optional, one of: `draft`, `published` |

### Cross-Field Validation

**Location Coordinates:**
- If `latitude` is provided, `longitude` is required
- If `longitude` is provided, `latitude` is required
- Both can be `null` to remove location

### Media Upload Validation

| Rule | Value |
|------|-------|
| Max files per upload | 10 |
| Max file size | 20 MB (20480 KB) |
| Allowed image types | jpg, jpeg, png, gif, webp |
| Allowed video types | mp4, quicktime, x-msvideo |
| Max media per post | 10 files total |

---

## Request/Response Examples

### Example 1: Create Text-Only Post

**Request:**
```http
POST /api/posts
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json

{
  "content": "Belle journée aujourd'hui ! ☀️",
  "visibility": "public"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Post publié avec succès.",
  "data": {
    "id": 43,
    "user_id": 7,
    "content": "Belle journée aujourd'hui ! ☀️",
    "visibility": "public",
    "location_label": null,
    "latitude": null,
    "longitude": null,
    "status": "published",
    "media_files": [],
    "created_at": "2026-03-07T15:00:00.000000Z",
    "updated_at": "2026-03-07T15:00:00.000000Z"
  }
}
```

---

### Example 2: Create Post with Location

**Request:**
```http
POST /api/posts
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json

{
  "content": "Visite du Louvre 🎨",
  "visibility": "friends",
  "location_label": "Musée du Louvre, Paris",
  "latitude": 48.8606,
  "longitude": 2.3376
}
```

**Response:**
```json
{
  "success": true,
  "message": "Post publié avec succès.",
  "data": {
    "id": 44,
    "user_id": 7,
    "content": "Visite du Louvre 🎨",
    "visibility": "friends",
    "location_label": "Musée du Louvre, Paris",
    "latitude": "48.86060000",
    "longitude": "2.33760000",
    "status": "published",
    "media_files": [],
    "created_at": "2026-03-07T15:15:00.000000Z",
    "updated_at": "2026-03-07T15:15:00.000000Z"
  }
}
```

---

### Example 3: Upload Media After Creating Post

**Request:**
```http
POST /api/posts/44/media
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: multipart/form-data

files[]: (binary - photo1.jpg)
files[]: (binary - photo2.jpg)
order_index: 0
```

**Response:**
```json
{
  "success": true,
  "message": "Médias ajoutés.",
  "data": [
    {
      "id": 7,
      "post_id": 44,
      "url": "/storage/posts/44/f47ac10b.jpg",
      "file_type": "image",
      "file_size": 312456,
      "order_index": 0
    },
    {
      "id": 8,
      "post_id": 44,
      "url": "/storage/posts/44/c81e728d.jpg",
      "file_type": "image",
      "file_size": 289012,
      "order_index": 1
    }
  ]
}
```

---

### Example 4: Update Post Visibility

**Request:**
```http
PUT /api/posts/44
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: application/json

{
  "visibility": "public"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Post mis à jour.",
  "data": {
    "id": 44,
    "content": "Visite du Louvre 🎨",
    "visibility": "public",
    "location_label": "Musée du Louvre, Paris",
    "status": "published",
    "media_files": [
      {
        "id": 7,
        "url": "/storage/posts/44/f47ac10b.jpg",
        "file_type": "image",
        "order_index": 0
      }
    ],
    "created_at": "2026-03-07T15:15:00.000000Z",
    "updated_at": "2026-03-07T15:45:00.000000Z"
  }
}
```

---

### Example 5: Filter Posts by Visibility

**Request:**
```http
GET /api/posts?visibility=public&per_page=5
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 44,
        "content": "Visite du Louvre 🎨",
        "visibility": "public",
        "status": "published",
        "created_at": "2026-03-07T15:15:00.000000Z"
      },
      {
        "id": 43,
        "content": "Belle journée aujourd'hui ! ☀️",
        "visibility": "public",
        "status": "published",
        "created_at": "2026-03-07T15:00:00.000000Z"
      }
    ],
    "per_page": 5,
    "total": 2
  }
}
```

---

## Error Handling

### Validation Error (422)

**Request:**
```json
{
  "content": "",
  "visibility": "invalid"
}
```

**Response:**
```json
{
  "success": false,
  "message": "Les données fournies sont invalides.",
  "errors": {
    "content": ["Le contenu est obligatoire."],
    "visibility": ["La visibilité sélectionnée est invalide."]
  }
}
```

---

### Unauthorized (401)

**Response:**
```json
{
  "success": false,
  "message": "Non authentifié."
}
```

---

### Forbidden (403)

**Response:**
```json
{
  "success": false,
  "message": "Non autorisé."
}
```

**Cause:** Attempting to access/modify another user's post

---

### Not Found (404)

**Response:**
```json
{
  "success": false,
  "message": "Post introuvable."
}
```

---

### Location Validation Error (422)

**Request:**
```json
{
  "content": "Test post",
  "visibility": "public",
  "latitude": 48.8566
}
```

**Response:**
```json
{
  "success": false,
  "message": "Les données fournies sont invalides.",
  "errors": {
    "longitude": ["La longitude est requise quand la latitude est fournie."]
  }
}
```

---

### Media Upload Error (422)

**Request:** File exceeds 20MB

**Response:**
```json
{
  "success": false,
  "message": "Les données fournies sont invalides.",
  "errors": {
    "files.0": ["Le fichier ne doit pas dépasser 20480 kilobytes."]
  }
}
```

---

## Status Codes Summary

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PUT, DELETE |
| 201 | Created | Successful POST (create) |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Not authorized to access resource |
| 404 | Not Found | Post or media not found |
| 422 | Unprocessable Entity | Validation errors |
| 500 | Internal Server Error | Server error |

---

## Implementation Notes

### Frontend Integration

**Flutter Example - Create Post:**
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

**Flutter Example - Upload Media:**
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

### Backend Features

- **Soft Deletes:** Posts are never permanently removed, allowing for recovery
- **Cascade Deletes:** Deleting a post removes all associated media files
- **Authorization:** Ownership checks on all update/delete operations
- **File Storage:** Media stored in `storage/app/public/posts/{post_id}/`
- **Pagination:** Efficient data loading with configurable page sizes

---

**Last Updated:** March 7, 2026  
**Version:** 1.0  
**API Version:** v1  
**Maintained by:** Development Team
