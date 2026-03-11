"use client"

import type React from "react"

import { useEffect, useState, useRef, useMemo, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { motion, AnimatePresence } from "framer-motion"
import {
  Plus,
  MapPin,
  Tag,
  Clock,
  Grid3x3,
  List,
  Search,
  Locate,
  X,
  ChevronDown,
  Heart,
  Share2,
  MessageCircle,
  User,
  Navigation,
  Eye,
} from "lucide-react"
import { fetchAnnoncements,fetchUserInfo, toggleFavorite, fetchCommentsByAnnouncementId } from "@/lib/api"
import {
  dealsCategories,
  HighTechSubCategories,
  ConsolesVideoGamesSubCategories,
  GroceriesShoppingSubCategories,
  TravelSubCategories,
  ServicesSubCategories,
  FinanceInsuranceSubCategories,
  MobileInternetPlansSubCategories,
  SportsOutdoorsSubCategories,
  CultureEntertainmentSubCategories,
  AutomotiveSubCategories,
  GardenDIYSubCategories,
  HomeLivingSubCategories,
  FamilyKidsSubCategories,
  HealthBeautySubCategories,
  FashionAccessoriesSubCategories,
} from "@/lib/constants/deals-categories"
import { labelObject } from "@/lib/constants/label-object"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Card } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { useToast } from "@/hooks/use-toast"
import { cn } from "@/lib/utils"
import { SaveSearchButton } from "@/components/save-search-button"
import { config } from "@/lib/config"
import { ShareModal } from "@/components/share-modal"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import { toast } from "sonner"
import citiesData from "@/lib/data/france-cities.json"
import { getCoordsFromAddress } from "@/lib/data/zipcode-coords"
import useInfiniteRender from "@/hooks/useInfiniteRender"

// const API_URL = "https://test.myreklam.fr"
const API_URL = config.API_URL

