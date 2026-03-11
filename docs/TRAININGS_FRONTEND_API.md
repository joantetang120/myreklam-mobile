# Trainings API - Frontend Documentation

> **Complete API reference for implementing the trainings (formations) feature in your mobile app**

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [Data Models](#data-models)
5. [Request/Response Examples](#requestresponse-examples)
6. [Error Handling](#error-handling)
7. [File Uploads](#file-uploads)

---

## Overview

**Base URL:** `http://192.168.10.169:8000/api`

All endpoints require authentication via Bearer token (Sanctum).

**Category:** Trainings (Formations)

---

## Authentication

All requests must include the authentication token in the header:

```http
Authorization: Bearer {your_token_here}
```

---

## API Endpoints

### 1. Get Training Metadata

Get all constants and options for training forms.

**Endpoint:** `GET /trainings/meta`

**Headers:**
```http
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "training_types": {
      "InitialTraining": "Formation initiale",
      "ContinuingEducation": "Formation continue",
      "ApprenticeshipTraining": "Formation en alternance",
      "CertificationProgram": "Programme de certification",
      "DegreeProgram": "Programme diplômant",
      "QualificationProgram": "Programme qualifiant",
      "ProfessionalTraining": "Formation professionnelle",
      "BlendedLearning": "Formation mixte (présentiel + distanciel)",
      "Elearning": "E-learning",
      "IntensiveBootcamp": "Bootcamp intensif",
      "SkillsValidation": "Validation des acquis de l'expérience (VAE)",
      "InternshipProfessionalImmersion": "Stage / Immersion professionnelle"
    },
    "teaching_types": {
      "Indifferent": "Indifférent",
      "OnSite": "En présentiel",
      "InCompany": "En entreprise",
      "Remote": "À distance",
      "InApprenticeship": "En alternance"
    },
    "target_publics": {
      "AllPublic": "Tout public",
      "Employed": "Salariés",
      "JobSeeker": "Demandeurs d'emploi",
      "Company": "Entreprises",
      "Student": "Étudiants"
    },
    "funding_options": {
      "Indifferent": "Indifférent",
      "SelfFunding": "Autofinancement",
      "RegionalCouncilLocalAuthorities": "Conseil régional / Collectivités locales",
      "Agefiph": "Agefiph",
      "CompetenceOperatorOPCO": "Opérateur de compétences (OPCO)",
      "PoleEmploi": "Pôle Emploi",
      "LocalMission": "Mission locale",
      "CPF": "CPF (Compte Personnel de Formation)"
    },
    "required_levels": [
      "Aucun prérequis",
      "CAP/BEP",
      "Bac",
      "Bac+2",
      "Bac+3",
      "Bac+5 et plus"
    ],
    "certifications": [
      "Qualiopi",
      "Datadock"
    ],
    "price_types": {
      "1": "NET",
      "2": "HT",
      "3": "TTC",
      "4": "Gratuit",
      "5": "Sur devis"
    },
    "public_types": {
      "personne": "Par personne",
      "groupe": "Par groupe"
    },
    "tempo_types": {
      "heure": "Par heure",
      "jour": "Par jour",
      "semaine": "Par semaine",
      "mois": "Par mois",
      "an": "Par an",
      "all": "Pour toute la formation"
    },
    "duration_units": {
      "0": "Heures",
      "1": "Jours",
      "2": "Semaines",
      "3": "Mois",
      "4": "Années"
    },
    "statuses": [
      "draft",
      "pending_review",
      "published",
      "rejected"
    ]
  }
}
```

---

### 2. List User's Trainings

Get all trainings created by the authenticated user.

**Endpoint:** `GET /trainings`

**Query Parameters:**
- `status` (optional): Filter by status (`draft`, `pending_review`, `published`, `rejected`)
- `per_page` (optional): Items per page (1-50, default: 15)
- `page` (optional): Page number

**Example:**
```http
GET /trainings?status=published&per_page=20&page=1
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "Formation Développeur Web",
      "description": "<p>Description HTML...</p>",
      "training_type": "ProfessionalTraining",
      "training_category": "ITDigitalTelecom",
      "training_sub_category": "WebDevelopment",
      "price": "2500.00",
      "price_type": "3",
      "status": "published",
      "created_at": "2026-03-05T12:00:00.000000Z",
      "media_files": [
        {
          "id": "uuid",
          "url": "http://192.168.10.169:8000/storage/trainings/...",
          "type": "image",
          "size": 159149
        }
      ],
      "document_files": [
        {
          "id": "uuid",
          "url": "http://192.168.10.169:8000/storage/trainings/.../documents/...",
          "file_name": "programme.pdf",
          "file_type": "application/pdf",
          "size": 245678
        }
      ]
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 15,
    "total": 42
  }
}
```

---

### 3. Create Training

Create a new training announcement.

**Endpoint:** `POST /trainings`

**Request Body:**
```json
{
  "title": "Formation Développeur Web Full Stack",
  "description": "<p>Formation complète pour devenir développeur web...</p>",
  "description_delta": {
    "ops": [
      {"insert": "Formation complète pour devenir développeur web...\n"}
    ]
  },
  "website": "https://example.com",
  "training_type": "ProfessionalTraining",
  "training_category": "ITDigitalTelecom",
  "training_sub_category": "WebDevelopment",
  "training_style": ["OnSite", "Remote"],
  "training_public": ["AllPublic", "Employed"],
  "required_levels": ["Bac+2", "Bac+3"],
  "price": 2500.00,
  "price_type": "3",
  "public_type": "personne",
  "tempo": "all",
  "training_funding": ["CPF", "PoleEmploi"],
  "duration_in_h": 350,
  "duration_unit": "0",
  "start_date": "2026-06-01",
  "end_date": "2026-12-15",
  "date_to_define": false,
  "address_line1": "123 Rue de Paris",
  "address_line2": "Bâtiment A",
  "address_line3": null,
  "address_city": "Lyon",
  "address_zipcode": "69001",
  "address_country": "FR",
  "show_location": true,
  "certification": ["Qualiopi"],
  "accept_messages": true,
  "status": "draft"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Formation créée avec succès",
  "data": {
    "id": "uuid",
    "status": "draft",
    "created_at": "2026-03-05T12:00:00.000000Z"
  }
}
```

---

### 4. Get Single Training

Get details of a specific training.

**Endpoint:** `GET /trainings/{id}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "user_id": 123,
    "title": "Formation Développeur Web",
    "description": "<p>Description...</p>",
    "description_delta": {...},
    "website": "https://example.com",
    "training_type": "ProfessionalTraining",
    "training_category": "ITDigitalTelecom",
    "training_sub_category": "WebDevelopment",
    "training_style": ["OnSite", "Remote"],
    "training_public": ["AllPublic"],
    "required_levels": ["Bac+2"],
    "price": "2500.00",
    "price_type": "3",
    "public_type": "personne",
    "tempo": "all",
    "training_funding": ["CPF"],
    "duration_in_h": 350,
    "duration_unit": "0",
    "start_date": "2026-06-01",
    "end_date": "2026-12-15",
    "date_to_define": false,
    "address_line1": "123 Rue de Paris",
    "address_city": "Lyon",
    "address_zipcode": "69001",
    "address_country": "FR",
    "show_location": true,
    "certification": ["Qualiopi"],
    "accept_messages": true,
    "status": "draft",
    "created_at": "2026-03-05T12:00:00.000000Z",
    "updated_at": "2026-03-05T12:00:00.000000Z",
    "media_files": [...],
    "document_files": [...]
  }
}
```

---

### 5. Update Training

Update an existing training.

**Endpoint:** `PUT /trainings/{id}`

**Request Body:** Same as create, all fields optional

**Response:**
```json
{
  "success": true,
  "message": "Formation mise à jour avec succès",
  "data": {
    "id": "uuid",
    "status": "draft"
  }
}
```

---

### 6. Delete Training

Delete a training (soft delete).

**Endpoint:** `DELETE /trainings/{id}`

**Response:**
```json
{
  "success": true,
  "message": "Formation supprimée avec succès"
}
```

---

### 7. Upload Media

Upload images or videos for a training.

**Endpoint:** `POST /trainings/{id}/media`

**Content-Type:** `multipart/form-data`

**Request:**
```
media[]: File (image or video)
media[]: File
```

**Accepted Types:**
- Images: `.jpg`, `.jpeg`, `.png`, `.gif`
- Videos: `.mp4`, `.mov`, `.avi`

**Max Size:** 50MB per file

**Response:**
```json
{
  "success": true,
  "message": "Médias uploadés avec succès",
  "data": {
    "media": [
      {
        "id": "uuid",
        "url": "http://192.168.10.169:8000/storage/trainings/.../image.jpg",
        "type": "image",
        "size": 159149
      }
    ]
  }
}
```

---

### 8. Delete Media

Delete a specific media file.

**Endpoint:** `DELETE /trainings/{training_id}/media/{media_id}`

**Response:**
```json
{
  "success": true,
  "message": "Média supprimé avec succès"
}
```

---

### 9. Upload Documents

Upload documents (PDFs, Office files, etc.) for a training.

**Endpoint:** `POST /trainings/{id}/documents`

**Content-Type:** `multipart/form-data`

**Request:**
```
documents[]: File
documents[]: File
```

**Accepted Types:**
- Documents: `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`
- Images: `.jpg`, `.jpeg`, `.png`

**Max Size:** 50MB per file

**Response:**
```json
{
  "success": true,
  "message": "Documents uploadés avec succès",
  "data": {
    "documents": [
      {
        "id": "uuid",
        "url": "http://192.168.10.169:8000/storage/trainings/.../documents/programme.pdf",
        "file_name": "programme.pdf",
        "file_type": "application/pdf",
        "size": 245678
      }
    ]
  }
}
```

---

### 10. Delete Document

Delete a specific document.

**Endpoint:** `DELETE /trainings/{training_id}/documents/{document_id}`

**Response:**
```json
{
  "success": true,
  "message": "Document supprimé avec succès"
}
```

---

## Data Models

### Training Object

```typescript
interface Training {
  id: string;
  user_id: number;
  
  // Basic Info
  title: string;
  description: string;
  description_delta?: object;
  website?: string;
  
  // Type & Category
  training_type: string;
  training_category: string;
  training_sub_category: string;
  
  // Teaching & Public
  training_style: string[];
  training_public: string[];
  required_levels: string[];
  
  // Pricing
  price?: number;
  price_type: string;
  public_type?: string;
  tempo?: string;
  
  // Funding & Duration
  training_funding: string[];
  duration_in_h?: number;
  duration_unit?: string;
  
  // Dates
  start_date?: string;
  end_date?: string;
  date_to_define: boolean;
  
  // Location
  address_line1?: string;
  address_line2?: string;
  address_line3?: string;
  address_city?: string;
  address_zipcode?: string;
  address_country?: string;
  show_location: boolean;
  
  // Certifications
  certification?: string[];
  
  // Settings
  accept_messages: boolean;
  status: string;
  
  // Timestamps
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}
```

### Media Object

```typescript
interface TrainingMedia {
  id: string;
  training_id: string;
  path: string;
  type: 'image' | 'video';
  size: number;
  display_order: number;
  url: string; // Generated URL
  created_at: string;
  updated_at: string;
}
```

### Document Object

```typescript
interface TrainingDocument {
  id: string;
  training_id: string;
  user_id: number;
  file_name: string;
  path: string;
  file_type: string;
  size: number;
  url: string; // Generated URL
  created_at: string;
  updated_at: string;
}
```

---

## Request/Response Examples

### Complete Create Workflow

```javascript
// Step 1: Get metadata
const metaResponse = await fetch('/api/trainings/meta', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
const meta = await metaResponse.json();

// Step 2: Create training
const trainingData = {
  title: "Formation Développeur Web",
  description: "<p>Description complète...</p>",
  training_type: "ProfessionalTraining",
  training_category: "ITDigitalTelecom",
  training_sub_category: "WebDevelopment",
  training_style: ["OnSite", "Remote"],
  training_public: ["AllPublic"],
  required_levels: ["Bac+2"],
  price: 2500,
  price_type: "3",
  training_funding: ["CPF"],
  accept_messages: true
};

const createResponse = await fetch('/api/trainings', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(trainingData)
});
const training = await createResponse.json();

// Step 3: Upload media
const formData = new FormData();
formData.append('media[]', imageFile1);
formData.append('media[]', imageFile2);

const mediaResponse = await fetch(`/api/trainings/${training.data.id}/media`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
});

// Step 4: Upload documents
const docFormData = new FormData();
docFormData.append('documents[]', pdfFile);

const docResponse = await fetch(`/api/trainings/${training.data.id}/documents`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: docFormData
});
```

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "message": "Error message here",
  "errors": {
    "field_name": [
      "Validation error message"
    ]
  }
}
```

### Common Error Codes

| Status Code | Meaning |
|-------------|---------|
| 400 | Bad Request - Invalid data |
| 401 | Unauthorized - Missing or invalid token |
| 403 | Forbidden - Not authorized to access this resource |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable Entity - Validation errors |
| 500 | Internal Server Error |

### Validation Errors Example

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "title": [
      "Le champ title est obligatoire."
    ],
    "price": [
      "Le prix est requis pour ce type de tarification."
    ],
    "training_style": [
      "Le champ training style doit contenir au moins 1 éléments."
    ]
  }
}
```

---

## File Uploads

### Upload Guidelines

1. **Media Files:**
   - Max size: 50MB per file
   - Accepted: Images (jpg, png, gif), Videos (mp4, mov, avi)
   - Field name: `media[]`

2. **Document Files:**
   - Max size: 50MB per file
   - Accepted: PDF, Office files, Images
   - Field name: `documents[]`

3. **Upload Process:**
   - Create training first
   - Use training ID to upload files
   - Upload in batches if many files
   - Files are stored in `storage/trainings/{training_id}/`

### Example Upload Code

```javascript
// Upload multiple media files
const uploadMedia = async (trainingId, files) => {
  const formData = new FormData();
  
  files.forEach(file => {
    formData.append('media[]', file);
  });
  
  const response = await fetch(`/api/trainings/${trainingId}/media`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });
  
  return response.json();
};
```

---

## Field Requirements

### Required Fields

- `title` ✅
- `description` ✅
- `training_type` ✅
- `training_category` ✅
- `training_sub_category` ✅
- `training_style` (at least 1) ✅
- `training_public` (at least 1) ✅
- `required_levels` (at least 1) ✅
- `price_type` ✅
- `training_funding` (at least 1) ✅

### Conditional Requirements

- `price`: Required if `price_type` is not "4" (Free) or "5" (Quote)
- `start_date` or `end_date`: Required if `date_to_define` is false
- `address_*`: Recommended if `training_type` is not "Elearning"

---

## Notes for Mobile Development

1. **Categories:** Fetch from external API (not included in this backend)
2. **Rich Text:** Use `description_delta` for Quill Delta format
3. **Arrays:** All array fields must be sent as JSON arrays
4. **Dates:** Use `YYYY-MM-DD` format
5. **Booleans:** Send as `true`/`false`, not strings
6. **File Uploads:** Use `multipart/form-data`, upload after creating training
7. **Pagination:** Use `page` and `per_page` query parameters

---

## Summary

**Total Endpoints:** 10  
**Authentication:** Required (Bearer token)  
**Base URL:** `http://192.168.10.169:8000/api`  
**File Upload:** Supported (media + documents)  
**Pagination:** Supported  
**Soft Delete:** Yes

This API provides complete CRUD operations for training announcements with support for media and document uploads.
