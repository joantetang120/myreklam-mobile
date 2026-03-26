"use client"

import { use, useEffect, useState } from "react"
import { notFound } from "next/navigation"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { fetchDealImages, fetchPublisherData, toggleFavorite, startConversation, checkUserSubscription, createApplication } from "@/lib/api"
import { config } from "@/lib/config"
import axios from "axios"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  Heart,
  Share2,
  MapPin,
  Calendar,
  ExternalLink,
  GraduationCap,
  Clock,
  Award,
  DollarSign,
  Users,
  BookOpen,
  Target,
  CheckCircle2,
  FileText,
  Briefcase,
  ChevronRight,
  Building2,
  User,
  Mail,
} from "lucide-react"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import labelObject from "@/lib/constants/label-object"
import Image from "next/image"
import { formatDateRelative } from "@/lib/utils"
import { CommentsSection } from "@/components/comments/comments-section"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { ShareModal } from "@/components/share-modal"
import { PublisherCard } from "@/components/publisher-card"
import { LocationMap } from "@/components/map/location-map"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { toast } from "sonner"

function formatAddress(address: any): string {
  if (!address) return ""

  if (typeof address === "string") {
    try {
      address = JSON.parse(address)
    } catch {
      return address
    }
  }

  const parts = []
  if (address.adresse || address.line1) parts.push(address.adresse || address.line1)
  if (address.ville || address.city) parts.push(address.ville || address.city)
  if (address.codepostal || address.zipcode || address.postalCode) {
    parts.push(address.codepostal || address.zipcode || address.postalCode)
  }

  return parts.filter(Boolean).join(", ")
}

// Fonction pour parser les données au format PostgreSQL array
function parsePostgreSQLArray(data: string | null): string[] {
  if (!data) return []
  
  try {
    // Si c'est déjà un array JavaScript
    if (Array.isArray(data)) return data
    
    // Parser le format PostgreSQL {value1,value2,value3}
    if (typeof data === 'string') {
      // Supprimer les accolades et diviser par les virgules
      const cleaned = data.replace(/[{}]/g, '')
      if (!cleaned) return []
      return cleaned.split(',').map(item => item.trim()).filter(Boolean)
    }
    
    return []
  } catch (error) {
    console.error('Error parsing PostgreSQL array:', error)
    return []
  }
}

// Fonction pour nettoyer et sécuriser le HTML (garder la structure)
function sanitizeHtml(html: string): string {
  if (!html) return ""
  
  // Décoder les entités HTML en utilisant un élément DOM temporaire
  if (typeof document !== 'undefined') {
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = html
    const decodedHtml = tempDiv.innerHTML
    
    // Nettoyer les styles inline excessifs mais garder la structure HTML
    return decodedHtml
      .replace(/style="[^"]*"/g, '') // Supprimer les styles inline
      .replace(/class="[^"]*"/g, '') // Supprimer les classes
      .trim()
  }
  
  // Fallback pour le rendu côté serveur
  return html
    .replace(/style="[^"]*"/g, '')
    .replace(/class="[^"]*"/g, '')
    .trim()
}

async function updateViewCount(announcementId: string) {
  try {
    console.log("[v0] Updating view count for training announcement:", announcementId)
    const response = await axios.post(
      `${config.API_URL}/Ads.php`,
      {
        id: announcementId,
        Method: "updateNumberViewAds",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    console.log("[v0] View count update response:", response.data)
  } catch (error) {
    console.error("[v0] Error updating view count:", error)
  }
}

function ImageCarousel({ images }: { images: string[] }) {
  const [currentIndex, setCurrentIndex] = useState(0)

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-purple-50 to-blue-50">
        <GraduationCap className="w-24 h-24 text-purple-300" />
      </div>
    )
  }

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % images.length)
  }

  const prevImage = () => {
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length)
  }

  const getImageUrl = (imagePath: string) => {
    if (!imagePath) return ""
    
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath
    }
    
    // S'assurer que le chemin commence par / pour un chemin absolu
    let cleanPath = imagePath
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/' + cleanPath
    }
    
    // Remplacer /ads/ par /annonces/ si présent
    if (cleanPath.includes("/ads/")) {
      cleanPath = cleanPath.replace("/ads/", "/annonces/")
    }
    
    // Construire l'URL complète avec l'API_URL
    return `${config.API_URL}${cleanPath}`
  }

  return (
    <div className="relative w-full h-full group">
      <Image
        src={getImageUrl(images[currentIndex])}
        alt="Training image"
        fill
        className="object-cover"
        onError={(e) => {
          const target = e.target as HTMLImageElement
          target.style.display = "none"
        }}
      />
      {images.length > 1 && (
        <>
          <button
            onClick={prevImage}
            className="absolute left-4 top-1/2 -translate-y-1/2 bg-white/90 hover:bg-white text-gray-800 p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all shadow-lg"
          >
            ←
          </button>
          <button
            onClick={nextImage}
            className="absolute right-4 top-1/2 -translate-y-1/2 bg-white/90 hover:bg-white text-gray-800 p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all shadow-lg"
          >
            →
          </button>
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2">
            {images.map((_, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentIndex(idx)}
                className={`w-2 h-2 rounded-full transition-all ${
                  idx === currentIndex ? "bg-white w-8" : "bg-white/60 hover:bg-white/80"
                }`}
              />
            ))}
          </div>
        </>
      )}
    </div>
  )
}

