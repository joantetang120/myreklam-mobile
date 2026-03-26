"use client"

import { use, useEffect, useState, useCallback } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import Link from "next/link"
import {
  MapPin,
  Clock,
  Heart,
  Share2,
  Mail,
  Phone,
  Calendar,
  Users,
  AlertCircle,
  Euro,
  Globe,
  ChevronRight,
  Home,
  User,
  Briefcase,
  CalendarDays,
  MapPinned,
  Ticket,
  Building,
  ExternalLink,
  ChevronLeft,
} from "lucide-react"
import Image from "next/image"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { fetchDealImages, toggleFavorite, fetchPublisherData, startConversation, checkUserSubscription } from "@/lib/api"
import axios from "axios"
import { CommentsSection } from "@/components/comments/comments-section"
import { ShareModal } from "@/components/share-modal"
import { ProfileLinkGuard } from "@/components/profile-link-guard"
import { PublisherCard } from "@/components/publisher-card"
import { LocationMap } from "@/components/map/location-map"
import FeatureGuard from "@/components/subscription/feature-guard"
import { labelObject } from "@/lib/constants/label-object"
import { config } from "@/lib/config"
import { participateEvent, checkParticipationStatus, unsubscribeFromEvent } from "@/lib/api"
import { formatDateRelative } from "@/lib/utils"
import { CalendarPopup } from "@/components/events/calendar-popup"

interface EventDetail {
  id: string
  title: string
  description: string
  category: string
  userId: string
  createdat: string
  endDate?: string
  eventDate?: string
  eventTime?: string
  eventLocation?: string
  eventCity?: string
  eventPrice?: string
  eventMaxAttendees?: string
  eventCurrentAttendees?: string
  eventCategory?: string
  eventAgenda?: string
  eventSpeakers?: string
  eventRequirements?: string
  eventSubCategory?: string
  eventType?: string
  eventFormat?: string
  reservationMode?: string
  address?: string
  startDate?: string
  startTime?: string
  endTime?: string
  price?: string
  website?: string
  nameOrganizator?: string
  isOrganizator?: boolean
  subCategory?: string
  formatEvent?: string
  formatevent?: string
  modereservation?: string
  eventDurationType?: string
  isOneDay?: boolean
  isSeveralDays?: boolean
  isAllDays?: boolean
  program?: string
  number_view?: number
  companyData?: {
    nomsociete?: string
    photoprofilurl?: string
    profiletype?: string
    activite?: string
    telephone?: string
    adresse?: string
    ville?: string
    codepostal?: string
    presentation?: string
  }
}

// Fonction pour construire correctement l'URL de l'image
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

const formatAddress = (addressData: any): string => {
  if (!addressData) return ""

  if (typeof addressData === "string") {
    try {
      const parsed = JSON.parse(addressData)
      addressData = parsed
    } catch {
      return addressData
    }
  }

  try {
    const parts = []
    if (addressData.line1 || addressData.adresse) parts.push(addressData.line1 || addressData.adresse)
    if (addressData.line2) parts.push(addressData.line2)
    if (addressData.line3) parts.push(addressData.line3)
    if (addressData.city || addressData.ville) parts.push(addressData.city || addressData.ville)
    if (addressData.zipcode || addressData.codepostal) parts.push(addressData.zipcode || addressData.codepostal)
    if (addressData.country || addressData.pays && addressData.country !== "France") {
      parts.push(addressData.country || addressData.pays)
    }

    return parts.filter(Boolean).join(", ")
  } catch (error) {
    console.error("Error formatting address:", error)
    return ""
  }
}

const formatEventTypeLabel = (eventType: string) => {
  return (labelObject as any)[eventType] || eventType
}

const formatSubCategoryLabel = (subCategory: string) => {
  return (labelObject as any)[subCategory] || subCategory
}

function sanitizeHtml(html: string): string {
  if (!html) return ""
  return html
    .replace(/style="[^"]*"/g, '')
    .replace(/class="[^"]*"/g, '')
    .trim()
}

// Composant pour les détails de l'événement dans la sidebar
const EventDetailsSidebar = ({ event }: { event: EventDetail }) => {
  const eventFeatures = [
    // Disponibilité (présentiel/en ligne/hybride)
    (event.formatevent || event.formatEvent || event.eventFormat) && {
      icon: "globe",
      title: "Disponibilité",
      description: (event.formatevent || event.formatEvent || event.eventFormat) === "in_person" 
        ? "En présentiel" 
        : (event.formatevent || event.formatEvent || event.eventFormat) === "online" 
          ? "En ligne" 
          : "Hybride",
    },

    // Organisateur
    event.nameOrganizator && {
      icon: "building",
      title: "Organisateur",
      description: event.nameOrganizator,
    },

    // Réservation
    (event.modereservation || event.reservationMode) && {
      icon: "ticket",
      title: "Réservation",
      description: event.modereservation || event.reservationMode,
    },

    // Date
    (event.eventDurationType === "permanent" || event.isAllDays) ? {
      icon: "calendar-days",
      title: "Date",
      description: "Événement permanent",
      badge: true,
    } : event.startDate && {
      icon: "calendar-days",
      title: "Date",
      description: (() => {
        try {
          if (event.startDate && event.endDate && event.startDate !== event.endDate) {
            return `Du ${new Date(event.startDate).toLocaleDateString("fr-FR")} au ${new Date(event.endDate).toLocaleDateString("fr-FR")}`
          }
          if (event.startDate) {
            return new Date(event.startDate).toLocaleDateString("fr-FR", {
              weekday: "long",
              day: "numeric",
              month: "long",
              year: "numeric",
            })
          }
          return "Date à définir"
        } catch (error) {
          return "Date à définir"
        }
      })(),
    },

    // Horaires
    (event.startTime || event.endTime) && {
      icon: "clock",
      title: "Horaires",
      description: `De ${event.startTime?.substring(0, 5) || "00:00"} à ${event.endTime?.substring(0, 5) || "23:59"}`,
    },

    // Nombre de vues
    event.number_view && event.number_view > 0 && {
      icon: "users",
      title: "Vues",
      description: `${event.number_view} vue${event.number_view > 1 ? 's' : ''}`,
    },
  ].filter(Boolean);

  return (
    <div className="border border-gray-200 p-6 rounded-none">
      <h2 className="text-2xl font-bold mb-6">Détails de l'événement</h2>
      <EventFeatureList features={eventFeatures} />
    </div>
  );
};

