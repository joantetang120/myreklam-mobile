"use client"

import type React from "react"

import { useEffect, useState, Suspense, useRef } from "react"
import { useRouter } from "next/navigation"
import { useAuthStore } from "@/lib/auth-store"
import {
  Loader2,
  Building2,
  User,
  ImageIcon,
  Share2,
  Newspaper,
  Upload,
  Trash2,
  MapPin,
  Phone,
  Mail,
  Globe,
  Briefcase,
  FileText,
  ImageIcon as ImageIconLucide,
  Facebook,
  Instagram,
  Linkedin,
  Youtube,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { AlertTriangle } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { WysiwygEditor } from "@/components/dashboard/wysiwyg-editor"
import { OnboardingGuide } from "@/components/dashboard/onboarding-guide"
import { RewardPopup } from "@/components/dashboard/reward-popup"
import { RewardsGuide } from "@/components/dashboard/rewards-guide"
import { CompletionCelebrationModal } from "@/components/dashboard/completion-celebration-modal"
import { toast } from "sonner"
import axios from "axios"
import Image from "next/image"
import { TikTokIcon, SnapchatIcon, XIcon } from "@/components/social-icons"
import { config } from "@/lib/config"

const API_URL = config.API_URL

const ACTIVITY_SECTORS = {
  agriculture: "Agriculture",
  automotive: "Automobile",
  construction: "Construction",
  bankingFinanceInsurance: "Banque, Finance, Assurance",
  retailDistribution: "Distribution de détail",
  education: "Éducation",
  employmentTrainingStaffing: "Emploi, Formation, Recrutement",
  industrialEnvironmental: "Industrie et Environnement",
  informationCommunication: "Information et Communication",
  realEstate: "Immobilier",
  publicServicesGovernment: "Services publics et Gouvernement",
  healthcare: "Santé",
  generalServices: "Services généraux",
  telecommunicationsMedia: "Télécommunications et Médias",
  tourism: "Tourisme",
  transportationLogistics: "Transport et Logistique",
  hospitality: "Hôtellerie",
  fashionTextilesLuxuryGoods: "Mode, Textiles et Produits de luxe",
  sports: "Sports",
  personalCareServices: "Soins personnels et services",
}

export default function DashboardPage() {
  return (
    <Suspense fallback={<LoadingContent />}>
      <DashboardContent />
    </Suspense>
  )
}

function LoadingContent() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
    </div>
  )
}

