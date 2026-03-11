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
  Calendar,
  Clock,
  Users,
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
} from "lucide-react"
import { fetchAnnoncements, toggleFavorite, fetchCommentsByAnnouncementId } from "@/lib/api"
import { toast as sonnerToast } from "sonner"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { Checkbox } from "@/components/ui/checkbox"
import { useToast } from "@/hooks/use-toast"
import { config } from "@/lib/config"
import { formatDateRelative } from "@/lib/utils"
import { SaveSearchButton } from "@/components/save-search-button"
import { ShareModal } from "@/components/share-modal"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import citiesData from "@/lib/data/france-cities.json"
import { labelObject } from "@/lib/constants/label-object"
import { getCoordsFromAddress } from "@/lib/data/zipcode-coords"
import useInfiniteRender from "@/hooks/useInfiniteRender"

// const API_URL = "https://test.myreklam.fr"
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

interface Event {
  id: string
  title: string
  description: string
  eventDate?: string
  startDate?: string
  endDate?: string
  eventTime?: string
  startTime?: string
  endTime?: string
  eventLocation?: string | any
  address?: string | any
  eventCity?: string
  eventPrice?: string
  price?: string
  eventMaxAttendees?: string
  eventCurrentAttendees?: string
  eventCategory?: string
  eventType?: string
  subCategory?: string
  nameOrganizator?: string
  modereservation?: string
  formatevent?: string
  isOneDay?: boolean
  isSeveralDays?: boolean
  isAllDays?: boolean
  eventDurationType?: string
  images?: string[]
  userId?: string
  createdat?: string
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
  isFavorite?: boolean
  number_view?: number
  [key: string]: any
}

