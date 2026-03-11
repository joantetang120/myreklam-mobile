"use client"

import type React from "react"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Image from "next/image"
import Link from "next/link"
import { Trash2, ArrowLeft } from "lucide-react"
import { config } from "@/lib/config"
import { deleteMessage } from "@/lib/api/messages"

interface ChatHeadProps {
  interlocutorId: string
  interlocutorName: string
  interlocutorImage: string
  conversationId: string
}

const ChatHead: React.FC<ChatHeadProps> = ({ interlocutorId, interlocutorName, interlocutorImage, conversationId }) => {
  const router = useRouter()
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)

  const handleDeleteClick = () => {
    setIsDeleteModalOpen(true)
  }

  const handleConfirmDelete = async () => {
    try {
      const response = await deleteMessage(conversationId)
      if (response?.success) {
        window.location.href = "/messages"
      }
    } catch (error) {
      console.error("Erreur lors de la suppression :", error)
    } finally {
      setIsDeleteModalOpen(false)
    }
  }

  const handleCancelDelete = () => {
    setIsDeleteModalOpen(false)
  }

  return (
    <>
      <div className="flex items-center justify-between px-4 py-4 border-b border-border bg-card">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.push("/messages")}
            className="p-2 hover:bg-muted rounded-full transition-colors"
            aria-label="Retour aux messages"
          >
            <ArrowLeft className="w-5 h-5 text-foreground" />
          </button>

          <Link href={`/profil-public?Id=${interlocutorId}`} className="group">
            <div className="relative">
              <div className="w-12 h-12 rounded-full overflow-hidden ring-2 ring-border group-hover:ring-primary transition-all">
                <Image
                  className="w-full h-full object-cover"
                  width={48}
                  height={48}
                  src={interlocutorImage ? config.API_URL + interlocutorImage : "/placeholder-user.jpg"}
                  alt={interlocutorName}
                />
              </div>
              <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-card" />
            </div>
          </Link>
          <div>
            <Link href={`/profil-public?Id=${interlocutorId}`} className="hover:text-primary transition-colors">
              <h3 className="font-semibold">{interlocutorName}</h3>
            </Link>
            <p className="text-xs text-muted-foreground">En ligne</p>
          </div>
        </div>

        <button
          onClick={handleDeleteClick}
          className="p-2 hover:bg-destructive/10 rounded-full transition-colors group"
          aria-label="Supprimer la conversation"
        >
          <Trash2 className="w-5 h-5 text-muted-foreground group-hover:text-destructive transition-colors" />
        </button>
      </div>

      {isDeleteModalOpen && (
        <div className="fixed inset-0 bg-background/80 backdrop-blur-sm flex items-center justify-center z-50 animate-in fade-in duration-200">
          <div className="bg-card border border-border rounded-3xl p-6 max-w-md w-full mx-4 shadow-2xl animate-in zoom-in duration-300">
            <h3 className="font-bold text-lg mb-4">Confirmer la suppression</h3>
            <p className="text-muted-foreground mb-6">
              Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.
            </p>
            <div className="flex gap-3 justify-end">
              <button
                className="px-4 py-2 rounded-xl bg-muted hover:bg-muted/80 transition-colors"
                onClick={handleCancelDelete}
              >
                Annuler
              </button>
              <button
                className="px-4 py-2 rounded-xl bg-destructive text-destructive-foreground hover:bg-destructive/90 transition-colors"
                onClick={handleConfirmDelete}
              >
                Supprimer
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}

export default ChatHead
