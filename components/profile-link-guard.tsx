"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Lock, Crown } from "lucide-react"

interface ProfileLinkGuardProps {
  userId: string
  children: React.ReactNode
  className?: string
}

export function ProfileLinkGuard({ userId, children, className }: ProfileLinkGuardProps) {
  const router = useRouter()
  const { limits, isPremium, loading } = useSubscriptionLimits()
  const [showUpgradeModal, setShowUpgradeModal] = useState(false)
  
  const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

  const handleClick = (e: React.MouseEvent) => {
    e.preventDefault()
    e.stopPropagation()

    console.log("[ProfileLinkGuard] Click detected:", {
      profileType,
      isPremium,
      loading,
      limits
    })

    // Si les données sont en cours de chargement, autoriser la navigation (pour éviter de bloquer à tort)
    if (loading) {
      console.log("[ProfileLinkGuard] Still loading, allowing navigation")
      router.push(`/profil-public?Id=${userId}`)
      return
    }

    // Vérifier si l'utilisateur est un professionnel sans abonnement
    const isFreeProfessional = profileType === "professionnel" && !isPremium

    console.log("[ProfileLinkGuard] isFreeProfessional:", isFreeProfessional)

    if (isFreeProfessional) {
      // Afficher le modal au lieu de rediriger
      console.log("[ProfileLinkGuard] Showing upgrade modal")
      setShowUpgradeModal(true)
    } else {
      // Autoriser la navigation
      console.log("[ProfileLinkGuard] Allowing navigation")
      router.push(`/profil-public?Id=${userId}`)
    }
  }

  const handleUpgrade = () => {
    setShowUpgradeModal(false)
    router.push("/subscription")
  }

  return (
    <>
      <div onClick={handleClick} className={className} style={{ cursor: "pointer" }}>
        {children}
      </div>

      <Dialog open={showUpgradeModal} onOpenChange={setShowUpgradeModal}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="flex items-center justify-center w-12 h-12 rounded-full bg-yellow-100 mx-auto mb-4">
              <Lock className="w-6 h-6 text-yellow-600" />
            </div>
            <DialogTitle className="text-center text-xl">
              Accès aux profils publics réservé aux abonnés
            </DialogTitle>
            <DialogDescription className="text-center text-base pt-2">
              Pour consulter les profils publics des autres utilisateurs, vous devez souscrire à un abonnement premium.
            </DialogDescription>
          </DialogHeader>

          <div className="bg-gradient-to-br from-yellow-50 to-orange-50 rounded-lg p-4 my-4">
            <div className="flex items-start gap-3">
              <Crown className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" />
              <div className="space-y-2 text-sm">
                <p className="font-semibold text-gray-900">Avec un abonnement premium :</p>
                <ul className="space-y-1 text-gray-700">
                  <li>✓ Accès illimité aux profils publics</li>
                  <li>✓ Consultation des coordonnées</li>
                  <li>✓ Téléchargement des documents</li>
                  <li>✓ Messagerie illimitée</li>
                  <li>✓ Publication d'annonces illimitées</li>
                </ul>
              </div>
            </div>
          </div>

          <DialogFooter className="flex-col sm:flex-row gap-2">
            <Button
              variant="outline"
              onClick={() => setShowUpgradeModal(false)}
              className="w-full sm:w-auto"
            >
              Annuler
            </Button>
            <Button
              onClick={handleUpgrade}
              className="w-full sm:w-auto bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 text-white"
            >
              <Crown className="w-4 h-4 mr-2" />
              Voir les abonnements
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
