"use client"

import { useEffect, useState, useRef } from "react"
import { useAuthStore } from "@/lib/auth-store"
import { Button } from "@/components/ui/button"
import { toast } from "sonner"
import axios from "axios"
import { config } from "@/lib/config"
import { Upload, X, Loader2 } from "lucide-react"
import Image from "next/image"

const API_URL = config.API_URL

const STEPS = [
  { 
    id: "welcome",
    title: "Bienvenue", 
    text: "Bienvenue sur MyReklam — découvrez rapidement les fonctionnalités principales." 
  },
  { 
    id: "photo",
    title: "Photo de profil", 
    text: "Ajoutez votre photo pour augmenter la confiance des visiteurs.",
    canSkip: true
  },
  { 
    id: "profile",
    title: "Compléter le profil", 
    text: "Complétez vos informations pour améliorer votre visibilité.", 
    action: { label: "Compléter mon profil", href: "/dashboard" } 
  },
  { 
    id: "announcement",
    title: "Créer une annonce", 
    text: "Publiez votre première annonce en quelques clics.", 
    action: { label: "Créer une annonce", href: "/announcements/create" } 
  },
  { 
    id: "done",
    title: "Terminé", 
    text: "Vous êtes prêt·e ! Explorez le site et revenez si besoin." 
  },
]

