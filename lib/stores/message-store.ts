import { create } from "zustand"
import { getConversationList, getConversationMessage, deleteMessage, startConversation, getCountMessage } from "@/lib/api/messages"

export interface Attachments {
  file_url: string
  file_type: string
  file_name: string
}

export interface ConversationMessage {
  id: string
  content: string
  status: "sent" | "delivered" | "read"
  sender_id: string
  attachments: Attachments[]
  created_at: string
}

export interface Interlocutor {
  id: string
  username: string
  photo: string
}

export interface Announcement {
  id: string
  name: string
  status?: string
  category?: string
}

export interface Message {
  id: string
  content: string
  status: "sent" | "delivered" | "read"
  created_at: string
  attachments: Attachments[] | null
}

export interface Conversation {
  id: string
  message: Message
  interlocutor: Interlocutor
  announcement: Announcement
}

interface MessageState {
  conversations: Conversation[]
  isLoadingConversations: boolean
  hasMoreConversations: boolean
  conversationPageNumber: number
  conversationPageSize: number
  searchQuery: string
  selectedConversationId: string | null

  conversationMessages: ConversationMessage[]
  isLoadingMessages: boolean
  hasMoreMessages: boolean
  messagePageNumber: number
  messagePageSize: number
  interlocutor: Interlocutor
  announcement: Announcement
  showState: boolean

  unreadCount: number

  setSearchQuery: (query: string) => void
  setSelectedConversationId: (id: string | null) => void
  fetchConversations: (forceRefresh?: boolean) => Promise<void>
  fetchUnreadCount: (userId: string) => Promise<void>
  loadMoreConversations: () => Promise<void>
  deleteConversation: (id: string) => Promise<boolean>
  startNewConversation: (announcementId: string) => Promise<string | null>

  fetchMessages: (forceRefresh?: boolean) => Promise<void>
  loadMoreMessages: () => Promise<void>
  resetMessagePagination: () => void
  addMessage: (message: ConversationMessage) => void
}

const defaultInterlocutor: Interlocutor = {
  id: "",
  username: "",
  photo: "",
}

const defaultAnnouncement: Announcement = {
  id: "",
  name: "",
  status: "",
}

