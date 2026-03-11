"use client"

import { useEffect, useState, Suspense } from "react"
import { useSearchParams, useRouter } from "next/navigation"
import Image from "next/image"
import Link from "next/link"
import { fetchPublisherData, fetchUserAnnonces, getUserSubscriptions, hasActiveSubscription, checkUserSubscription } from "@/lib/api"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { UserDocumentsSection } from "@/components/user-documents-section"
import { 
  ProfileDealCard, 
  ProfileJobCard, 
  ProfileTrainingCard, 
  ProfileEventCard, 
  ProfileInquiryCard 
} from "@/components/profile/announcement-cards"
import {
  MapPin,
  Phone,
  Mail,
  Globe,
  Facebook,
  Instagram,
  Linkedin,
  Youtube,
  Twitter,
  Star,
  MessageCircle,
  Eye,
  ChevronLeft,
  ChevronRight,
  ExternalLink,
  Newspaper,
  Briefcase,
  FileText,
  User,
  Heart,
  Users,
} from "lucide-react"
import { VerifiedBadge } from "@/components/dashboard/verified-badge"
import { toast } from "sonner"
import { TikTokIcon, SnapchatIcon, XIcon } from "@/components/social-icons"
import { useAmbassadorStatus } from "@/hooks/use-ambassador-status"
import { ContactModal } from "@/components/contact-modal"
import { startConversation, createUserReview, getUserReviews, sendNotification } from "@/lib/api"
import { useAuthStore } from "@/lib/auth-store"
import { config } from "@/lib/config"