// Composant pour afficher la liste des caractéristiques
const EventFeatureList = ({ features }: { features: any[] }) => {
  const getIconComponent = (iconName: string) => {
    const iconMap: Record<string, any> = {
      calendar: Calendar,
      ticket: Ticket,
      globe: Globe,
      building: Building,
      clock: Clock,
      "euro-sign": Euro,
      "calendar-days": CalendarDays,
      users: Users,
    }
    return iconMap[iconName] || Calendar
  }

  const getIconColors = (iconName: string) => {
    const colorMap: Record<string, { bg: string; text: string }> = {
      calendar: { bg: "bg-green-100", text: "text-green-600" },
      ticket: { bg: "bg-green-100", text: "text-green-600" },
      globe: { bg: "bg-blue-100", text: "text-blue-600" },
      building: { bg: "bg-green-100", text: "text-green-600" },
      clock: { bg: "bg-orange-100", text: "text-orange-600" },
      "euro-sign": { bg: "bg-green-100", text: "text-green-600" },
      "calendar-days": { bg: "bg-purple-100", text: "text-purple-600" },
      users: { bg: "bg-purple-100", text: "text-purple-600" },
    }
    return colorMap[iconName] || { bg: "bg-green-100", text: "text-green-600" }
  }

  return (
    <div className="space-y-4">
      {features.map((feature, index) => {
        const IconComponent = getIconComponent(feature.icon)
        const colors = getIconColors(feature.icon)
        
        return (
          <div key={index} className="flex items-start gap-3">
            <div className={`w-10 h-10 rounded-full ${colors.bg} flex items-center justify-center flex-shrink-0`}>
              <IconComponent className={`w-5 h-5 ${colors.text}`} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 mb-1">{feature.title}</p>
              {feature.badge ? (
                <Badge className="bg-blue-100 text-blue-700 border-blue-200">
                  {feature.description}
                </Badge>
              ) : (
                <p className={`text-sm ${feature.color || "text-gray-700"} ${feature.bold ? "font-bold" : ""}`}>
                  {feature.description}
                </p>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// Composant pour la carte d'action (participation)
const EventActionCard = ({
  website,
  onParticipate,
  isParticipating,
  isExpired,
  eventPrice = 0,
  priceType = null,
  onContact,
  isContactingLoading,
  showContactButton = true,
  hasParticipated = false,
}: {
  website?: string
  onParticipate: () => void
  isParticipating: boolean
  isExpired: boolean
  eventPrice?: number
  priceType?: string | null
  onContact: () => void
  isContactingLoading: boolean
  showContactButton?: boolean
  hasParticipated?: boolean
}) => {
  // Déterminer l'affichage du prix basé sur priceType
  const getPriceDisplay = () => {
    // Normaliser priceType en string pour la comparaison
    const normalizedPriceType = priceType ? String(priceType) : null
    
    // Règle métier:
    // - priceType = "1" ET price > 0 → Afficher le prix
    // - priceType = "1" ET price = 0 → "Non précisé"
    // - priceType = "2" ou "0" → "Gratuit"
    // - priceType = null/undefined → Rétrocompatibilité (si price > 0 → afficher prix, sinon gratuit)
    
    if (normalizedPriceType === "1") {
      // Payant
      const numPrice = Number(eventPrice || 0)
      if (numPrice > 0) {
        return `${numPrice.toFixed(2)}€`
      } else {
        return "Non précisé"
      }
    } else if (normalizedPriceType === "2" || normalizedPriceType === "0") {
      // Gratuit explicite
      return "Gratuit"
    } else if (!normalizedPriceType) {
      // Rétrocompatibilité pour anciens événements sans priceType
      const numPrice = Number(eventPrice || 0)
      if (numPrice > 0) {
        return `${numPrice.toFixed(2)}€`
      } else {
        return "Gratuit"
      }
    } else {
      // Cas par défaut (autres valeurs de priceType)
      return "Gratuit"
    }
  }

  return (
  <div className="bg-gradient-to-br from-purple-50 via-white to-blue-50 border-2 border-purple-200 p-6 rounded-2xl shadow-sm">
    <h3 className="text-xl font-bold text-gray-900 mb-6">Participer à l'événement</h3>
    
    {/* Prix */}
    <div className="text-center mb-6">
      <p className="text-sm text-gray-600 mb-2">Prix</p>
      <p className="text-3xl font-bold text-purple-600">
        {getPriceDisplay()}
      </p>
    </div>

    <div className="space-y-3">
      <button
        onClick={onParticipate}
        disabled={isExpired || isParticipating}
        className={`w-full py-3 px-4 text-center rounded-lg transition-all flex items-center justify-center gap-2 font-medium shadow-md ${
          hasParticipated
            ? "bg-gradient-to-r from-gray-600 to-gray-700 hover:from-gray-700 hover:to-gray-800 text-white"
            : isExpired
            ? "bg-gray-400 text-white cursor-not-allowed"
            : "bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white"
        }`}
      >
        <Ticket className="w-5 h-5" />
        <span>
          {isExpired 
            ? "Événement terminé" 
            : isParticipating 
              ? hasParticipated
                ? "Désinscription en cours..."
                : "Participation en cours..."
              : hasParticipated
              ? "Déjà inscrit / Ne plus participer"
              : "Je participe"
          }
        </span>
      </button>

      {showContactButton && (
        <button
          onClick={onContact}
          disabled={isExpired || isContactingLoading}
          className="w-full py-3 px-4 text-center border-2 border-purple-500 text-purple-700 hover:bg-purple-50 bg-transparent rounded-lg transition-all flex items-center justify-center gap-2 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Mail className="w-5 h-5" />
          <span>
            {isContactingLoading ? "Chargement..." : "Contacter"}
          </span>
        </button>
      )}

      {website && (
        <a
          href={website}
          target="_blank"
          rel="noopener noreferrer"
          className="block w-full py-3 px-4 text-center text-purple-600 hover:text-purple-700 font-medium transition-colors"
        >
          Visiter le site web
        </a>
      )}
    </div>
  </div>
  )
};

// Composant pour la carte organisateur
const EventOrganizerCard = ({
  userData,
  showMessageButton,
  userId,
  announcementId,
  onContact,
  isContactingLoading,
  displayName,
  isOrganizationPro,
  getOrganizerPhoto,
}: {
  userData: any
  showMessageButton: boolean
  userId: string
  announcementId: string
  onContact: () => void
  isContactingLoading: boolean
  displayName: string
  isOrganizationPro: boolean
  getOrganizerPhoto: () => string | null
}) => (
  <div className="border border-gray-200 p-6 rounded-none">
    <h2 className="text-2xl font-bold mb-6">À propos de l'organisateur</h2>
    
    <ProfileLinkGuard userId={userId} className="flex items-center gap-4 mb-4">
      <div className="relative w-16 h-16 rounded-full bg-gray-200 overflow-hidden">
        {getOrganizerPhoto() ? (
          <Image
            src={getOrganizerPhoto()!}
            alt={`Photo de ${displayName}`}
            width={64}
            height={64}
            className="object-cover w-full h-full"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center text-gray-500">
            {isOrganizationPro ? (
              <Briefcase className="h-8 w-8" />
            ) : (
              <User className="h-8 w-8" />
            )}
          </div>
        )}
      </div>
      <div>
        <div className="flex items-center gap-2">
          <p className="font-medium">{displayName}</p>
        </div>
        <p className="text-xs py-1 px-2 bg-green-500 rounded-sm text-white font-medium uppercase">
          {isOrganizationPro ? "Professionnel" : "Particulier"}
        </p>
      </div>
    </ProfileLinkGuard>

    {userData?.activite && (
      <p className="text-sm text-gray-600 mb-4">{userData.activite}</p>
    )}

    {userData?.presentation && (
      <div className="mb-4">
        <p className="text-xs font-semibold text-gray-900 mb-1">Présentation :</p>
        <p className="text-xs text-gray-700 leading-relaxed">{userData.presentation}</p>
      </div>
    )}

    {showMessageButton && (
      <FeatureGuard feature="messaging">
        <button
          onClick={onContact}
          disabled={isContactingLoading}
          className="w-full py-2 px-4 border border-gray-300 rounded flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
        >
          <Mail className="w-5 h-5" />
          <span>
            {isContactingLoading ? "Connexion en cours..." : "Contacter"}
          </span>
        </button>
      </FeatureGuard>
    )}
  </div>
);

// Composant ImageCarousel avec gestion d'erreurs robuste
function ImageCarousel({ images }: { images: string[] }) {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [imageErrors, setImageErrors] = useState<Set<number>>(new Set())

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100">
        <Calendar className="w-24 h-24 text-orange-300" />
      </div>
    )
  }

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % images.length)
  }

  const prevImage = () => {
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length)
  }

  const handleImageError = (index: number) => {
    setImageErrors(prev => new Set(prev).add(index))
  }

  const currentImageHasError = imageErrors.has(currentIndex)

  return (
    <div className="relative h-[400px] md:h-[500px] w-full overflow-hidden group border border-gray-100/30 rounded-none">
      {currentImageHasError ? (
        <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100">
          <div className="text-center">
            <Calendar className="w-24 h-24 text-orange-300 mx-auto mb-4" />
            <p className="text-gray-500">Image non disponible</p>
          </div>
        </div>
      ) : (
        <Image
          src={getImageUrl(images[currentIndex])}
          alt="Event image"
          fill
          className="object-cover"
          onError={() => handleImageError(currentIndex)}
          unoptimized
          priority={currentIndex === 0}
        />
      )}
      
      {images.length > 1 && (
        <>
          <button
            onClick={prevImage}
            className="absolute left-4 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/80 text-white p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-200 backdrop-blur-sm"
            aria-label="Image précédente"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>
          <button
            onClick={nextImage}
            className="absolute right-4 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/80 text-white p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-200 backdrop-blur-sm"
            aria-label="Image suivante"
          >
            <ChevronRight className="w-6 h-6" />
          </button>
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2 bg-black/40 backdrop-blur-sm px-3 py-2 rounded-full">
            {images.map((_, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentIndex(idx)}
                className={`w-2 h-2 rounded-full transition-all ${
                  idx === currentIndex ? "bg-white w-6" : "bg-white/60 hover:bg-white/80"
                } ${imageErrors.has(idx) ? "bg-red-500" : ""}`}
                aria-label={`Aller à l'image ${idx + 1}`}
              />
            ))}
          </div>
        </>
      )}
      
      {/* Date de l'annonce */}
      <div className="absolute top-4 left-4 bg-black/60 backdrop-blur-sm px-3 py-1 rounded text-white text-sm">
        {formatDateRelative(new Date().toISOString())}
      </div>
    </div>
  )
}

export default function EventDetailPage({ params }: { params: Promise<{ announcementId: string }> }) {
  const resolvedParams = use(params)
  const announcementId = resolvedParams.announcementId

  const router = useRouter()

  const [event, setEvent] = useState<EventDetail | null>(null)
  const [images, setImages] = useState<string[]>([])
  const [publisher, setPublisher] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [isFavorite, setIsFavorite] = useState(false)
  const [userId, setUserId] = useState<string | null>(null)
  const [isContactingLoading, setIsContactingLoading] = useState(false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [relatedEvents, setRelatedEvents] = useState<any[]>([])
  const [isParticipating, setIsParticipating] = useState(false)
  const [currentUserData, setCurrentUserData] = useState<any>(null)
  const [publisherHasSubscription, setPublisherHasSubscription] = useState(false)
  const [showCalendarPopup, setShowCalendarPopup] = useState(false)
  const [hasParticipated, setHasParticipated] = useState(false)

  const currentUserIsPro = currentUserData?.companyData?.profiletype === "professionnel"

  useEffect(() => {
    const storedUserId = localStorage.getItem("profileId")
    setUserId(storedUserId)
    loadEventData()
  }, [announcementId])

  // Check participation status when user or event changes
  useEffect(() => {
    if (userId && event) {
      checkUserParticipation()
    }
  }, [userId, event?.id])

  // Charger les événements similaires
  useEffect(() => {
    if (event) {
      const loadRelatedEvents = async () => {
        try {
          const response = await axios.post(
            `${config.API_URL}/Ads.php`,
            {
              Method: "readAdsByCriteria",
              category: "evenements",
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
            
            // Charger les données utilisateur et les images pour chaque événement
            const eventsWithUserData = await Promise.all(
              filtered.map(async (eventItem: any) => {
                let images: string[] = []

                // 1. Essayer de charger les images via ImageAnnonce.php
                try {
                  const imagesResult = await fetchDealImages(eventItem.id)
                  if (imagesResult.success && imagesResult.images && imagesResult.images.length > 0) {
                    images = imagesResult.images
                  }
                } catch (error) {
                  console.error(`Erreur chargement images pour ${eventItem.id}:`, error)
                }

                // 2. Si pas d'images trouvées, essayer de parser le champ images de l'annonce (fallback)
                if (images.length === 0 && eventItem.images) {
                  let parsedImages = eventItem.images
                  if (typeof parsedImages === 'string') {
                    try {
                      parsedImages = JSON.parse(parsedImages)
                    } catch (e) {
                      console.error(`Erreur parsing images fallback pour ${eventItem.id}:`, e)
                      parsedImages = []
                    }
                  }
                  if (Array.isArray(parsedImages) && parsedImages.length > 0) {
                    images = parsedImages
                  }
                }

                // 3. Charger les données de l'organisation
                let companyData = null
                try {
                  if (eventItem.userId) {
                    const userResult = await fetchPublisherData(eventItem.userId)
                    if (userResult.success) {
                      companyData = userResult.userData.companyData
                    }
                  }
                } catch (error) {
                  console.error(`Erreur chargement données utilisateur pour ${eventItem.id}:`, error)
                }

                return { 
                  ...eventItem, 
                  images,
                  companyData 
                }
              })
            )
            
            setRelatedEvents(eventsWithUserData)
          }
        } catch (error) {
          console.error("Error loading related events:", error)
        }
      }
      loadRelatedEvents()
    }
  }, [event, announcementId])

  const checkUserParticipation = async () => {
    if (!userId || !announcementId) return
    
    try {
      const result = await checkParticipationStatus(userId, announcementId)
      if (result.success) {
        setHasParticipated(result.isParticipating)
      }
    } catch (error) {
      console.error("Error checking participation:", error)
    }
  }

  const handleParticipate = async () => {
    if (!userId) {
      router.push("/login-required")
      return
    }

    // If already participating, unsubscribe
    if (hasParticipated) {
      setIsParticipating(true)
      try {
        const result = await unsubscribeFromEvent(userId, announcementId)
        if (result.success) {
          setHasParticipated(false)
          toastSuccess(result.message || "Désinscription réussie")
        } else {
          toastError(result.error || "Une erreur est survenue lors de la désinscription")
        }
      } catch (error) {
        console.error("Error unsubscribing from event:", error)
        toastError("Une erreur est survenue lors de la désinscription")
      } finally {
        setIsParticipating(false)
      }
      return
    }

    // Show calendar popup first
    setShowCalendarPopup(true)
  }

  const handleConfirmParticipation = async () => {
    if (!userId) return

    setIsParticipating(true)
    setShowCalendarPopup(false)
    
    try {
      const result = await participateEvent(userId, announcementId)
      if (result.success) {
        setHasParticipated(true)
        toastSuccess(result.message || "Participation enregistrée avec succès")
      } else {
        toastError(result.error || "Une erreur est survenue lors de la participation")
      }
    } catch (error) {
      console.error("Error participating in event:", error)
      toastError("Une erreur est survenue lors de la participation")
    } finally {
      setIsParticipating(false)
    }
  }

  const loadEventData = async () => {
    setLoading(true)
    try {
      await updateViewCount(announcementId)

      const eventResult = await fetchAnnouncementDetail(announcementId)

      if (!eventResult) {
        toastError("Événement introuvable")
        router.push("/evenements")
        return
      }

      setEvent(eventResult)
      setIsFavorite(eventResult.isFavorite || false)

      const imagesResult = await fetchDealImages(announcementId)
      if (imagesResult.success && imagesResult.images) {
        setImages(imagesResult.images)
      }

      const publisherResult = await fetchPublisherData(eventResult.userId)
      if (publisherResult.success) {
        setPublisher(publisherResult.userData)
        // Vérifier l'abonnement du publisher
        const hasSubscription = await checkUserSubscription(eventResult.userId)
        setPublisherHasSubscription(hasSubscription)
      }
    } catch (error) {
      console.error("Error loading event:", error)
      toastError("Erreur lors du chargement de l'événement")
    } finally {
      setLoading(false)
    }
  }

  // Charger l'utilisateur connecté
  useEffect(() => {
    if (userId) {
      const loadCurrentUser = async () => {
        const result = await fetchPublisherData(userId)
        if (result.success) {
          setCurrentUserData(result.userData)
        }
      }
      loadCurrentUser()
    }
  }, [userId])

  async function updateViewCount(announcementId: string) {
    try {
      console.log("[v0] Updating view count for event announcement:", announcementId)
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

  const handleToggleFavorite = async () => {
    if (!userId) {
      toastError("Vous devez être connecté")
      return
    }

    try {
      const result = await toggleFavorite(userId, announcementId, !isFavorite)
      if (result.success) {
        setIsFavorite(!isFavorite)
        toastSuccess(result.message || (isFavorite ? "Retiré des favoris" : "Ajouté aux favoris"))
      }
    } catch (error) {
      toastError("Erreur lors de la mise à jour")
    }
  }

  const handleShare = async () => {
    setShowShareModal(true)
  }

  const handleContact = async () => {
    if (!userId) {
      router.push("/login-required")
      return
    }

    setIsContactingLoading(true)
    try {
      if (!event?.userId) {
        toastError("Impossible de contacter cet utilisateur")
        return
      }
      
      const conversationId = await startConversation(event.userId)

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

  const isExpired = event?.endDate ? new Date(event.endDate) < new Date() : false
  const eventPrice = event?.price ? Number.parseFloat(event.price) : 0

  const getOrganizerName = () => {
    if (event?.isOrganizator && event?.nameOrganizator) {
      return event.nameOrganizator
    }
    
    if (publisher?.companyData?.profiletype === "professionnel") {
      return publisher?.companyData?.nomsociete || "Entreprise"
    }
    
    return publisher?.companyData?.pseudo || "Organisateur"
  }

  const getPublisherName = () => {
    if (publisher?.companyData?.profiletype === "professionnel") {
      return publisher?.companyData?.nomsociete || "Entreprise"
    }
    return publisher?.companyData?.pseudo || "Utilisateur"
  }

  const isOrganizationPro = () => {
    return publisher?.companyData?.profiletype === "professionnel"
  }

  const getOrganizerPhoto = () => {
    const photoUrl = publisher?.companyData?.photoprofilurl || publisher?.photoprofilurl
    if (!photoUrl) return null
    
    if (photoUrl.startsWith("http")) {
      return photoUrl
    }
    
    return `${config.API_URL}${photoUrl}`
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40">
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Chargement de l'événement...</p>
          </div>
        </div>
      </div>
    )
  }

  if (!event) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40">
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <AlertCircle className="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Événement introuvable</h2>
            <p className="text-gray-600 mb-4">Cet événement n'existe pas ou a été supprimé</p>
            <Button onClick={() => router.push("/evenements")}>Retour aux événements</Button>
          </div>
        </div>
      </div>
    )
  }

  const address = event.address ? (typeof event.address === 'string' ? JSON.parse(event.address) : event.address) : {}
  const showMessageButton = typeof window !== "undefined" && 
    localStorage.getItem("profileId") !== event?.userId && 
    !isExpired

  const sponsorshipLink = typeof window !== "undefined"
    ? `${window.location.origin}/announcements/events/${event?.id}`
    : ""

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40 overflow-x-hidden">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm text-gray-600 mb-6">
        <Home className="h-4 w-4" />
        <ChevronRight className="h-4 w-4" />
        <button onClick={() => router.push("/evenements")} className="hover:text-gray-900 transition-colors">
          Événements
        </button>
        <ChevronRight className="h-4 w-4" />
        <span className="text-gray-900 font-medium truncate max-w-[150px] sm:max-w-[200px]">{event.title}</span>
      </nav>

      {/* Layout principal */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6 lg:gap-8">
        {/* Contenu principal - 2/3 colonnes */}
        <div className="lg:col-span-2 space-y-6">
          {/* Carousel d'images */}
          {images.length > 0 && (
            <Card className="p-0 overflow-hidden">
              <ImageCarousel images={images} />
            </Card>
          )}

          <Card className={`p-6 ${isExpired ? "border-2 border-red-500" : ""}`}>
            <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-3 flex-wrap">
                  {event.eventType && (
                    <Badge variant="secondary" className="bg-orange-100 text-orange-700 break-words max-w-full">
                      {formatEventTypeLabel(event.eventType)}
                    </Badge>
                  )}
                  {event.subCategory && (
                    <Badge variant="outline" className="bg-blue-50 text-blue-700 break-words max-w-full">
                      {formatSubCategoryLabel(event.subCategory)}
                    </Badge>
                  )}
                  {(event.formatEvent || event.eventFormat) && (
                    <Badge variant="outline">
                      {(event.formatEvent || event.formatEvent) === "in_person"
                        ? "Présentiel"
                        : (event.formatEvent || event.formatEvent) === "online"
                          ? "En ligne"
                          : "Hybride"}
                    </Badge>
                  )}
                  {isExpired && (
                    <Badge className="bg-red-600 text-white border-2 border-white shadow-lg">
                      EXPIRÉ
                    </Badge>
                  )}
                </div>
                <h1 className={`text-3xl font-bold mb-3 break-words ${isExpired ? "text-gray-500" : "text-gray-900"}`}>
                  {event.title}
                </h1>
                <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
                  <div className="flex items-center gap-1">
                    <Calendar className="w-4 h-4" />
                    <span>Publié {formatDateRelative(event.createdat)}</span>
                  </div>
                </div>
              </div>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="icon"
                  onClick={handleToggleFavorite}
                  className="hover:bg-red-50"
                >
                  <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : ""}`} />
                </Button>
                <Button
                  variant="outline"
                  size="icon"
                  onClick={handleShare}
                  className="hover:bg-blue-50"
                >
                  <Share2 className="w-5 h-5" />
                </Button>
              </div>
            </div>
          </Card>

          {/* Description */}
          <Card className="p-6">
            <h2 className="text-2xl font-bold mb-6">À propos de cet événement</h2>
            <div 
              className="prose prose-slate max-w-none text-gray-700 leading-relaxed"
              dangerouslySetInnerHTML={{ __html: sanitizeHtml(event.description) }}
            />
          </Card>

          {/* Localisation avec carte - visible uniquement si publishadresse est autorisé */}
          {event.address && publisher && publisher.companyData && (publisher.companyData.publishadresse === "true" || publisher.companyData.publishadresse === true || publisher.companyData.publishadresse === "1") && (
            <div className="border border-gray-200 p-6 rounded-none mb-8">
              <h2 className="text-2xl font-bold mb-6">Localisation</h2>
              <div className="space-y-4">
                <div>
                  <p className="text-sm font-semibold text-gray-900 mb-1">Adresse :</p>
                  <p className="text-sm text-gray-700">{formatAddress(event.address)}</p>
                </div>
                <LocationMap 
                  address={event.address} 
                  title={event.title}
                  className="rounded-lg h-[300px]"
                />
              </div>
            </div>
          )}

          {/* Commentaires */}
          <CommentsSection announcementId={announcementId} />
        </div>

        {/* Sidebar - 1/3 colonne */}
        <div className="lg:col-span-1 order-1 lg:order-2 space-y-8">
          {/* Carousel d'images - visible sur mobile */}
          {images.length > 0 && (
            <div className="block md:hidden">
              <ImageCarousel images={images} />
            </div>
          )}

          {/* Détails de l'événement */}
          <EventDetailsSidebar event={event} />

          {/* Actions de participation */}
          <EventActionCard
            website={event.website}
            onParticipate={handleParticipate}
            isParticipating={isParticipating}
            isExpired={isExpired}
            eventPrice={eventPrice}
            priceType={event.priceType}
            onContact={handleContact}
            isContactingLoading={isContactingLoading}
            showContactButton={userId !== event?.userId && (event?.acceptMessages === true || event?.message === true)}
            hasParticipated={hasParticipated}
          />

          {/* Organisateur */}
          {publisher && publisher.companyData && (
            <PublisherCard
              publisherName={getPublisherName()}
              announcementTitle={event.title}
              announcementType="bon-plan"
              userId={event.userId}
              photoUrl={getOrganizerPhoto()}
              isProfessional={isOrganizationPro()}
              activite={publisher.companyData.activite}
              ville={publisher.companyData.ville}
              pays={publisher.companyData.pays}
              telephone={""}
              email={""}
              adresse={publisher.companyData.adresse}
              codePostal={publisher.companyData.codepostal}
              hasPremiumSubscription={publisherHasSubscription}
              currentUserIsPro={currentUserIsPro}
              publishadresse={publisher.companyData.publishadresse}
            />
          )}
        </div>
      </div>

      {/* Section Événements similaires */}
      {relatedEvents.length > 0 && (
        <div className="mt-16 py-12 bg-gradient-to-b from-gray-50 to-white rounded-lg">
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Autres événements</h2>
            <p className="text-gray-600">Découvrez d'autres événements qui pourraient vous intéresser</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {relatedEvents.map((relatedEvent) => {
              const getCleanDescription = () => {
                if (!relatedEvent.description) return ""
                const cleanText = relatedEvent.description.replace(/<[^>]*>/g, ' ')
                const normalized = cleanText.replace(/\s+/g, ' ').trim()
                return normalized
              }

              const isExpired = (relatedEvent.eventDurationType === "permanent" || relatedEvent.isAllDays) 
                ? false 
                : (relatedEvent.endDate ? new Date(relatedEvent.endDate) < new Date() : false)
              
              const isFull = relatedEvent.eventMaxAttendees && relatedEvent.eventCurrentAttendees &&
                Number.parseInt(relatedEvent.eventCurrentAttendees) >= Number.parseInt(relatedEvent.eventMaxAttendees)

              const getEventStatus = () => {
                if (isExpired) return { label: "Passé", color: "bg-gray-500" }
                if (isFull) return { label: "Complet", color: "bg-red-500" }
                if (relatedEvent.eventDurationType === "permanent" || relatedEvent.isAllDays) {
                  return { label: "Permanent", color: "bg-blue-500" }
                }
                const eventDate = relatedEvent.eventDate || relatedEvent.startDate
                if (!eventDate) return { label: "Date à définir", color: "bg-gray-400" }
                const eventDateTime = new Date(eventDate)
                const today = new Date()
                today.setHours(0, 0, 0, 0)
                const diffTime = eventDateTime.getTime() - today.getTime()
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
                if (diffDays < 0) return { label: "Passé", color: "bg-gray-500" }
                if (diffDays === 0) return { label: "Aujourd'hui", color: "bg-green-500" }
                if (diffDays === 1) return { label: "Demain", color: "bg-blue-500" }
                if (diffDays <= 7) return { label: "Cette semaine", color: "bg-blue-500" }
                if (diffDays <= 30) return { label: "Ce mois-ci", color: "bg-orange-500" }
                return { label: "À venir", color: "bg-orange-500" }
              }

              const status = getEventStatus()

              const getOrganizerName = () => {
                const companyData = relatedEvent.companyData
                if (!companyData) return "Organisateur"
                if (companyData.profiletype === "professionnel") {
                  return companyData.nomsociete || "Entreprise"
                }
                return companyData.pseudo || relatedEvent.userPseudo || "Particulier"
              }

              const getOrganizerPhoto = () => {
                const companyData = relatedEvent.companyData
                if (!companyData || !companyData.photoprofilurl) return null
                return companyData.photoprofilurl.startsWith("http") 
                  ? companyData.photoprofilurl 
                  : `${config.API_URL}${companyData.photoprofilurl}`
              }

              const isProfessional = relatedEvent.companyData?.profiletype === "professionnel"

              const formatEventDate = () => {
                if (relatedEvent.eventDurationType === "permanent" || relatedEvent.isAllDays) {
                  return "Permanent"
                }
                const eventDate = relatedEvent.eventDate || relatedEvent.startDate
                if (!eventDate) return "Date à définir"
                const date = new Date(eventDate)
                return date.toLocaleDateString("fr-FR", { 
                  day: "numeric", 
                  month: "long", 
                  year: "numeric" 
                })
              }

              const getFormattedLocation = () => {
                if (relatedEvent.eventCity) return relatedEvent.eventCity
                if (relatedEvent.eventLocation) {
                  if (typeof relatedEvent.eventLocation === 'string') {
                    return relatedEvent.eventLocation
                  }
                  return formatAddress(relatedEvent.eventLocation)
                }
                if (relatedEvent.address) {
                  return formatAddress(relatedEvent.address)
                }
                return null
              }

              const getParticipantsDisplay = () => {
                const current = Number.parseInt(relatedEvent.eventCurrentAttendees || "0")
                const max = Number.parseInt(relatedEvent.eventMaxAttendees || "0")
                if (max > 0) {
                  return `${current}/${max} participants`
                } else if (current > 0) {
                  return `${current} participant${current > 1 ? 's' : ''}`
                }
                return null
              }

              const getFormattedPrice = () => {
                const price = relatedEvent.eventPrice || relatedEvent.price
                if (!price) return "Gratuit"
                const numPrice = Number.parseFloat(price)
                return numPrice === 0 ? "Gratuit" : `${numPrice}€`
              }

              const getDisplayCategory = () => {
                const eventType = relatedEvent.eventType || relatedEvent.eventCategory || relatedEvent.category
                return (labelObject as any)[eventType] || eventType
              }

              const getDisplaySubCategory = () => {
                if (!relatedEvent.subCategory) return null
                return (labelObject as any)[relatedEvent.subCategory] || relatedEvent.subCategory
              }

              const getImageUrl = (imagePath: string) => {
                if (!imagePath) return ""
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

              const imageUrl = relatedEvent.images && relatedEvent.images[0] ? getImageUrl(relatedEvent.images[0]) : null
              
              return (
                <Link
                  key={relatedEvent.id}
                  href={`/announcements/events/${relatedEvent.id}`}
                  onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                >
                  <Card
                    className={`flex flex-col h-full min-h-[400px] hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-visible group cursor-pointer border-0 bg-white/90 backdrop-blur-md ${
                      isExpired ? "opacity-60 grayscale" : "hover:shadow-orange-200/60"
                    }`}
                  >
                    {/* Image with overlays */}
                    <div className="relative h-56 bg-gradient-to-br from-orange-100 via-orange-50 to-pink-50 overflow-hidden">
                      {isExpired && (
                        <div className="absolute inset-0 bg-black/40 z-20 flex items-center justify-center">
                          <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
                        </div>
                      )}
                      
                      {/* Placeholder background always visible, image sits on top */}
                      <div className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-orange-100 to-orange-50">
                        <Calendar className="w-16 h-16 text-orange-300" />
                      </div>

                      {imageUrl && (
                        <img
                          src={imageUrl}
                          alt={relatedEvent.title}
                          className={`absolute inset-0 w-full h-full object-cover group-hover:scale-110 transition-transform duration-300 ${
                            isExpired ? "grayscale brightness-75" : ""
                          }`}
                          onError={(e) => {
                            (e.target as HTMLImageElement).style.display = 'none';
                          }}
                        />
                      )}

                      {/* Category badge - top left */}
                      {getDisplayCategory() && (
                        <div className="absolute top-3 left-3 z-10">
                          <Badge className="bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-xl backdrop-blur-sm border border-white/20">{getDisplayCategory()}</Badge>
                        </div>
                      )}

                      {/* Badge statut */}
                      <div className="absolute top-3 right-3 z-10">
                        <Badge className={`text-white shadow-xl backdrop-blur-sm border border-white/20 ${status.color}`}>
                          {status.label}
                        </Badge>
                      </div>

                      {/* Action buttons - bottom right */}
                      <div className="absolute bottom-3 right-3 flex gap-2 z-10">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-10 w-10 rounded-full bg-white/95 hover:bg-white shadow-lg backdrop-blur-md hover:scale-110 transition-all duration-300"
                          onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}
                        >
                          <Heart className="w-4 h-4 text-gray-600" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 rounded-full bg-white/90 hover:bg-white shadow-md"
                          onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}
                        >
                          <Share2 className="w-4 h-4 text-gray-600" />
                        </Button>
                      </div>
                    </div>

                    {/* Content */}
                    <div className="p-4 flex-1 flex flex-col">
                      {/* Title */}
                      <h3
                        className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-orange-600 transition-colors ${
                          isExpired ? "text-gray-500" : "text-gray-900"
                        }`}
                      >
                        {relatedEvent.title}
                      </h3>

                      {/* Organizer */}
                      <div className="flex items-center gap-2 mb-3">
                        {getOrganizerPhoto() ? (
                          <img
                            src={getOrganizerPhoto()!}
                            alt={getOrganizerName()}
                            className="w-5 h-5 rounded-full object-cover"
                          />
                        ) : (
                          <div className="w-5 h-5 rounded-full bg-gradient-to-br from-orange-100 to-orange-200 flex items-center justify-center">
                            {isProfessional ? (
                              <svg className="w-2.5 h-2.5 text-orange-600" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M4 4a2 2 0 012-2h8a2 2 0 012 2v12a1 1 0 110 2h-3a1 1 0 01-1-1v-6a1 1 0 00-1-1H9a1 1 0 00-1 1v6a1 1 0 01-1 1H4a1 1 0 110-2V4zm3 1h2v2H7V5zm2 4H7v2h2V9zm2-4h2v2h-2V5zm2 4h-2v2h2V9z" clipRule="evenodd" />
                              </svg>
                            ) : (
                              <svg className="w-2.5 h-2.5 text-orange-600" fill="currentColor" viewBox="0 0 20 20">
                                <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd" />
                              </svg>
                            )}
                          </div>
                        )}
                        <span className="text-sm font-medium text-gray-600">{getOrganizerName()}</span>
                      </div>

                      {/* Informations clés */}
                      <div className="space-y-2 mb-4">
                        <div className="flex items-center gap-2">
                          <div className="flex items-center gap-2 bg-orange-100 px-3 py-1.5 rounded-lg">
                            <Calendar className="w-4 h-4 text-orange-600" />
                            <span className={status.label === "Passé" ? "text-sm font-bold text-orange-900 line-through" : "text-sm font-bold text-orange-900"}>{formatEventDate()}</span>
                          </div>
                        </div>
                        
                        {(relatedEvent.eventType || relatedEvent.subCategory) && (
                          <div className="flex items-center gap-2 text-sm text-gray-600">
                            <span className="font-medium text-xs truncate">{getDisplayCategory()}</span>
                            {relatedEvent.subCategory && relatedEvent.eventType && <span className="flex-shrink-0">·</span>}
                            {relatedEvent.subCategory && <span className="text-xs truncate">{getDisplaySubCategory()}</span>}
                          </div>
                        )}
                        
                        {getFormattedLocation() && (
                          <div className="flex items-center gap-2 text-sm text-gray-600">
                            <MapPin className="w-4 h-4 flex-shrink-0" />
                            <span className="truncate">{getFormattedLocation()}</span>
                          </div>
                        )}
                        
                        {getParticipantsDisplay() && (
                          <div className="flex items-center gap-2 text-sm text-gray-600">
                            <Users className="w-4 h-4 flex-shrink-0" />
                            <span>{getParticipantsDisplay()}</span>
                          </div>
                        )}
                      </div>

                      {/* Prix */}
                      <div className={`text-2xl font-bold mb-4 mt-auto ${isExpired ? "text-gray-400 line-through" : "text-orange-600"}`}>
                        {getFormattedPrice()}
                      </div>

                      {/* CTA Button */}
                      <Button
                        className={
                          isExpired
                            ? "w-full bg-gray-400 cursor-not-allowed"
                            : "w-full bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white"
                        }
                        disabled={isExpired}
                        onClick={(e) => {
                          e.preventDefault()
                          e.stopPropagation()
                        }}
                      >
                        {isExpired ? "Expiré" : "Voir l'événement"}
                      </Button>

                      {/* Publié il y a */}
                      <p className="text-sm text-gray-500 mt-3 text-center">
                        Publié {formatDateRelative(relatedEvent.createdat)}
                      </p>
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
        title={event?.title || ""}
        url={`/announcements/events/${announcementId}`}
        description={event?.description}
      />

      <CalendarPopup
        isOpen={showCalendarPopup}
        onClose={() => {
          setShowCalendarPopup(false)
        }}
        onCalendarSelected={() => {
          // After user selects a calendar, confirm participation
          if (userId && !hasParticipated) {
            handleConfirmParticipation()
          }
        }}
        event={{
          title: event?.title || "",
          description: event?.description,
          startDate: event?.startDate || event?.eventDate,
          endDate: event?.endDate,
          startTime: event?.startTime || event?.eventTime,
          endTime: event?.endTime,
          address: event?.address,
          location: event?.eventLocation || event?.eventCity,
        }}
      />
    </div>
  )
}