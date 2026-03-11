"use client"

import type React from "react"

import { useState, useEffect } from "react"
import axios from "axios"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { SortSelect } from "@/components/ui/sort-select"
import { SearchInput } from "@/components/ui/search-input"
import { CategoryFilter } from "@/components/ui/category-filter"
import { LoadingContent } from "@/components/ui/loading-content"
import { fetchUserAnnoncesWithApplications } from "@/lib/api"
import { useUserData } from "@/lib/hooks/use-user-data"
import { formatDate, formatRelativeDate } from "@/lib/utils"
import { Users, Calendar, Eye, Edit, Briefcase, GraduationCap, Mail, Phone, MapPin, X, Share2, Clock, FileText, Wifi, Home, Euro, Building2, User, Briefcase as BriefcaseIcon } from "lucide-react"
import Image from "next/image"
import { config } from "@/lib/config"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"

const API_URL = config.API_URL

const getImageUrl = (imagePath: string) => {
  if (!imagePath) return ""
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  let cleanPath = imagePath
  if (!cleanPath.startsWith('/')) {
    cleanPath = '/' + cleanPath
  }
  if (cleanPath.includes("/ads/")) {
    cleanPath = cleanPath.replace("/ads/", "/annonces/")
  }
  return `${config.API_URL}${cleanPath}`
}

