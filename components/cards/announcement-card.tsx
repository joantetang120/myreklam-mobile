"use client"

import { useState } from "react"
import Link from "next/link"
import Image from "next/image"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Heart,
  Share2,
  MessageCircle,
  User,
  MapPin,
  Clock,
  Tag,
  Calendar,
  Briefcase,
  GraduationCap,
  MessageSquare,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { labelObject } from "@/lib/constants/label-object"
import { config } from "@/lib/config"

const API_URL = config.API_URL

interface AnnouncementCardProps {
  announcement: any
  category: "bons_plans" | "emplois" | "formations" | "evenements" | "demandes"
  detailPath: string
  onFavorite?: (id: string) => void
  onShare?: (id: string) => void
}

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

export function AnnouncementCard({ announcement, category, detailPath, onFavorite, onShare }: AnnouncementCardProps) {
  const [isFavorite, setIsFavorite] = useState(announcement.isFavorite || false)
  const [imageError, setImageError] = useState(false)

  const getImageUrl = (imagePath: string | undefined | null): string => {
    if (!imagePath) return ""

    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
      return imagePath
    }

    // S'assurer que le chemin commence par / pour un chemin absolu
    let cleanPath = imagePath
    if (!cleanPath.startsWith("/")) {
      cleanPath = "/" + cleanPath
    }

    // Remplacer /ads/ par /annonces/ si présent
    if (cleanPath.includes("/ads/")) {
      cleanPath = cleanPath.replace("/ads/", "/annonces/")
    }

    // Construire l'URL complète avec l'API_URL
    return `${API_URL}${cleanPath}`
  }

  const handleFavorite = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setIsFavorite(!isFavorite)
    if (onFavorite) {
      onFavorite(announcement.id)
    }
  }

  const handleShare = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (onShare) {
      onShare(announcement.id)
    }
  }

  const getCategoryIcon = () => {
    switch (category) {
      case "bons_plans":
        return Tag
      case "emplois":
        return Briefcase
      case "formations":
        return GraduationCap
      case "evenements":
        return Calendar
      case "demandes":
        return MessageSquare
      default:
        return Tag
    }
  }

  const CategoryIcon = getCategoryIcon()

  // Vérifier si expiré (pour bons plans et événements)
  const isExpired =
    announcement.endDate && new Date(announcement.endDate) < new Date()

  // Calcul de la réduction pour les bons plans
  const getDiscountPercentage = () => {
    if (category !== "bons_plans") return 0
    const finalPrice = parseFloat(announcement.finalPrice)
    const initialPrice = parseFloat(announcement.initialPrice)
    if (!isNaN(finalPrice) && !isNaN(initialPrice) && initialPrice > finalPrice) {
      return Math.round(((initialPrice - finalPrice) / initialPrice) * 100)
    }
    return 0
  }

  const discountPercentage = getDiscountPercentage()

  const getUserDisplayName = () => {
    const companyData = announcement.companyData
    if (!companyData) return "Utilisateur"

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

  const renderImagePlaceholder = () => (
    <div
      className={cn(
        "w-full h-full flex items-center justify-center bg-gradient-to-br from-primary/10 to-primary/5",
        isExpired && "grayscale brightness-90"
      )}
    >
      <CategoryIcon className={cn("w-16 h-16 text-primary/30", isExpired && "opacity-50")} />
    </div>
  )

  return (
    <Link href={`/announcements/${detailPath}/${announcement.id}`}>
      <Card
        className={cn(
          "h-full hover:shadow-2xl transition-all duration-300 overflow-hidden group cursor-pointer border-2",
          isExpired
            ? "opacity-70 border-red-200 bg-gray-50/50 hover:border-red-300"
            : "hover:border-primary border-gray-200"
        )}
      >
        {/* Image */}
        <div className="relative h-48 bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
          {announcement.images && announcement.images.length > 0 && announcement.images[0] && !imageError ? (
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
            renderImagePlaceholder()
          )}

          {/* Category badge */}
          <div className="absolute top-3 left-3">
            <Badge
              className={cn(
                "backdrop-blur-sm shadow-md border-0 px-3 py-1 flex items-center gap-1",
                isExpired ? "bg-gray-200/95 text-gray-600" : "bg-white/95 text-gray-700"
              )}
            >
              <CategoryIcon className="w-3 h-3" />
              {announcement.dealCategory
                ? labelObject[announcement.dealCategory as keyof typeof labelObject] || announcement.dealCategory
                : category === "bons_plans"
                ? "Bon plan"
                : category === "emplois"
                ? "Emploi"
                : category === "formations"
                ? "Formation"
                : category === "evenements"
                ? "Événement"
                : "Demande"}
            </Badge>
          </div>

          {/* Discount badge or Expired badge */}
          {isExpired ? (
            <div className="absolute top-3 right-3">
              <Badge className="bg-red-500 text-white shadow-xl text-sm font-bold px-3 py-2 border-2 border-white animate-pulse">
                <div className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  <span>EXPIRÉ</span>
                </div>
              </Badge>
            </div>
          ) : category === "bons_plans" && discountPercentage > 0 ? (
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
        <div className="p-4 space-y-3 flex-1 flex flex-col">
          <h3
            className={cn(
              "font-semibold line-clamp-2 group-hover:text-primary transition-colors min-h-[3rem]",
              isExpired && "text-gray-500"
            )}
          >
            {announcement.title}
          </h3>

          <p className="text-sm text-muted-foreground line-clamp-2 flex-1 leading-relaxed">
            {cleanDescription(announcement.description)}
          </p>

          {/* Location and time */}
          <div className="space-y-2 text-xs text-muted-foreground">
            {getLocationDisplay(announcement) && (
              <div className="flex items-start gap-2">
                <MapPin className="h-3 w-3 mt-0.5 flex-shrink-0" />
                <span className="line-clamp-1">{getLocationDisplay(announcement)}</span>
              </div>
            )}
            {announcement.createdat && (
              <div className="flex items-center gap-2">
                <Clock className="h-3 w-3 flex-shrink-0" />
                <span>{getTimeAgo(announcement.createdat)}</span>
              </div>
            )}
          </div>

          {/* CTA */}
          <div className="pt-3 border-t mt-auto">
            <Button size="sm" className="w-full bg-primary hover:bg-primary/90">
              Voir plus
            </Button>
          </div>
        </div>
      </Card>
    </Link>
  )
}
