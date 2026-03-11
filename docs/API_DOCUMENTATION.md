# Myreklam — API Documentation (Frontend Integration Guide)

> **Base URL**: `http://<server>:8000/api`
>
> **Content-Type**: `application/json`
>
> **Authentication**: Bearer Token (Sanctum) — include `Authorization: Bearer <token>` header on protected routes.
>
> **Last updated**: February 2026

---

## Table of Contents

1. [General Information](#1-general-information)
2. [Authentication](#2-authentication)
3. [OTP / Email Verification](#3-otp--email-verification)
4. [Password Reset](#4-password-reset)
5. [Social Authentication](#5-social-authentication)
6. [Account Type & Profile](#6-account-type--profile)
7. [Subscriptions](#7-subscriptions)
8. [Referral / Parrainage](#8-referral--parrainage)
9. [Navigation / Routing Logic](#9-navigation--routing-logic)
10. [Error Handling](#10-error-handling)
11. [Validation Rules Reference](#11-validation-rules-reference)

---

## 1. General Information

### Request Headers

| Header | Value | Required |
|--------|-------|----------|
| `Content-Type` | `application/json` | Always |
| `Accept` | `application/json` | Always |
| `Authorization` | `Bearer <token>` | Protected routes only (🔒) |

### Standard Response Format

All endpoints return JSON with a `success` boolean:

```json
{
  "success": true,
  "message": "...",
  ...
}
```

### Error Response Format

```json
{
  "success": false,
  "message": "Error description"
}
```

Validation errors (HTTP 422) return:

```json
{
  "message": "The email field is required.",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password field must be at least 6 characters."]
  }
}
```

---

## 2. Authentication

### 2.1 Register

Creates a new user account and sends an OTP to the provided email.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/register` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "referral_code": "MYREK-A1B2C3"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `email` | string | ✅ | Valid email, unique in system |
| `password` | string | ✅ | Min 6 characters |
| `referral_code` | string | ❌ | Optional. Must be a valid existing referral code if provided |

**Success Response** — `201 Created`:

```json
{
  "success": true,
  "message": "OTP sent to email",
  "user_id": "1"
}
```

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `422` | Validation failed (email taken, password too short, invalid referral code) |

---

### 2.2 Login

Authenticates a user and returns access + refresh tokens.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/login` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

| Field | Type | Required |
|-------|------|----------|
| `email` | string | ✅ |
| `password` | string | ✅ |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "token": "1|abc123...",
  "refresh_token": "2|def456...",
  "user": {
    "id": "1",
    "email": "user@example.com",
    "account_type": "particulier",
    "is_email_verified": true,
    "profile_completed": true,
    "subscription": {
      "plan": "free",
      "status": "active"
    }
  }
}
```

> **Note:** `account_type` can be `null`, `"particulier"`, or `"pro"`.
> `subscription` is `null` if the user has no active subscription.

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `401` | Invalid email or password |
| `403` | Account is deactivated |

---

### 2.3 Logout 🔒

Invalidates the current access token.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/logout` |
| **Auth** | ✅ Bearer Token |

**Request Body:** None

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Déconnexion réussie."
}
```

---

### 2.4 Refresh Token 🔒

Exchanges the current refresh token for a new access + refresh token pair.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/refresh-token` |
| **Auth** | ✅ Bearer Token (use the **refresh_token**) |

**Request Body:** None

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "token": "3|newAccessToken...",
  "refresh_token": "4|newRefreshToken..."
}
```

> **Important:** Store both the `token` (access, 30 min) and `refresh_token` (refresh, 30 days) separately. Use the `refresh_token` to call this endpoint when the access token expires.

---

## 3. OTP / Email Verification

### 3.1 Send OTP

Sends a 4-digit OTP code to the user's email.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/otp/send` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com",
  "purpose": "email_verification"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `email` | string | ✅ | Valid email of existing user |
| `purpose` | string | ✅ | `"email_verification"` or `"password_reset"` |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Code OTP envoyé."
}
```

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `404` | No user found with this email |

---

### 3.2 Verify OTP

Verifies the 4-digit OTP code. On success for `email_verification`, marks the user's email as verified and returns auth tokens.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/otp/verify` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com",
  "code": "1234",
  "purpose": "email_verification"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `email` | string | ✅ | Valid email |
| `code` | string | ✅ | Exactly 4 characters |
| `purpose` | string | ✅ | `"email_verification"` or `"password_reset"` |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Code OTP vérifié avec succès.",
  "token": "5|accessToken...",
  "refresh_token": "6|refreshToken...",
  "user": {
    "id": "1",
    "email": "user@example.com",
    "account_type": null,
    "is_email_verified": true,
    "profile_completed": false
  }
}
```

> **After successful email verification**, use the returned `token` for subsequent authenticated requests (set account type, complete profile, etc.).

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `404` | No user found / No OTP found |
| `422` | OTP expired or incorrect |

> **OTP expiry**: 4 minutes 12 seconds (252 seconds). Start a countdown timer on the frontend matching this.

---

### 3.3 Resend OTP

Invalidates any previous OTP and sends a new one.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/otp/resend` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com",
  "purpose": "email_verification"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `email` | string | ✅ | Valid email |
| `purpose` | string | ✅ | `"email_verification"` or `"password_reset"` |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Code OTP renvoyé."
}
```

---

## 4. Password Reset

### 4.1 Forgot Password

Sends a password reset OTP to the user's email. Always returns success to prevent email enumeration.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/forgot-password` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com"
}
```

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Si un compte existe avec cet email, un code OTP a été envoyé."
}
```

> **Frontend flow:** After calling this, navigate to the OTP screen with `purpose: "password_reset"`. Use `/api/auth/otp/verify` to verify the code. On success, navigate to the Reset Password screen.

---

### 4.2 Reset Password

Resets the user's password after OTP verification. Revokes all existing tokens.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/reset-password` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "email": "user@example.com",
  "otp_code": "1234",
  "new_password": "newSecurePassword123"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `email` | string | ✅ | Valid email |
| `otp_code` | string | ✅ | Exactly 4 characters |
| `new_password` | string | ✅ | Min 6 characters |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Mot de passe mis à jour avec succès."
}
```

> **After success:** Navigate to Login screen and display the success message.

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `404` | User not found |
| `422` | OTP invalid or expired |

---

## 5. Social Authentication

### 5.1 Social Login/Register

Authenticates a user via a social provider. Creates a new account if the user doesn't exist.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/auth/social/{provider}` |
| **Auth** | ❌ None |

**Path Parameters:**

| Param | Values |
|-------|--------|
| `provider` | `google`, `apple`, `facebook` |

**Request Body:**

```json
{
  "provider": "google",
  "token": "oauth_token_from_provider",
  "email": "user@gmail.com"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `provider` | string | ✅ | `"google"`, `"apple"`, `"facebook"` |
| `token` | string | ✅ | OAuth token obtained from the provider SDK |
| `email` | string | ❌ | Email from the provider (recommended) |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "is_new_user": true,
  "token": "7|accessToken...",
  "refresh_token": "8|refreshToken...",
  "user": {
    "id": "1",
    "email": "user@gmail.com",
    "account_type": null,
    "profile_completed": false
  }
}
```

> **Routing after social auth:**
> - If `is_new_user == true` → Navigate to **Account Type Selection** screen
> - If `is_new_user == false` and `account_type == null` → Navigate to **Account Type Selection**
> - If `profile_completed == false` → Navigate to **Profile Completion**
> - Otherwise → **Dashboard**

---

## 6. Account Type & Profile

### 6.1 Set Account Type 🔒

Sets the user's account type after email verification.

| | |
|---|---|
| **Method** | `PUT` |
| **URL** | `/api/auth/account-type` |
| **Auth** | ✅ Bearer Token |

**Request Body:**

```json
{
  "account_type": "particulier"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `account_type` | string | ✅ | `"particulier"` or `"pro"` |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Type de compte défini.",
  "account_type": "particulier"
}
```

> **After setting account type:**
> - `"particulier"` → Navigate to **Particulier Info Screen**
> - `"pro"` → Navigate to **Pro Info Step 1 Screen**

---

### 6.2 Complete Particulier Profile 🔒

| | |
|---|---|
| **Method** | `PUT` |
| **URL** | `/api/profile/particulier` |
| **Auth** | ✅ Bearer Token |

**Request Body:**

```json
{
  "pseudo": "MonPseudo",
  "phone": "+33612345678"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `pseudo` | string | ✅ | Max 255 chars |
| `phone` | string | ✅ | 9-12 digits, may start with `+` (regex: `^\+?\d{9,12}$`) |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Profil particulier mis à jour.",
  "profile": {
    "id": "uuid",
    "user_id": 1,
    "pseudo": "MonPseudo",
    "phone": "+33612345678",
    "avatar_url": null,
    "created_at": "2026-02-24T14:00:00.000000Z",
    "updated_at": "2026-02-24T14:00:00.000000Z"
  }
}
```

> **After success:** Navigate directly to **Dashboard**.

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `403` | User account type is not `particulier` |

---

### 6.3 Complete Pro Profile — Step 1 (Company Info) 🔒

| | |
|---|---|
| **Method** | `PUT` |
| **URL** | `/api/profile/pro/step1` |
| **Auth** | ✅ Bearer Token |

**Request Body:**

```json
{
  "company_name": "My Company SAS",
  "siret": "12345678901234",
  "address": "123 Rue de Paris, 75001 Paris"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `company_name` | string | ✅ | Max 255 chars |
| `siret` | string | ✅ | Exactly 14 digits (regex: `^\d{14}$`) |
| `address` | string | ✅ | Max 500 chars |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Informations entreprise enregistrées.",
  "profile": {
    "id": "uuid",
    "user_id": 1,
    "company_name": "My Company SAS",
    "siret": "12345678901234",
    "address": "123 Rue de Paris, 75001 Paris",
    "first_name": null,
    "last_name": null,
    "contact_email": null,
    "phone": null,
    "avatar_url": null,
    "is_verified": false,
    "created_at": "2026-02-24T14:00:00.000000Z",
    "updated_at": "2026-02-24T14:00:00.000000Z"
  }
}
```

> **After success:** Navigate to **Pro Info Step 2 Screen**. Progress bar: 50%.

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `403` | User account type is not `pro` |

---

### 6.4 Complete Pro Profile — Step 2 (Personal Info) 🔒

| | |
|---|---|
| **Method** | `PUT` |
| **URL** | `/api/profile/pro/step2` |
| **Auth** | ✅ Bearer Token |

**Request Body:**

```json
{
  "first_name": "Jean",
  "last_name": "Dupont",
  "contact_email": "jean@company.com",
  "phone": "+33612345678"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `first_name` | string | ✅ | Max 255 chars |
| `last_name` | string | ✅ | Max 255 chars |
| `contact_email` | string | ✅ | Valid email, max 255 chars |
| `phone` | string | ❌ | 9-12 digits, may start with `+` |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Profil professionnel complété.",
  "profile": {
    "id": "uuid",
    "user_id": 1,
    "company_name": "My Company SAS",
    "siret": "12345678901234",
    "address": "123 Rue de Paris, 75001 Paris",
    "first_name": "Jean",
    "last_name": "Dupont",
    "contact_email": "jean@company.com",
    "phone": "+33612345678",
    "avatar_url": null,
    "is_verified": false,
    "created_at": "2026-02-24T14:00:00.000000Z",
    "updated_at": "2026-02-24T14:05:00.000000Z"
  }
}
```

> **After success:** Navigate to **Subscription Screen**. Progress bar: 100%.

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `403` | User account type is not `pro` |
| `422` | Step 1 must be completed first |

---

### 6.5 Get Current Profile 🔒

Returns the full user profile with subscription info.

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `/api/profile/me` |
| **Auth** | ✅ Bearer Token |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "user": {
    "id": "1",
    "email": "user@example.com",
    "account_type": "particulier",
    "is_email_verified": true,
    "profile_completed": true,
    "referral_code": "MYREK-A1B2C3",
    "created_at": "2026-02-24T14:00:00.000000Z"
  },
  "profile": {
    "id": "uuid",
    "user_id": 1,
    "pseudo": "MonPseudo",
    "phone": "+33612345678",
    "avatar_url": null,
    "created_at": "2026-02-24T14:00:00.000000Z",
    "updated_at": "2026-02-24T14:00:00.000000Z"
  },
  "subscription": {
    "id": "uuid",
    "user_id": 1,
    "plan": "free",
    "billing_cycle": null,
    "status": "active",
    "trial_end_date": null,
    "start_date": "2026-02-24T14:00:00.000000Z",
    "end_date": null,
    "price": "0.00",
    "created_at": "2026-02-24T14:00:00.000000Z",
    "updated_at": "2026-02-24T14:00:00.000000Z"
  }
}
```

> **Note:** `profile` content varies based on `account_type`:
> - `"particulier"` → returns `pseudo`, `phone`, `avatar_url`
> - `"pro"` → returns `company_name`, `siret`, `address`, `first_name`, `last_name`, `contact_email`, `phone`, `avatar_url`, `is_verified`
> - `null` → `profile` is `null`
>
> `subscription` is `null` if no active subscription exists.

---

### 6.6 Update Profile 🔒

Updates the current user's profile fields. Only send fields you want to update.

| | |
|---|---|
| **Method** | `PUT` |
| **URL** | `/api/profile/me` |
| **Auth** | ✅ Bearer Token |

**Request Body (Particulier):**

```json
{
  "pseudo": "NewPseudo",
  "phone": "+33698765432"
}
```

**Request Body (Pro):**

```json
{
  "company_name": "New Company Name",
  "first_name": "Pierre",
  "phone": "+33698765432"
}
```

> All fields are optional — only send the ones you want to update.

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Profil mis à jour."
}
```

---

## 7. Subscriptions

### 7.1 Get Available Plans

Returns all available subscription plans with features. **No auth required.**

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `/api/subscriptions/plans` |
| **Auth** | ❌ None |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "plans": [
    {
      "id": "free",
      "name": "Version GRATUITE",
      "price_monthly": 0,
      "price_annual": 0,
      "label": "Gratuit à vie · sans engagement",
      "description": "Découvrez la plateforme avec des fonctionnalités de base.",
      "features": [
        {
          "category": "TROUVER",
          "name": "Consulter les annonces",
          "status": "limited",
          "detail": "illimité"
        },
        {
          "category": "TROUVER",
          "name": "Obtenir un numéro ou email de contact",
          "status": "unavailable"
        }
      ]
    },
    {
      "id": "premium",
      "name": "Version PREMIUM",
      "price_monthly": 6.99,
      "price_annual": 59.90,
      "price_annual_per_month": 4.99,
      "savings_annual": 22.90,
      "trial_days": 30,
      "label": "1 mois d'essai gratuit",
      "description": "Maximisez votre visibilité et développez votre activité sans limites.",
      "highlights": [
        "Visibilité maximale",
        "Croissance accélérée",
        "Support dédié",
        "Profil vérifié"
      ],
      "features": [
        {
          "category": "TROUVER",
          "name": "Consulter les annonces",
          "status": "included",
          "detail": "illimité"
        }
      ]
    }
  ]
}
```

**Feature status values:**

| Status | Meaning | Display |
|--------|---------|---------|
| `"included"` | Fully available | ✅ |
| `"limited"` | Available with restrictions (see `detail`) | ⚠️ |
| `"unavailable"` | Not available in this plan | ❌ |

---

### 7.2 Subscribe to a Plan 🔒

Creates a subscription for the authenticated user. Cancels any existing active subscription.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/subscriptions/subscribe` |
| **Auth** | ✅ Bearer Token |

**Request Body:**

```json
{
  "plan": "premium",
  "billing_cycle": "annual"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `plan` | string | ✅ | `"free"` or `"premium"` |
| `billing_cycle` | string | Required if `plan` is `"premium"` | `"monthly"` or `"annual"` |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "subscription": {
    "id": "uuid",
    "plan": "premium",
    "billing_cycle": "annual",
    "status": "trial",
    "trial_end_date": "2026-03-24T14:00:00+00:00",
    "price": "59.90",
    "start_date": "2026-02-24T14:00:00+00:00"
  }
}
```

**Pricing:**

| Plan | Billing | Price | Trial |
|------|---------|-------|-------|
| Free | — | 0€ | — |
| Premium | Monthly | 6,99€/mois | 1 month free |
| Premium | Annual | 59,90€/an (4,99€/mois) | 1 month free |

> **After subscribing:** Navigate to **Dashboard**.

---

### 7.3 Get Current Subscription 🔒

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `/api/subscriptions/current` |
| **Auth** | ✅ Bearer Token |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "subscription": {
    "id": "uuid",
    "plan": "premium",
    "billing_cycle": "annual",
    "status": "trial",
    "trial_end_date": "2026-03-24T14:00:00+00:00",
    "start_date": "2026-02-24T14:00:00+00:00",
    "end_date": "2027-02-24T14:00:00+00:00",
    "price": "59.90"
  }
}
```

> Returns `"subscription": null` if no active subscription.

**Subscription status values:**

| Status | Meaning |
|--------|---------|
| `"active"` | Paid and active |
| `"trial"` | In free trial period |
| `"cancelled"` | Cancelled by user |
| `"expired"` | Past end date |

---

### 7.4 Cancel Subscription 🔒

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/subscriptions/cancel` |
| **Auth** | ✅ Bearer Token |

