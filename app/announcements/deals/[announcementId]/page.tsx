"use client"

import { use, useEffect, useState, useCallback } from "react"
import { notFound } from "next/navigation"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { fetchDealImages, fetchCommentsByAnnouncementId, fetchPublisherData, toggleFavorite, checkUserSubscription } from "@/lib/api"
import { config } from "@/lib/config"
import axios from "axios"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import {
  Heart,
  Share2,
  MapPin,
  Calendar,
  ExternalLink,
  Tag,
  Globe,
  Truck,
  CreditCard,
  Building,
  Clock,
  Store,
  AlertCircle,
  User,
  Briefcase,
  ChevronLeft,
  ChevronRight,
   Lock,
  Mail,
  Phone,
  MessageCircle,
} from "lucide-react"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import labelObject from "@/lib/constants/label-object"
import Image from "next/image"
import { formatDateRelative, cn } from "@/lib/utils"
import Link from "next/link"
import { CommentsSection } from "@/components/comments/comments-section"
import { startConversation } from "@/lib/api"
import { useRouter } from "next/navigation"
import { ShareModal } from "@/components/share-modal"
import { PublisherCard } from "@/components/publisher-card"
import { LocationMap } from "@/components/map/location-map"
// import { config } from "@/lib/config"
import FeatureGuard from "@/components/subscription/feature-guard"

async function updateViewCount(announcementId: string) {
  try {
    console.log("[v0] Updating view count for announcement:", announcementId)
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

function getImageUrl(imagePath: string | undefined | null): string {
  if (!imagePath) return ''
  
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  let cleanPath = imagePath
  if (!cleanPath.startsWith('/')) {
    cleanPath = '/' + cleanPath
  }
  
  if (cleanPath.includes("/ads/")) {
    cleanPath = cleanPath.replace("/ads/", "/annonces/")
  }
  
  return `${config.API_URL}${cleanPath}`
}

function getTimeAgo(date: string): string {
  const now = new Date()
  const past = new Date(date)
  const diffInHours = Math.floor((now.getTime() - past.getTime()) / (1000 * 60 * 60))

  if (diffInHours < 1) return "Il y a quelques minutes"
  if (diffInHours < 24) return `Il y a ${diffInHours} heure${diffInHours > 1 ? "s" : ""}`
  const days = Math.floor(diffInHours / 24)
  if (days < 7) return `Il y a ${days} jour${days > 1 ? "s" : ""}`
  const weeks = Math.floor(days / 7)
  if (weeks < 4) return `Il y a ${weeks} semaine${weeks > 1 ? "s" : ""}`
  const months = Math.floor(days / 30)
  return `Il y a ${months} mois`
}

function formatAddress(address: any): string {
  if (!address) return ""

  // If address is a string, try to parse it
  if (typeof address === "string") {
    try {
      address = JSON.parse(address)
    } catch {
      // If parsing fails, return the string as-is
      return address
    }
  }

  // Build address string from object - handle both field name formats
  const parts = []

  // Try new format first (line1, line2, etc.)
  if (address.line1) parts.push(address.line1)
  if (address.line2) parts.push(address.line2)
  if (address.line3) parts.push(address.line3)

  // Try old format (adresse)
  if (address.adresse) parts.push(address.adresse)

  // City
  if (address.city) parts.push(address.city)
  if (address.ville) parts.push(address.ville)

  // Postal code
  if (address.zipcode) parts.push(address.zipcode)
  if (address.postalCode) parts.push(address.postalCode)
  if (address.codepostal) parts.push(address.codepostal)

  // Country (only if not France)
  if (address.country && address.country !== "France") parts.push(address.country)
  if (address.pays && address.pays !== "France") parts.push(address.pays)

  return parts.filter(Boolean).join(", ")
}

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

function parseBrand(brand: any): string {
  if (!brand) return ""
  if (typeof brand === "string") {
    // Parser les formats PostgreSQL: ["value"] ou {"value"} ou {value}
    return brand.replace(/[\[\]{}"]/g, "").trim()
  }
  if (Array.isArray(brand)) {
    return brand.join(", ")
  }
  return String(brand)
}

function ImageCarousel({ images, announcementDate }: { images: string[]; announcementDate: string }) {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [isFullscreen, setIsFullscreen] = useState(false)

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-gray-100 to-gray-200">
        <div className="text-center">
          <Tag className="w-20 h-20 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-500 font-medium">Aucune image disponible</p>
        </div>
      </div>
    )
  }

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % images.length)
  }

  const prevImage = () => {
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length)
  }

  const toggleFullscreen = () => {
    setIsFullscreen(!isFullscreen)
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
    <>
      <div className="relative w-full h-full group bg-black">
        <Image
          src={getImageUrl(images[currentIndex])}
          alt="Deal image"
          fill
          className="object-contain"
          onError={(e) => {
            const target = e.target as HTMLImageElement
            target.style.display = "none"
          }}
        />
        
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

        {images.length > 1 && (
          <>
            <button
              onClick={prevImage}
              className="absolute left-4 top-1/2 -translate-y-1/2 bg-white/90 hover:bg-white text-gray-900 p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all shadow-lg"
              aria-label="Image précédente"
            >
              <ChevronLeft className="w-6 h-6" />
            </button>
            <button
              onClick={nextImage}
              className="absolute right-4 top-1/2 -translate-y-1/2 bg-white/90 hover:bg-white text-gray-900 p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all shadow-lg"
              aria-label="Image suivante"
            >
              <ChevronRight className="w-6 h-6" />
            </button>
            <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2 bg-black/50 px-4 py-2 rounded-full">
              {images.map((_, idx) => (
                <button
                  key={idx}
                  onClick={() => setCurrentIndex(idx)}
                  className={`w-2 h-2 rounded-full transition-all ${
                    idx === currentIndex ? "bg-white w-8" : "bg-white/50 hover:bg-white/75"
                  }`}
                  aria-label={`Aller à l'image ${idx + 1}`}
                />
              ))}
            </div>
            <div className="absolute top-6 right-6 bg-black/70 text-white px-3 py-1 rounded-full text-sm font-medium">
              {currentIndex + 1} / {images.length}
            </div>
          </>
        )}
      </div>

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
              alt="Deal image fullscreen"
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
    </>
  )
}

