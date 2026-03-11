"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Gift, Briefcase, GraduationCap, Calendar, MessageSquare, ArrowRight, MapPin, Clock, Tag, User, Heart, Share2, MessageCircle, FileText, Wifi, Home, Euro, Building2, Users, Locate, HelpCircle } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import { fetchAnnoncements, toggleFavorite, fetchCommentsByAnnouncementId } from "@/lib/api"
import { labelObject } from "@/lib/constants/label-object"
import { config } from "@/lib/config"
import { cn, formatDateRelative } from "@/lib/utils"
import { ShareModal } from "@/components/share-modal"
import { toast } from "sonner"
import { useToast } from "@/hooks/use-toast"

const API_URL = config.API_URL

const categories = [
  { id: "bons-plans", label: "Les bons plans", icon: Gift, apiCategory: "bons_plans", path: "/bons-plans", detailPath: "deals" },
  {
    id: "offres-emploi",
    label: "Offres d'emploi",
    icon: Briefcase,
    apiCategory: "emplois",
    path: "/offres-emploi",
    detailPath: "jobs",
  },
  { id: "formations", label: "Formations", icon: GraduationCap, apiCategory: "formations", path: "/formations", detailPath: "trainings" },
  { id: "evenements", label: "Événements", icon: Calendar, apiCategory: "evenements", path: "/evenements", detailPath: "events" },
  { id: "demandes", label: "Demandes", icon: MessageSquare, apiCategory: "demandes", path: "/demandes", detailPath: "inquiries" },
]

function cleanDescription(description: string): string {
  if (!description) return ""
  const cleanText = description.replace(/<[^>]*>/g, " ")
  const normalized = cleanText.replace(/\s+/g, " ").trim()
  return normalized
}

function getTimeAgo(date: string) {
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

  if (typeof address === "string") {
    try {
      const parsed = JSON.parse(address)
      return formatAddress(parsed)
    } catch {
      return address
    }
  }

  if (typeof address === "object") {
    const parts = []
    if (address.line1) parts.push(address.line1)
    if (address.street || address.adresse) parts.push(address.street || address.adresse)
    if (address.city || address.ville) parts.push(address.city || address.ville)
    if (address.zipcode || address.postalCode || address.codepostal) {
      parts.push(address.zipcode || address.postalCode || address.codepostal)
    }
    return parts.filter(Boolean).join(", ")
  }
  return ""
}