function DashboardContent() {
  const router = useRouter()
  const { userId, profileType, isAuthenticated, fetchUserInfo } = useAuthStore()
  const [activeTab, setActiveTab] = useState<"infos" | "medias">("infos")
  const [loading, setLoading] = useState(true)
  const [userData, setUserData] = useState<any>(null)
  const [localFormData, setLocalFormData] = useState<any>({})
  const [isSaving, setIsSaving] = useState(false)
  const [isAddingMedia, setIsAddingMedia] = useState(false)
  const [isAddingNews, setIsAddingNews] = useState(false)
  
  // Détection des modifications non enregistrées
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const [showUnsavedWarning, setShowUnsavedWarning] = useState(false)
  const [pendingTab, setPendingTab] = useState<"infos" | "medias" | null>(null)
  const [pendingNavigation, setPendingNavigation] = useState<string | null>(null)
  const initialFormData = useRef<any>({})

  // Modals
  const [isPhotoModalOpen, setIsPhotoModalOpen] = useState(false)
  const [isMediaModalOpen, setIsMediaModalOpen] = useState(false)
  const [isNewsModalOpen, setIsNewsModalOpen] = useState(false)
  const [isBannerModalOpen, setIsBannerModalOpen] = useState(false)

  // Files
  const [photoFile, setPhotoFile] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [mediaFile, setMediaFile] = useState<File | null>(null)
  const [mediaPreview, setMediaPreview] = useState<string | null>(null)
  const [bannerFile, setBannerFile] = useState<File | null>(null)
  const [bannerPreview, setBannerPreview] = useState<string | null>(null)

  // Debug: Logger les changements de bannerFile
  useEffect(() => {
    console.log("🔄 bannerFile state changed:", bannerFile)
  }, [bannerFile])

  // Debug: Logger les changements du modal
  useEffect(() => {
    console.log("🔄 isBannerModalOpen state changed:", isBannerModalOpen)
  }, [isBannerModalOpen])

  // News
  const [newsTitle, setNewsTitle] = useState("")
  const [newsUrl, setNewsUrl] = useState("")
  const [newsImage, setNewsImage] = useState<File | null>(null)
  const [newsImagePreview, setNewsImagePreview] = useState<string | null>(null)
  const [newsList, setNewsList] = useState<any[]>([])

  // Media gallery
  const [mediaGallery, setMediaGallery] = useState<any[]>([])

  // Onboarding and rewards
  const [showOnboardingGuide, setShowOnboardingGuide] = useState(true)
  const [showRewardPopup, setShowRewardPopup] = useState(false)
  const [rewardAmount, setRewardAmount] = useState(0)
  const [rewardTitle, setRewardTitle] = useState("")
  const [showCompletionModal, setShowCompletionModal] = useState(false)
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false)
  const [onboardingRefreshKey, setOnboardingRefreshKey] = useState(0)

  useEffect(() => {
    const init = async () => {
      await fetchUserInfo()
      const profileId = localStorage.getItem("profileId")
      if (!profileId) {
        router.push("/")
        return
      }
      await loadUserData(profileId)
      setLoading(false)
    }
    init()
  }, [])

  // Protection contre la navigation avec modifications non enregistrées
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (hasUnsavedChanges) {
        e.preventDefault()
        e.returnValue = ''
        return ''
      }
    }

    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
  }, [hasUnsavedChanges])

  // Intercepter les clics sur les liens pour afficher la popup
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (!hasUnsavedChanges) return

      const target = e.target as HTMLElement
      const link = target.closest('a')
      
      if (link && link.href && !link.href.includes('#')) {
        // Vérifier si c'est un lien interne (pas un lien externe)
        const isInternalLink = link.href.startsWith(window.location.origin)
        
        if (isInternalLink) {
          e.preventDefault()
          e.stopPropagation()
          setPendingNavigation(link.href)
          setShowUnsavedWarning(true)
        }
      }
    }

    document.addEventListener('click', handleClick, true)
    return () => document.removeEventListener('click', handleClick, true)
  }, [hasUnsavedChanges])

  const loadUserData = async (profileId: string) => {
    try {
      const response = await axios.post(
        `${API_URL}/UserInfo.php`,
        { userid: profileId, Method: "readAdsByCriteria" },
        { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
      )

      if (response.data.status === "success" && response.data.userInfo?.[0]) {
        const data = response.data.userInfo[0]
        console.log("[v0] Dashboard - User data loaded:", data)
        console.log("[v0] Photo URL:", data.photoprofilurl)
        setUserData(data)
        
        // Récupérer l'email du localStorage si disponible
        const userEmail = localStorage.getItem("userEmail") || data.email || ""
        
        const formData = {
          pseudo: data.pseudo || "",
          email: userEmail,
          telephone: data.telephone || "",
          nomsociete: data.nomsociete || "",
          activite: data.activite || "",
          adresse: data.adresse || "",
          ville: data.ville || "",
          codepostal: data.codepostal || "",
          pays: data.pays || "France",
          presentation: data.presentation || "",
          facebook: data.facebook || "",
          instagram: data.instagram || "",
          x: data.x || "",
          linkedin: data.linkedin || "",
          youtube: data.youtube || "",
          tiktok: data.tiktok || "",
          snapchat: data.snapchat || "",
          publishtelephone: data.publishtelephone === "true" || data.publishtelephone === true,
          publishemail: data.publishemail === "true" || data.publishemail === true,
          publishname: data.publishname === "true" || data.publishname === true,
          publishactivity: data.publishactivity === "true" || data.publishactivity === true,
          publishadresse: data.publishadresse === "true" || data.publishadresse === true,
        }
        setLocalFormData(formData)
        initialFormData.current = JSON.parse(JSON.stringify(formData))
        setHasUnsavedChanges(false)

        // Load news for professionals
        if (data.profiletype === "professionnel") {
          loadNews(data.localUserId || profileId)
        }

        // Load media gallery
        loadMediaGallery(data.userid || profileId)
      }
    } catch (error) {
      console.error("Error loading user data:", error)
      toast.error("Erreur lors du chargement des données")
    }
  }

  const loadNews = async (userId: string) => {
    try {
      const formData = new FormData()
      formData.append("Method", "READ")
      formData.append("userId", userId)

      const response = await fetch(`${API_URL}/actualiteEntreprise.php`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      if (data) {
        setNewsList(Array.isArray(data) ? data : [])
      }
    } catch (error) {
      console.error("Error loading news:", error)
    }
  }

  const loadMediaGallery = async (userId: string) => {
    try {
      const formData = new FormData()
      formData.append("Method", "readAllByUserId")
      formData.append("Id", userId)

      console.log("[v0] Loading media gallery for userId:", userId)

      const response = await fetch(`${API_URL}/ImageDiapo.php`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      console.log("[v0] Media gallery response:", data)
      
      if (data.status === "success" && data.images) {
        setMediaGallery(data.images)
      }
    } catch (error) {
      console.error("Error loading media gallery:", error)
    }
  }

  const handleInputChange = (name: string, value: any) => {
    setLocalFormData((prev: any) => {
      const newData = { ...prev, [name]: value }
      // Détecter si des changements ont été faits
      const hasChanges = JSON.stringify(newData) !== JSON.stringify(initialFormData.current)
      setHasUnsavedChanges(hasChanges)
      return newData
    })
  }

  const handleSave = async () => {
    if (!userData) return

    setIsSaving(true)
    try {
      const formData = new FormData()

      // Add user ID and id
      const userId = userData.userid || localStorage.getItem("profileId") || ""
      formData.append("userid", userId)
      formData.append("id", userData.id || "")
      formData.append("Method", "updateUserInfo")

      // Add all form fields - utiliser les noms exacts de l'API
      formData.append("pseudo", localFormData.pseudo || "")
      formData.append("telephone", localFormData.telephone || "")
      formData.append("nomsociete", localFormData.nomsociete || "")
      formData.append("activite", localFormData.activite || "")
      formData.append("adresse", localFormData.adresse || "")
      formData.append("ville", localFormData.ville || "")
      formData.append("codepostal", localFormData.codepostal || "")
      formData.append("pays", localFormData.pays || "")
      formData.append("presentation", localFormData.presentation || "")

      // Social media - envoyer même si vide
      formData.append("facebook", localFormData.facebook || "")
      formData.append("instagram", localFormData.instagram || "")
      formData.append("x", localFormData.x || "")
      formData.append("linkedin", localFormData.linkedin || "")
      formData.append("youtube", localFormData.youtube || "")
      formData.append("tiktok", localFormData.tiktok || "")
      formData.append("snapchat", localFormData.snapchat || "")

      // Publish settings
      formData.append("publishtelephone", localFormData.publishtelephone ? "true" : "false")
      formData.append("publishemail", localFormData.publishemail ? "true" : "false")
      formData.append("publishname", localFormData.publishname ? "true" : "false")
      formData.append("publishactivity", localFormData.publishactivity ? "true" : "false")
      formData.append("publishadresse", localFormData.publishadresse ? "true" : "false")

      console.log("[v0] Saving user data for userId:", userId)

      const response = await axios.post(`${API_URL}/UserInfo.php`, formData, {
        headers: { "Content-Type": "multipart/form-data" },
      })

      console.log("[v0] Save response:", response.data)

      if (response.data.status === "success") {
        toast.success("Profil mis à jour avec succès")
        setHasUnsavedChanges(false)
        await loadUserData(userId)
      } else {
        toast.error(response.data.message || "Erreur lors de la mise à jour")
      }
    } catch (error: any) {
      console.error("[v0] Error saving:", error)
      console.error("[v0] Error response:", error.response?.data)
      toast.error(error.response?.data?.message || "Erreur lors de la sauvegarde")
    } finally {
      setIsSaving(false)
    }
  }

  const checkProfileCompletion = () => {
    if (!userData) return false
    
    const hasPhone = !!userData.telephone && userData.telephone.length > 4 && userData.telephone.replace(/[\s\-\+]/g, '').length >= 10
    const hasPhoto = !!userData.photoprofilurl
    const hasSocial = !!(userData.facebook || userData.instagram || userData.linkedin || userData.x || userData.youtube || userData.tiktok || userData.snapchat)
    
    console.log("[v0] Profile completion check:")
    console.log("[v0] - Profile type:", userData.profiletype)
    console.log("[v0] - Phone:", hasPhone, userData.telephone)
    console.log("[v0] - Photo:", hasPhoto, userData.photoprofilurl)
    console.log("[v0] - Social:", hasSocial)
    
    if (userData.profiletype === "professionnel") {
      // Pour les professionnels : pas de vérification du pseudo
      console.log("[v0] - Professional profile: no pseudo required")
      return hasPhone && hasPhoto && hasSocial
    } else {
      // Pour les particuliers : vérifier aussi le pseudo
      const hasPseudo = !!userData.pseudo
      console.log("[v0] - Pseudo:", hasPseudo, userData.pseudo)
      return hasPseudo && hasPhone && hasPhoto && hasSocial
    }
  }

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setPhotoFile(file)
      setPhotoPreview(URL.createObjectURL(file))
    }
  }

  const handleSavePhoto = async () => {
    if (!photoFile || !userData || isUploadingPhoto) return

    setIsUploadingPhoto(true)
    const userId = userData.userid || localStorage.getItem("profileId") || ""
    
    const formData = new FormData()
    formData.append("Method", "updateUserInfo")
    formData.append("id", userData.id || "")
    formData.append("photoprofilurl", photoFile)

    console.log("[v0] Uploading photo for userId:", userId)

    try {
      const response = await fetch(`${API_URL}/UserInfo.php`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      console.log("[v0] Photo upload response:", data)
      
      if (data.status === "success") {
        toast.success("Photo mise à jour avec succès")
        console.log("[v0] Photo uploaded successfully, reloading user data...")
        
        // Recharger les données utilisateur pour mettre à jour l'affichage
        const response = await axios.post(
          `${API_URL}/UserInfo.php`,
          { userid: userId, Method: "readAdsByCriteria" },
          { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
        )
        
        if (response.data.status === "success" && response.data.userInfo?.[0]) {
          const freshData = response.data.userInfo[0]
          console.log("[v0] Fresh data loaded:", freshData)
          console.log("[v0] Fresh photo URL:", freshData.photoprofilurl)
          setUserData(freshData)
          setLocalFormData(freshData)
          
          // Vérifier la complétion avec les données fraîches
          const hasPhone = !!freshData.telephone && freshData.telephone.length > 4 && freshData.telephone.replace(/[\s\-\+]/g, '').length >= 10
          const hasPhoto = !!freshData.photoprofilurl
          const hasSocial = !!(freshData.facebook || freshData.instagram || freshData.linkedin || freshData.x || freshData.youtube || freshData.tiktok || freshData.snapchat)
          
          console.log("[v0] Profile completion check with fresh data:")
          console.log("[v0] - Profile type:", freshData.profiletype)
          console.log("[v0] - Phone:", hasPhone, freshData.telephone)
          console.log("[v0] - Photo:", hasPhoto, freshData.photoprofilurl)
          console.log("[v0] - Social:", hasSocial)
          
          let isProfileComplete = false
          if (freshData.profiletype === "professionnel") {
            // Pour les professionnels : pas de vérification du pseudo
            console.log("[v0] - Professional profile: no pseudo required")
            isProfileComplete = hasPhone && hasPhoto && hasSocial
          } else {
            // Pour les particuliers : vérifier aussi le pseudo
            const hasPseudo = !!freshData.pseudo
            console.log("[v0] - Pseudo:", hasPseudo, freshData.pseudo)
            isProfileComplete = hasPseudo && hasPhone && hasPhoto && hasSocial
          }
          console.log("[v0] Profile complete:", isProfileComplete)
          
          if (isProfileComplete) {
            console.log("[v0] 🎉 TRIGGERING COMPLETION MODAL!")
            setTimeout(() => {
              setShowCompletionModal(true)
            }, 500)
          }
        }
        
        // Rafraîchir aussi les infos dans le store
        await fetchUserInfo()
        console.log("[v0] User info refreshed in store")
        // Émettre un événement pour notifier la sidebar de se rafraîchir
        window.dispatchEvent(new CustomEvent('userDataUpdated'))
        console.log("[v0] userDataUpdated event dispatched")
        // Forcer le rafraîchissement du guide d'onboarding
        setOnboardingRefreshKey(prev => prev + 1)
        console.log("[v0] Onboarding refresh key incremented")
        
        setIsPhotoModalOpen(false)
        setPhotoFile(null)
        setPhotoPreview(null)
      } else {
        toast.error(data.message || "Erreur lors de la mise à jour de la photo")
      }
    } catch (error) {
      console.error("Error updating photo:", error)
      toast.error("Erreur lors de la mise à jour de la photo")
    } finally {
      setIsUploadingPhoto(false)
    }
  }

  const handleAddNews = async () => {
    if (!newsTitle || !newsUrl || !userData || isAddingNews) {
      console.log("❌ Actualité - Données manquantes:", { newsTitle, newsUrl, userData })
      return
    }

    setIsAddingNews(true)

    const userId = userData.userid || localStorage.getItem("profileId") || ""

    console.log("📰 Ajout d'actualité:", {
      userId,
      title: newsTitle,
      url: newsUrl,
      imageSize: newsImage?.size,
      imageType: newsImage?.type
    })

    const formData = new FormData()
    formData.append("Method", "CREATE")
    formData.append("userId", userId)
    formData.append("title", newsTitle)
    formData.append("url", newsUrl)
    if (newsImage) {
      formData.append("urlphoto", newsImage)
    }

    try {
      const response = await fetch(`${API_URL}/actualiteEntreprise.php`, {
        method: "POST",
        body: formData,
      })

      console.log("📬 Réponse actualité status:", response.status)
      
      const data = await response.json()
      console.log("📬 Réponse actualité data:", data)
      
      if (data.status === "success") {
        toast.success("Actualité ajoutée avec succès")
        await loadNews(userId)
        setIsNewsModalOpen(false)
        setNewsTitle("")
        setNewsUrl("")
        setNewsImage(null)
        setNewsImagePreview(null)
      } else {
        toast.error(data.message || "Erreur lors de l'ajout de l'actualité")
      }
    } catch (error) {
      console.error("❌ Error adding news:", error)
      toast.error("Erreur lors de l'ajout de l'actualité")
    } finally {
      setIsAddingNews(false)
    }
  }

  const handleDeleteNews = async (newsId: string) => {
    if (!userData) return

    const userId = userData.userid || localStorage.getItem("profileId") || ""

    const formData = new FormData()
    formData.append("Method", "DELETE")
    formData.append("id", newsId)
    formData.append("userId", userId)

    try {
      const response = await fetch(`${API_URL}/actualiteEntreprise.php`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      if (data.status === "success") {
        toast.success("Actualité supprimée avec succès")
        await loadNews(userId)
      } else {
        toast.error("Erreur lors de la suppression")
      }
    } catch (error) {
      console.error("Error deleting news:", error)
      toast.error("Erreur lors de la suppression de l'actualité")
    }
  }

  const handleSaveBanner = async () => {
    if (!bannerFile || !userData) {
      console.log("❌ Bannière - Données manquantes:", { bannerFile, userData })
      return
    }

    const userId = userData.userid || localStorage.getItem("profileId") || ""
    
    console.log("📤 Upload de la bannière:", {
      userId: userId,
      fileName: bannerFile.name,
      fileSize: bannerFile.size,
      fileType: bannerFile.type
    })

    const formData = new FormData()
    formData.append("Method", "UPDATE")
    formData.append("userId", userId)
    formData.append("urlPhoto", bannerFile)

    try {
      toast.loading("Envoi de la bannière en cours...")
      
      const response = await fetch(`${API_URL}/bannerEntreprise.php`, {
        method: "POST",
        body: formData,
      })

      console.log("📬 Réponse bannière status:", response.status)
      
      const data = await response.json()
      console.log("📬 Réponse bannière data:", data)
      
      toast.dismiss()
      
      if (data.status === "success") {
        toast.success("Bannière mise à jour avec succès")
        await loadUserData(userId)
        setIsBannerModalOpen(false)
        setBannerFile(null)
        setBannerPreview(null)
      } else {
        toast.error(data.message || "Erreur lors de la mise à jour de la bannière")
      }
    } catch (error) {
      console.error("❌ Error updating banner:", error)
      toast.dismiss()
      toast.error("Erreur lors de la mise à jour de la bannière")
    }
  }

  const handleAddMedia = async () => {
    if (!mediaFile || !userData || isAddingMedia) return

    setIsAddingMedia(true)

    const formData = new FormData()
    formData.append("Method", "create")
    formData.append("Id", userData.userid || localStorage.getItem("profileId") || "")
    formData.append("media", mediaFile)

    console.log("[v0] Adding media for userId:", userData.userid)

    try {
      const response = await fetch(`${API_URL}/ImageDiapo.php`, {
        method: "POST",
        body: formData,
      })

      const data = await response.json()
      console.log("[v0] Add media response:", data)
      
      if (data.status === "success") {
        toast.success("Média ajouté avec succès")
        await loadMediaGallery(userData.userid || localStorage.getItem("profileId") || "")
        setIsMediaModalOpen(false)
        setMediaFile(null)
        setMediaPreview(null)
      } else {
        toast.error(data.message || "Erreur lors de l'ajout du média")
      }
    } catch (error) {
      console.error("Error adding media:", error)
      toast.error("Erreur lors de l'ajout du média")
    } finally {
      setIsAddingMedia(false)
    }
  }

  const handleDeleteMedia = async (mediaId: string) => {
    if (!confirm("Êtes-vous sûr de vouloir supprimer ce média ?")) {
      return
    }

    try {
      const response = await fetch(`${API_URL}/Media.php`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          Method: "deleteMedia",
          id: mediaId,
        }),
      })

      const data = await response.json()
      console.log("[v0] Delete media response:", data)
      
      if (data.status === "success") {
        toast.success("Média supprimé avec succès")
        await loadMediaGallery(userData.userid || localStorage.getItem("profileId") || "")
      } else {
        toast.error(data.message || "Erreur lors de la suppression")
      }
    } catch (error) {
      console.error("Error deleting media:", error)
      toast.error("Erreur lors de la suppression du média")
    }
  }

  const handleReward = (amount: number, title: string) => {
    setRewardAmount(amount)
    setRewardTitle(title)
    setShowRewardPopup(true)
  }

  if (loading || !isAuthenticated || !userId) {
    return <LoadingContent />
  }

  const isProfessional = profileType === "professionnel"

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-muted/20 to-background">
      <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        <div className="mb-8">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                {isProfessional ? (
                  <div className="p-3 rounded-xl bg-gradient-to-br from-primary/20 to-primary/10 border border-primary/20">
                    <Building2 className="h-6 w-6 text-primary" />
                  </div>
                ) : (
                  <div className="p-3 rounded-xl bg-gradient-to-br from-primary/20 to-primary/10 border border-primary/20">
                    <User className="h-6 w-6 text-primary" />
                  </div>
                )}
                <h1 className="text-3xl font-bold text-foreground">
                  {isProfessional ? "Profil Entreprise" : "Mon Profil"}
                </h1>
              </div>
              <p className="text-muted-foreground">Personnalisez vos données et vos préférences</p>
            </div>
          </div>
        </div>

        <div className="flex gap-2 mb-6 p-1 bg-muted/50 rounded-xl border border-border w-fit">
          <Button
            variant={activeTab === "infos" ? "default" : "ghost"}
            onClick={() => {
              if (hasUnsavedChanges && activeTab !== "infos") {
                setPendingTab("infos")
                setShowUnsavedWarning(true)
              } else {
                setActiveTab("infos")
              }
            }}
            className={`flex items-center gap-2 transition-all duration-200 ${
              activeTab === "infos" ? "shadow-md" : "hover:bg-muted"
            }`}
          >
            {isProfessional ? <Building2 className="h-4 w-4" /> : <User className="h-4 w-4" />}
            Informations générales
          </Button>
          <Button
            variant={activeTab === "medias" ? "default" : "ghost"}
            onClick={() => {
              if (hasUnsavedChanges && activeTab !== "medias") {
                setPendingTab("medias")
                setShowUnsavedWarning(true)
              } else {
                setActiveTab("medias")
              }
            }}
            className={`flex items-center gap-2 transition-all duration-200 ${
              activeTab === "medias" ? "shadow-md" : "hover:bg-muted"
            }`}
          >
            <ImageIcon className="h-4 w-4" />
            Médias
          </Button>
        </div>

        {/* Onboarding Guide - Visible dans l'onglet infos, avec clé unique pour forcer le re-render */}
        {userData && activeTab === "infos" && showOnboardingGuide && (
          <OnboardingGuide
            key={`onboarding-refresh-${onboardingRefreshKey}`}
            userData={userData}
            onClose={() => setShowOnboardingGuide(false)}
            onReward={handleReward}
            onOpenPhotoModal={() => setIsPhotoModalOpen(true)}
            onComplete={() => {
              console.log("[v0] Dashboard - onComplete triggered, showing completion modal")
              setShowCompletionModal(true)
            }}
            onChangeTab={(tab) => setActiveTab(tab as "infos" | "medias")}
          />
        )}

        {/* Content */}
        {activeTab === "infos" && (
          <div className="space-y-6">
            {isProfessional ? (
              <ModernProfessionalInfoForm
                formData={localFormData}
                email={localFormData.email || ""}
                onChange={handleInputChange}
              />
            ) : (
              <ModernPersonalInfoForm
                formData={localFormData}
                email={localFormData.email || ""}
                onChange={handleInputChange}
              />
            )}

            <div className="flex justify-end">
              <Button onClick={handleSave} disabled={isSaving} size="lg" className="min-w-[150px] sm:min-w-[200px]">
                {isSaving ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
                Enregistrer les modifications
              </Button>
            </div>
          </div>
        )}

        {activeTab === "medias" && (
          <ModernMediasTab
            isProfessional={isProfessional}
            formData={localFormData}
            userData={userData}
            newsList={newsList}
            mediaGallery={mediaGallery}
            onChange={handleInputChange}
            onSave={handleSave}
            isSaving={isSaving}
            onOpenNewsModal={() => setIsNewsModalOpen(true)}
            onOpenBannerModal={() => setIsBannerModalOpen(true)}
            onOpenMediaModal={() => setIsMediaModalOpen(true)}
            onDeleteNews={handleDeleteNews}
            onDeleteMedia={handleDeleteMedia}
          />
        )}
      </div>

      {/* Photo Modal */}
      <Dialog open={isPhotoModalOpen} onOpenChange={setIsPhotoModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Changer la photo de profil</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            {photoPreview && (
              <div className="flex justify-center">
                <Image
                  src={photoPreview || "/placeholder.svg"}
                  alt="Prévisualisation"
                  width={128}
                  height={128}
                  className="h-32 w-32 rounded-full object-cover"
                />
              </div>
            )}
            <Input type="file" accept="image/*" onChange={handlePhotoChange} disabled={isUploadingPhoto} />
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setIsPhotoModalOpen(false)} disabled={isUploadingPhoto}>
                Annuler
              </Button>
              <Button onClick={handleSavePhoto} disabled={!photoFile || isUploadingPhoto}>
                {isUploadingPhoto ? "Enregistrement..." : "Enregistrer"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* News Modal */}
      <Dialog open={isNewsModalOpen} onOpenChange={setIsNewsModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ajouter une actualité</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Titre</Label>
              <Input
                value={newsTitle}
                onChange={(e) => setNewsTitle(e.target.value)}
                placeholder="Titre de l'actualité"
              />
            </div>
            <div>
              <Label>URL</Label>
              <Input
                type="url"
                value={newsUrl}
                onChange={(e) => setNewsUrl(e.target.value)}
                placeholder="https://..."
              />
            </div>
            <div>
              <Label>Image</Label>
              {newsImagePreview && (
                <div className="relative h-48 rounded-lg overflow-hidden mb-2">
                  <Image
                    src={newsImagePreview || "/placeholder.svg"}
                    alt="Prévisualisation"
                    fill
                    className="object-cover"
                  />
                </div>
              )}
              <Input
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0] || null
                  setNewsImage(file)
                  if (file) {
                    setNewsImagePreview(URL.createObjectURL(file))
                  }
                }}
              />
            </div>
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setIsNewsModalOpen(false)} disabled={isAddingNews}>
                Annuler
              </Button>
              <Button onClick={handleAddNews} disabled={!newsTitle || !newsUrl || isAddingNews}>
                {isAddingNews ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                    Ajout en cours...
                  </>
                ) : (
                  "Ajouter"
                )}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Banner Modal */}
      <Dialog open={isBannerModalOpen} onOpenChange={setIsBannerModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ajouter une bannière</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Dimensions recommandées : 1200x300 pixels. Formats acceptés : JPG, PNG.
            </p>
            {bannerPreview && (
              <div className="relative h-32 rounded-lg overflow-hidden">
                <Image src={bannerPreview || "/placeholder.svg"} alt="Prévisualisation" fill className="object-cover" />
              </div>
            )}
            <Input
              type="file"
              accept="image/*"
              onChange={(e) => {
                const file = e.target.files?.[0] || null
                console.log("📁 Fichier bannière sélectionné:", file)
                setBannerFile(file)
                if (file) {
                  const preview = URL.createObjectURL(file)
                  console.log("🖼️ Preview créé:", preview)
                  setBannerPreview(preview)
                }
              }}
            />
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setIsBannerModalOpen(false)}>
                Annuler
              </Button>
              <Button 
                onClick={() => {
                  console.log("🔘 CLIC SUR LE BOUTON BANNIERE !!!")
                  console.log("🔘 Bouton Enregistrer cliqué, bannerFile:", bannerFile)
                  handleSaveBanner()
                }} 
                disabled={!bannerFile}
              >
                {!bannerFile ? "⚠️ Sélectionnez d'abord un fichier" : "💾 ENREGISTRER LA BANNIERE"}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <Dialog open={isMediaModalOpen} onOpenChange={setIsMediaModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ajouter un média</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Ajoutez des photos ou vidéos à votre galerie. Formats acceptés : JPG, PNG, MP4, MOV.
            </p>
            {mediaPreview && (
              <div className="relative h-48 rounded-lg overflow-hidden">
                {mediaFile?.type.startsWith("image/") ? (
                  <Image
                    src={mediaPreview || "/placeholder.svg"}
                    alt="Prévisualisation"
                    fill
                    className="object-cover"
                  />
                ) : (
                  <video src={mediaPreview} controls className="w-full h-full object-cover" />
                )}
              </div>
            )}
            <Input
              type="file"
              accept="image/*,video/*"
              onChange={(e) => {
                const file = e.target.files?.[0] || null
                setMediaFile(file)
                if (file) {
                  setMediaPreview(URL.createObjectURL(file))
                }
              }}
            />
            <div className="flex justify-end gap-2">
              <Button variant="outline" onClick={() => setIsMediaModalOpen(false)} disabled={isAddingMedia}>
                Annuler
              </Button>
              <Button onClick={handleAddMedia} disabled={!mediaFile || isAddingMedia}>
                {isAddingMedia ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                    Ajout en cours...
                  </>
                ) : (
                  "Ajouter"
                )}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Unsaved Changes Warning Dialog */}
      <Dialog open={showUnsavedWarning} onOpenChange={setShowUnsavedWarning}>
        <DialogContent>
          <DialogHeader>
            <div className="flex items-center gap-3">
              <div className="p-3 rounded-full bg-amber-100 dark:bg-amber-900/20">
                <AlertTriangle className="h-6 w-6 text-amber-600 dark:text-amber-500" />
              </div>
              <div>
                <DialogTitle>Modifications non enregistrées</DialogTitle>
                <DialogDescription className="mt-1">
                  Vous avez des modifications en cours qui n'ont pas été enregistrées.
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>
          <div className="py-4">
            <p className="text-sm text-muted-foreground">
              Si vous changez de page maintenant, vos modifications seront perdues. Voulez-vous enregistrer avant de continuer ?
            </p>
          </div>
          <DialogFooter className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => {
                setShowUnsavedWarning(false)
                setHasUnsavedChanges(false)
                
                // Changement d'onglet
                if (pendingTab) {
                  setActiveTab(pendingTab)
                  setPendingTab(null)
                }
                
                // Navigation vers une autre page
                if (pendingNavigation) {
                  window.location.href = pendingNavigation
                  setPendingNavigation(null)
                }
              }}
            >
              Continuer sans enregistrer
            </Button>
            <Button
              onClick={async () => {
                setShowUnsavedWarning(false)
                await handleSave()
                
                // Changement d'onglet
                if (pendingTab) {
                  setActiveTab(pendingTab)
                  setPendingTab(null)
                }
                
                // Navigation vers une autre page
                if (pendingNavigation) {
                  window.location.href = pendingNavigation
                  setPendingNavigation(null)
                }
              }}
            >
              Enregistrer et continuer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reward Popup */}
      <RewardPopup
        isOpen={showRewardPopup}
        amount={rewardAmount}
        title={rewardTitle}
        onClose={() => setShowRewardPopup(false)}
      />

      {/* Completion Celebration Modal */}
      <CompletionCelebrationModal
        isOpen={showCompletionModal}
        onClose={() => setShowCompletionModal(false)}
      />
    </div>
  )
}