function EventsHeader({
  searchQuery,
  setSearchQuery,
  totalEvents,
}: { searchQuery: string; setSearchQuery: (query: string) => void; totalEvents: number }) {

  return (
    <header className="w-full relative overflow-hidden text-white">
      {/* Background image avec overlay orange */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/images/events-background.jpg"
          alt="Background"
          fill
          className="object-cover"
          priority
        />
        {/* Overlay orange semi-transparent */}
        <div className="absolute inset-0 bg-gradient-to-r from-orange-600/85 to-orange-500/85" />
      </div>
      
      <div className="container max-w-[1400px] mx-auto px-4 relative z-10 py-8 md:py-12 lg:py-16">
        <div className="flex flex-col md:flex-row items-start justify-between mb-6 md:mb-8 gap-4">
          <div className="flex items-start gap-3 md:gap-4">
            <div className="bg-white/20 backdrop-blur-sm p-3 md:p-4 rounded-2xl">
              <Calendar className="w-8 h-8 md:w-12 md:h-12 text-white" />
            </div>
            <div>
              <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold mb-1 md:mb-2">Événements</h1>
              <p className="text-sm md:text-base lg:text-lg text-white/90">
                Participez aux événements de votre communauté et créez des connexions
              </p>
            </div>
          </div>
          <div className="flex gap-4 md:gap-8 text-right">
            <div>
              <div className="text-xl md:text-2xl lg:text-3xl font-bold">{totalEvents}</div>
              <div className="text-xs md:text-sm text-white/80">Événements actifs</div>
            </div>
          </div>
        </div>

        <div className="relative max-w-3xl mx-auto">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <Input
            type="text"
            placeholder="Rechercher un événement, un lieu, une catégorie..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-6 text-base rounded-xl border-0 shadow-lg focus:ring-2 focus:ring-orange-300 text-gray-900 bg-white"
          />
        </div>
      </div>
    </header>
  )
}

function EventsToolbar({
  userId,
  router,
  showFilters,
  setShowFilters,
  filteredCount,
  sortBy,
  setSortBy,
  viewMode,
  setViewMode,
  //pour la sauvegarde
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
  shouldBeBlocked: profileType === 'professionnel' && !isPremium
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
    router.push("/announcements/create/events")
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
      description: "Vous serez notifié des nouveaux événements.",
    })
  }

  return (
    <div className="bg-white border-b sticky top-16 z-10 shadow-sm">
      <div className="container max-w-[1400px] mx-auto px-4 py-3 md:py-4">
        {/* First row: Action buttons */}
        <div className="flex flex-wrap gap-2 md:gap-3 mb-3 md:mb-4">
          <FeatureGuard feature="ads">
            <Button onClick={handleCreateAnnouncement} className="bg-orange-500 hover:bg-orange-600 text-white text-sm" size="sm">
              <Plus className="w-4 h-4 mr-2" />
              <span className="hidden sm:inline">Poster un événement</span>
              <span className="sm:hidden">Poster</span>
            </Button>
          </FeatureGuard>
          <SaveSearchButton
            searchTerm={searchQuery}
            category={"evenements"}
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
              <span className="font-semibold">{filteredCount}</span> événements
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
                  <SelectItem value="popular">🔥 Plus populaires</SelectItem>
                  <SelectItem value="soon">⏰ Bientôt</SelectItem>
                  <SelectItem value="price-low">💰 Prix croissant</SelectItem>
                  <SelectItem value="price-high">💎 Prix décroissant</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="flex gap-1 border rounded-lg p-1">
              <Button
                variant={viewMode === "grid" ? "default" : "ghost"}
                size="sm"
                onClick={() => setViewMode("grid")}
                className={viewMode === "grid" ? "bg-orange-500 hover:bg-orange-600" : ""}
              >
                <Grid3x3 className="w-4 h-4" />
              </Button>
              <Button
                variant={viewMode === "list" ? "default" : "ghost"}
                size="sm"
                onClick={() => setViewMode("list")}
                className={viewMode === "list" ? "bg-orange-500 hover:bg-orange-600" : ""}
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
  selectedPrice,
  setSelectedPrice,
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
  selectedPrice: string
  setSelectedPrice: (price: string) => void
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
        const { latitude, longitude } = position.coords
        
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`,
          )
          const data = await response.json()
          const city = data.address.city || data.address.town || data.address.village || "Ma position"
          setLocation(city)
          
          // Mettre à jour l'URL avec les coordonnées GPS
          const newParams = new URLSearchParams(window.location.search)
          newParams.set("location", city)
          newParams.set("lat", latitude.toString())
          newParams.set("lng", longitude.toString())
          window.history.pushState({}, '', `?${newParams.toString()}`)
          
          toast({
            title: "Position détectée",
            description: `Votre position: ${city}`,
          })
        } catch (error) {
          setLocation("Ma position")
          
          // Mettre à jour l'URL avec les coordonnées GPS même sans nom de ville
          const newParams = new URLSearchParams(window.location.search)
          newParams.set("location", "Ma position")
          newParams.set("lat", latitude.toString())
          newParams.set("lng", longitude.toString())
          window.history.pushState({}, '', `?${newParams.toString()}`)
          
          toast({
            title: "Position détectée",
            description: "Recherche autour de votre position actuelle",
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
                <div className="w-4 h-4 border-2 border-gray-300 border-t-orange-600 rounded-full animate-spin" />
              ) : (
                <Locate className="w-4 h-4" />
              )}
            </Button>
          </div>

          {/* Radius slider */}
          <div>
            <div className="flex justify-between items-center mb-2">
              <label className="text-sm font-medium text-gray-700">Rayon de recherche</label>
              <span className="text-sm font-semibold text-orange-600">{radius} km</span>
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
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Select value={selectedCategory} onValueChange={setSelectedCategory}>
              <SelectTrigger>
                <SelectValue placeholder="Toutes les catégories" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes les catégories</SelectItem>
                <SelectItem value="evenements_professionnels_reseautage">Événements Professionnels & Réseautage</SelectItem>
                <SelectItem value="culture_divertissement">Culture & Divertissement</SelectItem>
                <SelectItem value="sport_loisirs">Sport & Loisirs</SelectItem>
                <SelectItem value="formation_education">Formation / Éducation</SelectItem>
                <SelectItem value="engagement_associatif_caritatif">Engagement Associatif & Caritatif</SelectItem>
                <SelectItem value="famille_enfance">Famille & Enfance</SelectItem>
                <SelectItem value="marches_evenements_commerciaux">Marchés & Événements Commerciaux</SelectItem>
                <SelectItem value="jeux_concours">Jeux & Concours</SelectItem>
                <SelectItem value="gastronomie_oenologie">Gastronomie & Œnologie</SelectItem>
                <SelectItem value="bien_etre_developpement_personnel">Bien-être & Développement Personnel</SelectItem>
                <SelectItem value="technologie_innovation">Technologie & Innovation</SelectItem>
                <SelectItem value="mode_beaute">Mode & Beauté</SelectItem>
                <SelectItem value="autres">Autres</SelectItem>
              </SelectContent>
            </Select>

            <Select value={selectedPrice} onValueChange={setSelectedPrice}>
              <SelectTrigger>
                <SelectValue placeholder="Tous les prix" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous les prix</SelectItem>
                <SelectItem value="free">Gratuit</SelectItem>
                <SelectItem value="paid">Payant</SelectItem>
              </SelectContent>
            </Select>

            <Select value="all">
              <SelectTrigger>
                <SelectValue placeholder="Toutes les dates" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes les dates</SelectItem>
                <SelectItem value="today">Aujourd'hui</SelectItem>
                <SelectItem value="week">Cette semaine</SelectItem>
                <SelectItem value="month">Ce mois-ci</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Reset filters */}
          <div className="flex justify-end">
            <Button variant="link" onClick={onReset} className="text-orange-600 hover:text-orange-700">
              <X className="w-4 h-4 mr-1" />
              Réinitialiser les filtres
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}

function EventCard({ event, viewMode }: { event: Event; viewMode: "grid" | "list" }) {
  const [isFavorite, setIsFavorite] = useState(event.isFavorite || false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [imageError, setImageError] = useState(false)
    const [commentsCount, setCommentsCount] = useState(0)

  const { toast } = useToast()


  useEffect(() => {
    const fetchCommentsCount = async () => {
      try {
        const result = await fetchCommentsByAnnouncementId(event.id)
        if (result.success) {
          setCommentsCount(result.comments.length)
        }
      } catch (error) {
        console.error("Erreur lors de la récupération des commentaires:", error)
      }
    }

    fetchCommentsCount()
  }, [event.id])
  // Nettoyer la description HTML
  const getCleanDescription = () => {
    if (!event.description) return ""
    // Créer un élément temporaire pour décoder les entités HTML
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = event.description
    // Récupérer le texte décodé
    const decodedText = tempDiv.textContent || tempDiv.innerText || ""
    // Normaliser les espaces
    const normalized = decodedText.replace(/\s+/g, ' ').trim()
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
      const result = await toggleFavorite(userId, event.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite Event] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, event.title)
        
        if (newFavoriteState) {
          sonnerToast.success("Ajouté aux favoris", {
            description: "Retrouvez cette annonce dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=evenements"
            }
          })
        } else {
          sonnerToast.success("Retiré des favoris")
        }
      } else {
        sonnerToast.error("Erreur lors de la mise à jour du favori")
      }
    } catch (error) {
      console.error("[Favorite Event] Erreur:", error)
      sonnerToast.error("Erreur lors de la mise à jour du favori")
    }
  }

  // Un événement permanent n'expire jamais
  const now = new Date()
  const startDate = event.startDate ? new Date(event.startDate) : null
  const endDate = event.endDate ? new Date(event.endDate) : null
  
  // Vérifier si l'événement est en cours (entre startDate et endDate)
  const isOngoing = startDate && endDate && now >= startDate && now <= endDate
  
  const isExpired = (event.eventDurationType === "permanent" || event.isAllDays) 
    ? false 
    : (endDate ? endDate < now : false)
    
  const isFull =
    event.eventMaxAttendees &&
    event.eventCurrentAttendees &&
    Number.parseInt(event.eventCurrentAttendees) >= Number.parseInt(event.eventMaxAttendees)

  // Determine event status
  // const getEventStatus = () => {
  //   if (isExpired) return { label: "Passé", color: "bg-gray-500" }
  //   if (isFull) return { label: "Complet", color: "bg-red-500" }

  //   const eventDate = event.eventDate ? new Date(event.eventDate) : null
  //   const today = new Date()

  //   if (eventDate) {
  //     const diffTime = eventDate.getTime() - today.getTime()
  //     const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

  //     if (diffDays < 0) return { label: "Passé", color: "bg-gray-500" }
  //     if (diffDays === 0) return { label: "Aujourd'hui", color: "bg-green-500" }
  //     if (diffDays <= 7) return { label: "Bientôt", color: "bg-blue-500" }
  //   }

  //   return { label: "À venir", color: "bg-orange-500" }
  // }

  
  // Déterminer le statut de l'événement avec les vraies données
  const getEventStatus = () => {
    // Vérifier d'abord si l'événement est en cours
    if (isOngoing) return { label: "En cours", color: "bg-green-600" }
    
    if (isExpired) return { label: "Expiré", color: "bg-gray-500" }
    if (isFull) return { label: "Complet", color: "bg-red-500" }

    // Vérifier si l'événement est permanent
    if (event.eventDurationType === "permanent" || event.isAllDays) {
      return { label: "Permanent", color: "bg-blue-500" }
    }

    const eventDate = event.eventDate || event.startDate
    if (!eventDate) return { label: "Date à définir", color: "bg-gray-400" }

    const eventDateTime = new Date(eventDate)
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const diffTime = eventDateTime.getTime() - today.getTime()
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

    if (diffDays < 0) return { label: "Expiré", color: "bg-gray-500" }
    if (diffDays === 0) return { label: "Aujourd'hui", color: "bg-green-500" }
    if (diffDays === 1) return { label: "Demain", color: "bg-blue-500" }
    if (diffDays <= 7) return { label: "Cette semaine", color: "bg-blue-500" }
    if (diffDays <= 30) return { label: "Ce mois-ci", color: "bg-orange-500" }
    
    return { label: "À venir", color: "bg-orange-500" }
  }


  const status = getEventStatus()

  // const handleFavorite = (e: React.MouseEvent) => {
  //   e.preventDefault()
  //   e.stopPropagation()
  //   setIsFavorite(!isFavorite)
  //   toast({
  //     title: isFavorite ? "Retiré des favoris" : "Ajouté aux favoris",
  //     description: isFavorite ? "L'événement a été retiré de vos favoris" : "L'événement a été ajouté à vos favoris",
  //   })
  // }

  // Fonctions d'interaction (déjà définie plus haut)
  // const handleFavorite = async (e: React.MouseEvent) => {
  //   e.preventDefault()
  //   e.stopPropagation()
  //   
  //   const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
  //   if (!userId) {
  //     toast({
  //       title: "Connexion requise",
  //       description: "Vous devez être connecté pour ajouter aux favoris",
  //       variant: "destructive",
  //     })
  //     return
  //   }

  //   try {
  //     // Appeler l'API toggleFavorite si disponible
  //     setIsFavorite(!isFavorite)
  //     toast({
  //       title: isFavorite ? "Retiré des favoris" : "Ajouté aux favoris",
  //       description: isFavorite ? "L'événement a été retiré de vos favoris" : "L'événement a été ajouté à vos favoris",
  //     })
  //   } catch (error) {
  //     console.error("Erreur lors de la mise à jour des favoris:", error)
  //   }
  // }

  // const handleShare = (e: React.MouseEvent) => {
  //   e.preventDefault()
  //   e.stopPropagation()
  //   if (navigator.share) {
  //     navigator.share({
  //       title: event.title,
  //       text: event.description,
  //       url: window.location.origin + `/announcements/events/${event.id}`,
  //     })
  //   } else {
  //     navigator.clipboard.writeText(window.location.origin + `/announcements/events/${event.id}`)
  //     toast({
  //       title: "Lien copié",
  //       description: "Le lien de l'événement a été copié dans le presse-papier",
  //     })
  //   }
  // }

  const formatDate = (dateString?: string) => {
    if (!dateString) return ""
    const date = new Date(dateString)
    return date.toLocaleDateString("fr-FR", { day: "numeric", month: "long", year: "numeric" })
  }

  const formatTime = (timeString?: string) => {
    if (!timeString) return ""
    return timeString
  }

  // const getOrganizerName = () => {
  //   return event.userNomsociete || event.companyData?.nomsociete || event.userPseudo || "Organisateur"
  // }

  // const getOrganizerPhoto = () => {
  //   const photo = event.userPhotoUrl || event.companyData?.photoprofilurl
  //   return photo && photo.startsWith("http") ? photo : photo ? `${API_URL}${photo}` : null
  // }

  // const isCompany = event.userProfileType === "professionnel" || event.companyData?.profiletype === "professionnel"

    // Utiliser les vraies données utilisateur/entreprise
  const getOrganizerName = () => {
    const companyData = event.companyData
    if (!companyData) return "Organisateur"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || event.userPseudo || "Particulier"
  }

  const getOrganizerPhoto = () => {
    const companyData = event.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    
    return companyData.photoprofilurl.startsWith("http") 
      ? companyData.photoprofilurl 
      : `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = event.companyData?.profiletype === "professionnel"

  // Formater la date de l'événement
  const formatEventDate = () => {
    // Vérifier si l'événement est permanent
    if (event.eventDurationType === "permanent" || event.isAllDays) {
      return "Permanent"
    }
    
    const startDate = event.eventDate || event.startDate
    const endDate = event.endDate
    
    if (!startDate) return "Date à définir"
    
    const start = new Date(startDate)
    const startFormatted = start.toLocaleDateString("fr-FR", { 
      day: "numeric", 
      month: "long", 
      year: "numeric" 
    })
    
    // Si une date de fin existe et est différente de la date de début
    if (endDate) {
      const end = new Date(endDate)
      // Vérifier que la date de fin est différente de la date de début
      if (end.getTime() !== start.getTime()) {
        const endFormatted = end.toLocaleDateString("fr-FR", { 
          day: "numeric", 
          month: "long", 
          year: "numeric" 
        })
        return `${startFormatted} - ${endFormatted}`
      }
    }
    
    return startFormatted
  }

  // Formater l'heure de l'événement
  const formatEventTime = () => {
    if (event.eventTime) return event.eventTime
    if (event.startTime) return event.startTime
    return null
  }

  // Obtenir la localisation formatée
  const getFormattedLocation = () => {
    // Priorité aux données spécifiques d'événement
    if (event.eventCity) return event.eventCity
    if (event.eventLocation) {
      if (typeof event.eventLocation === 'string') {
        return event.eventLocation
      }
      return formatAddress(event.eventLocation)
    }
    
    // Fallback sur l'adresse générale
    if (event.address) {
      return formatAddress(event.address)
    }
    
    return null
  }

  // Obtenir le nombre de participants
  const getParticipantsDisplay = () => {
    const current = Number.parseInt(event.eventCurrentAttendees || "0")
    const max = Number.parseInt(event.eventMaxAttendees || "0")
    
    if (max > 0) {
      return `${current}/${max} participants`
    } else if (current > 0) {
      return `${current} participant${current > 1 ? 's' : ''}`
    }
    
    return null
  }

  // Obtenir le prix formaté
  const getFormattedPrice = () => {
    const price = event.eventPrice || event.price
    const priceType = event.priceType
    
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

  // Obtenir la catégorie affichée
  // const getDisplayCategory = () => {
  //   return event.eventType || event.eventCategory || event.category
  // }

  // Obtenir la catégorie affichée avec traduction
  const getDisplayCategory = () => {
    const eventType = event.eventType || event.eventCategory || event.category
    return (labelObject as any)[eventType] || eventType
  }

  // Obtenir la sous-catégorie traduite
  const getDisplaySubCategory = () => {
    if (!event.subCategory) return null
    return (labelObject as any)[event.subCategory] || event.subCategory
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

  const imageUrl = event.images && event.images[0] ? getImageUrl(event.images[0]) : null

  const handleCardClick = (e: React.MouseEvent) => {
    const target = e.target as HTMLElement
    if (target.closest("button")) {
      return
    }
    window.location.href = `/announcements/events/${event.id}`
  }

  if (viewMode === "list") {
    return (
      <Card
        className={`relative hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer border border-gray-200 bg-white ${
          isExpired ? "opacity-60" : "hover:border-orange-300"
        }`}
        onClick={handleCardClick}
      >
        <div className="flex flex-col md:flex-row md:items-stretch">
          {/* Image Section - Left */}
          <div className="relative w-full md:w-64 h-48 md:h-auto flex-shrink-0 overflow-hidden bg-gradient-to-br from-orange-100 via-orange-50 to-pink-50">
            {imageUrl && !imageError ? (
              <img
                src={imageUrl}
                alt={event.title}
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
          </div>

          {/* Content Section - Right */}
          <div className="flex-1 flex flex-col p-4 md:p-6">
            {/* Header: Title + Actions */}
            <div className="flex items-start justify-between gap-4 mb-4">
              <div className="flex-1 min-w-0">
                <h3 className={`text-xl md:text-2xl font-bold mb-2 line-clamp-2 group-hover:text-orange-600 transition-colors ${
                  isExpired ? "text-gray-400" : "text-gray-900"
                }`}>
                  {event.title}
                </h3>
                <div className="flex items-center gap-2">
                  {getOrganizerPhoto() ? (
                    <img src={getOrganizerPhoto()!} alt={getOrganizerName()} className="w-6 h-6 rounded-full object-cover" />
                  ) : (
                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-orange-400 to-orange-500 flex items-center justify-center">
                      <Calendar className="w-3 h-3 text-white" />
                    </div>
                  )}
                  <span className="text-sm text-gray-600">{getOrganizerName()}</span>
                </div>
              </div>
              
              {/* Actions */}
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="icon" className="h-10 w-10 rounded-full hover:bg-orange-50" onClick={handleFavorite}>
                  <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-400"}`} />
                </Button>
                <Button variant="ghost" size="icon" className="h-10 w-10 rounded-full hover:bg-orange-50" onClick={handleShare}>
                  <Share2 className="w-5 h-5 text-gray-400" />
                </Button>
              </div>
            </div>

            {/* Badges */}
            <div className="flex flex-wrap items-center gap-2 mb-4">
              {/* {getDisplayCategory() && (
                <Badge className="bg-orange-100 text-orange-700 border-0">{getDisplayCategory()}</Badge>
              )} */}
              {getDisplayCategory() && (
                <Badge className="bg-orange-100 text-orange-700 border-0">
                  {getDisplayCategory()}
                </Badge>
              )}
              <Badge className={`text-white border-0 ${status.color}`}>{status.label}</Badge>
            </div>

            {/* Description */}
            <p className="text-gray-600 text-sm mb-4 line-clamp-2 leading-relaxed">
              {getCleanDescription()}
            </p>

            {/* Info Grid */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="flex items-center gap-2">
                <div className="flex items-center gap-2 bg-orange-100 px-3 py-1.5 rounded-lg">
                  <Calendar className="w-4 h-4 text-orange-600" />
                  <span className="text-sm font-bold text-orange-900">{formatEventDate()}</span>
                </div>
              </div>
              {(event.eventType || event.subCategory) && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <span className="font-medium truncate">{getDisplayCategory()}</span>
                  {event.subCategory && event.eventType && <span className="flex-shrink-0">·</span>}
                  {/* {event.subCategory && <span className="truncate">{event.subCategory}</span>} */}
                  {event.subCategory && <span className="truncate">{getDisplaySubCategory()}</span>}
                </div>
              )}
              {getFormattedLocation() && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <MapPin className="w-4 h-4 text-orange-500" />
                  <span className="truncate">{getFormattedLocation()}</span>
                </div>
              )}
              {getParticipantsDisplay() && (
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Users className="w-4 h-4 text-orange-500" />
                  <span>{getParticipantsDisplay()}</span>
                </div>
              )}
            </div>

            {/* Footer: Price + CTA */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 mt-auto pt-4 border-t">
              <div className={`text-2xl md:text-3xl font-bold ${isExpired ? "text-gray-400 line-through" : "text-orange-600"}`}>
                {getFormattedPrice()}
              </div>
              <div className="flex flex-col items-end gap-2 w-full sm:w-auto">
                <Button
                  size="lg"
                  className={isExpired ? "bg-gray-400 w-full sm:w-auto" : "bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white shadow-lg w-full sm:w-auto"}
                  disabled={isExpired}
                  onClick={(e) => {
                    e.preventDefault()
                    e.stopPropagation()
                    if (!isExpired) {
                      window.location.href = `/announcements/events/${event.id}`
                    }
                  }}
                >
                  {isExpired ? "Événement terminé" : isOngoing ? "Voir l'événement en cours" : "Voir les détails"}
                </Button>
                <p className="text-sm text-gray-500">
                  Publié {formatDateRelative(event.createdat)}
                </p>
              </div>
            </div>
          </div>
        </div>
      </Card>
    )
  }

  // Grid view
  return (
    <>
      <Card
      className={`flex flex-col h-full min-h-[400px] hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-visible group cursor-pointer border-0 bg-white/90 backdrop-blur-md ${
        isExpired ? "opacity-60 grayscale" : "hover:shadow-orange-200/60"
      }`}
      onClick={handleCardClick}
    >
      {/* Image with overlays */}
      <div className="relative h-56 bg-gradient-to-br from-orange-100 via-orange-50 to-pink-50 overflow-hidden">
        {imageUrl && !imageError ? (
          <img
            src={imageUrl}
            alt={event.title}
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

        {/* Action buttons - top right */}
        {/* <div className="absolute top-3 right-3 flex gap-2">
          <Button
            variant="ghost"
            size="icon"
            className="h-8 w-8 rounded-full bg-white/90 hover:bg-white shadow-md"
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
        </div> */}
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
          {event.title}
        </h3>
        {/* <p className="text-sm text-gray-600 mb-3">{getOrganizerName()}</p> */}

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
          
          {(event.eventType || event.subCategory) && (
            <div className="flex items-center gap-2 text-sm text-gray-600">
              <span className="font-medium text-xs truncate">{getDisplayCategory()}</span>
              {event.subCategory && event.eventType && <span className="flex-shrink-0">·</span>}
              {/* {event.subCategory && <span className="text-xs truncate">{event.subCategory}</span>} */}
              {event.subCategory && <span className="text-xs truncate">{getDisplaySubCategory()}</span>}
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


        {/* Price */}
        {/* <div className={`text-2xl font-bold mb-4 ${isExpired ? "text-gray-400 line-through" : "text-orange-600"}`}>
          {event.eventPrice && Number.parseFloat(event.eventPrice) === 0 ? "Gratuit" : `${event.eventPrice}€`}
        </div> */}

        {/* Prix */}
        <div className={`text-2xl font-bold mb-4 mt-auto ${isExpired ? "text-gray-400 line-through" : "text-orange-600"}`}>
          {getFormattedPrice()}
        </div>

        {/* CTA Button */}
        <Button
          size="lg"
          className={
            isExpired
              ? "w-full bg-gray-400 cursor-not-allowed"
              : "w-full bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white"
          }
          disabled={isExpired}
          onClick={(e) => {
            e.preventDefault()
            e.stopPropagation()
            if (!isExpired) {
              window.location.href = `/announcements/events/${event.id}`
            }
          }}
        >
          {isExpired ? "Événement terminé" : isOngoing ? "Voir l'événement en cours" : "Voir l'événement"}
        </Button>

        {/* Publié il y a */}
        <p className="text-sm text-gray-500 mt-3 text-center">
          Publié {formatDateRelative(event.createdat)}
        </p>
      </div>
    </Card>
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={event.title}
        url={`/announcements/events/${event.id}`}
        description={event.description}
      />
    </>
  )
}

export default function EventsPage() {
  const router = useRouter()
  const params = useSearchParams()

  const [searchQuery, setSearchQuery] = useState(params.get("q") || "")
  const [showFilters, setShowFilters] = useState(false)
  const [location, setLocation] = useState(params.get("location") || "")
  const [radius, setRadius] = useState(parseInt(params.get("radius") || "10"))
  const [searchAllFrance, setSearchAllFrance] = useState(params.get("allFrance") === "true")
  const [selectedCategory, setSelectedCategory] = useState("all")
  const [selectedPrice, setSelectedPrice] = useState("all")
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
  
  const [allEvents, setAllEvents] = useState<Event[]>([])
  const [currentPage, setCurrentPage] = useState(1)
  const [eventsPerPage] = useState(20)
  const [userId, setUserId] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [showExpired, setShowExpired] = useState(true)


  
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
    if (typeof window !== "undefined") {
      setUserId(localStorage.getItem("profileId"))
    }
  }, [])

  useEffect(() => {
    const loadAllEvents = async () => {
      setIsLoading(true)
      try {
        const result = await fetchAnnoncements({ category: "evenements" })
        if (result.success) {
          setAllEvents(result.deals)
        } else {
          console.error("Erreur lors du chargement des annonces:", result.error)
          setAllEvents([])
        }
      } catch (error) {
        console.error("Exception lors du chargement des annonces:", error)
        setAllEvents([])
      } finally {
        setIsLoading(false)
      }
    }
    loadAllEvents()
  }, [])

  // Fonctions utilitaires
  const getOrganizerName = (event: Event): string => {
    const companyData = event.companyData
    if (!companyData) return "Organisateur"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || event.userPseudo || "Particulier"
  }

  const getFormattedLocation = (event: Event): string => {
    // Priorité aux données spécifiques d'événement
    if (event.eventCity) return event.eventCity
    if (event.eventLocation) {
      if (typeof event.eventLocation === 'string') {
        return event.eventLocation
      }
      return formatAddress(event.eventLocation)
    }
    
    // Fallback sur l'adresse générale
    if (event.address) {
      return formatAddress(event.address)
    }
    
    return ""
  }

  const getDisplayCategory = (event: Event): string => {
    return event.eventType || event.eventCategory || event.category || ""
  }

  // Mise à jour du filtrage
  const filteredEvents = useMemo(() => {
    if (allEvents.length === 0) return []

    return allEvents.filter((event) => {
      // Recherche étendue
      if (searchQuery) {
        const query = searchQuery.toLowerCase()
        const matchesSearch =
          event.title.toLowerCase().includes(query) ||
          event.description?.toLowerCase().includes(query) ||
          getOrganizerName(event)?.toLowerCase().includes(query) ||
          getFormattedLocation(event)?.toLowerCase().includes(query) ||
          getDisplayCategory(event)?.toLowerCase().includes(query)
        if (!matchesSearch) return false
      }

      if (selectedCategory !== "all" && event.eventCategory !== selectedCategory) return false
      if (selectedPrice === "free" && parseFloat(event.eventPrice || "0") !== 0) return false
      if (selectedPrice === "paid" && parseFloat(event.eventPrice || "0") === 0) return false

      const isExpired = event.endDate ? new Date(event.endDate) < new Date() : false
      if (!showExpired && isExpired) return false

      // Filtre par localisation avec calcul de distance
      if (location && !searchAllFrance) {
        try {
          // Si on a des coordonnées de recherche valides et un rayon
          if (searchCoords.lat !== 0 && searchCoords.lng !== 0 && radius > 0) {
            let eventLat = 0
            let eventLng = 0
            let eventCity = ""
            let eventZipcode = ""

            if (event.address) {
              if (typeof event.address === 'string') {
                try {
                  const addressObj = JSON.parse(event.address)
                  eventLat = parseFloat(addressObj.latitude || addressObj.lat || 0)
                  eventLng = parseFloat(addressObj.longitude || addressObj.lng || addressObj.lon || 0)
                  eventCity = addressObj.city || ""
                  eventZipcode = addressObj.zipcode || ""
                } catch {}
              } else if (typeof event.address === 'object') {
                eventLat = parseFloat(event.address.latitude || event.address.lat || 0)
                eventLng = parseFloat(event.address.longitude || event.address.lng || event.address.lon || 0)
                eventCity = event.address.city || ""
                eventZipcode = event.address.zipcode || ""
              }
            }

            if ((eventLat === 0 || eventLng === 0) && event.companyData) {
              eventLat = parseFloat((event.companyData as any).latitude || (event.companyData as any).lat || 0)
              eventLng = parseFloat((event.companyData as any).longitude || (event.companyData as any).lng || (event.companyData as any).lon || 0)
            }

            // Si toujours pas de coordonnées, utiliser la table de correspondance ville/code postal
            if ((eventLat === 0 || eventLng === 0) && (eventCity || eventZipcode)) {
              const fallbackCoords = getCoordsFromAddress(eventCity, eventZipcode)
              if (fallbackCoords) {
                eventLat = fallbackCoords.lat
                eventLng = fallbackCoords.lng
              }
            }

            if (eventLat !== 0 && eventLng !== 0) {
              const distance = calculateDistance(searchCoords.lat, searchCoords.lng, eventLat, eventLng)
              if (distance > radius) return false
            }
            // Si pas de coordonnées GPS pour l'événement, on l'inclut dans les résultats
          } else {
            // Pas de coordonnées GPS de recherche, ne pas filtrer par localisation
          }
        } catch (error) {
          console.warn("Erreur lors du filtrage par localisation:", error)
        }
      }

      return true
    })
  }, [allEvents, searchQuery, selectedCategory, selectedPrice, showExpired, location, searchAllFrance, radius, searchCoords])

  
  const filteredEvents0 = useMemo(() => {
    if (allEvents.length === 0) return []

    return allEvents.filter((event) => {
      // Search query filter
      if (
        searchQuery &&
        !event.title.toLowerCase().includes(searchQuery.toLowerCase()) &&
        !event.description?.toLowerCase().includes(searchQuery.toLowerCase())
      ) {
        return false
      }

      if (selectedCategory !== "all" && event.eventCategory !== selectedCategory) return false
      if (selectedPrice === "free" && Number.parseFloat(event.eventPrice || "0") !== 0) return false
      if (selectedPrice === "paid" && Number.parseFloat(event.eventPrice || "0") === 0) return false

      // Un événement permanent n'expire jamais
      const isExpired = (event.eventDurationType === "permanent" || event.isAllDays) 
        ? false 
        : (event.endDate ? new Date(event.endDate) < new Date() : false)
      if (!showExpired && isExpired) return false

      return true
    })
  }, [allEvents, searchQuery, selectedCategory, selectedPrice, showExpired])

  const sortedEvents = useMemo(() => {
    const sorted = [...filteredEvents]
    switch (sortBy) {
      case "recent":
        return sorted.sort((a, b) => new Date(b.createdat || 0).getTime() - new Date(a.createdat || 0).getTime())
      case "popular":
        return sorted.sort((a, b) => (Number(b.eventCurrentAttendees) || 0) - (Number(a.eventCurrentAttendees) || 0))
      case "soon":
        return sorted.sort((a, b) => new Date(a.eventDate || 0).getTime() - new Date(b.eventDate || 0).getTime())
      case "price-low":
        return sorted.sort((a, b) => Number.parseFloat(a.eventPrice || "0") - Number.parseFloat(b.eventPrice || "0"))
      case "price-high":
        return sorted.sort((a, b) => Number.parseFloat(b.eventPrice || "0") - Number.parseFloat(a.eventPrice || "0"))
      default:
        return sorted
    }
  }, [filteredEvents, sortBy])

  const paginationData = useMemo(() => {
    const indexOfLastEvent = currentPage * eventsPerPage
    const indexOfFirstEvent = indexOfLastEvent - eventsPerPage
    const currentEvents = sortedEvents.slice(indexOfFirstEvent, indexOfLastEvent)
    const totalPages = Math.ceil(sortedEvents.length / eventsPerPage)
    return { currentEvents, totalPages }
  }, [sortedEvents, currentPage, eventsPerPage])

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
    setSelectedPrice("all")
    setSearchQuery("")
    setShowExpired(true)
  }

    const { visibleItems: currentEvents, hasMore, sentinelRef } = useInfiniteRender(filteredEvents, 20)


  return (
    <Suspense fallback={<div>Chargement...</div>}>
      <div className="min-h-screen bg-gray-50">
        <EventsHeader searchQuery={searchQuery} setSearchQuery={setSearchQuery} totalEvents={allEvents.length} />
        <EventsToolbar
          userId={userId}
          router={router}
          showFilters={showFilters}
          setShowFilters={setShowFilters}
          filteredCount={sortedEvents.length}
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
        <div className="bg-white border-b py-2">
          <div className="container max-w-[1400px] mx-auto px-4">
            <div className="flex items-center space-x-2">
              <Checkbox
                id="showExpired"
                checked={showExpired}
                onCheckedChange={(checked) => setShowExpired(checked as boolean)}
              />
              <label htmlFor="showExpired" className="text-sm text-gray-600 cursor-pointer">
                Afficher les événements expirés
              </label>
            </div>
          </div>
        </div>
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
            selectedPrice={selectedPrice}
            setSelectedPrice={setSelectedPrice}
            onReset={handleResetFilters}
            citySearchTerm={citySearchTerm}
            setCitySearchTerm={setCitySearchTerm}
            showCitySuggestions={showCitySuggestions}
            setShowCitySuggestions={setShowCitySuggestions}
            citySuggestions={citySuggestions}
            setSearchCoords={setSearchCoords}
          />
        )}

        {/* Events Grid */}
        <div className="container max-w-[1400px] mx-auto px-4 py-8">
          {isLoading ? (
            <div className="text-center py-20">
              <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-orange-500 mx-auto mb-4" />
              <p className="text-gray-600">Chargement des événements...</p>
            </div>
          // ) : paginationData.currentEvents.length ? (
          ) : currentEvents.length ? (
            <>
              <div
                className={
                  viewMode === "grid"
                    ? "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
                    : "space-y-4"
                }
              >
                {/* {paginationData.currentEvents.map((event, index) => ( */}
                 {currentEvents.map((event) => ( 
                  <motion.div
                    key={event.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    // transition={{ delay: index * 0.05 }}
                  >
                    <EventCard event={event} viewMode={viewMode} />
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
                    className="hover:bg-orange-50"
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
                          className={`w-10 ${page === currentPage ? "bg-orange-500 hover:bg-orange-600" : "hover:bg-orange-50"}`}
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
                    className="hover:bg-orange-50"
                  >
                    Suivant
                  </Button>
                </div>
              )} */}
            </>
          ) : (
            <div className="text-center py-20">
              <div className="mb-4">
                <Calendar className="w-20 h-20 text-gray-300 mx-auto" />
              </div>
              <h3 className="text-xl font-semibold text-gray-700 mb-2">Aucun événement trouvé</h3>
              <p className="text-gray-500">Essayez de modifier vos filtres pour voir plus de résultats</p>
            </div>
          )}
        </div>
      </div>
    </Suspense>
  )
}
