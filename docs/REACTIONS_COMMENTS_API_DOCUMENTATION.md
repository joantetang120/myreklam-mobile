# Reactions & Comments API - Frontend Documentation

> Unified like/dislike and commenting system for all MyReklam entities.

---

## Table of Contents

1. [Overview](#overview)
2. [Supported Entity Types](#supported-entity-types)
3. [Reactions (Likes / Dislikes)](#reactions-likes--dislikes)
4. [Comments](#comments)
5. [Replies](#replies)
6. [Comment Reactions](#comment-reactions)
7. [Error Handling](#error-handling)

---

## Overview

**Base URL:** `http://<server>:8000/api`

All endpoints require authentication:
```
Authorization: Bearer {token}
Accept: application/json
```

The reactions and comments system uses a **unified polymorphic approach** — the same endpoints work identically across all entity types. Simply swap the `{entityType}` segment in the URL.

---

## Supported Entity Types

| URL Segment | Entity |
|-------------|--------|
| `posts` | Posts |
| `bon-plans` | Bon Plans |
| `trainings` | Trainings / Formations |
| `events` | Events / Événements |
| `demandes` | Demandes |
| `job-offers` | Job Offers / Offres d'emploi |
| `comments` | Comments (reactions only) |

**Entity IDs:**
- `posts` and `demandes` use **integer** IDs (e.g., `42`)
- `bon-plans`, `trainings`, `events`, `job-offers` use **UUID** IDs (e.g., `9c5a7b2e-...`)

---

## Reactions (Likes / Dislikes)

### Toggle Reaction

Like or dislike any entity. Calling again with the **same type** removes the reaction. Calling with a **different type** switches it.

```http
POST /api/{entityType}/{entityId}/reactions
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "type": "like"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `type` | string | Yes | `like` or `dislike` |

**Behavior:**
- **No existing reaction** → Creates the reaction
- **Same type exists** → Removes the reaction (toggle off)
- **Different type exists** → Switches to new type

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Réaction enregistrée.",
  "data": {
    "likes_count": 12,
    "dislikes_count": 3,
    "user_reaction": "like"
  }
}
```

When toggled off:
```json
{
  "success": true,
  "message": "Réaction retirée.",
  "data": {
    "likes_count": 11,
    "dislikes_count": 3,
    "user_reaction": null
  }
}
```

---

### Get Reaction Counts

Retrieve like/dislike counts and the current user's reaction for an entity.

```http
GET /api/{entityType}/{entityId}/reactions
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "likes_count": 12,
    "dislikes_count": 3,
    "user_reaction": "like"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `likes_count` | integer | Total likes on this entity |
| `dislikes_count` | integer | Total dislikes on this entity |
| `user_reaction` | string/null | Current user's reaction: `"like"`, `"dislike"`, or `null` |

---

### Examples for Each Entity Type

**Like a Post:**
```http
POST /api/posts/42/reactions
{ "type": "like" }
```

**Dislike a Bon Plan:**
```http
POST /api/bon-plans/9c5a7b2e-1234-5678-abcd-ef0123456789/reactions
{ "type": "dislike" }
```

**Get reactions on a Training:**
```http
GET /api/trainings/a1b2c3d4-5678-90ab-cdef-1234567890ab/reactions
```

**Like an Event:**
```http
POST /api/events/f47ac10b-58cc-4372-a567-0e02b2c3d479/reactions
{ "type": "like" }
```

**Like a Demande:**
```http
POST /api/demandes/15/reactions
{ "type": "like" }
```

**Like a Job Offer:**
```http
POST /api/job-offers/b8c7d6e5-4321-0987-fedc-ba9876543210/reactions
{ "type": "like" }
```

---

## Comments

### List Comments

Get paginated top-level comments for an entity, with nested replies.

```http
GET /api/{entityType}/{entityId}/comments
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `per_page` | integer | 15 | Items per page (max 50) |

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 101,
        "user": {
          "id": 7,
          "email": "john@example.com"
        },
        "body": "Super post, merci pour le partage !",
        "parent_id": null,
        "likes_count": 5,
        "dislikes_count": 0,
        "user_reaction": null,
        "replies_count": 2,
        "created_at": "2026-03-10T10:30:00.000000Z",
        "updated_at": "2026-03-10T10:30:00.000000Z",
        "replies": [
          {
            "id": 102,
            "user": {
              "id": 3,
              "email": "jane@example.com"
            },
            "body": "Tout à fait d'accord !",
            "parent_id": 101,
            "likes_count": 1,
            "dislikes_count": 0,
            "user_reaction": "like",
            "replies_count": 0,
            "created_at": "2026-03-10T10:45:00.000000Z",
            "updated_at": "2026-03-10T10:45:00.000000Z"
          }
        ]
      }
    ],
    "per_page": 15,
    "total": 8
  }
}
```

**Comment Object:**

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Comment ID |
| `user` | object | Author info (`id`, `email`) |
| `body` | string | Comment text |
| `parent_id` | integer/null | Parent comment ID (null for top-level) |
| `likes_count` | integer | Number of likes on this comment |
| `dislikes_count` | integer | Number of dislikes on this comment |
| `user_reaction` | string/null | Current user's reaction on this comment |
| `replies_count` | integer | Number of direct replies |
| `replies` | array | Nested reply objects (on top-level comments) |
| `created_at` | string | ISO 8601 timestamp |
| `updated_at` | string | ISO 8601 timestamp |

---

### Add Comment

Post a new top-level comment on any entity.

```http
POST /api/{entityType}/{entityId}/comments
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "body": "Super post, merci pour le partage !"
}
```

| Field | Type | Required | Max |
|-------|------|----------|-----|
| `body` | string | Yes | 2000 chars |

**Response 201 Created:**
```json
{
  "success": true,
  "message": "Commentaire ajouté.",
  "data": {
    "id": 101,
    "user": {
      "id": 7,
      "email": "john@example.com"
    },
    "body": "Super post, merci pour le partage !",
    "parent_id": null,
    "likes_count": 0,
    "dislikes_count": 0,
    "user_reaction": null,
    "replies_count": 0,
    "created_at": "2026-03-10T10:30:00.000000Z",
    "updated_at": "2026-03-10T10:30:00.000000Z"
  }
}
```

---

## Replies

### Reply to a Comment

Add a reply to an existing top-level comment. Replies are **one level deep only** (no nested replies to replies).

```http
POST /api/{entityType}/{entityId}/comments/{commentId}/reply
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters:**
- `entityType` — Entity type slug
- `entityId` — Entity ID
- `commentId` — Parent comment ID (must be a top-level comment)

**Request Body:**
```json
{
  "body": "Tout à fait d'accord !"
}
```

**Response 201 Created:**
```json
{
  "success": true,
  "message": "Réponse ajoutée.",
  "data": {
    "id": 102,
    "user": {
      "id": 3,
      "email": "jane@example.com"
    },
    "body": "Tout à fait d'accord !",
    "parent_id": 101,
    "likes_count": 0,
    "dislikes_count": 0,
    "user_reaction": null,
    "replies_count": 0,
    "created_at": "2026-03-10T10:45:00.000000Z",
    "updated_at": "2026-03-10T10:45:00.000000Z"
  }
}
```

---

### Edit Comment

Update your own comment or reply.

```http
PUT /api/comments/{commentId}
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "body": "Texte mis à jour."
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Commentaire mis à jour.",
  "data": {
    "id": 101,
    "user": {
      "id": 7,
      "email": "john@example.com"
    },
    "body": "Texte mis à jour.",
    "parent_id": null,
    "likes_count": 5,
    "dislikes_count": 0,
    "user_reaction": null,
    "replies_count": 2,
    "created_at": "2026-03-10T10:30:00.000000Z",
    "updated_at": "2026-03-10T11:00:00.000000Z"
  }
}
```

**Note:** Only the comment author can edit.

---

### Delete Comment

Delete your own comment. Deleting a top-level comment also removes all its replies.

```http
DELETE /api/comments/{commentId}
Authorization: Bearer {token}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Commentaire supprimé."
}
```

**Note:** Only the comment author can delete. Uses soft delete.

---

## Comment Reactions

You can like/dislike comments using the same reaction endpoints with `comments` as the entity type.

**Like a comment:**
```http
POST /api/comments/101/reactions
Authorization: Bearer {token}
Content-Type: application/json

{ "type": "like" }
```

**Response:**
```json
{
  "success": true,
  "message": "Réaction enregistrée.",
  "data": {
    "likes_count": 6,
    "dislikes_count": 0,
    "user_reaction": "like"
  }
}
```

**Get comment reactions:**
```http
GET /api/comments/101/reactions
Authorization: Bearer {token}
```

---

## Error Handling

### Validation Error (422)

```json
{
  "success": false,
  "message": "Les données fournies sont invalides.",
  "errors": {
    "type": ["Le champ type est obligatoire."],
    "body": ["Le commentaire ne doit pas dépasser 2000 caractères."]
  }
}
```

### Not Found (404)

```json
{
  "success": false,
  "message": "Ressource introuvable."
}
```

### Forbidden (403)

```json
{
  "success": false,
  "message": "Non autorisé."
}
```

### Unauthorized (401)

```json
{
  "success": false,
  "message": "Non authentifié."
}
```

---

## Quick Reference — All Routes

### Reactions

| Method | URL | Description |
|--------|-----|-------------|
| `POST` | `/api/{entityType}/{entityId}/reactions` | Toggle like/dislike |
| `GET` | `/api/{entityType}/{entityId}/reactions` | Get reaction counts |

### Comments

| Method | URL | Description |
|--------|-----|-------------|
| `GET` | `/api/{entityType}/{entityId}/comments` | List comments (paginated) |
| `POST` | `/api/{entityType}/{entityId}/comments` | Add a comment |
| `POST` | `/api/{entityType}/{entityId}/comments/{commentId}/reply` | Reply to a comment |
| `PUT` | `/api/comments/{commentId}` | Edit own comment |
| `DELETE` | `/api/comments/{commentId}` | Delete own comment |

### Entity Type Slugs

| Slug | Model |
|------|-------|
| `posts` | Post |
| `bon-plans` | BonPlan |
| `trainings` | Training |
| `events` | Event |
| `demandes` | Demande |
| `job-offers` | JobOffer |
| `comments` | Comment (reactions only) |

---

## Flutter Integration Examples

### Toggle Like on a Post

```dart
final response = await ApiClient().authenticatedPost(
  '/posts/$postId/reactions',
  body: {'type': 'like'},
);
// response['data']['user_reaction'] == 'like' or null
// response['data']['likes_count'] == 12
```

### Load Comments for an Event

```dart
final response = await ApiClient().authenticatedGet(
  '/events/$eventId/comments?per_page=20',
);
final comments = response['data']['data'] as List;
for (final comment in comments) {
  print(comment['body']);
  print('Likes: ${comment['likes_count']}');
  final replies = comment['replies'] as List;
  for (final reply in replies) {
    print('  Reply: ${reply['body']}');
  }
}
```

### Post a Comment

```dart
final response = await ApiClient().authenticatedPost(
  '/bon-plans/$bonPlanId/comments',
  body: {'body': 'Super bon plan !'},
);
```

### Reply to a Comment

```dart
final response = await ApiClient().authenticatedPost(
  '/trainings/$trainingId/comments/$commentId/reply',
  body: {'body': 'Merci pour l\'info !'},
);
```

### Like a Comment

```dart
final response = await ApiClient().authenticatedPost(
  '/comments/$commentId/reactions',
  body: {'type': 'like'},
);
```

---

**Last Updated:** March 10, 2026
**Version:** 1.0
**API Version:** v1
