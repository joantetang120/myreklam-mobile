# Myreklam — Backend Authentication & User Management Requirements

> **Document Purpose**: This document describes all authentication flows, user types, subscription plans, and data models required by the backend to fully support the Myreklam mobile application.
> 
> **Generated from**: Frontend codebase analysis (Flutter)
> **Date**: February 2026

---

## Table of Contents

1. [Authentication Flows Overview](#1-authentication-flows-overview)
2. [API Endpoints Required](#2-api-endpoints-required)
3. [Data Models / Database Schema](#3-data-models--database-schema)
4. [Account Types](#4-account-types)
5. [Registration Flow (Detailed)](#5-registration-flow-detailed)
6. [Login Flow (Detailed)](#6-login-flow-detailed)
7. [Password Reset Flow (Detailed)](#7-password-reset-flow-detailed)
8. [OTP / Email Verification](#8-otp--email-verification)
9. [Profile Completion Flow](#9-profile-completion-flow)
10. [Subscription Plans (Pro)](#10-subscription-plans-pro)
11. [Social Authentication](#11-social-authentication)
12. [Session & Token Management](#12-session--token-management)
13. [Validation Rules](#13-validation-rules)
14. [Referral / Parrainage System](#14-referral--parrainage-system)

---

## 1. Authentication Flows Overview

The app has the following auth-related screens and navigation flow:

```
Splash Screen
  └── Onboarding (4 pages)
        └── Login Screen
              ├── Register Screen
              │     └── OTP Verification Screen
              │           └── Account Type Selection Screen
              │                 ├── [Particulier] → Particulier Info Screen → Dashboard
              │                 └── [Professionnel] → Pro Info Step 1 → Pro Info Step 2 → Subscription Screen → Dashboard
              ├── Forgot Password Screen
              │     └── OTP Verification Screen
              │           └── Reset Password Screen → Login Screen
              └── [Login Success] → Dashboard (ParticulierMainScreen)
```

### Social Login (Login screen only)
- Google
- Apple
- Facebook

---

## 2. API Endpoints Required

### 2.1 Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Register a new user (email + password + optional referral code) |
| `POST` | `/api/auth/login` | Login with email + password |
| `POST` | `/api/auth/logout` | Logout / invalidate token |
| `POST` | `/api/auth/refresh-token` | Refresh JWT/access token |
| `POST` | `/api/auth/social/google` | Google OAuth login/register |
| `POST` | `/api/auth/social/apple` | Apple Sign-In login/register |
| `POST` | `/api/auth/social/facebook` | Facebook OAuth login/register |

### 2.2 OTP / Email Verification

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/otp/send` | Send OTP code to user email |
| `POST` | `/api/auth/otp/verify` | Verify the 4-digit OTP code |
| `POST` | `/api/auth/otp/resend` | Resend OTP code |

### 2.3 Password Reset

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/forgot-password` | Send password reset OTP to email |
| `POST` | `/api/auth/reset-password` | Reset password with new password (after OTP verification) |

### 2.4 Account Type & Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `PUT` | `/api/auth/account-type` | Set account type (`particulier` or `pro`) |
| `PUT` | `/api/profile/particulier` | Complete particulier profile (pseudo, phone) |
| `PUT` | `/api/profile/pro/step1` | Complete pro company info (company name, SIRET, address) |
| `PUT` | `/api/profile/pro/step2` | Complete pro personal info (first name, last name, email, phone) |
| `GET` | `/api/profile/me` | Get current user profile |
| `PUT` | `/api/profile/me` | Update profile |

### 2.5 Subscription

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/subscriptions/plans` | Get available subscription plans |
| `POST` | `/api/subscriptions/subscribe` | Subscribe to a plan |
| `GET` | `/api/subscriptions/current` | Get current subscription status |
| `POST` | `/api/subscriptions/cancel` | Cancel subscription |

### 2.6 Referral / Parrainage

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/referral/validate` | Validate a referral code during registration |
| `GET` | `/api/referral/my-code` | Get the user's own referral code |
| `GET` | `/api/referral/stats` | Get referral statistics (how many referred, rewards) |

---

## 3. Data Models / Database Schema

### 3.1 User

```
User {
  id                  : UUID (primary key)
  email               : String (unique, required)
  password_hash       : String (required, min 6 chars raw)
  account_type        : Enum ['particulier', 'pro'] (required, set after OTP)
  is_email_verified   : Boolean (default: false)
  referral_code       : String (unique, auto-generated)
  referred_by         : String (nullable, referral code used at registration)
  created_at          : DateTime
  updated_at          : DateTime
  last_login_at       : DateTime
  is_active           : Boolean (default: true)
  
  // Social auth fields
  google_id           : String (nullable)
  apple_id            : String (nullable)
  facebook_id         : String (nullable)
  
  // Profile completion status
  profile_completed   : Boolean (default: false)
}
```

### 3.2 Particulier Profile

```
ParticulierProfile {
  id                  : UUID (primary key)
  user_id             : UUID (foreign key → User.id, unique)
  pseudo              : String (required)
  phone               : String (format: +33 XXXXXXXXX, 9-10 digits)
  avatar_url          : String (nullable)
  created_at          : DateTime
  updated_at          : DateTime
}
```

### 3.3 Pro Profile

```
ProProfile {
  id                  : UUID (primary key)
  user_id             : UUID (foreign key → User.id, unique)
  
  // Step 1 - Company Info
  company_name        : String (required)
  siret               : String (required, exactly 14 digits)
  address             : String (required)
  
  // Step 2 - Personal Info
  first_name          : String (required)
  last_name           : String (required)
  contact_email       : String (required, valid email)
  phone               : String (optional, 9-10 digits)
  
  avatar_url          : String (nullable)
  is_verified         : Boolean (default: false) // "Badge Profil vérifié"
  created_at          : DateTime
  updated_at          : DateTime
}
```

### 3.4 OTP Code

```
OtpCode {
  id                  : UUID (primary key)
  user_id             : UUID (foreign key → User.id)
  code                : String (4 digits)
  purpose             : Enum ['email_verification', 'password_reset']
  expires_at          : DateTime (suggested: current time + 4 min 12 sec based on UI timer)
  is_used             : Boolean (default: false)
  created_at          : DateTime
}
```

### 3.5 Subscription

```
Subscription {
  id                  : UUID (primary key)
  user_id             : UUID (foreign key → User.id)
  plan                : Enum ['free', 'premium']
  billing_cycle       : Enum ['monthly', 'annual'] (nullable for free)
  status              : Enum ['active', 'cancelled', 'expired', 'trial']
  trial_end_date      : DateTime (nullable, 1 month free trial for premium)
  start_date          : DateTime
  end_date            : DateTime (nullable)
  price               : Decimal
  created_at          : DateTime
  updated_at          : DateTime
}
```

### 3.6 Referral

```
Referral {
  id                  : UUID (primary key)
  referrer_user_id    : UUID (foreign key → User.id, the one who shared the code)
  referred_user_id    : UUID (foreign key → User.id, the one who used the code)
  referral_code       : String
  status              : Enum ['pending', 'completed']
  created_at          : DateTime
}
```

---

## 4. Account Types

The app supports **two account types**, chosen after email verification:

### 4.1 Particulier (Individual)
- **Color theme**: Orange (`#FF9800`)
- **Description**: "Je souhaite découvrir et partager des bons plans, évènement et opportunités"
- **Profile fields**: Pseudo (required), Phone (required)
- **Subscription**: Not applicable (no subscription screen shown for particulier)
- **After profile completion**: Goes directly to Dashboard

### 4.2 Professionnel (Business)
- **Color theme**: Green (`#1B8D4B`)
- **Description**: "Je représente une entreprise et souhaite promouvoir mes services et offres"
- **Profile fields**: Company Name, SIRET (14 digits), Address, First Name, Last Name, Email, Phone
- **Subscription**: Must choose between Free and Premium plans
- **After profile completion**: Goes to Subscription Screen, then Dashboard

---

## 5. Registration Flow (Detailed)

### Step 1: Registration Form
**Screen**: `register_screen.dart`

**Input Fields**:

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Email | email | Yes | Valid email format (`^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`) |
| Password | password | Yes | Min 6 characters |
| Confirm Password | password | Yes | Must match password |
| Referral Code (Parrainage) | text | No | Optional, label: "Entrer le Code de parrainage (Facultatif)" |

**Request body** (`POST /api/auth/register`):
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "referral_code": "ABC123"  // optional
}
```

**Expected Response**:
```json
{
  "success": true,
  "message": "OTP sent to email",
  "user_id": "uuid"
}
```

### Step 2: OTP Verification
→ See [Section 8](#8-otp--email-verification)

### Step 3: Account Type Selection
→ See [Section 4](#4-account-types)

### Step 4: Profile Completion
→ See [Section 9](#9-profile-completion-flow)

### Step 5: Subscription Selection (Pro only)
→ See [Section 10](#10-subscription-plans-pro)

---

## 6. Login Flow (Detailed)

**Screen**: `login_screen.dart`

**Input Fields**:

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Email | email | Yes | Valid email format |
| Password | password | Yes | Not empty |

**Request body** (`POST /api/auth/login`):
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Expected Response**:
```json
{
  "success": true,
  "token": "jwt_token_here",
  "refresh_token": "refresh_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "account_type": "particulier" | "pro",
    "profile_completed": true,
    "subscription": {
      "plan": "free" | "premium",
      "status": "active" | "trial"
    }
  }
}
```

**Current frontend behavior**: Account type is determined by email (`pro@test.com` → pro, anything else → particulier). This needs to be replaced by the backend returning the actual `account_type` from the user record.

**Post-login routing logic the backend should support**:
- If `is_email_verified == false` → redirect to OTP screen
- If `account_type == null` → redirect to Account Type Selection
- If `profile_completed == false` → redirect to profile completion screen
- If `account_type == 'pro'` and no subscription → redirect to Subscription screen
- Otherwise → Dashboard

---

## 7. Password Reset Flow (Detailed)

### Step 1: Forgot Password
**Screen**: `forgot_password_screen.dart`

**Input**: Email address (validated)

**Request** (`POST /api/auth/forgot-password`):
```json
{
  "email": "user@example.com"
}
```

### Step 2: OTP Verification
Same OTP screen as registration, but with `purpose: 'password_reset'`.

### Step 3: Reset Password
**Screen**: `reset_password_screen.dart`

**Input Fields**:

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| New Password | password | Yes | Min 6 characters |
| Confirm Password | password | Yes | Must match new password |

**Request** (`POST /api/auth/reset-password`):
```json
{
  "email": "user@example.com",
  "otp_code": "1234",
  "new_password": "newSecurePassword123"
}
```

**After success**: User is redirected to Login screen with success message "Mot de passe mis à jour avec succès".

---

## 8. OTP / Email Verification

**Screen**: `otp_screen.dart`

### Behavior
- **4-digit code** input (4 separate text fields)
- **Countdown timer**: Starts at **4 minutes 12 seconds** (252 seconds)
- **Resend functionality**: Available after timer expires
- **OTP is used for two purposes**:
  1. Email verification after registration → navigates to `AccountTypeScreen`
  2. Password reset → navigates to `ResetPasswordScreen`

### OTP Send Request (`POST /api/auth/otp/send`):
```json
{
  "email": "user@example.com",
  "purpose": "email_verification" | "password_reset"
}
```

### OTP Verify Request (`POST /api/auth/otp/verify`):
```json
{
  "email": "user@example.com",
  "code": "1234",
  "purpose": "email_verification" | "password_reset"
}
```

### OTP Resend Request (`POST /api/auth/otp/resend`):
```json
{
  "email": "user@example.com",
  "purpose": "email_verification" | "password_reset"
}
```

---

## 9. Profile Completion Flow

### 9.1 Particulier Profile
**Screen**: `particulier_info_screen.dart` (1 step)

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Pseudo | text | Yes | Not empty |
| Phone | phone | Yes | 9-10 digits, prefixed with +33 (France) |

**Request** (`PUT /api/profile/particulier`):
```json
{
  "pseudo": "MonPseudo",
  "phone": "+33612345678"
}
```

**After completion**: Navigates directly to Dashboard.

---

### 9.2 Pro Profile — Step 1 (Company Info)
**Screen**: `pro_info_screen.dart` (progress bar: 50%)

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Company Name | text | Yes | Not empty |
| SIRET | number | Yes | Exactly 14 digits (`^\d{14}$`) |
| Address | text | Yes | Not empty |

**Request** (`PUT /api/profile/pro/step1`):
```json
{
  "company_name": "My Company SAS",
  "siret": "12345678901234",
  "address": "123 Rue de Paris, 75001 Paris"
}
```

---

### 9.3 Pro Profile — Step 2 (Personal Info)
**Screen**: `pro_info_step2_screen.dart` (progress bar: 100%)

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| First Name (Prénom) | text | Yes | Not empty |
| Last Name (Nom) | text | Yes | Not empty |
| Email | email | Yes | Valid email |
| Phone | phone | No | 9-10 digits if provided, prefixed with +33 |

**Request** (`PUT /api/profile/pro/step2`):
```json
{
  "first_name": "Jean",
  "last_name": "Dupont",
  "contact_email": "jean@company.com",
  "phone": "+33612345678"
}
```

**After completion**: Navigates to Subscription Screen.

---

## 10. Subscription Plans (Pro)

**Screen**: `pro_subscription_screen.dart`

The subscription screen is shown **only for Pro accounts** after profile completion.

### 10.1 Free Plan (Version GRATUITE)

| Property | Value |
|----------|-------|
| **Price** | 0€/mois |
| **Label** | "Gratuit à vie · sans engagement" |
| **Description** | "Découvrez la plateforme avec des fonctionnalités de base." |

**Features (with limitations)**:

| Category | Feature | Status |
|----------|---------|--------|
| **TROUVER** | Consulter les annonces (illimité) | ⚠️ Limited |
| | Commenter et réagir aux annonces (1 mois) | ⚠️ Limited |
| | Obtenir un numéro ou email de contact | ❌ Unavailable |
| | Voir les documents partagés | ❌ Unavailable |
| | Télécharger les programmes de formations | ❌ Unavailable |
| **PROMOUVOIR** | Poster une annonce (1 mois) | ⚠️ Limited |
| | Partager mes coordonnées sur mes annonces | ❌ Unavailable |
| **COMMUNIQUER** | Accès à la messagerie | ❌ Unavailable |
| | Convertir mes My's en récompense | ❌ Unavailable |
| **DIFFUSER** | Profil (Basique) | ⚠️ Limited |
| | Répondre aux avis | ❌ Unavailable |

---

### 10.2 Premium Plan (Version PREMIUM)

| Property | Value |
|----------|-------|
| **Monthly Price** | 6,99€/mois (billed monthly) |
| **Annual Price** | 4,99€/mois (billed 59,90€/year) |
| **Savings (Annual)** | 22,90€ |
| **Trial** | 1 month free |
| **Description** | "Maximisez votre visibilité et développez votre activité sans limites." |

**All features included (unlimited)**:

| Category | Feature |
|----------|---------|
| **TROUVER** | Consulter les annonces (illimité) |
| | Commenter et réagir aux annonces (illimité) |
| | Obtenir un numéro ou email de contact |
| | Voir les documents partagés |
| | Télécharger les programmes de formations |
| **PROMOUVOIR** | Poster une annonce (illimité) |
| | Partager mes coordonnées sur mes annonces |
| **COMMUNIQUER** | Accès à la messagerie |
| | Convertir mes My's en récompense |
| **DIFFUSER** | Profil (Premium) |
| | Badge "Profil vérifié" |
| | Répondre aux avis |

**Premium Highlights**:
- Visibilité maximale
- Croissance accélérée
- Support dédié
- Profil vérifié

### Subscribe Request (`POST /api/subscriptions/subscribe`):
```json
{
  "plan": "free" | "premium",
  "billing_cycle": "monthly" | "annual"  // only for premium
}
```

### Subscribe Response:
```json
{
  "success": true,
  "subscription": {
    "id": "uuid",
    "plan": "premium",
    "billing_cycle": "annual",
    "status": "trial",
    "trial_end_date": "2026-03-24T00:00:00Z",
    "price": 59.90,
    "start_date": "2026-02-24T00:00:00Z"
  }
}
```

---

## 11. Social Authentication

The **Login screen** supports 1 social login providers:

1. **Google** (OAuth 2.0)

> **Note**: The Registration screen does NOT have social login buttons (they were removed). Only the Login screen has them.

### Social Auth Flow:
1. User taps social button on Login screen
2. Frontend obtains OAuth token from provider
3. Frontend sends token to backend
4. Backend validates token with provider
5. Backend creates or finds user account
6. Backend returns JWT + user data

### Social Auth Request (`POST /api/auth/social/{provider}`):
```json
{
  "provider": "google" ,
  "token": "oauth_token_from_provider",
  "email": "user@example.com"  // from provider
}
```

### Social Auth Response:
```json
{
  "success": true,
  "is_new_user": true | false,
  "token": "jwt_token",
  "refresh_token": "refresh_token",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "account_type": null | "particulier" | "pro",
    "profile_completed": false | true
  }
}
```

If `is_new_user == true`, the frontend will navigate to Account Type Selection.

---

## 12. Session & Token Management

### Current State (Frontend)
The app currently uses a **singleton** `UserSession` class that stores user type in memory only:
```dart
class UserSession {
  String _userType = 'particulier'; // 'particulier' or 'pro'
  bool get isParticulier => _userType == 'particulier';
  bool get isPro => _userType == 'pro';
}
```

### Backend Requirements
The backend needs to provide:

1. **JWT Access Token** — Short-lived (e.g., 15-30 min)
2. **Refresh Token** — Long-lived (e.g., 7-30 days)
3. **Token payload** should include:
   - `user_id`
   - `email`
   - `account_type`
   - `subscription_plan`
   - `is_email_verified`
   - `profile_completed`

### Session Endpoints:
- `POST /api/auth/refresh-token` — Get new access token using refresh token
- `POST /api/auth/logout` — Invalidate refresh token

---

## 13. Validation Rules

### Email
- Format: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`
- Must be unique in the system

### Password
- Minimum 6 characters
- Confirm password must match

### Phone Number
- 9-10 digits (French format)
- Prefixed with `+33` on display
- Regex: `^\d{9,10}$`

### SIRET (Pro only)
- Exactly 14 digits
- Regex: `^\d{14}$`

### OTP Code
- Exactly 4 digits

### Referral Code
- Optional at registration
- Must be validated against existing user codes

---

## 14. Referral / Parrainage System

### Overview
- Every registered user gets a unique referral code auto-generated
- New users can enter a referral code during registration (optional)
- The referral code field label: "Entrer le Code de parrainage (Facultatif)"

### Backend Needs
1. **Auto-generate** a unique referral code for each new user upon registration
2. **Validate** referral codes when submitted during registration
3. **Track** referral relationships (who referred whom)
4. **Reward system** — The app mentions "My's" as a reward currency that can be converted to rewards (premium feature). The backend should support a points/rewards system tied to referrals.

### Referral Data Flow:
1. User A registers and gets auto-generated code `MYREK-A1B2C3`
2. User A shares code with User B
3. User B enters `MYREK-A1B2C3` during registration
4. Backend validates code, creates referral record
5. Upon User B completing registration, User A receives reward (My's points)

---

## Summary Checklist for Backend Team

- [ ] User registration with email + password + optional referral code
- [ ] Email OTP verification (4-digit, 4min12s expiry)
- [ ] Login with email/password returning JWT
- [ ] Social auth (Google, Apple, Facebook)
- [ ] Password reset flow (forgot → OTP → new password)
- [ ] Account type selection (particulier / pro)
- [ ] Particulier profile completion (pseudo, phone)
- [ ] Pro profile completion — Step 1 (company name, SIRET, address)
- [ ] Pro profile completion — Step 2 (first name, last name, email, phone)
- [ ] Subscription management (Free / Premium plans)
- [ ] Premium billing: monthly (6.99€) or annual (59.90€/year = 4.99€/month)
- [ ] 1-month free trial for Premium
- [ ] Feature access control based on subscription plan
- [ ] Referral code generation and validation
- [ ] My's reward points system
- [ ] Token refresh mechanism
- [ ] User session management
