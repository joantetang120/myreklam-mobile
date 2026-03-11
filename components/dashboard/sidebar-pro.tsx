"use client"

import type React from "react"

import { useState, useEffect } from "react"
import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { useAuthStore } from "@/lib/auth-store"
import { useUserData } from "@/lib/hooks/use-user-data"
import { useAmbassadorStatus } from "@/lib/hooks/use-ambassador-status"
import { MediaUploadModal } from "@/components/dashboard/media-upload-modal"
import { VerifiedBadge } from "@/components/dashboard/verified-badge"
import { getUserSubscriptions, hasActiveSubscription } from "@/lib/api"
import { toast } from "sonner"
import axios from "axios"
import {
  ClipboardDocumentListIcon,
  ChatBubbleOvalLeftEllipsisIcon,
  BookmarkIcon,
  Cog6ToothIcon,
  BriefcaseIcon,
  TrophyIcon,
  UsersIcon,
  CreditCardIcon,
  BuildingOffice2Icon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline"
import { Camera } from "lucide-react"
import { config } from "@/lib/config"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
  
import { useRouter } from "next/navigation"

const API_URL = config?.API_URL

interface MenuItem {
  label: string
  path: string
  icon: React.ElementType
  section?: string
}

const menuItems: MenuItem[] = [
  { label: "Mes annonces", path: "/dashboard/mes-annonces", icon: ClipboardDocumentListIcon, section: "Personnel" },
  { label: "Messagerie", path: "/messages", icon: ChatBubbleOvalLeftEllipsisIcon, section: "Personnel" },
  { label: "Mes Favoris", path: "/dashboard/mes-favoris", icon: BookmarkIcon, section: "Personnel" },
  {
    label: "Mes recherches sauvegardées",
    path: "/mes-recherches",
    icon: MagnifyingGlassIcon,
    section: "Personnel",
  },
  { label: "Espace Professionnel", path: "/dashboard/espace-professionnel", icon: BriefcaseIcon, section: "Personnel" },
  { label: "Paramètres du compte", path: "/dashboard/parametres-compte", icon: Cog6ToothIcon, section: "Personnel" },
  {
    label: "Récompenses ambassadeurs",
    path: "/dashboard/recompenses-ambassadeurs",
    icon: TrophyIcon,
    section: "Personnel",
  },
  { label: "Mon Parrainage", path: "/dashboard/mon-parrainage", icon: UsersIcon, section: "Personnel" },
  {
    label: "Gérer mon abonnement",
    path: "/dashboard/gerer-abonnement",
    icon: CreditCardIcon,
    section: "Professionnel",
  },
  { label: "Profil entreprise", path: "/dashboard", icon: BuildingOffice2Icon, section: "Professionnel" },
]

export function SidebarProMenu() {
  const [isMediaModalOpen, setIsMediaModalOpen] = useState(false)
  const [subscriptions, setSubscriptions] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const pathname = usePathname()
  const { logout } = useAuthStore()
  const { companyData, refreshData } = useUserData()
  const userId = companyData?.userid || ""
  const { activeStatus } = useAmbassadorStatus(userId)
const router = useRouter()

  const sections = menuItems.reduce(
    (acc, item) => {
      if (!acc[item.section!]) {
        acc[item.section!] = []
      }
      acc[item.section!].push(item)
      return acc
    },
    {} as Record<string, MenuItem[]>,
  )

  useEffect(() => {
    const fetchSubscriptions = async () => {
      if (companyData?.profiletype === "professionnel" && userId) {
        try {
          const userSubscriptions = await getUserSubscriptions(userId)
          setSubscriptions(userSubscriptions)
        } catch (error) {
          console.error("Erreur lors de la récupération des abonnements:", error)
          setSubscriptions([])
        }
      }
      setLoading(false)
    }

    fetchSubscriptions()
  }, [companyData?.profiletype, userId])

  const openMediaModal = () => setIsMediaModalOpen(true)
  const closeMediaModal = () => setIsMediaModalOpen(false)

   const { canCreateAds, remainingAds, isPremium } = useSubscriptionLimits()
  const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

  const handleCreateAnnouncement = () => {
    if (!userId) {
      toast({
        title: "Connexion requise",
        description: "Vous devez être connecté pour créer une annonce.",
        variant: "destructive",
      })
      return
    }

    if (!canCreateAds) {
      toast({
        title: "Limite d'annonces atteinte",
        description: "Vous avez atteint votre limite d'annonces pour ce mois. Souscrivez à un abonnement pour créer plus d'annonces.",
        variant: "destructive",
      })
      return
    }

    router.push("/announcements/create")
  }   

  const handleSaveMedia = async (file: File | null, link?: string) => {
    if (!file) {
      toast.error("Aucun fichier sélectionné")
      return
    }

    try {
      const formData = new FormData()
      formData.append("photoprofilurl", file)  // Le fichier binaire de l'image
      formData.append("Method", "updateUserInfo")  // La méthode à appeler
      formData.append("id", companyData?.id || "")  // L'ID de l'utilisateur

      // Envoi de la requête avec le bon format de payload
      const response = await axios.post(`${API_URL}/UserInfo.php`, formData, {
        headers: {
          "Content-Type": "multipart/form-data",  // Important pour les fichiers
        },
      })

      if (response.data.status === "success") {
        toast.success("Photo mise à jour avec succès !")
        await refreshData()
      } else {
        toast.error("Erreur lors de la mise à jour de la photo.")
      }
    } catch (error: any) {
      toast.error("Erreur lors de la mise à jour de la photo.")
    }
  }

  return (
    <aside className="flex h-full w-full flex-col bg-card border-r border-border">
      <div className="flex items-center justify-center p-4 border-b border-border">
        <Link href="/">
          <img
            src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Capture.PNG-H37lGxacbPN0FYkfQ6RsUSvwe4AYwt.png"
            alt="Myreklam"
            className="h-8 w-auto"
          />
        </Link>
      </div>

      <div className="flex flex-col items-center space-y-4 p-6 border-b border-border">
        <div className="relative group cursor-pointer" onClick={openMediaModal}>
          <div
            style={{
              borderColor: activeStatus?.hexprimarycolor || "#9CA3AF",
              boxShadow: `0 0 20px ${activeStatus?.hexprimarycolor || "#9CA3AF"}40`,
            }}
            className="border-[5px] rounded-full p-1 transition-all duration-300 hover:scale-105 hover:shadow-2xl"
          >
            <Image
              src={companyData?.photoprofilurl ? API_URL + companyData?.photoprofilurl : "/placeholder-user.jpg"}
              alt="Photo de profil"
              width={120}
              height={120}
              className="w-30 h-30 rounded-full object-cover"
            />
          </div>
          <div className="absolute inset-0 bg-black/50 rounded-full opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
            <Camera className="h-6 w-6 text-white" />
          </div>
        </div>

        {companyData && (
          <div className="w-full space-y-3 text-center">
            <div>
              <div className="flex items-center justify-center gap-2">
                <h3 className="text-lg font-semibold text-foreground">{companyData.nomsociete}</h3>
                {hasActiveSubscription(subscriptions) && (
                  <VerifiedBadge isVerified={hasActiveSubscription(subscriptions)} size="lg" />
                )}
              </div>
              {companyData.siret && <p className="text-xs text-muted-foreground mt-1">SIRET: {companyData.siret}</p>}
              <span className="inline-block mt-2 px-3 py-1 text-xs font-medium text-white bg-gradient-to-r from-green-500 to-teal-600 rounded-full">
                {companyData.profiletype}
              </span>
            </div>

            {userId && (
              <Link
                href={`/profil-public?Id=${userId}`}
                className="flex items-center justify-center gap-2 w-full px-4 py-2.5 bg-gradient-to-r from-blue-500 to-blue-600 text-white text-sm font-medium rounded-lg shadow-md hover:from-blue-600 hover:to-blue-700 hover:shadow-lg transition-all duration-200"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                  stroke="currentColor"
                  className="w-4 h-4"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M2.458 12C3.732 7.943 7.522 5 12 5c4.478 0 8.268 2.943 9.542 7-.274.84-.68 1.63-1.196 2.342M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                Voir mon profil public
              </Link>
            )}

            <FeatureGuard feature="ads">
              <button 
              onClick={handleCreateAnnouncement}
              className="flex items-center justify-center gap-2 w-full px-4 py-2.5 bg-gradient-to-r from-green-500 to-teal-600 text-white text-sm font-medium rounded-lg shadow-md hover:from-teal-600 hover:to-green-500 hover:shadow-lg transition-all duration-200"
              >
              <Camera className="w-4 h-4" />
              Poster une annonce
              </button>
            </FeatureGuard>
          </div>
        )}
      </div>

      <nav className="flex-1 overflow-y-auto p-4 space-y-6">
        {Object.entries(sections).map(([section, items]) => (
          <div key={section} className="space-y-1">
            <h3 className="px-4 text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-2">
              {section}
            </h3>
            {items.map((item, index) => (
              <Link key={index} href={item.path}>
                <button
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 ${
                    pathname === item.path
                      ? "bg-primary text-primary-foreground shadow-md"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  }`}
                >
                  <item.icon className="h-5 w-5 flex-shrink-0" />
                  <span className="truncate">{item.label}</span>
                </button>
              </Link>
            ))}
          </div>
        ))}
      </nav>

      <div className="p-4 border-t border-border">
        <button
          onClick={() => {
            if (confirm("Êtes-vous sûr de vouloir vous déconnecter ?")) {
              logout()
            }
          }}
          className="w-full flex items-center justify-center gap-3 px-4 py-3 rounded-lg text-sm font-medium text-destructive border-2 border-destructive/20 hover:bg-destructive/10 transition-all duration-200"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={1.5}
            stroke="currentColor"
            className="h-5 w-5"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-9A2.25 2.25 0 002.25 5.25v13.5A2.25 2.25 0 004.5 21h9a2.25 2.25 0 002.25-2.25V15M9 12h12m0 0l-3-3m3 3l-3 3"
            />
          </svg>
          <span>Déconnexion</span>
        </button>
      </div>

      <MediaUploadModal
        title="Modifier votre photo de profil"
        imageAccept="image/*"
        isOpen={isMediaModalOpen}
        onClose={closeMediaModal}
        onSave={handleSaveMedia}
      />
    </aside>
  )
}
