"use client"

import type React from "react"

import { useEffect, useState, useMemo, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { motion } from "framer-motion"
import {
  Plus,
  Bell,
  MapPin,
  HelpCircle,
  Clock,
  Search,
  Filter,
  ChevronUp,
  ChevronDown,
  Grid3x3,
  List,
  X,
  Locate,
  Heart,
  Share2,
  MessageCircle,
  Euro,
  User,
  Briefcase,
} from "lucide-react"
import { fetchAnnoncements, toggleFavorite, fetchCommentsByAnnouncementId, fetchUserInfoById } from "@/lib/api"
import { toast } from "sonner"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { Checkbox } from "@/components/ui/checkbox"
import { useToast } from "@/hooks/use-toast"
import { config } from "@/lib/config"
import { ShareModal } from "@/components/share-modal"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import labelObject from "@/lib/constants/label-object"
import { SaveSearchButton } from "@/components/save-search-button"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import axios from "axios"
import citiesData from "@/lib/data/france-cities.json"
import { getCoordsFromAddress } from "@/lib/data/zipcode-coords"
import useInfiniteRender from "@/hooks/useInfiniteRender"

const API_URL = config.API_URL

function formatAddress(address: any): string {
  if (!address) return ""

  // Si c'est une chaîne, essayer de la parser comme JSON
  if (typeof address === "string") {
    // Si ça ressemble à du JSON, essayer de le parser
    if (address.trim().startsWith("{") || address.trim().startsWith("[")) {
      try {
        const parsed = JSON.parse(address)
        return formatAddress(parsed)
      } catch {
        // Si le parsing échoue, retourner la chaîne telle quelle
        return address
      }
    }
    return address
  }

  // Si c'est un objet, extraire les informations
  if (typeof address === "object") {
    const parts = []
    
    // Code postal
    if (address.zipcode || address.postalCode || address.codepostal) {
      parts.push(address.zipcode || address.postalCode || address.codepostal)
    }
    
    // Ville
    if (address.city || address.ville) {
      parts.push(address.city || address.ville)
    }
    
    // Pays
    if (address.country || address.pays) {
      parts.push(address.country || address.pays)
    }
    
    return parts.filter(Boolean).join(", ")
  }

  return ""
}

// Fonction pour calculer la distance entre deux points GPS (formule de Haversine)
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371 // Rayon de la Terre en km
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c // Distance en km
}

interface Inquiry {
  id: string
  title: string
  description?: string
  inquiryTitle?: string
  inquiryDescription?: string
  inquiryType?: string
  inquiryTypeCategory?: string
  inquiryTrainingCategory?: string
  inquiryTrainingType?: string
  inquiryContractType?: string
  inquiryEntitled?: string
  inquiryOccupationType?: string
  inquiryStudyLevel?: string
  inquiryXpLevel?: string
  budgetMin?: string
  budgetMax?: string
  livingSpaceMin?: string
  livingSpaceMax?: string
  groundSpaceMin?: string
  groundSpaceMax?: string
  piece?: string
  bedroom?: string
  realEstateType?: string
  furniture?: string
  address?: string | any
  city?: string
  ray?: string
  startDate?: string
  endDate?: string
  images?: string[]
  userId?: string
  createdat?: string
  isFavorite?: boolean
  number_view?: number
  companyData?: {
    id?: string
    userid?: string
    profiletype?: "professionnel" | "particulier"
    pseudo?: string
    nomsociete?: string
    activite?: string
    photoprofilurl?: string
    adresse?: string
    ville?: string
    codepostal?: string
    pays?: string
    presentation?: string
    telephone?: string
  }
  telework?: boolean
  useCandidateDocuments?: boolean
  message?: boolean
  [key: string]: any
}

function getUserDisplayName(inquiry: Inquiry): string {
  console.log('the company', inquiry)
  if (inquiry.userInfo) {
    const userInfo = inquiry.userInfo
    if (userInfo.profiletype === "professionnel") {
      return userInfo.nomsociete || "Entreprise"
    }
    return userInfo.pseudo || "Particulier"
    }
  // Récupérer les infos utilisateur via inquiry.userId si companyData n'existe pas
  if (!inquiry.companyData && inquiry.userId) {
    // Retourner un nom par défaut en attendant de charger les vraies données
    return "Utilisateur"
  }

  const companyData = inquiry.companyData
  if (!companyData) return "Demandeur"

  if (companyData.profiletype === "professionnel") {
    return companyData.nomsociete || "Entreprise"
  }
  return companyData.pseudo || "Particulier"
}

function getUserPhoto(inquiry: Inquiry): string | null {
  // Essayer d'abord userInfo
  if (inquiry.userInfo?.photoprofilurl) {
    const photoUrl = inquiry.userInfo.photoprofilurl
    if (photoUrl.startsWith("http")) {
      return photoUrl
    }
    return `${API_URL}${photoUrl}`
  }
  
  // Sinon utiliser companyData
  const companyData = inquiry.companyData
  if (!companyData || !companyData.photoprofilurl) return null
  
  // Si l'URL commence déjà par http, la retourner telle quelle
  if (companyData.photoprofilurl.startsWith("http")) {
    return companyData.photoprofilurl
  }
  
  // Sinon, ajouter le préfixe API_URL
  return `${API_URL}${companyData.photoprofilurl}`
}

function getTimeAgo(date: string): string {
  const now = new Date()
  const past = new Date(date)
  const diffInMs = now.getTime() - past.getTime()
  const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
  const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
  const diffInMonths = Math.floor(diffInDays / 30)

  if (diffInMinutes < 60) return `Il y a ${diffInMinutes} min`
  if (diffInHours < 24) return `Il y a ${diffInHours}h`
  if (diffInDays < 30) return `Il y a ${diffInDays} jour${diffInDays > 1 ? "s" : ""}`
  return `Il y a ${diffInMonths} mois`
}

function getInquiryCategory(inquiry: Inquiry): string {
  if (!inquiry.inquiryType) return "Divers"
  
  // Utiliser directement labelObject pour toutes les traductions
  return labelObject[inquiry.inquiryType as keyof typeof labelObject] || inquiry.inquiryType
}

