"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Bell, MoreVertical } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  getAllNotification,
  readNotification,
  deleteNotification,
  countNotification,
  type Notification,
} from "@/lib/notifications"
import { formatDistanceToNow } from "date-fns"
import { fr } from "date-fns/locale"

interface NotificationsDropdownProps {
  userId: string
}

export function NotificationsDropdown({ userId }: NotificationsDropdownProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [activeTab, setActiveTab] = useState<"all" | "unread">("all")
  const [loading, setLoading] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)
  const router = useRouter()

  useEffect(() => {
    if (userId) {
      loadNotifications()
      loadUnreadCount()
    }
  }, [userId])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }

    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside)
    }

    return () => {
      document.removeEventListener("mousedown", handleClickOutside)
    }
  }, [isOpen])

  const loadNotifications = async () => {
    setLoading(true)
    const data = await getAllNotification(1, 5)
    setNotifications(data)
    setLoading(false)
  }

  const loadUnreadCount = async () => {
    const { unread_count } = await countNotification()
    setUnreadCount(unread_count)
  }

  const handleNotificationItemClick = async (notification: Notification) => {
    if (!notification.is_read) {
      await readNotification(notification.id)
      loadUnreadCount()
      loadNotifications()
    }
    setIsOpen(false)
    if (notification.return_url) {
      router.push(notification.return_url)
    }
  }

  const handleDeleteNotification = async (e: React.MouseEvent, notificationId: string) => {
    e.stopPropagation()
    await deleteNotification(notificationId)
    loadNotifications()
    loadUnreadCount()
  }

  const filteredNotifications = activeTab === "unread" ? notifications.filter((n) => !n.is_read) : notifications

  const unreadNotifications = notifications.filter((n) => !n.is_read).length

  const handleBellClick = () => {
    // Sur mobile, rediriger vers la page des notifications avec rechargement
    if (window.innerWidth < 640) {
      window.location.href = '/notifications'
    } else {
      // Sur desktop, afficher le dropdown
      setIsOpen(!isOpen)
    }
  }

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={handleBellClick}
        className="relative p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors group"
        title="Notifications"
      >
        <Bell className="h-5 w-5 text-gray-600 dark:text-gray-400 group-hover:text-primary transition-colors" />
        {unreadCount > 0 && (
          <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-red-500 ring-2 ring-white dark:ring-gray-950" />
        )}
      </button>

      {isOpen && (
        <div className="fixed sm:absolute left-4 right-4 sm:left-auto sm:right-0 top-16 sm:top-auto mt-0 sm:mt-2 w-auto sm:w-[380px] bg-white dark:bg-gray-950 rounded-lg shadow-xl border border-gray-200 dark:border-gray-800 overflow-hidden z-50">
          {/* Header */}
          <div className="p-4 border-b border-gray-200 dark:border-gray-800">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-lg font-bold text-gray-900 dark:text-gray-100">
                Notifications ({notifications.length})
              </h3>
              <button
                onClick={() => setIsOpen(false)}
                className="p-1 hover:bg-gray-100 dark:hover:bg-gray-900 rounded transition-colors"
              >
                <MoreVertical className="h-5 w-5 text-gray-500" />
              </button>
            </div>

            {/* Tabs */}
            <div className="flex gap-2">
              <button
                onClick={() => setActiveTab("all")}
                className={`px-4 py-1.5 text-sm font-medium rounded-full transition-colors ${
                  activeTab === "all"
                    ? "bg-primary text-white"
                    : "bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800"
                }`}
              >
                Tout ({notifications.length})
              </button>
              <button
                onClick={() => setActiveTab("unread")}
                className={`px-4 py-1.5 text-sm font-medium rounded-full transition-colors ${
                  activeTab === "unread"
                    ? "bg-primary text-white"
                    : "bg-gray-100 dark:bg-gray-900 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800"
                }`}
              >
                Non-lues ({unreadNotifications})
              </button>
            </div>
          </div>

          {/* Notifications List */}
          <div className="max-h-[400px] overflow-y-auto">
            {loading ? (
              <div className="p-8 text-center text-gray-500">Chargement...</div>
            ) : filteredNotifications.length === 0 ? (
              <div className="p-8 text-center text-gray-500">
                {activeTab === "unread" ? "Aucune notification non lue" : "Aucune notification"}
              </div>
            ) : (
              <div className="divide-y divide-gray-100 dark:divide-gray-900">
                {filteredNotifications.map((notification) => (
                  <div
                    key={notification.id}
                    onClick={() => handleNotificationItemClick(notification)}
                    className={`p-4 hover:bg-gray-50 dark:hover:bg-gray-900/50 cursor-pointer transition-colors ${
                      !notification.is_read ? "bg-blue-50/50 dark:bg-blue-950/20" : ""
                    }`}
                  >
                    <div className="flex gap-3">
                      <div className="flex-shrink-0">
                        <div className="h-10 w-10 rounded-full bg-gray-200 dark:bg-gray-800 flex items-center justify-center">
                          <Bell className="h-5 w-5 text-gray-500" />
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm text-gray-700 dark:text-gray-300 line-clamp-2">{notification.content}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                          {formatDistanceToNow(new Date(notification.created_at), {
                            addSuffix: true,
                            locale: fr,
                          })}
                        </p>
                      </div>
                      {!notification.is_read && (
                        <div className="flex-shrink-0">
                          <div className="h-2 w-2 rounded-full bg-primary" />
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="p-3 border-t border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900/50">
            <Link href="/notifications" onClick={() => setIsOpen(false)}>
              <Button variant="ghost" className="w-full text-primary hover:text-primary hover:bg-primary/10">
                Voir plus
              </Button>
            </Link>
          </div>
        </div>
      )}
    </div>
  )
}