function PublicProfileContent() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const userId = searchParams.get("Id")

  const [loading, setLoading] = useState(true)
  const [userData, setUserData] = useState<any>(null)
  const [announcements, setAnnouncements] = useState<any[]>([])
  const [subscriptions, setSubscriptions] = useState<any[]>([])
  const [currentPage, setCurrentPage] = useState(1)
  const [activeTab, setActiveTab] = useState("presentation")
  const [selectedCategory, setSelectedCategory] = useState<string>("all")
  const itemsPerPage = 9

  // Fonction pour gérer le changement d'onglet avec scroll
  const handleTabChange = (value: string) => {
    setActiveTab(value)
    if (value === "avis") {
      // Scroll vers la section des avis après un court délai pour laisser le temps au contenu de se charger
      setTimeout(() => {
        const avisSection = document.getElementById("avis-section")
        if (avisSection) {
          avisSection.scrollIntoView({ behavior: "smooth", block: "start" })
        }
      }, 100)
    }
  }

  const { activeStatus } = useAmbassadorStatus(userId || "")
  const { limits, isPremium, loading: subscriptionLoading } = useSubscriptionLimits()

  const [showContactModal, setShowContactModal] = useState(false)
  
  // Récupérer l'ID de l'utilisateur connecté
  const currentUserId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
  const currentUserProfileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null
  const [currentUserData, setCurrentUserData] = useState<any>(null)
  const [currentUserHasSubscription, setCurrentUserHasSubscription] = useState(false)
  const [profileOwnerHasSubscription, setProfileOwnerHasSubscription] = useState(false)
  
  // États pour le formulaire d'avis
  const [reviewRating, setReviewRating] = useState(0)
  const [reviewComment, setReviewComment] = useState("")
  const [hoverRating, setHoverRating] = useState(0)
  const [reviews, setReviews] = useState<any[]>([])
  const [reviewsLoading, setReviewsLoading] = useState(false)

  // Récupérer les données de l'utilisateur connecté
  useEffect(() => {
    const fetchCurrentUserData = async () => {
      if (currentUserId) {
        const result = await fetchPublisherData(currentUserId)
        const hasSubscription = await checkUserSubscription(currentUserId)
        
        if (result.success) {
          setCurrentUserData(result.userData)
          setCurrentUserHasSubscription(hasSubscription)
          
          console.log("👤 Utilisateur connecté - TOUTES LES DONNÉES:", result.userData)
          console.log("👤 CompanyData:", result.userData?.companyData)
          console.log("👤 A un abonnement actif (via Abonnement.php):", hasSubscription)
          console.log("👤 Utilisateur connecté:", {
            profiletype: result.userData?.companyData?.profiletype,
            hasActiveSubscription: hasSubscription,
            userid: currentUserId
          })
          console.log("📋 Condition pour afficher l'onglet documents:", {
            isProfessionnel: result.userData?.companyData?.profiletype === "professionnel",
            hasActiveSubscription: hasSubscription,
            shouldShowDocumentsTab: result.userData?.companyData?.profiletype === "professionnel" && hasSubscription
          })
        }
      }
    }
    fetchCurrentUserData()
  }, [currentUserId])

  useEffect(() => {
    if (!userId) {
      toast.error("Identifiant utilisateur manquant")
      router.push("/")
      return
    }

    // Attendre que les abonnements soient chargés
    if (subscriptionLoading) {
      return
    }

    // Vérifier si l'utilisateur peut accéder aux profils publics
    if (currentUserProfileType === "professionnel" && !isPremium) {
      toast.error("Vous devez avoir un abonnement premium pour accéder aux profils publics")
      router.push("/subscription")
      return
    }

    const fetchData = async () => {
      try {
        setLoading(true)

        const [publisherResult, annoncesResult, subscriptionsResult] = await Promise.all([
          fetchPublisherData(userId),
          fetchUserAnnonces(userId),
          getUserSubscriptions(userId),
        ])
        
        // Charger les avis
        loadReviews()

        if (publisherResult.success) {
          setUserData(publisherResult.userData)
          // Vérifier l'abonnement du profil visité
          const profileHasSubscription = await checkUserSubscription(userId)
          setProfileOwnerHasSubscription(profileHasSubscription)
          
          // Debug: Vérifier les valeurs des permissions
          console.log("🔍 Permissions de publication:", {
            publishtelephone: publisherResult.userData?.companyData?.publishtelephone,
            publishemail: publisherResult.userData?.companyData?.publishemail,
            publishadresse: publisherResult.userData?.companyData?.publishadresse,
            telephone: publisherResult.userData?.companyData?.telephone,
            email: publisherResult.userData?.email,
          })
          console.log("👁️ Profil visité:", {
            profiletype: publisherResult.userData?.companyData?.profiletype,
            isParticulier: publisherResult.userData?.companyData?.profiletype === "particulier",
            userid: userId,
            hasSubscription: profileHasSubscription
          })
        }

        if (annoncesResult.success) {
          // Afficher toutes les annonces de l'utilisateur
          setAnnouncements(annoncesResult.annonces)
        }

        setSubscriptions(subscriptionsResult)
      } catch (error) {
        console.error("Error fetching profile data:", error)
        toast.error("Erreur lors du chargement du profil")
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [userId, subscriptionLoading, isPremium, currentUserProfileType, router])

  const companyData = userData?.companyData
  const isProf = companyData?.profiletype === "professionnel"
  const displayName = isProf ? companyData?.nomsociete : companyData?.pseudo
  const isVerified = hasActiveSubscription(subscriptions)

  let bannerUrl = companyData?.bannerUrl || userData?.bannerData?.urlPhoto
  // Corriger l'URL de la bannière si elle contient test.myreklam.fr
  if (bannerUrl && bannerUrl.includes('test.myreklam.fr')) {
    bannerUrl = bannerUrl.replace('https://test.myreklam.fr', '').replace('http://test.myreklam.fr', '')
  }
  
  console.log("🖼️ Bannière profil public:", { 
    bannerUrl, 
    companyDataBannerUrl: companyData?.bannerUrl,
    userDataBannerUrl: userData?.bannerData?.urlPhoto 
  })
  
  const newsList = userData?.newsData || []
  const mediaGallery = userData?.imageDiapoData?.media || []
  const presentation = companyData?.presentation

  // Debug: Vérifier la configuration de l'API
  console.log("⚙️ CONFIG CHECK:", {
    API_URL: config.API_URL,
    env: process.env.NEXT_PUBLIC_API_BASE_URL
  })

  // Debug: Vérifier les données des médias
  console.log("📸 Media Gallery Data:", {
    imageDiapoData: userData?.imageDiapoData,
    mediaGallery,
    mediaCount: mediaGallery.length,
    firstMedia: mediaGallery[0]
  })

  // Filtrage par catégorie
  const filteredAnnouncements = selectedCategory === "all" 
    ? announcements 
    : announcements.filter(a => a.category === selectedCategory)

  // Pagination
  const totalPages = Math.ceil(filteredAnnouncements.length / itemsPerPage)
  const paginatedAnnouncements = filteredAnnouncements.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)

  const getCategoryPath = (category: string) => {
    const categoryMap: Record<string, string> = {
      bons_plans: "deals",
      offres_emploi: "jobs",
      formations: "trainings",
      evenements: "events",
      demandes: "inquiries",
    }
    return categoryMap[category] || "deals"
  }

  const getCategoryLabel = (category: string) => {
    const labels: Record<string, string> = {
      bons_plans: "Bons plans",
      offres_emploi: "Offres d'emploi",
      formations: "Formations",
      evenements: "Événements",
      demandes: "Demandes",
    }
    return labels[category] || category
  }

  const loadReviews = async () => {
    if (!userId) return
    
    setReviewsLoading(true)
    try {
      const response = await getUserReviews(userId)
      console.log("📋 Avis récupérés:", response)
      
      if (response.status === "success" && response.reviews) {
        setReviews(response.reviews)
      } else {
        setReviews([])
      }
    } catch (error) {
      console.error("Erreur lors du chargement des avis:", error)
      setReviews([])
    } finally {
      setReviewsLoading(false)
    }
  }

  // Calculer la moyenne des notes
  const getAverageRating = () => {
    if (reviews.length === 0) return 0
    const sum = reviews.reduce((acc: number, review: any) => acc + (Number(review.rating) || 0), 0)
    return (sum / reviews.length).toFixed(1)
  }

  // Vérifier si l'utilisateur connecté a déjà laissé un avis
  const hasUserAlreadyReviewed = () => {
    if (!currentUserId) return false
    return reviews.some((review: any) => 
      review.author_id === currentUserId || 
      review.authorid === currentUserId ||
      review.authorId === currentUserId
    )
  }

  const handleSubmitReview = async () => {
    if (reviewRating === 0) {
      toast.error("Veuillez sélectionner une note")
      return
    }
    if (!reviewComment.trim()) {
      toast.error("Veuillez écrire un commentaire")
      return
    }
    if (!currentUserId || !userId) {
      toast.error("Erreur d'authentification")
      return
    }

    try {
      console.log("📝 Envoi de l'avis:", {
        userId,
        authorId: currentUserId,
        rating: reviewRating,
        comment: reviewComment
      })

      const response = await createUserReview(
        userId, // userId = profil visité
        currentUserId, // authorId = utilisateur connecté
        reviewRating,
        reviewComment
      )

      console.log("📬 Réponse API:", response)

      if (response.status === "success") {
        toast.success("Avis publié avec succès !")
        setReviewRating(0)
        setReviewComment("")
        
        // Envoyer une notification au propriétaire du profil
        try {
          await sendNotification(
            userId, // receiverId = propriétaire du profil
            currentUserId, // senderId = auteur de l'avis
            "review", // type
            `${currentUserData?.companyData?.pseudo || currentUserData?.companyData?.nomsociete || "Un utilisateur"} a déposé un avis sur votre profil`, // message
            null, // announcementId
            null // conversationId
          )
          console.log("📬 Notification envoyée au propriétaire du profil")
        } catch (notifError) {
          console.error("Erreur lors de l'envoi de la notification:", notifError)
          // Ne pas bloquer si la notification échoue
        }
        
        // Recharger les avis
        await loadReviews()
      } else {
        toast.error(response.message || "Erreur lors de la publication de l'avis")
      }
    } catch (error) {
      console.error("Erreur lors de la publication de l'avis:", error)
      toast.error("Erreur lors de la publication de l'avis")
    }
  }

  const translateActivity = (activity: string) => {
    const translations: Record<string, string> = {
      informationCommunication: "Information et Communication",
      information: "Information",
      communication: "Communication",
      technology: "Technologie",
      finance: "Finance",
      health: "Santé",
      education: "Éducation",
      retail: "Commerce de détail",
      hospitality: "Hôtellerie",
      construction: "Construction",
      manufacturing: "Fabrication",
      transportation: "Transport",
      realEstate: "Immobilier",
      legal: "Juridique",
      consulting: "Conseil",
      marketing: "Marketing",
      sales: "Ventes",
      humanResources: "Ressources Humaines",
      customerService: "Service Client",
      engineering: "Ingénierie",
      design: "Design",
      arts: "Arts",
      entertainment: "Divertissement",
      sports: "Sports",
      agriculture: "Agriculture",
      energy: "Énergie",
      environment: "Environnement",
      nonprofit: "Organisation à but non lucratif",
      government: "Gouvernement",
      employmentTrainingStaffing: "Emploi, Formation et Recrutement",
      automotive: "Automobile",
      bankingFinanceInsurance: "Banque, Finance et Assurance",
      retailDistribution: "Distribution de détail",
      industrialEnvironmental: "Industrie et Environnement",
      other: "Autre",
    }
    return translations[activity] || activity
  }

  const hasSocialMedia =
    companyData?.facebook ||
    companyData?.instagram ||
    companyData?.linkedin ||
    companyData?.youtube ||
    companyData?.tiktok ||
    companyData?.snapchat ||
    companyData?.x

  // Helper function to ensure URLs have proper protocol
  const ensureHttps = (url: string | undefined | null): string => {
    if (!url) return ""
    const trimmedUrl = url.trim()
    if (!trimmedUrl) return ""
    // If URL already has a protocol, return as is
    if (trimmedUrl.startsWith("http://") || trimmedUrl.startsWith("https://")) {
      return trimmedUrl
    }
    // Otherwise, add https://
    return `https://${trimmedUrl}`
  }

  const handleContactClick = () => {
    const profileId = localStorage.getItem("profileId")
    if (!profileId) {
      router.push("/login-required")
      return
    }
    setShowContactModal(true)
  }

  const handleMessageClick = async () => {
    try {
      if (!userId) return

      const conversationId = await startConversation(userId)
      if (!conversationId) {
        toast.error("Erreur lors de la création de la conversation")
        return
      }

      router.push(`/messages?action=conversation&conversationId=${conversationId}`)
    } catch (error) {
      console.error("Error starting conversation:", error)
      toast.error("Erreur lors de la création de la conversation")
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Skeleton className="h-80 w-full" />
        <div className="container mx-auto px-4 py-8 max-w-7xl">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-1">
              <Skeleton className="h-96 w-full" />
            </div>
            <div className="lg:col-span-2">
              <Skeleton className="h-96 w-full" />
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!companyData) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Card className="p-8 text-center">
          <h2 className="text-2xl font-bold mb-4">Profil introuvable</h2>
          <p className="text-muted-foreground mb-6">Ce profil n'existe pas ou a été supprimé.</p>
          <Button onClick={() => router.push("/")}>Retour à l'accueil</Button>
        </Card>
      </div>
    )
  }

  // Log pour déboguer l'affichage de l'onglet documents
  console.log("🔍 Vérification des conditions pour l'onglet documents:", {
    isProf,
    currentUserProfileType: currentUserData?.companyData?.profiletype,
    isProfessionnel: currentUserData?.companyData?.profiletype === "professionnel",
    hasActiveSubscription: currentUserHasSubscription,
    userId,
    shouldShowTab: !isProf && currentUserData?.companyData?.profiletype === "professionnel" && currentUserHasSubscription && userId
  })

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="relative h-80 w-full overflow-hidden bg-gradient-to-br from-teal-400 via-cyan-500 to-blue-500">
        {bannerUrl ? (
          <Image src={`${config.API_URL}/${bannerUrl}`} alt="Banner" fill className="object-cover" />
        ) : (
          <div className="absolute inset-0 bg-gradient-to-r from-teal-500/90 to-cyan-600/90" />
        )}
      </div>

      <div className="relative bg-white border-b">
        <div className="container mx-auto px-4 max-w-7xl">
          <div className="relative">
            {/* Profile Photo - Positioned absolutely on the left */}
            <div className="absolute left-0 md:left-8 -top-20 z-10">
              <div
                className="relative rounded-full p-1.5 bg-white shadow-2xl"
                style={{
                  boxShadow: `0 0 0 4px ${activeStatus?.hexprimarycolor || "#9CA3AF"}, 0 10px 30px rgba(0,0,0,0.3)`,
                }}
              >
                <div className="relative w-32 h-32 md:w-40 md:h-40 rounded-full overflow-hidden bg-white">
                  <Image
                    src={
                      companyData?.photoprofilurl
                        ? (() => {
                            let photoUrl = companyData.photoprofilurl || ''
                            // Remplacer toutes les occurrences de test.myreklam.fr
                            photoUrl = photoUrl.replaceAll('https://test.myreklam.fr', config.API_URL)
                            photoUrl = photoUrl.replaceAll('http://test.myreklam.fr', config.API_URL)
                            photoUrl = photoUrl.replaceAll('test.myreklam.fr', config.API_URL.replace('https://', '').replace('http://', ''))
                            // Si l'URL ne commence pas par http, ajouter l'API_URL
                            if (!photoUrl.startsWith('http')) {
                              photoUrl = `${config.API_URL}${photoUrl.startsWith('/') ? '' : '/'}${photoUrl}`
                            }
                            return photoUrl
                          })()
                        : "/placeholder-user.jpg"
                    }
                    alt={displayName || "Profile"}
                    fill
                    className="object-cover"
                  />
                </div>
                {activeStatus && (
                  <div
                    className="absolute -bottom-2 left-1/2 transform -translate-x-1/2 px-3 py-1 rounded-full text-xs font-bold text-white shadow-lg whitespace-nowrap"
                    style={{ backgroundColor: activeStatus.hexprimarycolor }}
                  >
                    {activeStatus.icon} {activeStatus.level}
                  </div>
                )}
              </div>
            </div>

            {/* Profile Info - Adjusted to account for left-positioned photo */}
            <div className="pt-24 pb-4 pl-0 md:pl-56">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2 flex-wrap">
                    <h1 className="text-2xl md:text-3xl font-bold text-gray-900">{displayName}</h1>
                    {isVerified && <VerifiedBadge isVerified={true} size="lg" />}
                    <Badge
                      className={`${
                        isProf
                          ? "bg-gradient-to-r from-green-500 to-teal-600"
                          : "bg-gradient-to-r from-blue-500 to-indigo-600"
                      } text-white`}
                    >
                      {isProf ? "Professionnel" : "Particulier"}
                    </Badge>
                    {profileOwnerHasSubscription && (
                      <Badge className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white font-bold">
                        ⭐ Premium
                      </Badge>
                    )}
                  </div>
                  {isProf && companyData?.siret && (
                    <p className="text-sm text-gray-600 mb-2">
                      <span className="font-semibold">SIRET:</span> {companyData.siret}
                    </p>
                  )}
                  {isProf && (
                    <button
                      onClick={() => handleTabChange("avis")}
                      className="flex items-center gap-2 hover:opacity-80 transition-opacity cursor-pointer"
                    >
                      {reviews.length > 0 ? (
                        <>
                          <Star className="h-5 w-5 fill-current text-yellow-500" />
                          <span className="text-lg font-semibold text-gray-900">{getAverageRating()}</span>
                          <span className="text-sm text-gray-600 hover:text-teal-600 hover:underline">
                            ({reviews.length} avis)
                          </span>
                        </>
                      ) : (
                        <>
                          <Star className="h-5 w-5 text-gray-400" />
                          <span className="text-sm text-gray-600 hover:text-teal-600 hover:underline">
                            Aucun avis
                          </span>
                        </>
                      )}
                    </button>
                  )}
                </div>
                <div className="flex gap-3">
                  <Button variant="outline" size="lg" className="gap-2 bg-transparent">
                    <Heart className="h-4 w-4" />
                    Sauvegarder
                  </Button>
                  <Button
                    onClick={handleContactClick}
                    size="lg"
                    className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white gap-2"
                  >
                    <Mail className="h-4 w-4" />
                    Contacter
                  </Button>
                </div>
              </div>

              <Tabs value={activeTab} onValueChange={handleTabChange} className="mt-6">
                <TabsList className="bg-transparent border-b border-gray-200 rounded-none h-auto p-0 w-full justify-start">
                  <TabsTrigger
                    value="presentation"
                    className="rounded-none border-b-2 border-transparent data-[state=active]:border-teal-500 data-[state=active]:bg-transparent data-[state=active]:shadow-none px-6 py-3"
                  >
                    Présentation
                  </TabsTrigger>
                  <TabsTrigger
                    value="annonces"
                    className="rounded-none border-b-2 border-transparent data-[state=active]:border-teal-500 data-[state=active]:bg-transparent data-[state=active]:shadow-none px-6 py-3"
                  >
                    Annonces ({announcements.length})
                  </TabsTrigger>
                  {isProf && (
                    <TabsTrigger
                      value="avis"
                      className="rounded-none border-b-2 border-transparent data-[state=active]:border-teal-500 data-[state=active]:bg-transparent data-[state=active]:shadow-none px-6 py-3"
                    >
                      Avis ({reviews.length})
                    </TabsTrigger>
                  )}
                  {!isProf && (
                    (currentUserId === userId) || 
                    (currentUserData?.companyData?.profiletype === "professionnel" && currentUserHasSubscription)
                  ) && (
                    <TabsTrigger
                      value="documents"
                      className="rounded-none border-b-2 border-transparent data-[state=active]:border-teal-500 data-[state=active]:bg-transparent data-[state=active]:shadow-none px-6 py-3"
                    >
                      Mes documents
                    </TabsTrigger>
                  )}
                </TabsList>
              </Tabs>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8 max-w-7xl">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Sidebar */}
          <div className="lg:col-span-1 space-y-6">
            {/* Afficher la carte Informations générales seulement si au moins une info est disponible */}
            {(companyData?.pseudo ||
              (isProf && companyData?.activite)) && (
              <Card className="p-6">
                <h3 className="text-lg font-semibold mb-4 text-gray-900">Informations générales</h3>
                <div className="space-y-4">
                  {companyData?.pseudo && (
                    <div className="flex items-start gap-3">
                      <Users className="h-5 w-5 text-gray-400 mt-0.5" />
                      <div>
                        <p className="text-sm font-medium text-gray-900">Pseudo</p>
                        <p className="text-sm text-gray-600">{companyData.pseudo}</p>
                      </div>
                    </div>
                  )}
                  {isProf && companyData?.activite && (
                    <div className="flex items-start gap-3">
                      <Briefcase className="h-5 w-5 text-gray-400 mt-0.5" />
                      <div>
                        <p className="text-sm font-medium text-gray-900">Secteur d'activité</p>
                        <p className="text-sm text-gray-600">{translateActivity(companyData.activite)}</p>
                      </div>
                    </div>
                  )}
                </div>
              </Card>
            )}

            {((companyData?.publishtelephone === "true" || companyData?.publishtelephone === true || companyData?.publishtelephone === "1") ||
              (companyData?.publishemail === "true" || companyData?.publishemail === true || companyData?.publishemail === "1") ||
              (companyData?.publishadresse === "true" || companyData?.publishadresse === true || companyData?.publishadresse === "1")) && (
                <Card className="p-6">
                  <h3 className="text-lg font-semibold mb-4 text-gray-900">Contact</h3>
                  <div className="space-y-3">
                    {(companyData?.publishtelephone === "true" || companyData?.publishtelephone === true || companyData?.publishtelephone === "1") && companyData?.telephone && (
                      <div className="flex items-center gap-3 text-sm">
                        <Phone className="h-4 w-4 text-gray-400" />
                        <span className="text-gray-700">{companyData.telephone}</span>
                      </div>
                    )}
                    {(companyData?.publishemail === "true" || companyData?.publishemail === true || companyData?.publishemail === "1") && userData?.email && (
                      <div className="flex items-center gap-3 text-sm">
                        <Mail className="h-4 w-4 text-gray-400" />
                        <span className="text-gray-700">{userData.email}</span>
                      </div>
                    )}
                    {(companyData?.publishadresse === "true" || companyData?.publishadresse === true || companyData?.publishadresse === "1") && companyData?.adresse && (
                      <div className="flex items-start gap-3 text-sm">
                        <MapPin className="h-4 w-4 text-gray-400 mt-0.5" />
                        <span className="text-gray-700">
                          {companyData.adresse}
                          {companyData.ville && `, ${companyData.ville}`}
                          {companyData.codepostal && ` ${companyData.codepostal}`}
                        </span>
                      </div>
                    )}
                  </div>
                </Card>
              )}

            {hasSocialMedia && (
              <Card className="p-6">
                <h3 className="text-lg font-semibold mb-4 text-gray-900">Réseaux sociaux</h3>
                <div className="flex flex-wrap gap-3">
                  {companyData?.facebook && (
                    <a
                      href={ensureHttps(companyData.facebook)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-blue-50 text-blue-600 hover:bg-blue-100 transition-colors"
                    >
                      <Facebook className="h-5 w-5" />
                    </a>
                  )}
                  {companyData?.instagram && (
                    <a
                      href={ensureHttps(companyData.instagram)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-pink-50 text-pink-600 hover:bg-pink-100 transition-colors"
                    >
                      <Instagram className="h-5 w-5" />
                    </a>
                  )}
                  {companyData?.linkedin && (
                    <a
                      href={ensureHttps(companyData.linkedin)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors"
                    >
                      <Linkedin className="h-5 w-5" />
                    </a>
                  )}
                  {companyData?.youtube && (
                    <a
                      href={ensureHttps(companyData.youtube)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                    >
                      <Youtube className="h-5 w-5" />
                    </a>
                  )}
                  {companyData?.tiktok && (
                    <a
                      href={ensureHttps(companyData.tiktok)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-gray-50 text-gray-900 hover:bg-gray-100 transition-colors"
                    >
                      <TikTokIcon className="h-5 w-5" />
                    </a>
                  )}
                  {companyData?.snapchat && (
                    <a
                      href={ensureHttps(companyData.snapchat)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-yellow-50 text-yellow-600 hover:bg-yellow-100 transition-colors"
                    >
                      <SnapchatIcon className="h-5 w-5" />
                    </a>
                  )}
                  {companyData?.x && (
                    <a
                      href={ensureHttps(companyData.x)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-3 rounded-lg bg-gray-50 text-gray-900 hover:bg-gray-100 transition-colors"
                    >
                      <XIcon className="h-5 w-5" />
                    </a>
                  )}
                </div>
              </Card>
            )}
          </div>

          {/* Main Content */}
          <div className="lg:col-span-2">
            <Tabs value={activeTab} className="space-y-6">
              {/* Presentation Tab */}
              <TabsContent value="presentation" className="space-y-6 mt-0">

                {/* Section Présentation */}
                {companyData?.presentation && companyData.presentation.trim() && (
                  <Card className="p-6">
                    <h2 className="text-2xl font-bold mb-4 text-gray-900">Présentation</h2>
                    <div className="text-gray-700 prose prose-lg max-w-none" dangerouslySetInnerHTML={{ __html: companyData.presentation }} />
                  </Card>
                )}

                {mediaGallery.length > 0 && (
                  <Card className="p-6">
                    <h2 className="text-2xl font-bold mb-4 text-gray-900">Photos et vidéos</h2>
                    <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                      {mediaGallery.map((media: any, index: number) => {
                        // Remplacer test.myreklam.fr par api.myreklam.fr
                        let imageUrl = media.urlimg || ''
                        
                        // Utiliser une regex pour remplacer toutes les occurrences
                        imageUrl = imageUrl.replace(/https?:\/\/test\.myreklam\.fr/g, config.API_URL)
                        
                        // Si l'URL ne commence toujours pas par http, ajouter l'API_URL
                        if (!imageUrl.startsWith('http')) {
                          imageUrl = `${config.API_URL}${imageUrl.startsWith('/') ? '' : '/'}${imageUrl}`
                        }
                        
                        console.log(`🖼️ MEDIA ${index + 1}:`, {
                          original: media.urlimg,
                          transformed: imageUrl,
                          configURL: config.API_URL
                        })
                        return (
                          <div
                            key={index}
                            className="relative aspect-square rounded-lg overflow-hidden group cursor-pointer bg-gray-100"
                          >
                            <Image
                              src={imageUrl}
                              alt={`Media ${index + 1}`}
                              fill
                              className="object-cover group-hover:scale-110 transition-transform duration-300"
                              onError={(e) => {
                                console.error(`❌ Erreur chargement image ${index + 1}:`, imageUrl)
                              }}
                            />
                          </div>
                        )
                      })}
                    </div>
                  </Card>
                )}

                {isProf && newsList.length > 0 && (
                  <Card className="p-6">
                    <h2 className="text-2xl font-bold mb-4 text-gray-900 flex items-center gap-2">
                      <Newspaper className="h-6 w-6 text-teal-600" />
                      Actualités
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      {newsList.map((news: any, index: number) => {
                        // Corriger l'URL de la photo
                        let photoUrl = news.urlphoto || ''
                        
                        // Remplacer toutes les occurrences de test.myreklam.fr
                        photoUrl = photoUrl.replaceAll('https://test.myreklam.fr', config.API_URL)
                        photoUrl = photoUrl.replaceAll('http://test.myreklam.fr', config.API_URL)
                        photoUrl = photoUrl.replaceAll('test.myreklam.fr', config.API_URL.replace('https://', '').replace('http://', ''))
                        
                        // Si l'URL ne commence pas par http, ajouter l'API_URL
                        if (!photoUrl.startsWith('http')) {
                          photoUrl = `${config.API_URL}${photoUrl.startsWith('/') ? '' : '/'}${photoUrl}`
                        }
                        return (
                          <a
                            key={index}
                            href={news.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="group block"
                          >
                            <Card className="overflow-hidden hover:shadow-xl transition-all duration-300 border-2 hover:border-teal-500">
                              <div className="relative h-48 w-full overflow-hidden bg-gray-100">
                                <Image
                                  src={photoUrl}
                                  alt={news.title}
                                  fill
                                  className="object-cover group-hover:scale-110 transition-transform duration-300"
                                />
                              </div>
                            <div className="p-4">
                              <h3 className="font-semibold text-base mb-2 line-clamp-2 group-hover:text-teal-600 transition-colors">
                                {news.title}
                              </h3>
                              <div className="flex items-center gap-1 text-sm text-teal-600">
                                <span>Lire l'article</span>
                                <ExternalLink className="h-3 w-3" />
                              </div>
                            </div>
                          </Card>
                        </a>
                        )
                      })}
                    </div>
                  </Card>
                )}

                {!presentation && newsList.length === 0 && mediaGallery.length === 0 && (
                  <Card className="p-12 text-center">
                    <p className="text-gray-500">Aucune information disponible</p>
                  </Card>
                )}
              </TabsContent>

              {/* Annonces Tab */}
              <TabsContent value="annonces" className="space-y-6 mt-0">
                {announcements.length === 0 ? (
                  <Card className="p-12 text-center">
                    <p className="text-gray-500">Aucune annonce disponible</p>
                  </Card>
                ) : (
                  <>
                    {/* Filtres par catégories */}
                    <div className="flex flex-wrap gap-2 mb-6">
                      <Button
                        variant={selectedCategory === "all" ? "default" : "outline"}
                        size="sm"
                        onClick={() => {
                          setSelectedCategory("all")
                          setCurrentPage(1)
                        }}
                        className={selectedCategory === "all" ? "bg-teal-600 hover:bg-teal-700" : ""}
                      >
                        Toutes ({announcements.length})
                      </Button>
                      {announcements.filter(a => a.category === "bons_plans").length > 0 && (
                        <Button
                          variant={selectedCategory === "bons_plans" ? "default" : "outline"}
                          size="sm"
                          onClick={() => {
                            setSelectedCategory("bons_plans")
                            setCurrentPage(1)
                          }}
                          className={selectedCategory === "bons_plans" ? "bg-teal-600 hover:bg-teal-700" : ""}
                        >
                          Bons plans ({announcements.filter(a => a.category === "bons_plans").length})
                        </Button>
                      )}
                      {announcements.filter(a => a.category === "emplois").length > 0 && (
                        <Button
                          variant={selectedCategory === "emplois" ? "default" : "outline"}
                          size="sm"
                          onClick={() => {
                            setSelectedCategory("emplois")
                            setCurrentPage(1)
                          }}
                          className={selectedCategory === "emplois" ? "bg-teal-600 hover:bg-teal-700" : ""}
                        >
                          Emplois ({announcements.filter(a => a.category === "emplois").length})
                        </Button>
                      )}
                      {announcements.filter(a => a.category === "formations").length > 0 && (
                        <Button
                          variant={selectedCategory === "formations" ? "default" : "outline"}
                          size="sm"
                          onClick={() => {
                            setSelectedCategory("formations")
                            setCurrentPage(1)
                          }}
                          className={selectedCategory === "formations" ? "bg-teal-600 hover:bg-teal-700" : ""}
                        >
                          Formations ({announcements.filter(a => a.category === "formations").length})
                        </Button>
                      )}
                      {announcements.filter(a => a.category === "evenements").length > 0 && (
                        <Button
                          variant={selectedCategory === "evenements" ? "default" : "outline"}
                          size="sm"
                          onClick={() => {
                            setSelectedCategory("evenements")
                            setCurrentPage(1)
                          }}
                          className={selectedCategory === "evenements" ? "bg-teal-600 hover:bg-teal-700" : ""}
                        >
                          Événements ({announcements.filter(a => a.category === "evenements").length})
                        </Button>
                      )}
                      {announcements.filter(a => a.category === "demandes").length > 0 && (
                        <Button
                          variant={selectedCategory === "demandes" ? "default" : "outline"}
                          size="sm"
                          onClick={() => {
                            setSelectedCategory("demandes")
                            setCurrentPage(1)
                          }}
                          className={selectedCategory === "demandes" ? "bg-teal-600 hover:bg-teal-700" : ""}
                        >
                          Demandes ({announcements.filter(a => a.category === "demandes").length})
                        </Button>
                      )}
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
                      {paginatedAnnouncements.map((announcement) => {
                        // Rendre la carte spécifique selon la catégorie
                        switch (announcement.category) {
                          case "bons_plans":
                            return <ProfileDealCard key={announcement.id} announcement={announcement} />
                          case "emplois":
                            return <ProfileJobCard key={announcement.id} announcement={announcement} />
                          case "formations":
                            return <ProfileTrainingCard key={announcement.id} announcement={announcement} />
                          case "evenements":
                            return <ProfileEventCard key={announcement.id} announcement={announcement} />
                          case "demandes":
                            return <ProfileInquiryCard key={announcement.id} announcement={announcement} />
                          default:
                            return <ProfileDealCard key={announcement.id} announcement={announcement} />
                        }
                      })}
                    </div>

                      {/* Pagination */}
                      {totalPages > 1 && (
                        <div className="flex justify-center items-center gap-2 mt-8">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                            disabled={currentPage === 1}
                          >
                            Précédent
                          </Button>
                          {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                            let pageNum
                            if (totalPages <= 5) {
                              pageNum = i + 1
                            } else if (currentPage <= 3) {
                              pageNum = i + 1
                            } else if (currentPage >= totalPages - 2) {
                              pageNum = totalPages - 4 + i
                            } else {
                              pageNum = currentPage - 2 + i
                            }
                            return (
                              <Button
                                key={pageNum}
                                variant={currentPage === pageNum ? "default" : "outline"}
                                size="sm"
                                onClick={() => setCurrentPage(pageNum)}
                                className={`w-10 ${
                                  currentPage === pageNum
                                    ? "bg-teal-600 hover:bg-teal-700"
                                    : "hover:bg-teal-50 hover:text-teal-700"
                                }`}
                              >
                                {pageNum}
                              </Button>
                            )
                          })}
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setCurrentPage((prev) => Math.min(totalPages, prev + 1))}
                            disabled={currentPage === totalPages}
                          >
                            Suivant
                          </Button>
                        </div>
                      )}
                    </>
                  )}
              </TabsContent>

              {/* Avis Tab */}
              {isProf && (
                <TabsContent value="avis" className="space-y-6 mt-0" id="avis-section">
                  <Card className="p-6">
                    <div className="flex items-center justify-between mb-6">
                      <h2 className="text-2xl font-bold text-gray-900">
                        Avis ({reviews.length})
                      </h2>
                      {reviews.length > 0 && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="text-teal-600 border-teal-600 hover:bg-teal-50 bg-transparent"
                        >
                          Trier par
                        </Button>
                      )}
                    </div>

                    {/* Formulaire pour laisser un avis - Seulement si ce n'est pas son propre profil */}
                    {currentUserId && currentUserId !== userId && !hasUserAlreadyReviewed() && (
                      <Card className="p-6 mb-6 bg-teal-50 border-teal-200">
                        <h3 className="text-lg font-semibold mb-4 text-gray-900">Laisser un avis</h3>
                        <div className="space-y-4">
                          {/* Notation par étoiles */}
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Votre note {reviewRating > 0 && <span className="text-teal-600">({reviewRating}/5)</span>}
                            </label>
                            <div className="flex gap-2">
                              {[1, 2, 3, 4, 5].map((rating) => (
                                <button
                                  key={rating}
                                  type="button"
                                  onClick={() => setReviewRating(rating)}
                                  onMouseEnter={() => setHoverRating(rating)}
                                  onMouseLeave={() => setHoverRating(0)}
                                  className="focus:outline-none transition-transform hover:scale-110"
                                >
                                  <Star 
                                    className={`h-8 w-8 ${
                                      rating <= (hoverRating || reviewRating)
                                        ? "text-yellow-400 fill-yellow-400"
                                        : "text-gray-300"
                                    }`} 
                                  />
                                </button>
                              ))}
                            </div>
                          </div>

                          {/* Commentaire */}
                          <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                              Votre commentaire
                            </label>
                            <textarea
                              value={reviewComment}
                              onChange={(e) => setReviewComment(e.target.value)}
                              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-teal-500"
                              rows={4}
                              placeholder="Partagez votre expérience..."
                            />
                          </div>

                          {/* Bouton */}
                          <Button 
                            className="bg-teal-600 hover:bg-teal-700 text-white"
                            disabled={reviewRating === 0 || !reviewComment.trim()}
                            onClick={handleSubmitReview}
                          >
                            Publier l'avis
                          </Button>
                        </div>
                      </Card>
                    )}

                    {/* Message si c'est son propre profil */}
                    {currentUserId && currentUserId === userId && (
                      <div className="mb-6 p-4 bg-gray-100 rounded-lg text-center text-gray-600">
                        <p>Vous ne pouvez pas laisser un avis sur votre propre profil.</p>
                      </div>
                    )}

                    {/* Message si l'utilisateur a déjà laissé un avis */}
                    {currentUserId && currentUserId !== userId && hasUserAlreadyReviewed() && (
                      <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg text-center text-blue-700">
                        <p className="font-medium">✓ Vous avez déjà laissé un avis sur ce profil.</p>
                        <p className="text-sm mt-1">Vous ne pouvez laisser qu'un seul avis par profil.</p>
                      </div>
                    )}

                    {/* Liste des avis */}
                    {reviewsLoading ? (
                      <div className="text-center py-8 text-gray-500">
                        Chargement des avis...
                      </div>
                    ) : reviews.length === 0 ? (
                      <div className="text-center py-8 text-gray-500">
                        Aucun avis pour le moment. Soyez le premier à laisser un avis !
                      </div>
                    ) : (
                      <div className="space-y-6">
                        {reviews.map((review: any, index: number) => {
                          // Log pour déboguer la structure de l'avis
                          if (index === 0) {
                            console.log("🔍 Structure d'un avis:", review)
                            console.log("🔍 Champs disponibles:", Object.keys(review))
                          }
                          return (
                          <div key={review.id || index} className="border-b pb-6 last:border-b-0">
                            <div className="flex items-start gap-4">
                              <div className="w-12 h-12 rounded-full bg-teal-100 flex items-center justify-center flex-shrink-0 overflow-hidden">
                                {review.author_photo || review.photoprofilurl || review.photo ? (
                                  <Image
                                    src={(() => {
                                      let photoUrl = review.author_photo || review.photoprofilurl || review.photo || ''
                                      // Corriger l'URL si nécessaire
                                      photoUrl = photoUrl.replace(/https?:\/\/test\.myreklam\.fr/g, config.API_URL)
                                      if (!photoUrl.startsWith('http')) {
                                        photoUrl = `${config.API_URL}${photoUrl.startsWith('/') ? '' : '/'}${photoUrl}`
                                      }
                                      return photoUrl
                                    })()}
                                    alt={review.author_name || review.authorname || "Utilisateur"}
                                    width={48}
                                    height={48}
                                    className="w-12 h-12 object-cover"
                                  />
                                ) : (
                                  <User className="w-6 h-6 text-teal-600" />
                                )}
                              </div>
                              <div className="flex-1">
                                <div className="flex items-center gap-2 mb-2">
                                  <span className="font-semibold text-gray-900">
                                    {review.author_name || 
                                     review.authorname || 
                                     review.authorName ||
                                     review.pseudo ||
                                     review.nomsociete ||
                                     review.name ||
                                     "Utilisateur"}
                                  </span>
                                  <div className="flex text-yellow-400">
                                    {[...Array(5)].map((_, i) => (
                                      <Star 
                                        key={i} 
                                        className={`h-4 w-4 ${
                                          i < review.rating ? "fill-current" : "fill-none stroke-current"
                                        }`} 
                                      />
                                    ))}
                                  </div>
                                  <span className="text-sm text-gray-600">{review.rating}/5</span>
                                </div>
                                <p className="text-gray-700 mb-2">{review.comment}</p>
                                <p className="text-xs text-gray-500">
                                  {review.created_at ? new Date(review.created_at).toLocaleDateString("fr-FR", {
                                    day: "2-digit",
                                    month: "2-digit",
                                    year: "numeric",
                                    hour: "2-digit",
                                    minute: "2-digit"
                                  }) : ""}
                                </p>
                              </div>
                            </div>
                          </div>
                          )
                        })}
                      </div>
                    )}
                  </Card>
                </TabsContent>
              )}

              {/* Documents Tab - Visible au propriétaire du profil ou aux professionnels avec abonnement */}
              {!isProf && (
                (currentUserId === userId) || 
                (currentUserData?.companyData?.profiletype === "professionnel" && currentUserHasSubscription)
              ) && userId && (
                <TabsContent value="documents" className="space-y-6 mt-0">
                  {(() => {
                    const isOwner = currentUserId === userId
                    console.log("📋 Affichage de l'onglet documents pour userId:", userId, "- Est propriétaire:", isOwner)
                    return <UserDocumentsSection userId={userId} isOwner={isOwner} />
                  })()}
                </TabsContent>
              )}
            </Tabs>
          </div>
        </div>
      </div>
      <ContactModal
        isOpen={showContactModal}
        onClose={() => setShowContactModal(false)}
        phoneNumber={
          companyData?.publishtelephone === "true" && companyData?.telephone ? companyData.telephone : undefined
        }
        onMessageClick={handleMessageClick}
      />
    </div>
  )
}

export default function PublicProfilePage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Chargement du profil...</p>
          </div>
        </div>
      }
    >
      <PublicProfileContent />
    </Suspense>
  )
}