**Request Body:** None

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Abonnement annulé avec succès."
}
```

**Error Responses:**

| Status | Condition |
|--------|-----------|
| `404` | No active subscription found |

---

## 8. Referral / Parrainage

### 8.1 Validate Referral Code

Checks if a referral code is valid. **No auth required** — used during registration.

| | |
|---|---|
| **Method** | `POST` |
| **URL** | `/api/referral/validate` |
| **Auth** | ❌ None |

**Request Body:**

```json
{
  "referral_code": "MYREK-A1B2C3"
}
```

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "message": "Code de parrainage valide."
}
```

**Error Response** — `422`:

```json
{
  "success": false,
  "message": "Code de parrainage invalide."
}
```

---

### 8.2 Get My Referral Code 🔒

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `/api/referral/my-code` |
| **Auth** | ✅ Bearer Token |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "referral_code": "MYREK-A1B2C3"
}
```

> Referral code format: `MYREK-XXXXXX` (6 random alphanumeric characters). Auto-generated at registration.

---

### 8.3 Get Referral Stats 🔒

| | |
|---|---|
| **Method** | `GET` |
| **URL** | `/api/referral/stats` |
| **Auth** | ✅ Bearer Token |

**Success Response** — `200 OK`:

```json
{
  "success": true,
  "stats": {
    "total_referred": 5,
    "completed": 3,
    "pending": 2,
    "rewards_points": 30
  }
}
```

> `rewards_points` = 10 My's per completed referral.

---

## 9. Navigation / Routing Logic

Use the data returned from **Login**, **OTP Verify**, and **Social Auth** to determine where to navigate:

```
┌─────────────────────────────────────────────────┐
│                  POST-AUTH CHECK                  │
├─────────────────────────────────────────────────┤
│                                                   │
│  if (is_email_verified == false)                  │
│     → OTP Verification Screen                     │
│       (purpose: "email_verification")             │
│                                                   │
│  else if (account_type == null)                   │
│     → Account Type Selection Screen               │
│                                                   │
│  else if (profile_completed == false)             │
│     → if (account_type == "particulier")          │
│         → Particulier Info Screen                 │
│       else                                        │
│         → Pro Info Step 1 Screen                  │
│                                                   │
│  else if (account_type == "pro"                   │
│           && subscription == null)                │
│     → Subscription Screen                         │
│                                                   │
│  else                                             │
│     → Dashboard                                   │
│                                                   │
└─────────────────────────────────────────────────┘
```

---

## 10. Error Handling

### HTTP Status Codes Used

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Created (registration) |
| `401` | Unauthorized (bad credentials or expired token) |
| `403` | Forbidden (account deactivated, wrong account type) |
| `404` | Not found |
| `422` | Validation error / Business logic error |
| `500` | Server error |

### Token Expiration

- **Access token**: 30 minutes
- **Refresh token**: 30 days
- When you receive a `401` response, try refreshing the token using `/api/auth/refresh-token` with the stored refresh token
- If the refresh also fails with `401`, redirect the user to the Login screen

---

## 11. Validation Rules Reference

| Field | Rule |
|-------|------|
| **Email** | Valid email format, unique in system |
| **Password** | Min 6 characters |
| **Phone** | 9-12 digits, optional `+` prefix (regex: `^\+?\d{9,12}$`) |
| **SIRET** | Exactly 14 digits (regex: `^\d{14}$`) |
| **OTP Code** | Exactly 4 digits |
| **Account Type** | `"particulier"` or `"pro"` |
| **Plan** | `"free"` or `"premium"` |
| **Billing Cycle** | `"monthly"` or `"annual"` (required for premium) |
| **Referral Code** | Optional, format `MYREK-XXXXXX` |

---

## Quick Reference — All Endpoints

### Public (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Register new user |
| `POST` | `/api/auth/login` | Login |
| `POST` | `/api/auth/otp/send` | Send OTP |
| `POST` | `/api/auth/otp/verify` | Verify OTP |
| `POST` | `/api/auth/otp/resend` | Resend OTP |
| `POST` | `/api/auth/forgot-password` | Forgot password |
| `POST` | `/api/auth/reset-password` | Reset password |
| `POST` | `/api/auth/social/{provider}` | Social login (google/apple/facebook) |
| `POST` | `/api/referral/validate` | Validate referral code |
| `GET`  | `/api/subscriptions/plans` | Get subscription plans |

### Protected (Bearer Token Required) 🔒

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/logout` | Logout |
| `POST` | `/api/auth/refresh-token` | Refresh tokens |
| `PUT`  | `/api/auth/account-type` | Set account type |
| `GET`  | `/api/profile/me` | Get my profile |
| `PUT`  | `/api/profile/me` | Update my profile |
| `PUT`  | `/api/profile/particulier` | Complete particulier profile |
| `PUT`  | `/api/profile/pro/step1` | Pro profile step 1 |
| `PUT`  | `/api/profile/pro/step2` | Pro profile step 2 |
| `POST` | `/api/subscriptions/subscribe` | Subscribe to plan |
| `GET`  | `/api/subscriptions/current` | Get current subscription |
| `POST` | `/api/subscriptions/cancel` | Cancel subscription |
| `GET`  | `/api/referral/my-code` | Get my referral code |
| `GET`  | `/api/referral/stats` | Get referral stats |