export default function ManualOnboarding() {
  const { isAuthenticated, userId, urlPhotoProfil, fetchUserInfo } = useAuthStore()
  const [open, setOpen] = useState(false)
  const [step, setStep] = useState(0)
  const [hasPhoto, setHasPhoto] = useState(false)
  const [loadingPhoto, setLoadingPhoto] = useState(false)
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [isUploading, setIsUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Check if user has photo
  useEffect(() => {
    const checkUserPhoto = async () => {
      if (!userId || !isAuthenticated) return
      
      // First check from auth store
      if (urlPhotoProfil) {
        setHasPhoto(true)
        return
      }

      // If not in auth store, fetch from API
      try {
        setLoadingPhoto(true)
        const response = await axios.post(
          `${API_URL}/UserInfo.php`,
          { userid: userId, Method: "readAdsByCriteria" },
          { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
        )

        if (response.data.status === "success" && response.data.userInfo?.[0]) {
          const userData = response.data.userInfo[0]
          const photoUrl = userData.photoprofilurl
          if (photoUrl && photoUrl.trim() !== "") {
            setHasPhoto(true)
          }
        }
      } catch (error) {
        console.error("Error checking user photo:", error)
      } finally {
        setLoadingPhoto(false)
      }
    }

    checkUserPhoto()
  }, [userId, isAuthenticated, urlPhotoProfil])

  // Auto-skip photo step if user already has a photo
  useEffect(() => {
    if (open && step === 1 && hasPhoto && !loadingPhoto) {
      // Skip photo step if user already has a photo
      setStep(2) // Go directly to profile step
    }
  }, [open, step, hasPhoto, loadingPhoto])

  // Read persisted flag per user and start onboarding
  useEffect(() => {
    if (typeof window === "undefined") return
    const key = userId ? `onboarding-${userId}` : "onboarding-guest"
    const done = localStorage.getItem(key) === "true"
    if (!done && isAuthenticated && userId && !loadingPhoto) {
      // Wait a bit to ensure everything is ready, then check photo status
      const checkAndOpen = async () => {
        // Small delay to ensure auth store is ready
        await new Promise(resolve => setTimeout(resolve, 600))
        
        // If user has photo, start from step 2 (skip photo step)
        if (hasPhoto) {
          setStep(2)
        } else {
          setStep(0)
        }
        
        setOpen(true)
      }
      checkAndOpen()
    }
  }, [isAuthenticated, userId, hasPhoto, loadingPhoto])

  // expose manual starter
  useEffect(() => {
    if (typeof window === "undefined") return
    // attach global function
    ;(window as any).startOnboarding = (force = false) => {
      try {
        const key = userId ? `onboarding-${userId}` : "onboarding-guest"
        if (force) localStorage.setItem(key, "false")
      } catch {}
      // Start at step 0 (welcome) or step 2 (profile) if user has photo
      setStep(hasPhoto ? 2 : 0)
      setOpen(true)
    }
    return () => {
      try {
        delete (window as any).startOnboarding
      } catch {}
    }
  }, [userId, hasPhoto])

  const close = (markDone = true) => {
    if (markDone) {
      try {
        const key = userId ? `onboarding-${userId}` : "onboarding-guest"
        localStorage.setItem(key, "true")
      } catch {}
    }
    setOpen(false)
    setPhotoFile(null)
    setPhotoPreview(null)
  }

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      // Validate file type
      if (!file.type.startsWith("image/")) {
        toast.error("Veuillez sélectionner une image")
        return
      }
      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        toast.error("L'image ne doit pas dépasser 5 MB")
        return
      }
      setPhotoFile(file)
      setPhotoPreview(URL.createObjectURL(file))
    }
  }

  const handleUploadPhoto = async () => {
    if (!photoFile || !userId) {
      toast.error("Veuillez sélectionner une photo")
      return
    }

    setIsUploading(true)

    try {
      const formData = new FormData()
      formData.append("Method", "UPDATE")
      formData.append("userId", userId)
      formData.append("photoProfil", photoFile)

      const response = await fetch(`${API_URL}/UserInfo.php`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      if (data.status === "success") {
        toast.success("Photo mise à jour avec succès")
        setHasPhoto(true)
        // Refresh user info in auth store
        await fetchUserInfo()
        // Reset photo state
        setPhotoFile(null)
        if (photoPreview) {
          URL.revokeObjectURL(photoPreview)
        }
        setPhotoPreview(null)
        // Move to next step
        setStep((prev) => Math.min(prev + 1, STEPS.length - 1))
      } else {
        toast.error(data.message || "Erreur lors de la mise à jour de la photo")
      }
    } catch (error) {
      console.error("Error uploading photo:", error)
      toast.error("Erreur lors de la mise à jour de la photo")
    } finally {
      setIsUploading(false)
    }
  }

  const handleSkipPhoto = () => {
    setStep((prev) => Math.min(prev + 1, STEPS.length - 1))
  }

  const handleLater = () => {
    // Close without marking as done, so it can be shown again later
    close(false)
  }

  const handleNext = () => {
    setStep((prev) => {
      const next = prev + 1
      // If next step is photo (step 1) and user has photo, skip to step 2
      if (next === 1 && hasPhoto) {
        return 2
      }
      return Math.min(next, STEPS.length - 1)
    })
  }

  const handlePrevious = () => {
    setStep((prev) => {
      const prevStep = prev - 1
      // If previous step is photo (step 1) and user has photo, skip to step 0
      if (prevStep === 1 && hasPhoto) {
        return 0
      }
      return Math.max(prevStep, 0)
    })
  }

  if (!open) return null

  const currentStep = STEPS[step]
  const isPhotoStep = currentStep.id === "photo"

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-lg bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 relative">
        <button
          onClick={() => close(true)}
          className="absolute top-3 right-3 text-sm text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          aria-label="Fermer"
        >
          <X className="w-5 h-5" />
        </button>

        <h3 className="text-xl font-semibold mb-2 dark:text-white">{currentStep.title}</h3>
        <p className="text-gray-700 dark:text-gray-300 mb-4">{currentStep.text}</p>

        {/* Photo upload section */}
        {isPhotoStep && !hasPhoto && (
          <div className="mb-6 space-y-4">
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handlePhotoChange}
              className="hidden"
            />

            {photoPreview ? (
              <div className="relative">
                <div className="relative w-32 h-32 mx-auto rounded-full overflow-hidden border-4 border-primary">
                  <Image
                    src={photoPreview}
                    alt="Preview"
                    fill
                    className="object-cover"
                  />
                </div>
                <button
                  onClick={() => {
                    setPhotoFile(null)
                    if (photoPreview) {
                      URL.revokeObjectURL(photoPreview)
                    }
                    setPhotoPreview(null)
                  }}
                  className="absolute top-0 right-1/2 translate-x-8 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => fileInputRef.current?.click()}
                className="w-full flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg hover:border-primary transition-colors"
              >
                <Upload className="w-5 h-5 text-gray-500" />
                <span className="text-sm text-gray-600 dark:text-gray-400">Cliquez pour sélectionner une photo</span>
              </button>
            )}

            {photoFile && (
              <div className="flex gap-2">
                <Button
                  onClick={handleUploadPhoto}
                  disabled={isUploading}
                  className="flex-1"
                >
                  {isUploading ? (
                    <>
                      <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                      Upload en cours...
                    </>
                  ) : (
                    "Ajouter la photo"
                  )}
                </Button>
                <Button
                  onClick={handleSkipPhoto}
                  variant="outline"
                  disabled={isUploading}
                >
                  Passer
                </Button>
              </div>
            )}
          </div>
        )}

        {/* Show message if user already has photo */}
        {isPhotoStep && hasPhoto && (
          <div className="mb-4 p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
            <p className="text-sm text-green-700 dark:text-green-400">
              ✓ Vous avez déjà une photo de profil !
            </p>
          </div>
        )}

        {currentStep.action && !isPhotoStep && (
          <a
            href={currentStep.action.href}
            className="inline-block mb-4 text-sm text-primary underline"
          >
            {currentStep.action.label}
          </a>
        )}

        <div className="flex items-center justify-between mt-6">
          <div className="text-sm text-gray-500 dark:text-gray-400">
            Étape {step + 1} / {STEPS.length}
          </div>

          <div className="flex gap-2">
            {/* "Faire plus tard" button - only show if not on first step */}
            {step > 0 && (
              <Button
                onClick={handleLater}
                variant="outline"
                className="px-3 py-2"
              >
                Faire plus tard
              </Button>
            )}

            <Button
              onClick={handlePrevious}
              variant="outline"
              disabled={step === 0 || (step === 2 && hasPhoto)}
              className="px-3 py-2"
            >
              Précédent
            </Button>

            {step < STEPS.length - 1 ? (
              <Button
                onClick={handleNext}
                disabled={isUploading || (isPhotoStep && !hasPhoto && !photoFile && loadingPhoto)}
                className="px-4 py-2"
              >
                Suivant
              </Button>
            ) : (
              <Button
                onClick={() => close(true)}
                className="px-4 py-2 bg-green-600 hover:bg-green-700"
              >
                Terminer
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
