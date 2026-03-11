import axios from "axios"
// import config from "@/constants/config"
import { config } from "@/lib/config"

export const listTypes = {
  message: "message",
  announcement: "announcement",
  announcement_comment: "announcement_comment",
}

export const createNotification = async (
  content: string,
  type: string,
  return_url: string | null,
): Promise<{ success: boolean }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        content: content,
        type: type,
        return_url: return_url,
        Method: "create",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return { success: true }
  } catch (error) {
    return { success: false }
  }
}

export const deleteNotification = async (notificationId: string): Promise<{ success: boolean }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        notificationId: notificationId,
        Method: "delete",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return { success: true }
  } catch (error) {
    return { success: false }
  }
}

export const deleteAllNotification = async (): Promise<{ success: boolean }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        Method: "delete_all",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return { success: true }
  } catch (error) {
    return { success: false }
  }
}

export const readNotification = async (notificationId: string): Promise<{ success: boolean }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        notificationId: notificationId,
        Method: "read",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return { success: true }
  } catch (error) {
    return { success: false }
  }
}

export const readAllNotification = async (): Promise<{ success: boolean }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { success: false }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        Method: "read_all",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return { success: true }
  } catch (error) {
    return { success: false }
  }
}

export interface Notification {
  id: string
  user_id: string
  content: string
  type: string
  is_read: boolean
  return_url: string
  created_at: string
  avatar: string | null

  metadata_type: string
  metadata_id: string
}

export const getAllNotification = async (page: number, pageSize: number): Promise<Notification[]> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return []
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        page: page,
        pageSize: pageSize,
        Method: "get_notification",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const data = response.data?.data ?? []

    const formattedNotifications: Notification[] = data.map((notification: any) => ({
      id: notification.id,
      user_id: notification.user_id,
      content: notification.content,
      type: notification.type,
      is_read: notification.is_read,
      return_url: notification.return_url,
      created_at: notification.created_at,
      metadata_type: notification.metadata_type,
      metadata_id: notification.metadata_id,
    }))

    return formattedNotifications
  } catch (error) {
    return []
  }
}

export const countNotification = async (): Promise<{ unread_count: number }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { unread_count: 0 }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        Method: "count_notification",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return response.data
  } catch (error) {
    return { unread_count: 0 }
  }
}

export const countAllNotification = async (): Promise<{ count: number }> => {
  const userId = localStorage.getItem("profileId")

  if (!userId) {
    return { count: 0 }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Notification.php`,
      {
        userId: userId,
        Method: "count_notification_all",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return response.data
  } catch (error) {
    return { count: 0 }
  }
}