export default function TrainingPage({ params }: { params: Promise<{ announcementId: string }> }) {
  // Unwrap params using React.use()
  const resolvedParams = use(params)
  const announcementId = resolvedParams.announcementId

  const [training, setTraining] = useState<any>(null)
  const [images, setImages] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [isFavorite, setIsFavorite] = useState(false)
  const [relatedTrainings, setRelatedTrainings] = useState<any[]>([])
  const [companyData, setCompanyData] = useState<any>(null)
  const [currentUserData, setCurrentUserData] = useState<any>(null)
  const [publisherHasSubscription, setPublisherHasSubscription] = useState(false)
  const router = useRouter()
  const [isContactingLoading, setIsContactingLoading] = useState(false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [documents, setDocuments] = useState<any[]>([])
  const [loadingDocuments, setLoadingDocuments] = useState(false)
  const [showRegistrationDialog, setShowRegistrationDialog] = useState(false)
  const [isRegistering, setIsRegistering] = useState(false)
  const [hasMultipleParticipants, setHasMultipleParticipants] = useState(false)
  const [participantCount, setParticipantCount] = useState(1)
  const [registrationResult, setRegistrationResult] = useState<{
    success: boolean
    message: string
  } | null>(null)

  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") || "" : ""
  const currentUserIsPro = currentUserData?.companyData?.profiletype === "professionnel"
  const { limits } = useSubscriptionLimits()

  const isExpired = training?.endDate ? new Date(training.endDate) < new Date() : false

  const handleFavorite = async (newFavoriteState: boolean) => {
    const result = await toggleFavorite(userId, training?.id || "", newFavoriteState)
    if (result.success) {
      toastSuccess(result.message || "Favori mis à jour")
      setIsFavorite(newFavoriteState)
    } else {
      toastError(result.error || "Erreur lors de la mise à jour")
    }
  }

  const handleShare = () => {
    setShowShareModal(true)
  }

  const handleContact = async () => {
    if (!userId) {
      router.push("/login-required")
      return
    }

    setIsContactingLoading(true)
    try {
      if (!training?.userId) {
        toastError("Impossible de contacter cet utilisateur")
        return
      }
      
      const conversationId = await startConversation(training.userId)

      if (!conversationId) {
        toastError("Erreur lors du démarrage de la conversation")
        return
      }

      router.push(`/messages?action=conversation&conversationId=${conversationId}`)
      toastSuccess("Conversation démarrée")
    } catch (error) {
      toastError("Erreur lors du démarrage de la conversation")
    } finally {
      setIsContactingLoading(false)
    }
  }

  const handleRegisterClick = () => {
    if (!userId) {
      router.push("/login-required")
      return
    }
    setShowRegistrationDialog(true)
  }

  const handleConfirmRegistration = async () => {
    setIsRegistering(true)
    try {
      const finalParticipantCount = hasMultipleParticipants ? participantCount : 1
      const result = await createApplication(announcementId, userId, finalParticipantCount)
      
      if (result.status === "success") {
        setRegistrationResult({
          success: true,
          message: result.message || "Candidature créée avec succès"
        })
      } else {
        setRegistrationResult({
          success: false,
          message: result.message || "Erreur lors de la création de la candidature"
        })
      }
    } catch (error) {
      console.error("Erreur lors de l'inscription:", error)
      setRegistrationResult({
        success: false,
        message: "Erreur lors de la création de la candidature"
      })
    } finally {
      setIsRegistering(false)
      setShowRegistrationDialog(false)
    }
  }

  const fetchDocuments = async () => {
    setLoadingDocuments(true)
    try {
      const response = await axios.post(
        `${config.API_URL}/DocumentFiles.php`,
        {
          Method: "get_ad_document_files",
          ad_id: announcementId,
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        }
      )

      console.log("Documents response:", response.data)

      if (response.data?.status === "success" && response.data?.document_files?.length > 0) {
        setDocuments(response.data.document_files)
      }
    } catch (error) {
      console.error("Error fetching documents:", error)
    } finally {
      setLoadingDocuments(false)
    }
  }

  const handleDownloadDocuments = () => {
    if (documents.length === 0) return

    // Vérifier si l'utilisateur peut télécharger des documents
    if (!limits.canAccessDocuments) {
      toastError("Vous devez avoir un abonnement premium pour télécharger les documents de formation")
      return
    }

    documents.forEach((doc) => {
      const link = document.createElement('a')
      link.href = `${config.API_URL}${doc.url}`
      link.download = doc.name || 'document'
      link.target = '_blank'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    })

    toastSuccess(`${documents.length} document(s) téléchargé(s)`)
  }

  useEffect(() => {
    if (!announcementId) return

    const fetchTrainingData = async () => {
      try {
        const fetchedTraining = await fetchAnnouncementDetail(announcementId)
        if (!fetchedTraining) {
          notFound()
        }
        console.log("Training data:", fetchedTraining)
        setTraining(fetchedTraining)
        setIsFavorite(fetchedTraining.isFavorite || false)

        await updateViewCount(announcementId)

        const imagesResult = await fetchDealImages(announcementId)
        if (imagesResult.success) {
          setImages(imagesResult.images)
        }

        // Récupérer les documents
        await fetchDocuments()
      } catch (error) {
        console.error("Error loading training data:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchTrainingData()
  }, [announcementId])

  useEffect(() => {
    if (training?.userId) {
      const loadPublisherData = async () => {
        const result = await fetchPublisherData(training.userId)
        if (result.success) {
          setCompanyData(result.userData.companyData)
          const hasSubscription = await checkUserSubscription(training.userId)
          setPublisherHasSubscription(hasSubscription)
        }
      }
      loadPublisherData()
    }
  }, [training?.userId])

  useEffect(() => {
    if (userId) {
      const loadCurrentUserData = async () => {
        const result = await fetchPublisherData(userId)
        if (result.success) {
          setCurrentUserData(result.userData)
        }
      }
      loadCurrentUserData()
    }
  }, [userId])

  // Charger les formations similaires
  useEffect(() => {
    if (training) {
      const loadRelatedTrainings = async () => {
        try {
          const response = await axios.post(
            "https://api.myreklam.fr/Ads.php",
            {
              Method: "readAdsByCriteria",
              category: "formations",
            },
            {
              headers: {
                "Content-Type": "application/x-www-form-urlencoded",
              },
            }
          )
          
          if (response.data.status === "success" && response.data.ads) {
            const filtered = response.data.ads
              .filter((d: any) => d.id !== announcementId)
              .slice(-4)
              .reverse()
            
            // Charger les données utilisateur pour chaque formation
            const trainingsWithUserData = await Promise.all(
              filtered.map(async (trainingItem: any) => {
                try {
                  if (trainingItem.userId) {
                    const userResult = await fetchPublisherData(trainingItem.userId)
                    if (userResult.success) {
                      return { ...trainingItem, companyData: userResult.userData.companyData }
                    }
                  }
                  return trainingItem
                } catch (error) {
                  console.error(`Erreur chargement données utilisateur pour ${trainingItem.id}:`, error)
                  return trainingItem
                }
              })
            )
            
            setRelatedTrainings(trainingsWithUserData)
          }
        } catch (error) {
          console.error("Error loading related trainings:", error)
        }
      }
      loadRelatedTrainings()
    }
  }, [training, announcementId])

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40">
        <div className="animate-pulse space-y-8">
          <div className="h-8 bg-gray-200 rounded w-3/4"></div>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-4">
              <div className="h-96 bg-gray-200 rounded"></div>
              <div className="h-32 bg-gray-200 rounded"></div>
            </div>
            <div className="space-y-4">
              <div className="h-64 bg-gray-200 rounded"></div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!training) {
    notFound()
  }

  // Parser les données selon les vraies données de l'API
  const trainingStyle = parsePostgreSQLArray(training.trainingStyle)
  const trainingPublic = parsePostgreSQLArray(training.trainingPublic)
  const requiredLevels = parsePostgreSQLArray(training.requiredLevels)
  const certification = parsePostgreSQLArray(training.certification)
  const trainingFunding = parsePostgreSQLArray(training.trainingFunding)

  const getOrganizationName = () => {
    if (!companyData) return "Organisation"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Organisation"
    }
    return companyData.pseudo || "Particulier"
  }

  const isProfessional = companyData?.profiletype === "professionnel"

  // Fonction pour obtenir la photo de l'organisateur
  const getOrganizerPhoto = () => {
    if (!companyData || !companyData.photoprofilurl) return null
    
    // Si l'URL commence déjà par http, la retourner telle quelle
    if (companyData.photoprofilurl.startsWith("http")) {
      return companyData.photoprofilurl
    }
    
    // Sinon, ajouter le préfixe API_URL
    return `${config.API_URL}${companyData.photoprofilurl}`
  }

  // Fonction pour formater le prix avec tous les détails
  const getFormattedPrice = () => {
    const price = training.price
    
    // Gérer les cas spéciaux selon priceType
    // priceType: "1" = NET, "2" = HT, "3" = TTC, "4" = Gratuit, "5" = Devis sur-mesure
    if (training.priceType === "4") {
      return "Gratuit"
    }
    
    if (training.priceType === "5") {
      return "Devis sur-mesure"
    }
    
    if (!price) return "Prix sur demande"
    
    const numPrice = Number.parseFloat(price)
    if (numPrice === 0) return "Gratuit"
    
    // Construire le texte du prix
    let priceText = `${numPrice.toFixed(2)} €`
    
    // Ajouter NET, HT ou TTC selon priceType
    if (training.priceType === "1") {
      priceText += " NET"
    } else if (training.priceType === "2") {
      priceText += " HT"
    } else if (training.priceType === "3") {
      priceText += " TTC"
    }
    
    // Ajouter "par groupe" ou "par personne" selon le champ public
    if (training.public === "groupe") {
      priceText += " par groupe"
    } else if (training.public === "personne") {
      priceText += " par personne"
    }
    
    // Ajouter la période selon tempo
    if (training.tempo === "jour") {
      priceText += " par jour"
    } else if (training.tempo === "heure") {
      priceText += " par heure"
    } else if (training.tempo === "mois") {
      priceText += " par mois"
    }
    
    return priceText
  }

  // Fonction pour formater la durée
  const getFormattedDuration = () => {
    if (training.durationInH && Number.parseFloat(training.durationInH) > 0) {
      return `${training.durationInH} ${training.duration == 0 ? ' heures' : training.duration == 1 ? ' jours' : 
        training.duration == 2 ? ' semaines' : training.duration == 3 ? ' mois' : ' années'
      }`
    }
    if (training.duration && Number.parseFloat(training.duration) > 0) {
      const duration = Number.parseFloat(training.duration)
      const tempo = training.tempo || 'heures'
      
      switch (tempo) {
        case 'jour':
          return `${duration} jour${duration > 1 ? 's' : ''}`
        case 'semaine':
          return `${duration} semaine${duration > 1 ? 's' : ''}`
        case 'mois':
          return `${duration} mois`
        default:
          return `${duration} heures`
      }
    }
    return "Durée non spécifiée"
  }

  return (
    <div className="min-h-screen bg-gray-50 overflow-x-hidden">
      <div className="bg-white border-b overflow-x-hidden">
        <div className="max-w-7xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8 py-6 sm:py-8 md:py-12 overflow-x-hidden">
          <div className="flex items-center gap-2 text-sm text-gray-600 overflow-x-hidden">
            <Link href="/" className="hover:text-purple-600 transition-colors flex-shrink-0">
              Accueil
            </Link>
            <ChevronRight className="w-4 h-4 flex-shrink-0" />
            <Link href="/formations" className="hover:text-purple-600 transition-colors flex-shrink-0">
              Formations
            </Link>
            <ChevronRight className="w-4 h-4 flex-shrink-0 hidden sm:block" />
            <span className="text-gray-900 font-medium truncate min-w-0 hidden sm:inline">{training.title}</span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 overflow-x-hidden">
        {images.length > 0 && (
          <div className="mb-8">
            <div className="relative h-[300px] md:h-[400px] rounded-2xl overflow-hidden shadow-xl">
              <ImageCarousel images={images} />
              {isExpired && (
                <div className="absolute top-4 right-4 z-10">
                  <Badge className="bg-red-600 text-white border-2 border-white shadow-lg text-sm px-4 py-2">
                    EXPIRÉ
                  </Badge>
                </div>
              )}
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 overflow-x-hidden">
          {/* Left Column - Main Content */}
          <div className="lg:col-span-2 space-y-6 min-w-0">
            <Card className={`p-6 overflow-hidden ${isExpired ? "border-2 border-red-500" : ""}`}>
              <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2 mb-3">
                    <Badge variant="secondary" className="bg-purple-100 text-purple-700 text-xs sm:text-sm break-words max-w-full">
                      {labelObject[training.trainingCategory as keyof typeof labelObject] ||
                        training.trainingCategory ||
                        "Formation"}
                    </Badge>
                    {training.trainingSubCategory && (
                      <Badge variant="outline" className="bg-blue-50 text-blue-700 text-xs sm:text-sm break-words max-w-full">
                        {labelObject[training.trainingSubCategory as keyof typeof labelObject] || training.trainingSubCategory}
                      </Badge>
                    )}
                    {isExpired && images.length === 0 && (
                      <Badge className="bg-red-600 text-white border-2 border-white shadow-lg text-xs sm:text-sm">
                        EXPIRÉ
                      </Badge>
                    )}
                  </div>
                  <h1 className={`text-2xl sm:text-3xl font-bold mb-3 break-words ${isExpired ? "text-gray-500" : "text-gray-900"}`}>
                    {training.title}
                  </h1>
                  <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      <span>Publié {formatDateRelative(training.createdat)}</span>
                    </div>
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={() => handleFavorite(!isFavorite)}
                    className="hover:bg-red-50"
                  >
                    <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : ""}`} />
                  </Button>
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={handleShare}
                    className="hover:bg-blue-50 bg-transparent"
                  >
                    <Share2 className="w-5 h-5" />
                  </Button>
                </div>
              </div>
            </Card>

            {/* Informations supplémentaires */}
            <Card className="p-6 overflow-hidden">
              <h2 className="text-xl font-bold mb-6">Informations supplémentaires</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 overflow-hidden">
                {/* Niveau requis */}
                {requiredLevels.length > 0 && (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <GraduationCap className="w-5 h-5 text-gray-600" />
                      <h3 className="font-semibold text-gray-900">Niveau requis</h3>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {requiredLevels.map((level, idx) => (
                        <Badge key={idx} variant="outline" className="bg-blue-50 text-blue-700">
                          {labelObject[level as keyof typeof labelObject] || level}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}

                {/* Dates */}
                {(training.startDate || training.endDate) && (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <Calendar className="w-5 h-5 text-gray-600" />
                      <h3 className="font-semibold text-gray-900">Dates</h3>
                    </div>
                    <div className="text-sm text-gray-700">
                      {training.startDate && training.endDate ? (
                        <p>Du {new Date(training.startDate).toLocaleDateString("fr-FR")} au {new Date(training.endDate).toLocaleDateString("fr-FR")}</p>
                      ) : training.startDate ? (
                        <p>À partir du {new Date(training.startDate).toLocaleDateString("fr-FR")}</p>
                      ) : (
                        <p>Jusqu'au {new Date(training.endDate).toLocaleDateString("fr-FR")}</p>
                      )}
                    </div>
                  </div>
                )}

                {/* Financement */}
                {trainingFunding.length > 0 && (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <DollarSign className="w-5 h-5 text-gray-600" />
                      <h3 className="font-semibold text-gray-900">Financement</h3>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {trainingFunding.filter(f => f !== 'Indifferent').map((funding, idx) => (
                        <Badge key={idx} variant="outline" className="text-xs">
                          {labelObject[funding as keyof typeof labelObject] || funding}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}

                {/* Certification */}
                {certification.length > 0 && (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <Award className="w-5 h-5 text-gray-600" />
                      <h3 className="font-semibold text-gray-900">Certification</h3>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {certification.map((cert, idx) => (
                        <Badge key={idx} variant="outline" className="bg-purple-50 text-purple-700">
                          {labelObject[cert as keyof typeof labelObject] || cert}
                        </Badge>
                      ))}
                    </div>
                    {training.isQualiopiCertified === "true" && (
                      <div className="mt-2 p-2 bg-green-50 rounded-lg border border-green-200">
                        <div className="flex items-center gap-2">
                          <Award className="w-4 h-4 text-green-600" />
                          <span className="text-xs font-semibold text-green-800">Formation certifiée Qualiopi</span>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </Card>

            <Card className="p-6 overflow-hidden">
              <div className="flex items-center gap-2 mb-4">
                <BookOpen className="w-5 h-5 text-purple-600" />
                <h2 className="text-xl font-bold">Description</h2>
              </div>
              <div 
                className="prose prose-slate max-w-none text-gray-700 leading-relaxed prose-headings:text-gray-900 prose-h2:text-xl prose-h2:font-bold prose-h2:mt-6 prose-h2:mb-4 prose-p:mb-4 prose-ul:list-disc prose-ul:ml-6 prose-ul:mb-4 prose-li:mb-2 prose-strong:font-bold prose-strong:text-gray-900 prose-a:text-blue-600 prose-a:underline"
                dangerouslySetInnerHTML={{ __html: sanitizeHtml(training.description) }}
              />
            </Card>

            {training.descriptionprofil && (
              <Card className="p-6 overflow-hidden">
                <div className="flex items-center gap-2 mb-4">
                  <Target className="w-5 h-5 text-blue-600" />
                  <h2 className="text-xl font-bold">Profil de formation</h2>
                </div>
                <div 
                  className="prose prose-slate max-w-none text-gray-700 leading-relaxed prose-headings:text-gray-900 prose-h2:text-xl prose-h2:font-bold prose-h2:mt-6 prose-h2:mb-4 prose-p:mb-4 prose-ul:list-disc prose-ul:ml-6 prose-ul:mb-4 prose-li:mb-2 prose-strong:font-bold prose-strong:text-gray-900 prose-a:text-blue-600 prose-a:underline"
                  dangerouslySetInnerHTML={{ __html: sanitizeHtml(training.descriptionprofil) }}
                />
              </Card>
            )}

            {training.program && training.program !== '{}' && (
              <Card className="p-6 overflow-hidden">
                <div className="flex items-center gap-2 mb-4">
                  <FileText className="w-5 h-5 text-green-600" />
                  <h2 className="text-xl font-bold">Programme de formation</h2>
                </div>
                <div 
                  className="prose prose-slate max-w-none text-gray-700 leading-relaxed prose-headings:text-gray-900 prose-h2:text-xl prose-h2:font-bold prose-h2:mt-6 prose-h2:mb-4 prose-p:mb-4 prose-ul:list-disc prose-ul:ml-6 prose-ul:mb-4 prose-li:mb-2 prose-strong:font-bold prose-strong:text-gray-900 prose-a:text-blue-600 prose-a:underline"
                  dangerouslySetInnerHTML={{ __html: sanitizeHtml(training.program) }}
                />
              </Card>
            )}

            {/* Localisation - visible uniquement si publishadresse est autorisé */}
            {training.address && formatAddress(training.address) && companyData && (companyData.publishadresse === "true" || companyData.publishadresse === true || companyData.publishadresse === "1") && (
              <Card className="p-6 overflow-hidden">
                <div className="flex items-center gap-2 mb-4">
                  <MapPin className="w-5 h-5 text-red-600" />
                  <h2 className="text-xl font-bold">Localisation</h2>
                </div>
                <div className="space-y-4">
                  <div className="flex items-start gap-3">
                    <MapPin className="w-5 h-5 text-gray-400 mt-1" />
                    <div>
                      <p className="font-medium text-gray-900">{formatAddress(training.address)}</p>
                    </div>
                  </div>
                  {/* Carte interactive */}
                  <LocationMap 
                    address={training.address} 
                    title={training.title}
                  />
                </div>
              </Card>
            )}

            <CommentsSection announcementId={announcementId} />
          </div>

          {/* Right Column - Sidebar */}
          <div className="space-y-6 min-w-0">
            <div className="lg:sticky lg:top-24 space-y-6 min-w-0">
              <Card className="p-6 overflow-hidden">
                <h3 className="font-bold text-lg mb-4">Détails de la formation</h3>
                <div className="space-y-3">
                  {training.trainingType && (
                    <div className="flex items-start gap-2">
                      <div className="p-1.5 bg-purple-100 rounded-lg flex-shrink-0">
                        <GraduationCap className="w-4 h-4 text-purple-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-sm font-medium text-gray-600">Type de Formation</span>
                          <Badge variant="outline" className="text-xs bg-purple-50 text-purple-700 flex-shrink-0 max-w-full break-words">
                            {labelObject[training.trainingType as keyof typeof labelObject] || training.trainingType}
                          </Badge>
                        </div>
                      </div>
                    </div>
                  )}

                  {getFormattedDuration() && (
                    <div className="flex items-start gap-2">
                      <div className="p-1.5 bg-blue-100 rounded-lg flex-shrink-0">
                        <Clock className="w-4 h-4 text-blue-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-sm font-medium text-gray-600">Durée</span>
                          <span className="text-sm text-gray-700 text-right break-words">{getFormattedDuration()}</span>
                        </div>
                      </div>
                    </div>
                  )}

                  {trainingStyle.length > 0 && (
                    <div className="flex items-start gap-2">
                      <div className="p-1.5 bg-orange-100 rounded-lg flex-shrink-0">
                        <BookOpen className="w-4 h-4 text-orange-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-sm font-medium text-gray-600">Type d'enseignement</span>
                          <span className="text-sm text-gray-700 text-right break-words">
                            {trainingStyle.map(style => labelObject[style as keyof typeof labelObject] || style).join(' - ')}
                          </span>
                        </div>
                      </div>
                    </div>
                  )}

                  {trainingPublic.length > 0 && (
                    <div className="flex items-start gap-2">
                      <div className="p-1.5 bg-indigo-100 rounded-lg flex-shrink-0">
                        <Users className="w-4 h-4 text-indigo-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-sm font-medium text-gray-600">Public visé</span>
                          <span className="text-sm text-gray-700 text-right break-words">
                            {trainingPublic.includes('AllPublic') 
                              ? 'Tous publics' 
                              : trainingPublic.map(pub => labelObject[pub as keyof typeof labelObject] || pub).join(', ')}
                          </span>
                        </div>
                      </div>
                    </div>
                  )}

                  {trainingStyle.length > 0 && (
                    <div className="flex items-start gap-2">
                      <div className="p-1.5 bg-green-100 rounded-lg flex-shrink-0">
                        <CheckCircle2 className="w-4 h-4 text-green-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <span className="text-sm font-medium text-gray-600">Disponibilité</span>
                          <span className="text-sm text-gray-700 text-right break-words">En présentiel</span>
                        </div>
                      </div>
                    </div>
                  )}

                </div>
              </Card>

              <Card className="p-6 bg-gradient-to-br from-purple-50 to-blue-50 border-2 border-purple-200 overflow-hidden">
                <h3 className="font-bold text-lg mb-4">Intéressé par cette formation ?</h3>
                <div className="text-center mb-4">
                  <div className="text-sm text-gray-600 mb-1">Prix</div>
                  <div className="text-lg font-semibold text-purple-600">
                    {getFormattedPrice()}
                  </div>
                </div>
                <Button
                  className={`w-full text-white shadow-lg ${
                    isExpired
                      ? "bg-gray-400 cursor-not-allowed"
                      : "bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700"
                  }`}
                  size="lg"
                  disabled={isExpired}
                  onClick={handleRegisterClick}
                >
                  <ExternalLink className="w-5 h-5 mr-2" />
                  {isExpired ? "Formation expirée" : "S'inscrire maintenant"}
                </Button>
                {userId !== training?.userId && (training?.acceptMessages === true || training?.message === true) && (
                  <Button
                    variant="outline"
                    className="w-full mt-3 border-2 border-purple-500 text-purple-700 hover:bg-purple-50 bg-transparent"
                    size="lg"
                    onClick={handleContact}
                    disabled={isExpired || isContactingLoading}
                  >
                    {isContactingLoading ? (
                      "Chargement..."
                    ) : (
                      <>
                        <Mail className="w-5 h-5 mr-2" />
                        Contacter
                      </>
                    )}
                  </Button>
                )}
                {training.website && !isExpired && (
                  <a
                    href={training.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block text-center text-sm text-purple-600 hover:text-purple-700 mt-3"
                  >
                    Visiter le site web
                  </a>
                )}
              </Card>

              {documents.length > 0 && (
                <Card className="p-6 overflow-hidden">
                  <h3 className="font-bold text-lg mb-4">Voir le programme</h3>
                  <Button
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white"
                    size="lg"
                    onClick={handleDownloadDocuments}
                    disabled={loadingDocuments}
                  >
                    <FileText className="w-5 h-5 mr-2" />
                    {loadingDocuments ? 'Chargement...' : `Télécharger le(s) document(s) (${documents.length})`}
                  </Button>
                </Card>
              )}

              {companyData && (
                <PublisherCard
                  publisherName={getOrganizationName()}
                  announcementTitle={training.title}
                  announcementType="formation"
                  userId={training.userId}
                  photoUrl={getOrganizerPhoto()}
                  isProfessional={isProfessional}
                  activite={companyData.activite}
                  ville={companyData.ville}
                  pays={companyData.pays}
                  telephone={""}
                  email={""}
                  adresse={companyData.adresse}
                  codePostal={companyData.codePostal}
                  hasPremiumSubscription={publisherHasSubscription}
                  currentUserIsPro={currentUserIsPro}
                  publishadresse={companyData.publishadresse}
                />
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Section Formations similaires */}
      {relatedTrainings.length > 0 && (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 bg-gradient-to-b from-gray-50 to-white">
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Autres formations</h2>
            <p className="text-gray-600">Découvrez d'autres formations qui pourraient vous intéresser</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {relatedTrainings.map((relatedTraining) => {
              const isExpired = relatedTraining.endDate ? new Date(relatedTraining.endDate) < new Date() : false
              
              const getOrganizationName = () => {
                if (!relatedTraining.companyData) return "Organisation"
                if (relatedTraining.companyData.profiletype === "professionnel") {
                  return relatedTraining.companyData.nomsociete || "Organisation"
                }
                return relatedTraining.companyData.pseudo || "Particulier"
              }
              
              const getOrganizerPhoto = () => {
                const companyData = relatedTraining.companyData
                if (!companyData || !companyData.photoprofilurl) return null
                if (companyData.photoprofilurl.startsWith("http")) {
                  return companyData.photoprofilurl
                }
                return `${config.API_URL}${companyData.photoprofilurl}`
              }
              
              const isProfessional = relatedTraining.companyData?.profiletype === "professionnel"
              const organizationName = getOrganizationName()
              
              const getTimeAgo = (date: string) => {
                const now = new Date()
                const created = new Date(date)
                const diffInMs = now.getTime() - created.getTime()
                const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
                const diffInMonths = Math.floor(diffInDays / 30)
                if (diffInMonths > 0) return `Il y a ${diffInMonths} mois`
                if (diffInDays > 0) return `Il y a ${diffInDays} jour${diffInDays > 1 ? "s" : ""}`
                return "Aujourd'hui"
              }
              
              const timeAgo = getTimeAgo(relatedTraining.createdat)
              
              const getCleanDescription = () => {
                if (!relatedTraining.description) return ""
                const cleanText = relatedTraining.description.replace(/<[^>]*>/g, ' ')
                const normalized = cleanText.replace(/\\s+/g, ' ').trim()
                return normalized
              }
              
              const getTrainingPublicArray = () => {
                if (!relatedTraining.trainingPublic) return []
                try {
                  const cleaned = relatedTraining.trainingPublic.replace(/[{}]/g, '')
                  const publics = cleaned.split(',').map((p: string) => p.trim()).filter(Boolean)
                  if (publics.includes('AllPublic')) {
                    return ['Tout public']
                  }
                  const publicLabels: { [key: string]: string } = {
                    'Employed': 'Salarié',
                    'JobSeeker': "Demandeur d'emploi",
                    'Company': 'Entreprise',
                    'Student': 'Étudiant',
                    'Retraining': 'Reconversion'
                  }
                  const labels = publics.map((p: string) => publicLabels[p] || p)
                  return labels.length > 0 ? labels : []
                } catch {
                  return []
                }
              }
              
              const getFormattedDuration = () => {
                if (!relatedTraining.durationInH) return null
                const hours = parseFloat(relatedTraining.durationInH)
                if (isNaN(hours) || hours === 0) return null
                return `${hours}h`
              }
              
              const getFormattedLocation = () => {
                if (relatedTraining.address) {
                  return formatAddress(relatedTraining.address)
                }
                if (relatedTraining.location) {
                  return formatAddress(relatedTraining.location)
                }
                return null
              }
              
              const getTrainingType = () => {
                if (!relatedTraining.trainingType) return null
                const typeLabels: { [key: string]: string } = {
                  'ApprenticeshipTraining': 'Formation en alternance',
                  'ContinuingEducation': 'Formation continue',
                  'DegreeProgram': 'Formation diplômante',
                  'ProfessionalTraining': 'Formation professionnelle',
                  'Certification': 'Certification',
                  'Workshop': 'Atelier',
                  'Seminar': 'Séminaire',
                  'BlendedLearning': 'Formation hybride (BlendedLearning)'
                }
                return typeLabels[relatedTraining.trainingType] || `${relatedTraining.trainingType}`
              }
              
              const trainingTypeLabel = getTrainingType()
              const relatedDuration = getFormattedDuration()
              const relatedAddress = getFormattedLocation()
              const relatedPrice = relatedTraining.price && Number.parseFloat(relatedTraining.price) > 0
                ? `${relatedTraining.price}€`
                : "Gratuit"
              
              return (
                <Link
                  key={relatedTraining.id}
                  href={`/announcements/trainings/${relatedTraining.id}`}
                >
                  <Card className={`h-full hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer ${
                    isExpired ? "opacity-75 border-2 border-red-500" : ""
                  }`}>
                    {/* Logo and badges */}
                    <div className="p-4 pb-0 relative">
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex-shrink-0">
                          {getOrganizerPhoto() ? (
                            <div
                              className={`w-16 h-16 rounded-lg overflow-hidden bg-gray-100 flex items-center justify-center ${
                                isExpired ? "grayscale brightness-75" : ""
                              }`}
                            >
                              <img
                                src={getOrganizerPhoto()!}
                                alt={organizationName}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  const target = e.target as HTMLImageElement
                                  target.style.display = "none"
                                  target.parentElement!.innerHTML = `
                                    <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-purple-100 to-purple-50">
                                      <svg class="w-8 h-8 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                                      </svg>
                                    </div>
                                  `
                                }}
                              />
                            </div>
                          ) : (
                            <div
                              className={`w-16 h-16 rounded-lg bg-gradient-to-br from-purple-100 to-purple-50 flex items-center justify-center ${
                                isExpired ? "grayscale brightness-75" : ""
                              }`}
                            >
                              <GraduationCap className="w-8 h-8 text-purple-400" />
                            </div>
                          )}
                        </div>
                        <div className="flex items-center gap-2">
                          {relatedTraining.trainingLevel && (
                            <Badge variant="secondary" className="bg-purple-100 text-purple-700 border-purple-200 text-xs">
                              {relatedTraining.trainingLevel}
                            </Badge>
                          )}
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100" onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}>
                            <Heart className="w-4 h-4 text-gray-400" />
                          </Button>
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100" onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}>
                            <Share2 className="w-4 h-4 text-gray-400" />
                          </Button>
                        </div>
                      </div>

                      {/* Organization name with Pro/Particulier badge */}
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-sm font-semibold text-gray-900">{organizationName}</span>
                        <Badge variant="outline" className={`text-xs ${isProfessional ? 'bg-blue-50 text-blue-700 border-blue-200' : 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                          {isProfessional ? 'Pro' : 'Particulier'}
                        </Badge>
                      </div>

                      {/* Title */}
                      <h3
                        className={`text-lg font-bold mb-3 line-clamp-2 group-hover:text-purple-600 transition-colors ${
                          isExpired ? "text-gray-500" : "text-gray-900"
                        }`}
                      >
                        {relatedTraining.title}
                      </h3>

                      {/* Description */}
                      <p className="text-sm text-gray-600 line-clamp-2 mb-4 min-h-[2.5rem] leading-relaxed">{getCleanDescription()}</p>

                      {/* Key info grid */}
                      <div className="space-y-3 text-sm mb-4">
                        {getFormattedDuration() && (
                          <div className="flex items-center gap-1 text-gray-600">
                            <Clock className="w-4 h-4 flex-shrink-0" />
                            <span className="truncate">{getFormattedDuration()}</span>
                          </div>
                        )}
                        {getFormattedLocation() && (
                          <div className="flex items-center gap-1 text-gray-600">
                            <MapPin className="w-4 h-4 flex-shrink-0" />
                            <span className="truncate">{getFormattedLocation()}</span>
                          </div>
                        )}
                        {getTrainingPublicArray().length > 0 && (
                          <div className="flex items-start gap-1.5">
                            <User className="w-4 h-4 flex-shrink-0 mt-1 text-gray-600" />
                            <div className="flex flex-wrap gap-1.5">
                              {getTrainingPublicArray().map((publicLabel: string, index: number) => (
                                <Badge 
                                  key={index} 
                                  variant="outline" 
                                  className="text-xs bg-blue-50 text-blue-700 border-blue-200 px-2 py-0.5"
                                >
                                  {publicLabel}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Type de formation */}
                      {trainingTypeLabel && (
                        <div className="mb-4">
                          <Badge variant="outline" className="text-xs bg-purple-50 text-purple-700 border-purple-200 truncate max-w-full">
                            <span className="truncate">{trainingTypeLabel}</span>
                          </Badge>
                        </div>
                      )}
                    </div>

                    {/* CTA */}
                    <div className="px-4 pb-4 pt-2 border-t">
                      <div className="flex items-center justify-between">
                        <p className="text-xs text-gray-500">
                          {timeAgo}
                        </p>
                        <Button
                          className={isExpired ? "bg-gray-400 cursor-not-allowed" : "bg-purple-500 hover:bg-purple-600 text-white"}
                          disabled={isExpired}
                        >
                          {isExpired ? "Expiré" : "Voir la formation"}
                        </Button>
                      </div>
                    </div>
                  </Card>
                </Link>
              )
            })}
          </div>
        </div>
      )}

      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={training?.title || ""}
        url={`/announcements/trainings/${announcementId}`}
        description={training?.description}
      />

      <Dialog open={showRegistrationDialog} onOpenChange={setShowRegistrationDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Intéressé par cette formation ?</DialogTitle>
            <DialogDescription>
              Confirmez votre inscription pour cette formation. Nous enverrons votre candidature à l'organisateur.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4 py-4">
            {training?.trainingPrice && (
              <div className="text-center">
                <p className="text-sm text-gray-600 mb-2">Prix</p>
                <p className="text-3xl font-bold text-purple-600">
                  {training.trainingPrice} €
                </p>
                <p className="text-xs text-gray-500 mt-1">NET par personne par heure</p>
              </div>
            )}

            {currentUserIsPro && (
              <div className="space-y-3">
                <div className="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    id="multipleParticipants"
                    checked={hasMultipleParticipants}
                    onChange={(e) => {
                      setHasMultipleParticipants(e.target.checked)
                      if (!e.target.checked) {
                        setParticipantCount(1)
                      }
                    }}
                    className="w-4 h-4 text-purple-600 border-gray-300 rounded focus:ring-purple-500"
                  />
                  <label htmlFor="multipleParticipants" className="text-sm font-medium text-gray-700">
                    Plusieurs personnes participeront à cette formation
                  </label>
                </div>

                {hasMultipleParticipants && (
                  <div className="space-y-2">
                    <label htmlFor="participantCount" className="text-sm font-medium text-gray-700">
                      Nombre de participants
                    </label>
                    <input
                      type="number"
                      id="participantCount"
                      min="2"
                      max="100"
                      value={participantCount}
                      onChange={(e) => setParticipantCount(Math.max(2, parseInt(e.target.value) || 2))}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                      placeholder="Nombre de participants"
                    />
                  </div>
                )}
              </div>
            )}
          </div>

          <DialogFooter className="flex-col sm:flex-row gap-2">
            <Button
              variant="outline"
              onClick={() => setShowRegistrationDialog(false)}
              disabled={isRegistering}
              className="w-full sm:w-auto"
            >
              Annuler
            </Button>
            <Button
              onClick={handleConfirmRegistration}
              disabled={isRegistering}
              className="w-full sm:w-auto bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white"
            >
              {isRegistering ? (
                <>
                  <span className="animate-spin mr-2">⏳</span>
                  Inscription en cours...
                </>
              ) : (
                <>
                  <ExternalLink className="w-4 h-4 mr-2" />
                  Confirmer l'inscription
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Dialog de résultat d'inscription */}
      <Dialog open={registrationResult !== null} onOpenChange={() => setRegistrationResult(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className={registrationResult?.success ? "text-green-600" : "text-red-600"}>
              {registrationResult?.success ? "✅ Inscription réussie !" : "❌ Erreur d'inscription"}
            </DialogTitle>
            <DialogDescription>
              {registrationResult?.message}
            </DialogDescription>
          </DialogHeader>
          
          {registrationResult?.success && (
            <div className="py-4 text-center bg-green-50 rounded-lg border border-green-200">
              <div className="text-6xl mb-3">🎉</div>
              <p className="text-sm text-green-800 font-medium">
                Votre candidature a été envoyée avec succès !
              </p>
              <p className="text-xs text-green-600 mt-2">
                L'organisateur vous contactera prochainement.
              </p>
            </div>
          )}

          {!registrationResult?.success && (
            <div className="py-4 text-center bg-red-50 rounded-lg border border-red-200">
              <div className="text-6xl mb-3">😞</div>
              <p className="text-sm text-red-800 font-medium">
                Une erreur s'est produite lors de l'inscription.
              </p>
              <p className="text-xs text-red-600 mt-2">
                Veuillez réessayer plus tard ou contacter le support.
              </p>
            </div>
          )}

          <DialogFooter>
            <Button
              onClick={() => setRegistrationResult(null)}
              className={registrationResult?.success 
                ? "w-full bg-green-600 hover:bg-green-700 text-white" 
                : "w-full bg-red-600 hover:bg-red-700 text-white"
              }
            >
              {registrationResult?.success ? "Parfait !" : "Fermer"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}