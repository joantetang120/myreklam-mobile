"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import { motion } from "framer-motion"
import {
  Search,
  Bell,
  Mail,
  Trash2,
  ExternalLink,
  Calendar,
  Tag,
  Briefcase,
  GraduationCap,
  PartyPopper,
  MessageSquare,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useToast } from "@/hooks/use-toast"
import {
  fetchSavedSearches,
  deleteSavedSearch,
  toggleSearchNotifications,
  type SavedSearch,
} from "@/lib/saved-searches"

const categoryIcons = {
  bons_plans: Tag,
  emplois: Briefcase,
  formations: GraduationCap,
  evenements: PartyPopper,
  demandes: MessageSquare,
}

const categoryLabels = {
  bons_plans: "Bons plans",
  emplois: "Offres d'emploi",
  formations: "Formations",
  evenements: "Événements",
  demandes: "Demandes",
}

const categoryColors = {
  bons_plans: "bg-green-100 text-green-700 border-green-200",
  emplois: "bg-blue-100 text-blue-700 border-blue-200",
  formations: "bg-purple-100 text-purple-700 border-purple-200",
  evenements: "bg-orange-100 text-orange-700 border-orange-200",
  demandes: "bg-pink-100 text-pink-700 border-pink-200",
}

export default function SavedSearchesPage() {
  const router = useRouter()
  const { toast } = useToast()
  const [savedSearches, setSavedSearches] = useState<SavedSearch[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [sortBy, setSortBy] = useState<"date" | "new-results">("date")

  useEffect(() => {
    loadSavedSearches()
  }, [])

  const loadSavedSearches = async () => {
    const userId = localStorage.getItem("profileId")
    if (!userId) {
      router.push("/")
      return
    }

    setIsLoading(true)
    const result = await fetchSavedSearches(userId)
    if (result.success && result.searches) {
      setSavedSearches(result.searches)
    }
    setIsLoading(false)
  }

  const handleDelete = async (searchId: string) => {
    const result = await deleteSavedSearch(searchId)
    if (result.success) {
      toast({ title: "Recherche supprimée", description: "Votre recherche a été supprimée avec succès." })
      setSavedSearches((prev) => prev.filter((s) => s.id !== searchId))
    } else {
      toast({ title: "Erreur", description: result.error, variant: "destructive" })
    }
  }

  const handleToggleNotifications = async (searchId: string, currentState: boolean) => {
    const result = await toggleSearchNotifications(searchId, !currentState)
    if (result.success) {
      toast({
        title: !currentState ? "Notifications activées" : "Notifications désactivées",
        description: !currentState
          ? "Vous recevrez des alertes pour cette recherche."
          : "Vous ne recevrez plus d'alertes pour cette recherche.",
      })
      setSavedSearches((prev) =>
        prev.map((s) => (s.id === searchId ? { ...s, notification_enabled: !currentState } : s)),
      )
    } else {
      toast({ title: "Erreur", description: result.error, variant: "destructive" })
    }
  }

  const formatSearchCriteria = (search: SavedSearch) => {
    const criteria: string[] = []

    if (search.search_query) criteria.push(`"${search.search_query}"`)
    if (search.location) criteria.push(`📍 ${search.location}`)
    if (search.category && search.category !== "all") {
      criteria.push(categoryLabels[search.category as keyof typeof categoryLabels] || search.category)
    }

    return criteria.length > 0 ? criteria.join(" • ") : "Tous les résultats"
  }

  const getCategoryIcon = (category: string) => {
    const Icon = categoryIcons[category as keyof typeof categoryIcons] || Search
    return Icon
  }

  const getCategoryColor = (category: string) => {
    return categoryColors[category as keyof typeof categoryColors] || "bg-gray-100 text-gray-700 border-gray-200"
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-500 mx-auto mb-4" />
          <p className="text-gray-600">Chargement de vos recherches...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b">
        <div className="container mx-auto px-4 py-6 sm:py-8 max-w-5xl">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
            <div className="flex-1">
              <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-2">Mes recherches sauvegardées</h1>
              <p className="text-sm sm:text-base text-gray-600">
                Gérez vos recherches et recevez des alertes pour les nouvelles annonces correspondantes
              </p>
            </div>
            <Badge variant="outline" className="text-base sm:text-lg px-3 sm:px-4 py-1.5 sm:py-2 w-fit">
              {savedSearches.length} recherche{savedSearches.length > 1 ? "s" : ""}
            </Badge>
          </div>

          {/* Sort options */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
            <Button
              variant={sortBy === "date" ? "default" : "outline"}
              size="sm"
              onClick={() => setSortBy("date")}
              className="gap-2 w-full sm:w-auto"
            >
              <Calendar className="w-4 h-4" />
              Tri : Date
            </Button>
            <Button
              variant={sortBy === "new-results" ? "default" : "outline"}
              size="sm"
              onClick={() => setSortBy("new-results")}
              className="gap-2 w-full sm:w-auto"
            >
              <Bell className="w-4 h-4" />
              Tri : Nouveaux résultats
            </Button>
          </div>
        </div>
      </div>

      {/* Info banner */}
      <div className="bg-blue-50 border-b border-blue-100">
        <div className="container mx-auto px-4 py-4 max-w-5xl">
          <div className="flex items-start gap-3">
            <Bell className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-sm text-blue-900 font-medium">Triez vos recherches par nouveaux résultats !</p>
              <p className="text-sm text-blue-700">
                Désormais, vous pouvez afficher vos recherches sauvegardées comme vous préférez : par date ou par
                nouveaux résultats.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Saved searches list */}
      <div className="container mx-auto px-4 py-8 max-w-5xl">
        {savedSearches.length === 0 ? (
          <Card className="p-12 text-center">
            <Search className="w-16 h-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-700 mb-2">Aucune recherche sauvegardée</h3>
            <p className="text-gray-500 mb-6">
              Commencez par effectuer une recherche et cliquez sur "Sauvegarder cette recherche" pour recevoir des
              alertes.
            </p>
            <Button onClick={() => router.push("/")} className="bg-blue-500 hover:bg-blue-600">
              Parcourir les annonces
            </Button>
          </Card>
        ) : (
          <div className="space-y-4">
            {savedSearches.map((search, index) => {
              const CategoryIcon = getCategoryIcon(search.category || "")
              const categoryColor = getCategoryColor(search.category || "")

              return (
                <motion.div
                  key={search.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.05 }}
                >
                  <Card className="p-4 sm:p-6 hover:shadow-lg transition-shadow">
                    <div className="flex flex-col sm:flex-row items-start gap-4">
                      {/* Category icon */}
                      <div className={`p-3 rounded-lg ${categoryColor}`}>
                        <CategoryIcon className="w-6 h-6" />
                      </div>

                      {/* Content */}
                      <div className="flex-1 min-w-0">
                        {/* Title and category */}
                        <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2 sm:gap-0 mb-2">
                          <div className="flex-1">
                            <h3 className="text-base sm:text-lg font-bold text-gray-900 mb-1">{search.search_name}</h3>
                            <p className="text-xs sm:text-sm text-gray-600 break-words">{formatSearchCriteria(search)}</p>
                          </div>
                          <div className="flex items-center gap-2 sm:ml-4">
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => handleDelete(search.id)}
                              className="text-red-500 hover:text-red-700 hover:bg-red-50"
                              title="Supprimer"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>

                        {/* Date */}
                        <p className="text-xs text-gray-500 mb-4">
                          Créée le {new Date(search.created_at).toLocaleDateString("fr-FR")}
                        </p>

                        {/* Actions */}
                        <div className="flex flex-col sm:flex-row items-start sm:items-center sm:justify-between gap-4 pt-4 border-t">
                          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 sm:gap-6 w-full sm:w-auto">
                            {/* Bell notification toggle */}
                            <div className="flex items-center gap-3">
                              <button
                                onClick={() => handleToggleNotifications(search.id, search.notification_enabled)}
                                className={`p-2 rounded-full transition-colors ${
                                  search.notification_enabled
                                    ? "bg-blue-500 text-white hover:bg-blue-600"
                                    : "bg-gray-100 text-gray-400 hover:bg-gray-200"
                                }`}
                                title={
                                  search.notification_enabled
                                    ? "Désactiver les notifications"
                                    : "Activer les notifications"
                                }
                              >
                                <Bell className="w-4 h-4" />
                              </button>
                              <span className="text-sm text-gray-600">
                                {search.notification_enabled ? "Alertes activées" : "Alertes désactivées"}
                              </span>
                            </div>

                            {/* Email notification (placeholder) */}
                            <button
                              className="p-2 rounded-full bg-gray-100 text-gray-400 hover:bg-gray-200 transition-colors"
                              title="Notifications par email (bientôt disponible)"
                            >
                              <Mail className="w-4 h-4" />
                            </button>
                          </div>

                          {/* View results button */}
                          <Link href={search.search_url || "/"} className="w-full sm:w-auto">
                            <Button variant="outline" className="gap-2 bg-transparent w-full sm:w-auto">
                              <ExternalLink className="w-4 h-4" />
                              Voir les résultats
                            </Button>
                          </Link>
                        </div>
                      </div>
                    </div>
                  </Card>
                </motion.div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