export default function DealPage({ params }: { params: Promise<{ announcementId: string }> }) {
  const resolvedParams = use(params)
  const announcementId = resolvedParams.announcementId

  const [deal, setDeal] = useState<any>(null)
  const [images, setImages] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [isFavorite, setIsFavorite] = useState(false)
  const [companyData, setCompanyData] = useState<any>(null)
  const [comments, setComments] = useState<any[]>([])
  const [showShareModal, setShowShareModal] = useState(false)
  const [relatedDeals, setRelatedDeals] = useState<any[]>([])
  const [currentUserData, setCurrentUserData] = useState<any>(null)
  const [publisherHasSubscription, setPublisherHasSubscription] = useState(false)
  const [isContactingLoading, setIsContactingLoading] = useState(false)

  // const announcementId = params.announcementId
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") || "" : ""
  const currentUserIsPro = currentUserData?.companyData?.profiletype === "professionnel"

  const isExpired = deal?.endDate ? new Date(deal.endDate) < new Date() : false
  const isUpcoming = deal?.startDate ? new Date(deal.startDate) > new Date() : false

  const handleFavorite = async (newFavoriteState: boolean) => {
    const result = await toggleFavorite(userId, deal?.id || "", newFavoriteState)
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

    // Rediriger vers la messagerie avec l'ID de l'annonce
    // La conversation sera créée lors de l'envoi du premier message
    router.push(`/messages?action=new_conversation&announcementId=${announcementId}&publisherId=${deal.userId}`)
  }

  const fetchCommentsWithUsernames = useCallback(async () => {
    const commentsResult = await fetchCommentsByAnnouncementId(announcementId)
    if (commentsResult.success) {
      setComments(commentsResult.comments)
    }
  }, [announcementId])

  const router = useRouter()

  useEffect(() => {
    if (!announcementId) return

    const fetchDealData = async () => {
      try {
        const fetchedDeal = await fetchAnnouncementDetail(announcementId)
        if (!fetchedDeal) {
          notFound()
        }
        setDeal(fetchedDeal)
        setIsFavorite(fetchedDeal.isFavorite || false)

        await updateViewCount(announcementId)

        const imagesResult = await fetchDealImages(announcementId)
        if (imagesResult.success) {
          setImages(imagesResult.images)
        }

        await fetchCommentsWithUsernames()
      } catch (error) {
        console.error("Error loading deal data:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchDealData()
  }, [announcementId, fetchCommentsWithUsernames])

  useEffect(() => {
    if (deal?.userId) {
      const loadPublisherData = async () => {
        const result = await fetchPublisherData(deal.userId)
        if (result.success) {
          setCompanyData(result.userData?.companyData)
          const hasSubscription = await checkUserSubscription(deal.userId)
          setPublisherHasSubscription(hasSubscription)
        }
      }
      loadPublisherData()
    }
  }, [deal?.userId])

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

  // Charger les bons plans similaires
  useEffect(() => {
    if (deal) {
      const loadRelatedDeals = async () => {
        try {
          console.log("🔍 Chargement des bons plans similaires...")
          const response = await axios.post(
            "https://api.myreklam.fr/Ads.php",
            {
              Method: "readAdsByCriteria",
              category: "bons_plans",
            },
            {
              headers: {
                "Content-Type": "application/x-www-form-urlencoded",
              },
            }
          )
          
          console.log("📦 Réponse API:", response.data)
          
          if (response.data.status === "success" && response.data.ads) {
            // Filtrer pour exclure le bon plan actuel et prendre les 4 derniers
            const filtered = response.data.ads
              .filter((d: any) => d.id !== announcementId)
              .slice(-4)
              .reverse() // Pour avoir les plus récents en premier
            
            console.log("✅ Bons plans filtrés:", filtered)
            
            // Charger les images pour chaque bon plan
            const dealsWithImages = await Promise.all(
              filtered.map(async (dealItem: any) => {
                try {
                  const imageResult = await fetchDealImages(dealItem.id)
                  const images = imageResult.success ? imageResult.images : []
                  return { ...dealItem, images }
                } catch (error) {
                  console.error(`Erreur chargement images pour ${dealItem.id}:`, error)
                  return { ...dealItem, images: [] }
                }
              })
            )
            
            console.log("✅ Bons plans avec images:", dealsWithImages)
            setRelatedDeals(dealsWithImages)
          } else {
            console.log("❌ Pas de données ou erreur:", response.data)
          }
        } catch (error) {
          console.error("❌ Error loading related deals:", error)
        }
      }
      loadRelatedDeals()
    }
  }, [deal, announcementId])

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-7xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8 py-4 sm:py-6 md:py-8">
          <div className="animate-pulse space-y-4 sm:space-y-6">
            <div className="h-8 bg-gray-200 rounded w-1/4"></div>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6 lg:gap-8">
              <div className="lg:col-span-2 space-y-6">
                <div className="h-[500px] bg-gray-200 rounded-2xl"></div>
                <div className="h-48 bg-gray-200 rounded-2xl"></div>
              </div>
              <div className="space-y-6">
                <div className="h-96 bg-gray-200 rounded-2xl"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!deal) {
    notFound()
  }

  const formattedAddress = formatAddress(deal.address)

  const getUserDisplayName = () => {
    if (!companyData) return "Utilisateur"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Professionnel"
    }
    return companyData.pseudo || "Particulier"
  }

  return (
    <div className="min-h-screen bg-gray-50 overflow-x-hidden">
      {/* Breadcrumb */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <Link href="/" className="hover:text-gray-900">
              Accueil
            </Link>
            <span>/</span>
            <Link href="/bons-plans" className="hover:text-gray-900">
              Bons plans
            </Link>
            <span>/</span>
            <span className="text-gray-900 font-medium truncate">{deal.title}</span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8 py-4 sm:py-6 md:py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6 lg:gap-8">
          {/* Left Column - Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Image Carousel */}
            <Card className="overflow-hidden border-0 shadow-lg">
              <div className="relative h-[400px] md:h-[500px] bg-black">
                <ImageCarousel images={images} announcementDate={deal.createdat} />

                {/* Status Badge Overlay */}
                {(isExpired || isUpcoming) && (
                  <div className="absolute top-6 left-6">
                    <Badge
                      variant={isExpired ? "destructive" : "secondary"}
                      className={isExpired ? "text-xl px-8 py-4 font-bold animate-pulse border-2 border-white" : "text-sm px-4 py-2 font-semibold"}
                    >
                      {isExpired ? (
                        <div className="flex flex-col items-center gap-1">
                          <div className="flex items-center gap-2">
                            <Clock className="w-6 h-6" />
                            <span>EXPIRÉ</span>
                          </div>
                          {deal.endDate && (
                            <span className="text-xs font-normal">depuis le {new Date(deal.endDate).toLocaleDateString("fr-FR")}</span>
                          )}
                        </div>
                      ) : (
                        "À venir"
                      )}
                    </Badge>
                  </div>
                )}
              </div>
            </Card>

            {/* Title and Quick Info */}
            <Card className="p-6 border-0 shadow-lg">
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-3">
                    <Badge variant="secondary" className="text-sm">
                      {labelObject[deal.dealCategory as keyof typeof labelObject] || deal.dealCategory}
                    </Badge>
                    {deal.subCategory && (
                      <Badge variant="outline" className="text-sm">
                        {labelObject[deal.subCategory as keyof typeof labelObject] || deal.subCategory}
                      </Badge>
                    )}
                    <Badge variant="outline" className="text-sm">
                      {labelObject[deal.dealType as keyof typeof labelObject] || deal.dealType}
                    </Badge>
                  </div>
                  <h1 className="text-3xl md:text-4xl font-bold text-gray-900 mb-3">{deal.title}</h1>
                  <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                      <Clock className="w-4 h-4" />
                      <span>Publié {formatDateRelative(deal.createdat)}</span>
                    </div>
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={() => handleFavorite(!isFavorite)}
                    className="rounded-full"
                  >
                    <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : ""}`} />
                  </Button>
                  <Button variant="outline" size="icon" onClick={handleShare} className="rounded-full bg-transparent">
                    <Share2 className="w-5 h-5" />
                  </Button>
                </div>
              </div>


              {deal.dealType === "free" && (
                <div className="bg-gradient-to-r from-blue-50 to-cyan-50 rounded-xl p-6 border-2 border-blue-200">
                  <div className="flex items-center justify-between flex-wrap gap-4">
                    <div>
                      <p className="text-sm text-gray-600 mb-1">Offre</p>
                      <span className="text-4xl font-bold text-blue-600">Gratuit</span>
                    </div>
                    {deal.website && (
                      <Button
                        asChild
                        size="lg"
                        className="bg-gradient-to-r from-blue-500 to-cyan-600 hover:from-blue-600 hover:to-cyan-700 text-white shadow-lg"
                      >
                        <a
                          href={deal.website}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center gap-2"
                        >
                          <ExternalLink className="w-5 h-5" />
                          Profiter de l'offre
                        </a>
                      </Button>
                    )}
                  </div>
                </div>
              )}
            </Card>

            {/* Deal Details */}
            <Card className="p-6 border-0 shadow-lg">
              <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
                <AlertCircle className="w-6 h-6 text-green-600" />
                Détails du bon plan
              </h2>
              <div className="grid md:grid-cols-2 gap-6">
                {/* Price */}
                {(deal.finalPrice !== undefined && deal.finalPrice !== null) && (
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center flex-shrink-0">
                      <CreditCard className="w-5 h-5 text-orange-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Prix</p>
                      <div className="flex items-baseline gap-2">
                        {parseFloat(deal.finalPrice) === 0 ? (
                          <span className="text-2xl font-bold text-green-600">Gratuit</span>
                        ) : (
                          <>
                            <span className="text-2xl font-bold text-orange-600">{parseFloat(deal.finalPrice).toFixed(2)}€</span>
                            {deal.initialPrice && parseFloat(deal.initialPrice) > parseFloat(deal.finalPrice) && (
                              <>
                                <span className="text-sm text-gray-400 line-through">{parseFloat(deal.initialPrice).toFixed(2)}€</span>
                                <Badge className="bg-green-600 text-white text-sm px-2 py-1">
                                  -{Math.round(((parseFloat(deal.initialPrice) - parseFloat(deal.finalPrice)) / parseFloat(deal.initialPrice)) * 100)}%
                                </Badge>
                              </>
                            )}
                          </>
                        )}
                      </div>
                    </div>
                  </div>
                )}

                {/* Availability */}
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
                    <Globe className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900 mb-1">Disponibilité</p>
                    <p className="text-gray-600">
                      {deal.isOnline ? "En ligne" : "En magasin"}
                      {deal.brand && (
                        <span> chez <span className="font-semibold text-gray-900">{parseBrand(deal.brand)}</span></span>
                      )}
                    </p>
                  </div>
                </div>

                {/* Delivery/Pickup */}
                {deal.isOnline && deal.dealDeliveryType !== "no_delivery" && (
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center flex-shrink-0">
                      <Truck className="w-5 h-5 text-purple-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Livraison</p>
                      <p className="text-gray-600">
                        {deal.dealDeliveryType === "free_delivery"
                          ? "Livraison gratuite"
                          : Number.parseFloat(deal.shippingCost) > 0
                            ? `${deal.shippingCost} €`
                            : "Livraison gratuite"}
                      </p>
                    </div>
                  </div>
                )}

                {!deal.isOnline && (deal.drive || deal.inStore || deal.isDelivery) && (
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center flex-shrink-0">
                      <Store className="w-5 h-5 text-purple-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Moyen de retrait</p>
                      <div className="flex flex-wrap gap-2">
                        {deal.drive && <Badge variant="secondary">Drive</Badge>}
                        {deal.inStore && <Badge variant="secondary">En magasin</Badge>}
                        {deal.isDelivery && <Badge variant="secondary">Livraison</Badge>}
                      </div>
                    </div>
                  </div>
                )}

                {/* Validity Period */}
                {deal.endDate && (
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                      <Calendar className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Période de validité</p>
                      <p className="text-gray-600">
                        Jusqu'au {new Date(deal.endDate).toLocaleDateString("fr-FR")}
                      </p>
                    </div>
                  </div>
                )}

                {!deal.startDate && !deal.endDate && (
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                      <Calendar className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Validité</p>
                      <p className="text-gray-600">Offre permanente</p>
                    </div>
                  </div>
                )}

                {/* Promo Code */}
                {deal.discountCode && (
                  <div className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center flex-shrink-0">
                      <CreditCard className="w-5 h-5 text-orange-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Code promo</p>
                      <div className="flex items-center gap-2">
                        <code className="bg-gray-100 px-3 py-1 rounded font-mono text-sm font-bold">
                          {deal.discountCode}
                        </code>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => {
                            navigator.clipboard.writeText(deal.discountCode)
                            toastSuccess("Code copié !")
                          }}
                        >
                          Copier
                        </Button>
                      </div>
                    </div>
                  </div>
                )}

                {/* Condition */}
                {deal.condition && (
                  <div className="flex items-start gap-3 md:col-span-2">
                    <div className="w-10 h-10 rounded-full bg-yellow-100 flex items-center justify-center flex-shrink-0">
                      <AlertCircle className="w-5 h-5 text-yellow-600" />
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 mb-1">Conditions</p>
                      <p className="text-gray-600">{deal.condition}</p>
                    </div>
                  </div>
                )}

                {/* Location - visible uniquement si publishadresse est autorisé */}
                {formattedAddress && companyData && (companyData.publishadresse === "true" || companyData.publishadresse === true || companyData.publishadresse === "1") && (
                  <div className="flex items-start gap-3 md:col-span-2">
                    <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                      <MapPin className="w-5 h-5 text-red-600" />
                    </div>
                    <div className="flex-1">
                      <p className="font-semibold text-gray-900 mb-1">Localisation</p>
                      <p className="text-gray-600 mb-4">{formattedAddress}</p>
                      {/* Carte interactive */}
                      <LocationMap 
                        address={deal.address} 
                        title={deal.title}
                        className="mt-4"
                      />
                    </div>
                  </div>
                )}
              </div>
            </Card>

            {/* Description */}
            <Card className="p-6 border-0 shadow-lg">
              <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                <Tag className="w-6 h-6 text-green-600" />
                Description
              </h2>
              <div 
                className="prose prose-slate max-w-none text-gray-700 leading-relaxed prose-headings:text-gray-900 prose-h2:text-xl prose-h2:font-bold prose-h2:mt-6 prose-h2:mb-4 prose-p:mb-4 prose-ul:list-disc prose-ul:ml-6 prose-ul:mb-4 prose-li:mb-2 prose-strong:font-bold prose-strong:text-gray-900 prose-a:text-blue-600 prose-a:underline hover:prose-a:text-blue-800 break-words overflow-wrap-anywhere"
                dangerouslySetInnerHTML={{ __html: sanitizeHtml(deal.description) }}
              />
            </Card>

            {/* Comments Section */}
            <CommentsSection announcementId={announcementId} />
          </div>

          {/* Right Column - Sidebar */}
          <div className="space-y-6">
            {/* Sticky Sidebar */}
            <div className="lg:sticky lg:top-8 space-y-6">
              {/* Quick Info Card */}
              <Card className="p-6 border-0 shadow-lg">
                <h3 className="font-bold text-lg mb-4 text-gray-900">Informations rapides</h3>
                <div className="space-y-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-600">Catégorie</span>
                    <Badge variant="secondary">
                      {labelObject[deal.dealCategory as keyof typeof labelObject] || deal.dealCategory}
                    </Badge>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-600">Type</span>
                    <Badge variant="outline">
                      {labelObject[deal.dealType as keyof typeof labelObject] || deal.dealType}
                    </Badge>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-600">Disponibilité</span>
                    <span className="font-medium text-gray-900">
                      {deal.isOnline ? "En ligne" : "En magasin"}
                      {deal.brand && (
                        <span> chez {parseBrand(deal.brand)}</span>
                      )}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-600">Publié</span>
                    <span className="font-medium text-gray-900">{formatDateRelative(deal.createdat)}</span>
                  </div>
                  {deal.endDate && (
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-gray-600">Expire</span>
                      <span className={`font-medium ${isExpired ? "text-red-600" : "text-gray-900"}`}>
                        {new Date(deal.endDate).toLocaleDateString("fr-FR")}
                      </span>
                    </div>
                  )}
                </div>
              </Card>

              {/* CTA Card */}
              {deal.website && (
                <Card className="p-6 border-0 shadow-lg bg-gradient-to-br from-green-50 to-emerald-50">
                  <h3 className="font-bold text-lg mb-4 text-gray-900">Profiter de l'offre</h3>
                  <Button
                    asChild
                    size="lg"
                    className="w-full bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white shadow-lg"
                  >
                    <a
                      href={deal.website}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center gap-2"
                    >
                      <ExternalLink className="w-5 h-5" />
                      Voir le bon plan
                    </a>
                  </Button>
                </Card>
              )}

              {/* Contact Button Card */}
              {userId !== deal?.userId && (deal?.acceptMessages === true || deal?.message === true) && (
                <Card className="p-6 border-0 shadow-lg">
                  <h3 className="font-bold text-lg mb-4 text-gray-900">Contacter</h3>
                  <FeatureGuard feature="messaging">
                    <Button
                      size="lg"
                      variant="outline"
                      className="w-full border-2 border-green-500 text-green-700 hover:bg-green-50"
                      onClick={handleContact}
                      disabled={isExpired}
                    >
                      <Mail className="w-5 h-5 mr-2" />
                      Contacter
                    </Button>
                  </FeatureGuard>
                </Card>
              )}

              {/* Organizer Card */}
              {companyData && (
                <PublisherCard
                  publisherName={getUserDisplayName()}
                  announcementTitle={deal.title}
                  announcementType="bon-plan"
                  userId={deal.userId}
                  photoUrl={companyData.photoprofilurl ? `${config.API_URL}${companyData.photoprofilurl}` : null}
                  isProfessional={companyData.profiletype === "professionnel"}
                  activite={companyData.activite}
                  ville={companyData.ville}
                  pays={companyData.pays}
                  telephone={""}
                  email={""}
                  adresse={companyData.adresse}
                  codePostal={companyData.codepostal}
                  hasPremiumSubscription={publisherHasSubscription}
                  currentUserIsPro={currentUserIsPro}
                  publishadresse={companyData.publishadresse}
                />
              )}
            </div>
          </div>
        </div>
      </div>
      {/* Section Bons Plans Similaires */}
      {relatedDeals.length > 0 && (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 bg-gradient-to-b from-gray-50 to-white">
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Autres bons plans</h2>
            <p className="text-gray-600">Découvrez d'autres offres qui pourraient vous intéresser</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {relatedDeals.map((relatedDeal) => {
              const relatedAddress = relatedDeal.address ? formatAddress(relatedDeal.address) : ""
              const relatedBrand = parseBrand(relatedDeal.brand)
              const isExpired = relatedDeal.endDate ? new Date(relatedDeal.endDate) < new Date() : false
              
              // Calcul du discount
              const calculateDiscount = () => {
                if (relatedDeal.initialPrice && relatedDeal.finalPrice) {
                  const initial = parseFloat(relatedDeal.initialPrice)
                  const final = parseFloat(relatedDeal.finalPrice)
                  if (initial > final) {
                    return Math.round(((initial - final) / initial) * 100)
                  }
                }
                if (relatedDeal.discountValue) {
                  return Math.round(parseFloat(relatedDeal.discountValue))
                }
                return 0
              }
              const discountPercentage = calculateDiscount()
              
              // User info
              const getUserDisplayName = () => {
                const companyData = relatedDeal.companyData
                if (!companyData) return "Utilisateur"
                if (companyData.profiletype === "professionnel") {
                  return companyData.nomsociete || "Entreprise"
                }
                return companyData.pseudo || "Particulier"
              }
              
              const getUserPhoto = () => {
                const companyData = relatedDeal.companyData
                if (!companyData || !companyData.photoprofilurl) return null
                return companyData.photoprofilurl
              }
              
              const isProfessional = relatedDeal.companyData?.profiletype === "professionnel"
              
              const finalPrice = relatedDeal.finalPrice ? parseFloat(relatedDeal.finalPrice) : null
              const initialPrice = relatedDeal.initialPrice ? parseFloat(relatedDeal.initialPrice) : null
              
              return (
                <Link
                  key={relatedDeal.id}
                  href={`/announcements/deals/${relatedDeal.id}`}
                  onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                >
                  <Card
                    className={cn(
                      "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group cursor-pointer border-2 flex flex-col",
                      isExpired
                        ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300"
                        : "hover:border-green-200 border-gray-200",
                    )}
                  >
                    {/* Image */}
                    <div className="relative h-56 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
                      {relatedDeal.images && relatedDeal.images.length > 0 && relatedDeal.images[0] ? (
                        <img
                          src={getImageUrl(relatedDeal.images[0])}
                          alt={relatedDeal.title}
                          className={cn(
                            "w-full h-full object-cover group-hover:scale-110 transition-transform duration-500",
                            isExpired && "grayscale brightness-90",
                          )}
                          onError={(e) => {
                            const target = e.target as HTMLImageElement
                            target.style.display = "none"
                          }}
                        />
                      ) : (
                        <div
                          className={cn(
                            "w-full h-full flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50",
                            isExpired && "grayscale brightness-90",
                          )}
                        >
                          <Tag className={cn("w-20 h-20 text-green-300", isExpired && "opacity-50")} />
                        </div>
                      )}

                      {/* Category tag */}
                      <div className="absolute top-3 left-3">
                        <Badge
                          className={cn(
                            "backdrop-blur-sm shadow-md border-0 px-3 py-1 flex items-center gap-1",
                            isExpired ? "bg-gray-200/95 text-gray-600" : "bg-white/95 text-gray-700",
                          )}
                        >
                          <Tag className="w-3 h-3" />
                          {labelObject[relatedDeal.dealCategory as keyof typeof labelObject] || relatedDeal.dealCategory}
                        </Badge>
                      </div>

                      {/* Discount badge or Expired badge */}
                      {isExpired ? (
                        <div className="absolute top-3 right-3">
                          <Badge className="bg-red-500 text-white shadow-xl text-lg font-bold px-5 py-3 border-2 border-white animate-pulse">
                            <div className="flex flex-col items-center gap-0.5">
                              <div className="flex items-center gap-1">
                                <Clock className="w-5 h-5" />
                                <span>EXPIRÉ</span>
                              </div>
                            </div>
                          </Badge>
                        </div>
                      ) : discountPercentage > 0 ? (
                        <div className="absolute top-3 right-3">
                          <Badge className="bg-gradient-to-r from-orange-500 to-red-500 text-white shadow-lg text-lg font-bold px-4 py-2 border-0">
                            -{discountPercentage}%
                          </Badge>
                        </div>
                      ) : null}

                      {isExpired && <div className="absolute inset-0 bg-black/10" />}
                    </div>

                    {/* Content */}
                    <div className="p-5 flex flex-col flex-1">
                      <h3
                        className={cn(
                          "font-bold text-lg mb-2 line-clamp-2 min-h-[3.5rem] group-hover:text-green-600 transition-colors",
                          isExpired && "text-gray-500",
                        )}
                      >
                        {relatedDeal.title}
                      </h3>

                      {/* Category breadcrumb */}
                      <div className="flex items-center gap-2 text-xs text-gray-600 mb-3">
                        <span>{labelObject[relatedDeal.dealCategory as keyof typeof labelObject] || relatedDeal.dealCategory}</span>
                        {relatedDeal.subCategory && (
                          <>
                            <span>•</span>
                            <span>{labelObject[relatedDeal.subCategory as keyof typeof labelObject] || relatedDeal.subCategory}</span>
                          </>
                        )}
                      </div>

                      {relatedDeal.description && (
                        <p 
                          className={cn("text-sm mb-4 line-clamp-2 min-h-[2.5rem]", isExpired ? "text-gray-400" : "text-gray-600")}
                        >
                          {relatedDeal.description.replace(/<[^>]*>/g, '').substring(0, 150)}...
                        </p>
                      )}

                      {/* Availability */}
                      <div className="flex items-center gap-2 text-xs text-gray-600 mb-3">
                        <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth={2}
                            d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 010 4 2 2 0 01-2 2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                          />
                        </svg>
                        <span className="line-clamp-1">
                          {relatedDeal.isOnline ? "En ligne" : "En magasin"}
                          {relatedBrand && (
                            <span>, disponible chez <span className="font-semibold text-gray-900">{relatedBrand}</span></span>
                          )}
                        </span>
                      </div>

                      {/* Location */}
                      {!relatedDeal.isOnline && relatedAddress && (
                        <div className="flex items-center gap-1 text-xs text-gray-500 mb-3">
                          <MapPin className="w-3 h-3" />
                          <span className="truncate">{relatedAddress}</span>
                        </div>
                      )}

                      {/* Price */}
                      <div className="flex items-baseline gap-2 mb-4">
                        {finalPrice !== null && finalPrice === 0 ? (
                          <Badge className="bg-green-600 text-white text-lg font-bold px-4 py-1">
                            Gratuit
                          </Badge>
                        ) : finalPrice ? (
                          <>
                            <span className={cn("text-2xl font-bold", isExpired ? "text-gray-400 line-through" : "text-orange-600")}>
                              {finalPrice.toFixed(2)}€
                            </span>
                            {initialPrice && initialPrice > finalPrice && (
                              <span className="text-sm text-gray-400 line-through">{initialPrice.toFixed(2)}€</span>
                            )}
                          </>
                        ) : null}
                      </div>

                      {/* Engagement and CTA */}
                      <div className="flex items-center justify-between pt-4 border-t mt-auto">
                        <div className="flex items-center gap-4">
                          <div className="flex items-center gap-1 text-gray-500">
                            <MessageCircle className="w-4 h-4" />
                            <span className="text-sm font-medium">0</span>
                          </div>
                          <button className="flex items-center justify-center hover:text-green-600 transition-colors">
                            <Share2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>

                      {/* User info */}
                      <div className="flex items-center justify-between mt-4 pt-4 border-t">
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center overflow-hidden">
                            {getUserPhoto() ? (
                              <img
                                src={getUserPhoto()!}
                                alt={getUserDisplayName()}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <User className="w-4 h-4 text-white" />
                            )}
                          </div>
                          <div className="flex flex-col gap-0.5">
                            <span className="text-sm font-medium text-gray-700 truncate max-w-[80px] sm:max-w-[100px]">{getUserDisplayName()}</span>
                            <Badge
                              variant="outline"
                              className={cn(
                                "text-xs px-1.5 py-0 h-4 w-fit",
                                isProfessional
                                  ? "bg-blue-50 text-blue-700 border-blue-200"
                                  : "bg-gray-50 text-gray-600 border-gray-200",
                              )}
                            >
                              {isProfessional ? "Pro" : "Particulier"}
                            </Badge>
                          </div>
                        </div>

                        <Button
                          size="sm"
                          className={cn(
                            "shadow-md font-semibold px-4",
                            isExpired
                              ? "bg-gray-400 hover:bg-gray-400 text-white cursor-not-allowed"
                              : "bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white",
                          )}
                          disabled={isExpired}
                          onClick={(e) => {
                            e.preventDefault()
                            if (!isExpired) {
                              window.location.href = `/announcements/deals/${relatedDeal.id}`
                            }
                          }}
                        >
                          {isExpired ? "Offre expirée" : "Voir le bon plan"}
                        </Button>
                      </div>

                      {/* Time */}
                      {relatedDeal.createdat && (
                        <div className="flex items-center gap-1 text-xs text-gray-500 mt-3 pt-3 border-t">
                          <Clock className="w-3 h-3" />
                          <span>{getTimeAgo(relatedDeal.createdat)}</span>
                        </div>
                      )}
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
        title={deal?.title || ""}
        url={`/announcements/deals/${announcementId}`}
        description={deal?.description}
      />
    </div>
  )
}