function getInquirySubCategory(inquiry: Inquiry): string | null {
  if (!inquiry.inquiryTypeCategory) return null
  return labelObject[inquiry.inquiryTypeCategory as keyof typeof labelObject] || inquiry.inquiryTypeCategory
}

function getInquiryNature(inquiry: Inquiry): string {
  return getInquiryCategory(inquiry)
}

function getBudgetDisplay(inquiry: Inquiry): string | null {
  const budgetMin = inquiry.budgetMin ? Number.parseFloat(inquiry.budgetMin) : 0
  const budgetMax = inquiry.budgetMax ? Number.parseFloat(inquiry.budgetMax) : 0
  
  if (budgetMin > 0 && budgetMax > 0) {
    return `${budgetMin}€ - ${budgetMax}€`
  }
  if (budgetMin > 0) {
    return `À partir de ${budgetMin}€`
  }
  if (budgetMax > 0) {
    return `Jusqu'à ${budgetMax}€`
  }
  return null
}

function InquiryCard({ inquiry, viewMode }: { inquiry: Inquiry; viewMode: "grid" | "list" }) {
  const [isFavorite, setIsFavorite] = useState(inquiry.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [imageError, setImageError] = useState(false)
  const router = useRouter()

  const [commentsCount, setCommentsCount] = useState(0)

  useEffect(() => {
    const fetchCommentsCount = async () => {
      try {
        const result = await fetchCommentsByAnnouncementId(inquiry.id)
        if (result.success) {
          setCommentsCount(result.comments.length)
        }
      } catch (error) {
        console.error("Erreur lors de la récupération des commentaires:", error)
      }
    }

    fetchCommentsCount()
  }, [inquiry.id])

  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!displayDescription) return ""
    // Créer un élément temporaire pour décoder les entités HTML
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = displayDescription
    // Récupérer le texte décodé
    const decodedText = tempDiv.textContent || tempDiv.innerText || ""
    // Normaliser les espaces
    const normalized = decodedText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  // Gérer les favoris
  const handleFavorite = async (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
    if (!userId) {
      window.location.href = "/login-required"
      return
    }

    try {
      const newFavoriteState = !isFavorite
      const result = await toggleFavorite(userId, inquiry.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Inquiry] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, displayTitle)
        
        if (newFavoriteState) {
          toast.success("Ajouté aux favoris", {
            description: "Retrouvez cette annonce dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=demandes"
            }
          })
        } else {
          toast.success("Retiré des favoris")
        }
      } else {
        toast.error("Erreur lors de la mise à jour du favori")
      }
    } catch (error) {
      console.error("[Favorite Inquiry] Erreur:", error)
      toast.error("Erreur lors de la mise à jour du favori")
    }
  }

  const userName = getUserDisplayName(inquiry)
  const userAvatar = getUserPhoto(inquiry)
  const timeAgo = inquiry.createdat ? getTimeAgo(inquiry.createdat) : ""
  const category = getInquiryCategory(inquiry)
  const subCategory = getInquirySubCategory(inquiry)
  const nature = getInquiryNature(inquiry)
  const budget = getBudgetDisplay(inquiry)
  const location = formatAddress(inquiry.address)
  const isExpired = inquiry.endDate ? new Date(inquiry.endDate) < new Date() : false
  const isProfessional = inquiry.userInfo?.profiletype === "professionnel" || inquiry.companyData?.profiletype === "professionnel"

  // Titre réel de la demande
  const displayTitle = inquiry.inquiryTitle || inquiry.title || "Demande sans titre"
  const displayDescription = inquiry.inquiryDescription || inquiry.description || "Aucune description disponible"

  // Informations spécifiques selon le type de demande
  const getSpecificInfo = () => {
    const info = []
    
    if (inquiry.inquiryType === "JobSearchInternship") {
      if (inquiry.inquiryTypeCategory) {
        info.push(labelObject[inquiry.inquiryTypeCategory as keyof typeof labelObject] || inquiry.inquiryTypeCategory)
      }
      if (inquiry.inquiryContractType) {
        try {
          const contracts = typeof inquiry.inquiryContractType === 'string' 
            ? JSON.parse(inquiry.inquiryContractType.replace(/[{}]/g, '').split(',').map(s => `"${s.trim()}"`).join(','))
            : inquiry.inquiryContractType
          if (Array.isArray(contracts) && contracts.length > 0) {
            info.push(labelObject[contracts[0] as keyof typeof labelObject] || contracts[0])
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
      if (inquiry.telework) {
        info.push("Télétravail possible")
      }
    }
    
    if (inquiry.inquiryType === "Training") {
      if (inquiry.inquiryTrainingCategory) {
        info.push(labelObject[inquiry.inquiryTrainingCategory as keyof typeof labelObject] || inquiry.inquiryTrainingCategory)
      }
      if (inquiry.inquiryTrainingType) {
        info.push(labelObject[inquiry.inquiryTrainingType as keyof typeof labelObject] || inquiry.inquiryTrainingType)
      }
    }
    
    return info
  }

  const specificInfo = getSpecificInfo()

  // handleFavorite déjà défini plus haut avec gestion API

  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
  }

  const handleRespond = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    router.push(`/announcements/inquiries/${inquiry.id}`)
  }

  if (viewMode === "list") {
    return (
      <>
        <Link href={`/announcements/inquiries/${inquiry.id}`}>
          <Card
          className={`relative hover:shadow-2xl hover:-translate-y-1 transition-all duration-500 overflow-hidden group cursor-pointer border-0 bg-white/90 backdrop-blur-sm ${
            isExpired ? "opacity-60 grayscale" : "hover:shadow-indigo-200/50"
          }`}
        >
          <div className="p-6">
            {/* Header: Avatar + User Info + Actions */}
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                {userAvatar && !imageError ? (
                  <img
                    src={userAvatar}
                    alt={userName}
                    className="w-14 h-14 rounded-full object-cover ring-2 ring-indigo-100 shadow-md"
                    onError={() => setImageError(true)}
                  />
                ) : (
                  <div className="w-14 h-14 rounded-full bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center shadow-md ring-2 ring-indigo-100">
                    {isProfessional ? (
                      <Briefcase className="w-7 h-7 text-white" />
                    ) : (
                      <User className="w-7 h-7 text-white" />
                    )}
                  </div>
                )}
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-bold text-gray-900">{userName}</span>
                    <span className="text-xs text-gray-500">• {isProfessional ? "Pro" : "Particulier"}</span>
                  </div>
                  <p className="text-xs text-gray-600">
                    {nature}
                  </p>
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="icon" className="h-10 w-10 rounded-full hover:bg-indigo-50 hover:scale-110 transition-all" onClick={handleFavorite}>
                  <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
                </Button>
                <Button variant="ghost" size="icon" className="h-10 w-10 rounded-full hover:bg-indigo-50 hover:scale-110 transition-all" onClick={handleShare}>
                  <Share2 className="w-5 h-5 text-gray-400" />
                </Button>
              </div>
            </div>

            <div className="mt-4">
              {/* Badges */}
              <div className="flex items-center gap-2 mb-4 flex-wrap">
                <Badge className="bg-gradient-to-r from-indigo-500 to-indigo-600 text-white border-0 shadow-md">
                  {category}
                </Badge>
                {specificInfo.slice(0, 2).map((info: string, index: number) => (
                  <Badge key={index} className="bg-gray-100 text-gray-700 border-0">
                    {info}
                  </Badge>
                ))}
                {isExpired && (
                  <Badge className="bg-red-600 text-white border-0 shadow-md">EXPIRÉ</Badge>
                )}
              </div>

              {/* Title */}
              <h3
                className={`text-2xl font-bold mb-3 line-clamp-2 group-hover:text-indigo-600 transition-colors ${
                  isExpired ? "text-gray-400" : "text-gray-900"
                }`}
              >
                {displayTitle}
              </h3>

              {/* Meta info */}
              <div className="flex items-center gap-4 text-sm text-gray-600 mb-4">
                {location && (
                  <div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-indigo-500" />
                    <span>{location}</span>
                  </div>
                )}
                {inquiry.ray && (
                  <div className="flex items-center gap-2">
                    <Locate className="w-4 h-4 text-indigo-500" />
                    <span>{inquiry.ray === "0" ? "Toute la France" : `Rayon ${inquiry.ray}km`}</span>
                  </div>
                )}
              </div>

              {/* Description */}
              <p className="text-gray-600 text-sm mb-4 line-clamp-2 leading-relaxed">{getCleanDescription()}</p>

              {/* Footer with actions */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-1 text-gray-500">
                    <MessageCircle className="w-4 h-4" />
                    <span>{commentsCount}</span>
                  </div>
                </div>

                <div className="flex flex-col gap-2">
                  <Button
                    size="sm"
                    className={
                      isExpired
                        ? "bg-gray-400 cursor-not-allowed text-white"
                        : "bg-indigo-600 hover:bg-indigo-700 text-white"
                    }
                    onClick={handleRespond}
                    disabled={isExpired}
                  >
                    {isExpired ? "Expiré" : "Voir la demande"}
                  </Button>
                  <span className="text-xs text-gray-500 text-right">{timeAgo}</span>
                </div>
              </div>
            </div>
          </div>
        </Card>
        </Link>
        <ShareModal
          isOpen={showShareModal}
          onClose={() => setShowShareModal(false)}
          title={displayTitle}
          url={`/announcements/inquiries/${inquiry.id}`}
          description={displayDescription}
        />
      </>
    )
  }

  // Grid view
  return (
    <>
      <Link href={`/announcements/inquiries/${inquiry.id}`}>
        <Card
          className={`h-full hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group cursor-pointer border-0 bg-white/90 backdrop-blur-md ${
            isExpired ? "opacity-60 grayscale" : "hover:shadow-indigo-200/60"
          }`}
        >
          <div className="p-5 h-full flex flex-col">
            {/* Header with user info */}
            <div className="flex items-start gap-3 mb-4">
              {userAvatar && !imageError ? (
                <img
                  src={userAvatar}
                  alt={userName}
                  className="w-12 h-12 rounded-full object-cover ring-2 ring-indigo-100 shadow-md"
                  onError={() => setImageError(true)}
                />
              ) : (
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center shadow-md ring-2 ring-indigo-100">
                  {isProfessional ? (
                    <Briefcase className="w-6 h-6 text-white" />
                  ) : (
                    <User className="w-6 h-6 text-white" />
                  )}
                </div>
              )}

              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between">
                  <div>
                    <div className="flex items-center gap-1.5 mb-0.5">
                      <p className="font-semibold text-gray-900 text-sm truncate">{userName}</p>
                      <span className="text-xs text-gray-500">• {isProfessional ? "Pro" : "Particulier"}</span>
                    </div>
                    <p className="text-xs text-gray-600">
                      {nature}
                    </p>
                  </div>
                  <div className="flex items-center gap-1">
                    <Button variant="ghost" size="icon" className="h-7 w-7 hover:bg-gray-100" onClick={handleFavorite}>
                      <Heart className={`w-3.5 h-3.5 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
                    </Button>
                    <Button variant="ghost" size="icon" className="h-7 w-7 hover:bg-gray-100" onClick={handleShare}>
                      <Share2 className="w-3.5 h-3.5 text-gray-400" />
                    </Button>
                  </div>
                </div>

                {/* Badges */}
                <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                  {isExpired && (
                    <Badge className="bg-red-600 text-white border-2 border-white font-bold text-xs">EXPIRÉ</Badge>
                  )}
                </div>
              </div>
            </div>

            {/* Title */}
            <h3
              className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-indigo-600 transition-colors ${
                isExpired ? "text-gray-400" : "text-gray-900"
              }`}
            >
              {displayTitle}
            </h3>

            {/* Meta info */}
            <div className="flex items-center gap-3 text-xs text-gray-500 mb-3">
              {location && (
                <div className="flex items-center gap-1">
                  <MapPin className="w-3.5 h-3.5" />
                  <span className="truncate">{location}</span>
                </div>
              )}
              {inquiry.ray && (
                <div className="flex items-center gap-1">
                  <Locate className="w-3.5 h-3.5" />
                  <span>{inquiry.ray === "0" ? "Toute la France" : `Rayon ${inquiry.ray}km`}</span>
                </div>
              )}
            </div>

            {/* Description */}
            <p className="text-sm text-gray-600 mb-4 line-clamp-3 leading-relaxed">{getCleanDescription()}</p>

            {/* Footer */}
            <div className="space-y-3 mt-auto">
              <div className="flex items-center justify-end text-sm">
                <div className="flex items-center gap-1 text-gray-500">
                  <MessageCircle className="w-4 h-4" />
                  <span>{commentsCount}</span>
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <Button
                  size="sm"
                  className={
                    isExpired
                      ? "w-full bg-gray-400 cursor-not-allowed text-white text-sm"
                      : "w-full bg-indigo-600 hover:bg-indigo-700 text-white text-sm"
                  }
                  onClick={handleRespond}
                  disabled={isExpired}
                >
                  {isExpired ? "Expiré" : "Voir la demande"}
                </Button>
                <span className="text-xs text-gray-500 text-center">{timeAgo}</span>
              </div>
            </div>
          </div>
        </Card>
      </Link>
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={displayTitle}
        url={`/announcements/inquiries/${inquiry.id}`}
        description={displayDescription}
      />
    </>
  )
}

function InquiriesHeader({
  searchQuery,
  setSearchQuery,
  totalInquiries,
}: { searchQuery: string; setSearchQuery: (query: string) => void; totalInquiries: number }) {
  return (
    <header className="w-full relative overflow-hidden text-white">
      {/* Background image avec overlay indigo */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/images/inquiries-background.jpg"
          alt="Background"
          fill
          className="object-cover"
          priority
        />
        {/* Overlay indigo semi-transparent */}
        <div className="absolute inset-0 bg-gradient-to-r from-indigo-600/85 to-indigo-500/85" />
      </div>
      
      <div className="container max-w-[1400px] mx-auto px-4 relative z-10 py-8 md:py-12 lg:py-16">
        <div className="flex flex-col md:flex-row items-start justify-between mb-6 md:mb-8 gap-4">
          <div className="flex items-start gap-3 md:gap-4">
            <div className="bg-white/20 backdrop-blur-sm p-3 md:p-4 rounded-2xl">
              <HelpCircle className="w-8 h-8 md:w-12 md:h-12 text-white" />
            </div>
            <div>
              <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold mb-1 md:mb-2">Demandes</h1>
              <p className="text-sm md:text-base lg:text-lg text-white/90">Posez vos questions et obtenez des réponses de notre communauté</p>
            </div>
          </div>
          <div className="flex gap-4 md:gap-8 text-right">
            <div>
              <div className="text-xl md:text-2xl lg:text-3xl font-bold">{totalInquiries}</div>
              <div className="text-xs md:text-sm text-white/80">Demandes actives</div>
            </div>
          </div>
        </div>

        <div className="relative max-w-3xl mx-auto">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <Input
            type="text"
            placeholder="Rechercher une demande, une catégorie..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-6 text-base rounded-xl border-0 shadow-lg focus:ring-2 focus:ring-indigo-300 text-gray-900 bg-white"
          />
        </div>
      </div>
    </header>
  )
}

function InquiriesToolbar({
  userId,
  router,
  showFilters,
  setShowFilters,
  filteredCount,
  sortBy,
  setSortBy,
  viewMode,
  setViewMode,
    searchQuery,
  location,
  radius,
  searchAllFrance,
  isGettingLocation,
}: {
  userId: string | null
  router: any
  showFilters: boolean
  setShowFilters: (show: boolean) => void
  filteredCount: number
  sortBy: string
  setSortBy: (sort: string) => void
  viewMode: "grid" | "list"
  setViewMode: (mode: "grid" | "list") => void

  searchQuery: string
  location: string
  radius: number
  searchAllFrance: boolean
  isGettingLocation: boolean
}) {
  const { toast } = useToast()

    const { canCreateAds, remainingAds, isPremium } = useSubscriptionLimits()
  const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

console.log('[Debug Permissions]', {
  profileType,
  isPremium,
  canCreateAds,
  remainingAds,
  shouldBeBlocked: profileType === 'professionnel' && !canCreateAds
})  

  const handleCreateAnnouncement = () => {
    if (!userId) {
      router.push("/login-required")
      return
    }

    if (!canCreateAds) {
      toast({
        title: "Limite d'annonces atteinte",
        description: "Vous avez atteint votre limite d'annonces pour ce mois. Souscrivez à un abonnement pour créer plus d'annonces.",
        variant: "destructive",
      })
      return
    }

    router.push("/announcements/create/inquiries")
  }

  const handleCreateAlert = () => {
    if (!userId) {
      toast({
        title: "Connexion requise",
        description: "Vous devez être connecté pour créer une alerte.",
        variant: "destructive",
      })
      return
    }
    toast({
      title: "Alerte créée",
      description: "Vous serez notifié des nouvelles demandes.",
    })
  }

  return (
    <div className="bg-white border-b sticky top-16 z-10 shadow-sm">
      <div className="container max-w-[1400px] mx-auto px-4 py-3 md:py-4">
        {/* First row: Action buttons */}
        <div className="flex flex-wrap gap-2 md:gap-3 mb-3 md:mb-4">
          <FeatureGuard feature="ads">
          <Button onClick={handleCreateAnnouncement} className="bg-indigo-500 hover:bg-indigo-600 text-white text-sm" size="sm">
            <Plus className="w-4 h-4 mr-2" />
            <span className="hidden sm:inline">Poster une demande</span>
            <span className="sm:hidden">Poster</span>
          </Button>
            </FeatureGuard>
          <SaveSearchButton
                searchTerm={searchQuery}
                category={"demandes"}
                location={location}
                radius={radius}
                searchAllFrance={searchAllFrance}
                useGeolocation={isGettingLocation}
                userPosition={null}
                currentUrl={typeof window !== "undefined" ? window.location.href : ""}
                className="ml-auto"
          />
        </div>

        {/* Second row: Filters, sort, and view toggle */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div className="flex flex-wrap items-center gap-2 md:gap-4">
            <Button variant="outline" onClick={() => setShowFilters(!showFilters)} className="flex items-center gap-2 text-sm" size="sm">
              <Filter className="w-4 h-4" />
              Filtres
              {showFilters ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            </Button>
            <span className="text-xs md:text-sm text-gray-600">
              <span className="font-semibold">{filteredCount}</span> demandes
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-2 md:gap-4">
            <div className="flex items-center gap-2">
              <span className="text-xs md:text-sm text-gray-600 whitespace-nowrap">Trier:</span>
              <Select value={sortBy} onValueChange={setSortBy}>
                <SelectTrigger className="w-[140px] md:w-[180px] text-xs md:text-sm">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="recent">📅 Plus récents</SelectItem>
                  <SelectItem value="budget-high">💎 Budget décroissant</SelectItem>
                  <SelectItem value="budget-low">💰 Budget croissant</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="flex gap-1 border rounded-lg p-1">
              <Button
                variant={viewMode === "grid" ? "default" : "ghost"}
                size="sm"
                onClick={() => setViewMode("grid")}
                className={viewMode === "grid" ? "bg-indigo-500 hover:bg-indigo-600" : ""}
              >
                <Grid3x3 className="w-4 h-4" />
              </Button>
              <Button
                variant={viewMode === "list" ? "default" : "ghost"}
                size="sm"
                onClick={() => setViewMode("list")}
                className={viewMode === "list" ? "bg-indigo-500 hover:bg-indigo-600" : ""}
              >
                <List className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function FiltersSection({
  location,
  setLocation,
  radius,
  setRadius,
  searchAllFrance,
  setSearchAllFrance,
  selectedCategory,
  setSelectedCategory,
  onReset,
  citySearchTerm,
  setCitySearchTerm,
  showCitySuggestions,
  setShowCitySuggestions,
  citySuggestions,
  setSearchCoords,
}: {
  location: string
  setLocation: (location: string) => void
  radius: number
  setRadius: (radius: number) => void
  searchAllFrance: boolean
  setSearchAllFrance: (search: boolean) => void
  selectedCategory: string
  setSelectedCategory: (category: string) => void
  onReset: () => void
  citySearchTerm: string
  setCitySearchTerm: (term: string) => void
  showCitySuggestions: boolean
  setShowCitySuggestions: (show: boolean) => void
  citySuggestions: any[]
  setSearchCoords: (coords: { lat: number; lng: number }) => void
}) {
  const [isGettingLocation, setIsGettingLocation] = useState(false)
  const { toast } = useToast()

  const onUseGeolocation = () => {
    if (!navigator.geolocation) {
      toast({
        title: "Géolocalisation non disponible",
        description: "Votre navigateur ne supporte pas la géolocalisation.",
        variant: "destructive",
      })
      return
    }

    setIsGettingLocation(true)
    navigator.geolocation.getCurrentPosition(
      async (position) => {
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.coords.latitude}&lon=${position.coords.longitude}`,
          )
          const data = await response.json()
          const city = data.address.city || data.address.town || data.address.village || ""
          setLocation(city)
          toast({
            title: "Position détectée",
            description: `Votre position: ${city}`,
          })
        } catch (error) {
          toast({
            title: "Erreur",
            description: "Impossible de récupérer votre position.",
            variant: "destructive",
          })
        } finally {
          setIsGettingLocation(false)
        }
      },
      () => {
        setIsGettingLocation(false)
        toast({
          title: "Erreur",
          description: "Impossible d'accéder à votre position.",
          variant: "destructive",
        })
      },
    )
  }

  return (
    <div className="bg-white border-b">
      <div className="container max-w-[1400px] mx-auto px-4 py-6">
        <div className="space-y-6">
          {/* Location input with geolocation */}
          <div className="flex gap-2">
            <div className="relative flex-1">
              <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 z-10" />
              <Input
                type="text"
                placeholder="Ville, code postal..."
                value={citySearchTerm || location}
                onChange={(e) => {
                  const value = e.target.value
                  setCitySearchTerm(value)
                  setLocation(value)
                  setShowCitySuggestions(value.length >= 2)
                }}
                onFocus={() => (citySearchTerm || location).length >= 2 && setShowCitySuggestions(true)}
                onBlur={() => setTimeout(() => setShowCitySuggestions(false), 200)}
                disabled={searchAllFrance}
                className="pl-10"
              />
              
              {/* Suggestions de villes */}
              {showCitySuggestions && citySuggestions.length > 0 && (
                <div className="absolute z-50 mt-1 w-full bg-white border border-gray-200 rounded-md shadow-lg max-h-60 overflow-auto">
                  {citySuggestions.map((city: any, index: number) => (
                    <button
                      key={`${city.name}-${city.zipcode}-${index}`}
                      type="button"
                      className="w-full px-4 py-2 text-left hover:bg-gray-50 flex items-center justify-between"
                      onClick={async () => {
                        const cityValue = `${city.name} (${city.zipcode})`
                        setCitySearchTerm(cityValue)
                        setLocation(cityValue)
                        setShowCitySuggestions(false)
                        
                        // Géocoder la ville pour obtenir les coordonnées
                        try {
                          const response = await fetch(
                            `https://nominatim.openstreetmap.org/search?city=${encodeURIComponent(city.name)}&postalcode=${city.zipcode}&country=France&format=json&limit=1`,
                            {
                              headers: {
                                'User-Agent': 'MyReklam-Web'
                              }
                            }
                          )
                          const data = await response.json()
                          
                          if (data && data.length > 0) {
                            // Mettre à jour le state avec les coordonnées GPS
                            setSearchCoords({
                              lat: parseFloat(data[0].lat),
                              lng: parseFloat(data[0].lon)
                            })
                            // Mettre à jour l'URL avec les coordonnées GPS
                            const newParams = new URLSearchParams(window.location.search)
                            newParams.set("location", cityValue)
                            newParams.set("lat", data[0].lat)
                            newParams.set("lng", data[0].lon)
                            window.history.pushState({}, '', `?${newParams.toString()}`)
                          }
                        } catch (error) {
                          console.error('Erreur de géocodage:', error)
                        }
                      }}
                    >
                      <div>
                        <div className="font-medium">{city.name}</div>
                        <div className="text-sm text-gray-500">{city.region}</div>
                      </div>
                      <div className="text-sm text-gray-400">{city.zipcode}</div>
                    </button>
                  ))}
                </div>
              )}
            </div>
            <Button
              variant="outline"
              size="icon"
              onClick={onUseGeolocation}
              disabled={isGettingLocation || searchAllFrance}
              className="flex-shrink-0 bg-transparent"
            >
              {isGettingLocation ? (
                <div className="w-4 h-4 border-2 border-gray-300 border-t-indigo-600 rounded-full animate-spin" />
              ) : (
                <Locate className="w-4 h-4" />
              )}
            </Button>
          </div>

          {/* Radius slider */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-medium text-gray-700">Rayon de recherche</label>
              <span className="text-sm font-semibold text-indigo-600">{radius} km</span>
            </div>
            <Slider
              value={[radius]}
              onValueChange={(value) => setRadius(value[0])}
              max={200}
              step={5}
              disabled={searchAllFrance}
              className="w-full"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>0 km</span>
              <span>50 km</span>
              <span>100 km</span>
              <span>150 km</span>
              <span>200 km</span>
            </div>
          </div>

          {/* Search all France checkbox */}
          <div className="flex items-center space-x-2">
            <Checkbox
              id="searchAllFrance"
              checked={searchAllFrance}
              onCheckedChange={(checked) => setSearchAllFrance(checked as boolean)}
            />
            <label htmlFor="searchAllFrance" className="text-sm font-medium cursor-pointer">
              Rechercher dans toute la France
            </label>
          </div>

          {/* Filter dropdowns */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Select value={selectedCategory} onValueChange={setSelectedCategory}>
              <SelectTrigger>
                <SelectValue placeholder="Toutes les catégories" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes les catégories</SelectItem>
                <SelectItem value="JobSearchInternship">Emploi</SelectItem>
                <SelectItem value="Training">Formation</SelectItem>
                <SelectItem value="ServicesAssistance">Services</SelectItem>
                <SelectItem value="RealEstateInvestment">Immobilier</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Reset filters */}
          <div className="flex justify-end">
            <Button variant="link" onClick={onReset} className="text-indigo-600 hover:text-indigo-700">
              <X className="w-4 h-4 mr-1" />
              Réinitialiser les filtres
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function InquiriesPage() {
  const router = useRouter()
  const params = useSearchParams()

  const [searchQuery, setSearchQuery] = useState(params.get("q") || "")
  const [showFilters, setShowFilters] = useState(false)
  const [location, setLocation] = useState(params.get("location") || "")
  const [radius, setRadius] = useState(parseInt(params.get("radius") || "10"))
  const [searchAllFrance, setSearchAllFrance] = useState(params.get("allFrance") === "true")
  const [selectedCategory, setSelectedCategory] = useState("all")
  const [sortBy, setSortBy] = useState("recent")
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid")
  const [isGettingLocation, setIsGettingLocation] = useState(false)
  const [citySearchTerm, setCitySearchTerm] = useState("")
  const [showCitySuggestions, setShowCitySuggestions] = useState(false)
  
  // Coordonnées GPS de la recherche
  const [searchCoords, setSearchCoords] = useState({
    lat: parseFloat(params.get("lat") || "0"),
    lng: parseFloat(params.get("lng") || "0")
  })
  
  // Suggestions de villes basées sur la recherche
  const citySuggestions = useMemo(() => {
    if (!citySearchTerm || citySearchTerm.length < 2) return []
    const search = citySearchTerm.toLowerCase()
    return (citiesData as any[])
      .filter((city: any) => 
        city.name.toLowerCase().includes(search) || 
        city.zipcode.includes(search)
      )
      .slice(0, 10)
  }, [citySearchTerm])
  
  const [allInquiries, setAllInquiries] = useState<Inquiry[]>([])
  const [currentPage, setCurrentPage] = useState(1)
  const [inquiriesPerPage] = useState(20)
  const [userId, setUserId] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [showExpired, setShowExpired] = useState(true)

  useEffect(() => {
    if (typeof window !== "undefined") {
      setUserId(localStorage.getItem("profileId"))
    }
  }, [])

  // Initialiser les filtres depuis les paramètres URL
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    
    const searchQueryParam = urlParams.get("q")
    if (searchQueryParam) {
      setSearchQuery(searchQueryParam)
    }
    
    const locationParam = urlParams.get("location")
    if (locationParam) {
      setLocation(locationParam)
    }
    
    const radiusParam = urlParams.get("radius")
    if (radiusParam) {
      setRadius(parseInt(radiusParam))
    }
    
    const allFranceParam = urlParams.get("allFrance")
    if (allFranceParam === "true") {
      setSearchAllFrance(true)
      setLocation("")
    }
    
    // Initialiser les coordonnées GPS depuis l'URL
    const latParam = urlParams.get("lat")
    const lngParam = urlParams.get("lng")
    if (latParam && lngParam) {
      setSearchCoords({
        lat: parseFloat(latParam),
        lng: parseFloat(lngParam)
      })
    }
  }, [])

  useEffect(() => {
    const loadAllInquiries = async () => {
      setIsLoading(true)
      try {
        const response = await axios.post(
          `${API_URL}/Ads.php`,
          {
            Method: "readAdsByCriteria",
            category: "demandes",
          },
          {
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
            },
          }
        )
        
        console.log('readAdsByCriteria response:', response.data)
        
        if (response.data.status === "success" && response.data.ads) {
          // setAllInquiries(response.data.ads)
          const inquiries = response.data.ads
        
        // Charger les infos utilisateur pour chaque demande qui n'a pas de companyData
        const enrichedInquiries = await Promise.all(
          inquiries.map(async (inquiry: Inquiry) => {
            if (!inquiry.companyData && inquiry.userId) {
              try {
                const userResult = await fetchUserInfoById(inquiry.userId)
                if (userResult.success) {
                  return {
                    ...inquiry,
                    userInfo: userResult.userInfo
                  }
                }
              } catch (error) {
                console.error("Error fetching user info for inquiry:", inquiry.id, error)
              }
            }
            return inquiry
          })
        )
        console.log('enrichedInquiries', enrichedInquiries)
        setAllInquiries(enrichedInquiries)
     
        } else {
          console.error("Erreur lors du chargement des annonces:", response.data)
          setAllInquiries([])
        }
      } catch (error) {
        console.error("Exception lors du chargement des annonces:", error)
        setAllInquiries([])
      } finally {
        setIsLoading(false)
      }
    }
    loadAllInquiries()
  }, [])

   // Mise à jour du filtrage
  const filteredInquiries = useMemo(() => {
    if (allInquiries.length === 0) return []

    return allInquiries.filter((inquiry) => {
      // Filtrer les demandes sans titre valide
      const hasValidTitle = inquiry.inquiryTitle?.trim() || inquiry.title?.trim()
      if (!hasValidTitle) return false

      // Recherche étendue
      if (searchQuery) {
        const query = searchQuery.toLowerCase()
        const searchableText = `
          ${inquiry.inquiryTitle || inquiry.title || ''} 
          ${inquiry.inquiryDescription || inquiry.description || ''}
          ${getUserDisplayName(inquiry)}
          ${formatAddress(inquiry.address)}
          ${getInquiryCategory(inquiry)}
        `.toLowerCase()
        
        if (!searchableText.includes(query)) {
          return false
        }
      }

      if (selectedCategory !== "all" && inquiry.inquiryType !== selectedCategory) return false

      const isExpired = inquiry.endDate ? new Date(inquiry.endDate) < new Date() : false
      if (!showExpired && isExpired) return false

      // Filtre par localisation avec calcul de distance
      if (location && !searchAllFrance) {
        try {
          // Si on a des coordonnées de recherche valides et un rayon
          if (searchCoords.lat !== 0 && searchCoords.lng !== 0 && radius > 0) {
            // Extraire les coordonnées de la demande
            let inquiryLat = 0
            let inquiryLng = 0
            let inquiryCity = ""
            let inquiryZipcode = ""

            if (inquiry.address) {
              if (typeof inquiry.address === 'string') {
                try {
                  const addressObj = JSON.parse(inquiry.address)
                  inquiryLat = parseFloat(addressObj.latitude || addressObj.lat || 0)
                  inquiryLng = parseFloat(addressObj.longitude || addressObj.lng || addressObj.lon || 0)
                  inquiryCity = addressObj.city || ""
                  inquiryZipcode = addressObj.zipcode || ""
                } catch {
                  // Si le parsing échoue, continuer
                }
              } else if (typeof inquiry.address === 'object') {
                inquiryLat = parseFloat(inquiry.address.latitude || inquiry.address.lat || 0)
                inquiryLng = parseFloat(inquiry.address.longitude || inquiry.address.lng || inquiry.address.lon || 0)
                inquiryCity = inquiry.address.city || ""
                inquiryZipcode = inquiry.address.zipcode || ""
              }
            }

            // Si pas de coordonnées dans l'adresse, essayer avec les données de l'entreprise
            if ((inquiryLat === 0 || inquiryLng === 0) && inquiry.companyData) {
              inquiryLat = parseFloat((inquiry.companyData as any).latitude || (inquiry.companyData as any).lat || 0)
              inquiryLng = parseFloat((inquiry.companyData as any).longitude || (inquiry.companyData as any).lng || (inquiry.companyData as any).lon || 0)
            }

            // Si toujours pas de coordonnées, utiliser la table de correspondance ville/code postal
            if ((inquiryLat === 0 || inquiryLng === 0) && (inquiryCity || inquiryZipcode)) {
              const fallbackCoords = getCoordsFromAddress(inquiryCity, inquiryZipcode)
              if (fallbackCoords) {
                inquiryLat = fallbackCoords.lat
                inquiryLng = fallbackCoords.lng
              }
            }

            // Si on a des coordonnées valides pour la demande, calculer la distance
            if (inquiryLat !== 0 && inquiryLng !== 0) {
              const distance = calculateDistance(searchCoords.lat, searchCoords.lng, inquiryLat, inquiryLng)
              
              // Filtrer si la distance est supérieure au rayon
              if (distance > radius) {
                return false
              }
            }
            // Si pas de coordonnées GPS pour la demande, on l'inclut dans les résultats
          } else {
            // Pas de coordonnées GPS de recherche, ne pas filtrer par localisation
          }
        } catch (error) {
          console.error("Erreur lors du filtrage par localisation:", error)
        }
      }

      return true
    })
  }, [allInquiries, searchQuery, selectedCategory, showExpired, location, searchAllFrance, radius, searchCoords])

  const sortedInquiries = useMemo(() => {
    const sorted = [...filteredInquiries]
    switch (sortBy) {
      case "recent":
        return sorted.sort((a, b) => new Date(b.createdat || 0).getTime() - new Date(a.createdat || 0).getTime())
      case "budget-low":
        return sorted.sort((a, b) => {
          const budgetA = Math.max(Number.parseFloat(a.budgetMin || "0"), Number.parseFloat(a.budgetMax || "0"))
          const budgetB = Math.max(Number.parseFloat(b.budgetMin || "0"), Number.parseFloat(b.budgetMax || "0"))
          return budgetA - budgetB
        })
      case "budget-high":
        return sorted.sort((a, b) => {
          const budgetA = Math.max(Number.parseFloat(a.budgetMin || "0"), Number.parseFloat(a.budgetMax || "0"))
          const budgetB = Math.max(Number.parseFloat(b.budgetMin || "0"), Number.parseFloat(b.budgetMax || "0"))
          return budgetB - budgetA
        })
      default:
        return sorted
    }
  }, [filteredInquiries, sortBy])

  const paginationData = useMemo(() => {
    const indexOfLastInquiry = currentPage * inquiriesPerPage
    const indexOfFirstInquiry = indexOfLastInquiry - inquiriesPerPage
    const currentInquiries = sortedInquiries.slice(indexOfFirstInquiry, indexOfLastInquiry)
    const totalPages = Math.ceil(sortedInquiries.length / inquiriesPerPage)
    return { currentInquiries, totalPages }
  }, [sortedInquiries, currentPage, inquiriesPerPage])

  const handlePageChange = (page: number) => {
    if (page > 0 && page <= paginationData.totalPages) {
      setCurrentPage(page)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  const handleResetFilters = () => {
    setLocation("")
    setRadius(10)
    setSearchAllFrance(false)
    setSelectedCategory("all")
    setSearchQuery("")
    setShowExpired(true)
  }

    const { visibleItems: currentInquiries, hasMore, sentinelRef } = useInfiniteRender(sortedInquiries, 20)

  return (
    <Suspense fallback={<div>Chargement...</div>}>
      <div className="min-h-screen bg-gray-50">
        <InquiriesHeader searchQuery={searchQuery} setSearchQuery={setSearchQuery} totalInquiries={allInquiries.length} />
        <InquiriesToolbar
          userId={userId}
          router={router}
          showFilters={showFilters}
          setShowFilters={setShowFilters}
          filteredCount={sortedInquiries.length}
          sortBy={sortBy}
          setSortBy={setSortBy}
          viewMode={viewMode}
          setViewMode={setViewMode}

          searchQuery={searchQuery}
          location={location}
          radius={radius}
          searchAllFrance={searchAllFrance}
          isGettingLocation={isGettingLocation}
        />

        {showFilters && (
          <FiltersSection
            location={location}
            setLocation={setLocation}
            radius={radius}
            setRadius={setRadius}
            searchAllFrance={searchAllFrance}
            setSearchAllFrance={setSearchAllFrance}
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
            onReset={handleResetFilters}
            citySearchTerm={citySearchTerm}
            setCitySearchTerm={setCitySearchTerm}
            showCitySuggestions={showCitySuggestions}
            setShowCitySuggestions={setShowCitySuggestions}
            citySuggestions={citySuggestions}
            setSearchCoords={setSearchCoords}
          />
        )}

        <div className="bg-white border-b py-2">
          <div className="container max-w-[1400px] mx-auto px-4">
            <div className="flex items-center space-x-2">
              <Checkbox
                id="showExpired"
                checked={showExpired}
                onCheckedChange={(checked) => setShowExpired(checked as boolean)}
              />
              <label htmlFor="showExpired" className="text-sm text-gray-600 cursor-pointer">
                Afficher les demandes expirées
              </label>
            </div>
          </div>
        </div>

        <div className="container max-w-[1400px] mx-auto px-4 py-8">
          {isLoading ? (
            <div className="text-center py-20">
              <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-500 mx-auto mb-4" />
              <p className="text-gray-600">Chargement des demandes...</p>
            </div>
          // ) : paginationData.currentInquiries.length ? (
          ) : currentInquiries.length ? (
            <>
              <div
                className={
                  viewMode === "grid"
                    ? "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
                    : "space-y-4"
                }
              >
                {/* {paginationData.currentInquiries.map((inquiry, index) => ( */}
                 {currentInquiries.map((inquiry) => ( 
                  <motion.div
                    key={inquiry.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    // transition={{ delay: index * 0.05 }}
                  >
                    <InquiryCard inquiry={inquiry} viewMode={viewMode} />
                  </motion.div>
                ))}
              </div>

               {/* sentinel pour déclencher chargement */}
              <div ref={sentinelRef as any} className="h-8 flex items-center justify-center mt-8">
                {hasMore ? (
                  <div className="text-sm text-gray-500">Chargement...</div>
                ) : (
                  <div className="text-sm text-gray-400">Fin des résultats</div>
                )}
              </div>

              {/* {paginationData.totalPages > 1 && (
                <div className="flex justify-center items-center mt-12 gap-2">
                  <Button
                    variant="outline"
                    disabled={currentPage === 1}
                    onClick={() => handlePageChange(currentPage - 1)}
                    className="hover:bg-indigo-50"
                  >
                    Précédent
                  </Button>
                  <div className="flex gap-1">
                    {Array.from({ length: Math.min(paginationData.totalPages, 7) }, (_, i) => {
                      let page: number
                      if (paginationData.totalPages <= 7) {
                        page = i + 1
                      } else if (currentPage <= 4) {
                        page = i + 1
                      } else if (currentPage >= paginationData.totalPages - 3) {
                        page = paginationData.totalPages - 6 + i
                      } else {
                        page = currentPage - 3 + i
                      }

                      return (
                        <Button
                          key={page}
                          variant={page === currentPage ? "default" : "outline"}
                          onClick={() => handlePageChange(page)}
                          className={`w-10 ${page === currentPage ? "bg-indigo-500 hover:bg-indigo-600" : "hover:bg-indigo-50"}`}
                        >
                          {page}
                        </Button>
                      )
                    })}
                  </div>
                  <Button
                    variant="outline"
                    disabled={currentPage === paginationData.totalPages}
                    onClick={() => handlePageChange(currentPage + 1)}
                    className="hover:bg-indigo-50"
                  >
                    Suivant
                  </Button>
                </div>
              )} */}
            </>
          ) : (
            <div className="text-center py-20">
              <div className="mb-4">
                <HelpCircle className="w-20 h-20 text-gray-300 mx-auto" />
              </div>
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Aucune demande trouvée</h3>
              <p className="text-gray-500">Essayez de modifier vos filtres pour voir plus de résultats</p>
            </div>
          )}
        </div>
      </div>
    </Suspense>
  )
}