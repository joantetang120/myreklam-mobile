"use client"

import { useState, useEffect } from "react"
import { Bell, Trash2, Check, CheckCheck } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import {
  getAllNotification,
  readNotification,
  readAllNotification,
  deleteNotification,
  deleteAllNotification,
  countNotification,
  countAllNotification,
  type Notification,
} from "@/lib/notifications"
import { formatDistanceToNow } from "date-fns"
import { fr } from "date-fns/locale"
import { useAuthStore } from "@/lib/auth-store"
import { useRouter } from "next/navigation"

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [activeTab, setActiveTab] = useState<"all" | "unread">("all")
  const [loading, setLoading] = useState(true)
  const [unreadCount, setUnreadCount] = useState(0)
  const [totalCount, setTotalCount] = useState(0)
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(true)
  const { userId, isAuthenticated } = useAuthStore()
  const router = useRouter()

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/")
      return
    }
    loadNotifications()
    loadCounts()
  }, [isAuthenticated, page])

  const loadNotifications = async () => {
    setLoading(true)
    const data = await getAllNotification(page, 20)
    if (page === 1) {
      setNotifications(data)
    } else {
      setNotifications((prev) => [...prev, ...data])
    }
    setHasMore(data.length === 20)
    setLoading(false)
  }

  const loadCounts = async () => {
    const { unread_count } = await countNotification()
    const { count } = await countAllNotification()
    setUnreadCount(unread_count)
    setTotalCount(count)
  }

  const handleNotificationClick = async (notification: Notification) => {
    if (!notification.is_read) {
      await readNotification(notification.id)
      loadCounts()
      loadNotifications()
    }
    if (notification.return_url) {
      router.push(notification.return_url)
    }
  }

  const handleMarkAllAsRead = async () => {
    await readAllNotification()
    loadCounts()
    loadNotifications()
  }

  const handleDeleteNotification = async (notificationId: string) => {
    await deleteNotification(notificationId)
    loadCounts()
    loadNotifications()
  }

  const handleDeleteAll = async () => {
    if (confirm("Êtes-vous sûr de vouloir supprimer toutes les notifications ?")) {
      await deleteAllNotification()
      loadCounts()
      loadNotifications()
    }
  }

  const filteredNotifications = activeTab === "unread" ? notifications.filter((n) => !n.is_read) : notifications

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-950">
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">Notifications</h1>
          <p className="text-gray-600 dark:text-gray-400">Gérez toutes vos notifications en un seul endroit</p>
        </div>

        {/* Actions Bar */}
        <Card className="p-3 sm:p-4 mb-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4">
            <div className="flex gap-2">
              <button
                onClick={() => setActiveTab("all")}
                className={`flex-1 sm:flex-none px-3 sm:px-4 py-2 text-xs sm:text-sm font-medium rounded-lg transition-colors ${
                  activeTab === "all"
                    ? "bg-primary text-white"
                    : "bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800"
                }`}
              >
                Tout ({totalCount})
              </button>
              <button
                onClick={() => setActiveTab("unread")}
                className={`flex-1 sm:flex-none px-3 sm:px-4 py-2 text-xs sm:text-sm font-medium rounded-lg transition-colors ${
                  activeTab === "unread"
                    ? "bg-primary text-white"
                    : "bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800"
                }`}
              >
                Non-lues ({unreadCount})
              </button>
            </div>

            <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
              {unreadCount > 0 && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleMarkAllAsRead}
                  className="text-primary hover:text-primary bg-transparent text-xs sm:text-sm w-full sm:w-auto"
                >
                  <CheckCheck className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
                  <span className="truncate">Tout marquer comme lu</span>
                </Button>
              )}
              {totalCount > 0 && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleDeleteAll}
                  className="text-red-600 hover:text-red-700 bg-transparent text-xs sm:text-sm w-full sm:w-auto"
                >
                  <Trash2 className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
                  <span className="truncate">Tout supprimer</span>
                </Button>
              )}
            </div>
          </div>
        </Card>

        {/* Notifications List */}
        {loading && page === 1 ? (
          <div className="text-center py-12">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-primary border-r-transparent"></div>
            <p className="mt-4 text-gray-600 dark:text-gray-400">Chargement des notifications...</p>
          </div>
        ) : filteredNotifications.length === 0 ? (
          <Card className="p-12 text-center">
            <Bell className="h-16 w-16 mx-auto text-gray-300 dark:text-gray-700 mb-4" />
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">
              {activeTab === "unread" ? "Aucune notification non lue" : "Aucune notification"}
            </h3>
            <p className="text-gray-600 dark:text-gray-400">
              {activeTab === "unread"
                ? "Toutes vos notifications ont été lues"
                : "Vous n'avez pas encore de notifications"}
            </p>
          </Card>
        ) : (
          <div className="space-y-2">
            {filteredNotifications.map((notification) => (
              <Card
                key={notification.id}
                className={`p-4 hover:shadow-md transition-all cursor-pointer ${
                  !notification.is_read ? "bg-blue-50/50 dark:bg-blue-950/20 border-l-4 border-l-primary" : ""
                }`}
                onClick={() => handleNotificationClick(notification)}
              >
                <div className="flex gap-4">
                  <div className="flex-shrink-0">
                    <div className="h-12 w-12 rounded-full bg-gray-200 dark:bg-gray-800 flex items-center justify-center">
                      <Bell className="h-6 w-6 text-gray-500" />
                    </div>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-gray-900 dark:text-gray-100 mb-1">{notification.content}</p>
                    <div className="flex items-center gap-2">
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {formatDistanceToNow(new Date(notification.created_at), {
                          addSuffix: true,
                          locale: fr,
                        })}
                      </p>
                      {!notification.is_read && (
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-primary/10 text-primary">
                          Nouveau
                        </span>
                      )}
                    </div>
                  </div>
                  <div className="flex-shrink-0 flex items-start gap-2">
                    {!notification.is_read && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          readNotification(notification.id).then(() => {
                            loadCounts()
                            loadNotifications()
                          })
                        }}
                        className="p-2 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                        title="Marquer comme lu"
                      >
                        <Check className="h-4 w-4 text-gray-500" />
                      </button>
                    )}
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        handleDeleteNotification(notification.id)
                      }}
                      className="p-2 hover:bg-red-50 dark:hover:bg-red-950/20 rounded-lg transition-colors"
                      title="Supprimer"
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </button>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}

        {/* Load More */}
        {hasMore && filteredNotifications.length > 0 && (
          <div className="mt-6 text-center">
            <Button
              variant="outline"
              onClick={() => setPage((p) => p + 1)}
              disabled={loading}
              className="min-w-[150px] sm:min-w-[200px]"
            >
              {loading ? "Chargement..." : "Charger plus"}
            </Button>
          </div>
        )}
      </div>
    </div>
  )
}
