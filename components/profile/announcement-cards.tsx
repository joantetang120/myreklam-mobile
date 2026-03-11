"use client"

import { useState } from "react"
import Link from "next/link"
import Image from "next/image"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Heart, Share2, MessageCircle, User, MapPin, Clock, Tag, Eye, FileText, GraduationCap, Briefcase, Home, Wifi } from "lucide-react"
import { cn } from "@/lib/utils"
import { config } from "@/lib/config"
import { labelObject } from "@/lib/constants/label-object"

const API_URL = config.API_URL

// Fonction utilitaire pour construire les URLs d'images
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
  return `${API_URL}${cleanPath}`
}

// Composant pour les Bons Plans
export function ProfileDealCard({ announcement }: { announcement: any }) {
  const [imageError, setImageError] = useState(false)
  const isExpired = announcement.endDate ? new Date(announcement.endDate) < new Date() : false
  
  const calculateDiscount = () => {
    if (announcement.initialPrice && announcement.finalPrice) {
      const initial = parseFloat(announcement.initialPrice)
      const final = parseFloat(announcement.finalPrice)
      if (initial > final) {
        return Math.round(((initial - final) / initial) * 100)
      }
    }
    if (announcement.discountValue) {
      return Math.round(parseFloat(announcement.discountValue))
    }
    return 0
  }

  const discountPercentage = calculateDiscount()
  const finalPrice = announcement.finalPrice ? parseFloat(announcement.finalPrice) : null
  const initialPrice = announcement.initialPrice ? parseFloat(announcement.initialPrice) : null

  return (
    <Link href={`/announcements/deals/${announcement.id}`}>
      <Card className={cn(
        "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group border-2",
        isExpired ? "opacity-70 border-red-200 bg-gray-50/50" : "hover:border-green-200 border-gray-200"
      )}>
        <div className="relative h-56 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
          {announcement.images && announcement.images.length > 0 && !imageError ? (
            <Image
              src={getImageUrl(announcement.images[0])}
              alt={announcement.title}
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

          {isExpired ? (
            <div className="absolute top-3 right-3">
              <Badge className="bg-red-500 text-white shadow-xl text-lg font-bold px-5 py-3">
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

        <div className="p-5">
          <h3 className="font-bold text-lg mb-2 line-clamp-2 min-h-[3.5rem] group-hover:text-green-600 transition-colors">
            {announcement.title}
          </h3>

          {announcement.description && (
            <p className="text-sm text-gray-600 mb-4 line-clamp-2 min-h-[2.5rem]">
              {announcement.description.replace(/<[^>]*>/g, '').substring(0, 150)}...
            </p>
          )}

          {finalPrice !== null && (
            <div className="flex items-baseline gap-2 mb-4">
              {finalPrice === 0 ? (
                <Badge className="bg-green-600 text-white text-lg font-bold px-4 py-1">Gratuit</Badge>
              ) : (
                <>
                  <span className="text-2xl font-bold text-orange-600">{finalPrice.toFixed(2)}€</span>
                  {initialPrice && initialPrice > finalPrice && (
                    <span className="text-sm text-gray-400 line-through">{initialPrice.toFixed(2)}€</span>
                  )}
                </>
              )}
            </div>
          )}

          <div className="flex items-center gap-4 text-gray-500">
            <span className="flex items-center gap-1 text-sm">
              <Eye className="w-4 h-4" />
              {announcement.views || 0}
            </span>
            <span className="flex items-center gap-1 text-sm">
              <MessageCircle className="w-4 h-4" />
              0
            </span>
          </div>
        </div>
      </Card>
    </Link>
  )
}

// Composant pour les Emplois
export function ProfileJobCard({ announcement }: { announcement: any }) {
  const isExpired = announcement.endDate ? new Date(announcement.endDate) < new Date() : false
  
  const getUserDisplayName = () => {
    if (announcement.business) {
      try {
        if (typeof announcement.business === 'string') {
          const cleaned = announcement.business.replace(/[{}"]/g, '').trim()
          if (cleaned) return cleaned
        }
      } catch (error) {
        // ignore
      }
    }
    
    const companyData = announcement.companyData
    if (!companyData) return "Entreprise"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const getUserPhoto = () => {
    const companyData = announcement.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    return companyData.photoprofilurl
  }

  const isProfessional = announcement.companyData?.profiletype === "professionnel"
  const displayName = getUserDisplayName()
  const displayPhoto = getUserPhoto()

  const formatAddress = (address: any) => {
    if (!address) return null
    if (typeof address === "string") {
      try {
        const parsed = JSON.parse(address)
        const parts = []
        if (parsed.ville || parsed.city) parts.push(parsed.ville || parsed.city)
        return parts.join(", ") || null
      } catch {
        return address
      }
    }
    const parts = []
    if (address.ville || address.city) parts.push(address.ville || address.city)
    return parts.join(", ") || null
  }

  const location = formatAddress(announcement.location || announcement.address)

  const getLabel = (key: string) => {
    const labels: { [key: string]: string } = {
      'CDI': 'CDI',
      'CDD': 'CDD',
      'Internship': 'Stage',
      'Apprenticeship': 'Alternance',
      'Temporary': 'Intérim',
      'BelowBac': 'Inférieur au Bac',
      'Bac': 'Bac',
      'BacPlus2': 'Bac+2',
      'BacPlus3': 'Bac+3',
      'BacPlus5': 'Bac+5',
      'Junior': 'Débutant',
      'Confirmed': 'Confirmé',
      'Expert': 'Expert',
      'BACEmployeeSpecializedWorker': 'BAC/Employé/Ouvrier spécialisé',
      'Intermediate2To4Years': 'Intermédiaire : de 2 à 4 années'
    }
    return labels[key] || key
  }

  const getOccupationTimeLabel = () => {
    if (announcement.occupationTime === "fullTime") return "Temps plein"
    if (announcement.occupationTime === "partTime") return "Temps partiel"
    return null
  }

  const getSalaryDisplay = () => {
    if (announcement.issalarybasedonprofile) return "Selon profil"
    if (!announcement.minSalary && !announcement.maxSalary) return null
    
    const salaryType = announcement.netSalary === "raw" ? "brut" : announcement.netSalary === "net" ? "net" : ""
    let period = ""
    if (announcement.unitSalary === "month") period = " /mois"
    else if (announcement.unitSalary === "years") period = " /an"

    const isSalaryExact = announcement.salaryExact === true || announcement.salaryExact === "true"
    
    if (isSalaryExact && announcement.maxSalary) {
      const max = parseFloat(announcement.maxSalary)
      if (max === 0) return null
      return `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    if (announcement.minSalary && announcement.maxSalary) {
      const min = parseFloat(announcement.minSalary)
      const max = parseFloat(announcement.maxSalary)
      if (min === 0 && max === 0) return null
      return `${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }
    
    return null
  }

  const salary = getSalaryDisplay()

  const getCleanDescription = () => {
    if (!announcement.description) return ""
    // Créer un élément temporaire pour décoder les entités HTML
    if (typeof document !== 'undefined') {
      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = announcement.description
      // Récupérer le texte décodé
      const decodedText = tempDiv.textContent || tempDiv.innerText || ""
      // Normaliser les espaces
      const normalized = decodedText.replace(/\s+/g, ' ').trim()
      return normalized
    }
    // Fallback si document n'est pas disponible
    const cleanText = announcement.description.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  return (
    <Link href={`/announcements/jobs/${announcement.id}`}>
      <Card className={cn(
        "h-full hover:shadow-xl transition-all duration-300 overflow-hidden group border-2",
        isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-blue-200"
      )}>
        <div className="p-5">
          {/* Logo entreprise */}
          <div className="flex items-start gap-4 mb-4">
            {displayPhoto ? (
              <div className="w-16 h-16 rounded-full overflow-hidden bg-gray-100 flex-shrink-0 border-4 border-white shadow-md ring-2 ring-blue-100">
                <Image
                  src={displayPhoto.startsWith("http") ? displayPhoto : `${API_URL}${displayPhoto}`}
                  alt={displayName}
                  width={64}
                  height={64}
                  className="w-full h-full object-cover"
                />
              </div>
            ) : (
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center border-4 border-white shadow-md ring-2 ring-blue-100">
                <User className="w-8 h-8 text-white" />
              </div>
            )}

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-sm font-semibold text-gray-900 truncate">{displayName}</span>
                {isProfessional && (
                  <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs">
                    Pro
                  </Badge>
                )}
              </div>
              {isExpired && (
                <Badge className="bg-red-600 text-white text-xs">EXPIRÉ</Badge>
              )}
            </div>
          </div>

          {/* Titre */}
          <h3 className={cn(
            "font-bold text-lg mb-3 line-clamp-2 group-hover:text-blue-600 transition-colors",
            isExpired ? "text-gray-500" : "text-gray-900"
          )}>
            {announcement.title}
          </h3>

          {/* Badges d'informations */}
          <div className="flex flex-wrap gap-1.5 mb-4">
            {announcement.contractType && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <FileText className="w-3 h-3 mr-1 inline" />
                {getLabel(announcement.contractType)}
              </Badge>
            )}
            {announcement.studyLevel && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <GraduationCap className="w-3 h-3 mr-1 inline" />
                {getLabel(announcement.studyLevel)}
              </Badge>
            )}
            {announcement.xpLevel && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <Briefcase className="w-3 h-3 mr-1 inline" />
                {getLabel(announcement.xpLevel)}
              </Badge>
            )}
            {getOccupationTimeLabel() && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                <Clock className="w-3 h-3 mr-1 inline" />
                {getOccupationTimeLabel()}
              </Badge>
            )}
            {announcement.remote !== null && announcement.remote !== undefined && (
              <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                {announcement.remote === 't' || announcement.remote === true ? (
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
          {getCleanDescription() && (
            <p className="text-sm text-gray-700 mb-4 line-clamp-3 leading-relaxed break-words">
              {getCleanDescription()}
            </p>
          )}

          {/* Salaire */}
          {salary && (
            <div className="mb-4">
              <p className="text-lg font-bold text-blue-600 break-words">{salary}</p>
            </div>
          )}
        </div>
      </Card>
    </Link>
  )
}

// Composant pour les Formations
export function ProfileTrainingCard({ announcement }: { announcement: any }) {
  const isExpired = announcement.endDate ? new Date(announcement.endDate) < new Date() : false
  
  const getOrganizationName = () => {
    const companyData = announcement.companyData
    if (!companyData) return "Organisation"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const getOrganizerPhoto = () => {
    const companyData = announcement.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    if (companyData.photoprofilurl.startsWith("http")) {
      return companyData.photoprofilurl
    }
    return `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = announcement.companyData?.profiletype === "professionnel"
  const organizationName = getOrganizationName()

  const getTrainingPublicArray = () => {
    if (!announcement.trainingPublic) return []
    try {
      const cleaned = announcement.trainingPublic.replace(/[{}]/g, '')
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
      return publics.map((p: string) => publicLabels[p] || p)
    } catch {
      return []
    }
  }

  const getTrainingType = () => {
    if (!announcement.trainingType) return null
    const typeLabels: { [key: string]: string } = {
      'ApprenticeshipTraining': 'Formation en alternance',
      'ContinuingEducation': 'Formation continue',
      'DegreeProgram': 'Formation diplômante',
      'ProfessionalTraining': 'Formation professionnelle',
      'Certification': 'Certification',
      'Workshop': 'Atelier',
      'Seminar': 'Séminaire',
      'BlendedLearning': 'Formation hybride'
    }
    return typeLabels[announcement.trainingType] || announcement.trainingType
  }

  const getCleanDescription = () => {
    if (!announcement.description) return ""
    return announcement.description.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
  }

  const getTrainingStatus = () => {
    if (isExpired) return "Expiré"
    const startDate = announcement.startDate
    if (!startDate) return "Inscription ouverte"
    const start = new Date(startDate)
    const today = new Date()
    return start > today ? "À venir" : "En cours"
  }

  const trainingTypeLabel = getTrainingType()
  const status = getTrainingStatus()

  return (
    <Link href={`/announcements/trainings/${announcement.id}`}>
      <Card className={cn(
        "h-full hover:shadow-xl transition-all duration-300 overflow-hidden group border-2",
        isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-purple-200"
      )}>
        <div className="p-5">
          {/* Logo organisateur */}
          <div className="flex items-start gap-4 mb-4">
            {getOrganizerPhoto() ? (
              <div className="w-16 h-16 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0 border-2 border-white shadow-md ring-2 ring-purple-100">
                <Image
                  src={getOrganizerPhoto()!}
                  alt={organizationName}
                  width={64}
                  height={64}
                  className="w-full h-full object-cover"
                />
              </div>
            ) : (
              <div className="w-16 h-16 rounded-xl bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center border-2 border-white shadow-md ring-2 ring-purple-100">
                <User className="w-8 h-8 text-white" />
              </div>
            )}

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-sm font-semibold text-gray-900 truncate">{organizationName}</span>
                <Badge variant="outline" className={cn(
                  "text-xs",
                  isProfessional ? 'bg-blue-50 text-blue-700 border-blue-200' : 'bg-gray-50 text-gray-700 border-gray-200'
                )}>
                  {isProfessional ? 'Pro' : 'Particulier'}
                </Badge>
              </div>
              <Badge variant="outline" className="text-xs">
                {status}
              </Badge>
            </div>
          </div>

          {/* Titre */}
          <h3 className="font-bold text-lg mb-3 line-clamp-2 group-hover:text-purple-600 transition-colors">
            {announcement.title}
          </h3>

          {/* Badges d'informations */}
          <div className="flex flex-wrap gap-1.5 mb-4">
            {/* Public cible */}
            {getTrainingPublicArray().length > 0 && getTrainingPublicArray().map((publicLabel: string, index: number) => (
              <Badge 
                key={index} 
                variant="outline" 
                className="text-xs bg-blue-50 text-blue-700 border-blue-200"
              >
                {publicLabel}
              </Badge>
            ))}
            
            {/* Type de formation */}
            {trainingTypeLabel && (
              <Badge variant="outline" className="text-xs bg-purple-50 text-purple-700 border-purple-200">
                {trainingTypeLabel}
              </Badge>
            )}
          </div>

          {/* Description */}
          <p className="text-sm text-gray-600 line-clamp-2 mb-4 leading-relaxed break-words">
            {getCleanDescription()}
          </p>

          {/* Durée */}
          {announcement.trainingDuration && (
            <div className="flex items-center gap-1 text-sm text-gray-600">
              <Clock className="w-4 h-4" />
              <span>{announcement.trainingDuration}</span>
            </div>
          )}
        </div>
      </Card>
    </Link>
  )
}

// Composant pour les Événements
export function ProfileEventCard({ announcement }: { announcement: any }) {
  const [imageError, setImageError] = useState(false)
  
  const isExpired = (announcement.eventDurationType === "permanent" || announcement.isAllDays) 
    ? false 
    : (announcement.endDate ? new Date(announcement.endDate) < new Date() : false)

  const getOrganizerName = () => {
    const companyData = announcement.companyData
    if (!companyData) return "Organisateur"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || announcement.userPseudo || "Particulier"
  }

  const getOrganizerPhoto = () => {
    const companyData = announcement.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    return companyData.photoprofilurl.startsWith("http") 
      ? companyData.photoprofilurl 
      : `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = announcement.companyData?.profiletype === "professionnel"

  const getEventStatus = () => {
    if (isExpired) return { label: "Passé", color: "bg-gray-500" }
    
    if (announcement.eventDurationType === "permanent" || announcement.isAllDays) {
      return { label: "Permanent", color: "bg-blue-500" }
    }

    const eventDate = announcement.eventDate || announcement.startDate
    if (!eventDate) return { label: "À venir", color: "bg-orange-500" }

    const eventDateTime = new Date(eventDate)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const diffTime = eventDateTime.getTime() - today.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays < 0) return { label: "Passé", color: "bg-gray-500" }
    if (diffDays === 0) return { label: "Aujourd'hui", color: "bg-green-500" }
    if (diffDays === 1) return { label: "Demain", color: "bg-blue-500" }
    if (diffDays <= 7) return { label: "Cette semaine", color: "bg-blue-500" }
    
    return { label: "À venir", color: "bg-orange-500" }
  }

  const status = getEventStatus()

  const formatEventDate = () => {
    if (announcement.eventDurationType === "permanent" || announcement.isAllDays) {
      return "Permanent"
    }
    
    const eventDate = announcement.eventDate || announcement.startDate
    if (!eventDate) return "Date à définir"
    
    const date = new Date(eventDate)
    return date.toLocaleDateString("fr-FR", { 
      day: "numeric", 
      month: "long", 
      year: "numeric" 
    })
  }

  const formatAddress = (address: any) => {
    if (!address) return null
    if (typeof address === "string") return address
    const parts = []
    if (address.ville || address.city) parts.push(address.ville || address.city)
    return parts.join(", ") || null
  }

  const getFormattedLocation = () => {
    if (announcement.eventCity) return announcement.eventCity
    if (announcement.eventLocation) {
      if (typeof announcement.eventLocation === 'string') {
        return announcement.eventLocation
      }
      return formatAddress(announcement.eventLocation)
    }
    if (announcement.address) {
      return formatAddress(announcement.address)
    }
    return null
  }

  const getFormattedPrice = () => {
    const price = announcement.eventPrice || announcement.price
    const priceType = announcement.priceType
    
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

  const imageUrl = announcement.images && announcement.images[0] ? getImageUrl(announcement.images[0]) : null
  const location = getFormattedLocation()
  const price = getFormattedPrice()

  return (
    <Link href={`/announcements/events/${announcement.id}`}>
      <Card className={cn(
        "h-full hover:shadow-xl transition-all duration-300 overflow-hidden group border-2",
        isExpired ? "opacity-60 border-gray-200" : "border-gray-200 hover:border-orange-300"
      )}>
        {/* Image */}
        <div className="relative h-48 bg-gradient-to-br from-orange-100 via-orange-50 to-pink-50 overflow-hidden">
          {isExpired && (
            <div className="absolute inset-0 bg-black/40 z-10 flex items-center justify-center">
              <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
            </div>
          )}
          {imageUrl && !imageError ? (
            <Image
              src={imageUrl}
              alt={announcement.title}
              fill
              className={cn(
                "object-cover group-hover:scale-110 transition-transform duration-300",
                isExpired && "grayscale brightness-75"
              )}
              onError={() => setImageError(true)}
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <Clock className="w-16 h-16 text-orange-300" />
            </div>
          )}
        </div>

        <div className="p-5">
          {/* Organisateur */}
          <div className="flex items-center gap-2 mb-3">
            {getOrganizerPhoto() ? (
              <img 
                src={getOrganizerPhoto()!} 
                alt={getOrganizerName()} 
                className="w-8 h-8 rounded-full object-cover ring-2 ring-orange-100" 
              />
            ) : (
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-orange-400 to-orange-500 flex items-center justify-center">
                <User className="w-4 h-4 text-white" />
              </div>
            )}
            <div className="flex items-center gap-2">
              <span className="text-sm font-semibold text-gray-700">{getOrganizerName()}</span>
              {isProfessional && (
                <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs">
                  Pro
                </Badge>
              )}
            </div>
          </div>

          {/* Badges */}
          <div className="flex flex-wrap gap-1.5 mb-3">
            <Badge className={cn("text-white border-0", status.color)}>
              {status.label}
            </Badge>
          </div>

          {/* Titre */}
          <h3 className={cn(
            "font-bold text-lg mb-3 line-clamp-2 group-hover:text-orange-600 transition-colors",
            isExpired ? "text-gray-400" : "text-gray-900"
          )}>
            {announcement.title}
          </h3>

          {/* Date */}
          <div className="flex items-center gap-2 bg-orange-50 px-3 py-2 rounded-lg mb-3">
            <Clock className="w-4 h-4 text-orange-600" />
            <span className="text-sm font-semibold text-orange-900">{formatEventDate()}</span>
          </div>

          {/* Localisation */}
          {location && (
            <div className="flex items-center gap-2 text-sm text-gray-600 mb-3">
              <MapPin className="w-4 h-4 text-orange-500" />
              <span className="truncate">{location}</span>
            </div>
          )}

          {/* Prix */}
          <div className="flex items-center justify-between pt-3 border-t">
            <span className="text-lg font-bold text-orange-600">{price}</span>
            <span className="flex items-center gap-1 text-sm text-gray-500">
              <Eye className="w-4 h-4" />
              {announcement.views || 0}
            </span>
          </div>
        </div>
      </Card>
    </Link>
  )
}

// Composant pour les Demandes
export function ProfileInquiryCard({ announcement }: { announcement: any }) {
  const [imageError, setImageError] = useState(false)
  const isExpired = announcement.endDate ? new Date(announcement.endDate) < new Date() : false
  
  const getUserDisplayName = () => {
    const companyData = announcement.companyData || announcement.userInfo
    if (!companyData) return "Utilisateur"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const getUserPhoto = () => {
    const companyData = announcement.companyData || announcement.userInfo
    if (!companyData || !companyData.photoprofilurl) return null
    if (companyData.photoprofilurl.startsWith("http")) {
      return companyData.photoprofilurl
    }
    return `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = announcement.userInfo?.profiletype === "professionnel" || announcement.companyData?.profiletype === "professionnel"
  const userName = getUserDisplayName()
  const userAvatar = getUserPhoto()
  
  const displayTitle = announcement.inquiryTitle || announcement.title || "Demande sans titre"
  const displayDescription = announcement.inquiryDescription || announcement.description || ""

  const getCleanDescription = () => {
    if (!displayDescription) return ""
    return displayDescription.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim()
  }

  const formatAddress = (address: any) => {
    if (!address) return null
    if (typeof address === "string") return address
    const parts = []
    if (address.ville || address.city) parts.push(address.ville || address.city)
    if (address.codepostal || address.zipcode) parts.push(address.codepostal || address.zipcode)
    return parts.join(", ") || null
  }

  const location = formatAddress(announcement.address)

  const getInquiryCategory = () => {
    const categoryLabels: { [key: string]: string } = {
      'RealEstate': 'Immobilier',
      'JobSearchInternship': 'Emploi / Stage',
      'Training': 'Formation',
      'ServicesAssistance': 'Services / Assistance'
    }
    return categoryLabels[announcement.inquiryType] || announcement.inquiryType || "Demande"
  }

  const getInquiryNature = () => {
    if (announcement.inquiryTypeCategory) {
      const natureLabels: { [key: string]: string } = {
        'LookingForProfessionalSpace': 'Recherche local professionnel',
        'LookingForRental': 'Recherche location',
        'LookingForPurchase': 'Recherche achat',
        'JobSearch': 'Recherche emploi',
        'InternshipSearch': 'Recherche stage',
        'ServiceProvision': 'Prestation de service',
        'ServiceRequest': 'Demande de service'
      }
      return natureLabels[announcement.inquiryTypeCategory] || announcement.inquiryTypeCategory
    }
    return null
  }

  const category = getInquiryCategory()
  const nature = getInquiryNature()

  return (
    <Link href={`/announcements/inquiries/${announcement.id}`}>
      <Card className={cn(
        "h-full hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group border-0 bg-white/90 backdrop-blur-md",
        isExpired ? "opacity-60 grayscale" : "hover:shadow-indigo-200/60"
      )}>
        <div className="p-5 h-full flex flex-col">
          {/* Header avec user info */}
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
                <User className="w-6 h-6 text-white" />
              </div>
            )}

            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5 mb-0.5">
                <p className="font-semibold text-gray-900 text-sm truncate">{userName}</p>
                <span className="text-xs text-gray-500">• {isProfessional ? "Pro" : "Particulier"}</span>
              </div>
              {nature && (
                <p className="text-xs text-gray-600">{nature}</p>
              )}
            </div>
          </div>

          {/* Badges */}
          <div className="flex items-center gap-1.5 mb-3 flex-wrap">
            <Badge className="bg-gradient-to-r from-indigo-500 to-indigo-600 text-white border-0 shadow-md text-xs">
              {category}
            </Badge>
            {isExpired && (
              <Badge className="bg-red-600 text-white border-0 text-xs">EXPIRÉ</Badge>
            )}
          </div>

          {/* Titre */}
          <h3 className={cn(
            "text-lg font-bold mb-2 line-clamp-2 group-hover:text-indigo-600 transition-colors",
            isExpired ? "text-gray-400" : "text-gray-900"
          )}>
            {displayTitle}
          </h3>

          {/* Localisation et rayon */}
          <div className="flex items-center gap-3 text-xs text-gray-500 mb-3 flex-wrap">
            {location && (
              <div className="flex items-center gap-1">
                <MapPin className="w-3.5 h-3.5 text-indigo-500" />
                <span className="truncate">{location}</span>
              </div>
            )}
            {announcement.ray && (
              <div className="flex items-center gap-1">
                <MapPin className="w-3.5 h-3.5 text-indigo-500" />
                <span>{announcement.ray === "0" ? "Toute la France" : `Rayon ${announcement.ray}km`}</span>
              </div>
            )}
          </div>

          {/* Description */}
          <p className="text-sm text-gray-600 line-clamp-3 mb-4 flex-1">
            {getCleanDescription()}
          </p>

          {/* Stats */}
          <div className="flex items-center gap-4 text-gray-500 pt-3 border-t">
            <span className="flex items-center gap-1 text-sm">
              <Eye className="w-4 h-4" />
              {announcement.views || 0}
            </span>
            <span className="flex items-center gap-1 text-sm">
              <MessageCircle className="w-4 h-4" />
              0
            </span>
          </div>
        </div>
      </Card>
    </Link>
  )
}
