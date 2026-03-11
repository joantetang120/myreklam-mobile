"use client"

import { useEffect, useState, useMemo, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { motion } from "framer-motion"
import {
  Plus,
  Bell,
  MapPin,
  GraduationCap,
  Clock,
  Search,
  Filter,
  Grid3x3,
  List,
  ChevronDown,
  ChevronUp,
  Locate,
  Heart,
  Share2,
  Users,
  Star,
  Calendar,
  User,
} from "lucide-react"
import { fetchAnnoncements, toggleFavorite } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { Checkbox } from "@/components/ui/checkbox"
import { useToast } from "@/hooks/use-toast"
import { config } from "@/lib/config"
import { SaveSearchButton } from "@/components/save-search-button"
import { ShareModal } from "@/components/share-modal"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import citiesData from "@/lib/data/france-cities.json"
import { getCoordsFromAddress } from "@/lib/data/zipcode-coords"
import useInfiniteRender from "@/hooks/useInfiniteRender"

const API_URL = config?.API_URL;

function formatAddress(address: any): string {
  if (!address) return ""

  // Si c'est une string, essayer de la parser comme JSON
  if (typeof address === "string") {
    try {
      const parsed = JSON.parse(address)
      return formatAddress(parsed) // Récursion avec l'objet parsé
    } catch {
      return address // Si ce n'est pas du JSON, retourner tel quel
    }
  }

  // Si c'est un objet
  if (typeof address === "object") {
    const parts = []
    
    // Ignorer lat et lng
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

interface Training {
  id: string
  title: string
  description: string
  trainingLevel?: string
  trainingFormat?: string
  trainingDuration?: string
  trainingPrice?: string
  price?: string
  location?: string | any
  address?: string | any
  startDate?: string
  trainingCertification?: string
  certification?: string
  images?: string[]
  userId?: string
  createdat?: string
  endDate?: string
  trainingType?: string
  trainingCategory?: string
  trainingPublic?: string
  trainingFunding?: string
  trainingStyle?: string
  trainingSubCategory?: string
  requiredLevels?: string
  isQualiopiCertified?: string
  durationInH?: string
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
  userProfileType?: string
  userPhotoUrl?: string
  rating?: number
  reviewCount?: number
  studentCount?: number
  skills?: string[]
  status?: string
  isFavorite?: boolean
  number_view?: number
  [key: string]: any
}

function getOrganizationName(training: Training): string {
  return training.companyData?.nomsociete || training.userNomsociete || training.userPseudo || "Centre de formation"
}

function getTimeAgo(date: string | undefined): string {
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

function TrainingCard({ training, viewMode }: { training: Training; viewMode: "grid" | "list" }) {
  const [isFavorite, setIsFavorite] = useState(training.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const isExpired = training.endDate ? new Date(training.endDate) < new Date() : false
  const organizationName = getOrganizationName(training)
  const timeAgo = getTimeAgo(training.createdat)

  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!training.description) return ""
    // Créer un élément temporaire pour décoder les entités HTML
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = training.description
    // Récupérer le texte décodé
    const decodedText = tempDiv.textContent || tempDiv.innerText || ""
    // Normaliser les espaces
    const normalized = decodedText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  // Parser le public cible - retourne un tableau pour affichage en badges
  const getTrainingPublicArray = () => {
    if (!training.trainingPublic) return []
    try {
      const cleaned = training.trainingPublic.replace(/[{}]/g, '')
      const publics = cleaned.split(',').map(p => p.trim()).filter(Boolean)
      
      // Si AllPublic est présent, afficher uniquement "Tout public"
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
      const labels = publics.map(p => publicLabels[p] || p)
      return labels.length > 0 ? labels : []
    } catch {
      return []
    }
  }

  // Formater la durée en heures
  const getFormattedDuration = () => {
    if (!training.durationInH) return null
    const hours = parseFloat(training.durationInH)
    if (isNaN(hours) || hours === 0) return null
    return `${hours}h`
  }

  // Obtenir le type de formation
  const getTrainingType = () => {
    if (!training.trainingType) return null
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
    return typeLabels[training.trainingType] || `${training.trainingType} (${training.trainingType})`
  }

  const trainingTypeLabel = getTrainingType()

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
      const result = await toggleFavorite(userId, training.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Training] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, training.title)
      }
    } catch (error) {
      console.error("[Favorite Training] Erreur:", error)
    }
  }

    // Fonction pour obtenir la photo de l'organisateur
  const getOrganizerPhoto = () => {
    const companyData = training.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    
    // Si l'URL commence déjà par http, la retourner telle quelle
    if (companyData.photoprofilurl.startsWith("http")) {
      return companyData.photoprofilurl
    }
    
    // Sinon, ajouter le préfixe API_URL
    return `${API_URL}${companyData.photoprofilurl}`
  }

    // Déterminer si c'est un professionnel
  const isProfessional = training.companyData?.profiletype === "professionnel"

  // Obtenir le prix formaté avec HT/TTC, par groupe/personne, et par jour/heure/mois
  const getFormattedPrice = () => {
    const price = training.trainingPrice || training.price
    if (!price) return "Prix sur demande"
    
    const numPrice = Number.parseFloat(price)
    if (numPrice === 0) return "Gratuit"
    
    // Construire le texte du prix
    let priceText = `${numPrice.toFixed(2)} €`
    
    // Ajouter HT ou TTC selon priceType
    // priceType: "1" = HT, "2" = TTC, autres = pas de mention
    if (training.priceType === "1") {
      priceText += " HT"
    } else if (training.priceType === "2") {
      priceText += " HT"
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

  // Obtenir la localisation formatée
  const getFormattedLocation = () => {
    if (training.address) {
      return formatAddress(training.address)
    }
    if (training.location) {
      return formatAddress(training.location)
    }
    return null
  }

  // Obtenir le statut de la formation
  const getTrainingStatus = () => {
    if (isExpired) return "Expiré"
    
    const startDate = training.startDate
    if (!startDate) return "Inscription ouverte"
    
    const start = new Date(startDate)
    const today = new Date()
    
    if (start > today) {
      return "À venir"
    } else {
      return "En cours"
    }
  }

  
  // Obtenir les compétences (si disponibles dans les données réelles)
  const getSkills = () => {
    // Priorité aux vraies données si disponibles
    if (training.skills && Array.isArray(training.skills)) {
      return training.skills
    }
    
    // Sinon, essayer d'extraire depuis la description ou autres champs
    const skills: string[] = []
    
    // Ajouter la catégorie comme compétence si disponible
    if (training.trainingCategory) {
      skills.push(training.trainingCategory)
    }
    
    // Ajouter le type de formation
    if (training.trainingType) {
      skills.push(training.trainingType)
    }
    
    return skills.slice(0, 4) // Limiter à 4 compétences
  }

  const skills = getSkills()
  const status = getTrainingStatus()



  // Mock data for demonstration (in production, these would come from the API)
  const rating = training.rating || (Math.random() * 1 + 4).toFixed(1)
  const reviewCount = training.reviewCount || Math.floor(Math.random() * 1000 + 100)
  const studentCount = training.studentCount || Math.floor(Math.random() * 2000 + 500)
  // const skills = training.skills || []
  // const status =
  //   training.status || (training.startDate && new Date(training.startDate) > new Date() ? "À venir" : "Déjà commencée")

  const logoUrl = training.companyData?.photoprofilurl || training.userPhotoUrl

  if (viewMode === "list") {
    return (
      <>
        <Link href={`/announcements/trainings/${training.id}`}>
        <Card
          className={`hover:shadow-xl hover:scale-[1.01] transition-all duration-300 overflow-hidden group cursor-pointer border-2 ${
            isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-purple-200"
          }`}
        >
          <div className="flex gap-6 p-6">
            {/* Logo/Image */}
            <div className="flex-shrink-0 relative">
              {/* {isExpired && (
                <div className="absolute inset-0 bg-black/30 rounded-lg z-10 flex items-center justify-center">
                  <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg text-xs">
                    EXPIRÉ
                  </Badge>
                </div>
              )} */}
              {/* {logoUrl ? (
                <div
                  className={`w-20 h-20 rounded-lg overflow-hidden bg-gray-100 flex items-center justify-center ${
                    isExpired ? "grayscale brightness-75" : ""
                  }`}
                >
                  <img
                    src={logoUrl.startsWith("http") ? logoUrl : `${API_URL}${logoUrl}`}
                    alt={organizationName}
                    className="w-full h-full object-cover"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement
                      target.style.display = "none"
                      target.parentElement!.innerHTML = `
                        <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-purple-100 to-purple-50">
                          <svg class="w-10 h-10 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                          </svg>
                        </div>
                      `
                    }}
                  />
                </div>
              ) : (
                <div
                  className={`w-20 h-20 rounded-lg bg-gradient-to-br from-purple-100 to-purple-50 flex items-center justify-center ${
                    isExpired ? "grayscale brightness-75" : ""
                  }`}
                >
                  <GraduationCap className="w-10 h-10 text-purple-400" />
                </div>
              )} */}

               {getOrganizerPhoto() ? (
                <div
                  className={`w-24 h-24 rounded-xl overflow-hidden bg-gray-100 flex items-center justify-center border-4 border-white shadow-lg ring-2 ring-purple-100 ${
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
                          <svg class="w-10 h-10 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
                          </svg>
                        </div>
                      `
                    }}
                  />
                </div>
              ) : (
                <div
                  className={`w-24 h-24 rounded-xl bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center border-4 border-white shadow-lg ring-2 ring-purple-100 ${
                    isExpired ? "grayscale brightness-75" : ""
                  }`}
                >
                  <GraduationCap className="w-12 h-12 text-white" />
                </div>
              )}
            </div>

            {/* Content */}
            <div className="flex-1 min-w-0">
              <div className="flex items-start justify-between mb-2">
                <div className="flex-1">
                  {/* Organization name with Pro/Particulier badge */}
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-sm font-semibold text-gray-900">{organizationName}</span>
                    <Badge variant="outline" className={`text-xs ${isProfessional ? 'bg-blue-50 text-blue-700 border-blue-200' : 'bg-gray-50 text-gray-700 border-gray-200'}`}>
                      {isProfessional ? 'Pro' : 'Particulier'}
                    </Badge>
                  </div>
                  
                  {/* Title */}
                  <h3
                    className={`font-bold text-2xl mb-2 group-hover:text-purple-600 transition-colors line-clamp-1 ${
                      isExpired ? "text-gray-500" : "text-gray-900"
                    }`}
                  >
                    {training.title}
                  </h3>
                </div>
                <div className="flex items-center gap-2 ml-4">
                  {training.trainingLevel && (
                    <Badge variant="secondary" className="bg-purple-100 text-purple-700 border-purple-200">
                      {training.trainingLevel}
                    </Badge>
                  )}
                  <Badge variant="outline" className="text-xs">
                    {status}
                  </Badge>

                  {/* {isExpired && <Badge className="bg-red-600 text-white border-2 border-white font-bold">EXPIRÉ</Badge>} */}
                  <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100" onClick={handleFavorite}>
                    <Heart className={`w-4 h-4 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100" onClick={handleShare}>
                    <Share2 className="w-4 h-4 text-gray-400" />
                  </Button>
                </div>
              </div>

              {/* Key info row */}
              <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600 mb-3">
                {training.trainingDuration && (
                  <div className="flex items-center gap-1">
                    <Clock className="w-4 h-4" />
                    <span>{training.trainingDuration}</span>
                  </div>
                )}
                {getTrainingPublicArray().length > 0 && (
                  <div className="flex items-start gap-1.5">
                    <User className="w-4 h-4 flex-shrink-0 mt-0.5" />
                    <div className="flex flex-wrap gap-1.5">
                      {getTrainingPublicArray().map((publicLabel, index) => (
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
                {/* <div className="flex items-center gap-1">
                  <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                  <span className="font-medium">{rating}</span>
                </div> */}

                 {/* {getFormattedLocation() && (
                  <div className="flex items-center gap-1">
                    <MapPin className="w-4 h-4" />
                    <span className="truncate max-w-[100px] sm:max-w-[150px]">{getFormattedLocation()}</span>
                  </div>
                )} */}

                {/* <div className="flex items-center gap-1">
                  <Calendar className="w-4 h-4" />
                  <span>{status}</span>
                </div> */}
                {/* {training.location && (
                  <div className="flex items-center gap-1">
                    <MapPin className="w-4 h-4" />
                    <span className="truncate max-w-[100px] sm:max-w-[150px]">{formatAddress(training.location)}</span>
                  </div>
                )} */}
              </div>

              {/* Description */}
              <p className="text-sm text-gray-600 line-clamp-2 mb-3 leading-relaxed">{getCleanDescription()}</p>

              {/* Type de formation */}
              {trainingTypeLabel && (
                <div className="mb-3">
                  <Badge variant="outline" className="text-xs bg-purple-50 text-purple-700 border-purple-200 truncate max-w-full">
                    <span className="truncate">{trainingTypeLabel}</span>
                  </Badge>
                </div>
              )}

              {/* Bottom row */}
              {/* <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  {training.trainingPrice && (
                    <div
                      className={`text-2xl font-bold ${isExpired ? "text-gray-400 line-through" : "text-orange-500"}`}
                    >
                      {training.trainingPrice}€
                    </div>
                  )}
                  <div className="flex items-center gap-1 text-sm text-gray-500">
                    <Users className="w-4 h-4" />
                    <span>{studentCount} étudiants</span>
                  </div>
                </div>
                <Button
                  className={
                    isExpired ? "bg-gray-400 cursor-not-allowed" : "bg-purple-500 hover:bg-purple-600 text-white"
                  }
                  disabled={isExpired}
                >
                  {isExpired ? "Expiré" : "Voir la formation"}
                </Button>
              </div> */}
                <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="text-sm text-gray-500">
                    {timeAgo}
                  </div>
                </div>
                {/* <Button
                  className={
                    isExpired ? "bg-gray-400 cursor-not-allowed" : "bg-purple-500 hover:bg-purple-600 text-white"
                  }
                  disabled={isExpired}
                >
                  {isExpired ? "Expiré " : "Voir la formation"}
                </Button> */}
              </div>
            </div>
          </div>
        </Card>
        </Link>
        <ShareModal
          isOpen={showShareModal}
          onClose={() => setShowShareModal(false)}
          title={training.title}
          url={`/announcements/trainings/${training.id}`}
          description={training.description}
        />
      </>
    )
  }

  // Grid view
  // return (
  //   <Link href={`/announcements/trainings/${training.id}`}>
  //     <Card
  //       className={`h-full hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer ${
  //         isExpired ? "opacity-75 border-2 border-red-500" : ""
  //       }`}
  //     >
  //       {/* Logo and badges */}
  //       <div className="p-4 pb-0 relative">
  //         {isExpired && (
  //           <div className="absolute top-3 left-3 z-10">
  //             <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg text-xs">EXPIRÉ</Badge>
  //           </div>
  //         )}

  //         <div className="flex items-start justify-between mb-3">
  //           <div className="flex-shrink-0">
  //             {logoUrl ? (
  //               <div
  //                 className={`w-16 h-16 rounded-lg overflow-hidden bg-gray-100 flex items-center justify-center ${
  //                   isExpired ? "grayscale brightness-75" : ""
  //                 }`}
  //               >
  //                 <img
  //                   src={logoUrl.startsWith("http") ? logoUrl : `${API_URL}${logoUrl}`}
  //                   alt={organizationName}
  //                   className="w-full h-full object-cover"
  //                   onError={(e) => {
  //                     const target = e.target as HTMLImageElement
  //                     target.style.display = "none"
  //                     target.parentElement!.innerHTML = `
  //                       <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-purple-100 to-purple-50">
  //                         <svg class="w-8 h-8 text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
  //                           <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path>
  //                         </svg>
  //                       </div>
  //                     `
  //                   }}
  //                 />
  //               </div>
  //             ) : (
  //               <div
  //                 className={`w-16 h-16 rounded-lg bg-gradient-to-br from-purple-100 to-purple-50 flex items-center justify-center ${
  //                   isExpired ? "grayscale brightness-75" : ""
  //                 }`}
  //               >
  //                 <GraduationCap className="w-8 h-8 text-purple-400" />
  //               </div>
  //             )}
  //           </div>
  //           <div className="flex items-center gap-2">
  //             {training.trainingLevel && (
  //               <Badge variant="secondary" className="bg-purple-100 text-purple-700 border-purple-200 text-xs">
  //                 {training.trainingLevel}
  //               </Badge>
  //             )}
  //             <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100">
  //               <Heart className="w-4 h-4 text-gray-400" />
  //             </Button>
  //             <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100">
  //               <Share2 className="w-4 h-4 text-gray-400" />
  //             </Button>
  //           </div>
  //         </div>

  //         {/* Title and organization */}
  //         <h3
  //           className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-purple-600 transition-colors ${
  //             isExpired ? "text-gray-500" : "text-gray-900"
  //           }`}
  //         >
  //           {training.title}
  //         </h3>
  //         <p className="text-sm text-gray-600 mb-3">{organizationName}</p>

  //         {/* Description */}
  //         <p className="text-sm text-gray-600 line-clamp-2 mb-4 min-h-[2.5rem]">{training.description}</p>

  //         {/* Key info grid */}
  //         <div className="grid grid-cols-2 gap-y-2 text-sm mb-4">
  //           <div className="flex items-center gap-1 text-gray-600">
  //             <Clock className="w-4 h-4 flex-shrink-0" />
  //             <span className="truncate">{training.trainingDuration || "Non spécifié"}</span>
  //           </div>
  //           <div className="flex items-center gap-1 text-gray-600">
  //             <User className="w-4 h-4 flex-shrink-0" />
  //             <span className="truncate">{training.trainingFormat || "Non spécifié"}</span>
  //           </div>
  //           <div className="flex items-center gap-1 text-gray-600">
  //             <Users className="w-4 h-4 flex-shrink-0" />
  //             <span className="truncate">{studentCount} étudiants</span>
  //           </div>
  //           <div className="flex items-center gap-1 text-gray-600">
  //             <Calendar className="w-4 h-4 flex-shrink-0" />
  //             <span className="truncate">{status}</span>
  //           </div>
  //         </div>

  //         {/* Rating */}
  //         <div className="flex items-center gap-2 mb-4">
  //           <div className="flex items-center gap-1">
  //             <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
  //             <span className="font-semibold text-sm">{rating}</span>
  //           </div>
  //           <span className="text-xs text-gray-500">({reviewCount} avis)</span>
  //         </div>

  //         {/* Skills */}
  //         {skills.length > 0 && (
  //           <div className="mb-4">
  //             <p className="text-xs font-semibold text-gray-700 mb-2">Compétences acquises :</p>
  //             <div className="flex flex-wrap gap-1.5">
  //               {skills.slice(0, 3).map((skill, index) => (
  //                 <Badge key={index} variant="outline" className="text-xs">
  //                   {skill}
  //                 </Badge>
  //               ))}
  //               {skills.length > 3 && (
  //                 <Badge variant="outline" className="text-xs text-gray-500">
  //                   +{skills.length - 3}
  //                 </Badge>
  //               )}
  //             </div>
  //           </div>
  //         )}
  //       </div>

  //       {/* Price and CTA */}
  //       <div className="px-4 pb-4 pt-2 border-t">
  //         <div className="flex items-center justify-between">
  //           {training.trainingPrice ? (
  //             <div className={`text-2xl font-bold ${isExpired ? "text-gray-400 line-through" : "text-orange-500"}`}>
  //               {training.trainingPrice}€
  //             </div>
  //           ) : (
  //             <div className="text-sm text-gray-500">Prix sur demande</div>
  //           )}
  //           <Button
  //             className={isExpired ? "bg-gray-400 cursor-not-allowed" : "bg-purple-500 hover:bg-purple-600 text-white"}
  //             disabled={isExpired}
  //           >
  //             {isExpired ? "Expiré" : "Voir la formation"}
  //           </Button>
  //         </div>
  //       </div>
  //     </Card>
  //   </Link>
  // )

   return (
    <>
      <Link href={`/announcements/trainings/${training.id}`}>
      <Card
        className={`h-full hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer ${
          isExpired ? "opacity-75 border-2 border-red-500" : ""
        }`}
      >
        {/* Logo and badges */}
        <div className="p-4 pb-0 relative">
          {/* {isExpired && (
            <div className="absolute top-3 left-3 z-10">
              <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg text-xs">EXPIRÉ</Badge>
            </div>
          )} */}

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
              {training.trainingLevel && (
                <Badge variant="secondary" className="bg-purple-100 text-purple-700 border-purple-200 text-xs">
                  {training.trainingLevel}
                </Badge>
              )}
              {/* <Badge variant="outline" className="text-xs">
                {status}
              </Badge> */}
              <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100" onClick={handleFavorite}>
                <Heart className={`w-4 h-4 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
              </Button>
              <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-gray-100" onClick={handleShare}>
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
            {training.title}
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
                  {getTrainingPublicArray().map((publicLabel, index) => (
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
      title={training.title}
      url={`/announcements/trainings/${training.id}`}
      description={training.description}
    />
    </>
  )
}

function TrainingsPage() {
  const router = useRouter()
  const params = useSearchParams()
  const { toast } = useToast()

  const [searchQuery, setSearchQuery] = useState(params.get("q") || "")
  const [showFilters, setShowFilters] = useState(false)
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid")
  const [sortBy, setSortBy] = useState("recent")
  const [selectedLevel, setSelectedLevel] = useState("all")
  const [selectedFormat, setSelectedFormat] = useState("all")
  const [selectedDuration, setSelectedDuration] = useState("all")
  const [selectedCertification, setSelectedCertification] = useState("all")
  const [location, setLocation] = useState(params.get("location") || "")
  const [searchRadius, setSearchRadius] = useState(parseInt(params.get("radius") || "10"))
  const [searchAllFrance, setSearchAllFrance] = useState(params.get("allFrance") === "true")
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
  
  const [allTrainings, setAllTrainings] = useState<Training[]>([])
  const [currentPage, setCurrentPage] = useState(1)
  const [trainingsPerPage] = useState(20)
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
      setSearchRadius(parseInt(radiusParam))
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
    const loadAllTrainings = async () => {
      setIsLoading(true)
      try {
        const result = await fetchAnnoncements({ category: "formations" })
        if (result.success) {
          setAllTrainings(result.deals)
        } else {
          console.error("Erreur lors du chargement des annonces:", result.error)
          setAllTrainings([])
        }
      } catch (error) {
        console.error("Exception lors du chargement des annonces:", error)
        setAllTrainings([])
      } finally {
        setIsLoading(false)
      }
    }
    loadAllTrainings()
  }, [])

  // Fonction utilitaire pour formater la localisation
  const getFormattedLocation = (training: Training): string => {
    if (!training.location && !training.address) return ""
    
    const locationData = training.location || training.address
    
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

  // Fonction utilitaire pour obtenir le nom de l'organisateur
  const getOrganizerName = (training: Training): string => {
    const companyData = training.companyData
    if (!companyData) return "Organisation"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Organisation"
    }
    return companyData.pseudo || training.userPseudo || "Particulier"
  }

  const handleUseGeolocation = async () => {
    if (searchAllFrance) return

    setIsGettingLocation(true)
    try {
      if (!navigator.geolocation) {
        toast({
          title: "Géolocalisation non disponible",
          description: "Votre navigateur ne supporte pas la géolocalisation.",
          variant: "destructive",
        })
        return
      }

      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords
          try {
            const response = await fetch(
              `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&accept-language=fr`,
            )
            const data = await response.json()
            const city = data.address?.city || data.address?.town || data.address?.village || "Ma position"
            setLocation(city)
            
            // Mettre à jour l'URL avec les coordonnées GPS
            const newParams = new URLSearchParams(params.toString())
            newParams.set("location", city)
            newParams.set("lat", latitude.toString())
            newParams.set("lng", longitude.toString())
            router.push(`?${newParams.toString()}`, { scroll: false })
            
            toast({
              title: "Position détectée",
              description: `Votre position a été détectée : ${city}`,
            })
          } catch (error) {
            setLocation("Ma position")
            
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
    } catch (error) {
      setIsGettingLocation(false)
      toast({
        title: "Erreur",
        description: "Une erreur est survenue.",
        variant: "destructive",
      })
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

    router.push("/announcements/create/trainings")
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
      description: "Vous serez notifié des nouvelles formations.",
    })
  }

  // Mise à jour du filtrage
  const filteredTrainings = useMemo(() => {
    if (allTrainings.length === 0) return []

    const filtered = allTrainings.filter((training) => {
      const isExpired = training.endDate ? new Date(training.endDate) < new Date() : false
      if (!showExpired && isExpired) return false

      // Recherche étendue
      if (searchQuery) {
        const query = searchQuery.toLowerCase()
        const matchesSearch =
          training.title.toLowerCase().includes(query) ||
          training.description?.toLowerCase().includes(query) ||
          getOrganizerName(training)?.toLowerCase().includes(query) ||
          getFormattedLocation(training)?.toLowerCase().includes(query)
        if (!matchesSearch) return false
      }

      if (selectedLevel !== "all" && training.trainingLevel !== selectedLevel) return false
      if (selectedFormat !== "all" && training.trainingFormat !== selectedFormat) return false
      if (selectedDuration !== "all" && training.trainingDuration !== selectedDuration) return false
      if (selectedCertification !== "all") {
        if (selectedCertification === "certified" && !training.trainingCertification) return false
        if (selectedCertification === "not-certified" && training.trainingCertification) return false
      }

      // Filtre par localisation avec calcul de distance
      if (location && !searchAllFrance) {
        try {
          // Si on a des coordonnées de recherche valides et un rayon
          if (searchCoords.lat !== 0 && searchCoords.lng !== 0 && searchRadius > 0) {
            let trainingLat = 0
            let trainingLng = 0
            let trainingCity = ""
            let trainingZipcode = ""

            if (training.address) {
              if (typeof training.address === 'string') {
                try {
                  const addressObj = JSON.parse(training.address)
                  trainingLat = parseFloat(addressObj.latitude || addressObj.lat || 0)
                  trainingLng = parseFloat(addressObj.longitude || addressObj.lng || addressObj.lon || 0)
                  trainingCity = addressObj.city || ""
                  trainingZipcode = addressObj.zipcode || ""
                } catch {}
              } else if (typeof training.address === 'object') {
                trainingLat = parseFloat(training.address.latitude || training.address.lat || 0)
                trainingLng = parseFloat(training.address.longitude || training.address.lng || training.address.lon || 0)
                trainingCity = training.address.city || ""
                trainingZipcode = training.address.zipcode || ""
              }
            }

            if ((trainingLat === 0 || trainingLng === 0) && training.companyData) {
              trainingLat = parseFloat((training.companyData as any).latitude || (training.companyData as any).lat || 0)
              trainingLng = parseFloat((training.companyData as any).longitude || (training.companyData as any).lng || (training.companyData as any).lon || 0)
            }

            // Si toujours pas de coordonnées, utiliser la table de correspondance ville/code postal
            if ((trainingLat === 0 || trainingLng === 0) && (trainingCity || trainingZipcode)) {
              const fallbackCoords = getCoordsFromAddress(trainingCity, trainingZipcode)
              if (fallbackCoords) {
                trainingLat = fallbackCoords.lat
                trainingLng = fallbackCoords.lng
              }
            }

            if (trainingLat !== 0 && trainingLng !== 0) {
              const distance = calculateDistance(searchCoords.lat, searchCoords.lng, trainingLat, trainingLng)
              if (distance > searchRadius) return false
            }
            // Si pas de coordonnées GPS pour la formation, on l'inclut dans les résultats
          } else {
            // Pas de coordonnées GPS de recherche, ne pas filtrer par localisation
          }
        } catch (error) {
          console.warn("Erreur lors du filtrage par localisation:", error)
        }
      }

      return true
    })

    return filtered
  }, [
    allTrainings,
    searchQuery,
    selectedLevel,
    selectedFormat,
    selectedDuration,
    selectedCertification,
    location,
    searchAllFrance,
    showExpired,
    searchRadius,
    searchCoords,
  ])

  const filteredTrainings0 = useMemo(() => {
    if (allTrainings.length === 0) return []

    const filtered = allTrainings.filter((training) => {
      const isExpired = training.endDate ? new Date(training.endDate) < new Date() : false
      if (!showExpired && isExpired) return false

      // Recherche étendue
      if (searchQuery) {
        const query = searchQuery.toLowerCase()
        const matchesSearch =
          training.title.toLowerCase().includes(query) ||
          training.description?.toLowerCase().includes(query) ||
          getOrganizerName(training)?.toLowerCase().includes(query) ||
          getFormattedLocation(training)?.toLowerCase().includes(query)
        if (!matchesSearch) return false
      }
      if (
        searchQuery &&
        !training.title.toLowerCase().includes(searchQuery.toLowerCase()) &&
        !training.description?.toLowerCase().includes(searchQuery.toLowerCase())
      ) {
        return false
      }
      if (selectedLevel !== "all" && training.trainingLevel !== selectedLevel) return false
      if (selectedFormat !== "all" && training.trainingFormat !== selectedFormat) return false
      if (selectedDuration !== "all" && training.trainingDuration !== selectedDuration) return false
      if (selectedCertification !== "all") {
        if (selectedCertification === "certified" && !training.trainingCertification) return false
        if (selectedCertification === "not-certified" && training.trainingCertification) return false
      }

       // Filtre de localisation
      if (location && !searchAllFrance) {
        const trainingLocation = getFormattedLocation(training)?.toLowerCase() || ""
        const searchLocation = location.toLowerCase()
        if (!trainingLocation.includes(searchLocation)) return false
      }

      if (location && !searchAllFrance && !training.location?.toLowerCase().includes(location.toLowerCase())) {
        return false
      }
      return true
    })

    // Sort
    if (sortBy === "recent") {
      filtered.sort((a, b) => new Date(b.createdat || 0).getTime() - new Date(a.createdat || 0).getTime())
    } else if (sortBy === "price-asc") {
      filtered.sort((a, b) => Number.parseFloat(a.trainingPrice || "0") - Number.parseFloat(b.trainingPrice || "0"))
    } else if (sortBy === "price-desc") {
      filtered.sort((a, b) => Number.parseFloat(b.trainingPrice || "0") - Number.parseFloat(a.trainingPrice || "0"))
    }

    return filtered
  }, [
    allTrainings,
    searchQuery,
    selectedLevel,
    selectedFormat,
    selectedDuration,
    selectedCertification,
    location,
    searchAllFrance,
    sortBy,
    showExpired,
  ])

  const paginationData = useMemo(() => {
    const indexOfLastTraining = currentPage * trainingsPerPage
    const indexOfFirstTraining = indexOfLastTraining - trainingsPerPage
    const currentTrainings = filteredTrainings.slice(indexOfFirstTraining, indexOfLastTraining)
    const totalPages = Math.ceil(filteredTrainings.length / trainingsPerPage)
    return { currentTrainings, totalPages }
  }, [filteredTrainings, currentPage, trainingsPerPage])

  const handlePageChange = (page: number) => {
    if (page > 0 && page <= paginationData.totalPages) {
      setCurrentPage(page)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  const resetFilters = () => {
    setSelectedLevel("all")
    setSelectedFormat("all")
    setSelectedDuration("all")
    setSelectedCertification("all")
    setLocation("")
    setSearchRadius(10)
    setSearchAllFrance(false)
    setShowExpired(true)
  }

    const { visibleItems: currentTrainings, hasMore, sentinelRef } = useInfiniteRender(filteredTrainings, 20)

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="w-full relative overflow-hidden text-white">
        {/* Background image avec overlay violet */}
        <div className="absolute inset-0 z-0">
          <Image
            src="/images/training-background.jpg"
            alt="Background"
            fill
            className="object-cover"
            priority
          />
          {/* Overlay violet semi-transparent */}
          <div className="absolute inset-0 bg-gradient-to-r from-purple-600/85 to-purple-500/85" />
        </div>
        
        <div className="container mx-auto px-4 max-w-[1400px] relative z-10 py-8 md:py-12 lg:py-16">
          <div className="flex flex-col md:flex-row items-start justify-between mb-6 md:mb-8 gap-4">
            <div className="flex items-center gap-3 md:gap-4">
              <div className="bg-white/20 backdrop-blur-sm p-3 md:p-4 rounded-2xl">
                <GraduationCap className="w-8 h-8 md:w-12 md:h-12 text-white" />
              </div>
              <div>
                <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold mb-1 md:mb-2">Formations</h1>
                <p className="text-sm md:text-base lg:text-lg text-white/90">Développez vos compétences avec les formations recommandées</p>
              </div>
            </div>
            <div className="flex gap-4 md:gap-8 text-right">
              <div>
                <div className="text-xl md:text-2xl lg:text-3xl font-bold">{allTrainings.length}</div>
                <div className="text-xs md:text-sm text-white/80">Formations actives</div>
              </div>
            </div>
          </div>

          <div className="relative max-w-4xl mx-auto">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <Input
              type="text"
              placeholder="Rechercher une formation, un domaine, une certification..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-6 text-base rounded-xl border-0 shadow-lg focus:ring-2 focus:ring-purple-300 text-gray-900 bg-white"
            />
          </div>
        </div>
      </header>

      <div className="bg-white border-b sticky top-16 z-10 shadow-sm">
        <div className="container mx-auto px-4 max-w-[1400px]">
          {/* First row: Action buttons */}
          <div className="flex flex-wrap gap-2 md:gap-3 py-3 md:py-4 border-b">
            <FeatureGuard feature="ads">
              <Button onClick={handleCreateAnnouncement} className="bg-purple-500 hover:bg-purple-600 text-white">
                <Plus className="w-4 h-4 mr-2" />
                Poster une formation
              </Button>
            </FeatureGuard>
            {/* <Button
              onClick={handleCreateAlert}
              variant="outline"
              className="border-yellow-500 text-yellow-600 hover:bg-yellow-50 bg-transparent"
            >
              <Bell className="w-4 h-4 mr-2" />
              Créer une alerte
            </Button> */}
            <SaveSearchButton
              searchTerm={searchQuery}
              category={"formations"}
              location={location}
              radius={searchRadius}
              searchAllFrance={searchAllFrance}
              useGeolocation={isGettingLocation}
              userPosition={null}
              currentUrl={typeof window !== "undefined" ? window.location.href : ""}
              className="ml-auto"
            />
          </div>

          {/* Second row: Filters, Sort, View toggle */}
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 py-3">
            <div className="flex flex-wrap items-center gap-2 md:gap-4">
              <Button
                variant="outline"
                onClick={() => setShowFilters(!showFilters)}
                className="flex items-center gap-2 text-sm"
                size="sm"
              >
                <Filter className="w-4 h-4" />
                Filtres
                {showFilters ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
              </Button>
              <span className="text-xs md:text-sm text-gray-600">
                <span className="font-semibold">{filteredTrainings.length}</span> formations
              </span>
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="showExpired"
                  checked={showExpired}
                  onCheckedChange={(checked) => setShowExpired(checked as boolean)}
                />
                <label htmlFor="showExpired" className="text-xs md:text-sm text-gray-600 cursor-pointer whitespace-nowrap">
                  <span className="hidden sm:inline">Afficher les formations expirées</span>
                  <span className="sm:hidden">Expirées</span>
                </label>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2 md:gap-4">
              <div className="flex items-center gap-2">
                <span className="text-xs md:text-sm text-gray-600 whitespace-nowrap">Trier:</span>
                <Select value={sortBy} onValueChange={setSortBy}>
                  <SelectTrigger className="w-[140px] md:w-[180px] border-gray-300 text-xs md:text-sm">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="recent">Plus récents</SelectItem>
                    <SelectItem value="price-asc">Prix croissant</SelectItem>
                    <SelectItem value="price-desc">Prix décroissant</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="flex gap-1 border rounded-lg p-1">
                <Button
                  variant={viewMode === "grid" ? "default" : "ghost"}
                  size="sm"
                  onClick={() => setViewMode("grid")}
                  className={viewMode === "grid" ? "bg-purple-500 hover:bg-purple-600" : ""}
                >
                  <Grid3x3 className="w-4 h-4" />
                </Button>
                <Button
                  variant={viewMode === "list" ? "default" : "ghost"}
                  size="sm"
                  onClick={() => setViewMode("list")}
                  className={viewMode === "list" ? "bg-purple-500 hover:bg-purple-600" : ""}
                >
                  <List className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {showFilters && (
        <div className="bg-white border-b shadow-sm">
          <div className="container mx-auto px-4 py-6 max-w-[1400px]">
            <div className="space-y-4">
              {/* Location with geolocation */}
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
                >
                  {isGettingLocation ? (
                    <div className="w-4 h-4 border-2 border-gray-300 border-t-purple-600 rounded-full animate-spin" />
                  ) : (
                    <Locate className="w-4 h-4" />
                  )}
                </Button>
              </div>

              {/* Radius slider */}
              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="text-sm font-medium text-gray-700">Rayon de recherche</label>
                  <span className="text-sm font-semibold text-purple-600">{searchRadius} km</span>
                </div>
                <Slider
                  value={[searchRadius]}
                  onValueChange={(value) => setSearchRadius(value[0])}
                  min={0}
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
                  id="search-all-france"
                  checked={searchAllFrance}
                  onCheckedChange={(checked) => setSearchAllFrance(checked as boolean)}
                />
                <label htmlFor="search-all-france" className="text-sm text-gray-700 cursor-pointer">
                  Rechercher dans toute la France
                </label>
              </div>

              {/* Filter dropdowns */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <Select value={selectedLevel} onValueChange={setSelectedLevel}>
                  <SelectTrigger>
                    <SelectValue placeholder="Tous les niveaux" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Tous les niveaux</SelectItem>
                    <SelectItem value="Débutant">Débutant</SelectItem>
                    <SelectItem value="Intermédiaire">Intermédiaire</SelectItem>
                    <SelectItem value="Avancé">Avancé</SelectItem>
                    <SelectItem value="Expert">Expert</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={selectedFormat} onValueChange={setSelectedFormat}>
                  <SelectTrigger>
                    <SelectValue placeholder="Tous les formats" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Tous les formats</SelectItem>
                    <SelectItem value="Présentiel">Présentiel</SelectItem>
                    <SelectItem value="En ligne">En ligne</SelectItem>
                    <SelectItem value="Hybride">Hybride</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={selectedDuration} onValueChange={setSelectedDuration}>
                  <SelectTrigger>
                    <SelectValue placeholder="Toutes durées" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Toutes durées</SelectItem>
                    <SelectItem value="1 jour">1 jour</SelectItem>
                    <SelectItem value="2-5 jours">2-5 jours</SelectItem>
                    <SelectItem value="1-2 semaines">1-2 semaines</SelectItem>
                    <SelectItem value="1 mois+">1 mois+</SelectItem>
                  </SelectContent>
                </Select>

                <Select value={selectedCertification} onValueChange={setSelectedCertification}>
                  <SelectTrigger>
                    <SelectValue placeholder="Certification" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Toutes</SelectItem>
                    <SelectItem value="certified">Avec certification</SelectItem>
                    <SelectItem value="not-certified">Sans certification</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Reset filters */}
              <div className="flex justify-end">
                <Button variant="ghost" onClick={resetFilters} className="text-purple-600 hover:text-purple-700">
                  Réinitialiser les filtres
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="container mx-auto px-4 py-8 max-w-[1400px]">
        {isLoading ? (
          <div className="text-center py-20">
            <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-purple-500 mx-auto mb-4" />
            <p className="text-gray-600">Chargement des formations...</p>
          </div>
        // ) : paginationData.currentTrainings.length ? (
        ) : currentTrainings.length ? (
          <>
            <div
              className={
                viewMode === "grid"
                  ? "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
                  : "flex flex-col gap-4"
              }
            >
              {/* {paginationData.currentTrainings.map((training, index) => { */}
              {currentTrainings.map((training) => {
                return (
                  <motion.div
                    key={training.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    // transition={{ delay: index * 0.05 }}
                  >
                    <TrainingCard training={training} viewMode={viewMode} />
                  </motion.div>
                )
              })}
            </div>

              {/* sentinel pour déclencher chargement */}
              <div ref={sentinelRef as any} className="h-8 flex items-center justify-center mt-8">
                {hasMore ? (
                  <div className="text-sm text-gray-500">Chargement...</div>
                ) : (
                  <div className="text-sm text-gray-400">Fin des résultats</div>
                )}
              </div>

            {/* Pagination */}
            {/* {paginationData.totalPages > 1 && (
              <div className="flex justify-center items-center mt-12 gap-2">
                <Button
                  variant="outline"
                  disabled={currentPage === 1}
                  onClick={() => handlePageChange(currentPage - 1)}
                  className="hover:bg-purple-50"
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
                        className={`w-10 ${page === currentPage ? "bg-purple-500 hover:bg-purple-600" : "hover:bg-purple-50"}`}
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
                  className="hover:bg-purple-50"
                >
                  Suivant
                </Button>
              </div>
            )} */}
          </>
        ) : (
          <div className="text-center py-20">
            <div className="mb-4">
              <GraduationCap className="w-20 h-20 text-gray-300 mx-auto" />
            </div>
            <h3 className="text-xl font-semibold text-gray-700 mb-2">Aucune formation trouvée</h3>
            <p className="text-gray-500">Essayez de modifier vos filtres pour voir plus de résultats</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default function TrainingsPageWrapper() {
  return (
    <Suspense fallback={<div>Chargement...</div>}>
      <TrainingsPage />
    </Suspense>
  )
}
