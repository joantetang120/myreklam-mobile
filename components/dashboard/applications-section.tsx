"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { SortSelect } from "@/components/ui/sort-select"
import { SearchInput } from "@/components/ui/search-input"
import { CategoryFilter } from "@/components/ui/category-filter"
import { LoadingContent } from "@/components/ui/loading-content"
import { getApplicationAdsByInterestedUserId } from "@/lib/api"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { formatDate } from "@/lib/utils"
import { Calendar, ExternalLink, Briefcase, GraduationCap, Send, MessageCircle, Trash2, MapPin, Clock, User, Building2 } from "lucide-react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import axios from "axios"
import { config } from "@/lib/config"
import { startConversation } from "@/lib/api"

interface ApplicationsSectionProps {
  categoryFilterSelectOnly?: string[]
}

export function ApplicationsSection({
  categoryFilterSelectOnly = ["emplois", "formations"],
}: ApplicationsSectionProps) {
  const [annonces, setAnnonces] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [sortCriteria, setSortCriteria] = useState<string>("recent")
  const [searchTerm, setSearchTerm] = useState<string>("")
  const [selectedCategory, setSelectedCategory] = useState<string>("")
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [contactingId, setContactingId] = useState<string | null>(null)
  const router = useRouter()

  useEffect(() => {
    // Ne pas exécuter côté serveur
    if (typeof window === "undefined") {
      setLoading(false)
      return
    }
    fetchData()
  }, [])

  const fetchData = async () => {
    if (typeof window === "undefined") {
      setLoading(false)
      return
    }
    
    const userId = localStorage.getItem("profileId") || ""
    if (!userId) {
      setLoading(false)
      return
    }

    try {
      console.log("[v0] Fetching applications for user:", userId)
      const applications = await getApplicationAdsByInterestedUserId(userId)
      console.log("[v0] Applications fetched:", applications?.length || 0)

      let ads = applications
      if (selectedCategory.length > 0) {
        ads = applications?.filter(
          (annonce) =>
            annonce?.title?.toLowerCase().includes(searchTerm.toLowerCase()) &&
            (selectedCategory ? categoryFilterSelectOnly.includes(annonce?.category) : true),
        )
      }

      setAnnonces(ads || [])
    } catch (err: any) {
      console.error("[v0] Error in fetchData:", err)
      setAnnonces([])
    } finally {
      setLoading(false)
    }
  }

  const handleSortChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSortCriteria(event.target.value)
  }

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value)
  }

  const handleCategoryChange = (category: string) => {
    setSelectedCategory(category)
  }

  const handleContact = async (announcementId: string) => {
    if (typeof window === "undefined") return
    
    const userId = localStorage.getItem("profileId") || ""
    if (!userId) {
      router.push("/login-required")
      return
    }

    setContactingId(announcementId)
    try {
      // First, fetch the announcement details to get the author user ID
      const announcement = await fetchAnnouncementDetail(announcementId)
      
      if (!announcement || !announcement.userId) {
        toast.error("Impossible de récupérer les informations de l'annonce")
        setContactingId(null)
        return
      }

      // Now create conversation with the author user ID
      const conversationId = await startConversation(announcement.userId)

      if (!conversationId) {
        toast.error("Erreur lors du démarrage de la conversation")
        return
      }

      router.push(`/messages?action=conversation&conversationId=${conversationId}`)
      toast.success("Conversation démarrée")
    } catch (error) {
      console.error("Erreur lors du contact:", error)
      toast.error("Erreur lors du démarrage de la conversation")
    } finally {
      setContactingId(null)
    }
  }

  const handleDeleteApplication = async (applicationId: string) => {
    if (typeof window === "undefined") return
    
    const userId = localStorage.getItem("profileId") || ""
    if (!userId) {
      return
    }

    if (!confirm("Êtes-vous sûr de vouloir retirer cette candidature ?")) {
      return
    }

    setDeletingId(applicationId)
    try {
      const response = await axios.post(
        `${config.API_URL}/DocumentFiles.php`,
        {
          Method: "delete_application",
          user_id: userId,
          application_id: applicationId,
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        }
      )

      if (response.data.status === "success") {
        toast.success("Candidature retirée avec succès")
        // Recharger les candidatures
        fetchData()
      } else {
        toast.error(response.data.message || "Erreur lors de la suppression")
      }
    } catch (error) {
      console.error("Erreur lors de la suppression:", error)
      toast.error("Erreur lors de la suppression de la candidature")
    } finally {
      setDeletingId(null)
    }
  }

  if (loading) {
    return <LoadingContent />
  }

  const filteredAnnonces = annonces?.filter(
    (annonce) =>
      annonce?.title?.toLowerCase().includes(searchTerm.toLowerCase()) &&
      (selectedCategory ? annonce?.category === selectedCategory : true),
  )

  const sortedAnnonces = [...filteredAnnonces].sort((a, b) => {
    switch (sortCriteria) {
      case "recent":
        return new Date(b.createdat || b.date).getTime() - new Date(a.createdat || a.date).getTime()
      case "oldest":
        return new Date(a.createdat || a.date).getTime() - new Date(b.createdat || b.date).getTime()
      default:
        return 0
    }
  })

  return (
    <>
      <div className="mb-6 flex flex-col md:flex-row gap-4 justify-between items-start md:items-center">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Send className="h-4 w-4" />
          <span className="font-medium">{sortedAnnonces.length} candidature(s) envoyée(s)</span>
        </div>
        <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
          <SearchInput searchTerm={searchTerm} onSearchChange={handleSearchChange} />
          <SortSelect sortCriteria={sortCriteria} onSortChange={handleSortChange} />
        </div>
      </div>

      <CategoryFilter
        showAll={true}
        selectedCategory={selectedCategory}
        onCategoryChange={handleCategoryChange}
        selectOnly={categoryFilterSelectOnly}
      />

      {!sortedAnnonces || sortedAnnonces?.length === 0 ? (
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <div className="rounded-full bg-muted p-4 mb-4">
              <Send className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Aucune candidature</h3>
            <p className="text-muted-foreground max-w-sm">
              Vous n'avez pas encore envoyé de candidature. Explorez les offres disponibles et postulez dès maintenant.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {sortedAnnonces.map((annonce) => {
            const getTimeAgo = (date: string) => {
              const now = new Date()
              const past = new Date(date)
              const diffInHours = Math.floor((now.getTime() - past.getTime()) / (1000 * 60 * 60))
              if (diffInHours < 1) return "Il y a quelques minutes"
              if (diffInHours < 24) return `${diffInHours}h`
              const days = Math.floor(diffInHours / 24)
              if (days < 30) return `Il y a ${days} jour${days > 1 ? 's' : ''}`
              const months = Math.floor(days / 30)
              return `Il y a ${months} mois`
            }

            const getCleanDescription = () => {
              if (!annonce.description) return ""
              const cleanText = annonce.description.replace(/<[^>]*>/g, ' ')
              return cleanText.replace(/\s+/g, ' ').trim()
            }

            const isProfessional = annonce.companyData?.profiletype === "professionnel"
            const organizationName = isProfessional 
              ? (annonce.companyData?.nomsociete || "Entreprise")
              : (annonce.companyData?.pseudo || "Particulier")

            return (
              <Card
                key={annonce.id}
                className="group hover:shadow-xl transition-all duration-300 overflow-hidden cursor-pointer border-2 hover:border-purple-200"
              >
                <div className="p-4 pb-0">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-shrink-0">
                      <div className="w-16 h-16 rounded-lg overflow-hidden bg-gradient-to-br from-purple-100 to-purple-50 flex items-center justify-center">
                        {annonce.category === "emplois" ? (
                          <Briefcase className="w-8 h-8 text-purple-600" />
                        ) : (
                          <GraduationCap className="w-8 h-8 text-purple-600" />
                        )}
                      </div>
                    </div>
                    <Badge className="bg-blue-100 text-blue-700 border-blue-200">
                      {isProfessional ? "Pro" : "Particulier"}
                    </Badge>
                  </div>

                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-sm font-semibold text-gray-900">{organizationName}</span>
                  </div>

                  <h3 className="text-lg font-bold mb-3 line-clamp-2 text-purple-600 group-hover:text-purple-700 transition-colors">
                    {annonce.title}
                  </h3>

                  <p className="text-sm text-gray-600 line-clamp-2 mb-4 leading-relaxed">
                    {getCleanDescription()}
                  </p>

                  <div className="space-y-2 text-sm mb-4">
                    <div className="flex items-center gap-2 text-gray-600">
                      <Clock className="w-4 h-4 flex-shrink-0" />
                      <span>{getTimeAgo(annonce.created_at || annonce.createdat || annonce.date)}</span>
                    </div>
                    {annonce.location && (
                      <div className="flex items-center gap-2 text-gray-600">
                        <MapPin className="w-4 h-4 flex-shrink-0" />
                        <span className="truncate">{annonce.location}</span>
                      </div>
                    )}
                    <div className="flex items-center gap-2">
                      <User className="w-4 h-4 flex-shrink-0 text-gray-600" />
                      <div className="flex flex-wrap gap-1.5">
                        {annonce.category === "emplois" ? (
                          <Badge variant="outline" className="text-xs bg-blue-50 text-blue-700 border-blue-200">
                            Offre d'emploi
                          </Badge>
                        ) : (
                          <Badge variant="outline" className="text-xs bg-blue-50 text-blue-700 border-blue-200">
                            Formation
                          </Badge>
                        )}
                      </div>
                    </div>
                  </div>

                  <Badge variant="outline" className="text-xs bg-purple-50 text-purple-700 border-purple-200 mb-4">
                    {annonce.category === "emplois" ? "Emploi" : "Formation"}
                  </Badge>
                </div>

                <div className="px-4 pb-4 pt-2 border-t bg-gray-50/50">
                  <div className="flex flex-col gap-2">
                    <div className="flex items-center justify-between text-xs text-gray-500 mb-2">
                      <div className="flex items-center gap-1">
                        <Send className="w-3 h-3" />
                        <span>Candidature envoyée</span>
                      </div>
                      <span>{getTimeAgo(annonce.created_at || annonce.createdat || annonce.date)}</span>
                    </div>
                    <Link 
                      href={
                        annonce.category === "emplois" 
                          ? `/announcements/jobs/${annonce.ad_id || annonce.id}`
                          : `/announcements/trainings/${annonce.ad_id || annonce.id}`
                      }
                      target="_blank"
                      className="w-full"
                    >
                      <Button 
                        className="w-full bg-gradient-to-r from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white"
                        size="sm"
                      >
                        Voir {annonce.category === "emplois" ? "l'offre" : "la formation"}
                      </Button>
                    </Link>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        className="flex-1 gap-1 border-blue-200 text-blue-700 hover:bg-blue-50 text-xs"
                        onClick={() => handleContact(annonce.ad_id || annonce.id)}
                        disabled={contactingId === (annonce.ad_id || annonce.id)}
                      >
                        {contactingId === (annonce.ad_id || annonce.id) ? (
                          <span className="animate-spin">⏳</span>
                        ) : (
                          <MessageCircle className="h-3 w-3" />
                        )}
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="flex-1 gap-1 border-red-200 text-red-700 hover:bg-red-50 text-xs"
                        onClick={() => handleDeleteApplication(annonce.id)}
                        disabled={deletingId === annonce.id}
                      >
                        {deletingId === annonce.id ? (
                          <span className="animate-spin">⏳</span>
                        ) : (
                          <Trash2 className="h-3 w-3" />
                        )}
                      </Button>
                    </div>
                  </div>
                </div>
              </Card>
            )
          })}
        </div>
      )}
    </>
  )
}
