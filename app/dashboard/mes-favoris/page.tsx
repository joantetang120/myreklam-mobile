"use client"

import type React from "react"
import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { useAuthStore } from "@/lib/auth-store"
import { fetchUserFavorites, toggleFavorite, fetchDealImages } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Loader2, Eye, Calendar, MapPin, Package, Grid3x3, List, Heart, Share2, Tag, User, Briefcase, Clock, MessageCircle, FileText, GraduationCap, Euro, Wifi, Home, Users, Locate, Edit, Trash2 } from "lucide-react"
import { toast } from "sonner"
import Image from "next/image"
import { config } from "@/lib/config"
import { cn } from "@/lib/utils"
import { labelObject } from "@/lib/constants/label-object"

interface Announcement {
  id: string
  title: string
  category: string
  subcategory?: string
  createdat: string
  endDate?: string
  address?: string
  images: string[]
  views?: number
  isFavorite?: boolean
  [key: string]: any
}

const CATEGORY_LABELS: Record<string, string> = {
  bons_plans: "Bons Plans",
  emplois: "Offres d'Emploi",
  formations: "Formations",
  evenements: "Événements",
  demandes: "Demandes",
}

const API_URL = config.API_URL

// Helper functions
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

const formatAddressHelper = (address: any): string => {
  if (!address) return ""
  
  // Si c'est une chaîne, essayer de la parser comme JSON
  if (typeof address === "string") {
    // Si ça ressemble à du JSON, essayer de le parser
    if (address.trim().startsWith("{") || address.trim().startsWith("[")) {
      try {
        const parsed = JSON.parse(address)
        return formatAddressHelper(parsed)
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

const getImageUrl = (imagePath: string) => {
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

export default function MesFavorisPage() {
  const router = useRouter()
  const { userId, isAuthenticated } = useAuthStore()
  const [announcements, setAnnouncements] = useState<Announcement[]>([])
  const [filteredAnnouncements, setFilteredAnnouncements] = useState<Announcement[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState("")
  const [categoryFilter, setCategoryFilter] = useState<string>("bons_plans")
  const [sortBy, setSortBy] = useState<string>("recent")
  const [viewMode, setViewMode] = useState<"grid" | "list">("grid")

  // Détecter la catégorie depuis l'URL au chargement
  useEffect(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search)
      const category = params.get("category")
      if (category && CATEGORY_LABELS[category]) {
        setCategoryFilter(category)
      }
    }
  }, [])

  useEffect(() => {
    if (!isAuthenticated || !userId) {
      router.push("/")
      return
    }
    loadFavorites()
  }, [userId, isAuthenticated])

  useEffect(() => {
    filterAnnouncements()
  }, [searchQuery, categoryFilter, announcements, sortBy])

  const loadFavorites = async () => {
    if (!userId) return

    setLoading(true)
    try {
      const result = await fetchUserFavorites(userId)
      if (result.success) {
        const annonces = result.annonces || []
        
        // Charger les images pour chaque annonce
        const annoncesWithImages = await Promise.all(
          annonces.map(async (annonce: Announcement) => {
            let images: string[] = []
            
            // 1. Essayer de charger via API
            try {
              const imagesResult = await fetchDealImages(annonce.id)
              if (imagesResult.success && imagesResult.images && imagesResult.images.length > 0) {
                images = imagesResult.images
              }
            } catch (error) {
              console.error(`Erreur chargement images pour ${annonce.id}:`, error)
            }
            
            // 2. Fallback parsing JSON
            if (images.length === 0 && annonce.images) {
              let parsedImages = annonce.images
              if (typeof parsedImages === 'string') {
                try {
                  parsedImages = JSON.parse(parsedImages)
                } catch {
                  parsedImages = []
                }
              }
              if (Array.isArray(parsedImages) && parsedImages.length > 0) {
                images = parsedImages as string[]
              }
            }
            
            return { ...annonce, images }
          })
        )
        
        setAnnouncements(annoncesWithImages)
      } else {
        toast.error("Erreur lors du chargement des favoris")
      }
    } catch (error) {
      console.error("Error loading favorites:", error)
      toast.error("Erreur lors du chargement des favoris")
    } finally {
      setLoading(false)
    }
  }

  const filterAnnouncements = () => {
    let filtered = [...announcements]

    if (searchQuery) {
      filtered = filtered.filter((announcement) => announcement.title.toLowerCase().includes(searchQuery.toLowerCase()))
    }

    if (categoryFilter && categoryFilter !== "all") {
      filtered = filtered.filter((announcement) => announcement.category === categoryFilter)
    }

    if (sortBy === "recent") {
      filtered.sort((a, b) => new Date(b.createdat).getTime() - new Date(a.createdat).getTime())
    } else if (sortBy === "oldest") {
      filtered.sort((a, b) => new Date(a.createdat).getTime() - new Date(b.createdat).getTime())
    } else if (sortBy === "views") {
      filtered.sort((a, b) => (b.views || 0) - (a.views || 0))
    }

    setFilteredAnnouncements(filtered)
  }

  const handleUnfavorite = async (announcementId: string) => {
    if (!userId) return

    try {
      const result = await toggleFavorite(userId, announcementId, false)
      if (result.success) {
        toast.success("Annonce retirée des favoris")
        setAnnouncements((prev) => prev.filter((a) => a.id !== announcementId))
      } else {
        toast.error("Erreur lors de la suppression du favori")
      }
    } catch (error) {
      console.error("Error removing favorite:", error)
      toast.error("Erreur lors de la suppression du favori")
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-[400px] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-foreground">Mes Favoris</h1>
        <p className="text-muted-foreground mt-1">Accédez à vos annonces préférées</p>
      </div>

      {/* Filters */}
      <Card className="border-2">
        <CardContent className="p-4 sm:p-6">
          <div className="flex flex-col gap-4">
            {/* Top row: Sort and Search */}
            <div className="flex flex-col gap-4">
              <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 sm:gap-4 w-full">
                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 w-full sm:w-auto">
                  <span className="text-sm font-medium text-muted-foreground whitespace-nowrap">Trier par :</span>
                  <Select value={sortBy} onValueChange={setSortBy}>
                    <SelectTrigger className="w-full sm:w-[180px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="recent">Les plus récents</SelectItem>
                      <SelectItem value="oldest">Les plus anciens</SelectItem>
                      <SelectItem value="views">Les plus vus</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 flex-1 w-full">
                  <span className="text-sm font-medium text-muted-foreground whitespace-nowrap hidden sm:inline">Rechercher :</span>
                  <div className="relative flex-1 w-full">
                    <Input
                      placeholder="Rechercher une annonce"
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="w-full"
                    />
                  </div>
                </div>
              </div>

              {/* View Mode Toggle */}
              <div className="flex items-center justify-end gap-1 border-2 border-gray-200 rounded-lg p-1 bg-gray-50 w-full sm:w-auto">
                <button
                  onClick={() => setViewMode("grid")}
                  className={cn(
                    "p-2 rounded transition-all flex-1 sm:flex-none",
                    viewMode === "grid"
                      ? "bg-primary text-white shadow-sm"
                      : "text-gray-600 hover:bg-white hover:text-primary",
                  )}
                  title="Vue grille"
                >
                  <Grid3x3 className="w-4 h-4 mx-auto" />
                </button>
                <button
                  onClick={() => setViewMode("list")}
                  className={cn(
                    "p-2 rounded transition-all flex-1 sm:flex-none",
                    viewMode === "list"
                      ? "bg-primary text-white shadow-sm"
                      : "text-gray-600 hover:bg-white hover:text-primary",
                  )}
                  title="Vue liste"
                >
                  <List className="w-4 h-4 mx-auto" />
                </button>
              </div>
            </div>

            {/* Category tabs */}
            <div className="flex items-center gap-2 flex-wrap">
              {Object.entries(CATEGORY_LABELS).map(([key, label]) => (
                <Button
                  key={key}
                  variant={categoryFilter === key ? "default" : "outline"}
                  size="sm"
                  onClick={() => setCategoryFilter(key)}
                  className={cn(
                    "rounded-full transition-all",
                    categoryFilter === key
                      ? "bg-green-500 hover:bg-green-600 text-white"
                      : "bg-gray-100 hover:bg-gray-200 text-gray-700",
                  )}
                >
                  {label}
                </Button>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Favorites List */}
      {filteredAnnouncements.length === 0 ? (
        <Card className="border-2 border-dashed">
          <CardContent className="p-12">
            <div className="text-center">
              <Heart className="h-16 w-16 mx-auto mb-4 text-muted-foreground opacity-50" />
              <h3 className="text-xl font-semibold mb-2">Aucun favori trouvé</h3>
              <p className="text-muted-foreground mb-6">
                {searchQuery
                  ? "Essayez de modifier vos filtres de recherche"
                  : "Commencez par ajouter des annonces à vos favoris"}
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div
          className={cn(
            viewMode === "grid"
              ? "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6"
              : "flex flex-col gap-4",
          )}
        >
          {filteredAnnouncements.map((announcement) => {
            const handleUnfavoriteClick = () => handleUnfavorite(announcement.id)
            
            // Rendre la card spécifique selon la catégorie
            switch (announcement.category) {
              case "bons_plans":
                return <DealCardWithFavorite key={announcement.id} item={announcement} onUnfavorite={handleUnfavoriteClick} />
              case "emplois":
              case "offres_emploi":
                return <JobCardWithFavorite key={announcement.id} item={announcement} onUnfavorite={handleUnfavoriteClick} />
              case "formations":
                return <TrainingCardWithFavorite key={announcement.id} item={announcement} onUnfavorite={handleUnfavoriteClick} />
              case "evenements":
                return <EventCardWithFavorite key={announcement.id} item={announcement} onUnfavorite={handleUnfavoriteClick} />
              case "demandes":
                return <InquiryCardWithFavorite key={announcement.id} item={announcement} onUnfavorite={handleUnfavoriteClick} />
              default:
                return <DealCardWithFavorite key={announcement.id} item={announcement} onUnfavorite={handleUnfavoriteClick} />
            }
          })}
        </div>
      )}
    </div>
  )
}

// Card pour les bons plans avec bouton Retirer des favoris (design EXACT de /bons-plans)
function DealCardWithFavorite({ item, onUnfavorite }: { item: any; onUnfavorite: () => void }) {
  const [imageError, setImageError] = useState(false)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  
  const calculateDiscount = () => {
    if (item.initialPrice && item.finalPrice) {
      const initial = parseFloat(item.initialPrice)
      const final = parseFloat(item.finalPrice)
      if (initial > final) {
        return Math.round(((initial - final) / initial) * 100)
      }
    }
    if (item.discountValue) {
      return Math.round(parseFloat(item.discountValue))
    }
    return 0
  }

  const discountPercentage = calculateDiscount()

  const getUserDisplayName = () => {
    const companyData = item.companyData
    if (!companyData) return "Utilisateur"
    if (companyData.profiletype === "professionnel") {
      return companyData.nomsociete || "Entreprise"
    }
    return companyData.pseudo || "Particulier"
  }

  const getUserPhoto = () => {
    const companyData = item.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    return companyData.photoprofilurl
  }

  const isProfessional = item.companyData?.profiletype === "professionnel"

  const getFinalPrice = () => {
    if (item.finalPrice !== undefined && item.finalPrice !== null) {
      const price = parseFloat(item.finalPrice)
      return isNaN(price) ? null : price
    }
    return null
  }

  const getInitialPrice = () => {
    if (item.initialPrice !== undefined && item.initialPrice !== null) {
      const price = parseFloat(item.initialPrice)
      return isNaN(price) ? null : price
    }
    return null
  }

  const finalPrice = getFinalPrice()
  const initialPrice = getInitialPrice()

  const getFormattedAddress = () => {
    if (!item.address) return ""
    try {
      const addressData = typeof item.address === "string" ? JSON.parse(item.address) : item.address
      const parts = []
      if (addressData.line1) parts.push(addressData.line1)
      if (addressData.city) parts.push(addressData.city)
      else if (addressData.ville) parts.push(addressData.ville)
      if (addressData.zipcode) parts.push(addressData.zipcode)
      else if (addressData.codepostal) parts.push(addressData.codepostal)
      return parts.filter(Boolean).join(", ")
    } catch (error) {
      return item.address.toString()
    }
  }

  const getBrandArray = () => {
    if (!item.brand) return []
    try {
      if (Array.isArray(item.brand)) {
        return item.brand.filter((b: string) => b && b.trim())
      }
      if (typeof item.brand === 'string') {
        const cleanBrand = item.brand.trim()
        if (cleanBrand.startsWith('[')) {
          const parsed = JSON.parse(cleanBrand)
          return Array.isArray(parsed) ? parsed.filter((b: string) => b && b.trim()) : []
        }
        if (cleanBrand.startsWith('{')) {
          const matches = cleanBrand.match(/"([^"]+)"/g)
          if (matches) {
            return matches.map((match: string) => match.replace(/"/g, '').trim()).filter((b: string) => b)
          }
        }
        return [cleanBrand]
      }
      return []
    } catch (error) {
      if (typeof item.brand === 'string') {
        const matches = item.brand.match(/"([^"]+)"/g)
        if (matches) {
          return matches.map((match: string) => match.replace(/"/g, '').trim()).filter((b: string) => b)
        }
        const cleaned = item.brand.replace(/[\[\]{}"]/g, '').trim()
        return cleaned ? [cleaned] : []
      }
      return []
    }
  }

  const brandArray = getBrandArray()

  return (
    <Card
      className={cn(
        "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group border-2",
        isExpired ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300" : "hover:border-green-200 border-gray-200"
      )}
    >
      <div className="relative h-56 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
        {item.images && item.images.length > 0 && item.images[0] && !imageError ? (
          <img
            src={getImageUrl(item.images[0])}
            alt={item.title}
            className={cn(
              "w-full h-full object-cover group-hover:scale-110 transition-transform duration-500",
              isExpired && "grayscale brightness-90"
            )}
            onError={() => setImageError(true)}
          />
        ) : (
          <div className={cn("w-full h-full flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-50", isExpired && "grayscale brightness-90")}>
            <Tag className={cn("w-20 h-20 text-green-300", isExpired && "opacity-50")} />
          </div>
        )}

        <div className="absolute top-3 left-3">
          <Badge className={cn("backdrop-blur-sm shadow-md border-0 px-3 py-1 flex items-center gap-1", isExpired ? "bg-gray-200/95 text-gray-600" : "bg-white/95 text-gray-700")}>
            <Tag className="w-3 h-3" />
            {labelObject[item.dealCategory as keyof typeof labelObject] || item.dealCategory}
          </Badge>
        </div>

        {isExpired ? (
          <div className="absolute top-3 right-3">
            <Badge className="bg-red-500 text-white shadow-xl text-lg font-bold px-5 py-3 border-2 border-white animate-pulse">
              <div className="flex flex-col items-center gap-0.5">
                <div className="flex items-center gap-1">
                  <Clock className="w-5 h-5" />
                  <span>EXPIRÉ</span>
                </div>
                {item.endDate && (
                  <span className="text-[10px] font-normal whitespace-nowrap">depuis le {new Date(item.endDate).toLocaleDateString("fr-FR")}</span>
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
      </div>

      <div className="p-5">
        <h3 className={cn("font-bold text-lg mb-2 line-clamp-2 min-h-[3.5rem] group-hover:text-green-600 transition-colors", isExpired && "text-gray-500")}>
          {item.title}
        </h3>

        <div className="flex items-center gap-2 text-xs text-gray-600 mb-3">
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
            {item.description.replace(/<[^>]*>/g, '').substring(0, 150)}...
          </p>
        )}

        <div className="flex items-center gap-2 text-xs text-gray-600 mb-3">
          <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 010 4 2 2 0 01-2 2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span className="line-clamp-1">
            {item.isOnline ? "En ligne" : "En magasin"}
            {brandArray.length > 0 && (
              <span>, disponible chez <span className="font-semibold text-gray-900">{brandArray.join(", ")}</span></span>
            )}
          </span>
        </div>

        {!item.isOnline && getFormattedAddress() && (
          <div className="flex items-center gap-1 text-xs text-gray-500 mb-3">
            <MapPin className="w-3 h-3" />
            <span className="truncate">{getFormattedAddress()}</span>
          </div>
        )}

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

        <div className="flex items-center justify-between pt-4 border-t">
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-1 text-gray-500">
              <MessageCircle className="w-4 h-4" />
              <span className="text-sm font-medium">0</span>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between mt-4 pt-4 border-t">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center overflow-hidden">
              {getUserPhoto() ? (
                <img src={getUserPhoto()!} alt={getUserDisplayName()} className="w-full h-full object-cover" />
              ) : (
                <User className="w-4 h-4 text-white" />
              )}
            </div>
            <div className="flex flex-col gap-0.5">
              <span className="text-sm font-medium text-gray-700 truncate max-w-[80px] sm:max-w-[100px]">{getUserDisplayName()}</span>
              <Badge variant="outline" className={cn("text-xs px-1.5 py-0 h-4 w-fit", isProfessional ? "bg-blue-50 text-blue-700 border-blue-200" : "bg-gray-50 text-gray-600 border-gray-200")}>
                {isProfessional ? "Pro" : "Particulier"}
              </Badge>
            </div>
          </div>
        </div>

        {item.views !== undefined && (
          <div className="flex items-center gap-2 text-sm text-gray-500 mt-4">
            <Eye className="w-4 h-4" />
            <span>{item.views} vues</span>
          </div>
        )}

        <div className="flex flex-col gap-2 pt-4 border-t mt-4">
          <Button variant="outline" size="sm" className="w-full gap-2 text-red-600 hover:text-red-700 hover:bg-red-50" onClick={(e) => { e.stopPropagation(); onUnfavorite(); }}>
            <Heart className="h-4 w-4 fill-red-500" />
            Retirer des favoris
          </Button>
          {item.createdat && (
            <span className="text-xs text-gray-500 text-center">{getTimeAgo(item.createdat)}</span>
          )}
        </div>
      </div>
    </Card>
  )
}

// Card pour les offres d'emploi avec bouton Retirer des favoris (design EXACT de /offres-emploi)
function JobCardWithFavorite({ item, onUnfavorite }: { item: any; onUnfavorite: () => void }) {
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  
  const getUserPhoto = () => {
    const companyData = item.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    return companyData.photoprofilurl
  }

  const getUserDisplayName = () => {
    if (item.business) {
      try {
        if (typeof item.business === 'string') {
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

  const getCleanDescription = () => {
    if (!item.description) return ""
    const cleanText = item.description.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  const getFormattedLocation = () => {
    if (!item.location && !item.address) return ""
    const locationData = item.location || item.address
    if (typeof locationData === 'string') {
      try {
        const parsed = JSON.parse(locationData)
        return formatAddressHelper(parsed)
      } catch {
        return locationData
      }
    }
    return formatAddressHelper(locationData)
  }

  const getOccupationTimeLabel = () => {
    if (item.occupationTime === "fullTime") return "Temps plein"
    if (item.occupationTime === "partTime") return "Temps partiel"
    return null
  }

  const getSalaryDisplay = () => {
    if (item.issalarybasedonprofile) return "Selon profil"
    if (!item.minSalary && !item.maxSalary && !item.salary) return null
    const salaryType = item.netSalary === "raw" ? "brut" : item.netSalary === "net" ? "net" : ""
    let period = ""
    if (item.unitSalary === "years") period = " /an"
    else if (item.unitSalary === "month") period = " /mois"
    else if (item.unitSalary === "day" || item.unitSalary === "days") period = " /jour"
    else if (item.unitSalary === "hour" || item.unitSalary === "hours") period = " /heure"
    const isSalaryExact = item.salaryExact === true || item.salaryExact === "true"
    if (isSalaryExact && item.maxSalary) {
      const max = parseFloat(item.maxSalary)
      if (max === 0) return null
      return `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }
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
    if (item.salary) return item.salary
    return null
  }

  const getSkills = () => {
    if (!item.skills) return []
    try {
      if (typeof item.skills === 'string') {
        if (item.skills.startsWith('[') || item.skills.startsWith('{')) {
          return JSON.parse(item.skills)
        }
        return item.skills.split(',').map((s: string) => s.trim()).filter(Boolean)
      }
      if (Array.isArray(item.skills)) {
        return item.skills
      }
      return []
    } catch (error) {
      return []
    }
  }

  const getBenefits = () => {
    if (!item.benefit && !item.benefits) return []
    const benefitData = item.benefit || item.benefits
    try {
      let rawBenefits = []
      if (typeof benefitData === 'string') {
        if (benefitData.startsWith('[')) {
          rawBenefits = JSON.parse(benefitData)
        }
        else if (benefitData.startsWith('{')) {
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
      return rawBenefits.map((benefit: string) => (labelObject as any)[benefit] || benefit)
    } catch (error) {
      return []
    }
  }

  const skills = getSkills()
  const benefits = getBenefits()

  return (
    <Card
      className={cn(
        "h-full hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 overflow-hidden group border-2",
        isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-blue-200"
      )}
    >
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
        </div>

        <h3 className={cn("font-bold text-xl mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors", isExpired ? "text-gray-500" : "text-gray-900")}>
          {item.title}
        </h3>
        <div className="flex items-center gap-2">
          <p className="text-sm text-gray-700 font-semibold">{getUserDisplayName()}</p>
          {isProfessional && (
            <Badge className="bg-blue-50 text-blue-700 border-blue-200 text-xs">Pro</Badge>
          )}
        </div>
      </div>

      <div className="p-6 flex-1 flex flex-col">
        <div className="flex flex-wrap items-center gap-2 mb-4">
          {item.contractType && (
            <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
              <FileText className="w-3 h-3 mr-1 inline" />
              {(labelObject as any)[item.contractType] || item.contractType}
            </Badge>
          )}
          {getFormattedLocation() && (
            <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
              <MapPin className="w-3 h-3 mr-1 inline" />
              {getFormattedLocation()}
            </Badge>
          )}
          {item.studyLevel && (
            <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
              <GraduationCap className="w-3 h-3 mr-1 inline" />
              {(labelObject as any)[item.studyLevel] || item.studyLevel}
            </Badge>
          )}
          {item.xpLevel && (
            <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
              <Briefcase className="w-3 h-3 mr-1 inline" />
              {(labelObject as any)[item.xpLevel] || item.xpLevel}
            </Badge>
          )}
          {getOccupationTimeLabel() && (
            <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
              <Clock className="w-3 h-3 mr-1 inline" />
              {getOccupationTimeLabel()}
            </Badge>
          )}
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
          {getSalaryDisplay() && (
            <Badge className="bg-green-50 text-green-700 border-green-200 text-xs">
              <Euro className="w-3 h-3 mr-1 inline" />
              {getSalaryDisplay()}
            </Badge>
          )}
        </div>

        <p className="text-sm text-gray-700 mb-4 line-clamp-3 flex-1 leading-relaxed">{getCleanDescription()}</p>

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

        {item.views !== undefined && (
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
            <Eye className="w-4 h-4" />
            <span>{item.views} vues</span>
          </div>
        )}

        <div className="flex flex-col gap-2 pt-4 border-t mt-auto">
          <Button variant="outline" size="sm" className="w-full gap-2 text-red-600 hover:text-red-700 hover:bg-red-50" onClick={(e) => { e.stopPropagation(); onUnfavorite(); }}>
            <Heart className="h-4 w-4 fill-red-500" />
            Retirer des favoris
          </Button>
          {item.createdat && (
            <span className="text-xs text-gray-500 text-center">{getTimeAgo(item.createdat)}</span>
          )}
        </div>
      </div>
    </Card>
  )
}

// Card pour les formations avec bouton Retirer des favoris (design EXACT de /formations)
function TrainingCardWithFavorite({ item, onUnfavorite }: { item: any; onUnfavorite: () => void }) {
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  
  const getOrganizationName = () => {
    return item.companyData?.nomsociete || item.userNomsociete || item.userPseudo || "Centre de formation"
  }

  const getCleanDescription = () => {
    if (!item.description) return ""
    const cleanText = item.description.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

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

  const getFormattedDuration = () => {
    if (!item.durationInH) return null
    const hours = parseFloat(item.durationInH)
    if (isNaN(hours) || hours === 0) return null
    return `${hours}h`
  }

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

  const getOrganizerPhoto = () => {
    const companyData = item.companyData
    if (!companyData || !companyData.photoprofilurl) return null
    if (companyData.photoprofilurl.startsWith("http")) {
      return companyData.photoprofilurl
    }
    return `${API_URL}${companyData.photoprofilurl}`
  }

  const isProfessional = item.companyData?.profiletype === "professionnel"

  const getFormattedLocation = () => {
    if (item.address) {
      return formatAddressHelper(item.address)
    }
    if (item.location) {
      return formatAddressHelper(item.location)
    }
    return null
  }

  const organizationName = getOrganizationName()
  const trainingTypeLabel = getTrainingType()

  return (
    <Card
      className={`h-full hover:shadow-xl transition-all duration-300 overflow-hidden group cursor-pointer ${
        isExpired ? "opacity-75 border-2 border-red-500" : ""
      }`}
    >
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
          </div>
        </div>

        <div className="flex items-center gap-2 mb-2">
          <span className="text-sm font-semibold text-gray-900">{organizationName}</span>
          <Badge variant="outline" className={`text-xs ${isProfessional ? 'bg-blue-50 text-blue-700 border-blue-200' : 'bg-gray-50 text-gray-700 border-gray-200'}`}>
            {isProfessional ? 'Pro' : 'Particulier'}
          </Badge>
        </div>

        <h3
          className={`text-lg font-bold mb-3 line-clamp-2 group-hover:text-purple-600 transition-colors ${
            isExpired ? "text-gray-500" : "text-gray-900"
          }`}
        >
          {item.title}
        </h3>

        <p className="text-sm text-gray-600 line-clamp-2 mb-4 min-h-[2.5rem] leading-relaxed">{getCleanDescription()}</p>

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

        {trainingTypeLabel && (
          <div className="mb-4">
            <Badge variant="outline" className="text-xs bg-purple-50 text-purple-700 border-purple-200 truncate max-w-full">
              <span className="truncate">{trainingTypeLabel}</span>
            </Badge>
          </div>
        )}

        {item.views !== undefined && (
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
            <Eye className="w-4 h-4" />
            <span>{item.views} vues</span>
          </div>
        )}
      </div>

      <div className="px-4 pb-4 pt-2 border-t">
        <div className="flex flex-col gap-2">
          <Button variant="outline" size="sm" className="w-full gap-2 text-red-600 hover:text-red-700 hover:bg-red-50" onClick={(e) => { e.stopPropagation(); onUnfavorite(); }}>
            <Heart className="h-4 w-4 fill-red-500" />
            Retirer des favoris
          </Button>
          {item.createdat && (
            <p className="text-xs text-gray-500 text-center">{getTimeAgo(item.createdat)}</p>
          )}
        </div>
      </div>
    </Card>
  )
}

// Card pour les événements avec bouton Retirer des favoris (design EXACT de /evenements)
function EventCardWithFavorite({ item, onUnfavorite }: { item: any; onUnfavorite: () => void }) {
  const [imageError, setImageError] = useState(false)
  
  const isExpired = (item.eventDurationType === "permanent" || item.isAllDays) 
    ? false 
    : (item.endDate ? new Date(item.endDate) < new Date() : false)

  const getEventStatus = () => {
    if (isExpired) return { label: "Passé", color: "bg-gray-500" }
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

  const formatEventDate = () => {
    if (item.eventDurationType === "permanent" || item.isAllDays) {
      return "Permanent"
    }
    const eventDate = item.eventDate || item.startDate
    if (!eventDate) return "Date à définir"
    const date = new Date(eventDate)
    return date.toLocaleDateString("fr-FR", { day: "numeric", month: "long", year: "numeric" })
  }

  const getFormattedLocation = () => {
    if (item.eventCity) return item.eventCity
    if (item.eventLocation) {
      if (typeof item.eventLocation === 'string') {
        return item.eventLocation
      }
      return formatAddressHelper(item.eventLocation)
    }
    if (item.address) {
      return formatAddressHelper(item.address)
    }
    return null
  }

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

  const getFormattedPrice = () => {
    const price = item.eventPrice || item.price
    if (!price) return "Gratuit"
    const numPrice = Number.parseFloat(price)
    return numPrice === 0 ? "Gratuit" : `${numPrice}€`
  }

  const getDisplayCategory = () => {
    const eventType = item.eventType || item.eventCategory || item.category
    return (labelObject as any)[eventType] || eventType
  }

  const getDisplaySubCategory = () => {
    if (!item.subCategory) return null
    return (labelObject as any)[item.subCategory] || item.subCategory
  }

  const imageUrl = item.images && item.images[0] ? getImageUrl(item.images[0]) : null

  return (
    <Card
      className={`flex flex-col h-full min-h-[400px] hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-visible group cursor-pointer border-0 bg-white/90 backdrop-blur-md ${
        isExpired ? "opacity-60 grayscale" : "hover:shadow-orange-200/60"
      }`}
    >
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
          <div className={`w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-100 to-orange-50 ${
              isExpired ? "grayscale brightness-75" : ""
            }`}>
            <Calendar className="w-16 h-16 text-orange-300" />
          </div>
        )}

        {getDisplayCategory() && (
          <div className="absolute top-3 left-3 z-10">
            <Badge className="bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-xl backdrop-blur-sm border border-white/20">{getDisplayCategory()}</Badge>
          </div>
        )}

        <div className="absolute top-3 right-3 z-10">
          <Badge className={`text-white shadow-xl backdrop-blur-sm border border-white/20 ${status.color}`}>
            {status.label}
          </Badge>
        </div>
      </div>

      <div className="p-4 flex-1 flex flex-col">
        <h3 className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-orange-600 transition-colors ${
            isExpired ? "text-gray-500" : "text-gray-900"
          }`}>
          {item.title}
        </h3>

        <div className="flex items-center gap-2 mb-3">
          {getOrganizerPhoto() ? (
            <img src={getOrganizerPhoto()!} alt={getOrganizerName()} className="w-5 h-5 rounded-full object-cover" />
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

        {item.views !== undefined && (
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
            <Eye className="w-4 h-4" />
            <span>{item.views} vues</span>
          </div>
        )}

        <div className={`text-2xl font-bold mb-4 mt-auto ${isExpired ? "text-gray-400 line-through" : "text-orange-600"}`}>
          {getFormattedPrice()}
        </div>

        <div className="flex flex-col gap-2">
          <Button variant="outline" size="sm" className="w-full gap-2 text-red-600 hover:text-red-700 hover:bg-red-50" onClick={(e) => { e.stopPropagation(); onUnfavorite(); }}>
            <Heart className="h-4 w-4 fill-red-500" />
            Retirer des favoris
          </Button>
          {item.createdat && (
            <p className="text-sm text-gray-500 text-center">Publié {getTimeAgo(item.createdat)}</p>
          )}
        </div>
      </div>
    </Card>
  )
}

// Card pour les demandes avec bouton Retirer des favoris (design EXACT de /demandes)
function InquiryCardWithFavorite({ item, onUnfavorite }: { item: any; onUnfavorite: () => void }) {
  const [imageError, setImageError] = useState(false)

  const getUserDisplayName = (inquiry: any): string => {
    if (inquiry.userInfo) {
      const userInfo = inquiry.userInfo
      if (userInfo.profiletype === "professionnel") {
        return userInfo.nomsociete || "Entreprise"
      }
      return userInfo.pseudo || "Utilisateur"
    }
    if (inquiry.companyData) {
      const companyData = inquiry.companyData
      if (companyData.profiletype === "professionnel") {
        return companyData.nomsociete || "Entreprise"
      }
      return companyData.pseudo || "Utilisateur"
    }
    return "Utilisateur"
  }

  const getUserPhoto = (inquiry: any): string | null => {
    if (inquiry.userInfo?.photoprofilurl) {
      return inquiry.userInfo.photoprofilurl.startsWith("http") 
        ? inquiry.userInfo.photoprofilurl 
        : `${API_URL}${inquiry.userInfo.photoprofilurl}`
    }
    if (inquiry.companyData?.photoprofilurl) {
      return inquiry.companyData.photoprofilurl.startsWith("http")
        ? inquiry.companyData.photoprofilurl
        : `${API_URL}${inquiry.companyData.photoprofilurl}`
    }
    return null
  }

  const getInquiryCategory = (inquiry: any): string => {
    if (inquiry.inquiryType) {
      return (labelObject as any)[inquiry.inquiryType] || inquiry.inquiryType
    }
    return "Demande"
  }

  const getInquiryNature = (inquiry: any): string => {
    if (inquiry.inquiryTypeCategory) {
      return (labelObject as any)[inquiry.inquiryTypeCategory] || inquiry.inquiryTypeCategory
    }
    return ""
  }

  const userName = getUserDisplayName(item)
  const userAvatar = getUserPhoto(item)
  const timeAgo = item.createdat ? getTimeAgo(item.createdat) : ""
  const category = getInquiryCategory(item)
  const nature = getInquiryNature(item)
  const location = formatAddressHelper(item.address)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false
  const isProfessional = item.userInfo?.profiletype === "professionnel" || item.companyData?.profiletype === "professionnel"

  const displayTitle = item.inquiryTitle || item.title || "Demande sans titre"
  const displayDescription = item.inquiryDescription || item.description || "Aucune description disponible"

  const getCleanDescription = () => {
    if (!displayDescription) return ""
    const cleanText = displayDescription.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  const getSpecificInfo = () => {
    const info = []
    if (item.inquiryType === "JobSearchInternship") {
      if (item.inquiryTypeCategory) {
        info.push((labelObject as any)[item.inquiryTypeCategory] || item.inquiryTypeCategory)
      }
      if (item.inquiryContractType) {
        try {
          const contracts = typeof item.inquiryContractType === 'string' 
            ? JSON.parse(item.inquiryContractType.replace(/[{}]/g, '').split(',').map((s: string) => `"${s.trim()}"`).join(','))
            : item.inquiryContractType
          if (Array.isArray(contracts) && contracts.length > 0) {
            info.push((labelObject as any)[contracts[0]] || contracts[0])
          }
        } catch (e) {
          // Ignore
        }
      }
      if (item.telework) {
        info.push("Télétravail possible")
      }
    }
    if (item.inquiryType === "Training") {
      if (item.inquiryTrainingCategory) {
        info.push((labelObject as any)[item.inquiryTrainingCategory] || item.inquiryTrainingCategory)
      }
      if (item.inquiryTrainingType) {
        info.push((labelObject as any)[item.inquiryTrainingType] || item.inquiryTrainingType)
      }
    }
    return info
  }

  const specificInfo = getSpecificInfo()

  return (
    <Card
      className={`h-full hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group cursor-pointer border-0 bg-white/90 backdrop-blur-md ${
        isExpired ? "opacity-60 grayscale" : "hover:shadow-indigo-200/60"
      }`}
    >
      <div className="p-5 h-full flex flex-col">
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
                <p className="text-xs text-gray-600">{nature}</p>
              </div>
            </div>

            <div className="flex items-center gap-1.5 mt-2 flex-wrap">
              {isExpired && (
                <Badge className="bg-red-600 text-white border-2 border-white font-bold text-xs">EXPIRÉ</Badge>
              )}
            </div>
          </div>
        </div>

        <h3
          className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-indigo-600 transition-colors ${
            isExpired ? "text-gray-400" : "text-gray-900"
          }`}
        >
          {displayTitle}
        </h3>

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

        <p className="text-sm text-gray-600 mb-4 line-clamp-3 leading-relaxed">{getCleanDescription()}</p>

        {item.views !== undefined && (
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
            <Eye className="w-4 h-4" />
            <span>{item.views} vues</span>
          </div>
        )}

        <div className="space-y-3 mt-auto">
          <div className="flex flex-col gap-2">
            <Button variant="outline" size="sm" className="w-full gap-2 text-red-600 hover:text-red-700 hover:bg-red-50" onClick={(e) => { e.stopPropagation(); onUnfavorite(); }}>
              <Heart className="h-4 w-4 fill-red-500" />
              Retirer des favoris
            </Button>
            <span className="text-xs text-gray-500 text-center">{timeAgo}</span>
          </div>
        </div>
      </div>
    </Card>
  )
}
