"use client"

import Link from "next/link"
import { useState, useEffect } from "react"
import { Menu, X, LogOut, Settings, MessageCircle, Heart, Plus, LayoutDashboard, Bell } from "lucide-react"
import { Button } from "@/components/ui/button"
import { useAuthStore } from "@/lib/auth-store"
import { SignInModal } from "@/components/auth/sign-in-modal"
import { SignUpModal } from "@/components/auth/sign-up-modal"
import { useAmbassadorStatus } from "@/hooks/use-ambassador-status"
import { useUserData } from "@/hooks/use-user-data"
import { NotificationsDropdown } from "@/components/notifications-dropdown"
import FeatureGuard from "@/components/subscription/feature-guard"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import { useMessageStore } from "@/lib/stores/message-store"
import { config } from "@/lib/config"

import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"

const navigation = [
  { name: "Bons plans", href: "/bons-plans" },
  { name: "Offres d'emploi", href: "/offres-emploi" },
  { name: "Formations", href: "/formations" },
  { name: "Événements", href: "/evenements" },
  { name: "Demandes", href: "/demandes" },
]

const API_URL = config.API_URL

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [showSignIn, setShowSignIn] = useState(false)
  const [showSignUp, setShowSignUp] = useState(false)

  const { userId, profileType, isAuthenticated, logout, fetchUserInfo } = useAuthStore()
  const { companyData } = useUserData()
  const { activeStatus, totalCoins } = useAmbassadorStatus(userId || "")
  const { unreadCount, fetchUnreadCount } = useMessageStore()
  const router = useRouter()
  const { toast } = useToast()
  
  useEffect(() => {
    fetchUserInfo()
  }, [fetchUserInfo])

  // Charger le compteur de messages au montage
  useEffect(() => {
    const profileId = localStorage.getItem("profileId")
    if (profileId) {
      fetchUnreadCount(profileId)
    }
  }, [fetchUnreadCount])

  const handleSignOut = () => {
    logout()
  }

  const profilePhotoUrl = companyData?.photoprofilurl ? API_URL + companyData.photoprofilurl : `/placeholder-user.jpg`
  const displayName = companyData?.nomsociete || companyData?.pseudo || profileType || "Utilisateur"
 const { canCreateAds, remainingAds, isPremium } = useSubscriptionLimits()
  const profileType0 = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

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

  return (
    <>
      <header className="sticky top-0 z-50 w-full border-b bg-white dark:bg-gray-950 shadow-sm">
        <div className="border-b border-gray-100 dark:border-gray-900">
          <nav
            className="mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-2.5 lg:px-6"
            aria-label="Global"
          >
            {/* Logo Section */}
            <div className="flex items-center">
              <Link href="/" className="flex items-center">
                <img
                  src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Capture.PNG-H37lGxacbPN0FYkfQ6RsUSvwe4AYwt.png"
                  alt="Myreklam"
                  className="h-7 w-auto"
                />
              </Link>
            </div>

            {isAuthenticated && userId && activeStatus && (
              <Link
                href="/dashboard/recompenses-ambassadeurs"
                className="hidden lg:flex items-center gap-2 px-3 py-1.5 rounded-full border-2 hover:bg-gray-50 dark:hover:bg-gray-900 transition-colors"
                style={{ borderColor: activeStatus.hexprimarycolor }}
              >
                <img
                  src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
                  alt="My's coin"
                  className="h-5 w-5 object-contain"
                />
                <span className="text-sm font-bold" style={{ color: activeStatus.hexprimarycolor }}>
                  {totalCoins}
                </span>
                <span className="text-xs text-gray-500 dark:text-gray-400">My's</span>
              </Link>
            )}

            <div className="flex items-center gap-2 ml-auto">
              {isAuthenticated && userId ? (
                <>
                  <div className="hidden lg:flex lg:items-center lg:gap-1">
                    <NotificationsDropdown userId={userId} />

                    <Link
                      href="/messages"
                      className="relative p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors group"
                      title="Messagerie"
                    >
                      <MessageCircle className="h-5 w-5 text-gray-600 dark:text-gray-400 group-hover:text-primary transition-colors" />
                      {unreadCount > 0 && (
                        <span className="absolute -top-1 -right-1 h-5 w-5 rounded-full bg-red-500 text-white text-xs font-bold flex items-center justify-center">
                          {unreadCount}
                        </span>
                      )}
                    </Link>

                    <Link
                      href="/dashboard/mes-favoris"
                      className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors group"
                      title="Mes Favoris"
                    >
                      <Heart className="h-5 w-5 text-gray-600 dark:text-gray-400 group-hover:text-red-500 transition-colors" />
                    </Link>

                    <div className="w-px h-6 bg-gray-200 dark:bg-gray-800 mx-1" />
                  </div>

                  <FeatureGuard feature="ads">
                  <Button 
                    size="sm" 
                    className="hidden lg:flex bg-primary hover:bg-primary/90 text-white font-medium shadow-sm"
                    onClick={handleCreateAnnouncement}
                  >
                    <Plus className="h-4 w-4 mr-1.5" />
                    Poster une annonce
                  </Button>
                  </FeatureGuard>

                  <Link
                    href="/dashboard"
                    className="hidden lg:flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors border border-gray-200 dark:border-gray-800"
                  >
                    <img
                      src={profilePhotoUrl || "/placeholder.svg"}
                      alt="Profile"
                      className="h-8 w-8 rounded-full object-cover ring-2 ring-white dark:ring-gray-950"
                      style={{ borderColor: activeStatus?.hexprimarycolor || "#e5e7eb" }}
                    />
                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300 max-w-[80px] sm:max-w-[120px] truncate">
                      {displayName}
                    </span>
                  </Link>

                  <button
                    type="button"
                    className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors"
                    onClick={() => setMobileMenuOpen(true)}
                  >
                    <Menu className="h-6 w-6 text-gray-700 dark:text-gray-300" />
                  </button>
                </>
              ) : (
                <>
                  <Button variant="ghost" size="sm" onClick={() => setShowSignIn(true)} className="hidden lg:flex">
                    Connexion
                  </Button>
                  <Button size="sm" onClick={() => setShowSignUp(true)} className="hidden lg:flex">
                    S'inscrire
                  </Button>
                  <button
                    type="button"
                    className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors"
                    onClick={() => setMobileMenuOpen(true)}
                  >
                    <Menu className="h-6 w-6 text-gray-700 dark:text-gray-300" />
                  </button>
                </>
              )}
            </div>
          </nav>
        </div>

        <div className="hidden lg:block bg-gray-50 dark:bg-gray-900/50">
          <div className="mx-auto max-w-7xl px-4 lg:px-6">
            <div className="flex items-center justify-center gap-1 py-2">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-primary hover:bg-white dark:text-gray-300 dark:hover:bg-gray-900 rounded-lg transition-colors"
                >
                  {item.name}
                </Link>
              ))}
            </div>
          </div>
        </div>
      </header>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="lg:hidden">
          <div className="fixed inset-0 z-[60] bg-black/50 backdrop-blur-sm" onClick={() => setMobileMenuOpen(false)} />
          <div className="fixed top-0 right-0 bottom-0 z-[70] h-screen w-full overflow-y-auto bg-white dark:bg-gray-950 px-6 py-6 sm:max-w-sm shadow-2xl">
            <div className="flex items-center justify-between mb-6">
              <Link href="/" className="flex items-center">
                <img
                  src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Capture.PNG-H37lGxacbPN0FYkfQ6RsUSvwe4AYwt.png"
                  alt="Myreklam"
                  className="h-7 w-auto"
                />
              </Link>
              <button
                type="button"
                className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-900 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                <X className="h-6 w-6" />
              </button>
            </div>

            {isAuthenticated && userId && (
              <Link href="/dashboard" onClick={() => setMobileMenuOpen(false)}>
                <div className="mb-6 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors cursor-pointer">
                  <div className="flex items-center gap-3">
                    <img
                      src={profilePhotoUrl || "/placeholder.svg"}
                      alt="Profile"
                      className="h-12 w-12 rounded-full object-cover"
                    />
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-gray-900 dark:text-gray-100 truncate">{displayName}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 capitalize">
                        {profileType || "Utilisateur"}
                      </p>
                    </div>
                  </div>
                </div>
              </Link>
            )}

            {isAuthenticated && userId && (
              // <Link href="/announcements/create" onClick={() => setMobileMenuOpen(false)} className="mb-4 block">
              //   <Button className="w-full bg-primary hover:bg-primary/90 text-white font-medium">
              //     <Plus className="h-4 w-4 mr-2" />
              //     Poster une annonce
              //   </Button>

                <FeatureGuard feature="ads">
                  <Button 
                    className="w-full bg-primary hover:bg-primary/90 text-white font-medium"
                    onClick={handleCreateAnnouncement}
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Poster une annonce
                  </Button>
                  </FeatureGuard>
              // </Link>
            )}

            <div className="space-y-1 mb-6">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className="block px-4 py-3 text-base font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {item.name}
                </Link>
              ))}
            </div>

            {isAuthenticated && userId ? (
              <div className="space-y-1 border-t border-gray-200 dark:border-gray-800 pt-4">
                <Link
                  href="/notifications"
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center gap-3 px-4 py-3 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                >
                  <Bell className="h-5 w-5" />
                  <span className="text-sm font-medium">Notifications</span>
                </Link>

                <Link
                  href="/messages"
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center justify-between px-4 py-3 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <MessageCircle className="h-5 w-5" />
                    <span className="text-sm font-medium">Messagerie</span>
                  </div>
                  {unreadCount > 0 && (
                    <span className="h-5 w-5 rounded-full bg-red-500 text-white text-xs font-bold flex items-center justify-center">
                      {unreadCount}
                    </span>
                  )}
                </Link>

                <Link
                  href="/dashboard/mes-favoris"
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center gap-3 px-4 py-3 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                >
                  <Heart className="h-5 w-5" />
                  <span className="text-sm font-medium">Mes Favoris</span>
                </Link>

                <Link
                  href="/dashboard"
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center gap-3 px-4 py-3 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                >
                  <LayoutDashboard className="h-5 w-5" />
                  <span className="text-sm font-medium">Tableau de bord</span>
                </Link>

                <Link
                  href="/dashboard/recompenses-ambassadeurs"
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-center justify-between px-4 py-3 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-900 rounded-lg transition-colors"
                >
                  <div className="flex items-center gap-3">
                    <img
                      src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
                      alt="My's coin"
                      className="h-5 w-5 object-contain"
                    />
                    <span className="text-sm font-medium">Mes My's</span>
                  </div>
                  <span className="text-sm font-bold text-amber-600">{totalCoins}</span>
                </Link>

                <button
                  onClick={handleSignOut}
                  className="flex w-full items-center gap-3 px-4 py-3 text-red-600 hover:bg-red-50 dark:hover:bg-red-950/20 rounded-lg transition-colors"
                >
                  <LogOut className="h-5 w-5" />
                  <span className="text-sm font-medium">Déconnexion</span>
                </button>
              </div>
            ) : (
              <div className="space-y-2 border-t border-gray-200 dark:border-gray-800 pt-4">
                <Button
                  variant="outline"
                  className="w-full bg-transparent"
                  onClick={() => {
                    setShowSignIn(true)
                    setMobileMenuOpen(false)
                  }}
                >
                  Connexion
                </Button>
                <Button
                  className="w-full"
                  onClick={() => {
                    setShowSignUp(true)
                    setMobileMenuOpen(false)
                  }}
                >
                  S'inscrire
                </Button>
              </div>
            )}
          </div>
        </div>
      )}

      <SignInModal
        isOpen={showSignIn}
        onClose={() => setShowSignIn(false)}
        onSwitchToSignUp={() => {
          setShowSignIn(false)
          setShowSignUp(true)
        }}
      />
      <SignUpModal
        isOpen={showSignUp}
        onClose={() => setShowSignUp(false)}
        onSwitchToSignIn={() => {
          setShowSignUp(false)
          setShowSignIn(true)
        }}
      />
    </>
  )
}
