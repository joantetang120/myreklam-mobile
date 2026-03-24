import axios from "axios"
import { config } from "@/lib/config"
import type {
  Conversation,
  ConversationMessage,
  Interlocutor,
  Announcement,
  Attachments,
} from "@/lib/stores/message-store"

export const startConversation = async (partnerId: string) => {
  const token = localStorage.getItem("token")

  if (!token || !partnerId) {
    console.error("[startConversation] Missing token or partnerId")
    return null
  }

  try {
    console.log("[startConversation] Creating/getting conversation with partner:", partnerId)
    
    const response = await axios.post(
      `${config.API_URL}/api/conversations`,
      {
        partner_id: partnerId,
      },
      {
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
      },
    )

    // Laravel API returns the conversation in response.data
    if (response.data?.success && response.data?.data?.id) {
      console.log("[startConversation] Conversation ID:", response.data.data.id)
      return response.data.data.id
    }

    console.error("[startConversation] Unexpected response from backend:", response.data)
    return null
  } catch (error: any) {
    console.error("[startConversation] Error starting conversation:", error.response?.data || error.message)
    
    if (error.response?.status === 422) {
      console.error("[startConversation] Validation error:", error.response.data.message)
    }
    
    return null
  }
}

export const getConversationList = async (search: string, page: number, pageSize: number): Promise<Conversation[]> => {
  const userId = localStorage.getItem("profileId")
  if (!userId) {
    return []
  }
  try {
    const response = await axios.post(
      `${config.API_URL}/Message.php`,
      {
        senderId: userId,
        search: search,
        page: page,
        pageSize: pageSize,
        Method: "get_conversation",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const conversations = response.data?.conversations || []

    const formattedConversations: Conversation[] = conversations.map((conversation: any) => ({
      id: conversation.id,
      message: {
        id: conversation?.message?.id,
        content: conversation?.message?.content,
        status: conversation?.message?.status,
        created_at: conversation?.message?.created_at,
        attachments: conversation?.message?.attachments,
      },
      interlocutor: {
        id: conversation?.interlocutor?.id,
        username: conversation?.interlocutor?.username,
        photo: conversation?.interlocutor?.photo,
      },
      announcement: {
        id: conversation?.announcement?.id,
        name: conversation?.announcement?.name,
        status: conversation?.announcement?.status,
        category: conversation?.announcement?.category,
      },
    }))

    const uniqueConversations = formattedConversations.filter(
      (conversation, index, self) => index === self.findIndex((t) => t.id === conversation.id),
    )

    return uniqueConversations
  } catch (error) {
    return []
  }
}

export const getConversationMessage = async (
  ConversationId: string,
  page: number,
  pageSize: number,
): Promise<{ announcement: Announcement; interlocutor: Interlocutor; messages: ConversationMessage[] }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return {
      announcement: {
        id: "",
        name: "",
        status: "",
      },
      interlocutor: {
        id: "",
        username: "Inconnu",
        photo: "",
      },
      messages: [],
    }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Message.php`,
      {
        idConversation: ConversationId,
        senderId: userId,
        page: page,
        pageSize: pageSize,
        Method: "get_message",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const announcement = response.data?.data?.announcement || {}
    const interlocutor = response.data?.data?.interlocutor || {}
    const messages = response.data?.data?.messages || []

    const formattedAnnouncement: Announcement = {
      id: announcement?.id,
      name: announcement?.name,
      status: announcement?.status,
    }

    const formattedInterlocutor: Interlocutor = {
      id: interlocutor.id,
      username: interlocutor.username,
      photo: interlocutor.photo,
    }

    const formattedMessages: ConversationMessage[] = messages.map((message: any) => ({
      id: message.id,
      sender_id: message.sender_id,
      content: message.content,
      status: message.status,
      created_at: message.created_at,
      attachments: message.attachments,
    }))

    return {
      announcement: formattedAnnouncement,
      interlocutor: formattedInterlocutor,
      messages: formattedMessages,
    }
  } catch (error) {
    return {
      announcement: {
        id: "",
        name: "",
        status: "",
      },
      interlocutor: {
        id: "",
        username: "Inconnu",
        photo: "",
      },
      messages: [],
    }
  }
}

export const sendMessage = async (
  conversationId: string,
  interlocutorId: string,
  content: string,
  attachments: Attachments[],
): Promise<{ success: boolean; message: string }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false, message: "Vous devez être connecté pour envoyer un message." }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Message.php`,
      {
        idConversation: conversationId,
        senderId: userId,
        receiverId: interlocutorId,
        message: content,
        attachments: attachments,
        Method: "create",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return { success: true, message: "Message envoyé avec succès" }
  } catch (error) {
    return { success: false, message: "Erreur lors de l'envoi du message" }
  }
}

export const deleteMessage = async (conversationId: string): Promise<{ success: boolean; message: string }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false, message: "Vous devez être connecté pour supprimer un message." }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Message.php`,
      {
        idConversation: conversationId,
        senderId: userId,
        Method: "delete",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return { success: true, message: "Message supprimé avec succès" }
  } catch (error) {
    return { success: false, message: "Erreur lors de la suppression du message" }
  }
}

export const getCountMessage = async (userId: string): Promise<{ unread_count: number }> => {
  if (!userId) {
    console.log("[v0] getCountMessage - No userId provided")
    return { unread_count: 0 }
  }

  try {
    console.log("[v0] getCountMessage - Calling API with userId:", userId)
    const response = await axios.post(
      `${config.API_URL}/Message.php`,
      {
        senderId: userId,
        Method: "count_messages",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    console.log("[v0] getCountMessage - API Response:", response.data)
    const count = response.data.count || 0
    console.log("[v0] getCountMessage - Returning count:", count)
    
    return { unread_count: count }
  } catch (error) {
    console.error("[v0] getCountMessage - Error:", error)
    return { unread_count: 0 }
  }
}

export const getUserInfo = async () => {
  // Cette fonction doit être implémentée selon votre API
  // Pour l'instant, je retourne un objet vide
  return {
    user: null,
    subscription: null,
  }
}