export function AdsSection() {
  const { companyData, loading } = useUserData()
  const [sortCriteria, setSortCriteria] = useState<string>("recent")
  const [searchTerm, setSearchTerm] = useState<string>("")
  const [selectedCategory, setSelectedCategory] = useState<string>("")
  const [annonces, setAnnonces] = useState<any[]>([])
  const [selectedAnnonce, setSelectedAnnonce] = useState<any>(null)
  const [isApplicationsModalOpen, setIsApplicationsModalOpen] = useState(false)
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""

  const fetchData = async () => {
    const result = await fetchUserAnnoncesWithApplications(userId || "")
    if (result.success) {
      setAnnonces(result.annonces)
    }
  }

  useEffect(() => {
    const fetchAnnonces = async () => {
      console.log("📋 Chargement des annonces pour userId:", userId)
      const result = await fetchUserAnnoncesWithApplications(userId || "")
      console.log("📋 Résultat fetchUserAnnoncesWithApplications:", result)
      console.log("📋 Nombre d'annonces:", result.annonces?.length)
      console.log("📋 Détail des annonces:", JSON.stringify(result.annonces, null, 2))
      if (result.success) {
        console.log("✅ Annonces chargées:", result.annonces.length, "annonces")
        result.annonces.forEach((annonce: any, index: number) => {
          console.log(`📋 Annonce ${index + 1}:`, {
            id: annonce.id,
            title: annonce.title,
            category: annonce.category,
            date: annonce.date,
            created_at: annonce.created_at,
            dateCreation: annonce.dateCreation,
            allFields: Object.keys(annonce),
            applications: annonce.applications?.length || 0
          })
        })
        setAnnonces(result.annonces)
      } else {
        console.log("❌ Échec du chargement des annonces")
      }
    }
    if (userId) {
      fetchAnnonces()
    }
  }, [userId])

  useEffect(() => {
    const fetchImagesForAnnonces = async () => {
      const annoncesWithImages = await Promise.all(
        annonces.map(async (annonce) => {
          try {
            const response = await axios.post(
              `${API_URL}/ImageAnnonce.php`,
              {
                Method: "readAllByAnnonceId",
                Id: annonce.id,
              },
              {
                headers: {
                  "Content-Type": "application/x-www-form-urlencoded",
                },
              },
            )
            if (response.data.status === "success") {
              const imageUrls = response.data.images?.map((img: any) => img.urlimg) || []
              return { ...annonce, images: imageUrls }
            }
          } catch (error) {
            // ignore error, return annonce without images
          }
          return { ...annonce, images: [] }
        }),
      )
      setAnnonces(annoncesWithImages)
    }

    if (annonces.length > 0 && !annonces[0].images) {
      fetchImagesForAnnonces()
    }
  }, [annonces.length])

  const handleSortChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setSortCriteria(event.target.value)
  }

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value)
  }

  const handleCategoryChange = (category: string) => {
    setSelectedCategory(category)
  }

  const filteredAnnonces = annonces.filter(
    (annonce) =>
      (annonce.category === "emplois" || annonce.category === "formations") &&
      (selectedCategory ? annonce.category === selectedCategory : true) &&
      annonce?.title.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const sortedAnnonces = [...filteredAnnonces].sort((a, b) => {
    switch (sortCriteria) {
      case "recent":
        return new Date(b.created_at || b.date).getTime() - new Date(a.created_at || a.date).getTime()
      case "oldest":
        return new Date(a.created_at || a.date).getTime() - new Date(b.created_at || b.date).getTime()
      default:
        return 0
    }
  })

  if (loading) {
    return <LoadingContent />
  }

  return (
    <>
      <div className="mb-6 flex flex-col md:flex-row gap-4 justify-between items-start md:items-center">
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Briefcase className="h-4 w-4" />
          <span className="font-medium">{sortedAnnonces.length} offre(s) publiée(s)</span>
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
        selectOnly={["emplois", "formations"]}
      />

      {!sortedAnnonces || sortedAnnonces?.length === 0 ? (
        <Card className="border-dashed">
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <div className="rounded-full bg-muted p-4 mb-4">
              <Briefcase className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-semibold mb-2">Aucune offre publiée</h3>
            <p className="text-muted-foreground max-w-sm">
              Vous n'avez pas encore publié d'annonce. Commencez par créer votre première offre d'emploi ou de
              formation.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-1">
          {sortedAnnonces.map((annonce) => {
            const displayPhoto = annonce.images && annonce.images.length > 0 
              ? getImageUrl(annonce.images[0])
              : null
            
            return (
            <Card
              key={annonce.id}
              className="h-full hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 overflow-hidden group cursor-pointer flex flex-col border-2 border-gray-100 hover:border-blue-200"
            >
              {/* Company Logo Header */}
              <div className="p-6 pb-4 border-b bg-gradient-to-br from-blue-50/30 to-white relative">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-16 h-16 border-4 border-white shadow-lg ring-2 ring-blue-100 rounded-full overflow-hidden bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                    {displayPhoto ? (
                      <Image
                        src={displayPhoto}
                        alt={annonce.title}
                        width={64}
                        height={64}
                        className="object-cover w-full h-full"
                      />
                    ) : annonce.category === "emplois" ? (
                      <Briefcase className="w-8 h-8 text-white" />
                    ) : (
                      <GraduationCap className="w-8 h-8 text-white" />
                    )}
                  </div>
                  <div className="flex gap-1">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 rounded-full hover:bg-white"
                    >
                      <Share2 className="w-4 h-4 text-gray-400" />
                    </Button>
                  </div>
                </div>

                <h3 className="font-bold text-xl mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors text-gray-900">
                  {annonce.title}
                </h3>
                <div className="flex items-center gap-2">
                  <p className="text-sm text-gray-700 font-semibold">
                    {companyData?.nomsociete || companyData?.pseudo || "Entreprise"}
                  </p>
                  <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs">
                    Pro
                  </Badge>
                </div>
              </div>

              {/* Content */}
              <div className="p-6 flex-1 flex flex-col">
                {/* Key Info - Badges */}
                <div className="flex flex-wrap items-center gap-2 mb-4">
                  {annonce.contractType && (
                    <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                      <FileText className="w-3 h-3 mr-1 inline" />
                      Intérim
                    </Badge>
                  )}
                  {annonce.address && (
                    <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                      <MapPin className="w-3 h-3 mr-1 inline" />
                      Metz
                    </Badge>
                  )}
                  <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                    Sans diplôme
                  </Badge>
                  <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                    <Clock className="w-3 h-3 mr-1 inline" />
                    Temps plein
                  </Badge>
                  <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                    <Home className="w-3 h-3 mr-1 inline" />
                    Présentiel uniquement
                  </Badge>
                  <Badge className="bg-green-50 text-green-700 border-green-200 text-xs">
                    <Euro className="w-3 h-3 mr-1 inline" />
                    Selon profil
                  </Badge>
                </div>

                {/* Description */}
                <p className="text-sm text-gray-700 mb-4 line-clamp-3 flex-1 leading-relaxed">
                  {annonce.description?.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim() || ''}
                </p>

                {/* Avantages */}
                {annonce.applications && annonce.applications.length > 0 && (
                  <div className="mb-4">
                    <p className="text-xs font-semibold text-gray-900 mb-2 flex items-center gap-1">
                      <span className="w-0.5 h-3 bg-blue-500 rounded"></span>
                      Avantages
                    </p>
                    <div className="flex flex-wrap gap-1.5">
                      <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200 text-xs px-2 py-0.5">
                        Primes
                      </Badge>
                      <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200 text-xs px-2 py-0.5">
                        Heures supp. majorée
                      </Badge>
                    </div>
                  </div>
                )}

                {/* Footer */}
                <div className="flex items-center justify-between pt-4 border-t mt-auto">
                  {annonce.created_at && (
                    <div className="flex items-center gap-1.5 text-xs text-gray-600">
                      <Clock className="w-3.5 h-3.5" />
                      <span>Il y a 2 mois</span>
                    </div>
                  )}
                  <Button
                    size="sm"
                    className="bg-blue-500 hover:bg-blue-600 text-white text-xs px-4"
                    onClick={() => {
                      if (annonce.applications && annonce.applications.length > 0) {
                        setSelectedAnnonce(annonce)
                        setIsApplicationsModalOpen(true)
                      }
                    }}
                  >
                    {annonce.applications && annonce.applications.length > 0 
                      ? `Voir candidatures (${annonce.applications.length})`
                      : "Voir l'offre"
                    }
                  </Button>
                </div>
              </div>
            </Card>
            )
          })}
        </div>
      )}

      {/* Modal des candidatures */}
      <Dialog open={isApplicationsModalOpen} onOpenChange={setIsApplicationsModalOpen}>
        <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Users className="h-5 w-5 text-primary" />
              Candidatures pour : {selectedAnnonce?.title}
            </DialogTitle>
          </DialogHeader>
          <div className="space-y-4 mt-4">
            {selectedAnnonce?.applications?.map((application: any, index: number) => (
              <Card key={index} className="overflow-hidden">
                <CardContent className="p-6">
                  <div className="flex items-start gap-4">
                    <div className="w-16 h-16 bg-gradient-to-br from-primary to-primary/60 rounded-full flex items-center justify-center shadow-lg flex-shrink-0">
                      <span className="text-primary-foreground font-bold text-xl">
                        {application.userInfo?.pseudo?.[0] || application.userInfo?.nomsociete?.[0] || "?"}
                      </span>
                    </div>
                    <div className="flex-1 space-y-3">
                      <div className="flex items-start justify-between">
                        <div>
                          <h3 className="font-semibold text-lg">
                            {application.userInfo?.pseudo || application.userInfo?.nomsociete || "Utilisateur"}
                          </h3>
                          <Badge variant="outline" className="capitalize mt-1">
                            {application.userInfo?.profiletype || "particulier"}
                          </Badge>
                        </div>
                        <div className="text-right">
                          <p className="text-sm text-muted-foreground">
                            Candidature envoyée
                          </p>
                          <p className="text-sm font-medium">
                            {formatRelativeDate(application.application?.created_at)}
                          </p>
                        </div>
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3 pt-3 border-t">
                        {application.userInfo?.telephone && (
                          <div className="flex items-center gap-2 text-sm">
                            <Phone className="h-4 w-4 text-muted-foreground" />
                            <a href={`tel:${application.userInfo.telephone}`} className="hover:text-primary">
                              {application.userInfo.telephone}
                            </a>
                          </div>
                        )}
                        {application.userInfo?.ville && (
                          <div className="flex items-center gap-2 text-sm">
                            <MapPin className="h-4 w-4 text-muted-foreground" />
                            <span>{application.userInfo.ville}</span>
                          </div>
                        )}
                      </div>

                      {application.application?.message && (
                        <div className="mt-4 p-4 bg-muted/30 rounded-lg">
                          <p className="text-sm font-medium mb-2">Message de motivation :</p>
                          <p className="text-sm text-muted-foreground">{application.application.message}</p>
                        </div>
                      )}

                      {application.application?.cv_url && (
                        <div className="mt-4">
                          <Button variant="outline" size="sm" asChild>
                            <a href={`${API_URL}${application.application.cv_url}`} target="_blank" rel="noopener noreferrer">
                              Télécharger le CV
                            </a>
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}
