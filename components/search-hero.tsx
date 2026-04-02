"use client"

import { useState, useEffect, useMemo } from "react"
import { useRouter } from "next/navigation"
import { Search, MapPin, Bookmark, Locate } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { useToast } from "@/hooks/use-toast"
import franceCities from "@/lib/data/france-cities.json"

interface City {
  name: string
  region: string
  zipcode: string
}

export function SearchHero() {
  const [searchTerm, setSearchTerm] = useState("")
  const [selectedCategory, setSelectedCategory] = useState("bons-plans")
  const [location, setLocation] = useState("")
  const [useLocation, setUseLocation] = useState(false)
  const [distance, setDistance] = useState(10)
  const [isGettingLocation, setIsGettingLocation] = useState(false)
  const [showCitySuggestions, setShowCitySuggestions] = useState(false)
  
  // États spécifiques pour l'emploi
  const [jobContract, setJobContract] = useState("all")
  const [jobExperience, setJobExperience] = useState("all")
  const [jobRemote, setJobRemote] = useState("all")
  const [jobSalary, setJobSalary] = useState("")
  
  const router = useRouter()
  const { toast } = useToast()

  // Filtrer et limiter les suggestions de villes
  const citySuggestions = useMemo(() => {
    if (!location || location.length < 2) return []
    
    const filtered = (franceCities as City[]).filter(city => 
      city.name.toLowerCase().includes(location.toLowerCase()) ||
      city.zipcode.includes(location)
    ).slice(0, 8) // Limiter à 8 suggestions
    
    return filtered
  }, [location])

  // Géolocalisation
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
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&accept-language=fr`,
          )
          const data = await response.json()
          const city = data.address?.city || data.address?.town || data.address?.village || ""
          
          setLocation(city)
          setUseLocation(true)
          
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

  // Fonction de recherche
  const handleSearch = () => {
    console.log('=== DEBUG: handleSearch called ===')
    console.log('searchTerm:', searchTerm)
    console.log('selectedCategory:', selectedCategory)
    console.log('location:', location)
    console.log('distance:', distance)
    
    // Construire les paramètres de recherche
    const searchParams = new URLSearchParams()
    
    if (searchTerm.trim()) {
      searchParams.set('q', searchTerm.trim())
      console.log('Added search term to params:', searchTerm.trim())
    }
    
    if (location.trim()) {
      searchParams.set('location', location.trim())
      console.log('Added location to params:', location.trim())
    }
    
    searchParams.set('radius', distance.toString())
    console.log('Added radius to params:', distance.toString())

    if (selectedCategory === 'emploi') {
      if (jobContract !== 'all') searchParams.set('contract', jobContract)
      if (jobExperience !== 'all') searchParams.set('experience', jobExperience)
      if (jobRemote !== 'all') searchParams.set('remote', jobRemote)
      if (jobSalary) searchParams.set('minSalary', jobSalary)
    }
    
    // Router vers la page appropriée selon la catégorie
    const categoryRoutes = {
      'bons-plans': '/bons-plans',
      'emploi': '/offres-emploi', 
      'formations': '/formations',
      'evenements': '/evenements',
      'demandes': '/demandes'
    }
    
    const route = categoryRoutes[selectedCategory as keyof typeof categoryRoutes] || '/bons-plans'
    console.log('Selected route:', route)
    
    const url = `${route}?${searchParams.toString()}`
    console.log('Final URL:', url)
    console.log('Search params string:', searchParams.toString())
    
    router.push(url)
    console.log('=== DEBUG: router.push executed ===')
  }

  // Sélectionner une ville depuis les suggestions
  const handleCitySelect = (city: City) => {
    setLocation(`${city.name} (${city.zipcode})`)
    setShowCitySuggestions(false)
  }

  // Sauvegarder la recherche
  const handleSaveSearch = () => {
    const searchData = {
      term: searchTerm,
      category: selectedCategory,
      location: location,
      distance: distance,
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
    <div className="relative isolate overflow-hidden bg-gradient-to-b from-primary/5 to-background">
      <div className="mx-auto max-w-7xl px-6 py-24 sm:py-32 lg:px-8">
        <div className="mx-auto max-w-2xl text-center">
          <h1 className="text-4xl font-bold tracking-tight text-foreground sm:text-6xl text-balance">
            Bienvenue sur la plateforme qui digitalise le bouche-à-oreille !
          </h1>
          <p className="mt-6 text-lg leading-8 text-muted-foreground text-pretty">
            Transformez vos recommandations en réseau digital. Rejoignez une communauté où le partage d'expériences fait
            grandir votre confiance et vos choix.
          </p>
        </div>

        <div className="mx-auto mt-10 max-w-3xl">
          <div className="rounded-2xl bg-card p-6 shadow-lg border">
            <div className="space-y-4">
              {/* Terme de recherche */}
              <div>
                <label htmlFor="search" className="sr-only">
                  Que recherchez-vous ? TTT
                </label>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
                  <Input 
                    id="search" 
                    type="text" 
                    placeholder="Que recherchez-vous ?" 
                    className="pl-10 h-12"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                  />
                </div>
              </div>

              {/* Catégorie */}
              <div>
                <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Catégorie" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="bons-plans">🎯 Bons plans</SelectItem>
                    <SelectItem value="emploi">💼 Offres d'emploi</SelectItem>
                    <SelectItem value="formations">📚 Formations</SelectItem>
                    <SelectItem value="evenements">📅 Événements</SelectItem>
                    <SelectItem value="demandes">💬 Demandes</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Localisation */}
              <div className="relative">
                <label htmlFor="location" className="sr-only">
                  Localisation
                </label>
                <div className="relative">
                  <MapPin className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
                  <Input 
                    id="location" 
                    type="text" 
                    placeholder="Ville, code postal..." 
                    className="pl-10 pr-12 h-12"
                    value={location}
                    onChange={(e) => {
                      setLocation(e.target.value)
                      setUseLocation(false)
                      setShowCitySuggestions(e.target.value.length >= 2)
                    }}
                    onFocus={() => location.length >= 2 && setShowCitySuggestions(true)}
                    onBlur={() => setTimeout(() => setShowCitySuggestions(false), 200)}
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="absolute right-1 top-1/2 -translate-y-1/2 h-10 w-10"
                    onClick={handleUseGeolocation}
                    disabled={isGettingLocation}
                    title="Utiliser ma position"
                  >
                    {isGettingLocation ? (
                      <div className="w-4 h-4 border-2 border-gray-300 border-t-primary rounded-full animate-spin" />
                    ) : (
                      <Locate className="w-4 h-4" />
                    )}
                  </Button>
                </div>

                {/* Suggestions de villes */}
                {showCitySuggestions && citySuggestions.length > 0 && (
                  <div className="absolute top-full left-0 right-0 z-50 mt-1 bg-white border border-gray-200 rounded-md shadow-lg max-h-60 overflow-auto">
                    {citySuggestions.map((city, index) => (
                      <button
                        key={`${city.name}-${city.zipcode}-${index}`}
                        type="button"
                        className="w-full px-4 py-2 text-left hover:bg-gray-50 flex items-center justify-between"
                        onClick={() => handleCitySelect(city)}
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

              {/* Utiliser position actuelle */}
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="use-location"
                  checked={useLocation}
                  onChange={(e) => {
                    setUseLocation(e.target.checked)
                    if (e.target.checked) {
                      handleUseGeolocation()
                    }
                  }}
                  className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                />
                <label htmlFor="use-location" className="text-sm text-muted-foreground cursor-pointer">
                  Utiliser ma position actuelle
                </label>
              </div>

              {/* Filtres supplémentaires pour l'emploi */}
              {selectedCategory === 'emploi' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 p-4 bg-muted/30 rounded-xl border border-dashed animate-in fade-in slide-in-from-top-2 duration-300">
                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Type de contrat</label>
                    <Select value={jobContract} onValueChange={setJobContract}>
                      <SelectTrigger className="h-10 bg-background">
                        <SelectValue placeholder="Tous les contrats" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous les contrats</SelectItem>
                        <SelectItem value="PermanentContract">CDI</SelectItem>
                        <SelectItem value="FixedTermContract">CDD</SelectItem>
                        <SelectItem value="TemporaryWork">Intérim</SelectItem>
                        <SelectItem value="Internship">Stage</SelectItem>
                        <SelectItem value="Apprenticeship">Alternance</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Niveau d'expérience</label>
                    <Select value={jobExperience} onValueChange={setJobExperience}>
                      <SelectTrigger className="h-10 bg-background">
                        <SelectValue placeholder="Tous niveaux" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous niveaux</SelectItem>
                        <SelectItem value="Beginner0To1Year">0 - 1 an</SelectItem>
                        <SelectItem value="Intermediate2To4Years">2 - 4 ans</SelectItem>
                        <SelectItem value="Experienced5To9Years">5 - 9 ans</SelectItem>
                        <SelectItem value="Senior10YearsOrMore">10 ans+</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Télétravail</label>
                    <Select value={jobRemote} onValueChange={setJobRemote}>
                      <SelectTrigger className="h-10 bg-background">
                        <SelectValue placeholder="Indifférent" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Indifférent</SelectItem>
                        <SelectItem value="remote">Télétravail</SelectItem>
                        <SelectItem value="onsite">Sur site</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Salaire min.</label>
                    <Input 
                      type="number" 
                      placeholder="Ex: 35000" 
                      className="h-10 bg-background"
                      value={jobSalary}
                      onChange={(e) => setJobSalary(e.target.value)}
                    />
                  </div>
                </div>
              )}

              {/* Distance */}
              <div>
                <label htmlFor="distance" className="block text-sm font-medium text-foreground mb-2">
                  Distance : {distance} km
                </label>
                <input
                  type="range"
                  id="distance"
                  min="5"
                  max="200"
                  step="5"
                  value={distance}
                  onChange={(e) => setDistance(Number(e.target.value))}
                  className="w-full h-2 bg-muted rounded-lg appearance-none cursor-pointer accent-primary"
                />
                <div className="flex justify-between text-xs text-muted-foreground mt-1">
                  <span>5 km</span>
                  <span>50 km</span>
                  <span>100 km</span>
                  <span>150 km</span>
                  <span>200 km</span>
                </div>
              </div>

              {/* Boutons d'action */}
              <div className="flex gap-3">
                <Button 
                  className="flex-1 h-12" 
                  size="lg"
                  onClick={handleSearch}
                >
                  <Search className="mr-2 h-5 w-5" />
                  Rechercher
                </Button>
                <Button 
                  variant="outline" 
                  className="h-12 bg-transparent" 
                  size="lg"
                  onClick={handleSaveSearch}
                  disabled={!searchTerm.trim() && !location.trim()}
                >
                  <Bookmark className="mr-2 h-5 w-5" />
                  Sauvegarder
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}