function getLocationDisplay(item: any): string {
  const address = formatAddress(item.address)
  if (address && address !== "{}") {
    return address
  }

  if (item.isOnline) {
    if (item.brand) {
      let brandName = item.brand
      if (typeof brandName === "string") {
        brandName = brandName.replace(/[\[\]{}\"]/g, "").trim()
      }
      if (brandName) {
        return `En ligne - ${brandName}`
      }
    }
    return "En ligne"
  }

  if (item.brand) {
    let brandName = item.brand
    if (typeof brandName === "string") {
      brandName = brandName.replace(/[\[\]{}\"]/g, "").trim()
    }
    if (brandName) {
      return brandName
    }
  }

  return ""
}

function getImageUrl(imagePath: string | undefined | null): string {
  if (!imagePath) return ""

  // Si c'est déjà une URL complète, la retourner telle quelle
  if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
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
  return `${API_URL}${cleanPath}`
}

// Card pour les bons plans (design de /bons-plans)
function DealCard({ item, detailPath }: { item: any; detailPath: string }) {
  const [imageError, setImageError] = useState(false)
  const isExpired = item.endDate && new Date(item.endDate) < new Date()
  
  const finalPrice = item.finalPrice ? parseFloat(item.finalPrice) : null
  const initialPrice = item.initialPrice ? parseFloat(item.initialPrice) : null
  const discountPercentage =
    finalPrice !== null && initialPrice !== null && initialPrice > finalPrice
      ? Math.round(((initialPrice - finalPrice) / initialPrice) * 100)
      : 0

  return (
    <Link href={`/announcements/${detailPath}/${item.id}`}>
      <Card
        className={cn(
          "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group cursor-pointer border-2 min-w-0",
          isExpired ? "opacity-70 border-red-200 bg-gray-50/50" : "hover:border-green-200 border-gray-200"
        )}
      >
        {/* Image */}
        <div className="relative h-56 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
          {item.images && item.images.length > 0 && item.images[0] && !imageError ? (
            <Image
              src={getImageUrl(item.images[0])}
              alt={item.title}
              fill
              className={cn(
                "object-cover group-hover:scale-110 transition-transform duration-500",
                isExpired && "grayscale brightness-90"
              )}
              onError={() => setImageError(true)}
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50">
              <Tag className="w-20 h-20 text-green-300" />
            </div>
          )}

          {/* Category badge */}
          <div className="absolute top-3 left-3">
            <Badge className="backdrop-blur-sm shadow-md border-0 px-3 py-1 flex items-center gap-1 bg-white/95 text-gray-700">
              <Tag className="w-3 h-3" />
              {labelObject[item.dealCategory as keyof typeof labelObject] || item.dealCategory}
            </Badge>
          </div>

          {/* Discount badge */}
          {isExpired ? (
            <div className="absolute top-3 right-3">
              <Badge className="bg-red-500 text-white shadow-xl text-lg font-bold px-5 py-3 border-2 border-white">
                <Clock className="w-5 h-5 mr-1" />
                EXPIRÉ
              </Badge>
            </div>
          ) : discountPercentage > 0 ? (
            <div className="absolute top-3 right-3">
              <Badge className="bg-gradient-to-r from-orange-500 to-red-500 text-white shadow-lg text-lg font-bold px-4 py-2">
                -{discountPercentage}%
              </Badge>
            </div>
          ) : null}
        </div>

        {/* Content */}
        <div className="p-5 min-w-0">
          <h3 className={cn("font-bold text-lg mb-2 line-clamp-2 min-h-[3.5rem] break-words", isExpired && "text-gray-500")}>
            {item.title}
          </h3>

          {/* Category breadcrumb */}
          <div className="flex items-center gap-2 text-xs text-gray-600 mb-3 flex-wrap">
            <span>{labelObject[item.dealCategory as keyof typeof labelObject] || item.dealCategory}</span>
            {item.subCategory && (
              <>
                <span>•</span>
                <span>{labelObject[item.subCategory as keyof typeof labelObject] || item.subCategory}</span>
              </>
            )}
          </div>

          {item.description && (
            <p className={cn("text-sm mb-4 line-clamp-2 min-h-[2.5rem]", isExpired ? "text-gray-400" : "text-gray-600")}>
              {cleanDescription(item.description).substring(0, 150)}...
            </p>
          )}

          {/* Location */}
          {getLocationDisplay(item) && (
            <div className="flex items-center gap-1 text-xs text-gray-500 mb-3">
              <MapPin className="w-3 h-3" />
              <span className="truncate">{getLocationDisplay(item)}</span>
            </div>
          )}

          {/* Price */}
          <div className="flex items-baseline gap-2 mb-4">
            {finalPrice !== null && finalPrice === 0 ? (
              <Badge className="bg-green-600 text-white text-lg font-bold px-4 py-1">Gratuit</Badge>
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

          {/* Footer */}
          <div className="flex items-center justify-between pt-4 border-t">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1 text-gray-500">
                <MessageCircle className="w-4 h-4" />
                <span className="text-sm font-medium">0</span>
              </div>
            </div>
          </div>

          {/* Time */}
          {item.createdat && (
            <div className="flex items-center gap-1 text-xs text-gray-500 mt-3">
              <Clock className="w-3 h-3" />
              <span>{getTimeAgo(item.createdat)}</span>
            </div>
          )}
        </div>
      </Card>
    </Link>
  )
}

// Fonction helper pour obtenir les labels
const getLabel = (key: string): string => {
  return (labelObject as any)[key] || key
}

// Fonctions helper pour les demandes
function getUserDisplayName(inquiry: any): string {
  if (inquiry.userInfo) {
    const userInfo = inquiry.userInfo
    if (userInfo.profiletype === "professionnel") {
      return userInfo.nomsociete || "Entreprise"
    }
    return userInfo.pseudo || "Particulier"
  }
  if (!inquiry.companyData && inquiry.userId) {
    return "Utilisateur"
  }
  const companyData = inquiry.companyData
  if (!companyData) return "Demandeur"
  if (companyData.profiletype === "professionnel") {
    return companyData.nomsociete || "Entreprise"
  }
  return companyData.pseudo || "Particulier"
}

function getInquiryUserPhoto(inquiry: any): string | null {
  if (inquiry.userInfo?.photoprofilurl) {
    const photoUrl = inquiry.userInfo.photoprofilurl
    if (photoUrl.startsWith("http")) {
      return photoUrl
    }
    return `${API_URL}${photoUrl}`
  }
  const companyData = inquiry.companyData
  if (!companyData || !companyData.photoprofilurl) return null
  if (companyData.photoprofilurl.startsWith("http")) {
    return companyData.photoprofilurl
  }
  return `${API_URL}${companyData.photoprofilurl}`
}

function getInquiryTimeAgo(date: string): string {
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

function getInquiryCategory(inquiry: any): string {
  if (inquiry.inquiryType === "JobSearchInternship") {
    return "Emploi"
  }
  if (inquiry.inquiryType === "Training") {
    return "Formation"
  }
  if (inquiry.inquiryType === "ServicesAssistance") {
    return "Services"
  }
  if (inquiry.inquiryType === "RealEstateInvestment" || inquiry.inquiryType === "RealEstate") {
    return "Immobilier"
  }
  return inquiry.inquiryType ? (labelObject[inquiry.inquiryType as keyof typeof labelObject] || inquiry.inquiryType) : "Divers"
}

function getInquirySubCategory(inquiry: any): string | null {
  if (!inquiry.inquiryTypeCategory) return null
  return labelObject[inquiry.inquiryTypeCategory as keyof typeof labelObject] || inquiry.inquiryTypeCategory
}

function getInquiryNature(inquiry: any): string {
  return getInquiryCategory(inquiry)
}

function getBudgetDisplay(inquiry: any): string | null {
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

// Card pour les offres d'emploi (design exact de /offres-emploi en mode grille)
function JobCard({ item, detailPath }: { item: any; detailPath: string }) {
  const [isFavorite, setIsFavorite] = useState(item.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  
  // Fonction pour obtenir la photo
  const getUserPhoto = () => {
    const companyData = item.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    return companyData.photoprofilurl
  }

  // Fonction pour obtenir le nom d'affichage
  const getUserDisplayName = () => {
    // Essayer d'abord le champ business
    if (item.business) {
      try {
        if (typeof item.business === 'string') {
          // Format PostgreSQL: {"METZ EMPLOI"} ou {Myreklam}
          const cleaned = item.business.replace(/[{}"]/g, '').trim()
          if (cleaned) return cleaned
        }
      } catch (error) {
        console.warn('Erreur lors du parsing de business:', error)
      }
    }
    
    const companyData = item.companyData
    if (!companyData) return "Entreprise"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const isProfessional = item.companyData?.profiletype === "professionnel"
  const displayPhoto = getUserPhoto()

  // Calculate time ago
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

  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!item.description) return ""
    
    // Supprimer tous les tags HTML
    const cleanText = item.description.replace(/<[^>]*>/g, ' ')
    // Supprimer les espaces multiples
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  // Formater l'adresse depuis les données réelles
  const getFormattedLocation = () => {
    if (!item.location && !item.address) return ""
    
    const locationData = item.location || item.address
    
    if (typeof locationData === 'string') {
      try {
        // Essayer de parser si c'est du JSON
        const parsed = JSON.parse(locationData)
        return formatAddress(parsed)
      } catch {
        return locationData
      }
    }
    
    return formatAddress(locationData)
  }

  // Obtenir le type de temps de travail
  const getOccupationTimeLabel = () => {
    if (item.occupationTime === "fullTime") return "Temps plein"
    if (item.occupationTime === "partTime") return "Temps partiel"
    return null
  }

  // Utiliser les vraies données de salaire avec brut/net
  const getSalaryDisplay = () => {
    // Si salaire basé sur profil
    if (item.issalarybasedonprofile) return "Selon profil"
    
    // Ne rien afficher si aucune donnée de salaire n'est présente
    if (!item.minSalary && !item.maxSalary && !item.salary) return null
    
    // Déterminer le type de salaire (brut/net)
    const salaryType = item.netSalary === "raw" ? "brut" : item.netSalary === "net" ? "net" : ""
    
    // Déterminer la période
    let period = ""
    if (item.unitSalary === "years") period = " /an"
    else if (item.unitSalary === "month") period = " /mois"
    else if (item.unitSalary === "day" || item.unitSalary === "days") period = " /jour"
    else if (item.unitSalary === "hour" || item.unitSalary === "hours") period = " /heure"

    // Si salaryExact est true, afficher uniquement maxSalary
    const isSalaryExact = item.salaryExact === true || item.salaryExact === "true"
    
    if (isSalaryExact && item.maxSalary) {
      const max = parseFloat(item.maxSalary)
      if (max === 0) return null
      return `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    // Sinon afficher la fourchette
    if (item.minSalary && item.maxSalary && !isSalaryExact) {
      const min = parseFloat(item.minSalary)
      const max = parseFloat(item.maxSalary)
      if (min === 0 && max === 0) return null
      return `${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }
    
    if (item.minSalary) {
      const min = parseFloat(item.minSalary)
      if (min === 0) return null
      return `À partir de ${min.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    // Fallback sur item.salary si présent
    if (item.salary) return item.salary

    return null
  }

  // Parser les compétences
  const getSkills = () => {
    if (!item.skills) return []
    
    try {
      if (typeof item.skills === 'string') {
        // Si c'est une string, essayer de la parser comme JSON
        if (item.skills.startsWith('[') || item.skills.startsWith('{')) {
          return JSON.parse(item.skills)
        }
        // Sinon, diviser par des virgules ou retourner comme array
        return item.skills.split(',').map((s: string) => s.trim()).filter(Boolean)
      }
      
      if (Array.isArray(item.skills)) {
        return item.skills
      }
      
      return []
    } catch (error) {
      console.warn('Erreur lors du parsing des compétences:', error)
      return []
    }
  }

  // Parser les avantages
  const getBenefits = () => {
    if (!item.benefit && !item.benefits) return []
    
    const benefitData = item.benefit || item.benefits
    
    try {
      let rawBenefits = []
      if (typeof benefitData === 'string') {
        // Si c'est une string, essayer de la parser comme JSON
        if (benefitData.startsWith('[')) {
          rawBenefits = JSON.parse(benefitData)
        }
        else if (benefitData.startsWith('{')) {
          // Format PostgreSQL: {Bonuses,Commissions,flexibleHours}
          const cleaned = benefitData.replace(/[{}]/g, '')
          rawBenefits = cleaned.split(',').map((s: string) => s.trim()).filter(Boolean)
        }
        else {
          rawBenefits = benefitData.split(',').map((s: string) => s.trim()).filter(Boolean)
        }
      }
      else if (Array.isArray(benefitData)) {
        rawBenefits = benefitData
      }
          
      return rawBenefits.map((benefit: string) => getLabel(benefit))
    } catch (error) {
      console.warn('Erreur lors du parsing des avantages:', error)
      return []
    }
  }

  const skills = getSkills()
  const benefits = getBenefits()

  // Gérer le partage
  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
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
      const result = await toggleFavorite(userId, item.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Job] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, item.title)
        
        if (newFavoriteState) {
          toast.success("Ajouté aux favoris", {
            description: "Retrouvez cette offre dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=emplois"
            }
          })
        } else {
          toast.success("Retiré des favoris")
        }
      } else {
        toast.error("Erreur lors de la mise à jour du favori")
      }
    } catch (error) {
      console.error("[Favorite Job] Erreur:", error)
      toast.error("Erreur lors de la mise à jour du favori")
    }
  }

  return (
    <>
      <Link href={`/announcements/${detailPath}/${item.id}`}>
        <Card
          className={cn(
            "h-full hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 overflow-hidden group cursor-pointer flex flex-col border-2",
            isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-blue-200"
          )}
        >
        {/* Company Logo Header */}
        <div className="p-6 pb-4 border-b bg-gradient-to-br from-blue-50/30 to-white relative">
          {isExpired && (
            <div className="absolute top-3 left-3 z-10">
              <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
            </div>
          )}

          <div className="flex items-start justify-between mb-3">
            <div
              className={cn(
                "w-16 h-16 rounded-full border-4 border-white shadow-lg ring-2 ring-blue-100 flex items-center justify-center overflow-hidden",
                isExpired && "grayscale brightness-75"
              )}
            >
              {displayPhoto ? (
                <Image
                  src={displayPhoto.startsWith("http") ? displayPhoto : `${API_URL}${displayPhoto}`}
                  alt={getUserDisplayName()}
                  width={64}
                  height={64}
                  className="object-cover w-full h-full"
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                  {isProfessional ? <Briefcase className="w-8 h-8 text-white" /> : <User className="w-8 h-8 text-white" />}
                </div>
              )}
            </div>
            <div className="flex gap-1">
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8 rounded-full hover:bg-white"
                onClick={handleFavorite}
              >
                <Heart className={cn("w-4 h-4", isFavorite ? "fill-red-500 text-red-500" : "text-gray-400")} />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8 rounded-full hover:bg-white"
                onClick={handleShare}
              >
                <Share2 className="w-4 h-4 text-gray-400" />
              </Button>
            </div>
          </div>

          <h3
            className={cn(
              "font-bold text-xl mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors",
              isExpired ? "text-gray-500" : "text-gray-900"
            )}
          >
            {item.title}
          </h3>
          <div className="flex items-center gap-2">
            <p className="text-sm text-gray-700 font-semibold">{getUserDisplayName()}</p>
            {isProfessional && (
              <Badge className="bg-blue-50 text-blue-700 border-blue-200 text-xs">Pro</Badge>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="p-6 flex-1 flex flex-col">
          {/* Key Info - Badges */}
          <div className="flex flex-wrap items-center gap-2 mb-4">
            {/* Type de contrat */}
            {item.contractType && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <FileText className="w-3 h-3 mr-1 inline" />
                {labelObject[item.contractType as keyof typeof labelObject] || item.contractType}
              </Badge>
            )}

            {/* Localisation */}
            {getFormattedLocation() && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <MapPin className="w-3 h-3 mr-1 inline" />
                {getFormattedLocation()}
              </Badge>
            )}

            {/* Niveau d'études */}
            {item.studyLevel && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <GraduationCap className="w-3 h-3 mr-1 inline" />
                {labelObject[item.studyLevel as keyof typeof labelObject] || item.studyLevel}
              </Badge>
            )}

            {/* Niveau d'expérience */}
            {item.xpLevel && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <Briefcase className="w-3 h-3 mr-1 inline" />
                {labelObject[item.xpLevel as keyof typeof labelObject] || item.xpLevel}
              </Badge>
            )}

            {/* Temps de travail */}
            {getOccupationTimeLabel() && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <Clock className="w-3 h-3 mr-1 inline" />
                {getOccupationTimeLabel()}
              </Badge>
            )}

            {/* Télétravail */}
            {item.remote !== null && item.remote !== undefined && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                {item.remote === 't' || item.remote === true ? (
                  <>
                    <Wifi className="w-3 h-3 mr-1 inline" />
                    Télétravail possible
                  </>
                ) : (
                  <>
                    <Home className="w-3 h-3 mr-1 inline" />
                    Présentiel uniquement
                  </>
                )}
              </Badge>
            )}

            {/* Salaire */}
            {getSalaryDisplay() && (
              <Badge className="bg-green-50 text-green-700 border-green-200 text-xs">
                <Euro className="w-3 h-3 mr-1 inline" />
                {getSalaryDisplay()}
              </Badge>
            )}
          </div>

          {/* Description */}
          <p className="text-sm text-gray-700 mb-4 line-clamp-3 flex-1 leading-relaxed">{getCleanDescription()}</p>

          {/* Skills */}
          {skills.length > 0 && (
            <div className="mb-4">
              <p className="text-xs font-semibold text-gray-900 mb-2 flex items-center gap-1">
                <span className="w-0.5 h-3 bg-blue-500 rounded"></span>
                Compétences
              </p>
              <div className="flex flex-wrap gap-1.5">
                {skills.slice(0, 3).map((skill: string, idx: number) => (
                  <Badge key={idx} className="bg-blue-50 text-blue-700 border-blue-200 text-xs px-2 py-0.5">
                    {skill}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          {/* Benefits */}
          {benefits.length > 0 && (
            <div className="mb-4">
              <p className="text-xs font-semibold text-gray-900 mb-2 flex items-center gap-1">
                <span className="w-0.5 h-3 bg-green-500 rounded"></span>
                Avantages
              </p>
              <div className="flex flex-wrap gap-1.5">
                {benefits.slice(0, 3).map((benefit: string, idx: number) => (
                  <Badge key={idx} className="bg-green-50 text-green-700 border-green-200 text-xs px-2 py-0.5">
                    {benefit}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          {/* Footer */}
          <div className="flex items-center justify-between pt-4 border-t mt-auto">
            {item.createdat && (
              <div className="flex items-center gap-1.5 text-xs text-gray-600">
                <Clock className="w-3.5 h-3.5" />
                <span>{getTimeAgo(item.createdat)}</span>
              </div>
            )}
            <Button
              size="sm"
              className={cn(
                "text-xs px-4",
                isExpired ? "bg-gray-400 cursor-not-allowed" : "bg-blue-500 hover:bg-blue-600 text-white"
              )}
              disabled={isExpired}
            >
              {isExpired ? "Expiré" : "Voir l'offre"}
            </Button>
          </div>
        </div>
      </Card>
    </Link>
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={item.title}
        url={`/announcements/jobs/${item.id}`}
        description={item.description}
      />
    </>
  )
}

// Fonction helper pour obtenir le nom de l'organisation (formations)
function getOrganizationName(training: any): string {
  return training.companyData?.nomsociete || training.userNomsociete || training.userPseudo || "Centre de formation"
}

// Card pour les formations (design exact de /formations en mode grille)
function TrainingCard({ item, detailPath }: { item: any; detailPath: string }) {
  const [isFavorite, setIsFavorite] = useState(item.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  const organizationName = getOrganizationName(item)
  
  const getTimeAgo = (date: string) => {
    if (!date) return "Récemment"
    const now = new Date()
    const created = new Date(date)
    const diffMs = now.getTime() - created.getTime()
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
    const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
    const diffMonths = Math.floor(diffDays / 30)
    if (diffMonths > 0) return `Il y a ${diffMonths} mois`
    if (diffDays > 0) return `Il y a ${diffDays} jour${diffDays > 1 ? "s" : ""}`
    if (diffHours > 0) return `Il y a ${diffHours} heure${diffHours > 1 ? "s" : ""}`
    return "Aujourd'hui"
  }
  
  const timeAgo = getTimeAgo(item.createdat)
  
  // Gérer le partage
  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
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
      const result = await toggleFavorite(userId, item.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Training] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, item.title)
        
        if (newFavoriteState) {
          toast.success("Ajouté aux favoris", {
            description: "Retrouvez cette formation dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=formations"
            }
          })
        } else {
          toast.success("Retiré des favoris")
        }
      }
    } catch (error) {
      console.error("[Favorite Training] Erreur:", error)
      toast.error("Erreur lors de la mise à jour du favori")
    }
  }

  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!item.description) return ""
    const cleanText = item.description.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  // Parser le public cible
  const getTrainingPublicArray = () => {
    if (!item.trainingPublic) return []
    try {
      const cleaned = item.trainingPublic.replace(/[{}]/g, '')
      const publics = cleaned.split(',').map((p: string) => p.trim()).filter(Boolean)
      
      if (publics.includes('AllPublic')) {
        return ['Tout public']
      }
      
      const publicLabels: { [key: string]: string } = {
        'Employed': 'Salarié',
        'JobSeeker': 'Demandeur d\'emploi',
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

  // Formater la durée en heures
  const getFormattedDuration = () => {
    if (!item.durationInH) return null
    const hours = parseFloat(item.durationInH)
    if (isNaN(hours) || hours === 0) return null
    return `${hours}h`
  }

  // Obtenir le type de formation
  const getTrainingType = () => {
    if (!item.trainingType) return null
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
    return typeLabels[item.trainingType] || `${item.trainingType} (${item.trainingType})`
  }

  const trainingTypeLabel = getTrainingType()

  // Fonction pour obtenir la photo de l'organisateur
  const getOrganizerPhoto = () => {
    const companyData = item.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    
    if (companyData.photoprofilurl.startsWith("http")) {
      return companyData.photoprofilurl
    }
    
    return `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = item.companyData?.profiletype === "professionnel"

  // Obtenir la localisation formatée
  const getFormattedLocation = () => {
    if (item.address) {
      return formatAddress(item.address)
    }
    if (item.location) {
      return formatAddress(item.location)
    }
    return null
  }

  return (
    <>
      <Link href={`/announcements/${detailPath}/${item.id}`}>
        <Card
          className={`h-full hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer min-w-0 ${
            isExpired ? "opacity-75 border-2 border-red-500" : ""
          }`}
        >
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
              {item.trainingLevel && (
                <Badge variant="secondary" className="bg-purple-100 text-purple-700 border-purple-200 text-xs">
                  {item.trainingLevel}
                </Badge>
              )}
              <button
                className="h-8 w-8 hover:bg-gray-100 rounded-full flex items-center justify-center"
                onClick={handleFavorite}
              >
                <Heart className={`w-4 h-4 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
              </button>
              <button
                className="h-8 w-8 hover:bg-gray-100 rounded-full flex items-center justify-center"
                onClick={handleShare}
              >
                <Share2 className="w-4 h-4 text-gray-400" />
              </button>
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
            {item.title}
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
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={item.title}
        url={`/announcements/trainings/${item.id}`}
        description={item.description}
      />
    </>
  )
}

// Card pour les événements (design exact de /evenements en mode grille)
function EventCard({ item, detailPath }: { item: any; detailPath: string }) {
  const [isFavorite, setIsFavorite] = useState(item.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [imageError, setImageError] = useState(false)
  const [commentsCount, setCommentsCount] = useState(0)
  const { toast: toastHook } = useToast()

  useEffect(() => {
    const fetchCommentsCount = async () => {
      try {
        const result = await fetchCommentsByAnnouncementId(item.id)
        if (result.success) {
          setCommentsCount(result.comments.length)
        }
      } catch (error) {
        console.error("Erreur lors de la récupération des commentaires:", error)
      }
    }
    fetchCommentsCount()
  }, [item.id])

  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!item.description) return ""
    const cleanText = item.description.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  // Gérer le partage
  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
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
      const result = await toggleFavorite(userId, item.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Event] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, item.title)
        
        if (newFavoriteState) {
          toast.success("Ajouté aux favoris", {
            description: "Retrouvez cette annonce dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=evenements"
            }
          })
        } else {
          toast.success("Retiré des favoris")
        }
      } else {
        toast.error("Erreur lors de la mise à jour du favori")
      }
    } catch (error) {
      console.error("[Favorite Event] Erreur:", error)
      toast.error("Erreur lors de la mise à jour du favori")
    }
  }

  // Un événement permanent n'expire jamais
  const isExpired = (item.eventDurationType === "permanent" || item.isAllDays) 
    ? false 
    : (item.endDate ? new Date(item.endDate) < new Date() : false)
  const isFull =
    item.eventMaxAttendees &&
    item.eventCurrentAttendees &&
    Number.parseInt(item.eventCurrentAttendees) >= Number.parseInt(item.eventMaxAttendees)

  // Déterminer le statut de l'événement
  const getEventStatus = () => {
    if (isExpired) return { label: "Passé", color: "bg-gray-500" }
    if (isFull) return { label: "Complet", color: "bg-red-500" }

    if (item.eventDurationType === "permanent" || item.isAllDays) {
      return { label: "Permanent", color: "bg-blue-500" }
    }

    const eventDate = item.eventDate || item.startDate
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

  // Obtenir le nom de l'organisateur
  const getOrganizerName = () => {
    const companyData = item.companyData
    if (!companyData) return "Organisateur"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || item.userPseudo || "Particulier"
  }

  const getOrganizerPhoto = () => {
    const companyData = item.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    
    return companyData.photoprofilurl.startsWith("http") 
      ? companyData.photoprofilurl 
      : `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = item.companyData?.profiletype === "professionnel"

  // Formater la date de l'événement
  const formatEventDate = () => {
    if (item.eventDurationType === "permanent" || item.isAllDays) {
      return "Permanent"
    }
    
    const eventDate = item.eventDate || item.startDate
    if (!eventDate) return "Date à définir"
    
    const date = new Date(eventDate)
    return date.toLocaleDateString("fr-FR", { 
      day: "numeric", 
      month: "long", 
      year: "numeric" 
    })
  }

  // Obtenir la localisation formatée
  const getFormattedLocation = () => {
    if (item.eventCity) return item.eventCity
    if (item.eventLocation) {
      if (typeof item.eventLocation === 'string') {
        return item.eventLocation
      }
      return formatAddress(item.eventLocation)
    }
    
    if (item.address) {
      return formatAddress(item.address)
    }
    
    return null
  }

  // Obtenir le nombre de participants
  const getParticipantsDisplay = () => {
    const current = Number.parseInt(item.eventCurrentAttendees || "0")
    const max = Number.parseInt(item.eventMaxAttendees || "0")
    
    if (max > 0) {
      return `${current}/${max} participants`
    } else if (current > 0) {
      return `${current} participant${current > 1 ? 's' : ''}`
    }
    
    return null
  }

  // Obtenir le prix formaté
  const getFormattedPrice = () => {
    const price = item.eventPrice || item.price
    const priceType = item.priceType
    
    // Normaliser priceType en string pour la comparaison
    const normalizedPriceType = priceType ? String(priceType) : null
    
    // Règle métier:
    // - priceType = "1" ET price > 0 → Afficher le prix
    // - priceType = "1" ET price = 0 → "Non précisé"
    // - priceType = "2" ou "0" → "Gratuit"
    // - priceType = null/undefined → Rétrocompatibilité (si price > 0 → afficher prix, sinon gratuit)
    
    if (normalizedPriceType === "1") {
      // Payant
      const numPrice = Number.parseFloat(price || 0)
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
      const numPrice = Number.parseFloat(price || 0)
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

  // Obtenir la catégorie affichée avec traduction
  const getDisplayCategory = () => {
    const eventType = item.eventType || item.eventCategory || item.category
    return (labelObject as any)[eventType] || eventType
  }

  // Obtenir la sous-catégorie traduite
  const getDisplaySubCategory = () => {
    if (!item.subCategory) return null
    return (labelObject as any)[item.subCategory] || item.subCategory
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

  const imageUrl = item.images && item.images[0] ? getImageUrl(item.images[0]) : null

  const handleCardClick = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement
    if (target.closest("button")) {
      return
    }
    window.location.href = `/announcements/${detailPath}/${item.id}`
  }

  return (
    <>
      <Card
        className={`flex flex-col h-full min-h-[400px] hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group cursor-pointer border-0 bg-white/90 backdrop-blur-md min-w-0 ${
          isExpired ? "opacity-60 grayscale" : "hover:shadow-orange-200/60"
        }`}
        onClick={handleCardClick}
      >
        {/* Image with overlays */}
        <div className="relative h-56 bg-gradient-to-br from-orange-100 via-orange-50 to-pink-50 overflow-hidden">
          {isExpired && (
            <div className="absolute inset-0 bg-black/40 z-20 flex items-center justify-center">
              <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
            </div>
          )}
          {imageUrl && !imageError ? (
            <img
              src={imageUrl}
              alt={item.title}
              className={`w-full h-full object-cover group-hover:scale-110 transition-transform duration-300 ${
                isExpired ? "grayscale brightness-75" : ""
              }`}
              onError={() => setImageError(true)}
            />
          ) : (
            <div
              className={`w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-100 to-orange-50 ${
                isExpired ? "grayscale brightness-75" : ""
              }`}
            >
              <Calendar className="w-16 h-16 text-orange-300" />
            </div>
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

          {/* Action buttons */}
          <div className="absolute bottom-3 right-3 flex gap-2 z-10">
            <Button
              variant="ghost"
              size="icon"
              className="h-10 w-10 rounded-full bg-white/95 hover:bg-white shadow-lg backdrop-blur-md hover:scale-110 transition-all duration-300"
              onClick={handleFavorite}
            >
              <Heart className={`w-4 h-4 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-600"}`} />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 rounded-full bg-white/90 hover:bg-white shadow-md"
              onClick={handleShare}
            >
              <Share2 className="w-4 h-4 text-gray-600" />
            </Button>
          </div>
        </div>

        {/* Content */}
        <div className="p-4 flex-1 flex flex-col">
          {/* Title and organizer */}
          <h3
            className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-orange-600 transition-colors ${
              isExpired ? "text-gray-500" : "text-gray-900"
            }`}
          >
            {item.title}
          </h3>

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
            
            {(item.eventType || item.subCategory) && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <span className="font-medium text-xs truncate">{getDisplayCategory()}</span>
                {item.subCategory && item.eventType && <span className="flex-shrink-0">·</span>}
                {item.subCategory && <span className="text-xs truncate">{getDisplaySubCategory()}</span>}
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
          <div className={`text-2xl font-bold mb-4 mt-auto ${
            isExpired ? "text-gray-400 line-through" : "text-orange-600"
          }`}>
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
            Publié {formatDateRelative(item.createdat)}
          </p>
        </div>
      </Card>
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={item.title}
        url={`/announcements/events/${item.id}`}
        description={item.description}
      />
    </>
  )
}

// Card pour les demandes (design exact de /demandes en mode grille)
function InquiryCard({ item, detailPath }: { item: any; detailPath: string }) {
  const [isFavorite, setIsFavorite] = useState(item.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [imageError, setImageError] = useState(false)
  const [commentsCount, setCommentsCount] = useState(0)
  const router = useRouter()

  useEffect(() => {
    const fetchCommentsCount = async () => {
      try {
        const result = await fetchCommentsByAnnouncementId(item.id)
        if (result.success) {
          setCommentsCount(result.comments.length)
        }
      } catch (error) {
        console.error("Erreur lors de la récupération des commentaires:", error)
      }
    }
    fetchCommentsCount()
  }, [item.id])

  const displayTitle = item.inquiryTitle || item.title || "Demande sans titre"
  const displayDescription = item.inquiryDescription || item.description || "Aucune description disponible"

  const getCleanDescription = () => {
    if (!displayDescription) return ""
    const cleanText = displayDescription.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

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
      const result = await toggleFavorite(userId, item.id, newFavoriteState)
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

  const userName = getUserDisplayName(item)
  const userAvatar = getInquiryUserPhoto(item)
  const timeAgo = item.createdat ? getInquiryTimeAgo(item.createdat) : ""
  const category = getInquiryCategory(item)
  const subCategory = getInquirySubCategory(item)
  const nature = getInquiryNature(item)
  const budget = getBudgetDisplay(item)
  const location = formatAddress(item.address)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  const isProfessional = item.userInfo?.profiletype === "professionnel" || item.companyData?.profiletype === "professionnel"

  const getSpecificInfo = () => {
    const info = []
    
    if (item.inquiryType === "JobSearchInternship") {
      if (item.inquiryTypeCategory) {
        info.push(labelObject[item.inquiryTypeCategory as keyof typeof labelObject] || item.inquiryTypeCategory)
      }
      if (item.inquiryContractType) {
        try {
          const contracts = typeof item.inquiryContractType === 'string' 
            ? JSON.parse(item.inquiryContractType.replace(/[{}]/g, '').split(',').map((s: string) => `"${s.trim()}"`).join(','))
            : item.inquiryContractType
          if (Array.isArray(contracts) && contracts.length > 0) {
            info.push(labelObject[contracts[0] as keyof typeof labelObject] || contracts[0])
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
      if (item.telework) {
        info.push("Télétravail possible")
      }
    }
    
    if (item.inquiryType === "Training") {
      if (item.inquiryTrainingCategory) {
        info.push(labelObject[item.inquiryTrainingCategory as keyof typeof labelObject] || item.inquiryTrainingCategory)
      }
      if (item.inquiryTrainingType) {
        info.push(labelObject[item.inquiryTrainingType as keyof typeof labelObject] || item.inquiryTrainingType)
      }
    }
    
    return info
  }

  const specificInfo = getSpecificInfo()

  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
  }

  const handleRespond = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    router.push(`/announcements/inquiries/${item.id}`)
  }

  return (
    <>
      <Link href={`/announcements/inquiries/${item.id}`}>
        <Card
          className={`h-full hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group cursor-pointer border-0 bg-white/90 backdrop-blur-md min-w-0 ${
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
              {item.ray && (
                <div className="flex items-center gap-1">
                  <Locate className="w-3.5 h-3.5" />
                  <span>{item.ray === "0" ? "Toute la France" : `Rayon ${item.ray}km`}</span>
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
        url={`/announcements/inquiries/${item.id}`}
        description={displayDescription}
      />
    </>
  )
}

export function CategoriesSection() {
  const [selectedCategory, setSelectedCategory] = useState("bons-plans")
  const [announcements, setAnnouncements] = useState<any[]>([])
  const [isLoading, setIsLoading] = useState(false)

  useEffect(() => {
    const loadAnnouncements = async () => {
      setIsLoading(true)
      const category = categories.find((cat) => cat.id === selectedCategory)
      if (!category) return

      try {
        const result = await fetchAnnoncements({
          category: category.apiCategory,
        })

        if (result.success) {
          setAnnouncements(result.deals.slice(0, 6))
        } else {
          setAnnouncements([])
        }
      } catch (error) {
        console.error("Error loading announcements:", error)
        setAnnouncements([])
      } finally {
        setIsLoading(false)
      }
    }

    loadAnnouncements()
  }, [selectedCategory])

  const currentCategory = categories.find((cat) => cat.id === selectedCategory)

  const renderCard = (item: any, index: number) => {
    const detailPath = currentCategory?.detailPath || ""
    
    switch (currentCategory?.apiCategory) {
      case "bons_plans":
        return <DealCard key={item.id} item={item} detailPath={detailPath} />
      case "emplois":
        return <JobCard key={item.id} item={item} detailPath={detailPath} />
      case "formations":
        return <TrainingCard key={item.id} item={item} detailPath={detailPath} />
      case "evenements":
        return <EventCard key={item.id} item={item} detailPath={detailPath} />
      case "demandes":
        return <InquiryCard key={item.id} item={item} detailPath={detailPath} />
      default:
        return <GenericCard key={item.id} item={item} detailPath={detailPath} icon={Tag} color="gray" />
    }
  }

  return (
    <section className="py-16 md:py-24 bg-gradient-to-b from-muted/30 to-background overflow-x-hidden">
      <div className="container mx-auto px-4 overflow-x-hidden">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">Nos catégories</h2>
          <p className="text-lg text-muted-foreground max-w-3xl mx-auto">
            Explorez toutes nos catégories : bons plans pour économiser au quotidien, offres d'emploi pour votre
            carrière, formations pour développer vos compétences, événements pour réseauter, et demandes pour trouver ce
            dont vous avez besoin
          </p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-[250px_1fr] gap-8">
          {/* Categories sidebar */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="space-y-2 overflow-x-auto"
          >
            {categories.map((category) => {
              const Icon = category.icon
              const isActive = selectedCategory === category.id
              return (
                <Button
                  key={category.id}
                  variant={isActive ? "default" : "ghost"}
                  className={`w-full justify-start h-12 ${isActive ? "bg-primary text-white" : "hover:bg-muted"}`}
                  onClick={() => setSelectedCategory(category.id)}
                >
                  <Icon className="mr-3 h-5 w-5" />
                  {category.label}
                </Button>
              )
            })}
          </motion.div>

          {/* Items grid */}
          <div className="space-y-8 min-w-0 overflow-hidden">
            {isLoading ? (
              <div className="text-center py-20">
                <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-primary mx-auto mb-4" />
                <p className="text-muted-foreground">Chargement des annonces...</p>
              </div>
            ) : announcements.length === 0 ? (
              <div className="text-center py-20">
                <p className="text-muted-foreground">Aucune annonce disponible pour le moment</p>
              </div>
            ) : (
              <>
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6 }}
                  className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6"
                >
                  {announcements.map((item, index) => (
                    <motion.div
                      key={item.id}
                      initial={{ opacity: 0, y: 20 }}
                      whileInView={{ opacity: 1, y: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.6, delay: index * 0.1 }}
                    >
                      {renderCard(item, index)}
                    </motion.div>
                  ))}
                </motion.div>

                <div className="flex justify-center mt-8">
                  <Link href={currentCategory?.path || "/"}>
                    <Button size="lg" variant="outline" className="group bg-transparent">
                      Voir plus d'annonces
                      <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                    </Button>
                  </Link>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </section>
  )
}
