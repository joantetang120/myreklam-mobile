"use client"

import { ReactNode, useState } from "react"
import { useSubscriptionLimits } from "@/hooks/use-subscription-limits"
import LimitReachedModal from "./limit-reached-modal"

interface FeatureGuardProps {
  children: ReactNode
  feature: "comments" | "ads" | "contacts" | "documents" | "messaging" | "conversion"
  fallback?: ReactNode
  onBlock?: () => void
}

export default function FeatureGuard({ children, feature, fallback, onBlock }: FeatureGuardProps) {
  const { limits, canComment, canCreateAds, isPremium } = useSubscriptionLimits()
  const [showLimitModal, setShowLimitModal] = useState(false)

  // Récupérer le type de profil depuis localStorage
  const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

  const checkAccess = () => {
    // CORRECTION : Logique d'accès mise à jour
    switch (feature) {
      case "comments":
        return canComment
      case "ads":
        return canCreateAds
      case "contacts":
        // Seuls les professionnels avec abonnement peuvent accéder aux contacts
        return profileType !== "professionnel" || isPremium
      case "documents":
        // Seuls les professionnels avec abonnement peuvent télécharger des documents
        return profileType !== "professionnel" || isPremium
      case "messaging":
        // Seuls les professionnels avec abonnement peuvent accéder à la messagerie
        return profileType !== "professionnel" || isPremium
      case "conversion":
        // Seuls les professionnels avec abonnement peuvent convertir des coins
        return profileType !== "professionnel" || isPremium
      default:
        return true
    }
  }

  const handleClick = (e: any) => {
    if (!checkAccess()) {
      e.preventDefault()
      e.stopPropagation()
      setShowLimitModal(true)
      onBlock?.()
      return false
    }
    return true
  }

  if (!checkAccess() && fallback) {
    return <>{fallback}</>
  }

  return (
    <>
      <div onClick={handleClick}>
        {children}
      </div>
      
      <LimitReachedModal
        open={showLimitModal}
        onOpenChange={setShowLimitModal}
        limitType={feature}
        feature={feature}
      />
    </>
  )
}