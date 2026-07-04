"use client"

import type React from "react"

import { useEffect, useState, useMemo, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { motion, AnimatePresence } from "framer-motion"
import {
  Plus,
  Bell,
  MapPin,
  Briefcase,
  Clock,
  Search,
  Filter,
  Grid3x3,
  List,
  Locate,
  Heart,
  Share2,
  Users,
  Euro,
  Building2,
  User,
  GraduationCap,
  FileText,
  Wifi,
  Home,
  Briefcase as BriefcaseIcon,
  Eye,
} from "lucide-react"
import { fetchAnnoncements, fetchUserInfo, toggleFavorite } from "@/lib/api"
import { toast } from "sonner"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { useToast } from "@/hooks/use-toast"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Checkbox } from "@/components/ui/checkbox"
import { config } from "@/lib/config"
import { ShareModal } from "@/components/share-modal"
import { SaveSearchButton } from "@/components/save-search-button"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import labelObject from "@/lib/constants/label-object"
import citiesData from "@/lib/data/france-cities.json"
import { getCoordsFromAddress } from "@/lib/data/zipcode-coords"
import useInfiniteRender from "@/hooks/useInfiniteRender"

// Fonction utilitaire pour obtenir les traductions
const getLabel = (key: string): string => {
  return (labelObject as any)[key] || key
}

const API_URL = config.API_URL;