function ModernPersonalInfoForm({ formData, email, onChange }: any) {
  return (
    <Card id="personal-info-section" className="border-2 hover:border-primary/20 transition-colors scroll-mt-6">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <User className="h-5 w-5 text-primary" />
          Informations personnelles
        </CardTitle>
        <CardDescription>Gérez vos informations de profil</CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <User className="h-4 w-4 text-muted-foreground" />
              Pseudo
            </Label>
            <Input value={formData.pseudo || ""} disabled className="bg-muted/50" />
          </div>

          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <Mail className="h-4 w-4 text-muted-foreground" />
              Adresse email
            </Label>
            <Input value={email} disabled className="bg-muted/50" />
            <div className="flex items-center gap-2 mt-2 p-3 bg-muted/30 rounded-lg">
              <input
                type="checkbox"
                checked={formData.publishemail || false}
                onChange={(e) => onChange("publishemail", e.target.checked)}
                className="rounded"
              />
              <span className="text-sm text-muted-foreground">Afficher sur le profil public</span>
            </div>
          </div>

          <div className="space-y-2">
            <Label className="flex items-center gap-2">
              <Phone className="h-4 w-4 text-muted-foreground" />
              Téléphone
            </Label>
            <Input
              value={formData.telephone || ""}
              onChange={(e) => onChange("telephone", e.target.value)}
              placeholder="+33 6 12 34 56 78"
            />
            <div className="flex items-center gap-2 mt-2 p-3 bg-muted/30 rounded-lg">
              <input
                type="checkbox"
                checked={formData.publishtelephone || false}
                onChange={(e) => onChange("publishtelephone", e.target.checked)}
                className="rounded"
              />
              <span className="text-sm text-muted-foreground">Afficher sur le profil public</span>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

function ModernProfessionalInfoForm({ formData, email, onChange }: any) {
  return (
    <div className="space-y-6">
      <Card className="border-2 hover:border-primary/20 transition-colors">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-5 w-5 text-primary" />
            Informations de l'entreprise
          </CardTitle>
          <CardDescription>Détails de votre société</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Building2 className="h-4 w-4 text-muted-foreground" />
                Nom de la société
              </Label>
              <Input
                value={formData.nomsociete || ""}
                onChange={(e) => onChange("nomsociete", e.target.value)}
                placeholder="Nom de votre entreprise"
              />
            </div>

            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Briefcase className="h-4 w-4 text-muted-foreground" />
                Secteur d'activité
              </Label>
              <Select value={formData.activite || ""} onValueChange={(v) => onChange("activite", v)}>
                <SelectTrigger>
                  <SelectValue placeholder="Sélectionnez une activité" />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(ACTIVITY_SECTORS).map(([key, label]) => (
                    <SelectItem key={key} value={key}>
                      {label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="border-2 hover:border-primary/20 transition-colors">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Phone className="h-5 w-5 text-primary" />
            Coordonnées
          </CardTitle>
          <CardDescription>Informations de contact</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-muted-foreground" />
                Téléphone
              </Label>
              <Input
                value={formData.telephone || ""}
                onChange={(e) => onChange("telephone", e.target.value)}
                placeholder="+33 1 23 45 67 89"
              />
              <div className="flex items-center gap-2 mt-2 p-3 bg-muted/30 rounded-lg">
                <input
                  type="checkbox"
                  checked={formData.publishtelephone || false}
                  onChange={(e) => onChange("publishtelephone", e.target.checked)}
                  className="rounded"
                />
                <span className="text-sm text-muted-foreground">Afficher sur le profil public</span>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="flex items-center gap-2">
                <Mail className="h-4 w-4 text-muted-foreground" />
                Email
              </Label>
              <Input value={email} disabled className="bg-muted/50" />
              <div className="flex items-center gap-2 mt-2 p-3 bg-muted/30 rounded-lg">
                <input
                  type="checkbox"
                  checked={formData.publishemail || false}
                  onChange={(e) => onChange("publishemail", e.target.checked)}
                  className="rounded"
                />
                <span className="text-sm text-muted-foreground">Afficher sur le profil public</span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="border-2 hover:border-primary/20 transition-colors">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-primary" />
            Adresse
          </CardTitle>
          <CardDescription>Localisation de votre entreprise</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2 md:col-span-2">
              <Label>Adresse complète</Label>
              <Input
                value={formData.adresse || ""}
                onChange={(e) => onChange("adresse", e.target.value)}
                placeholder="123 Rue de la République"
              />
            </div>

            <div className="space-y-2">
              <Label>Code Postal</Label>
              <Input
                value={formData.codepostal || ""}
                onChange={(e) => onChange("codepostal", e.target.value)}
                placeholder="75001"
              />
            </div>

            <div className="space-y-2">
              <Label>Ville</Label>
              <Input value={formData.ville || ""} disabled className="bg-muted/50" />
            </div>

            <div className="space-y-2">
              <Label>Pays</Label>
              <Select value={formData.pays || "France"} onValueChange={(v) => onChange("pays", v)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="France">France</SelectItem>
                  <SelectItem value="Belgique">Belgique</SelectItem>
                  <SelectItem value="Suisse">Suisse</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex items-center gap-2 p-3 bg-muted/30 rounded-lg">
            <input
              type="checkbox"
              checked={formData.publishadresse || false}
              onChange={(e) => onChange("publishadresse", e.target.checked)}
              className="rounded"
            />
            <span className="text-sm text-muted-foreground">Afficher l'adresse complète sur le profil public</span>
          </div>
        </CardContent>
      </Card>

      <Card id="presentation-section" className="border-2 hover:border-primary/20 transition-colors scroll-mt-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5 text-primary" />
            Présentation
          </CardTitle>
          <CardDescription>Décrivez votre entreprise</CardDescription>
        </CardHeader>
        <CardContent>
          <WysiwygEditor
            value={formData.presentation || ""}
            onChange={(v) => onChange("presentation", v)}
            placeholder="Qui sommes-nous ? Présentez votre entreprise, vos valeurs, votre histoire..."
          />
        </CardContent>
      </Card>
    </div>
  )
}

function ModernMediasTab({
  isProfessional,
  formData,
  userData,
  newsList,
  mediaGallery,
  onChange,
  onSave,
  isSaving,
  onOpenNewsModal,
  onOpenBannerModal,
  onOpenMediaModal,
  onDeleteNews,
  onDeleteMedia,
}: any) {
  return (
    <div className="space-y-6">
      <Card id="social-media-section" className="border-2 hover:border-primary/20 transition-colors scroll-mt-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Share2 className="h-5 w-5 text-primary" />
            Réseaux Sociaux
          </CardTitle>
          <CardDescription>Connectez vos profils sociaux</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <ModernSocialMediaForm formData={formData} onChange={onChange} />
          <div className="flex justify-end">
            <Button onClick={onSave} disabled={isSaving}>
              {isSaving ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : null}
              Enregistrer les réseaux sociaux
            </Button>
          </div>
        </CardContent>
      </Card>

      {isProfessional && (
        <Card className="border-2 hover:border-primary/20 transition-colors">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center gap-2">
                  <Newspaper className="h-5 w-5 text-primary" />
                  Actualités
                </CardTitle>
                <CardDescription>Partagez les dernières nouvelles de votre entreprise</CardDescription>
              </div>
              <Button onClick={onOpenNewsModal} size="sm">
                <Upload className="h-4 w-4 mr-2" />
                Ajouter
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {newsList.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {newsList.map((news) => (
                  <div
                    key={news.id}
                    className="group relative border-2 border-border rounded-xl overflow-hidden hover:border-primary/40 hover:shadow-xl transition-all duration-300"
                  >
                    <div className="relative h-48">
                      <Image src={`${API_URL}/${news.urlphoto}`} alt={news.title} fill className="object-cover" />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                      <button
                        className="absolute top-2 right-2 bg-destructive text-destructive-foreground rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity shadow-lg hover:scale-110 transform duration-200"
                        onClick={() => onDeleteNews(news.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                    <div className="p-4 bg-card">
                      <h3 className="font-semibold mb-2 line-clamp-2">{news.title}</h3>
                      <a
                        href={news.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-primary hover:underline text-sm flex items-center gap-1"
                      >
                        Voir plus
                        <Globe className="h-3 w-3" />
                      </a>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-12 text-muted-foreground">
                <Newspaper className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>Aucune actualité pour le moment</p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {isProfessional && (
        <Card className="border-2 hover:border-primary/20 transition-colors">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center gap-2">
                  <ImageIconLucide className="h-5 w-5 text-primary" />
                  Bannière de l'entreprise
                </CardTitle>
                <CardDescription>Image de couverture de votre profil</CardDescription>
              </div>
              <Button 
                onClick={() => {
                  console.log("🚀 Ouverture du modal bannière")
                  onOpenBannerModal()
                }} 
                size="sm"
              >
                <Upload className="h-4 w-4 mr-2" />
                {userData?.bannerUrl ? "Modifier" : "Ajouter une bannière"}
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {(() => {
              console.log("🖼️ Données bannière:", { 
                bannerUrl: userData?.bannerUrl,
                bannerData: userData?.bannerData 
              })
              return userData?.bannerUrl ? (
                <div className="relative h-64 rounded-xl overflow-hidden border-2 border-border hover:border-primary/40 transition-colors">
                  <Image
                    src={`${API_URL}${userData.bannerUrl}`}
                    alt="Bannière"
                    fill
                    className="object-cover"
                  />
                </div>
              ) : (
                <div className="h-64 rounded-xl border-2 border-dashed border-border flex items-center justify-center text-muted-foreground">
                  <div className="text-center">
                    <ImageIconLucide className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>Aucune bannière ajoutée</p>
                    <p className="text-sm mt-2">Dimensions recommandées : 1200x300 pixels</p>
                  </div>
                </div>
              )
            })()}
          </CardContent>
        </Card>
      )}

      <Card className="border-2 hover:border-primary/20 transition-colors">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <ImageIcon className="h-5 w-5 text-primary" />
                Galerie de Médias
              </CardTitle>
              <CardDescription>Photos et vidéos de votre entreprise</CardDescription>
            </div>
            <Button onClick={onOpenMediaModal} size="sm">
              <Upload className="h-4 w-4 mr-2" />
              Ajouter
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {mediaGallery.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {mediaGallery.map((media, index) => (
                <div key={media.id || index} className="relative group">
                  <div className="relative h-48 rounded-xl overflow-hidden border-2 border-border hover:border-primary/40 transition-all duration-300">
                    {media.urlimg &&
                    (media.urlimg.endsWith(".jpg") ||
                      media.urlimg.endsWith(".png") ||
                      media.urlimg.endsWith(".jpeg") ||
                      media.urlimg.endsWith(".webp")) ? (
                      <Image src={`${API_URL}${media.urlimg}`} alt={`Media ${index}`} fill className="object-cover" />
                    ) : (
                      <video src={`${API_URL}${media.urlimg}`} controls className="w-full h-full object-cover" />
                    )}
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                      <Badge variant="secondary" className="text-xs">
                        {media.urlimg &&
                        (media.urlimg.endsWith(".jpg") ||
                          media.urlimg.endsWith(".png") ||
                          media.urlimg.endsWith(".jpeg") ||
                          media.urlimg.endsWith(".webp"))
                          ? "Photo"
                          : "Vidéo"}
                      </Badge>
                    </div>
                  </div>
                  <button
                    className="absolute top-2 right-2 bg-destructive text-destructive-foreground rounded-full p-2 opacity-0 group-hover:opacity-100 transition-opacity shadow-lg hover:scale-110 transform duration-200"
                    onClick={() => onDeleteMedia(media.id)}
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12 text-muted-foreground">
              <ImageIcon className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>Aucun média pour le moment</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

function ModernSocialMediaForm({ formData, onChange }: any) {
  const socials = [
    {
      name: "facebook",
      label: "Facebook",
      placeholder: "https://facebook.com/votre-page",
      icon: Facebook,
      color: "text-[#1877F2]",
    },
    {
      name: "instagram",
      label: "Instagram",
      placeholder: "https://instagram.com/votre-compte",
      icon: Instagram,
      color: "text-[#E4405F]",
    },
    {
      name: "x",
      label: "X (Twitter)",
      placeholder: "https://x.com/votre-compte",
      icon: XIcon,
      color: "text-foreground",
    },
    {
      name: "linkedin",
      label: "LinkedIn",
      placeholder: "https://linkedin.com/company/votre-entreprise",
      icon: Linkedin,
      color: "text-[#0A66C2]",
    },
    {
      name: "youtube",
      label: "YouTube",
      placeholder: "https://youtube.com/@votre-chaine",
      icon: Youtube,
      color: "text-[#FF0000]",
    },
    {
      name: "tiktok",
      label: "TikTok",
      placeholder: "https://tiktok.com/@votre-compte",
      icon: TikTokIcon,
      color: "text-foreground",
    },
    {
      name: "snapchat",
      label: "Snapchat",
      placeholder: "https://snapchat.com/add/votre-compte",
      icon: SnapchatIcon,
      color: "text-[#FFFC00]",
    },
  ]

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {socials.map((social) => (
        <div key={social.name} className="space-y-2">
          <Label className="flex items-center gap-2">
            <social.icon className={`h-4 w-4 ${social.color}`} />
            {social.label}
          </Label>
          <div className="relative">
            <div className="absolute left-3 top-1/2 -translate-y-1/2">
              <social.icon className={`h-4 w-4 ${social.color}`} />
            </div>
            <Input
              type="url"
              value={formData[social.name] || ""}
              onChange={(e) => onChange(social.name, e.target.value)}
              placeholder={social.placeholder}
              className="pl-10"
            />
          </div>
        </div>
      ))}
    </div>
  )
}