export const useMessageStore = create<MessageState>((set, get) => ({
  conversations: [],
  isLoadingConversations: false,
  hasMoreConversations: true,
  conversationPageNumber: 1,
  conversationPageSize: 20,
  searchQuery: "",
  selectedConversationId: null,

  conversationMessages: [],
  isLoadingMessages: false,
  hasMoreMessages: true,
  messagePageNumber: 1,
  messagePageSize: 20,
  interlocutor: defaultInterlocutor,
  announcement: defaultAnnouncement,
  showState: false,

  unreadCount: 0,

  setSearchQuery: (query) =>
    set({
      searchQuery: query,
      conversationPageNumber: 1,
      conversations: [],
    }),

  setSelectedConversationId: (id) => {
    set({
      selectedConversationId: id,
      messagePageNumber: 1,
      conversationMessages: [],
    })
    if (id) {
      get().fetchMessages(true)
    }
  },

  fetchUnreadCount: async (userId: string) => {
    if (!userId) {
      console.log("[v0] MessageStore - No userId provided to fetchUnreadCount")
      return
    }
    
    try {
      console.log("[v0] MessageStore - Fetching unread count for userId:", userId)
      const countData = await getCountMessage(userId)
      const unreadCount = countData.unread_count || 0
      console.log("[v0] MessageStore - Unread count received:", unreadCount)
      set({ unreadCount })
    } catch (error) {
      console.error("Erreur lors du chargement du compteur:", error)
    }
  },

  fetchConversations: async (forceRefresh = false) => {
    const { isLoadingConversations, searchQuery, conversationPageSize } = get()

    if (isLoadingConversations && !forceRefresh) return

    set({ isLoadingConversations: true })

    try {
      const data = await getConversationList(searchQuery, 1, conversationPageSize)

      // Récupérer le userId pour le compteur
      const userId = localStorage.getItem("profileId")
      if (userId) {
        const countData = await getCountMessage(userId)
        const unreadCount = countData.unread_count || 0
        console.log("[v0] MessageStore - Unread count from API:", unreadCount)
        
        set({
          conversations: data,
          unreadCount,
          isLoadingConversations: false,
          hasMoreConversations: data.length === conversationPageSize,
        })
      } else {
        set({
          conversations: data,
          isLoadingConversations: false,
          hasMoreConversations: data.length === conversationPageSize,
        })
      }
    } catch (error) {
      console.error("Erreur lors du chargement des conversations:", error)
      set({ isLoadingConversations: false })
    }
  },

  loadMoreConversations: async () => {
    const {
      isLoadingConversations,
      hasMoreConversations,
      searchQuery,
      conversationPageNumber,
      conversationPageSize,
      conversations,
    } = get()

    if (isLoadingConversations || !hasMoreConversations) return

    const nextPage = conversationPageNumber + 1

    set({ isLoadingConversations: true })

    try {
      const data = await getConversationList(searchQuery, nextPage, conversationPageSize)

      set({
        conversations: [...conversations, ...data],
        conversationPageNumber: nextPage,
        isLoadingConversations: false,
        hasMoreConversations: data.length === conversationPageSize,
      })
    } catch (error) {
      console.error("Erreur lors du chargement de plus de conversations:", error)
      set({ isLoadingConversations: false })
    }
  },

  deleteConversation: async (id) => {
    try {
      const response = await deleteMessage(id)

      if (response?.success) {
        const { conversations, selectedConversationId } = get()
        set({
          conversations: conversations.filter((conv) => conv.id !== id),
          selectedConversationId: selectedConversationId === id ? null : selectedConversationId,
        })

        return true
      }
      return false
    } catch (error) {
      console.error("Erreur lors de la suppression de la conversation:", error)
      return false
    }
  },

  startNewConversation: async (announcementId) => {
    try {
      const conversationId = await startConversation(announcementId)
      if (conversationId) {
        await get().fetchConversations(true)
        return conversationId
      }
      return null
    } catch (error) {
      console.error("Erreur lors du démarrage d'une nouvelle conversation:", error)
      return null
    }
  },

  fetchMessages: async (forceRefresh = false) => {
    const { isLoadingMessages, selectedConversationId, messagePageSize } = get()

    if (!selectedConversationId || (isLoadingMessages && !forceRefresh)) return

    set({ isLoadingMessages: true })

    try {
      const data = await getConversationMessage(selectedConversationId, 1, messagePageSize)

      const showState =
        data.messages.length > 0 && data.messages[data.messages.length - 1].sender_id !== data.interlocutor.id

      set({
        conversationMessages: data.messages,
        interlocutor: data.interlocutor,
        announcement: data.announcement,
        showState,
        isLoadingMessages: false,
        hasMoreMessages: data.messages.length === messagePageSize,
        messagePageNumber: 1,
      })
    } catch (error) {
      console.error("Erreur lors du chargement des messages:", error)
      set({ isLoadingMessages: false })
    }
  },

  loadMoreMessages: async () => {
    const {
      isLoadingMessages,
      hasMoreMessages,
      selectedConversationId,
      messagePageNumber,
      messagePageSize,
      conversationMessages,
    } = get()

    if (!selectedConversationId || isLoadingMessages || !hasMoreMessages) return

    const nextPage = messagePageNumber + 1

    set({ isLoadingMessages: true })

    try {
      const data = await getConversationMessage(selectedConversationId, nextPage, messagePageSize)

      set({
        conversationMessages: [...data.messages, ...conversationMessages],
        messagePageNumber: nextPage,
        isLoadingMessages: false,
        hasMoreMessages: data.messages.length === messagePageSize,
      })
    } catch (error) {
      console.error("Erreur lors du chargement de plus de messages:", error)
      set({ isLoadingMessages: false })
    }
  },

  resetMessagePagination: () => {
    set({
      messagePageNumber: 1,
      conversationMessages: [],
    })
  },

  addMessage: (message) => {
    const { conversationMessages } = get()
    set({
      conversationMessages: [...conversationMessages, message],
      showState: true,
    })
  },
}))

export const setupMessageRefresh = () => {
  const intervalId = setInterval(() => {
    const { fetchConversations, fetchMessages, selectedConversationId } = useMessageStore.getState()
    fetchConversations()
    if (selectedConversationId) {
      fetchMessages()
    }
  }, 10000)

  return () => clearInterval(intervalId)
}
