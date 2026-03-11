"use client"

import { Suspense, useEffect, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { useMessageStore } from "@/lib/stores/message-store"
import { getUserInfo, getCountMessage } from "@/lib/api/messages"
import SearchBar from "@/components/messages/search-bar"
import ConversationList from "@/components/messages/conversation-list"
import ChatSection from "@/components/messages/chat-section"
import MessageDetailView from "@/components/messages/message-detail-view"
// import { ArrowLeft } from "lucide-react"
import Link from "next/link"
import FeatureGuard from "@/components/subscription/feature-guard"
import { ArrowLeft, MessageCircle } from "lucide-react"
import { Button } from "@/components/ui/button"

const MessagesContent = () => {
  const [searchQuery, setSearchQuery] = useState("")
  const [viewMode, setViewMode] = useState<"list" | "detail">("list")
  const router = useRouter()
  const searchParams = useSearchParams()
  const [isProfessionnal, setIsProfessionnal] = useState<boolean>(false)
  const [isSubscribed, setIsSubscribed] = useState<boolean>(false)
  const [countMessage, setCountMessage] = useState<number>(0)

  const { selectedConversationId, setSelectedConversationId, startNewConversation } = useMessageStore()

  useEffect(() => {
    const fetchUserInfo = async () => {
      const result = await getUserInfo()
      if (result.subscription) {
        const datedesabo = new Date(result.subscription.dateabo)
        if (result.subscription.typeabo !== undefined) {
          if (result.subscription.typeabo === "annuel") datedesabo.setFullYear(datedesabo.getFullYear() + 1)
          else datedesabo.setMonth(datedesabo.getMonth() + 1)

          if (datedesabo > new Date()) {
            setIsSubscribed(true)
          }
        }
      }
      if (result.user) {
        if (result.user.profiletype === "professionnel") {
          setIsProfessionnal(true)
        }
      }
    }
    fetchUserInfo()

    const fetchCountMessage = async () => {
      const result = await getCountMessage()
      setCountMessage(result.unread_count)
    }
    fetchCountMessage()
  }, [])

  useEffect(() => {
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
    if (!userId) {
      router.replace("/")
      return
    }

    const action = searchParams.get("action")
    const announcementId = searchParams.get("announcementId")
    const conversationId = searchParams.get("conversationId")

    if (action === "start_conversation" && announcementId) {
      startNewConversation(announcementId)
        .then((newConversationId) => {
          if (newConversationId && newConversationId !== selectedConversationId) {
            setSelectedConversationId(newConversationId)
            handleSearch("")

            const newSearchParams = new URLSearchParams(searchParams.toString())
            newSearchParams.delete("action")
            newSearchParams.delete("announcementId")
            newSearchParams.set("action", "conversation")
            newSearchParams.set("conversationId", newConversationId)
            router.replace(`/messages?${newSearchParams.toString()}`)
          }
        })
        .catch(() => {
          const newSearchParams = new URLSearchParams(searchParams.toString())
          newSearchParams.delete("action")
          newSearchParams.delete("announcementId")
          router.replace(`/messages?${newSearchParams.toString()}`)
        })
    } else if (action === "new_conversation" && announcementId) {
      // Nouvelle action : ne pas créer la conversation immédiatement
      // La conversation sera créée lors de l'envoi du premier message
      // On ne fait rien ici, le ChatSection gérera l'affichage
    } else if (action === "conversation" && conversationId && conversationId !== selectedConversationId) {
      // Only update if the conversation ID is different from the current one
      setSelectedConversationId(conversationId)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams, router])

  const handleSearch = (query: string) => {
    setSearchQuery(query)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-50 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950 py-4 md:py-8">
      <FeatureGuard 
  feature="messaging"
  fallback={
    <div className="text-center py-20">
      <MessageCircle className="w-20 h-20 text-gray-300 mx-auto mb-4" />
      <h3 className="text-xl font-semibold mb-2">Messagerie Premium</h3>
      <p className="text-gray-500 mb-6">La messagerie est réservée aux abonnés Premium</p>
      <Button onClick={() => router.push("/subscription")}>
        Passer à Premium
      </Button>
    </div>
  }
>
      <div className="container max-w-[1600px] mx-auto px-4">
        <div className="flex items-center justify-between mb-6 animate-in fade-in slide-in-from-top duration-500">
          <Link
            href="/dashboard"
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-white/80 dark:bg-slate-800/80 backdrop-blur-sm border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:border-primary/50 transition-all group shadow-sm hover:shadow-md"
          >
            <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
            <span className="text-sm font-medium">Retour</span>
          </Link>

          <div className="flex items-center gap-3 px-6 py-3 bg-gradient-to-r from-primary/10 via-primary/5 to-transparent rounded-2xl border border-primary/20">
            <div className="relative">
              <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
              <div className="absolute inset-0 w-2 h-2 rounded-full bg-primary animate-ping opacity-75" />
            </div>
            <h1 className="text-xl md:text-3xl font-bold bg-gradient-to-r from-primary via-primary/80 to-primary/60 bg-clip-text text-transparent">
              Messagerie
            </h1>
          </div>

          <div className="w-24" />
        </div>

        <div className="relative">
          {isProfessionnal && !isSubscribed && (
            <div className="absolute inset-0 z-30 rounded-3xl flex items-center justify-center bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl animate-in fade-in duration-300">
              <div className="bg-white dark:bg-slate-800 border-2 border-primary/30 rounded-3xl p-8 md:p-12 text-center max-w-xl shadow-2xl animate-in zoom-in duration-500">
                {countMessage > 0 && (
                  <div className="flex flex-col items-center gap-3 mb-8 animate-in slide-in-from-top duration-700">
                    <p className="text-sm text-slate-600 dark:text-slate-400 font-medium">Vous avez reçu</p>
                    <div className="relative">
                      <div className="absolute inset-0 bg-primary/30 blur-2xl animate-pulse" />
                      <div className="relative text-5xl font-black bg-gradient-to-br from-primary to-primary/60 bg-clip-text text-transparent px-8 py-4">
                        {countMessage}
                      </div>
                    </div>
                    <p className="text-lg font-semibold text-slate-900 dark:text-white">
                      nouveau{countMessage > 1 ? "x" : ""} message{countMessage > 1 ? "s" : ""}
                    </p>
                  </div>
                )}
                <p className="text-lg font-medium text-slate-700 dark:text-slate-300 mb-6">
                  Vous devez être un professionnel abonné pour accéder à cette fonctionnalité
                </p>
                <Link
                  href="/subscription"
                  className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-primary to-primary/80 text-white rounded-2xl font-semibold hover:shadow-xl hover:shadow-primary/25 transition-all hover:scale-105"
                >
                  S'abonner maintenant
                </Link>
              </div>
            </div>
          )}

          <SearchBar onSearch={handleSearch} />

          <div className="flex flex-col lg:flex-row gap-4 mt-4 animate-in fade-in slide-in-from-bottom duration-700">
            <ConversationList conversationId={selectedConversationId} searchQuery={searchQuery} />
            {selectedConversationId ? (
              viewMode === "list" ? (
                <ChatSection conversationId={selectedConversationId} onViewDetail={() => setViewMode("detail")} />
              ) : (
                <MessageDetailView conversationId={selectedConversationId} onBack={() => setViewMode("list")} />
              )
            ) : (
              <div className="flex-1 bg-white/60 dark:bg-slate-800/60 backdrop-blur-sm rounded-3xl border border-slate-200 dark:border-slate-700 shadow-xl flex flex-col justify-center items-center min-h-[600px] animate-in fade-in duration-500">
                <div className="text-center space-y-6 p-8">
                  <div className="relative w-32 h-32 mx-auto">
                    <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-primary/5 rounded-full animate-pulse" />
                    <div className="relative w-full h-full bg-gradient-to-br from-primary/10 to-transparent rounded-full flex items-center justify-center border-2 border-primary/20">
                      <svg
                        className="w-16 h-16 text-primary"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        strokeWidth={1.5}
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                        />
                      </svg>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Sélectionnez une conversation</h2>
                    <p className="text-sm text-slate-600 dark:text-slate-400 max-w-sm mx-auto">
                      Choisissez une conversation dans la liste pour commencer à discuter avec vos contacts
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      </FeatureGuard>
    </div>
  )
}

const Messages = () => {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 to-white dark:from-slate-950 dark:to-slate-900">
          <div className="flex flex-col items-center gap-4">
            <div className="relative">
              <div className="animate-spin rounded-full h-16 w-16 border-4 border-slate-200 dark:border-slate-700 border-t-primary" />
              <div className="absolute inset-0 rounded-full bg-primary/10 blur-xl animate-pulse" />
            </div>
            <p className="text-sm text-slate-600 dark:text-slate-400 font-medium">Chargement de la messagerie...</p>
          </div>
        </div>
      }
    >
      <MessagesContent />
    </Suspense>
  )
}

export default Messages
