# 🚨 Problème d'envoi d'emails - Configuration Backend

## Problème identifié

Le serveur backend retourne `emailSent: false` lors de l'inscription et de la réinitialisation de mot de passe, ce qui signifie que **les emails ne sont pas envoyés** même si le serveur répond `status: "success"`.

### Exemple de réponse serveur lors de l'inscription :
```json
{
  "status": "success",
  "emailSent": false,  // ❌ PROBLÈME ICI
  "id": "a50d017a-c1f2-4fba-af31-07b5738649ea",
  "email": "alt.c2-are58sfc@yopmail.com",
  "token": "f5d4fa63-c369-4c23-b5fc-09ced1147469-...",
  "message": "Utilisateur créé avec succès. Un email de vérification a été envoyé..."
}
```

## Configuration SMTP disponible

Les credentials SMTP sont définis dans `.env` du frontend mais **ne sont PAS transmis au backend** :

```env
MRK_MAIL_AUTH_HOST="ssl0.ovh.net"
MRK_MAIL_AUTH_PORT=465
MRK_MAIL_AUTH_SECURE=true
MRK_MAIL_AUTH_USER="noreply@myreklam.fr"
MRK_MAIL_AUTH_PASS="noreply.mrk.2023"
```

## Solution requise côté backend

### 1. Vérifier la configuration SMTP sur le serveur PHP

Le fichier `LoginUser.php` sur `https://test.myreklam.fr` doit avoir accès aux credentials SMTP.

**Créer un fichier `.env` sur le serveur PHP** avec :
```env
SMTP_HOST=ssl0.ovh.net
SMTP_PORT=465
SMTP_SECURE=true
SMTP_USER=noreply@myreklam.fr
SMTP_PASS=noreply.mrk.2023
SMTP_FROM_EMAIL=noreply@myreklam.fr
SMTP_FROM_NAME=MyReklam
```

### 2. Vérifier l'implémentation PHPMailer

Le code PHP doit utiliser PHPMailer (ou équivalent) correctement :

```php
<?php
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/autoload.php';

function sendVerificationEmail($email, $token, $link) {
    $mail = new PHPMailer(true);
    
    try {
        // Configuration SMTP
        $mail->isSMTP();
        $mail->Host       = getenv('SMTP_HOST') ?: 'ssl0.ovh.net';
        $mail->SMTPAuth   = true;
        $mail->Username   = getenv('SMTP_USER') ?: 'noreply@myreklam.fr';
        $mail->Password   = getenv('SMTP_PASS') ?: 'noreply.mrk.2023';
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
        $mail->Port       = getenv('SMTP_PORT') ?: 465;
        
        // Destinataire
        $mail->setFrom(getenv('SMTP_FROM_EMAIL') ?: 'noreply@myreklam.fr', 
                       getenv('SMTP_FROM_NAME') ?: 'MyReklam');
        $mail->addAddress($email);
        
        // Contenu
        $mail->isHTML(true);
        $mail->Subject = 'Vérification de votre compte MyReklam';
        $mail->Body    = "Cliquez sur ce lien pour vérifier votre compte: $link";
        
        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Email sending failed: {$mail->ErrorInfo}");
        return false;
    }
}
```

### 3. Vérifier les logs d'erreur PHP

Activer les logs d'erreur pour voir pourquoi l'envoi échoue :

```php
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/path/to/php-error.log');
```

### 4. Tester la connexion SMTP

Créer un script de test `test_smtp.php` :

```php
<?php
require 'vendor/autoload.php';
use PHPMailer\PHPMailer\PHPMailer;

$mail = new PHPMailer(true);
$mail->isSMTP();
$mail->Host = 'ssl0.ovh.net';
$mail->SMTPAuth = true;
$mail->Username = 'noreply@myreklam.fr';
$mail->Password = 'noreply.mrk.2023';
$mail->SMTPSecure = PHPMailer::ENCRYPTION_SMTPS;
$mail->Port = 465;
$mail->SMTPDebug = 2; // Active le debug

$mail->setFrom('noreply@myreklam.fr', 'MyReklam');
$mail->addAddress('test@example.com');
$mail->Subject = 'Test SMTP';
$mail->Body = 'Test email';

try {
    $mail->send();
    echo "Email envoyé avec succès!";
} catch (Exception $e) {
    echo "Erreur: {$mail->ErrorInfo}";
}
```

## Modifications frontend effectuées

Le frontend a été mis à jour pour vérifier le champ `emailSent` et informer l'utilisateur correctement :

### ✅ Fichiers modifiés :
1. **`components/auth/sign-up-modal.tsx`** - Vérifie `emailSent` lors de l'inscription
2. **`components/auth/forgot-password-modal.tsx`** - Vérifie `emailSent` lors de la réinitialisation

### Comportement actuel :
- Si `emailSent: true` → Message de succès normal
- Si `emailSent: false` → Avertissement clair à l'utilisateur avec instructions de contacter le support

## Actions à effectuer

### Priorité HAUTE 🔴
1. **Vérifier les logs PHP** sur `https://test.myreklam.fr`
2. **Configurer les variables d'environnement SMTP** sur le serveur
3. **Tester l'envoi d'email** avec le script de test
4. **Vérifier que PHPMailer est installé** (`composer require phpmailer/phpmailer`)

### Priorité MOYENNE 🟡
5. Vérifier que le serveur OVH autorise l'envoi d'emails sur le port 465
6. Vérifier que l'IP du serveur n'est pas blacklistée
7. Tester avec un autre port SMTP (587 avec STARTTLS)

### Priorité BASSE 🟢
8. Implémenter un système de retry pour l'envoi d'emails
9. Ajouter une file d'attente pour les emails
10. Mettre en place des notifications admin en cas d'échec d'envoi

## Vérification de la résolution

Une fois le problème résolu, vous devriez voir dans la réponse du serveur :
```json
{
  "status": "success",
  "emailSent": true,  // ✅ DOIT ÊTRE TRUE
  "message": "..."
}
```

## Contact

Si le problème persiste, vérifier :
- Les credentials SMTP sont corrects
- Le serveur OVH autorise l'envoi d'emails
- Le firewall n'est pas bloqué
- Les logs d'erreur PHP pour plus de détails
