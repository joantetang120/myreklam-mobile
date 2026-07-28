# Permission Declaration for Google Play Console

## Permissions Required

### 1. READ_MEDIA_IMAGES
**Description for Google Play Console:**
```
MyReklam allows users to upload photos to create posts, stories, job offers, events, and deals. The READ_MEDIA_IMAGES permission is required to access the user's photo library so they can select and upload images to share content on the platform. This is a core feature of the app as it is a social networking and classifieds platform where visual content is essential.
```

**French version:**
```
MyReklam permet aux utilisateurs de télécharger des photos pour créer des publications, stories, offres d'emploi, événements et bons plans. L'autorisation READ_MEDIA_IMAGES est nécessaire pour accéder à la bibliothèque photo de l'utilisateur afin qu'il puisse sélectionner et télécharger des images pour partager du contenu sur la plateforme. C'est une fonctionnalité essentielle de l'application car il s'agit d'une plateforme de réseautage social et de petites annonces où le contenu visuel est primordial.
```

### 2. READ_MEDIA_VIDEO
**Description for Google Play Console:**
```
MyReklam enables users to upload videos to create stories and posts. The READ_MEDIA_VIDEO permission is required to access the user's video library, allowing them to select and share video content with their network. Video content is a key feature for user engagement on our social platform.
```

**French version:**
```
MyReklam permet aux utilisateurs de télécharger des vidéos pour créer des stories et des publications. L'autorisation READ_MEDIA_VIDEO est nécessaire pour accéder à la bibliothèque vidéo de l'utilisateur, lui permettant de sélectionner et de partager du contenu vidéo avec son réseau. Le contenu vidéo est une fonctionnalité clé pour l'engagement des utilisateurs sur notre plateforme sociale.
```

## How to submit in Google Play Console:

1. Go to Google Play Console → Your App → Policy center → App permissions
2. Click "Add declaration" for each permission
3. Copy-paste the descriptions above
4. Select "This is the only way to implement this feature"
5. Click "Save"

## Alternative: Video demonstration

You may also need to provide a video demonstrating the feature. The video should show:
- User opening the app
- User navigating to create a post/story
- User selecting an image/video from their gallery
- The uploaded content being displayed in the app

## Note:
- These permissions are used by the photo_manager and image_picker Flutter plugins
- The app does not access media files in the background
- Users explicitly select which photos/videos to upload
- No data is collected or shared with third parties
