"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Heart,
  Share2,
  Edit,
  Trash2,
  Briefcase,
  User,
  MapPin,
  Clock,
  Calendar,
  FileText,
  Wifi,
  Home,
  Euro,
  Building2,
  GraduationCap,
  Users,
  Locate,
  MessageCircle,
  Eye,
} from "lucide-react"
import { config } from "@/lib/config"
import { cn } from "@/lib/utils"
import { labelObject } from "@/lib/constants/label-object"

const API_URL = config.API_URL

interface AnnouncementCardProps {
  item: any
  category: string
  onEdit: () => void
  onDelete: () => void
  viewMode?: "grid" | "list"
}

// Fonction pour formater l'adresse
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

// Fonction pour obtenir le temps écoulé
function getTimeAgo(date: string): string {
  const now = new Date()
  const past = new Date(date)
  const diffInMs = now.getTime() - past.getTime()
  const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
  const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
  const diffInMonths = Math.floor(diffInDays / 30)
  if (diffInMinutes < 60) return `Il y a ${diffInMinutes} min`
  if (diffInHours < 24) return `Il y a ${diffInHours}h`
  if (diffInDays < 30) return `Il y a ${diffInDays} jour${diffInDays > 1 ? "s" : ""}`
  return `Il y a ${diffInMonths} mois`
}

// Fonction helper pour obtenir les labels
const getLabel = (key: string): string => {
  return (labelObject as any)[key] || key
}

export function DealCardWithActions({ item, onEdit, onDelete }: AnnouncementCardProps) {
  const [imageError, setImageError] = useState(false)
  const isExpired = item.endDate ? new Date(item.endDate) < new Date() : false

  const getCleanDescription = () => {
    if (!item.description) return ""
    const cleanText = item.description.replace(/<[^>]*>/g, ' ')
    const normalized = cleanText.replace(/\s+/g, ' ').trim()
    return normalized
  }

  const getImageUrl = (imagePath: string) => {
    if (!imagePath) return ""
    
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imagePath.startsWith("http://") || imagePath.startsWith("https://")) {
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

  const getDealCategory = () => {
    if (!item.dealCategory) return null
    return labelObject[item.dealCategory as keyof typeof labelObject] || item.dealCategory
  }

  const getDealType = () => {
    if (!item.dealType) return null
    return labelObject[item.dealType as keyof typeof labelObject] || item.dealType
  }

  return (
    <Card className={cn("h-full hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group border-0 bg-white/90 backdrop-blur-md", isExpired ? "opacity-60 grayscale" : "hover:shadow-blue-200/60")}>
      <div className="relative h-56 overflow-hidden bg-gradient-to-br from-blue-50 to-blue-100">
        {item.images && item.images.length > 0 && item.images[0] && !imageError ? (
          <Image
            src={getImageUrl(item.images[0])}
            alt={item.title}
            fill
            className="object-cover group-hover:scale-110 transition-transform duration-500"
            onError={() => setImageError(true)}
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <Calendar className="w-20 h-20 text-blue-300" />
          </div>
        )}
        
        {getDealCategory() && (
          <div className="absolute top-3 left-3">
            <Badge className="bg-gradient-to-r from-blue-500 to-blue-600 text-white border-0 shadow-lg text-sm px-3 py-1">
              {getDealCategory()}
            </Badge>
          </div>
        )}

        {isExpired && (
          <div className="absolute top-3 right-3">
            <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
          </div>
        )}
      </div>

      <div className="p-5">
        <h3 className={cn("text-xl font-bold mb-3 line-clamp-2 group-hover:text-blue-600 transition-colors", isExpired ? "text-gray-400" : "text-gray-900")}>
          {item.title}
        </h3>

        <p className="text-sm text-gray-600 mb-4 line-clamp-2 leading-relaxed">{getCleanDescription()}</p>

        {item.address && (
          <div className="flex items-center gap-2 text-sm text-gray-600 mb-4">
            <MapPin className="w-4 h-4 text-blue-500" />
            <span className="truncate">{formatAddress(item.address)}</span>
          </div>
        )}

        {item.views !== undefined && (
          <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
            <Eye className="w-4 h-4" />
            <span>{item.views} vues</span>
          </div>
        )}

        <div className="flex flex-col gap-2 pt-4 border-t">
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              className="flex-1 gap-2"
              onClick={(e) => {
                e.stopPropagation()
                onEdit()
              }}
              disabled={isExpired}
            >
              <Edit className="h-4 w-4" />
              Modifier
            </Button>
            <Button
              variant="outline"
              size="sm"
              className="flex-1 gap-2 text-red-600 hover:text-red-700 hover:bg-red-50"
              onClick={(e) => {
                e.stopPropagation()
                onDelete()
              }}
            >
              <Trash2 className="h-4 w-4" />
              Supprimer
            </Button>
          </div>
          <span className="text-xs text-gray-500 text-center">{getTimeAgo(item.createdat)}</span>
        </div>
      </div>
    </Card>
  )
}

// Ajoutez les autres composants (JobCardWithActions, TrainingCardWithActions, EventCardWithActions, InquiryCardWithActions) ici
// Pour l'instant, je vais créer un placeholder pour tester
export function JobCardWithActions({ item, onEdit, onDelete }: AnnouncementCardProps) {
  return <DealCardWithActions item={item} category="emplois" onEdit={onEdit} onDelete={onDelete} />
}

export function TrainingCardWithActions({ item, onEdit, onDelete }: AnnouncementCardProps) {
  return <DealCardWithActions item={item} category="formations" onEdit={onEdit} onDelete={onDelete} />
}

export function EventCardWithActions({ item, onEdit, onDelete }: AnnouncementCardProps) {
  return <DealCardWithActions item={item} category="evenements" onEdit={onEdit} onDelete={onDelete} />
}

export function InquiryCardWithActions({ item, onEdit, onDelete }: AnnouncementCardProps) {
  return <DealCardWithActions item={item} category="demandes" onEdit={onEdit} onDelete={onDelete} />
}
