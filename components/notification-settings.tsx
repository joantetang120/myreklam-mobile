"use client"

import { useEffect, useState } from "react"
import { Bell } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Switch } from "@/components/ui/switch"
import { updateSetting } from "@/lib/api"
import { useUserData } from "@/hooks/use-user-data"

interface Settings {
  active_nofification_mobile_message: boolean
  active_nofification_mobile_alert: boolean
  active_nofification_mobile_comment: boolean
  active_nofification_mobile_notice: boolean
  active_nofification_mobile_newsletter: boolean
  active_nofification_email_message: boolean
  active_nofification_email_alert: boolean
  active_nofification_email_comment: boolean
  active_nofification_email_notice: boolean
  active_nofification_email_newsletter: boolean
  [key: string]: boolean | string | undefined
}

export function NotificationSettings() {
  const { companyData, loading } = useUserData()
  const [isLoading, setIsLoading] = useState(true)
  const [settings, setSettings] = useState<Settings>({
    active_nofification_mobile_message: false,
    active_nofification_mobile_alert: false,
    active_nofification_mobile_comment: false,
    active_nofification_mobile_notice: false,
    active_nofification_mobile_newsletter: false,
    active_nofification_email_message: false,
    active_nofification_email_alert: false,
    active_nofification_email_comment: false,
    active_nofification_email_notice: false,
    active_nofification_email_newsletter: false,
  })

  const notificationItems = [
    { id: "message", label: "Nouveaux messages" },
    { id: "alert", label: "Alertes" },
    { id: "comment", label: "Commentaires" },
    { id: "notice", label: "Avis" },
    { id: "newsletter", label: "Newsletter" },
  ]

  useEffect(() => {
    setIsLoading(loading)

    if (companyData) {
      setSettings({
        active_nofification_mobile_message: companyData.active_nofification_mobile_message || false,
        active_nofification_mobile_alert: companyData.active_nofification_mobile_alert || false,
        active_nofification_mobile_comment: companyData.active_nofification_mobile_comment || false,
        active_nofification_mobile_notice: companyData.active_nofification_mobile_notice || false,
        active_nofification_mobile_newsletter: companyData.active_nofification_mobile_newsletter || false,
        active_nofification_email_message: companyData.active_nofification_email_message || false,
        active_nofification_email_alert: companyData.active_nofification_email_alert || false,
        active_nofification_email_comment: companyData.active_nofification_email_comment || false,
        active_nofification_email_notice: companyData.active_nofification_email_notice || false,
        active_nofification_email_newsletter: companyData.active_nofification_email_newsletter || false,
      })
    }
  }, [companyData, loading])

  const handleToggle = async (channel: "email" | "mobile", type: string, checked: boolean) => {
    if (!companyData?.id) return

    const settingName = `active_nofification_${channel}_${type}`

    setSettings((prev) => ({
      ...prev,
      [settingName]: checked,
    }))

    const updatedSettings = {
      ...settings,
      [settingName]: checked,
      id: companyData.id,
    }

    try {
      const response = await updateSetting(updatedSettings)

      if (!response.success) {
        setSettings((prev) => ({
          ...prev,
          [settingName]: !checked,
        }))
        console.error("Erreur lors de la mise à jour des paramètres:", response.error)
      }
    } catch (error) {
      setSettings((prev) => ({
        ...prev,
        [settingName]: !checked,
      }))
      console.error("Erreur lors de la mise à jour des paramètres:", error)
    }
  }

  if (isLoading) {
    return (
      <Card className="p-6 mb-6">
        <div className="text-center">Chargement des paramètres...</div>
      </Card>
    )
  }

  return (
    <Card className="p-6 mb-6">
      <h3 className="text-xl font-semibold text-gray-700 mb-4 flex items-center gap-2">
        <Bell className="h-5 w-5" />
        Notifications
      </h3>
      <div className="overflow-x-auto">
        <table className="min-w-full">
          <thead>
            <tr className="border-b">
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
              <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Mobile
              </th>
            </tr>
          </thead>
          <tbody>
            {notificationItems.map((item) => (
              <tr key={item.id} className="border-b hover:bg-gray-50 transition-colors">
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className="text-gray-600">{item.label}</span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-center">
                  <Switch
                    checked={!!settings[`active_nofification_email_${item.id}`]}
                    onCheckedChange={(checked) => handleToggle("email", item.id, checked)}
                  />
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-center">
                  <Switch
                    checked={!!settings[`active_nofification_mobile_${item.id}`]}
                    onCheckedChange={(checked) => handleToggle("mobile", item.id, checked)}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  )
}
