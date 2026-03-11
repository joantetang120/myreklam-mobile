"use client"

import { useEffect, useRef } from "react"
import { useMessageStore } from "@/lib/stores/message-store"
import ChatHead from "./chat-head"
import ChatBubble from "./chat-bubble"
import MessageInput from "./message-input"
import { Loader2 } from "lucide-react"

interface ChatSectionProps {
  conversationId: string
  onViewDetail?: () => void
}

const ChatSection = ({ conversationId, onViewDetail }: ChatSectionProps) => {
  const {
    conversationMessages,
    interlocutor,
    announcement,
    isLoadingMessages,
    hasMoreMessages,
    showState,
    loadMoreMessages,
    fetchMessages,
  } = useMessageStore()

  const messagesContainerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (conversationId) {
      fetchMessages(true)
    }
  }, [conversationId, fetchMessages])

  useEffect(() => {
    if (messagesContainerRef.current && conversationMessages.length > 0) {
      messagesContainerRef.current.scrollTop = messagesContainerRef.current.scrollHeight
    }
  }, [conversationMessages])

  const groupMessagesByDate = (messages: typeof conversationMessages) => {
    const groupedMessages: { [key: string]: typeof conversationMessages } = {}
    messages.forEach((message) => {
      const date = new Date(message.created_at).toLocaleDateString("fr-FR", {
        day: "numeric",
        month: "long",
        year: "numeric",
      })
      if (!groupedMessages[date]) {
        groupedMessages[date] = []
      }
      groupedMessages[date].push(message)
    })
    return groupedMessages
  }

  const groupedMessages = groupMessagesByDate(conversationMessages)

  return (
    <div className="flex-1 bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm rounded-3xl border border-slate-200 dark:border-slate-700 shadow-xl flex flex-col overflow-hidden animate-in fade-in slide-in-from-right duration-500">
      <ChatHead
        conversationId={conversationId}
        interlocutorId={interlocutor?.id || ""}
        interlocutorName={interlocutor?.username || "Inconnu"}
        interlocutorImage={interlocutor?.photo}
        onViewDetail={onViewDetail}
      />

      <div
        className="flex-1 p-4 md:p-6 overflow-y-auto custom-scrollbar bg-slate-50/50 dark:bg-slate-900/50"
        ref={messagesContainerRef}
      >
        {hasMoreMessages && (
          <button
            onClick={loadMoreMessages}
            disabled={isLoadingMessages}
            className="w-full text-center text-sm text-slate-600 dark:text-slate-400 py-3 hover:text-slate-900 dark:hover:text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2 mb-4"
          >
            {isLoadingMessages ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                Chargement...
              </>
            ) : (
              "Voir les messages précédents"
            )}
          </button>
        )}

        {Object.entries(groupedMessages).map(([date, messages]) => (
          <div key={date} className="space-y-3">
            <div className="flex justify-center my-6">
              <div className="px-4 py-1.5 bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm rounded-full border border-slate-200 dark:border-slate-700 shadow-sm">
                <span className="text-xs font-semibold text-slate-600 dark:text-slate-400">{date}</span>
              </div>
            </div>
            {messages.map((message) => {
              const isSender = message.sender_id !== interlocutor.id
              const lastMessage = conversationMessages[conversationMessages.length - 1]
              return (
                <ChatBubble
                  key={message.id}
                  isSender={isSender}
                  showState={showState && lastMessage.id === message.id}
                  isNotRead={message.status !== "read"}
                  message={message.content}
                  time={new Date(message.created_at).toLocaleTimeString([], {
                    hour: "2-digit",
                    minute: "2-digit",
                  })}
                  senderName={!isSender ? interlocutor.username : "Vous"}
                  senderImage={interlocutor.photo}
                  attachments={message.attachments}
                />
              )
            })}
          </div>
        ))}
      </div>

      <MessageInput
        conversationId={conversationId}
        interlocutorId={interlocutor?.id || ""}
        announcementStatus={announcement?.status ?? "valid"}
        onMessageSent={() => {
          fetchMessages(true)
        }}
      />
    </div>
  )
}

export default ChatSection
