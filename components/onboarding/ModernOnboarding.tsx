"use client"

import { useEffect, useState } from "react"
import { useAuthStore } from "@/lib/auth-store"
import { Button } from "@/components/ui/button"
import { toast } from "sonner"
import axios from "axios"
import { config } from "@/lib/config"
import { 
  Upload, 
  X, 
  Loader2, 
  CheckCircle2, 
  Sparkles,
  User,
  FileText,
  Megaphone,
  ArrowRight,
  Camera
} from "lucide-react"
import Image from "next/image"
import { motion, AnimatePresence } from "framer-motion"
import { useRouter } from "next/navigation"

const API_URL = config.API_URL

interface OnboardingStep {
  id: string
  title: string
  description: string
  icon: any
  component?: React.ReactNode
}

export default function ModernOnboarding() {
  const router = useRouter()
  const { isAuthenticated, userId, urlPhotoProfil, fetchUserInfo } = useAuthStore()
  const [open, setOpen] = useState(false)
  // Initialiser l'état avec les valeurs sauvegardées
  const [currentStep, setCurrentStep] = useState(() => {
    if (typeof window === 'undefined' || !userId) return 0
    const savedStep = localStorage.getItem(`onboarding-step-${userId}`)
    return savedStep ? parseInt(savedStep, 10) : 0
  })
  
  const [completedSteps, setCompletedSteps] = useState<Set<string>>(() => {
    if (typeof window === 'undefined' || !userId) return new Set()
    const savedSteps = localStorage.getItem(`onboarding-completed-steps-${userId}`)
    return savedSteps ? new Set(JSON.parse(savedSteps)) : new Set()
  })

  // Fonction pour naviguer entre les étapes avec sauvegarde
  const goToStep = (step: number) => {
    setCurrentStep(step)
    if (userId) {
      localStorage.setItem(`onboarding-step-${userId}`, step.toString())
    }
  }

  const goToNextStep = () => {
    if (currentStep < steps.length - 1) {
      const nextStep = currentStep + 1
      goToStep(nextStep)
    } else {
      handleClose()
    }
  }
  const updateCompletedSteps = (updater: (prev: Set<string>) => Set<string>) => {
    setCompletedSteps(prev => {
      const newSteps = updater(prev)
      if (userId) {
        localStorage.setItem(
          `onboarding-completed-steps-${userId}`, 
          JSON.stringify(Array.from(newSteps))
        )
      }
      return newSteps
    })
  }
  const [userData, setUserData] = useState<any>(null)
  const [announcementsCount, setAnnouncementsCount] = useState(0)
  const [loading, setLoading] = useState(true)
  
  // Photo upload state
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [isUploading, setIsUploading] = useState(false)

  // Check user progress
  useEffect(() => {
    const checkUserProgress = async () => {
      if (!userId || !isAuthenticated) {
        setLoading(false)
        return
      }

      try {
        const response = await axios.post(
          `${API_URL}/UserInfo.php`,
          { userid: userId, Method: "readAdsByCriteria" },
          { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
        )

        if (response.data.status === "success" && response.data.userInfo?.[0]) {
          const user = response.data.userInfo[0]
          setUserData(user)
          
          const completed = new Set<string>()
          
          // Check photo
          if (user.photoprofilurl && user.photoprofilurl.trim() !== "") {
            completed.add("photo")
          }
          
          // Check profile info
          if ((user.pseudo && user.pseudo.trim() !== "") || 
              (user.nomsociete && user.nomsociete.trim() !== "") ||
              (user.telephone && user.telephone.trim() !== "")) {
            completed.add("profile")
          }
          
          updateCompletedSteps(prev => new Set([...prev, ...completed]))
        }

        // Check announcements
        try {
          const annoncesResponse = await axios.post(
            `${API_URL}/Annonces.php`,
            { userid: userId, Method: "readAllByUserId" },
            { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
          )
          if (annoncesResponse.data.status === "success" && Array.isArray(annoncesResponse.data.annonces)) {
            const count = annoncesResponse.data.annonces.length
            setAnnouncementsCount(count)
            if (count > 0) {
              updateCompletedSteps(prev => new Set([...prev, "announcement"]))
            }
          }
        } catch (err) {
          console.error("Error fetching announcements:", err)
        }
      } catch (error) {
        console.error("Error checking user progress:", error)
      } finally {
        setLoading(false)
      }
    }

    checkUserProgress()
  }, [userId, isAuthenticated])

  // Auto-start onboarding for first-time users ONLY after subscription is completed
  useEffect(() => {
    if (typeof window === "undefined" || !isAuthenticated || !userId || loading) return

    const key = `modern-onboarding-${userId}`
    const hasSeenOnboarding = localStorage.getItem(key) === "true"
    const subscriptionCompleted = localStorage.getItem(`subscription-completed-${userId}`) === "true"
    
    // Only show onboarding if user has completed subscription and hasn't seen onboarding yet
    if (!hasSeenOnboarding && subscriptionCompleted) {
      const timer = setTimeout(() => {
        setOpen(true)
      }, 800)
      return () => clearTimeout(timer)
    }
  }, [userId, isAuthenticated, loading])

  // Restaurer l'état de l'onboarding quand userId est disponible
  useEffect(() => {
    if (userId) {
      // Restaurer l'étape actuelle
      const savedStep = localStorage.getItem(`onboarding-step-${userId}`)
      if (savedStep) {
        const step = parseInt(savedStep, 10)
        // Vérifier que l'étape est valide
        if (!isNaN(step) && step >= 0 && step < steps.length) {
          setCurrentStep(step)
        }
      }

      // Restaurer les étapes complétées
      const savedCompletedSteps = localStorage.getItem(`onboarding-completed-steps-${userId}`)
      if (savedCompletedSteps) {
        try {
          const steps = JSON.parse(savedCompletedSteps)
          if (Array.isArray(steps)) {
            setCompletedSteps(new Set(steps))
          }
        } catch (e) {
          console.error("Erreur lors de la restauration des étapes complétées:", e)
        }
      }
    }
  }, [userId])

  // Global trigger
  useEffect(() => {
    if (typeof window === "undefined") return
    
    const handleStart = (e: Event) => {
      const detail = (e as CustomEvent)?.detail || {}
      if (detail.force) {
        const key = `modern-onboarding-${userId}`
        localStorage.setItem(key, "false")
      }
      setCurrentStep(0)
      setOpen(true)
    }

    window.addEventListener("startModernOnboarding", handleStart as EventListener)
    return () => window.removeEventListener("startModernOnboarding", handleStart as EventListener)
  }, [userId])

  const handleClose = (markComplete = true) => {
    if (markComplete && userId) {
      const key = `modern-onboarding-${userId}`
      localStorage.setItem(key, "true")
    }
    setOpen(false)
    setPhotoFile(null)
    setPhotoPreview(null)
  }

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      if (!file.type.startsWith("image/")) {
        toast.error("Veuillez sélectionner une image")
        return
      }
      if (file.size > 5 * 1024 * 1024) {
        toast.error("L'image ne doit pas dépasser 5 MB")
        return
      }
      setPhotoFile(file)
      setPhotoPreview(URL.createObjectURL(file))
    }
  }

  const handleUploadPhoto = async () => {
    if (!photoFile) return

    setIsUploading(true)

    try {
      const formData = new FormData()
      formData.append("Method", "updateUserInfo")
      formData.append("id", userId || "")
      formData.append("photoprofilurl", photoFile)

      const response = await fetch(`${API_URL}/UserInfo.php`, {
        method: "POST",
        body: formData,
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      let data
      try {
        data = await response.json()
      } catch (jsonError) {
        console.error("Error parsing JSON response:", jsonError)
        throw new Error("Réponse invalide du serveur")
      }

      if (data.status === "success") {
        toast.success("Photo mise à jour avec succès !")
        updateCompletedSteps(prev => new Set([...prev, "photo"]))
        
        // Forcer le rafraîchissement des données utilisateur
        await fetchUserInfo()
        
        // Nettoyer les états
        setPhotoFile(null)
        if (photoPreview) URL.revokeObjectURL(photoPreview)
        setPhotoPreview(null)
        
        // Petit délai pour s'assurer que tout est bien mis à jour
        setTimeout(() => {
          goToNextStep()
        }, 300)
      } else {
        throw new Error(data.message || "Erreur lors de la mise à jour de la photo")
      }
    } catch (error) {
      console.error("Error uploading photo:", error)
      const errorMessage = error instanceof Error ? error.message : "Erreur lors de la mise à jour de la photo"
      toast.error(errorMessage)
    } finally {
      setIsUploading(false)
    }
  }

  const steps: OnboardingStep[] = [
    {
      id: "welcome",
      title: "Bienvenue sur MyReklam ! 🎉",
      description: "Découvrez comment tirer le meilleur parti de votre compte en quelques étapes simples.",
      icon: Sparkles,
    },
    {
      id: "photo",
      title: "Ajoutez votre photo",
      description: "Une photo de profil augmente la confiance et rend votre profil plus attractif.",
      icon: Camera,
      component: (
        <div className="space-y-4">
          {completedSteps.has("photo") ? (
            <motion.div
              initial={{ scale: 0.8, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              transition={{ type: "spring", damping: 15 }}
              className="flex items-center justify-center gap-4 p-8 bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-3xl border-2 border-green-200 dark:border-green-800 shadow-lg"
            >
              <motion.div
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ delay: 0.2, type: "spring", damping: 10 }}
              >
                <CheckCircle2 className="w-10 h-10 text-green-600 dark:text-green-400" />
              </motion.div>
              <p className="text-green-700 dark:text-green-300 font-semibold text-lg">
                Photo de profil ajoutée !
              </p>
            </motion.div>
          ) : (
            <>
              <input
                type="file"
                accept="image/*"
                onChange={handlePhotoChange}
                className="hidden"
                id="photo-upload"
              />
              
              {photoPreview ? (
                <motion.div
                  initial={{ scale: 0.8, opacity: 0, rotateY: -180 }}
                  animate={{ scale: 1, opacity: 1, rotateY: 0 }}
                  transition={{ type: "spring", damping: 20, stiffness: 200 }}
                  className="relative"
                >
                  <div className="relative w-48 h-48 mx-auto rounded-full overflow-hidden border-4 border-primary shadow-2xl ring-4 ring-primary/20">
                    <Image src={photoPreview} alt="Preview" fill className="object-cover" />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent" />
                  </div>
                  <motion.button
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.9 }}
                    onClick={() => {
                      setPhotoFile(null)
                      if (photoPreview) URL.revokeObjectURL(photoPreview)
                      setPhotoPreview(null)
                    }}
                    className="absolute top-2 right-1/2 translate-x-20 bg-red-500 text-white rounded-full p-2.5 hover:bg-red-600 shadow-xl transition-colors"
                  >
                    <X className="w-5 h-5" />
                  </motion.button>
                </motion.div>
              ) : (
                <label
                  htmlFor="photo-upload"
                  className="relative flex flex-col items-center justify-center gap-4 p-12 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-3xl hover:border-primary hover:bg-gradient-to-br hover:from-primary/5 hover:to-purple-500/5 transition-all cursor-pointer group overflow-hidden"
                >
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/0 to-purple-500/0 group-hover:from-primary/5 group-hover:to-purple-500/5 transition-all duration-500" />
                  <motion.div
                    whileHover={{ scale: 1.1, rotate: 5 }}
                    className="relative w-20 h-20 rounded-full bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center shadow-lg"
                  >
                    <Upload className="w-10 h-10 text-white" />
                  </motion.div>
                  <div className="text-center relative z-10">
                    <p className="font-semibold text-lg text-gray-700 dark:text-gray-300">Cliquez pour ajouter votre photo</p>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">JPG, PNG ou GIF (max 5 MB)</p>
                  </div>
                </label>
              )}

              {photoFile && (
                <motion.div
                  initial={{ y: 20, opacity: 0, scale: 0.9 }}
                  animate={{ y: 0, opacity: 1, scale: 1 }}
                  transition={{ type: "spring", damping: 20, stiffness: 300 }}
                  className="flex gap-3"
                >
                  <Button
                    onClick={handleUploadPhoto}
                    disabled={isUploading}
                    className="flex-1 h-14 text-lg font-semibold bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-600/90 shadow-lg hover:shadow-xl transition-all"
                  >
                    {isUploading ? (
                      <>
                        <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                        Envoi en cours...
                      </>
                    ) : (
                      <>
                        <CheckCircle2 className="w-5 h-5 mr-2" />
                        Valider ma photo
                      </>
                    )}
                  </Button>
                </motion.div>
              )}
            </>
          )}
        </div>
      ),
    },
    {
      id: "profile",
      title: "Complétez votre profil",
      description: "Plus votre profil est complet, plus vous êtes visible et crédible auprès des autres utilisateurs.",
      icon: User,
      component: (
        <div className="space-y-4">
          {completedSteps.has("profile") ? (
            <motion.div
              initial={{ scale: 0.8, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              transition={{ type: "spring", damping: 15 }}
              className="flex items-center justify-center gap-4 p-8 bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-3xl border-2 border-green-200 dark:border-green-800 shadow-lg"
            >
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: "spring", damping: 10 }}
              >
                <CheckCircle2 className="w-10 h-10 text-green-600 dark:text-green-400" />
              </motion.div>
              <p className="text-green-700 dark:text-green-300 font-semibold text-lg">
                Profil completé !
              </p>
            </motion.div>
          ) : (
            <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
              <Button
                onClick={() => {
                  handleClose(false)
                  router.push("/dashboard")
                }}
                className="w-full h-14 text-lg font-semibold bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-600/90 shadow-lg hover:shadow-xl transition-all"
                size="lg"
              >
                <FileText className="w-5 h-5 mr-2" />
                Compléter mon profil
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
            </motion.div>
          )}
        </div>
      ),
    },
    {
      id: "announcement",
      title: "Créez votre première annonce",
      description: "Partagez vos bons plans, événements, offres d'emploi ou formations avec la communauté.",
      icon: Megaphone,
      component: (
        <div className="space-y-4">
          {completedSteps.has("announcement") ? (
            <motion.div
              initial={{ scale: 0.8, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              transition={{ type: "spring", damping: 15 }}
              className="flex items-center justify-center gap-4 p-8 bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-3xl border-2 border-green-200 dark:border-green-800 shadow-lg"
            >
              <motion.div
                initial={{ scale: 0, rotate: -180 }}
                animate={{ scale: 1, rotate: 0 }}
                transition={{ delay: 0.2, type: "spring", damping: 10 }}
              >
                <CheckCircle2 className="w-10 h-10 text-green-600 dark:text-green-400" />
              </motion.div>
              <p className="text-green-700 dark:text-green-300 font-semibold text-lg">
                {announcementsCount} annonce{announcementsCount > 1 ? "s" : ""} publiée{announcementsCount > 1 ? "s" : ""} !
              </p>
            </motion.div>
          ) : (
            <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
              <Button
                onClick={() => {
                  handleClose(false)
                  router.push("/announcements/create")
                }}
                className="w-full h-14 text-lg font-semibold bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-600/90 shadow-lg hover:shadow-xl transition-all"
                size="lg"
              >
                <Megaphone className="w-5 h-5 mr-2" />
                Créer une annonce
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
            </motion.div>
          )}
        </div>
      ),
    },
  ]

  if (!open) return null

  const step = steps[currentStep]
  const Icon = step.icon
  const progress = ((currentStep + 1) / steps.length) * 100

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4"
          onClick={(e) => {
            if (e.target === e.currentTarget) handleClose(false)
          }}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.9, opacity: 0, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            className="w-full max-w-2xl bg-white dark:bg-gray-900 rounded-3xl shadow-2xl overflow-hidden"
          >
            {/* Progress bar */}
            <div className="h-2 bg-gray-100 dark:bg-gray-800">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${progress}%` }}
                transition={{ duration: 0.5, ease: "easeOut" }}
                className="h-full bg-gradient-to-r from-primary to-purple-600"
              />
            </div>

            <div className="p-8 md:p-12">
              {/* Close button */}
              <button
                onClick={() => handleClose(true)}
                className="absolute top-6 right-6 p-2 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                aria-label="Fermer"
              >
                <X className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              </button>

              {/* Icon */}
              <motion.div
                key={step.id}
                initial={{ scale: 0, rotate: -180, y: -20 }}
                animate={{ scale: 1, rotate: 0, y: 0 }}
                transition={{ type: "spring", damping: 15, stiffness: 200 }}
                className="relative w-24 h-24 mx-auto mb-8"
              >
                <div className="absolute inset-0 bg-gradient-to-br from-primary to-purple-600 rounded-3xl blur-xl opacity-50 animate-pulse" />
                <div className="relative w-full h-full rounded-3xl bg-gradient-to-br from-primary to-purple-600 flex items-center justify-center shadow-2xl">
                  <Icon className="w-12 h-12 text-white" />
                </div>
              </motion.div>

              {/* Content */}
              <AnimatePresence mode="wait">
                <motion.div
                  key={step.id}
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  transition={{ duration: 0.3 }}
                  className="text-center mb-8"
                >
                  <h2 className="text-4xl font-bold mb-4 bg-gradient-to-r from-gray-900 via-primary to-purple-600 dark:from-white dark:via-primary dark:to-purple-400 bg-clip-text text-transparent">
                    {step.title}
                  </h2>
                  <p className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto leading-relaxed">
                    {step.description}
                  </p>
                </motion.div>
              </AnimatePresence>

              {/* Step component */}
              <AnimatePresence mode="wait">
                <motion.div
                  key={step.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  transition={{ duration: 0.3, delay: 0.1 }}
                  className="mb-8"
                >
                  {step.component}
                </motion.div>
              </AnimatePresence>

              {/* Navigation */}
              <div className="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-800">
                <div className="flex items-center gap-2">
                  {steps.map((_, index) => (
                    <motion.div
                      key={index}
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      transition={{ delay: index * 0.1 }}
                      className={`h-2 rounded-full transition-all ${
                        index === currentStep
                          ? "w-8 bg-primary"
                          : index < currentStep
                          ? "w-2 bg-green-500"
                          : "w-2 bg-gray-300 dark:bg-gray-700"
                      }`}
                    />
                  ))}
                </div>

                <div className="flex gap-3">
                  {currentStep > 0 && (
                    <Button
                      onClick={() => setCurrentStep(prev => prev - 1)}
                      variant="outline"
                      className="px-6"
                    >
                      Précédent
                    </Button>
                  )}
                  
                  {currentStep < steps.length - 1 ? (
                    <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                      <Button
                        onClick={() => setCurrentStep(prev => prev + 1)}
                        className="px-8 h-12 text-base font-semibold bg-gradient-to-r from-primary to-purple-600 hover:from-primary/90 hover:to-purple-600/90 shadow-lg"
                        disabled={isUploading}
                      >
                        Suivant
                        <ArrowRight className="w-5 h-5 ml-2" />
                      </Button>
                    </motion.div>
                  ) : (
                    <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                      <Button
                        onClick={() => handleClose(true)}
                        className="px-8 h-12 text-base font-semibold bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 shadow-lg"
                      >
                        <CheckCircle2 className="w-5 h-5 mr-2" />
                        C'est parti !
                      </Button>
                    </motion.div>
                  )}
                </div>
              </div>

              {/* Skip option */}
              {currentStep > 0 && (
                <div className="text-center mt-4">
                  <button
                    onClick={() => handleClose(false)}
                    className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
                  >
                    Je ferai ça plus tard
                  </button>
                </div>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
