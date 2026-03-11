"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { useMessageStore, setupMessageRefresh } from "@/lib/stores/message-store"
import ConversationItem from "./conversation-item"
import { Loader2 } from "lucide-react"

interface ConversationListProps {
  searchQuery: string
  conversationId: string | null
}

const ConversationList: React.FC<ConversationListProps> = ({ searchQuery, conversationId }) => {
  const router = useRouter()
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [conversationToDelete, setConversationToDelete] = useState<string | null>(null)

  const {
    conversations,
    isLoadingConversations,
    hasMoreConversations,
    setSearchQuery,
    fetchConversations,
    loadMoreConversations,
    deleteConversation,
    setSelectedConversationId,
  } = useMessageStore()

  useEffect(() => {
    setSearchQuery(searchQuery)
  }, [searchQuery, setSearchQuery])

  useEffect(() => {
    fetchConversations(true)
    const cleanupRefresh = setupMessageRefresh()
    return () => cleanupRefresh()
  }, [fetchConversations])

  useEffect(() => {
    setSelectedConversationId(conversationId)
  }, [conversationId, setSelectedConversationId])

  const handleDeleteClick = (convId: string) => {
    setConversationToDelete(convId)
    setIsDeleteModalOpen(true)
  }

  const handleConfirmDelete = async () => {
    if (!conversationToDelete) return

    const success = await deleteConversation(conversationToDelete)

    if (success && conversationId === conversationToDelete) {
      router.push("/messages")
    }

    setIsDeleteModalOpen(false)
    setConversationToDelete(null)
  }

  const handleCancelDelete = () => {
    setIsDeleteModalOpen(false)
    setConversationToDelete(null)
  }

  return (
    <div className="w-full lg:w-96 bg-card/80 backdrop-blur-sm rounded-3xl border border-border shadow-lg overflow-hidden flex flex-col animate-in fade-in slide-in-from-left duration-500">
      <div className="flex-1 overflow-y-auto custom-scrollbar">
        {conversations.length === 0 && !isLoadingConversations && (
          <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
            <div className="w-16 h-16 bg-muted rounded-full flex items-center justify-center mb-4">
              <svg className="w-8 h-8 text-muted-foreground" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
                />
              </svg>
            </div>
            <p className="text-muted-foreground">Aucune conversation trouvée</p>
          </div>
        )}

        {conversations.map((conversation, index) => {
          const lastMessage = conversation.message
          const interlocutor = conversation.interlocutor
          const announcement = conversation.announcement

          const lastMessageContent =
            lastMessage?.content ||
            ((lastMessage?.attachments?.length ?? 0) > 0
              ? `(${lastMessage.attachments?.length}) Pièce jointe`
              : "Aucun message")

          const formatTime = (dateString: string | undefined) =>
            dateString
              ? new Date(dateString).toLocaleTimeString([], {
                  hour: "2-digit",
                  minute: "2-digit",
                })
              : ""

          return (
            <div
              key={conversation.id}
              className="animate-in fade-in slide-in-from-left"
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <ConversationItem
                active={conversation.id === conversationId}
                conversationId={conversation.id}
                status={lastMessage?.status}
                lastMessage={lastMessageContent}
                lastMessageTime={formatTime(lastMessage?.created_at)}
                interlocutorName={interlocutor?.username ?? "Inconnu"}
                interlocutorImage={interlocutor?.photo ?? "/placeholder-user.jpg"}
                announcementName={announcement?.name ?? "Inconnu"}
                announcementStatus={announcement?.status ?? "valid"}
                onDelete={() => handleDeleteClick(conversation.id)}
                announcementId={announcement?.id ?? ""}
                announcementCategory={announcement?.category ?? ""}
                interlocutorId={interlocutor?.id ?? ""}
              />
            </div>
          )
        })}
      </div>

      {hasMoreConversations && (
        <button
          onClick={loadMoreConversations}
          disabled={isLoadingConversations}
          className="w-full py-4 bg-muted/50 hover:bg-muted transition-colors text-sm font-medium text-muted-foreground hover:text-foreground disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {isLoadingConversations ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              Chargement...
            </>
          ) : (
            "Voir plus"
          )}
        </button>
      )}

      {/* Delete confirmation modal */}
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
    </div>
  )
}

export default ConversationList
