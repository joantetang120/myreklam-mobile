"use client"

import type React from "react"
import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { useAuthStore } from "@/lib/auth-store"
import { fetchUserFavorites, toggleFavorite } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Loader2, Eye, Calendar, MapPin, Package, Grid3x3, List, Heart, Share2, Tag, User, Briefcase, Clock, MessageCircle, FileText, GraduationCap, Euro, Wifi, Home, Users, Locate } from "lucide-react"
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
}

const CATEGORY_LABELS: Record<string, string> = {
  bons_plans: "Bons Plans",
  emplois: "Offres d'Emploi",
  formations: "Formations",
  evenements: "Événements",
  demandes: "Demandes",
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
  const [viewMode, setViewMode] = useState<"grid" | "list">("list")

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
      console.log("[MesFavoris] API Response:", result)
      if (result.success) {
        const annonces = result.annonces || []
        console.log("[MesFavoris] Loaded announcements:", annonces)
        console.log("[MesFavoris] Categories found:", [...new Set(annonces.map((a: Announcement) => a.category))])
        setAnnouncements(annonces)
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
    console.log("[MesFavoris] Filtering - Total announcements:", filtered.length)
    console.log("[MesFavoris] Category filter:", categoryFilter)

    if (searchQuery) {
      filtered = filtered.filter((announcement) => announcement.title.toLowerCase().includes(searchQuery.toLowerCase()))
      console.log("[MesFavoris] After search filter:", filtered.length)
    }

    if (categoryFilter && categoryFilter !== "all") {
      console.log("[MesFavoris] Filtering by category:", categoryFilter)
      filtered = filtered.filter((announcement) => {
        console.log("[MesFavoris] Announcement category:", announcement.category, "Match:", announcement.category === categoryFilter)
        return announcement.category === categoryFilter
      })
      console.log("[MesFavoris] After category filter:", filtered.length)
    }

    if (sortBy === "recent") {
      filtered.sort((a, b) => new Date(b.createdat).getTime() - new Date(a.createdat).getTime())
    } else if (sortBy === "oldest") {
      filtered.sort((a, b) => new Date(a.createdat).getTime() - new Date(b.createdat).getTime())
    } else if (sortBy === "views") {
      filtered.sort((a, b) => (b.views || 0) - (a.views || 0))
    }

    console.log("[MesFavoris] Final filtered announcements:", filtered.length)
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

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString("fr-FR", {
      day: "numeric",
      month: "long",
      year: "numeric",
    })
  }

  const formatAddress = (address: string | undefined) => {
    if (!address) return "Non spécifié"
    try {
      const parsed = JSON.parse(address)
      return `${parsed.ville || ""}, ${parsed.pays || ""}`.trim()
    } catch {
      return address
    }
  }

  const isExpired = (announcement: Announcement) => {
    if (!announcement.endDate) return false
    return new Date(announcement.endDate) < new Date()
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
        <CardContent className="p-6">
          <div className="flex flex-col gap-4">
            {/* Top row: Sort and Search */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div className="flex items-center gap-4 flex-1 w-full">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-medium text-muted-foreground whitespace-nowrap">Trier par :</span>
                  <Select value={sortBy} onValueChange={setSortBy}>
                    <SelectTrigger className="w-[200px]">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="recent">Les plus récents</SelectItem>
                      <SelectItem value="oldest">Les plus anciens</SelectItem>
                      <SelectItem value="views">Les plus vus</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex items-center gap-2 flex-1">
                  <span className="text-sm font-medium text-muted-foreground whitespace-nowrap">Rechercher :</span>
                  <div className="relative flex-1 max-w-md">
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
              <div className="flex items-center gap-1 border-2 border-gray-200 rounded-lg p-1 bg-gray-50">
                <button
                  onClick={() => setViewMode("grid")}
                  className={cn(
                    "p-2 rounded transition-all",
                    viewMode === "grid"
                      ? "bg-primary text-white shadow-sm"
                      : "text-gray-600 hover:bg-white hover:text-primary",
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
                      ? "bg-primary text-white shadow-sm"
                      : "text-gray-600 hover:bg-white hover:text-primary",
                  )}
                  title="Vue liste"
                >
                  <List className="w-4 h-4" />
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
  if (typeof address === "string") {
    try {
      const parsed = JSON.parse(address)
      return formatAddressHelper(parsed)
    } catch {
      return address
    }
  }
  if (typeof address === "object") {
    const parts = []
    if (address.line1) parts.push(address.line1)
    if (address.city || address.ville) parts.push(address.city || address.ville)
    if (address.zipcode || address.codepostal) parts.push(address.zipcode || address.codepostal)
    return parts.filter(Boolean).join(", ")
  }
  return ""
}

const getImageUrl = (imagePath: string) => {
  if (!imagePath) return ''
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  let cleanPath = imagePath
  if (cleanPath.includes('/ads/')) {
    cleanPath = cleanPath.replace('/ads/', '/mediaannonce/')
  }
  if (cleanPath.startsWith('/')) {
    return `${config.API_URL}${cleanPath}`
  }
  return `${config.API_URL}/${cleanPath}`
}

// Card pour les bons plans avec bouton Retirer des favoris (design EXACT de /bons-plans)
function DealCardWithFavorite({ item, onUnfavorite }: { item: any; onUnfavorite: () => void }) {
  const [imageError, setImageError] = useState(false)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false

  if (viewMode === "list") {
    return (
      <Card
        onClick={handleCardClick}
        className={cn(
          "hover:shadow-xl transition-all duration-300 overflow-hidden group border-2 cursor-pointer",
          isExpired
            ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300"
            : "hover:border-primary/40 border-gray-200",
        )}
      >
        <CardContent className="p-6">
          <div className="flex flex-col md:flex-row gap-6">
            {showImage && (
              <div className="relative w-full md:w-48 h-48 rounded-xl overflow-hidden bg-muted flex-shrink-0">
                {announcement.images && announcement.images.length > 0 ? (
                  <Image
                    src={`${config.API_URL}${announcement.images[0]}`}
                    alt={announcement.title}
                    fill
                    className={cn("object-cover", isExpired && "grayscale brightness-75")}
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <Package className="h-12 w-12 text-muted-foreground opacity-50" />
                  </div>
                )}
                {isExpired && <div className="absolute inset-0 bg-black/40" />}
                {isExpired && (
                  <Badge className="absolute top-2 right-2 bg-red-500 text-white border-white border-2">EXPIRÉ</Badge>
                )}

                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    onUnfavorite(announcement.id)
                  }}
                  className="absolute top-2 left-2 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center hover:scale-110 transition-transform"
                >
                  <Heart className="w-5 h-5 fill-red-500 text-red-500" />
                </button>
              </div>
            )}

            <div className="flex-1 min-w-0">
              <div className="flex flex-col gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-2 flex-wrap">
                    <Badge className={cn(getCategoryColor(announcement.category), "text-white")}>
                      {getCategoryLabel(announcement.category)}
                    </Badge>
                    {announcement.subcategory && <Badge variant="outline">{announcement.subcategory}</Badge>}
                    {!showImage && isExpired && (
                      <Badge className="bg-red-500 text-white border-white border-2">EXPIRÉ</Badge>
                    )}
                  </div>
                  <h3
                    className={cn("text-xl font-bold mb-2 line-clamp-2", isExpired ? "text-gray-500" : "text-gray-900")}
                  >
                    {announcement.title}
                  </h3>
                  <p className="text-sm text-muted-foreground mb-3">
                    Hier à{" "}
                    {new Date(announcement.createdat).toLocaleTimeString("fr-FR", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </p>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                  {announcement.address && (
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <MapPin className="h-4 w-4 flex-shrink-0" />
                      <span className="truncate">{formatAddress(announcement.address)}</span>
                    </div>
                  )}

                  <div className="flex items-center gap-2 text-muted-foreground">
                    <Eye className="h-4 w-4 flex-shrink-0" />
                    <span>{announcement.views || 0}</span>
                  </div>

                  <div className="flex items-center gap-2 text-muted-foreground">
                    <Heart className="h-4 w-4 flex-shrink-0 fill-red-500 text-red-500" />
                    <span>0</span>
                  </div>
                </div>

                <div className="flex items-center gap-3 pt-4 border-t">
                  <Button
                    variant="outline"
                    size="default"
                    className="gap-2 text-red-600 hover:text-red-700 hover:bg-red-50 bg-white"
                    onClick={(e) => {
                      e.stopPropagation()
                      onUnfavorite(announcement.id)
                    }}
                  >
                    Supprimer
                  </Button>
                  {!showImage && (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-10 w-10 rounded-full hover:bg-gray-100 ml-auto"
                      onClick={handleShare}
                      title="Partager cette annonce"
                    >
                      <Share2 className="w-5 h-5 text-gray-400" />
                    </Button>
                  )}
                  {showImage && (
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-10 w-10 rounded-full hover:bg-gray-100 ml-auto"
                      onClick={handleShare}
                      title="Partager cette annonce"
                    >
                      <Share2 className="w-5 h-5 text-gray-400" />
                    </Button>
                  )}
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card
      onClick={handleCardClick}
      className={cn(
        "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group flex flex-col border-2 cursor-pointer",
        isExpired
          ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300"
          : "hover:border-primary/40 border-gray-200",
      )}
    >
      {showImage && (
        <div className="relative h-48 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
          {announcement.images && announcement.images.length > 0 ? (
            <Image
              src={`${config.API_URL}${announcement.images[0]}`}
              alt={announcement.title}
              fill
              className={cn(
                "object-cover group-hover:scale-110 transition-transform duration-500",
                isExpired && "grayscale brightness-90",
              )}
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <Package className="h-16 w-16 text-muted-foreground opacity-30" />
            </div>
          )}

          <div className="absolute top-3 left-3">
            <Badge className={cn(getCategoryColor(announcement.category), "text-white shadow-md")}>
              {getCategoryLabel(announcement.category)}
            </Badge>
          </div>

          {isExpired && (
            <div className="absolute top-3 right-3">
              <Badge className="bg-red-500 text-white shadow-xl text-base font-bold px-4 py-2 border-2 border-white">
                EXPIRÉ
              </Badge>
            </div>
          )}

          {isExpired && <div className="absolute inset-0 bg-black/10" />}

          <button
            onClick={(e) => {
              e.stopPropagation()
              onUnfavorite(announcement.id)
            }}
            className="absolute bottom-3 right-3 w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center hover:scale-110 transition-transform"
          >
            <Heart className="w-5 h-5 fill-red-500 text-red-500" />
          </button>
        </div>
      )}

      <div className="p-5 flex-1 flex flex-col">
        {!showImage && (
          <div className="flex items-center justify-between mb-3">
            <Badge className={cn(getCategoryColor(announcement.category), "text-white shadow-md")}>
              {getCategoryLabel(announcement.category)}
            </Badge>
            {isExpired && (
              <Badge className="bg-red-500 text-white shadow-xl text-sm font-bold px-3 py-1 border-2 border-white">
                EXPIRÉ
              </Badge>
            )}
          </div>
        )}

        <h3
          className={cn(
            "font-bold text-lg mb-3 line-clamp-2 min-h-[3.5rem]",
            isExpired ? "text-gray-500" : "text-gray-900",
          )}
        >
          {announcement.title}
        </h3>

        <div className="flex items-center gap-2 text-xs text-gray-500 mb-2">
          <Calendar className="w-3.5 h-3.5" />
          <span>
            Hier à{" "}
            {new Date(announcement.createdat).toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" })}
          </span>
        </div>

        {announcement.address && (
          <div className="flex items-center gap-2 text-xs text-gray-500 mb-3">
            <MapPin className="w-3.5 h-3.5 flex-shrink-0" />
            <span className="truncate">{formatAddress(announcement.address)}</span>
          </div>
        )}

        <div className="flex items-center gap-4 text-sm text-muted-foreground mb-4">
          <div className="flex items-center gap-1">
            <Eye className="w-4 h-4" />
            <span>{announcement.views || 0}</span>
          </div>
          <div className="flex items-center gap-1">
            <Heart className="w-4 h-4 fill-red-500 text-red-500" />
            <span>0</span>
          </div>
        </div>

        <div className="flex flex-col gap-2 pt-4 border-t mt-auto">
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              className="flex-1 gap-2 text-red-600 hover:text-red-700 hover:bg-red-50 bg-white"
              onClick={(e) => {
                e.stopPropagation()
                onUnfavorite(announcement.id)
              }}
            >
              Supprimer
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-9 w-9 rounded-full hover:bg-gray-100"
              onClick={handleShare}
              title="Partager cette annonce"
            >
              <Share2 className="w-4 h-4 text-gray-400" />
            </Button>
          </div>
        </div>

        {announcement.endDate && (
          <div
            className={cn(
              "text-xs mt-2 pt-2 border-t text-center",
              isExpired ? "text-red-600 font-medium" : "text-muted-foreground",
            )}
          >
            {isExpired ? "Expirée" : "Expire"} le {formatDate(announcement.endDate)}
          </div>
        )}
      </div>
    </Card>
  )
}
