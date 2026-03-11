"use client"

import { useEffect } from "react"
import { useMessageStore } from "@/lib/stores/message-store"
import {
  ArrowLeft,
  Calendar,
  MapPin,
  Briefcase,
  DollarSign,
  Clock,
  User,
  Mail,
  Phone,
  ExternalLink,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import Image from "next/image"
import { config } from "@/lib/config"

interface MessageDetailViewProps {
  conversationId: string
  onBack: () => void
}

const MessageDetailView = ({ conversationId, onBack }: MessageDetailViewProps) => {
  const { interlocutor, announcement, fetchMessages } = useMessageStore()

  useEffect(() => {
    if (conversationId) {
      fetchMessages(true)
    }
  }, [conversationId, fetchMessages])

  if (!announcement) {
    return (
      <div className="flex-1 bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm rounded-3xl border border-slate-200 dark:border-slate-700 shadow-xl flex items-center justify-center p-8">
        <p className="text-slate-600 dark:text-slate-400">Aucune annonce associée à cette conversation</p>
      </div>
    )
  }

  return (
    <div className="flex-1 bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm rounded-3xl border border-slate-200 dark:border-slate-700 shadow-xl flex flex-col overflow-hidden animate-in fade-in slide-in-from-right duration-500">
      {/* Header */}
      <div className="flex items-center gap-4 p-6 border-b border-slate-200 dark:border-slate-700 bg-gradient-to-r from-primary/5 to-transparent">
        <Button
          variant="ghost"
          size="icon"
          onClick={onBack}
          className="rounded-full hover:bg-white/50 dark:hover:bg-slate-700/50"
        >
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div>
          <h2 className="text-xl font-bold text-slate-900 dark:text-white">Détails de l'annonce</h2>
          <p className="text-sm text-slate-600 dark:text-slate-400">Informations complètes</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-6 space-y-6 custom-scrollbar">
        {/* Announcement Card */}
        <Card className="p-6 space-y-6 border-2 border-primary/20 bg-gradient-to-br from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1 space-y-2">
              <div className="flex items-center gap-2 flex-wrap">
                <h3 className="text-2xl font-bold text-slate-900 dark:text-white">{announcement.title}</h3>
                <Badge variant={announcement.status === "valid" ? "default" : "secondary"} className="capitalize">
                  {announcement.status}
                </Badge>
              </div>
              <div className="flex items-center gap-4 text-sm text-slate-600 dark:text-slate-400">
                <div className="flex items-center gap-1">
                  <Calendar className="w-4 h-4" />
                  <span>{new Date(announcement.created_at).toLocaleDateString("fr-FR")}</span>
                </div>
                {announcement.location && (
                  <div className="flex items-center gap-1">
                    <MapPin className="w-4 h-4" />
                    <span>{announcement.location}</span>
                  </div>
                )}
              </div>
            </div>
            {announcement.image && (
              <Image
                src={config.API_URL + announcement.image || "/placeholder.svg"}
                alt={announcement.title}
                width={120}
                height={120}
                className="rounded-xl object-cover border-2 border-slate-200 dark:border-slate-700"
              />
            )}
          </div>

          <Separator />

          <div className="space-y-4">
            <div>
              <h4 className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-2">Description</h4>
              <p className="text-slate-600 dark:text-slate-400 leading-relaxed">{announcement.description}</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {announcement.job_type && (
                <div className="flex items-center gap-3 p-3 bg-white/50 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700">
                  <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Briefcase className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <p className="text-xs text-slate-600 dark:text-slate-400">Type de contrat</p>
                    <p className="font-semibold text-slate-900 dark:text-white">{announcement.job_type}</p>
                  </div>
                </div>
              )}

              {announcement.salary && (
                <div className="flex items-center gap-3 p-3 bg-white/50 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700">
                  <div className="w-10 h-10 rounded-full bg-green-500/10 flex items-center justify-center">
                    <DollarSign className="w-5 h-5 text-green-600 dark:text-green-400" />
                  </div>
                  <div>
                    <p className="text-xs text-slate-600 dark:text-slate-400">Salaire</p>
                    <p className="font-semibold text-slate-900 dark:text-white">{announcement.salary}</p>
                  </div>
                </div>
              )}

              {announcement.duration && (
                <div className="flex items-center gap-3 p-3 bg-white/50 dark:bg-slate-800/50 rounded-xl border border-slate-200 dark:border-slate-700">
                  <div className="w-10 h-10 rounded-full bg-blue-500/10 flex items-center justify-center">
                    <Clock className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                  </div>
                  <div>
                    <p className="text-xs text-slate-600 dark:text-slate-400">Durée</p>
                    <p className="font-semibold text-slate-900 dark:text-white">{announcement.duration}</p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </Card>

        {/* Interlocutor Card */}
        {interlocutor && (
          <Card className="p-6 space-y-4 bg-gradient-to-br from-white to-slate-50 dark:from-slate-800 dark:to-slate-900">
            <h4 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <User className="w-5 h-5 text-primary" />
              Contact
            </h4>
            <Separator />
            <div className="flex items-center gap-4">
              {interlocutor.photo && (
                <Image
                  src={config.API_URL + interlocutor.photo || "/placeholder.svg"}
                  alt={interlocutor.username}
                  width={64}
                  height={64}
                  className="rounded-full object-cover border-2 border-primary/20"
                />
              )}
              <div className="flex-1">
                <p className="font-semibold text-lg text-slate-900 dark:text-white">{interlocutor.username}</p>
                {interlocutor.email && (
                  <div className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400 mt-1">
                    <Mail className="w-4 h-4" />
                    <span>{interlocutor.email}</span>
                  </div>
                )}
                {interlocutor.phone && (
                  <div className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400 mt-1">
                    <Phone className="w-4 h-4" />
                    <span>{interlocutor.phone}</span>
                  </div>
                )}
              </div>
            </div>
            <Button variant="outline" className="w-full bg-transparent" asChild>
              <a href={`/profil-public?Id=${interlocutor.id}`} target="_blank" rel="noopener noreferrer">
                <ExternalLink className="w-4 h-4 mr-2" />
                Voir le profil complet
              </a>
            </Button>
          </Card>
        )}
      </div>
    </div>
  )
}

export default MessageDetailView
