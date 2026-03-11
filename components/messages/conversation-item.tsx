"use client"

import type React from "react"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Image from "next/image"
import { MoreVertical, Eye, Trash2, CheckCheck } from "lucide-react"
import { config } from "@/lib/config"

interface ConversationItemProps {
  conversationId: string
  active: boolean
  status: string
  lastMessage: string
  lastMessageTime: string
  interlocutorName: string
  interlocutorImage: string
  announcementName: string
  announcementStatus: string
  announcementId?: string
  announcementCategory?: string
  interlocutorId?: string
  onMarkAsRead?: () => void
  onDelete?: () => void
}

const ConversationItem: React.FC<ConversationItemProps> = ({
  conversationId,
  active,
  lastMessage,
  status,
  lastMessageTime,
  interlocutorName,
  interlocutorImage,
  announcementName,
  announcementStatus,
  announcementId,
  announcementCategory,
  interlocutorId,
  onMarkAsRead = () => {},
  onDelete = () => {},
}) => {
  const router = useRouter()
  const [isHovered, setIsHovered] = useState(false)
  const [showOptions, setShowOptions] = useState(false)

  const limiterTexte = (texte: string, limite = 20): string => {
    if (texte.length > limite) {
      return texte.substring(0, limite) + "..."
    }
    return texte
  }

  return (
    <div
      className={`relative cursor-pointer transition-all duration-300 ${
        active ? "bg-primary/10 border-l-4 border-primary" : "hover:bg-muted/50 border-l-4 border-transparent"
      } ${announcementStatus !== "valid" ? "bg-destructive/5" : ""}`}
      onClick={() => router.push(`/messages?action=conversation&conversationId=${conversationId}`)}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => {
        setIsHovered(false)
        setShowOptions(false)
      }}
    >
      <div className="flex items-center gap-4 p-4">
        {/* Avatar */}
        <div className="relative flex-shrink-0">
          <div className="w-12 h-12 rounded-full overflow-hidden ring-2 ring-border">
            <Image
              className="w-full h-full object-cover"
              alt={interlocutorName}
              width={48}
              height={48}
              src={interlocutorImage ? config.API_URL + interlocutorImage : "/placeholder-user.jpg"}
            />
          </div>
          {status !== "read" && (
            <div className="absolute -top-1 -right-1 w-4 h-4 bg-primary rounded-full border-2 border-card animate-pulse" />
          )}
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between mb-1">
            <p className="text-sm font-semibold truncate">{interlocutorName}</p>
            <span className="text-xs text-primary font-medium ml-2 flex-shrink-0">{lastMessageTime}</span>
          </div>
          <p className="text-xs text-muted-foreground truncate mb-1">{announcementName}</p>
          <p className="text-xs text-muted-foreground/70 truncate">{limiterTexte(lastMessage, 30)}</p>
          {announcementStatus !== "valid" && <p className="text-xs text-destructive mt-1">Offre supprimée</p>}
        </div>

        {/* Status indicator */}
        <div className="flex-shrink-0">
          {status === "read" ? (
            <CheckCheck className="w-4 h-4 text-primary" />
          ) : (
            <div className="w-2 h-2 bg-primary rounded-full" />
          )}
        </div>

        {/* Options button */}
        {isHovered && (
          <div className="absolute top-3 right-3" onClick={(e) => e.stopPropagation()}>
            <button
              className="p-2 hover:bg-muted rounded-full transition-colors"
              onClick={() => setShowOptions(!showOptions)}
            >
              <MoreVertical className="w-4 h-4" />
            </button>

            {showOptions && (
              <div className="absolute top-10 right-0 bg-card border border-border rounded-xl shadow-xl z-20 min-w-[200px] overflow-hidden animate-in fade-in slide-in-from-top-2 duration-200">
                {announcementId && announcementCategory && (
                  <button
                    className="w-full flex items-center gap-3 px-4 py-3 hover:bg-muted transition-colors text-left"
                    onClick={() => router.push(`/announcements/${announcementCategory}/${announcementId}`)}
                  >
                    <Eye className="w-4 h-4 text-primary" />
                    <span className="text-sm">Voir l'annonce</span>
                  </button>
                )}
                {interlocutorId && (
                  <button
                    className="w-full flex items-center gap-3 px-4 py-3 hover:bg-muted transition-colors text-left"
                    onClick={() => router.push(`/profil-public?Id=${interlocutorId}`)}
                  >
                    <Eye className="w-4 h-4 text-primary" />
                    <span className="text-sm">Voir le profil</span>
                  </button>
                )}
                <button
                  className="w-full flex items-center gap-3 px-4 py-3 hover:bg-destructive/10 transition-colors text-left text-destructive"
                  onClick={onDelete}
                >
                  <Trash2 className="w-4 h-4" />
                  <span className="text-sm">Supprimer</span>
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

export default ConversationItem
