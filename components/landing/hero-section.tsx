"use client"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Slider } from "@/components/ui/slider"
import { Checkbox } from "@/components/ui/checkbox"
import { Search, MapPin, Bookmark, Locate, Loader2 } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import { motion } from "framer-motion"
import { useState, useMemo, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import dynamic from "next/dynamic"
import { useToast } from "@/hooks/use-toast"
import franceCities from "@/lib/data/france-cities.json"
import { SaveSearchButton } from "@/components/save-search-button"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import axios from "axios"
import { config } from "@/lib/config"

import { useAuthStore } from "@/lib/auth-store"
import "@/app/leaflet.css"

// Import dynamique pour éviter l'erreur SSR
const MapWithRadius = dynamic(() => import("@/components/map-with-radius").then(mod => ({ default: mod.MapWithRadius })), {
  ssr: false,
  loading: () => <div className="h-[400px] bg-gray-100 rounded-lg animate-pulse flex items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-gray-400" /></div>
})

interface City {
  name: string
  region: string
  zipcode: string
}

export function HeroSection() {
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedCategory, setSelectedCategory] = useState("")
  const [location, setLocation] = useState("")
  const [radius, setRadius] = useState([10])
  const [isLocating, setIsLocating] = useState(false)
  const [useCurrentLocation, setUseCurrentLocation] = useState(false)
  const [searchAllFrance, setSearchAllFrance] = useState(false)
  const [showCitySuggestions, setShowCitySuggestions] = useState(false)
  const [searchSuggestions, setSearchSuggestions] = useState<any[]>([])
  const [showSearchSuggestions, setShowSearchSuggestions] = useState(false)
  const [isLoadingSuggestions, setIsLoadingSuggestions] = useState(false)
  const [mapCenter, setMapCenter] = useState<[number, number]>([48.8566, 2.3522]) // Paris par défaut
  const [showMap, setShowMap] = useState(false)
  const [searchCoords, setSearchCoords] = useState({ lat: 0, lng: 0 }) // Coordonnées GPS de la recherche
  const currentUrl = typeof window !== "undefined" ? window.location.href : ""
  const { userId, isAuthenticated, logout, fetchUserInfo } = useAuthStore()
  const router = useRouter()
  const { toast } = useToast()


  
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

    router.push("/announcements/create")
  }   

  // Live search pour les suggestions d'annonces
  const fetchSearchSuggestions = useCallback(async (query: string) => {
    if (!query || query.length < 1) {
      setSearchSuggestions([])
      setShowSearchSuggestions(false)
      return
    }

    setIsLoadingSuggestions(true)
    try {
      // Convertir la catégorie au format API
      const categoryMap: Record<string, string> = {
        'bons-plans': 'bons_plans',
        'offres-emploi': 'emplois',
        'formations': 'formations',
        'evenements': 'evenements',
        'demandes': 'demandes'
      }

      // Préparer les paramètres de recherche
      const searchParams: any = {
        Method: "readAdsByCriteria",
        title: query
      }

      // Ajouter la catégorie seulement si elle est sélectionnée et différente de "all"
      if (selectedCategory && selectedCategory !== 'all') {
        searchParams.category = categoryMap[selectedCategory]
      }

      const response = await axios.post(
        `${config.API_URL}/Ads.php`,
        searchParams,
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        }
      )

      if (response.data.status === "success" && response.data.ads) {
        setSearchSuggestions(response.data.ads.slice(0, 5)) // Limiter à 5 suggestions
        setShowSearchSuggestions(true)
      } else {
        setSearchSuggestions([])
        setShowSearchSuggestions(false)
      }
    } catch (error) {
      console.error("Erreur lors de la recherche de suggestions:", error)
      setSearchSuggestions([])
    } finally {
      setIsLoadingSuggestions(false)
    }
  }, [selectedCategory])

  // Debounce pour le live search
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchSearchSuggestions(searchTerm)
    }, 300) // Attendre 300ms après la dernière frappe

    return () => clearTimeout(timer)
  }, [searchTerm, fetchSearchSuggestions])

  // Filtrer et limiter les suggestions de villes
  const citySuggestions = useMemo(() => {
    if (!location || location.length < 2) return []
    
    const filtered = (franceCities as City[]).filter(city => 
      city.name && (
        city.name.toLowerCase().includes(location.toLowerCase()) ||
        city.zipcode.includes(location)
      )
    ).slice(0, 8) // Limiter à 8 suggestions
    
    return filtered
  }, [location])

  const handleGetCurrentLocation = async () => {
    if (searchAllFrance) return

    if (!navigator.geolocation) {
      toast({
        title: "Géolocalisation non disponible",
        description: "Votre navigateur ne supporte pas la géolocalisation.",
        variant: "destructive",
      })
      return
    }

    setIsLocating(true)

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords

        // Reverse geocoding to get city name (using a free API)
        try {
          const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=10&addressdetails=1`,
          )
          const data = await response.json()
          const city = data.address.city || data.address.town || data.address.village || "Ma position"
          setLocation(city)
          setUseCurrentLocation(true)
          setMapCenter([latitude, longitude])
          setShowMap(true)
          // Stocker les coordonnées GPS pour la recherche
          setSearchCoords({ lat: latitude, lng: longitude })
          toast({
            title: "Position détectée",
            description: `Recherche autour de ${city}`,
          })
        } catch (error) {
          console.error("Error getting location name:", error)
          setLocation("Ma position")
          setUseCurrentLocation(true)
          setMapCenter([latitude, longitude])
          setShowMap(true)
          // Stocker les coordonnées GPS pour la recherche
          setSearchCoords({ lat: latitude, lng: longitude })
          toast({
            title: "Position détectée",
            description: "Recherche autour de votre position actuelle",
          })
        } finally {
          setIsLocating(false)
        }
      },
      (error) => {
        setIsLocating(false)

        let title = "Géolocalisation impossible"
        let description = ""

        switch (error.code) {
          case error.PERMISSION_DENIED:
            title = "Autorisation refusée"
            description =
              "Vous devez autoriser l'accès à votre position pour utiliser cette fonctionnalité. Vérifiez les paramètres de votre navigateur."
            break
          case error.POSITION_UNAVAILABLE:
            title = "Position indisponible"
            description = "Impossible de déterminer votre position. Veuillez réessayer."
            break
          case error.TIMEOUT:
            title = "Délai dépassé"
            description = "La demande de géolocalisation a pris trop de temps. Veuillez réessayer."
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

  const handleSearchAllFranceChange = (checked: boolean) => {
    setSearchAllFrance(checked)
    if (checked) {
      // Clear location and reset radius when searching all France
      setLocation("")
      setUseCurrentLocation(false)
      setShowMap(false)
    }
  }

  // Géocoder une ville pour obtenir ses coordonnées
  const geocodeCity = async (cityName: string, zipcode?: string) => {
    try {
      const query = zipcode 
        ? `${encodeURIComponent(cityName)},${zipcode},France`
        : `${encodeURIComponent(cityName)},France`
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${query}&limit=1`
      )
      const data = await response.json()
      if (data && data.length > 0) {
        const lat = parseFloat(data[0].lat)
        const lon = parseFloat(data[0].lon)
        setMapCenter([lat, lon])
        setShowMap(true)
        // Stocker les coordonnées GPS pour la recherche
        setSearchCoords({ lat, lng: lon })
      }
    } catch (error) {
      console.error("Erreur lors du géocodage:", error)
    }
  }

  // Sélectionner une ville depuis les suggestions
  const handleCitySelect = (city: City) => {
    setLocation(`${city.name} (${city.zipcode})`)
    setShowCitySuggestions(false)
    geocodeCity(city.name, city.zipcode)
  }

  // Fonction de recherche principale
  const handleSearch = () => {
    // Construire les paramètres de recherche
    const searchParams = new URLSearchParams()
    
    if (searchTerm.trim()) {
      searchParams.set('q', searchTerm.trim())
    }
    
    if (location.trim() && !searchAllFrance) {
      searchParams.set('location', location.trim())
      searchParams.set('radius', radius[0].toString())
      
      // Ajouter les coordonnées GPS si disponibles
      if (searchCoords.lat !== 0 && searchCoords.lng !== 0) {
        searchParams.set('lat', searchCoords.lat.toString())
        searchParams.set('lng', searchCoords.lng.toString())
      }
    }
    
    if (searchAllFrance) {
      searchParams.set('allFrance', 'true')
    }
    
    // Router vers la page appropriée selon la catégorie
    const categoryRoutes = {
      'bons-plans': '/bons-plans',
      'offres-emploi': '/offres-emploi', 
      'formations': '/formations',
      'evenements': '/evenements',
      'demandes': '/demandes'
    }
    
    const route = categoryRoutes[selectedCategory as keyof typeof categoryRoutes] || '/bons-plans'
    const url = `${route}?${searchParams.toString()}`
    
    console.log('Redirecting to:', url)
    router.push(url)
  }

  // Sauvegarder la recherche
  const handleSaveSearch = () => {
    const searchData = {
      term: searchTerm,
      category: selectedCategory,
      location: location,
      radius: radius[0],
      searchAllFrance: searchAllFrance,
      timestamp: new Date().toISOString()
    }
    
    // Sauvegarder dans le localStorage
    const savedSearches = JSON.parse(localStorage.getItem('savedSearches') || '[]')
    savedSearches.unshift(searchData)
    
    // Limiter à 10 recherches sauvegardées
    if (savedSearches.length > 10) {
      savedSearches.splice(10)
    }
    
    localStorage.setItem('savedSearches', JSON.stringify(savedSearches))
    
    toast({
      title: "Recherche sauvegardée",
      description: "Votre recherche a été ajoutée à vos favoris",
    })
  }

  return (
    <section className="relative overflow-hidden overflow-x-hidden pt-20 pb-16">
      {/* Background image avec overlay blanc */}
      <div className="absolute inset-0 -z-10">
        <Image
          src="/images/hero-background.jpg"
          alt="Background"
          fill
          className="object-cover"
          priority
        />
        {/* Overlay blanc semi-transparent pour garder la lisibilité */}
        <div className="absolute inset-0 bg-white/80 dark:bg-gray-900/80" />
      </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left content */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center lg:text-left space-y-6"
          >
            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold text-balance leading-tight">
              Bienvenue sur la plateforme qui digitalise le{" "}
              <span className="text-teal-600 dark:text-teal-400">bouche à oreille</span> !
            </h1>

            <p className="text-lg sm:text-xl text-muted-foreground text-pretty max-w-2xl mx-auto lg:mx-0">
              Transformez vos recommandations en réseau digital. Rejoignez une communauté où le partage d'expériences
              fait grandir votre confiance et vos choix.
            </p>

<FeatureGuard feature="ads">
            <Button 
              size="lg" 
              className="bg-teal-600 hover:bg-teal-700 text-white h-14 px-8"
              onClick={handleCreateAnnouncement}
            >
              Poster une annonce
            </Button>
            </FeatureGuard>
          </motion.div>

          {/* Right content - Search form */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="relative"
          >
            <div className="bg-white dark:bg-gray-800 rounded-3xl shadow-2xl p-8 space-y-6 border border-teal-100 dark:border-gray-700">
              <div className="text-center mb-6">
                <h3 className="text-2xl font-bold mb-2">Trouvez ce que vous cherchez</h3>
                <p className="text-sm text-muted-foreground">
                  Bons plans, emplois, formations, événements et plus encore
                </p>
              </div>

              <div className="space-y-4">
                {/* Terme de recherche avec suggestions */}
                <div className="relative">
                  <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground z-10" />
                  {isLoadingSuggestions && (
                    <Loader2 className="absolute right-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground animate-spin z-10" />
                  )}
                  <Input
                    placeholder="Que recherchez-vous ?"
                    className="pl-12 h-14 text-base rounded-xl border-2 focus:border-teal-500"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                    onFocus={() => searchTerm.length >= 1 && setShowSearchSuggestions(true)}
                    onBlur={() => setTimeout(() => setShowSearchSuggestions(false), 200)}
                  />
                  
                  {/* Suggestions de recherche */}
                  {showSearchSuggestions && searchSuggestions.length > 0 && (
                    <div className="absolute top-full left-0 right-0 z-50 mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg max-h-80 overflow-auto">
                      {searchSuggestions.map((suggestion) => (
                        <button
                          key={suggestion.id}
                          type="button"
                          className="w-full px-4 py-3 text-left hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700 last:border-b-0"
                          onClick={() => {
                            // Fermer les suggestions
                            setShowSearchSuggestions(false)
                            
                            // Rediriger directement vers la page de détail de l'annonce
                            const categoryRouteMap: Record<string, string> = {
                              'bons_plans': 'deals',
                              'emplois': 'jobs',
                              'formations': 'trainings',
                              'evenements': 'events',
                              'demandes': 'inquiries'
                            }
                            const routeType = categoryRouteMap[suggestion.category] || 'deals'
                            router.push(`/announcements/${routeType}/${suggestion.id}`)
                          }}
                        >
                          <div className="font-medium text-gray-900 dark:text-gray-100 line-clamp-1">
                            {suggestion.title}
                          </div>
                          {suggestion.description && (
                            <div className="text-sm text-gray-500 dark:text-gray-400 line-clamp-1 mt-1">
                              {suggestion.description.replace(/<[^>]*>/g, '').substring(0, 100)}...
                            </div>
                          )}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* Sélection de catégorie */}
                <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                  <SelectTrigger className="h-14 text-base rounded-xl border-2">
                    <SelectValue placeholder="Toutes les catégories" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">🌐 Toutes les catégories</SelectItem>
                    <SelectItem value="bons-plans">🎁 Bons plans</SelectItem>
                    <SelectItem value="offres-emploi">💼 Offres d'emploi</SelectItem>
                    <SelectItem value="formations">🎓 Formations</SelectItem>
                    <SelectItem value="evenements">📅 Événements</SelectItem>
                    <SelectItem value="demandes">💬 Demandes</SelectItem>
                  </SelectContent>
                </Select>

                <div className="space-y-3">
                  {/* Localisation avec autocomplétion */}
                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <MapPin className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                      <Input
                        placeholder="Ville, code postal..."
                        value={location}
                        onChange={(e) => {
                          const newValue = e.target.value
                          setLocation(newValue)
                          setUseCurrentLocation(false)
                          setShowCitySuggestions(newValue.length >= 2)
                          // Masquer la carte si le champ est vide
                          if (newValue.trim() === "") {
                            setShowMap(false)
                          }
                        }}
                        onFocus={() => location.length >= 2 && setShowCitySuggestions(true)}
                        onBlur={() => setTimeout(() => setShowCitySuggestions(false), 200)}
                        disabled={searchAllFrance}
                        className="pl-12 h-14 text-base rounded-xl border-2 focus:border-teal-500 disabled:opacity-50 disabled:cursor-not-allowed"
                      />
                      
                      {/* Suggestions de villes */}
                      {showCitySuggestions && citySuggestions.length > 0 && (
                        <div className="absolute top-full left-0 right-0 z-50 mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg max-h-60 overflow-auto">
                          {citySuggestions.map((city, index) => (
                            <button
                              key={`${city.name}-${city.zipcode}-${index}`}
                              type="button"
                              className="w-full px-4 py-2 text-left hover:bg-gray-50 dark:hover:bg-gray-700 flex items-center justify-between"
                              onClick={() => handleCitySelect(city)}
                            >
                              <div>
                                <div className="font-medium">{city.name}</div>
                                <div className="text-sm text-gray-500 dark:text-gray-400">{city.region}</div>
                              </div>
                              <div className="text-sm text-gray-400 dark:text-gray-500">{city.zipcode}</div>
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      size="icon"
                      onClick={handleGetCurrentLocation}
                      disabled={isLocating || searchAllFrance}
                      className="h-14 w-14 rounded-xl border-2 hover:bg-teal-50 hover:border-teal-500 shrink-0 bg-transparent disabled:opacity-50 disabled:cursor-not-allowed"
                      title="Autour de moi"
                    >
                      {isLocating ? <Loader2 className="h-5 w-5 animate-spin" /> : <Locate className="h-5 w-5" />}
                    </Button>
                  </div>

                  {/* Slider de rayon */}
                  <div className="space-y-2 px-1">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted-foreground">Rayon de recherche</span>
                      <span className="font-semibold text-teal-600">
                        {searchAllFrance ? "France entière" : radius[0] === 0 ? "Ville uniquement" : `${radius[0]} km`}
                      </span>
                    </div>
                    <Slider
                      value={radius}
                      onValueChange={setRadius}
                      max={200}
                      step={5}
                      className="w-full"
                      disabled={searchAllFrance}
                    />
                    <div className="flex justify-between text-xs text-muted-foreground">
                      <span>0 km</span>
                      <span>50 km</span>
                      <span>100 km</span>
                      <span>150 km</span>
                      <span>200 km</span>
                    </div>
                  </div>

                  {/* Carte interactive avec rayon */}
                  {showMap && !searchAllFrance && (
                    <div className="mt-4">
                      <MapWithRadius
                        center={mapCenter}
                        radius={radius[0]}
                        locationName={location}
                      />
                    </div>
                  )}

                  {/* Checkbox toute la France */}
                  <div className="flex items-center space-x-2 px-1 py-2">
                    <Checkbox
                      id="search-all-france"
                      checked={searchAllFrance}
                      onCheckedChange={handleSearchAllFranceChange}
                      className="data-[state=checked]:bg-teal-600 data-[state=checked]:border-teal-600"
                    />
                    <label
                      htmlFor="search-all-france"
                      className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer"
                    >
                      Rechercher dans toute la France
                    </label>
                  </div>

                  {/* Indicateurs d'état */}
                  {useCurrentLocation && !searchAllFrance && (
                    <div className="flex items-center gap-2 text-sm text-teal-600 bg-teal-50 dark:bg-teal-900/20 px-3 py-2 rounded-lg">
                      <Locate className="h-4 w-4" />
                      <span>Recherche autour de votre position</span>
                    </div>
                  )}

                  {searchAllFrance && (
                    <div className="flex items-center gap-2 text-sm text-teal-600 bg-teal-50 dark:bg-teal-900/20 px-3 py-2 rounded-lg">
                      <MapPin className="h-4 w-4" />
                      <span>Recherche sur tout le territoire français</span>
                    </div>
                  )}
                </div>

                {/* Boutons d'action */}
                <div className="pt-2">
                  <Button 
                    onClick={handleSearch}
                    className="w-full bg-teal-600 hover:bg-teal-700 h-14 text-base rounded-xl font-semibold"
                  >
                    <Search className="mr-2 h-5 w-5" />
                    Rechercher
                  </Button>
                </div>

                {/* <Button 
                  variant="link" 
                  className="w-full text-teal-600 hover:text-teal-700 font-medium"
                  onClick={handleSaveSearch}
                  disabled={!searchTerm.trim() && !location.trim()}
                >
                  💾 Sauvegarder ma recherche
                </Button> */}
                <SaveSearchButton
                  searchTerm={searchTerm}
                  category={selectedCategory}
                  location={location}
                  radius={radius[0]}
                  searchAllFrance={searchAllFrance}
                  useGeolocation={useCurrentLocation}
                  userPosition={null}
                  currentUrl={currentUrl}
                  className="w-full text-teal-600 hover:text-teal-700 font-medium"
                />
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}