function formatAddress(address: any): string {
  if (!address) return ""

  // If address is a string, return it
  if (typeof address === "string") return address

  // If address is an object, format it nicely
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

interface Deal {
  id: string
  title: string
  description: string
  dealType: string
  dealCategory: string
  subCategory?: string
  address?: string | any
  images?: string[]
  isOnline?: boolean
  userId?: string
  createdat?: string
  endDate?: string
  // Nouvelles propriétés des prix
  initialPrice?: string
  finalPrice?: string
  discountValue?: string
  // Données de l'entreprise/utilisateur
  companyData?: {
    id: string
    userid: string
    profiletype: "professionnel" | "particulier"
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
    // ... autres propriétés
  }
  // Statistiques
  number_view?: number
  isFavorite?: boolean
  // Marques/brands
  brand?: string

  userPseudo?: string
  userNomsociete?: string
  userProfileType?: "professionnel" | "particulier"
  userPhotoUrl?: string
  [key: string]: any
}

type ViewMode = "grid" | "list"
type SortOption = "recent" | "oldest" | "ending" | "discount"

function DealsHeader({ searchTerm, setSearchTerm, totalDeals }: { searchTerm: string; setSearchTerm: (term: string) => void; totalDeals: number }) {
  return (
    <header className="w-full relative overflow-hidden text-white">
      {/* Background image avec overlay vert */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/images/deals-background.jpg"
          alt="Background"
          fill
          className="object-cover"
          priority
        />
        {/* Overlay vert semi-transparent pour garder la lisibilité */}
        <div className="absolute inset-0 bg-gradient-to-br from-emerald-600/85 via-green-600/85 to-teal-600/85" />
      </div>
      
      <div className="container mx-auto px-4 max-w-[1400px] relative z-10">
        <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="py-8 md:py-12 lg:py-16">
          {/* Main title section */}
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 md:gap-8 mb-6 md:mb-8">
            <div className="flex items-center gap-3 md:gap-4">
              <div className="bg-white/20 backdrop-blur-sm p-3 md:p-4 rounded-2xl shadow-lg">
                <Tag className="w-8 h-8 md:w-12 md:h-12" />
              </div>
              <div>
                <h1 className="text-2xl md:text-4xl lg:text-5xl font-bold mb-1 md:mb-2">Bons Plans</h1>
                <p className="text-sm md:text-base lg:text-lg text-white/90">Les meilleures offres partagées par la communauté</p>
              </div>
            </div>

            {/* Quick stats */}
            <div className="flex gap-4 md:gap-6">
              <div className="text-center">
                <div className="text-xl md:text-2xl lg:text-3xl font-bold">{totalDeals}</div>
                <div className="text-xs md:text-sm text-white/80">Offres actives</div>
              </div>
            </div>
          </div>

          <div className="max-w-3xl mx-auto">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <Input
                type="text"
                placeholder="Rechercher un bon plan, une marque, un produit..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-12 pr-4 py-4 text-lg bg-white/95 backdrop-blur-sm border-0 shadow-xl rounded-xl focus:ring-2 focus:ring-white/50 text-gray-900 placeholder:text-gray-500"
              />
            </div>
          </div>
        </motion.div>
      </div>
    </header>
  )
}

function SearchFilters({
  selectedDealType,
  setSelectedDealType,
  selectedCategory,
  setSelectedCategory,
  selectedSubCategory,
  setSelectedSubCategory,
  selectedAvailability,
  setSelectedAvailability,
  location,
  setLocation,
  radius,
  setRadius,
  searchAllFrance,
  setSearchAllFrance,
  useCurrentLocation,
  onUseGeolocation,
  isGettingLocation,
  isOpen,
  citySearchTerm,
  setCitySearchTerm,
  showCitySuggestions,
  setShowCitySuggestions,
  citySuggestions,
  params,
  router,
  setSearchCoords,
}: {
  selectedCategory: string
  setSelectedCategory: (category: string) => void
  selectedSubCategory: string | null
  setSelectedSubCategory: (subCategory: string | null) => void
  selectedDealType: string
  setSelectedDealType: (type: string) => void
  selectedAvailability: string
  setSelectedAvailability: (availability: string) => void
  location: string
  setLocation: (location: string) => void
  radius: number[]
  setRadius: (radius: number[]) => void
  searchAllFrance: boolean
  setSearchAllFrance: (value: boolean) => void
  useCurrentLocation: boolean
  onUseGeolocation: () => void
  isGettingLocation: boolean
  isOpen: boolean
  citySearchTerm: string
  setCitySearchTerm: (term: string) => void
  showCitySuggestions: boolean
  setShowCitySuggestions: (show: boolean) => void
  citySuggestions: any[]
  params: URLSearchParams
  router: any
  setSearchCoords: (coords: { lat: number; lng: number }) => void
}) {
  const getSubCategories = () => {
    const subCategoryMap: Record<string, string[]> = {
      HighTech: HighTechSubCategories,
      ConsolesVideoGames: ConsolesVideoGamesSubCategories,
      GroceriesShopping: GroceriesShoppingSubCategories,
      Travel: TravelSubCategories,
      Services: ServicesSubCategories,
      FinanceInsurance: FinanceInsuranceSubCategories,
      MobileInternetPlans: MobileInternetPlansSubCategories,
      SportsOutdoors: SportsOutdoorsSubCategories,
      CultureEntertainment: CultureEntertainmentSubCategories,
      Automotive: AutomotiveSubCategories,
      GardenDIY: GardenDIYSubCategories,
      HomeLiving: HomeLivingSubCategories,
      FamilyKids: FamilyKidsSubCategories,
      HealthBeauty: HealthBeautySubCategories,
      FashionAccessories: FashionAccessoriesSubCategories,
    }
    return subCategoryMap[selectedCategory] || []
  }

  return (
    <div className="bg-white border-b shadow-sm mb-6">
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden p-4"
          >
            <div className="space-y-4">
              <div className="space-y-3">
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
                      disabled={searchAllFrance || selectedAvailability === "online"}
                      className="pl-10 disabled:opacity-50 disabled:cursor-not-allowed"
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
                    onClick={onUseGeolocation}
                    disabled={isGettingLocation || searchAllFrance || selectedAvailability === "online"}
                    className="flex-shrink-0 bg-transparent hover:bg-green-50 hover:border-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
                    title="Autour de moi"
                  >
                    {isGettingLocation ? (
                      <div className="w-4 h-4 border-2 border-gray-300 border-t-green-600 rounded-full animate-spin" />
                    ) : (
                      <Locate className="w-4 h-4" />
                    )}
                  </Button>
                </div>

                {!searchAllFrance && selectedAvailability !== "online" && (
                  <div className="space-y-2 px-1">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Rayon de recherche</span>
                      <span className="font-semibold text-green-600">
                        {radius[0] === 0 ? "Ville uniquement" : `${radius[0]} km`}
                      </span>
                    </div>
                    <input
                      type="range"
                      min="0"
                      max="200"
                      step="5"
                      value={radius[0]}
                      onChange={(e) => setRadius([Number.parseInt(e.target.value)])}
                      className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-green-600"
                    />
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>0 km</span>
                      <span>50 km</span>
                      <span>100 km</span>
                      <span>150 km</span>
                      <span>200 km</span>
                    </div>
                  </div>
                )}

                <div className="flex items-center space-x-2 px-1">
                  <input
                    type="checkbox"
                    id="search-all-france"
                    checked={searchAllFrance}
                    onChange={(e) => setSearchAllFrance(e.target.checked)}
                    disabled={selectedAvailability === "online"}
                    className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
                  />
                  <label htmlFor="search-all-france" className={`text-sm font-medium ${selectedAvailability === "online" ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}>
                    Rechercher dans toute la France
                  </label>
                </div>

                {useCurrentLocation && !searchAllFrance && (
                  <div className="flex items-center gap-2 text-sm text-green-600 bg-green-50 px-3 py-2 rounded-lg">
                    <Navigation className="w-4 h-4" />
                    <span>Recherche autour de votre position</span>
                  </div>
                )}

                {searchAllFrance && (
                  <div className="flex items-center gap-2 text-sm text-green-600 bg-green-50 px-3 py-2 rounded-lg">
                    <MapPin className="w-4 h-4" />
                    <span>Recherche sur tout le territoire français</span>
                  </div>
                )}
              </div>

              {/* Filters */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {/* Category */}
                <select
                  value={selectedCategory}
                  onChange={(e) => {
                    setSelectedCategory(e.target.value)
                    setSelectedSubCategory(null)
                  }}
                  className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                >
                  {dealsCategories.map((category) => (
                    <option key={category} value={category}>
                      {labelObject[category as keyof typeof labelObject] || category}
                    </option>
                  ))}
                </select>

                {/* Subcategory */}
                {selectedCategory !== "All" && getSubCategories().length > 0 && (
                  <select
                    value={selectedSubCategory || ""}
                    onChange={(e) => setSelectedSubCategory(e.target.value || null)}
                    className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                  >
                    <option value="">Toutes les sous-catégories</option>
                    {getSubCategories().map((sub) => (
                      <option key={sub} value={sub}>
                        {labelObject[sub as keyof typeof labelObject] || sub}
                      </option>
                    ))}
                  </select>
                )}

                {/* Deal Type */}
                <select
                  value={selectedDealType}
                  onChange={(e) => setSelectedDealType(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                >
                  <option value="all">Tous les types</option>
                  <option value="Discount">Réductions / Remises</option>
                  <option value="Promotion">Codes Promo</option>
                  <option value="Flash">Offres Spéciales / Ventes Flash</option>
                  <option value="GoodPlan">Gratuit</option>
                  <option value="Info">Infos pouvoir d'achat</option>
                </select>

                {/* Availability */}
                <select
                  value={selectedAvailability}
                  onChange={(e) => setSelectedAvailability(e.target.value)}
                  className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
                >
                  <option value="all">Toutes disponibilités</option>
                  <option value="online">En ligne</option>
                  <option value="inStore">En magasin</option>
                </select>
              </div>

              {/* Reset button */}
              <div className="flex justify-end">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    setSelectedCategory("All")
                    setSelectedSubCategory(null)
                    setSelectedDealType("all")
                    setSelectedAvailability("all")
                    setLocation("")
                    setRadius([10])
                    setSearchAllFrance(false)
                  }}
                  className="text-gray-600 hover:text-gray-900"
                >
                  <X className="w-4 h-4 mr-2" />
                  Réinitialiser les filtres
                </Button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

function DealsToolbar({
  userId,
  router,
  viewMode,
  setViewMode,
  sortBy,
  setSortBy,
  totalResults,
  filtersOpen,
  onToggleFilters,
  showExpired,
  onToggleExpired,
  searchCriteria,
  currentUrl,
}: {
  userId: string | null
  router: any
  viewMode: ViewMode
  setViewMode: (mode: ViewMode) => void
  sortBy: SortOption
  setSortBy: (sort: SortOption) => void
  totalResults: number
  filtersOpen: boolean
  onToggleFilters: () => void
  showExpired: boolean
  onToggleExpired: () => void
  searchCriteria: any
  currentUrl: string
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
    console.log('[Debug Create] handleCreateAnnouncement called')
    console.log('[Debug Create] userId:', userId)
    console.log('[Debug Create] canCreateAds:', canCreateAds)
    console.log('[Debug Create] remainingAds:', remainingAds)

    if (!userId) {
      console.log('[Debug Create] No userId - redirecting to login-required')
      router.push("/login-required")
      return
    }

    if (!canCreateAds) {
      console.log('[Debug Create] Cannot create ads - showing limit reached toast')
      toast({
        title: "Limite d'annonces atteinte",
        description: "Vous avez atteint votre limite d'annonces pour ce mois. Souscrivez à un abonnement pour créer plus d'annonces.",
        variant: "destructive",
      })
      return
    }

    console.log('[Debug Create] All checks passed - navigating to create deals page')
    router.push("/announcements/create/deals")
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
      description: "Vous serez notifié des nouveaux bons plans.",
    })
  }

  return (
    <div className="bg-white border-b shadow-sm sticky top-0 z-30 backdrop-blur-sm bg-white/95">
      <div className="py-3 md:py-4 px-4">
        {/* Top row: Actions */}
        <div className="flex flex-wrap items-center justify-between gap-2 md:gap-4 mb-3 md:mb-4">
          <div className="flex flex-wrap gap-2 md:gap-3">
            <FeatureGuard feature="ads">
            <Button
              onClick={handleCreateAnnouncement}
              className="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white shadow-md hover:shadow-lg transition-all text-sm"
              size="sm"
            >
              <Plus className="w-4 h-4 mr-2" />
              <span className="hidden sm:inline">Poster un bon plan</span>
              <span className="sm:hidden">Poster</span>
            </Button>
            </FeatureGuard>
            <SaveSearchButton searchCriteria={searchCriteria} currentUrl={currentUrl} />
          </div>
        </div>

        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <div className="flex flex-wrap items-center gap-2 md:gap-4">
            {/* Filter button */}
            <Button variant="outline" onClick={onToggleFilters} className="flex items-center gap-2 bg-transparent text-sm" size="sm">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"
                />
              </svg>
              Filtres
              <ChevronDown className={cn("w-4 h-4 transition-transform", filtersOpen && "rotate-180")} />
            </Button>

            <div className="hidden md:block h-6 w-px bg-gray-300" />

            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={showExpired}
                onChange={(e) => onToggleExpired()}
                className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
              />
              <span className="text-xs md:text-sm font-medium text-gray-700 whitespace-nowrap">
                <span className="hidden sm:inline">Afficher les offres expirées</span>
                <span className="sm:hidden">Expirées</span>
              </span>
            </label>

            <div className="hidden md:block h-6 w-px bg-gray-300" />

            {/* Results count */}
            <p className="text-xs md:text-sm text-gray-600">
              <span className="font-bold text-gray-900 text-base md:text-lg">{totalResults}</span> bon{totalResults > 1 ? "s" : ""} plan{totalResults > 1 ? "s" : ""}
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 md:gap-4">
            {/* Sort */}
            <div className="flex items-center gap-2">
              <span className="text-xs md:text-sm text-gray-600 font-medium whitespace-nowrap">Trier:</span>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortOption)}
                className="text-xs md:text-sm border-2 border-gray-200 rounded-lg px-2 md:px-4 py-1.5 md:py-2 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white font-medium"
              >
                <option value="recent">🆕 Plus récents</option>
                <option value="oldest">📅 Plus anciens</option>
                <option value="ending">⏰ Se termine bientôt</option>
                <option value="discount">💰 Plus grosse réduction</option>
              </select>
            </div>

            {/* View toggle */}
            <div className="flex items-center gap-1 border-2 border-gray-200 rounded-lg p-1 bg-gray-50">
              <button
                onClick={() => setViewMode("grid")}
                className={cn(
                  "p-2 rounded transition-all",
                  viewMode === "grid"
                    ? "bg-green-600 text-white shadow-sm"
                    : "text-gray-600 hover:bg-white hover:text-green-600",
                )}
                title="Vue grille"
              >
                <Grid3x3 className="w-4 h-4" />
              </button>
              <button
                onClick={() => setViewMode("list")}
                className={cn(
                  "p-2 rounded transition-all",
                  viewMode === "list"
                    ? "bg-green-600 text-white shadow-sm"
                    : "text-gray-600 hover:bg-white hover:text-green-600",
                )}
                title="Vue liste"
              >
                <List className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function DealsSidebar({
  selectedCategory,
  setSelectedCategory,
  selectedSubCategory,
  setSelectedSubCategory,
  selectedDealType,
  setSelectedDealType,
  selectedAvailability,
  setSelectedAvailability,
  searchTerm,
  setSearchTerm,
  isOpen,
  onClose,
}: {
  selectedCategory: string
  setSelectedCategory: (category: string) => void
  selectedSubCategory: string | null
  setSelectedSubCategory: (subCategory: string | null) => void
  selectedDealType: string
  setSelectedDealType: (type: string) => void
  selectedAvailability: string
  setSelectedAvailability: (availability: string) => void
  searchTerm: string
  setSearchTerm: (term: string) => void
  isOpen: boolean
  onClose: () => void
}) {
  const [expandedSections, setExpandedSections] = useState({
    category: true,
    type: true,
    availability: true,
  })

  const toggleSection = (section: keyof typeof expandedSections) => {
    setExpandedSections((prev) => ({ ...prev, [section]: !prev[section] }))
  }

  const getSubCategories = () => {
    const subCategoryMap: Record<string, string[]> = {
      HighTech: HighTechSubCategories,
      ConsolesVideoGames: ConsolesVideoGamesSubCategories,
      GroceriesShopping: GroceriesShoppingSubCategories,
      Travel: TravelSubCategories,
      Services: ServicesSubCategories,
      FinanceInsurance: FinanceInsuranceSubCategories,
      MobileInternetPlans: MobileInternetPlansSubCategories,
      SportsOutdoors: SportsOutdoorsSubCategories,
      CultureEntertainment: CultureEntertainmentSubCategories,
      Automotive: AutomotiveSubCategories,
      GardenDIY: GardenDIYSubCategories,
      HomeLiving: HomeLivingSubCategories,
      FamilyKids: FamilyKidsSubCategories,
      HealthBeauty: HealthBeautySubCategories,
      FashionAccessories: FashionAccessoriesSubCategories,
    }
    return subCategoryMap[selectedCategory] || []
  }

  return (
    <>
      {/* Mobile overlay */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 z-40 lg:hidden"
            onClick={onClose}
          />
        )}
      </AnimatePresence>

      {/* Sidebar */}
      <motion.aside
        initial={false}
        animate={{ x: isOpen ? 0 : "-100%" }}
        className={cn(
          "fixed lg:sticky top-0 left-0 h-screen lg:h-auto w-80 bg-white border-r lg:border-r-0 shadow-xl lg:shadow-none z-50 lg:z-0 overflow-y-auto",
          "lg:translate-x-0 transition-transform duration-300",
        )}
      >
        <div className="p-6">
          {/* Mobile close button */}
          <div className="flex justify-between items-center mb-6 lg:hidden">
            <h2 className="text-lg font-semibold">Filtres</h2>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="w-5 h-5" />
            </Button>
          </div>

          {/* Search */}
          <div className="mb-6">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input
                type="text"
                placeholder="Rechercher..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>

          {/* Category Filter */}
          <div className="mb-6">
            <button
              onClick={() => toggleSection("category")}
              className="flex items-center justify-between w-full mb-3 font-semibold text-gray-900"
            >
              <span>Catégorie</span>
              <ChevronDown className={cn("w-4 h-4 transition-transform", expandedSections.category && "rotate-180")} />
            </button>
            <AnimatePresence>
              {expandedSections.category && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="space-y-2 overflow-hidden"
                >
                  {dealsCategories.map((category) => (
                    <label key={category} className="flex items-center space-x-2 cursor-pointer group">
                      <input
                        type="radio"
                        name="category"
                        value={category}
                        checked={selectedCategory === category}
                        onChange={(e) => {
                          setSelectedCategory(e.target.value)
                          setSelectedSubCategory(null)
                        }}
                        className="w-4 h-4 text-green-600 focus:ring-green-500"
                      />
                      <span className="text-sm text-gray-700 group-hover:text-green-600 transition-colors">
                        {labelObject[category as keyof typeof labelObject] || category}
                      </span>
                    </label>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Subcategory Filter */}
          {selectedCategory !== "All" && getSubCategories().length > 0 && (
            <div className="mb-6">
              <h3 className="font-semibold text-gray-900 mb-3">Sous-catégorie</h3>
              <div className="space-y-2 max-h-48 overflow-y-auto">
                <label className="flex items-center space-x-2 cursor-pointer group">
                  <input
                    type="radio"
                    name="subcategory"
                    value=""
                    checked={!selectedSubCategory}
                    onChange={() => setSelectedSubCategory(null)}
                    className="w-4 h-4 text-green-600 focus:ring-green-500"
                  />
                  <span className="text-sm text-gray-700 group-hover:text-green-600 transition-colors">Toutes</span>
                </label>
                {getSubCategories().map((sub) => (
                  <label key={sub} className="flex items-center space-x-2 cursor-pointer group">
                    <input
                      type="radio"
                      name="subcategory"
                      value={sub}
                      checked={selectedSubCategory === sub}
                      onChange={(e) => setSelectedSubCategory(e.target.value)}
                      className="w-4 h-4 text-green-600 focus:ring-green-500"
                    />
                    <span className="text-sm text-gray-700 group-hover:text-green-600 transition-colors">
                      {labelObject[sub as keyof typeof labelObject] || sub}
                    </span>
                  </label>
                ))}
              </div>
            </div>
          )}

          {/* Deal Type Filter */}
          <div className="mb-6">
            <button
              onClick={() => toggleSection("type")}
              className="flex items-center justify-between w-full mb-3 font-semibold text-gray-900"
            >
              <span>Type de bon plan</span>
              <ChevronDown className={cn("w-4 h-4 transition-transform", expandedSections.type && "rotate-180")} />
            </button>
            <AnimatePresence>
              {expandedSections.type && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="space-y-2 overflow-hidden"
                >
                  {[
                    { value: "all", label: "Tous" },
                    { value: "Discount", label: "Réductions / Remises" },
                    { value: "Promotion", label: "Codes Promo" },
                    { value: "Flash", label: "Offres Spéciales / Ventes Flash" },
                    { value: "GoodPlan", label: "Gratuit" },
                    { value: "Info", label: "Infos pouvoir d'achat" }
                  ].map((type) => (
                    <label key={type.value} className="flex items-center space-x-2 cursor-pointer group">
                      <input
                        type="radio"
                        name="dealType"
                        value={type.value}
                        checked={selectedDealType === type.value}
                        onChange={(e) => setSelectedDealType(e.target.value)}
                        className="w-4 h-4 text-green-600 focus:ring-green-500"
                      />
                      <span className="text-sm text-gray-700 group-hover:text-green-600 transition-colors">
                        {type.label}
                      </span>
                    </label>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Availability Filter */}
          <div className="mb-6">
            <button
              onClick={() => toggleSection("availability")}
              className="flex items-center justify-between w-full mb-3 font-semibold text-gray-900"
            >
              <span>Disponibilité</span>
              <ChevronDown
                className={cn("w-4 h-4 transition-transform", expandedSections.availability && "rotate-180")}
              />
            </button>
            <AnimatePresence>
              {expandedSections.availability && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="space-y-2 overflow-hidden"
                >
                  {["all", "online", "inStore"].map((availability) => (
                    <label key={availability} className="flex items-center space-x-2 cursor-pointer group">
                      <input
                        type="radio"
                        name="availability"
                        value={availability}
                        checked={selectedAvailability === availability}
                        onChange={(e) => setSelectedAvailability(e.target.value)}
                        className="w-4 h-4 text-green-600 focus:ring-green-500"
                      />
                      <span className="text-sm text-gray-700 group-hover:text-green-600 transition-colors">
                        {availability === "all" ? "Toutes" : availability === "online" ? "En ligne" : "En magasin"}
                      </span>
                    </label>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Reset Filters */}
          <Button
            variant="outline"
            className="w-full bg-transparent"
            onClick={() => {
              setSelectedCategory("All")
              setSelectedSubCategory(null)
              setSelectedDealType("all")
              setSelectedAvailability("all")
              setSearchTerm("")
            }}
          >
            Réinitialiser les filtres
          </Button>
        </div>
      </motion.aside>
    </>
  )
}

function DealCard({ deal, viewMode }: { deal: Deal; viewMode: ViewMode }) {
  const [isFavorite, setIsFavorite] = useState(deal.isFavorite || false)
  const [imageError, setImageError] = useState(false)
  const [showShareModal, setShowShareModal] = useState(false)
  const isExpired = deal.endDate ? new Date(deal.endDate) < new Date() : false
  const [commentsCount, setCommentsCount] = useState(0)




  // Récupérer le nombre de commentaires
  useEffect(() => {
    const fetchCommentsCount = async () => {
      try {
        const result = await fetchCommentsByAnnouncementId(deal.id)
        if (result.success) {
          setCommentsCount(result.comments.length)
        }
      } catch (error) {
        console.error("Erreur lors de la récupération des commentaires:", error)
      }
    }

    fetchCommentsCount()
  }, [deal.id])

  // const calculateDiscount = () => {
  //   // This is a placeholder - you'll need actual price fields in your data
  //   // For now, we'll generate a random discount for demo purposes
  //   return Math.floor(Math.random() * 70) + 10 // 10-80% discount
  // }


   const calculateDiscount = () => {
    if (deal.initialPrice && deal.finalPrice) {
      const initial = parseFloat(deal.initialPrice)
      const final = parseFloat(deal.finalPrice)
      if (initial > final) {
        return Math.round(((initial - final) / initial) * 100)
      }
    }
    // Si pas de données de prix, utiliser discountValue si disponible
    if (deal.discountValue) {
      return Math.round(parseFloat(deal.discountValue))
    }
    return 0
  }

  const discountPercentage = calculateDiscount()

  // const getTimeAgo = (date: string) => {
  //   const now = new Date()
  //   const past = new Date(date)
  //   const diffInHours = Math.floor((now.getTime() - past.getTime()) / (1000 * 60 * 60))

  //   if (diffInHours < 1) return "Il y a quelques minutes"
  //   if (diffInHours < 24)
  //     return `Il y a ${Math.floor(diffInHours / 24)} jour${Math.floor(diffInHours / 24) > 1 ? "s" : ""}`
  //   if (diffInHours < 168)
  //     return `Il y a ${Math.floor(diffInHours / 24)} jour${Math.floor(diffInHours / 24) > 1 ? "s" : ""}`
  //   if (diffInHours < 720)
  //     return `Il y a ${Math.floor(diffInHours / 168)} semaine${Math.floor(diffInHours / 168) > 1 ? "s" : ""}`
  //   return `Il y a ${Math.floor(diffInHours / 720)} mois`
  // }

   const getTimeAgo = (date: string) => {
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
  
    const views = deal.number_view || Math.floor(Math.random() * 200)
  const likes = Math.floor(Math.random() * 200)
  const comments = Math.floor(Math.random() * 50)

  // const getUserDisplayName = () => {
  //   if (deal.userProfileType === "professionnel" && deal.userNomsociete) {
  //     return deal.userNomsociete
  //   }
  //   if (deal.userPseudo) {
  //     return deal.userPseudo
  //   }
  //   return deal.userProfileType === "professionnel" ? "Entreprise" : "Particulier"
  // }

   const getUserDisplayName = () => {
    const companyData = deal.companyData
    if (!companyData) return "Utilisateur"

    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const getUserPhoto = () => {
    const companyData = deal.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    
    // L'URL est déjà complète dans les données
    return companyData.photoprofilurl
  }

  // const isProfessional = deal.userProfileType === "professionnel"

   const isProfessional = deal.companyData?.profiletype === "professionnel"

  // Gestion des prix réels
  const getFinalPrice = () => {
    if (deal.finalPrice !== undefined && deal.finalPrice !== null) {
      const price = parseFloat(deal.finalPrice)
      return isNaN(price) ? null : price
    }
    return null
  }

  const getInitialPrice = () => {
    if (deal.initialPrice !== undefined && deal.initialPrice !== null) {
      const price = parseFloat(deal.initialPrice)
      return isNaN(price) ? null : price
    }
    return null
  }

  const finalPrice = getFinalPrice()
  const initialPrice = getInitialPrice()

  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setShowShareModal(true)
  }

  // const handleFavorite = (e: React.MouseEvent) => {
  //   e.preventDefault()
  //   e.stopPropagation()
  //   setIsFavorite(!isFavorite)
  // }

  
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
      const result = await toggleFavorite(userId, deal.id, newFavoriteState)
      if (result.success) {
        setIsFavorite(newFavoriteState)
        console.log(`[Favorite] ${newFavoriteState ? 'Ajouté aux' : 'Retiré des'} favoris:`, deal.title)
        
        if (newFavoriteState) {
          toast.success("Ajouté aux favoris", {
            description: "Retrouvez cette annonce dans vos favoris",
            action: {
              label: "Voir mes favoris",
              onClick: () => window.location.href = "/dashboard/mes-favoris?category=bons_plans"
            }
          })
        } else {
          toast.success("Retiré des favoris")
        }
      } else {
        console.error("[Favorite] Échec de la mise à jour:", result)
        toast.error("Erreur lors de la mise à jour du favori")
      }
    } catch (error) {
      console.error("[Favorite] Erreur lors de la mise à jour du favori:", error)
      toast.error("Erreur lors de la mise à jour du favori")
    }
  }

    const handleImageError = () => {
    setImageError(true)
  }

  const renderImagePlaceholder = (className?: string) => (
    <div className={cn("w-full h-full flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50", className, isExpired && "grayscale brightness-90")}>
      <Tag className={cn("w-20 h-20 text-green-300", isExpired && "opacity-50")} />
    </div>
  )

    // Formater l'adresse à partir des données réelles
  const getFormattedAddress = () => {
    if (!deal.address) return ""
    
    try {
      const addressData = typeof deal.address === "string" ? JSON.parse(deal.address) : deal.address
      const parts = []
      
      if (addressData.line1) parts.push(addressData.line1)
      if (addressData.city) parts.push(addressData.city)
      else if (addressData.ville) parts.push(addressData.ville)
      if (addressData.zipcode) parts.push(addressData.zipcode)
      else if (addressData.codepostal) parts.push(addressData.codepostal)
      
      return parts.filter(Boolean).join(", ")
    } catch (error) {
      return deal.address.toString()
    }
  }

  const getImageUrl = (imagePath: string | undefined | null): string => {
    if (!imagePath) return ''
    
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
  // Fonction utilitaire pour parser le brand en toute sécurité
  const getBrandArray = () => {
    if (!deal.brand) return []
    
    try {
      // Si c'est déjà un array, le retourner
      if (Array.isArray(deal.brand)) {
        return deal.brand.filter(b => b && b.trim())
      }
      
      // Si c'est une string, essayer de la parser
      if (typeof deal.brand === 'string') {
        const cleanBrand = deal.brand.trim()
        
        // Vérifier si ça commence par [ (array JSON)
        if (cleanBrand.startsWith('[')) {
          const parsed = JSON.parse(cleanBrand)
          return Array.isArray(parsed) ? parsed.filter(b => b && b.trim()) : []
        }
        
        // Vérifier si ça commence par { (objet JSON mal formé)
        if (cleanBrand.startsWith('{')) {
          // Extraire le contenu entre guillemets
          const matches = cleanBrand.match(/"([^"]+)"/g)
          if (matches) {
            return matches.map(match => match.replace(/"/g, '').trim()).filter(b => b)
          }
        }
        
        // Si ce n'est pas du JSON, traiter comme une seule marque
        return [cleanBrand]
      }
      
      return []
    } catch (error) {
      console.warn('Erreur lors du parsing de brand:', error, 'Brand value:', deal.brand)
      
      // En cas d'erreur, essayer d'extraire le contenu entre guillemets
      if (typeof deal.brand === 'string') {
        const matches = deal.brand.match(/"([^"]+)"/g)
        if (matches) {
          return matches.map(match => match.replace(/"/g, '').trim()).filter(b => b)
        }
        
        // Dernière tentative : nettoyer et utiliser la valeur brute
        const cleaned = deal.brand.replace(/[\[\]{}"]/g, '').trim()
        return cleaned ? [cleaned] : []
      }
      
      return []
    }
  }

  const brandArray = getBrandArray()


  if (viewMode === "list") {
    return (
      <Link href={`/announcements/deals/${deal.id}`}>
        <Card
          className={cn(
            "hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer border-2",
            isExpired
              ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300"
              : "hover:border-green-200 border-gray-200",
          )}
        >
          <div className="flex flex-col sm:flex-row gap-0">
            {/* Image or Icon */}
            <div className="relative w-full sm:w-64 h-56 sm:h-auto bg-gradient-to-br from-gray-50 to-gray-100 flex-shrink-0 flex items-center justify-center">
              {/* {deal.images && deal.images[0] ? (
                 <img
                  src={getImageUrl(deal.images[0])}
                  alt={deal.title}
                  className={cn(
                    "w-full h-full object-cover group-hover:scale-105 transition-transform duration-500",
                    isExpired && "grayscale brightness-90",
                  )}
                  onError={handleImageError}
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center p-8">
                  <svg
                    className={cn("w-32 h-32 text-green-500", isExpired && "opacity-50")}
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M9 2L7.17 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2h-3.17L15 2H9zm3 15c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5z" />
                  </svg>
                </div>
              )} */}

              {deal.images && deal.images.length > 0 && deal.images[0] && !imageError ? (
                <img
                  src={getImageUrl(deal.images[0])}
                  alt={deal.title}
                  className={cn(
                    "w-full h-full object-cover group-hover:scale-105 transition-transform duration-500",
                    isExpired && "grayscale brightness-90",
                  )}
                  onError={handleImageError}
                  onLoad={() => console.log('[Image Debug] Image loaded successfully:', deal.images?.[0])}
                />
              ) : (
                renderImagePlaceholder()
              )}

              {isExpired && (
                <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
                  <Badge className="bg-red-500 text-white shadow-xl text-xl font-bold px-8 py-4 border-2 border-white animate-pulse">
                    <div className="flex flex-col items-center gap-1">
                      <div className="flex items-center gap-2">
                        <Clock className="w-6 h-6" />
                        <span>EXPIRÉ</span>
                      </div>
                      {deal.endDate && (
                        <span className="text-xs font-normal">depuis le {new Date(deal.endDate).toLocaleDateString("fr-FR")}</span>
                      )}
                    </div>
                  </Badge>
                </div>
              )}

              {/* Favorite button */}
              <button
                onClick={handleFavorite}
                className="absolute top-4 right-4 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center hover:scale-110 transition-transform z-10"
              >
                <Heart className={cn("w-5 h-5", isFavorite ? "fill-red-500 text-red-500" : "text-gray-400")} />
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 p-6 flex flex-col">
              <div className="flex items-start justify-between mb-2">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <h3
                      className={cn(
                        "font-bold text-2xl group-hover:text-green-600 transition-colors",
                        isExpired && "text-gray-500",
                      )}
                    >
                      {deal.title}
                    </h3>
                  </div>

                  {/* Category breadcrumb */}
                  <div className="flex items-center gap-2 text-sm text-gray-600 mb-3">
                    <span>{labelObject[deal.dealCategory as keyof typeof labelObject] || deal.dealCategory}</span>
                    {deal.subCategory && (
                      <>
                        <span>•</span>
                        <span>{labelObject[deal.subCategory as keyof typeof labelObject] || deal.subCategory}</span>
                      </>
                    )}
                  </div>

                  {/* Availability */}
                  <div className="flex items-center gap-2 text-sm text-gray-600 mb-4">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 010 4 2 2 0 01-2 2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                    <span>
                      {deal.isOnline ? "En ligne" : "En magasin"}
                      {brandArray.length > 0 && (
                        <span>, disponible chez <span className="font-semibold text-gray-900">{brandArray.join(", ")}</span></span>
                      )}
                    </span>
                  </div>

                  {/* Location */}
                  {/* {!deal.isOnline && deal.address && (
                    <div className="flex items-center gap-2 text-sm text-gray-600 mb-4">
                      <MapPin className="w-4 h-4" />
                      <span>{formatAddress(deal.address)}</span>
                    </div>
                  )} */}

                   {!deal.isOnline && getFormattedAddress() && (
                    <div className="flex items-center gap-2 text-sm text-gray-600 mb-4">
                      <MapPin className="w-4 h-4" />
                      <span>{getFormattedAddress()}</span>
                    </div>
                  )}
                </div>

                {/* Share button */}
                <button
                  onClick={handleShare}
                  className="w-10 h-10 flex items-center justify-center hover:bg-gray-100 rounded-full transition-colors"
                >
                  <Share2 className="w-5 h-5 text-gray-400" />
                </button>
              </div>

              {/* Price and engagement */}
              <div className="mt-auto flex items-end justify-between">
                <div className="flex items-baseline gap-3">
                  {finalPrice !== null && finalPrice === 0 ? (
                    <Badge className="bg-green-600 text-white text-xl font-bold px-4 py-2">
                      Gratuit
                    </Badge>
                  ) : finalPrice ? (
                    <>
                      <span className={cn("text-3xl font-bold", isExpired && "text-gray-400 line-through")}>
                        {finalPrice.toFixed(2)}€
                      </span>
                      {initialPrice && initialPrice > finalPrice && (
                        <span className="text-lg text-gray-400 line-through">{initialPrice.toFixed(2)}€</span>
                      )}
                      {!isExpired && discountPercentage > 0 && (
                        <Badge className="bg-green-600 text-white text-sm px-2 py-1">-{discountPercentage}%</Badge>
                      )}
                    </>
                  ) : null}
                </div>

                <div className="flex items-center gap-4">
                  <div className="flex items-center gap-1 text-gray-500">
                    <MessageCircle className="w-4 h-4" />
                    <span className="text-sm">{commentsCount}</span>
                  </div>

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
                    <div className="flex flex-col">
                      <span className="text-sm font-medium text-gray-700">{getUserDisplayName()}</span>
                      <Badge
                        variant="outline"
                        className={cn(
                          "text-xs px-1.5 py-0 h-5",
                          isProfessional
                            ? "bg-blue-50 text-blue-700 border-blue-200"
                            : "bg-gray-50 text-gray-600 border-gray-200",
                        )}
                      >
                        {isProfessional ? "Pro" : "Particulier"}
                      </Badge>
                    </div>
                  </div>
                </div>
              </div>

              {/* Time */}
              {deal.createdat && (
                <div className="flex items-center gap-1 text-xs text-gray-500 mt-4 pt-4 border-t">
                  <Clock className="w-3 h-3" />
                  <span>{getTimeAgo(deal.createdat)}</span>
                </div>
              )}
              
            </div>
          </div>
        </Card>
      </Link>
    )
  }

  return (
    <>
      <Link href={`/announcements/deals/${deal.id}`}>
      <Card
        className={cn(
          "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group cursor-pointer border-2",
          isExpired
            ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300"
            : "hover:border-green-200 border-gray-200",
        )}
      >
        {/* Image */}
        <div className="relative h-56 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
          {/* {deal.images && deal.images[0] ? (
            <img
              src={deal.images[0].startsWith("http") ? deal.images[0] : `${API_URL}${deal.images[0]}`}
              alt={deal.title}
              className={cn(
                "w-full h-full object-cover group-hover:scale-110 transition-transform duration-500",
                isExpired && "grayscale brightness-90",
              )}
              onError={(e) => {
                const target = e.target as HTMLImageElement
                target.style.display = "none"
                const parent = target.parentElement
                if (parent) {
                  parent.innerHTML = `
                    <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50 ${isExpired ? "grayscale brightness-90" : ""}">
                      <svg class="w-20 h-20 text-green-300 ${isExpired ? "opacity-50" : ""}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
                      </svg>
                    </div>
                  `
                }
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
          )} */}

            {deal.images && deal.images.length > 0 && deal.images[0] && !imageError ? (
            <img
              src={getImageUrl(deal.images[0])}
              alt={deal.title}
              className={cn(
              "w-full h-full object-cover group-hover:scale-110 transition-transform duration-500",
              isExpired && "grayscale brightness-90",
              )}
              onError={handleImageError}
              onLoad={() => console.log('[Image Debug] Image loaded successfully (grid):', deal.images?.[0])}
            />
            ) : (
            renderImagePlaceholder()
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
              {labelObject[deal.dealCategory as keyof typeof labelObject] || deal.dealCategory}
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
                  {deal.endDate && (
                    <span className="text-[10px] font-normal whitespace-nowrap">depuis le {new Date(deal.endDate).toLocaleDateString("fr-FR")}</span>
                  )}
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

          {/* Favorite button */}
          <button
            onClick={handleFavorite}
            className="absolute top-3 left-1/2 -translate-x-1/2 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center hover:scale-110 transition-transform opacity-0 group-hover:opacity-100"
          >
            <Heart className={cn("w-5 h-5", isFavorite ? "fill-red-500 text-red-500" : "text-gray-400")} />
          </button>
        </div>

        {/* Content */}
        <div className="p-5">
          <h3
            className={cn(
              "font-bold text-lg mb-2 line-clamp-2 min-h-[3.5rem] group-hover:text-green-600 transition-colors",
              isExpired && "text-gray-500",
            )}
          >
            {deal.title}
          </h3>

          {/* Category breadcrumb */}
          <div className="flex items-center gap-2 text-xs text-gray-600 mb-3">
            <span>{labelObject[deal.dealCategory as keyof typeof labelObject] || deal.dealCategory}</span>
            {deal.subCategory && (
              <>
                <span>•</span>
                <span>{labelObject[deal.subCategory as keyof typeof labelObject] || deal.subCategory}</span>
              </>
            )}
          </div>

          {deal.description && (
            <p 
              className={cn("text-sm mb-4 line-clamp-2 min-h-[2.5rem]", isExpired ? "text-gray-400" : "text-gray-600")}
              dangerouslySetInnerHTML={{ 
                __html: deal.description.replace(/<[^>]*>/g, '').substring(0, 150) + '...'
              }}
            />
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
              {deal.isOnline ? "En ligne" : "En magasin"}
              {brandArray.length > 0 && (
                <span>, disponible chez <span className="font-semibold text-gray-900">{brandArray.join(", ")}</span></span>
              )}
            </span>
          </div>

          {/* Location */}
          {!deal.isOnline && getFormattedAddress() && (
            <div className="flex items-center gap-1 text-xs text-gray-500 mb-3">
              <MapPin className="w-3 h-3" />
              <span className="truncate">
                {getFormattedAddress()}
              </span>
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
          <div className="flex items-center justify-between pt-4 border-t">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1 text-gray-500">
                <MessageCircle className="w-4 h-4" />
                <span className="text-sm font-medium">{commentsCount}</span>
              </div>
              <button
                onClick={handleShare}
                className="flex items-center justify-center hover:text-green-600 transition-colors"
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* <div className="flex items-center justify-between mt-4 pt-4 border-t">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center overflow-hidden">
                {deal.userPhotoUrl ? (
                  <img
                    src={deal.userPhotoUrl.startsWith("http") ? deal.userPhotoUrl : `${API_URL}${deal.userPhotoUrl}`}
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
                  window.location.href = `/announcements/deals/${deal.id}`
                }
              }}
            >
              {isExpired ? "Offre expirée" : "Voir le bon plan"}
            </Button>
          </div> */}

          
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
                  window.location.href = `/announcements/deals/${deal.id}`
                }
              }}
            >
              {isExpired ? "Offre expirée" : "Voir le bon plan"}
            </Button>
          </div>

          {/* Time */}
          {deal.createdat && (
            <div className="flex items-center gap-1 text-xs text-gray-500 mt-3 pt-3 border-t">
              <Clock className="w-3 h-3" />
              <span>{getTimeAgo(deal.createdat)}</span>
            </div>
          )}

        </div>
      </Card>
      </Link>
      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={deal.title}
        url={`/announcements/deals/${deal.id}`}
        description={deal.description}
      />
    </>
  )
}

function DealsContent({
  deals,
  viewMode,
  currentPage,
  totalPages,
  handlePageChange,
  isLoading,
}: {
  deals: Deal[]
  viewMode: ViewMode
  currentPage: number
  totalPages: number
  handlePageChange: (page: number) => void
  isLoading: boolean
}) {
  if (isLoading) {
    return (
      <div className="text-center py-20">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-green-500 mx-auto mb-4" />
        <p className="text-gray-600">Chargement des bons plans...</p>
      </div>
    )
  }

  if (deals.length === 0) {
    return (
      <div className="text-center py-20">
        <div className="mb-4">
          <Tag className="w-20 h-20 text-gray-300 mx-auto" />
        </div>
        <h3 className="text-xl font-semibold text-gray-700 mb-2">Aucun bon plan trouvé</h3>
        <p className="text-gray-500">Essayez de modifier vos filtres pour voir plus de résultats</p>
      </div>
    )
  }

    const { visibleItems: currentDeals, hasMore, sentinelRef } = useInfiniteRender(deals, 20)


  return (
    <>
      <div
        className={cn(
          viewMode === "grid"
            ? "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6"
            : "flex flex-col gap-4",
        )}
      >
        {/* {deals.map((deal, index) => ( */}
         {currentDeals.map((deal) => (
          <motion.div
            key={deal.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            // transition={{ delay: index * 0.05 }}
          >
            <DealCard deal={deal} viewMode={viewMode} />
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
      {/* Pagination */}
      {/* {totalPages > 1 && (
        <div className="flex justify-center items-center mt-12 gap-2">
          <Button
            variant="outline"
            disabled={currentPage === 1}
            onClick={() => handlePageChange(currentPage - 1)}
            className="hover:bg-green-50"
          >
            Précédent
          </Button>
          <div className="flex gap-1">
            {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => {
              let page: number
              if (totalPages <= 7) {
                page = i + 1
              } else if (currentPage <= 4) {
                page = i + 1
              } else if (currentPage >= totalPages - 3) {
                page = totalPages - 6 + i
              } else {
                page = currentPage - 3 + i
              }

              return (
                <Button
                  key={page}
                  variant={page === currentPage ? "default" : "outline"}
                  onClick={() => handlePageChange(page)}
                  className={cn("w-10", page === currentPage ? "bg-green-600 hover:bg-green-700" : "hover:bg-green-50")}
                >
                  {page}
                </Button>
              )
            })}
          </div>
          <Button
            variant="outline"
            disabled={currentPage === totalPages}
            onClick={() => handlePageChange(currentPage + 1)}
            className="hover:bg-green-50"
          >
            Suivant
          </Button>
        </div>
      )} */}
    </>
  )
}

export default function Deals() {
  const router = useRouter()
  const params = useSearchParams()
  const { toast } = useToast()

  const [selectedCategory, setSelectedCategory] = useState(params.get("adsCategory") || dealsCategories[0])
  const [selectedSubCategory, setSelectedSubCategory] = useState<string | null>(params.get("subCategory"))
  const [selectedDealType, setSelectedDealType] = useState("all")
  const [selectedAvailability, setSelectedAvailability] = useState("all")
  const [searchTerm, setSearchTerm] = useState(params.get("q") || "")
  const [location, setLocation] = useState(params.get("location") || "")
  const [isGettingLocation, setIsGettingLocation] = useState(false)
  const [viewMode, setViewMode] = useState<ViewMode>("grid")
  const [sortBy, setSortBy] = useState<SortOption>("recent")
  const [allDeals, setAllDeals] = useState<Deal[]>([])
  const [currentPage, setCurrentPage] = useState(1)
  const [dealsPerPage] = useState(20)
  const [userId, setUserId] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const initialLoadDone = useRef(false)

  const [radius, setRadius] = useState([parseInt(params.get("radius") || "10")])
  const [searchAllFrance, setSearchAllFrance] = useState(false)
  const [useCurrentLocation, setUseCurrentLocation] = useState(false)
  const [filtersOpen, setFiltersOpen] = useState(params.get("allFrance") === "true")
  const [citySearchTerm, setCitySearchTerm] = useState("")
  const [showCitySuggestions, setShowCitySuggestions] = useState(false)

  const [showExpired, setShowExpired] = useState(false)

  // Coordonnées GPS de la recherche
  const [searchCoords, setSearchCoords] = useState({
    lat: parseFloat(params.get("lat") || "0"),
    lng: parseFloat(params.get("lng") || "0")
  })

  // Suggestions de villes basées sur la recherche
  const citySuggestions = useMemo(() => {
    if (!citySearchTerm || citySearchTerm.length < 2) return []
    const search = citySearchTerm.toLowerCase()
    return citiesData
      .filter((city: any) => 
        city.name.toLowerCase().includes(search) || 
        city.zipcode.includes(search)
      )
      .slice(0, 10)
  }, [citySearchTerm])

  // Get user ID
  useEffect(() => {
    if (typeof window !== "undefined") {
      setUserId(localStorage.getItem("profileId"))
    }
  }, [])

  // Initialiser les filtres depuis les paramètres URL
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    
    // Terme de recherche
    const searchQuery = urlParams.get("q")
    if (searchQuery) {
      setSearchTerm(searchQuery)
    }
    
    // Localisation
    const locationParam = urlParams.get("location")
    if (locationParam) {
      setLocation(locationParam)
    }
    
    // Rayon
    const radiusParam = urlParams.get("radius")
    if (radiusParam) {
      setRadius([parseInt(radiusParam)])
    }
    
    // Recherche France entière
    const allFranceParam = urlParams.get("allFrance")
    if (allFranceParam === "true") {
      setSearchAllFrance(true)
      setLocation("")
    }
    
    // Catégorie (pour des recherches futures)
    const categoryParam = urlParams.get("category")
    if (categoryParam) {
      setSelectedCategory(categoryParam)
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


  const handleUseGeolocation = () => {
    if (searchAllFrance) return

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
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=10&addressdetails=1`,
          )
          const data = await response.json()
          const city = data.address.city || data.address.town || data.address.village || "Ma position"
          setLocation(city)
          setUseCurrentLocation(true)
          
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
          console.error("Error getting location name:", error)
          setLocation("Ma position")
          setUseCurrentLocation(true)
          
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

        let title = "Géolocalisation impossible"
        let description = ""

        switch (error.code) {
          case error.PERMISSION_DENIED:
            title = "Autorisation refusée"
            description = "Vous devez autoriser l'accès à votre position pour utiliser cette fonctionnalité."
            break
          case error.POSITION_UNAVAILABLE:
            title = "Position indisponible"
            description = "Impossible de déterminer votre position."
            break
          case error.TIMEOUT:
            title = "Délai dépassé"
            description = "La demande de géolocalisation a pris trop de temps."
            break
          default:
            description = "Une erreur s'est produite lors de la géolocalisation."
        }

        toast({
          title,
          description,
          variant: "destructive",
        })
      },
    )
  }

  // Load all deals
  useEffect(() => {
    const loadAllDeals = async () => {
      setIsLoading(true)

      try {
        const result = await fetchAnnoncements({
          category: "bons_plans",
        })
console.log("fetchAnnoncements result:", result)
        if (result.success) {
          setAllDeals(result.deals)
        } else {
          console.error("Erreur lors du chargement des annonces:", result.error)
          setAllDeals([])
        }
      } catch (error) {
        console.error("Exception lors du chargement des annonces:", error)
        setAllDeals([])
      } finally {
        setIsLoading(false)
        initialLoadDone.current = true
      }
    }

    loadAllDeals()
  }, [])

  // Reset subcategory when category changes
  useEffect(() => {
    if (initialLoadDone.current && !params.get("subCategory")) {
      setSelectedSubCategory(null)
    }
  }, [selectedCategory, params])

  useEffect(() => {
    if (searchAllFrance) {
      setLocation("")
      setUseCurrentLocation(false)
    }
  }, [searchAllFrance])

  // Filter deals
  const filteredDeals = useMemo(() => {
    if (allDeals.length === 0) return []

    return allDeals.filter((deal) => {
      // Filtre des offres expirées
      if (!showExpired && deal.endDate && new Date(deal.endDate) < new Date()) {
        return false
      }

      // Filtre de recherche textuelle
      if (searchTerm) {
        const search = searchTerm.toLowerCase()
        const matchesTitle = (deal.title || "").toLowerCase().includes(search)
        const matchesDescription = (deal.description || "").toLowerCase().includes(search)
        const matchesBrand = deal.brand ? 
          (typeof deal.brand === 'string' ? deal.brand.toLowerCase().includes(search) : false) : false
        
        if (!matchesTitle && !matchesDescription && !matchesBrand) return false
      }

      // Filtre par type de bon plan - Corriger le mapping
      if (selectedDealType !== "all") {
        // Mapper les valeurs d'interface vers les valeurs de base de données
        const dealTypeMapping: Record<string, string> = {
          "Discount": "price",     // Réduction -> price
          "Promotion": "code",     // Promotion -> code  
          "GoodPlan": "info",      // Bon plan -> info
          "Flash": "flash"         // Flash -> flash
        }
        
        const mappedDealType = dealTypeMapping[selectedDealType] || selectedDealType
        if (deal.dealType !== mappedDealType) {
          return false
        }
      }

      // Filtre par catégorie
      if (selectedCategory !== "All" && deal.dealCategory !== selectedCategory) {
        return false
      }

      // Filtre par sous-catégorie
      if (selectedSubCategory && deal.subCategory !== selectedSubCategory) {
        return false
      }

      // Filtre par disponibilité
      if (selectedAvailability === "online" && !deal.isOnline) return false
      if (selectedAvailability === "inStore" && deal.isOnline) return false

      // Filtre par localisation avec calcul de distance
      if (location && !searchAllFrance) {
        try {
          // Si on a des coordonnées de recherche valides et un rayon
          if (searchCoords.lat !== 0 && searchCoords.lng !== 0 && radius[0] > 0) {
            // Extraire les coordonnées de l'annonce
            let dealLat = 0
            let dealLng = 0
            let dealCity = ""
            let dealZipcode = ""

            if (deal.address) {
              if (typeof deal.address === 'string') {
                try {
                  const addressObj = JSON.parse(deal.address)
                  dealLat = parseFloat(addressObj.latitude || addressObj.lat || 0)
                  dealLng = parseFloat(addressObj.longitude || addressObj.lng || addressObj.lon || 0)
                  dealCity = addressObj.city || addressObj.ville || ""
                  dealZipcode = addressObj.zipcode || addressObj.codepostal || ""
                } catch {
                  // Si le parsing échoue, continuer
                }
              } else if (typeof deal.address === 'object') {
                dealLat = parseFloat(deal.address.latitude || deal.address.lat || 0)
                dealLng = parseFloat(deal.address.longitude || deal.address.lng || deal.address.lon || 0)
                dealCity = deal.address.city || deal.address.ville || ""
                dealZipcode = deal.address.zipcode || deal.address.codepostal || ""
              }
            }

            // Si pas de coordonnées dans l'adresse, essayer avec les données de l'entreprise
            if ((dealLat === 0 || dealLng === 0) && deal.companyData) {
              dealLat = parseFloat((deal.companyData as any).latitude || (deal.companyData as any).lat || 0)
              dealLng = parseFloat((deal.companyData as any).longitude || (deal.companyData as any).lng || (deal.companyData as any).lon || 0)
              if (!dealCity) dealCity = deal.companyData.ville || ""
              if (!dealZipcode) dealZipcode = deal.companyData.codepostal || ""
            }

            // Si toujours pas de coordonnées, utiliser la table de correspondance ville/code postal
            if ((dealLat === 0 || dealLng === 0) && (dealCity || dealZipcode)) {
              const fallbackCoords = getCoordsFromAddress(dealCity, dealZipcode)
              if (fallbackCoords) {
                dealLat = fallbackCoords.lat
                dealLng = fallbackCoords.lng
              }
            }

            // Si on a des coordonnées valides pour l'annonce, calculer la distance
            if (dealLat !== 0 && dealLng !== 0) {
              const distance = calculateDistance(searchCoords.lat, searchCoords.lng, dealLat, dealLng)
              
              // Filtrer si la distance est supérieure au rayon
              if (distance > radius[0]) {
                return false
              }
            }
            // Si pas de coordonnées GPS pour l'annonce, on l'inclut dans les résultats
          } else {
            // Pas de coordonnées GPS de recherche, ne pas filtrer par localisation
          }
        } catch (error) {
          console.warn("Erreur lors du filtrage par localisation:", error)
        }
      }

      return true
    })
  }, [
    allDeals,
    selectedDealType,
    selectedCategory,
    selectedSubCategory,
    selectedAvailability,
    searchTerm,
    location,
    searchAllFrance,
    showExpired,
    radius,
    searchCoords,
  ])



  // const sortedDeals = useMemo(() => {
  //   const sorted = [...filteredDeals]

  //   switch (sortBy) {
  //     case "recent":
  //       sorted.sort((a, b) => {
  //         const dateA = new Date(a.createdat || 0).getTime()
  //         const dateB = new Date(b.createdat || 0).getTime()
  //         return dateB - dateA
  //       })
  //       break
  //     case "ending":
  //       sorted.sort((a, b) => {
  //         if (!a.endDate) return 1
  //         if (!b.endDate) return -1
  //         const dateA = new Date(a.endDate).getTime()
  //         const dateB = new Date(b.endDate).getTime()
  //         return dateA - dateB
  //       })
  //       break
  //     case "popular":
  //       // For now, just use recent as we don't have popularity data
  //       sorted.sort((a, b) => {
  //         const dateA = new Date(a.createdat || 0).getTime()
  //         const dateB = new Date(b.createdat || 0).getTime()
  //         return dateB - dateA
  //       })
  //       break
  //     case "discount":
  //       // For now, just use recent as we don't have discount percentage data
  //       sorted.sort((a, b) => {
  //         const dateA = new Date(a.createdat || 0).getTime()
  //         const dateB = new Date(b.createdat || 0).getTime()
  //         return dateB - dateA
  //       })
  //       break
  //   }

  //   return sorted
  // }, [filteredDeals, sortBy])


  const sortedDeals = useMemo(() => {
    const sorted = [...filteredDeals]

    switch (sortBy) {
      case "recent":
        sorted.sort((a, b) => {
          const dateA = new Date(a.createdat || a.created_at || 0).getTime()
          const dateB = new Date(b.createdat || b.created_at || 0).getTime()
          return dateB - dateA
        })
        break
        
      case "ending":
        // Trier par date de fin (les plus proches en premier)
        sorted.sort((a, b) => {
          if (!a.endDate && !b.endDate) return 0
          if (!a.endDate) return 1
          if (!b.endDate) return -1
          const dateA = new Date(a.endDate).getTime()
          const dateB = new Date(b.endDate).getTime()
          return dateA - dateB
        })
        break
        
      case "oldest":
        // Trier par date de création (plus anciens en premier)
        sorted.sort((a, b) => {
          const dateA = new Date(a.createdat || a.created_at || 0).getTime()
          const dateB = new Date(b.createdat || b.created_at || 0).getTime()
          return dateA - dateB
        })
        break
        
      case "discount":
        // Trier par pourcentage de réduction
        sorted.sort((a, b) => {
          const getDiscountPercentage = (deal: Deal) => {
            if (deal.initialPrice && deal.finalPrice) {
              const initial = parseFloat(deal.initialPrice)
              const final = parseFloat(deal.finalPrice)
              if (initial > final) {
                return ((initial - final) / initial) * 100
              }
            }
            if (deal.discountValue) {
              return parseFloat(deal.discountValue)
            }
            return 0
          }
          
          const discountA = getDiscountPercentage(a)
          const discountB = getDiscountPercentage(b)
          return discountB - discountA
        })
        break
        
      default:
        // Tri par défaut : récent
        sorted.sort((a, b) => {
          const dateA = new Date(a.createdat || a.created_at || 0).getTime()
          const dateB = new Date(b.createdat || b.created_at || 0).getTime()
          return dateB - dateA
        })
    }

    return sorted
  }, [filteredDeals, sortBy])

  // Pagination
  const paginationData = useMemo(() => {
    const indexOfLastDeal = currentPage * dealsPerPage
    const indexOfFirstDeal = indexOfLastDeal - dealsPerPage
    const currentDeals = sortedDeals.slice(indexOfFirstDeal, indexOfLastDeal)
    const totalPages = Math.ceil(sortedDeals.length / dealsPerPage)

    return { currentDeals, totalPages }
  }, [sortedDeals, currentPage, dealsPerPage])

  const handlePageChange = (page: number) => {
    if (page > 0 && page <= paginationData.totalPages) {
      setCurrentPage(page)
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }

  const searchCriteria = {
    category: "bons_plans",
    search_query: searchTerm,
    location: location,
    filters: {
      dealType: selectedDealType !== "all" ? selectedDealType : undefined,
      dealCategory: selectedCategory !== "All" ? selectedCategory : undefined,
      subCategory: selectedSubCategory || undefined,
      availability: selectedAvailability !== "all" ? selectedAvailability : undefined,
    },
  }

  const currentUrl = typeof window !== "undefined" ? window.location.href : ""

  return (
    <Suspense fallback={<div>Chargement...</div>}>
      <div className="min-h-screen bg-gray-50">
        <DealsHeader searchTerm={searchTerm} setSearchTerm={setSearchTerm} totalDeals={allDeals.length} />

        <div className="max-w-[1400px] mx-auto px-4 py-6">
          <DealsToolbar
            userId={userId}
            router={router}
            viewMode={viewMode}
            setViewMode={setViewMode}
            sortBy={sortBy}
            setSortBy={setSortBy}
            totalResults={sortedDeals.length}
            filtersOpen={filtersOpen}
            onToggleFilters={() => setFiltersOpen(!filtersOpen)}
            showExpired={showExpired}
            onToggleExpired={() => setShowExpired(!showExpired)}
            // Pass search criteria to toolbar
            searchCriteria={searchCriteria}
            currentUrl={currentUrl}
          />

          <SearchFilters
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
            selectedSubCategory={selectedSubCategory}
            setSelectedSubCategory={setSelectedSubCategory}
            selectedDealType={selectedDealType}
            setSelectedDealType={setSelectedDealType}
            selectedAvailability={selectedAvailability}
            setSelectedAvailability={setSelectedAvailability}
            location={location}
            setLocation={setLocation}
            radius={radius}
            setRadius={setRadius}
            searchAllFrance={searchAllFrance}
            setSearchAllFrance={setSearchAllFrance}
            useCurrentLocation={useCurrentLocation}
            onUseGeolocation={handleUseGeolocation}
            isGettingLocation={isGettingLocation}
            isOpen={filtersOpen}
            citySearchTerm={citySearchTerm}
            setCitySearchTerm={setCitySearchTerm}
            showCitySuggestions={showCitySuggestions}
            setShowCitySuggestions={setShowCitySuggestions}
            citySuggestions={citySuggestions}
            params={params}
            router={router}
            setSearchCoords={setSearchCoords}
          />

          <DealsContent
            deals={paginationData.currentDeals}
            viewMode={viewMode}
            currentPage={currentPage}
            totalPages={paginationData.totalPages}
            handlePageChange={handlePageChange}
            isLoading={isLoading}
          />
        </div>
      </div>
    </Suspense>
  )
}
