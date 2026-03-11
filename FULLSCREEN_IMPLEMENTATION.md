# Implémentation Fullscreen pour Events

## État actuel
✅ **Deals page** - Fullscreen fonctionnel
❌ **Events page** - À implémenter

## Code à copier depuis deals (lignes 179-353)

### 1. Ajouter l'état isFullscreen (ligne 181)
```typescript
const [isFullscreen, setIsFullscreen] = useState(false)
```

### 2. Ajouter la fonction toggleFullscreen (lignes 202-204)
```typescript
const toggleFullscreen = () => {
  setIsFullscreen(!isFullscreen)
}
```

### 3. Wrapper le return dans un fragment (ligne 229)
```typescript
return (
  <>
    <div className="relative...">
```

### 4. Ajouter le bouton fullscreen (lignes 243-251)
```typescript
{/* Fullscreen Button */}
<button
  onClick={toggleFullscreen}
  className="absolute top-6 left-6 bg-black/70 hover:bg-black/90 text-white p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all shadow-lg z-10"
  aria-label="Plein écran"
>
  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
  </svg>
</button>
```

### 5. Ajouter la modal fullscreen (lignes 288-350)
```typescript
{/* Fullscreen Modal */}
{isFullscreen && (
  <div className="fixed inset-0 z-50 bg-black flex items-center justify-center">
    {/* Close Button */}
    <button
      onClick={toggleFullscreen}
      className="absolute top-6 right-6 bg-white/10 hover:bg-white/20 text-white p-3 rounded-full transition-all shadow-lg z-20"
      aria-label="Fermer"
    >
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
      </svg>
    </button>

    {/* Image */}
    <div className="relative w-full h-full flex items-center justify-center p-4">
      <img
        src={getImageUrl(images[currentIndex])}
        alt="Event image fullscreen"
        className="max-w-full max-h-full object-contain"
      />
    </div>

    {/* Navigation */}
    {images.length > 1 && (
      <>
        <button
          onClick={prevImage}
          className="absolute left-6 top-1/2 -translate-y-1/2 bg-white/10 hover:bg-white/20 text-white p-4 rounded-full transition-all shadow-lg"
          aria-label="Image précédente"
        >
          <ChevronLeft className="w-8 h-8" />
        </button>
        <button
          onClick={nextImage}
          className="absolute right-6 top-1/2 -translate-y-1/2 bg-white/10 hover:bg-white/20 text-white p-4 rounded-full transition-all shadow-lg"
          aria-label="Image suivante"
        >
          <ChevronRight className="w-8 h-8" />
        </button>
        
        {/* Counter */}
        <div className="absolute bottom-6 left-1/2 -translate-x-1/2 bg-black/70 text-white px-4 py-2 rounded-full text-lg font-medium">
          {currentIndex + 1} / {images.length}
        </div>

        {/* Thumbnails */}
        <div className="absolute bottom-20 left-1/2 -translate-x-1/2 flex gap-2 bg-black/50 px-4 py-2 rounded-full max-w-md overflow-x-auto">
          {images.map((_, idx) => (
            <button
              key={idx}
              onClick={() => setCurrentIndex(idx)}
              className={`w-3 h-3 rounded-full transition-all flex-shrink-0 ${
                idx === currentIndex ? "bg-white w-10" : "bg-white/50 hover:bg-white/75"
              }`}
              aria-label={`Aller à l'image ${idx + 1}`}
            />
          ))}
        </div>
      </>
    )}
  </div>
)}
```

### 6. Fermer le fragment (lignes 351-352)
```typescript
    </>
  )
}
```

## Fichier à modifier
`g:\ProjetWeb\MyReklam-Web\app\announcements\events\[announcementId]\page.tsx`

## Fonction ImageCarousel
Lignes 525-610

**IMPORTANT**: Ne pas casser la syntaxe JSX. Vérifier que tous les tags sont correctement fermés.