function formatAddress(address: any): string {
  if (!address) return ""

  if (typeof address === "string") return address

  if (typeof address === "object") {
    const parts = []
    if (address.street || address.adresse) parts.push(address.street || address.adresse)
    if (address.city || address.ville) parts.push(address.city || address.ville)
    if (address.postalCode || address.codepostal) parts.push(address.postalCode || address.codepostal)
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

interface Job {
  id: string
  title: string
  description: string
  contractType?: string
  occupationTime?: string
  location?: string | any
  address?: string | any
  salary?: string
  minSalary?: string
  maxSalary?: string
  experience?: string
  xpLevel?: string
  studyLevel?: string
  images?: string[]
  userId?: string
  createdat?: string
  endDate?: string
  activity?: string | any
  business?: string
  benefit?: string
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
  userPseudo?: string
  userNomsociete?: string
  userProfileType?: "professionnel" | "particulier"
  userPhotoUrl?: string
  skills?: string[] | string
  benefits?: string[] | string
  applicantsCount?: number
  isFavorite?: boolean
  number_view?: number
  [key: string]: any
}

function JobCard({ job, viewMode }: { job: Job; viewMode: "grid" | "list" }) {
  const [isFavorite, setIsFavorite] = useState(job.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const isExpired = job.endDate ? new Date(job.endDate) < new Date() : false

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

  // Get company/user display info
  // const displayName =
  //   job.userNomsociete ||
  //   job.companyData?.nomsociete ||
  //   job.userPseudo ||
  //   (job.userProfileType === "professionnel" ? "Entreprise" : "Recruteur")
 
    // const displayPhoto = job.userPhotoUrl || job.companyData?.photoprofilurl
  
    // Utiliser les vraies données de l'entreprise/utilisateur
  const getUserDisplayName = () => {
    // Essayer d'abord le champ business
    if (job.business) {
      try {
        if (typeof job.business === 'string') {
          // Format PostgreSQL: {"METZ EMPLOI"} ou {Myreklam}
          const cleaned = job.business.replace(/[{}"]/g, '').trim()
          if (cleaned) return cleaned
        }
      } catch (error) {
        console.warn('Erreur lors du parsing de business:', error)
      }
    }
    
    const companyData = job.companyData
    if (!companyData) return "Entreprise"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const getUserPhoto = () => {
    const companyData = job.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    
    // L'URL est déjà complète dans les données
    return companyData.photoprofilurl
  }
  
  const isProfessional = job.companyData?.profiletype === "professionnel"
  
  // Utiliser les vraies données ou des fallbacks
  const displayName = getUserDisplayName()
  const displayPhoto = getUserPhoto()

    // const isPro = job.userProfileType === "professionnel"

  // Mock data for skills and benefits if not available
  // const skills = job.skills || ["React", "Node.js", "TypeScript"]
  // const benefits = job.benefits || ["Télétravail flexible", "Tickets restaurant", "Mutuelle premium"]
 
  
  // const applicantsCount = job.applicantsCount || Math.floor(Math.random() * 50) + 1

  // Parser les compétences et avantages s'ils sont en format JSON
  const getSkills = () => {
    if (!job.skills) return []
    
    try {
      if (typeof job.skills === 'string') {
        // Si c'est une string, essayer de la parser comme JSON
        if (job.skills.startsWith('[') || job.skills.startsWith('{')) {
          return JSON.parse(job.skills)
        }
        // Sinon, diviser par des virgules ou retourner comme array
        return job.skills.split(',').map(s => s.trim()).filter(Boolean)
      }
      
      if (Array.isArray(job.skills)) {
        return job.skills
      }
      
      return []
    } catch (error) {
      console.warn('Erreur lors du parsing des compétences:', error)
      return []
    }
  }

  const getBenefits = () => {
    if (!job.benefit && !job.benefits) return []
    
    const benefitData = job.benefit || job.benefits
    
    try {
      let rawBenefits = []
      if (typeof benefitData === 'string') {
        // Si c'est une string, essayer de la parser comme JSON
        if (benefitData.startsWith('[')) {
          // return JSON.parse(benefitData)
          rawBenefits = JSON.parse(benefitData)

        }
        else if (benefitData.startsWith('{')) {
          // Format PostgreSQL: {Bonuses,Commissions,flexibleHours}
          const cleaned = benefitData.replace(/[{}]/g, '')
          // return cleaned.split(',').map(s => s.trim()).filter(Boolean)
                  rawBenefits = cleaned.split(',').map(s => s.trim()).filter(Boolean)

        }
        else {
          rawBenefits = benefitData.split(',').map(s => s.trim()).filter(Boolean)

        }
        // Sinon, diviser par des virgules
        // return benefitData.split(',').map(s => s.trim()).filter(Boolean)
      }
      else if (Array.isArray(benefitData)) {
      rawBenefits = benefitData
    }
      
      // if (Array.isArray(benefitData)) {
      //   return benefitData
      // }
          return rawBenefits.map((benefit: string) => getLabel(benefit))

      // return []
    } catch (error) {
      console.warn('Erreur lors du parsing des avantages:', error)
      return []
    }
  }

  const skills = getSkills()
  const benefits = getBenefits()

  // Utiliser les vraies statistiques ou générer des valeurs cohérentes basées sur l'ID
  const getApplicantsCount = () => {
    if (job.applicantsCount !== undefined) return job.applicantsCount
    
    // Générer un nombre basé sur l'ID pour la cohérence
    const hash = job.id.split('').reduce((a, b) => {
      a = ((a << 5) - a) + b.charCodeAt(0)
      return a & a
    }, 0)
    
    return Math.abs(hash % 50) + 1
  }

  const applicantsCount = getApplicantsCount()

  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!job.description) return ""
    
    // Créer un élément temporaire pour décoder les entités HTML
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = job.description
    // Récupérer le texte décodé
    const decodedText = tempDiv.textContent || tempDiv.innerText || ""
    // Normaliser les espaces
    const normalized = decodedText.replace(/\s+/g, ' ').trim()
    return normalized
  }

   // Formater l'adresse depuis les données réelles
  const getFormattedLocation = () => {
    if (!job.location && !job.address) return ""
    
    const locationData = job.location || job.address
    
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
    if (job.occupationTime === "fullTime") return "Temps plein"
    if (job.occupationTime === "partTime") return "Temps partiel"
    return null
  }

  // Utiliser les vraies données de salaire avec brut/net
  const getSalaryDisplay = () => {
    // Si salaire basé sur profil
    if (job.issalarybasedonprofile) return "Selon profil"
    
    // Ne rien afficher si aucune donnée de salaire n'est présente
    if (!job.minSalary && !job.maxSalary && !job.salary) return null
    
    // Déterminer le type de salaire (brut/net)
    const salaryType = job.netSalary === "raw" ? "brut" : job.netSalary === "net" ? "net" : ""
    
    // Déterminer la période
    let period = ""
    if (job.unitSalary === "years") period = " /an"
    else if (job.unitSalary === "month") period = " /mois"
    else if (job.unitSalary === "day" || job.unitSalary === "days") period = " /jour"
    else if (job.unitSalary === "hour" || job.unitSalary === "hours") period = " /heure"

    // Si salaryExact est true, afficher uniquement maxSalary
    const isSalaryExact = job.salaryExact === true || job.salaryExact === "true"
    
    if (isSalaryExact && job.maxSalary) {
      const max = parseFloat(job.maxSalary)
      if (max === 0) return null
      return `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    // Sinon afficher la fourchette
    if (job.minSalary && job.maxSalary && !isSalaryExact) {
      const min = parseFloat(job.minSalary)
      const max = parseFloat(job.maxSalary)
      if (min === 0 && max === 0) return null
      return `${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }
    
    if (job.minSalary) {
      const min = parseFloat(job.minSalary)
      if (min === 0) return null
      return `À partir de ${min.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    // Fallback sur job.salary si présent
    if (job.salary) return job.salary

    return null
  }

  // const handleShare = (e: React.MouseEvent) => {
  //   e.preventDefault()
  //   e.stopPropagation()
  //   if (navigator.share) {
  //     navigator.share({
  //       title: job.title,
  //       text: job.description,
  //       url: window.location.origin + `/announcements/jobs/${job.id}`,
  //     })
  //   }
  // }

  // const handleFavorite = (e: React.MouseEvent) => {
  //   e.preventDefault()
  //   e.stopPropagation()
  //   setIsFavorite(!isFavorite)
  // }


  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
  }

  // Parser l'activité/secteur
const getActivityDisplay = (job: Job): string => {
  if (!job.activity) return ""
  
  try {
    if (typeof job.activity === 'string') {
      // Si c'est du JSON PostgreSQL: {Sales} ou ["Sales"]
      if (job.activity.startsWith('{') && job.activity.endsWith('}')) {
        const cleaned = job.activity.replace(/[{}]/g, '').trim()
        return getLabel(cleaned)
      }
      if (job.activity.startsWith('[')) {
        const parsed = JSON.parse(job.activity)
        return parsed.map((act: string) => getLabel(act)).join(', ')
      }
      return getLabel(job.activity)
    }
    
    if (Array.isArray(job.activity)) {
      return job.activity.map((act: string) => getLabel(act)).join(', ')
    }
    
    return getLabel(job.activity)
  } catch (error) {
    console.warn('Erreur lors du parsing de l\'activité:', error)
    return job.activity?.toString() || ""
  }
}

  const handleFavorite = async (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
    if (!userId) {
      // Rediriger vers la page de connexion
      window.location.href = "/login-required"
      return
    }

    try {
      const newFavoriteState = !isFavorite
      const result = await toggleFavorite(userId, job.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Job] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, job.title)
        
        if (newFavoriteState) {
          toast.success("Ajouté aux favoris", {
            description: "Retrouvez cette annonce dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=emplois"
            }
          })
        } else {
          toast.success("Retiré des favoris")
        }
      } else {
        console.error("[Favorite Job] Échec de la mise à jour:", result)
        toast.error("Erreur lors de la mise à jour du favori")
      }
    } catch (error) {
      console.error("[Favorite Job] Erreur lors de la mise à jour du favori:", error)
      toast.error("Erreur lors de la mise à jour du favori")
    }
  }

  if (viewMode === "list") {
    return (
      <>
        <Link href={`/announcements/jobs/${job.id}`}>
        <Card
          className={`hover:shadow-xl hover:scale-[1.01] transition-all duration-300 overflow-hidden group cursor-pointer border-2 ${
            isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-blue-200"
          }`}
        >
          <div className="p-6">
            <div className="flex gap-6">
              {/* Company Logo */}
              <div className="flex-shrink-0 relative">
                {isExpired && (
                  <div className="absolute inset-0 bg-black/30 rounded-full z-10 flex items-center justify-center">
                    <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
                  </div>
                )}
                <Avatar className={`w-20 h-20 border-4 border-white shadow-lg ring-2 ring-gray-100 ${isExpired ? "grayscale brightness-75" : ""}`}>
                  <AvatarImage
                    src={
                      displayPhoto
                        ? displayPhoto.startsWith("http")
                          ? displayPhoto
                          : `${API_URL}${displayPhoto}`
                        : undefined
                    }
                  />
                  <AvatarFallback className="bg-gradient-to-br from-blue-500 to-blue-600">
                    {isProfessional ? (
                      <Building2 className="w-10 h-10 text-white" />
                    ) : (
                      <User className="w-10 h-10 text-white" />
                    )}
                  </AvatarFallback>
                </Avatar>
              </div>

              {/* Main Content */}
              <div className="flex-1 min-w-0">
                {/* Header with title and actions */}
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1 min-w-0">
                    <h3
                      className={`text-2xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors mb-2 line-clamp-1 ${
                        isExpired ? "text-gray-500" : ""
                      }`}
                    >
                      {job.title}
                    </h3>
                    <div className="flex items-center gap-2">
                      <p className="text-gray-700 font-semibold text-lg">{displayName}</p>
                      {isProfessional && (
                        <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs">
                          Pro
                        </Badge>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-9 w-9 rounded-full hover:bg-gray-100"
                      onClick={handleFavorite}
                    >
                      <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-9 w-9 rounded-full hover:bg-gray-100"
                      onClick={handleShare}
                    >
                      <Share2 className="w-5 h-5 text-gray-400" />
                    </Button>
                    {isExpired && (
                      <Badge className="bg-red-600 text-white border-2 border-white font-bold">EXPIRÉ</Badge>
                    )}
                  </div>
                </div>

                {/* Key Info Row - Badges */}
                <div className="flex flex-wrap items-center gap-2 mb-3">
                  {/* Type de contrat */}
                  {job.contractType && (
                    <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                      <FileText className="w-3 h-3 mr-1 inline" />
                      {getLabel(job.contractType)}
                    </Badge>
                  )}

                  {/* Niveau d'études */}
                  {job.studyLevel && (
                    <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                      <GraduationCap className="w-3 h-3 mr-1 inline" />
                      {getLabel(job.studyLevel)}
                    </Badge>
                  )}

                  {/* Niveau d'expérience */}
                  {job.xpLevel && (
                    <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                      <BriefcaseIcon className="w-3 h-3 mr-1 inline" />
                      {getLabel(job.xpLevel)}
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
                  {job.remote !== null && job.remote !== undefined && (
                    <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                      {job.remote === 't' || job.remote === true ? (
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
                </div>

                {/* Description */}
                <p className="text-gray-600 text-base mb-4 line-clamp-2 leading-relaxed">{getCleanDescription()}</p>

                {/* Skills */}
                {skills.length > 0 && (
                  <div className="mb-4">
                    <p className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
                      <span className="w-1 h-4 bg-blue-500 rounded"></span>
                      Compétences requises
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {skills.slice(0, 5).map((skill: string, idx: number) => (
                        <Badge key={idx} variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100 transition-colors">
                          {skill}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}

                {/* Benefits */}
                {benefits.length > 0 && (
                  <div className="mb-4">
                    <p className="text-sm font-semibold text-gray-900 mb-3 flex items-center gap-2">
                      <span className="w-1 h-4 bg-green-500 rounded"></span>
                      Avantages
                    </p>
                    <div className="flex flex-wrap gap-2">
                      {benefits.slice(0, 4).map((benefit: string, idx: number) => (
                        <Badge key={idx} variant="outline" className="bg-green-50 text-green-700 border-green-200 hover:bg-green-100 transition-colors">
                          {benefit}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}

                {/* Footer */}
                <div className="flex items-center justify-between pt-4 border-t">
                  {job.createdat && (
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Clock className="w-4 h-4" />
                      <span>{getTimeAgo(job.createdat)}</span>
                    </div>
                  )}
                  <Button
                    className={
                      isExpired ? "bg-gray-400 cursor-not-allowed" : "bg-blue-500 hover:bg-blue-600 text-white"
                    }
                    disabled={isExpired}
                  >
                    {isExpired ? "Expiré" : "Voir l'offre"}
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </Card>
      </Link>
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={job.title}
        url={`/announcements/jobs/${job.id}`}
        description={job.description}
      />
    </>
    )
  }

  // Grid View
  return (
    <>
      <Link href={`/announcements/jobs/${job.id}`}>
      <Card
        className={`h-full hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 overflow-hidden group cursor-pointer flex flex-col border-2 ${
          isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-blue-200"
        }`}
      >
        {/* Company Logo Header */}
        <div className="p-6 pb-4 border-b bg-gradient-to-br from-blue-50/30 to-white relative">
          {isExpired && (
            <div className="absolute top-3 left-3 z-10">
              <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
            </div>
          )}

          <div className="flex items-start justify-between mb-3">
            <Avatar
              className={`w-16 h-16 border-4 border-white shadow-lg ring-2 ring-blue-100 ${isExpired ? "grayscale brightness-75" : ""}`}
            >
              <AvatarImage
                src={
                  displayPhoto
                    ? displayPhoto.startsWith("http")
                      ? displayPhoto
                      : `${API_URL}${displayPhoto}`
                    : undefined
                }
              />
              <AvatarFallback className="bg-gradient-to-br from-blue-500 to-blue-600">
                {isProfessional ? <Building2 className="w-8 h-8 text-white" /> : <User className="w-8 h-8 text-white" />}
              </AvatarFallback>
            </Avatar>
            <div className="flex gap-1">
              <Button
                variant="ghost"
                size="icon"
                className="h-8 w-8 rounded-full hover:bg-white"
                onClick={handleFavorite}
              >
                <Heart className={`w-4 h-4 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
              </Button>
              <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full hover:bg-white" onClick={handleShare}>
                <Share2 className="w-4 h-4 text-gray-400" />
              </Button>
            </div>
          </div>

          <h3
            className={`font-bold text-xl mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors ${
              isExpired ? "text-gray-500" : "text-gray-900"
            }`}
          >
            {job.title}
          </h3>
          <div className="flex items-center gap-2">
            <p className="text-sm text-gray-700 font-semibold">{displayName}</p>
            {isProfessional && (
              <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs">
                Pro
              </Badge>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="p-6 flex-1 flex flex-col">
          {/* Key Info - Badges */}
          <div className="flex flex-wrap items-center gap-2 mb-4">
            {/* Type de contrat */}
            {job.contractType && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <FileText className="w-3 h-3 mr-1 inline" />
                {getLabel(job.contractType)}
              </Badge>
            )}

            {/* Niveau d'études */}
            {job.studyLevel && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <GraduationCap className="w-3 h-3 mr-1 inline" />
                {getLabel(job.studyLevel)}
              </Badge>
            )}

            {/* Niveau d'expérience */}
            {job.xpLevel && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <BriefcaseIcon className="w-3 h-3 mr-1 inline" />
                {getLabel(job.xpLevel)}
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
            {job.remote !== null && job.remote !== undefined && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                {job.remote === 't' || job.remote === true ? (
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
                  <Badge key={idx} variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs px-2 py-0.5">
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
                  <Badge key={idx} variant="outline" className="bg-green-50 text-green-700 border-green-200 text-xs px-2 py-0.5">
                    {benefit}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          {/* Footer */}
          <div className="flex items-center justify-end pt-4 border-t mt-auto">
            <Button
              size="sm"
              className={
                isExpired
                  ? "bg-gray-400 cursor-not-allowed text-xs px-4"
                  : "bg-blue-500 hover:bg-blue-600 text-white text-xs px-4"
              }
              disabled={isExpired}
            >
              {isExpired ? "Expiré" : "Voir l'offre"}
            </Button>
          </div>
        </div>

        {/* Occupation Time Badge - Retiré */}
      </Card>
    </Link>
    <ShareModal
      isOpen={showShareModal}
      onClose={() => setShowShareModal(false)}
      title={job.title}
      url={`/announcements/jobs/${job.id}`}
      description={job.description}
    />
    </>
  )
}

export default function JobsPage() {
  const router = useRouter()
  const params = useSearchParams()
  const { toast } = useToast()

  const [searchQuery, setSearchQuery] = useState(params.get("q") || "")
  const [showFilters, setShowFilters] = useState(false)
  const [sortBy, setSortBy] = useState("recent")
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid")

  const [selectedContractType, setSelectedContractType] = useState("all")
  const [selectedOccupationTime, setSelectedOccupationTime] = useState("all")
  const [selectedActivity, setSelectedActivity] = useState("all")
  const [selectedFunction, setSelectedFunction] = useState("all")
  const [selectedExperience, setSelectedExperience] = useState("all")
  const [selectedRemote, setSelectedRemote] = useState("all")
  const [selectedDateRange, setSelectedDateRange] = useState("all")
  const [minSalary, setMinSalary] = useState("")
  const [hasDocuments, setHasDocuments] = useState(false)
  const [selectedCity, setSelectedCity] = useState(params.get("location") || "")
  const [searchRadius, setSearchRadius] = useState(parseInt(params.get("radius") || "50"))
  const [searchAllFrance, setSearchAllFrance] = useState(params.get("allFrance") === "true")
  const [isGettingLocation, setIsGettingLocation] = useState(false)
  const [showExpired, setShowExpired] = useState(true)
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

  const [allJobs, setAllJobs] = useState<Job[]>([])
  const [currentPage, setCurrentPage] = useState(1)
  const [jobsPerPage] = useState(20)
  const [userId, setUserId] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    if (typeof window !== "undefined") {
      setUserId(localStorage.getItem("profileId"))
    }
  }, [])

  // Initialiser les filtres depuis les paramètres URL
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    
    // Terme de recherche
    const searchQueryParam = urlParams.get("q")
    if (searchQueryParam) {
      setSearchQuery(searchQueryParam)
    }
    
    // Localisation
    const locationParam = urlParams.get("location")
    if (locationParam) {
      setSelectedCity(locationParam)
    }
    
    // Rayon
    const radiusParam = urlParams.get("radius")
    if (radiusParam) {
      setSearchRadius(parseInt(radiusParam))
    }
    
    // Recherche France entière
    const allFranceParam = urlParams.get("allFrance")
    if (allFranceParam === "true") {
      setSearchAllFrance(true)
      setSelectedCity("")
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
    const loadAllJobs = async () => {
      setIsLoading(true)
      try {
        const result = await fetchAnnoncements({ category: "emplois" })
        if (result.success) {
          setAllJobs(result.deals)
        } else {
          console.error("Erreur lors du chargement des annonces:", result.error)
          setAllJobs([])
        }
      } catch (error) {
        console.error("Exception lors du chargement des annonces:", error)
        setAllJobs([])
      } finally {
        setIsLoading(false)
      }
    }
    loadAllJobs()
  }, [])

  // Fonctions utilitaires pour le filtrage
  const getFormattedLocation = (job: Job): string => {
    if (!job.location && !job.address) return ""
    
    const locationData = job.location || job.address
    
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

   const getUserDisplayName = (job: Job): string => {
    if (!job.companyData) return ""
    
    const { profiletype, pseudo, nomsociete } = job.companyData
    
    if (profiletype === "professionnel") {
      return nomsociete || "Entreprise"
    }
    return pseudo || job.userPseudo || "Particulier"
  }

  const handleUseGeolocation = async () => {
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
        const { latitude, longitude } = position.coords
        
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`,
          )
          const data = await response.json()
          const city = data.address.city || data.address.town || data.address.village || "Ma position"
          setSelectedCity(city)
          
          // Mettre à jour l'URL avec les coordonnées GPS
          const newParams = new URLSearchParams(params.toString())
          newParams.set("location", city)
          newParams.set("lat", latitude.toString())
          newParams.set("lng", longitude.toString())
          router.push(`?${newParams.toString()}`, { scroll: false })
          
          toast({
            title: "Position détectée",
            description: `Recherche autour de ${city}`,
          })
        } catch (error) {
          setSelectedCity("Ma position")
          
          // Mettre à jour l'URL avec les coordonnées GPS même sans nom de ville
          const newParams = new URLSearchParams(params.toString())
          newParams.set("location", "Ma position")
          newParams.set("lat", latitude.toString())
          newParams.set("lng", longitude.toString())
          router.push(`?${newParams.toString()}`, { scroll: false })
          
          toast({
            title: "Position détectée",
            description: "Recherche autour de votre position actuelle",
          })
        } finally {
          setIsGettingLocation(false)
        }
      },
      (error) => {
        setIsGettingLocation(false)
        toast({
          title: "Erreur de géolocalisation",
          description: "Impossible d'accéder à votre position.",
          variant: "destructive",
        })
      },
    )
  }

  const filteredJobs = useMemo(() => {
    if (allJobs.length === 0) return []

    const filtered = allJobs.filter((job) => {
      const isExpired = job.endDate ? new Date(job.endDate) < new Date() : false
      if (!showExpired && isExpired) return false

      // if (searchQuery) {
      //   const query = searchQuery.toLowerCase()
      //   const matchesSearch =
      //     job.title?.toLowerCase().includes(query) ||
      //     job.description?.toLowerCase().includes(query) ||
      //     job.location?.toLowerCase().includes(query)
      //   if (!matchesSearch) return false
      // }
      if (searchQuery) {
        const query = searchQuery.toLowerCase()
        const matchesSearch =
          job.title?.toLowerCase().includes(query) ||
          job.description?.toLowerCase().includes(query) ||
          getFormattedLocation(job)?.toLowerCase().includes(query) ||
          getUserDisplayName(job)?.toLowerCase().includes(query)
        if (!matchesSearch) return false
      }

      if (selectedContractType !== "all" && job.contractType !== selectedContractType) return false
      if (selectedOccupationTime !== "all" && job.occupationTime !== selectedOccupationTime) return false
      
      // Filtre par secteur d'activité
      if (selectedActivity !== "all") {
        const jobActivity = (job.activity || "").toString().toLowerCase()
        const selectedActivityLower = selectedActivity.toLowerCase()
        if (!jobActivity.includes(selectedActivityLower)) return false
      }

      // Filtre par fonction (job title/role)
      if (selectedFunction !== "all") {
        const jobTitle = (job.title || "").toString().toLowerCase()
        const selectedFunctionLower = selectedFunction.toLowerCase()
        if (!jobTitle.includes(selectedFunctionLower)) return false
      }

      // Filtre par niveau d'expérience
      if (selectedExperience !== "all" && job.xpLevel !== selectedExperience) return false

      // Filtre par télétravail
      if (selectedRemote !== "all") {
        const isRemote = job.remote === 't' || job.remote === true || job.remote === 'true'
        if (selectedRemote === "remote" && !isRemote) return false
        if (selectedRemote === "onsite" && isRemote) return false
      }

      // Filtre par date
      if (selectedDateRange !== "all") {
        const jobDate = new Date(job.createdat || 0)
        const now = new Date()
        const diffInDays = (now.getTime() - jobDate.getTime()) / (1000 * 3600 * 24)
        if (selectedDateRange === "today" && diffInDays > 1) return false
        if (selectedDateRange === "week" && diffInDays > 7) return false
        if (selectedDateRange === "month" && diffInDays > 30) return false
      }

      // Filtre par salaire
      if (minSalary) {
        const minVal = parseFloat(minSalary)
        const jobMinSalary = parseFloat(job.minSalary || job.salary || "0")
        const jobMaxSalary = parseFloat(job.maxSalary || "0")
        if (jobMaxSalary > 0 && jobMaxSalary < minVal) return false
        if (jobMaxSalary === 0 && jobMinSalary > 0 && jobMinSalary < minVal) return false
      }

      // Filtre par documents (si applicable dans le futur)
      if (hasDocuments && !job.documents) return false

      // Filtre par localisation avec calcul de distance
      if (selectedCity && !searchAllFrance) {
        try {
          // Si on a des coordonnées de recherche valides et un rayon
          if (searchCoords.lat !== 0 && searchCoords.lng !== 0 && searchRadius > 0) {
            // Extraire les coordonnées de l'offre
            let jobLat = 0
            let jobLng = 0
            let jobCity = ""
            let jobZipcode = ""

            if (job.address) {
              if (typeof job.address === 'string') {
                try {
                  const addressObj = JSON.parse(job.address)
                  jobLat = parseFloat(addressObj.latitude || addressObj.lat || 0)
                  jobLng = parseFloat(addressObj.longitude || addressObj.lng || addressObj.lon || 0)
                  jobCity = addressObj.city || ""
                  jobZipcode = addressObj.zipcode || ""
                } catch {
                  // Si le parsing échoue, continuer
                }
              } else if (typeof job.address === 'object') {
                jobLat = parseFloat(job.address.latitude || job.address.lat || 0)
                jobLng = parseFloat(job.address.longitude || job.address.lng || job.address.lon || 0)
                jobCity = job.address.city || ""
                jobZipcode = job.address.zipcode || ""
              }
            }

            // Si pas de coordonnées dans l'adresse, essayer avec les données de l'entreprise
            if ((jobLat === 0 || jobLng === 0) && job.companyData) {
              jobLat = parseFloat((job.companyData as any).latitude || (job.companyData as any).lat || 0)
              jobLng = parseFloat((job.companyData as any).longitude || (job.companyData as any).lng || (job.companyData as any).lon || 0)
            }

            // Si toujours pas de coordonnées, utiliser la table de correspondance ville/code postal
            if ((jobLat === 0 || jobLng === 0) && (jobCity || jobZipcode)) {
              const fallbackCoords = getCoordsFromAddress(jobCity, jobZipcode)
              if (fallbackCoords) {
                jobLat = fallbackCoords.lat
                jobLng = fallbackCoords.lng
              }
            }

            // Si on a des coordonnées valides pour l'offre, calculer la distance
            if (jobLat !== 0 && jobLng !== 0) {
              const distance = calculateDistance(searchCoords.lat, searchCoords.lng, jobLat, jobLng)
              
              // Filtrer si la distance est supérieure au rayon
              if (distance > searchRadius) {
                return false
              }
            }
            // Si pas de coordonnées GPS pour l'offre, on l'inclut dans les résultats
          } else {
            // Pas de coordonnées GPS de recherche, ne pas filtrer par localisation
          }
        } catch (error) {
          console.warn("Erreur lors du filtrage par localisation:", error)
        }
      }

      return true
    })

    filtered.sort((a, b) => {
      switch (sortBy) {
        case "recent":
          return new Date(b.createdat || 0).getTime() - new Date(a.createdat || 0).getTime()
        case "ending":
          return new Date(a.endDate || 0).getTime() - new Date(b.endDate || 0).getTime()
        case "salary":
          const salaryA = Number.parseFloat(a.salary || "0")
          const salaryB = Number.parseFloat(b.salary || "0")
          return salaryB - salaryA
        default:
          return 0
      }
    })

    return filtered
  }, [
    allJobs,
    searchQuery,
    selectedContractType,
    selectedOccupationTime,
    selectedCity,
    searchAllFrance,
    sortBy,
    showExpired,
    searchRadius,
    searchCoords,
  ])

  const paginationData = useMemo(() => {
    const indexOfLastJob = currentPage * jobsPerPage
    const indexOfFirstJob = indexOfLastJob - jobsPerPage
    const currentJobs = filteredJobs.slice(indexOfFirstJob, indexOfLastJob)
    const totalPages = Math.ceil(filteredJobs.length / jobsPerPage)
    return { currentJobs, totalPages }
  }, [filteredJobs, currentPage, jobsPerPage])

  const handlePageChange = (page: number) => {
    if (page > 0 && page <= paginationData.totalPages) {
      setCurrentPage(page)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

    const { canCreateAds, remainingAds, isPremium } = useSubscriptionLimits()
  const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

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

    if (profileType !== 'professionnel') {
      toast({
        title: "Interdiction",
        description: "Seuls les entreprises peuvent effectuer cette actions",
        variant: "destructive",
      })
      return
    }

    router.push("/announcements/create/jobs")
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
      description: "Vous serez notifié des nouvelles offres d'emploi.",
    })
  }

    const { visibleItems: currentJobs, hasMore, sentinelRef } = useInfiniteRender(filteredJobs, 20)


  return (
    <Suspense fallback={<div>Chargement...</div>}>
      <div className="min-h-screen bg-gray-50">
        <header className="w-full relative overflow-hidden text-white">
          {/* Background image avec overlay bleu */}
          <div className="absolute inset-0 z-0">
            <Image
              src="/images/jobs-background.jpg"
              alt="Background"
              fill
              className="object-cover"
              priority
            />
            {/* Overlay bleu semi-transparent */}
            <div className="absolute inset-0 bg-gradient-to-r from-blue-600/85 to-blue-500/85" />
          </div>
          
          <div className="container mx-auto px-4 max-w-[1400px] relative z-10">
            <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="py-8 md:py-12 lg:py-16 flex flex-col">
              <div className="flex flex-col md:flex-row items-start justify-between mb-6 md:mb-8 gap-4">
                <div className="flex items-center gap-3 md:gap-4">
                  <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-3 md:p-4 flex items-center justify-center">
                    <Briefcase className="w-8 h-8 md:w-12 md:h-12 text-white" />
                  </div>
                  <div>
                    <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold mb-1 md:mb-2">Offres d'Emploi</h1>
                    <p className="text-sm md:text-base lg:text-lg text-white/90">
                      Trouvez votre prochain emploi grâce aux recommandations de notre communauté
                    </p>
                  </div>
                </div>

                <div className="flex gap-4 md:gap-8 text-right">
                  <div>
                    <div className="text-xl md:text-2xl lg:text-3xl font-bold">{allJobs.length}</div>
                    <div className="text-xs md:text-sm text-white/80">Offres actives</div>
                  </div>
                </div>
              </div>

              <div className="w-full max-w-4xl mx-auto">
                <div className="relative">
                  <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <Input
                    type="text"
                    placeholder="Rechercher un emploi, une entreprise, un lieu..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-12 pr-4 py-6 text-base rounded-xl border-0 shadow-lg focus:ring-2 focus:ring-blue-300 text-gray-900 bg-white"
                  />
                </div>
              </div>
            </motion.div>
          </div>
        </header>

        <div className="bg-white border-b sticky top-16 z-20 shadow-sm">
          <div className="container mx-auto px-4 max-w-[1400px] py-3 md:py-4">
            {/* Première ligne : Boutons d'action */}
            <div className="flex flex-wrap gap-2 md:gap-3 mb-3 md:mb-4">
              <Button
                onClick={handleCreateAnnouncement}
                className="bg-gradient-to-r from-blue-600 to-blue-500 hover:from-blue-700 hover:to-blue-600 text-white shadow-md text-sm"
                size="sm"
              >
                <Plus className="w-4 h-4 mr-2" />
                <span className="hidden sm:inline">Poster une offre</span>
                <span className="sm:hidden">Poster</span>
              </Button>
              <SaveSearchButton
                searchTerm={searchQuery}
                category={"demandes"}
                location={selectedCity}
                radius={searchRadius}
                searchAllFrance={searchAllFrance}
                useGeolocation={isGettingLocation}
                userPosition={null}
                currentUrl={typeof window !== "undefined" ? window.location.href : ""}
                className="ml-auto"
              />
            </div>

            {/* Deuxième ligne : Filtres et options */}
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
              {/* Groupe gauche */}
              <div className="flex flex-wrap items-center gap-2 md:gap-4">
                <Button variant="outline" onClick={() => setShowFilters(!showFilters)} className="gap-2 text-sm" size="sm">
                  <Filter className="w-4 h-4" />
                  Filtres
                  {(selectedContractType !== "all" || 
                    selectedOccupationTime !== "all" || 
                    selectedCity || 
                    selectedActivity !== "all" || 
                    selectedFunction !== "all" || 
                    selectedExperience !== "all" || 
                    selectedRemote !== "all" || 
                    selectedDateRange !== "all" || 
                    minSalary !== "" || 
                    hasDocuments) && (
                    <Badge className="ml-1 bg-blue-500">
                      {
                        [
                          selectedContractType !== "all", 
                          selectedOccupationTime !== "all", 
                          selectedCity,
                          selectedActivity !== "all",
                          selectedFunction !== "all",
                          selectedExperience !== "all",
                          selectedRemote !== "all",
                          selectedDateRange !== "all",
                          minSalary !== "",
                          hasDocuments
                        ].filter(Boolean).length
                      }
                    </Badge>
                  )}
                </Button>
                <span className="text-xs md:text-sm text-gray-600">
                  <span className="font-semibold">{filteredJobs.length}</span> offres
                </span>
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="showExpired"
                    checked={showExpired}
                    onCheckedChange={(checked) => setShowExpired(checked as boolean)}
                  />
                  <label htmlFor="showExpired" className="text-xs md:text-sm text-gray-600 cursor-pointer whitespace-nowrap">
                    <span className="hidden sm:inline">Afficher les offres expirées</span>
                    <span className="sm:hidden">Expirées</span>
                  </label>
                </div>
              </div>

              {/* Groupe droite */}
              <div className="flex flex-wrap items-center gap-2 md:gap-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs md:text-sm text-gray-600 whitespace-nowrap">Trier:</span>
                  <Select value={sortBy} onValueChange={setSortBy}>
                    <SelectTrigger className="w-[140px] md:w-[180px] text-xs md:text-sm">
                      <SelectValue placeholder="Trier par" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="recent">Plus récents</SelectItem>
                      <SelectItem value="ending">Se termine bientôt</SelectItem>
                      <SelectItem value="salary">Salaire</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex border rounded-lg overflow-hidden">
                  <Button
                    variant={viewMode === "grid" ? "default" : "ghost"}
                    size="sm"
                    onClick={() => setViewMode("grid")}
                    className={viewMode === "grid" ? "bg-blue-500 hover:bg-blue-600" : "hover:bg-gray-100"}
                  >
                    <Grid3x3 className="w-4 h-4" />
                  </Button>
                  <Button
                    variant={viewMode === "list" ? "default" : "ghost"}
                    size="sm"
                    onClick={() => setViewMode("list")}
                    className={viewMode === "list" ? "bg-blue-500 hover:bg-blue-600" : "hover:bg-gray-100"}
                  >
                    <List className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <AnimatePresence>
          {showFilters && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: "auto", opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.3 }}
              className="bg-white border-b overflow-hidden"
            >
              <div className="container mx-auto px-4 max-w-[1400px] py-6">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="lg:col-span-2">
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Localisation</label>
                    <div className="flex gap-2">
                      <div className="relative flex-1">
                        <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4 z-10" />
                        <Input
                          type="text"
                          placeholder="Ville ou code postal"
                          value={citySearchTerm || selectedCity}
                          onChange={(e) => {
                            const value = e.target.value
                            setCitySearchTerm(value)
                            setSelectedCity(value)
                            setShowCitySuggestions(value.length >= 2)
                          }}
                          onFocus={() => (citySearchTerm || selectedCity).length >= 2 && setShowCitySuggestions(true)}
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
                                  setSelectedCity(cityValue)
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
                                      const newParams = new URLSearchParams(params.toString())
                                      newParams.set("location", cityValue)
                                      newParams.set("lat", data[0].lat)
                                      newParams.set("lng", data[0].lon)
                                      router.push(`?${newParams.toString()}`, { scroll: false })
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
                        onClick={handleUseGeolocation}
                        disabled={isGettingLocation || searchAllFrance}
                        className="flex-shrink-0 bg-transparent"
                        title="Autour de moi"
                      >
                        {isGettingLocation ? (
                          <div className="w-4 h-4 border-2 border-gray-300 border-t-blue-600 rounded-full animate-spin" />
                        ) : (
                          <Locate className="w-4 h-4" />
                        )}
                      </Button>
                    </div>
                    {!searchAllFrance && selectedCity && (
                      <div className="mt-2">
                        <label className="text-xs text-gray-600 mb-1 block">
                          Rayon de recherche: {searchRadius} km
                        </label>
                        <input
                          type="range"
                          min="5"
                          max="100"
                          step="5"
                          value={searchRadius}
                          onChange={(e) => setSearchRadius(Number(e.target.value))}
                          className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-blue-600"
                        />
                      </div>
                    )}
                    <label className="flex items-center mt-2 text-sm text-gray-600 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={searchAllFrance}
                        onChange={(e) => setSearchAllFrance(e.target.checked)}
                        className="mr-2 w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                      />
                      Rechercher dans toute la France
                    </label>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Type de contrat</label>
                    {/* <Select value={selectedContractType} onValueChange={setSelectedContractType}>
                      <SelectTrigger>
                        <SelectValue placeholder="Tous" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous</SelectItem>
                        <SelectItem value="CDI">CDI</SelectItem>
                        <SelectItem value="CDD">CDD</SelectItem>
                        <SelectItem value="Interim">Intérim</SelectItem>
                        <SelectItem value="Stage">Stage</SelectItem>
                        <SelectItem value="Alternance">Alternance</SelectItem>
                        <SelectItem value="Freelance">Freelance</SelectItem>
                      </SelectContent>
                    </Select> */}
                    <Select value={selectedContractType} onValueChange={setSelectedContractType}>
                      <SelectTrigger>
                        <SelectValue placeholder="Tous" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous</SelectItem>
                        <SelectItem value="PermanentContract">{getLabel("PermanentContract")}</SelectItem>
                        <SelectItem value="FixedTermContract">{getLabel("FixedTermContract")}</SelectItem>
                        <SelectItem value="TemporaryWork">{getLabel("TemporaryWork")}</SelectItem>
                        <SelectItem value="Internship">{getLabel("Internship")}</SelectItem>
                        <SelectItem value="Apprenticeship">{getLabel("Apprenticeship")}</SelectItem>
                        <SelectItem value="SelfEmployed">{getLabel("SelfEmployed")}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Temps de travail</label>
                    {/* <Select value={selectedOccupationTime} onValueChange={setSelectedOccupationTime}>
                      <SelectTrigger>
                        <SelectValue placeholder="Tous" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous</SelectItem>
                        <SelectItem value="Temps plein">Temps plein</SelectItem>
                        <SelectItem value="Temps partiel">Temps partiel</SelectItem>
                      </SelectContent>
                    </Select> */}
                    <Select value={selectedOccupationTime} onValueChange={setSelectedOccupationTime}>
                      <SelectTrigger>
                        <SelectValue placeholder="Tous" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous</SelectItem>
                        <SelectItem value="FullTime">{getLabel("FullTime")}</SelectItem>
                        <SelectItem value="PartialTime">{getLabel("PartialTime")}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Secteur d'activité</label>
                    <Select value={selectedActivity} onValueChange={setSelectedActivity}>
                      <SelectTrigger>
                        <SelectValue placeholder="Tous les secteurs" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous les secteurs</SelectItem>
                        <SelectItem value="ITInternet">{getLabel("ITInternet")}</SelectItem>
                        <SelectItem value="Sales">{getLabel("Sales")}</SelectItem>
                        <SelectItem value="HealthcareMedicine">{getLabel("HealthcareMedicine")}</SelectItem>
                        <SelectItem value="HospitalityRestaurant">{getLabel("HospitalityRestaurant")}</SelectItem>
                        <SelectItem value="LogisticsPurchasingTransportation">{getLabel("LogisticsPurchasingTransportation")}</SelectItem>
                        <SelectItem value="Construction">{getLabel("Construction")}</SelectItem>
                        <SelectItem value="HumanResources">{getLabel("HumanResources")}</SelectItem>
                        <SelectItem value="PublicService">{getLabel("PublicService")}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Fonction</label>
                    <Select value={selectedFunction} onValueChange={setSelectedFunction}>
                      <SelectTrigger>
                        <SelectValue placeholder="Toutes les fonctions" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Toutes les fonctions</SelectItem>
                        <SelectItem value="Manager">{getLabel("Manager")}</SelectItem>
                        <SelectItem value="Technician">{getLabel("Technician")}</SelectItem>
                        <SelectItem value="Assistant">{getLabel("Assistant")}</SelectItem>
                        <SelectItem value="Director">{getLabel("Director")}</SelectItem>
                        <SelectItem value="Engineer">{getLabel("Engineer")}</SelectItem>
                        <SelectItem value="Consultant">{getLabel("Consultant")}</SelectItem>
                        <SelectItem value="Salesperson">{getLabel("Salesperson")}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Niveau d'expérience</label>
                    <Select value={selectedExperience} onValueChange={setSelectedExperience}>
                      <SelectTrigger>
                        <SelectValue placeholder="Tous niveaux" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous niveaux</SelectItem>
                        <SelectItem value="Beginner0To1Year">{getLabel("Beginner0To1Year")}</SelectItem>
                        <SelectItem value="Intermediate2To4Years">{getLabel("Intermediate2To4Years")}</SelectItem>
                        <SelectItem value="Experienced5To9Years">{getLabel("Experienced5To9Years")}</SelectItem>
                        <SelectItem value="Senior10YearsOrMore">{getLabel("Senior10YearsOrMore")}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Date de publication</label>
                    <Select value={selectedDateRange} onValueChange={setSelectedDateRange}>
                      <SelectTrigger>
                        <SelectValue placeholder="Toutes les dates" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Toutes les dates</SelectItem>
                        <SelectItem value="today">Dernières 24h</SelectItem>
                        <SelectItem value="week">Dernière semaine</SelectItem>
                        <SelectItem value="month">Dernier mois</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Télétravail</label>
                    <Select value={selectedRemote} onValueChange={setSelectedRemote}>
                      <SelectTrigger>
                        <SelectValue placeholder="Indifférent" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Indifférent</SelectItem>
                        <SelectItem value="remote">Télétravail possible</SelectItem>
                        <SelectItem value="onsite">Sur site uniquement</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 mb-2 block">Salaire minimum</label>
                    <div className="relative">
                      <Euro className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                      <Input 
                        type="number" 
                        placeholder="Ex: 30000" 
                        className="pl-10"
                        value={minSalary}
                        onChange={(e) => setMinSalary(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="flex items-end pb-1">
                    <label className="flex items-center text-sm text-gray-600 cursor-pointer">
                      <Checkbox
                        checked={hasDocuments}
                        onCheckedChange={(checked) => setHasDocuments(checked as boolean)}
                        className="mr-2"
                      />
                      Offres avec documents
                    </label>
                  </div>

                  <div className="flex items-end">
                    <Button 
                      variant="ghost" 
                      size="sm" 
                      className="text-gray-500 hover:text-red-500 text-xs"
                      onClick={() => {
                        setSelectedContractType("all")
                        setSelectedOccupationTime("all")
                        setSelectedActivity("all")
                        setSelectedFunction("all")
                        setSelectedExperience("all")
                        setSelectedRemote("all")
                        setSelectedDateRange("all")
                        setMinSalary("")
                        setHasDocuments(false)
                        setSelectedCity("")
                        setSearchAllFrance(false)
                      }}
                    >
                      Réinitialiser les filtres
                    </Button>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="container mx-auto px-4 max-w-[1400px] py-8">
          {isLoading ? (
            <div className="text-center py-20">
              <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-500 mx-auto mb-4" />
              <p className="text-gray-600">Chargement des offres d'emploi...</p>
            </div>
          // ) : paginationData.currentJobs.length ? (
          ) : currentJobs.length ? (
            <>
              <div
                className={
                  viewMode === "grid"
                    ? "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
                    : "flex flex-col gap-4"
                }
              >
                {/* {paginationData.currentJobs.map((job, index) => ( */}
                  {currentJobs.map((job) => (
                  <motion.div
                    key={job.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    // transition={{ delay: index * 0.05 }}
                  >
                    <JobCard job={job} viewMode={viewMode} />
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
                    className="hover:bg-blue-50"
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
                          className={`w-10 ${page === currentPage ? "bg-blue-500 hover:bg-blue-600" : "hover:bg-blue-50"}`}
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
                    className="hover:bg-blue-50"
                  >
                    Suivant
                  </Button>
                </div>
              )} */}
            </>
          ) : (
            <div className="text-center py-20">
              <div className="mb-4">
                <Briefcase className="w-20 h-20 text-gray-300 mx-auto" />
              </div>
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Aucune offre trouvée</h3>
              <p className="text-gray-500">Essayez de modifier vos filtres pour voir plus de résultats</p>
            </div>
          )}
        </div>
      </div>
    </Suspense>
  )
}
