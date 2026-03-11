"use client"

import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Crown, Zap, MessageCircle, FileText } from "lucide-react"
import SubscriptionModal from "./subscription-modal"
import { useState } from "react"

interface LimitReachedModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  limitType: "comments" | "ads" | "contacts" | "documents" | "messaging" | "conversion"
  feature: string
}

// const LIMIT_CONFIG = {
//   comments: {
//     icon: MessageCircle,
//     title: "Limite de commentaires atteinte",
//     description: "Vous avez atteint votre limite de 1 commentaire par mois.",
//     benefits: ["Commentaires illimités", "Accès aux contacts", "Messagerie intégrée"],
//   },
//   ads: {
//     icon: FileText,
//     title: "Limite d'annonces atteinte",
//     description: "Vous avez atteint votre limite de 1 annonce par mois.",
//     benefits: ["Publications illimitées", "Visibilité premium", "Partage de coordonnées"],
//   },
//   contacts: {
//     icon: Zap,
//     title: "Fonctionnalité Premium",
//     description: "L'accès aux coordonnées de contact est réservé aux abonnés Premium.",
//     benefits: ["Accès à tous les contacts", "Messagerie directe", "Documents téléchargeables"],
//   },
//   documents: {
//     icon: FileText,
//     title: "Fonctionnalité Premium",
//     description: "Le téléchargement de documents est réservé aux abonnés Premium.",
//     benefits: ["Téléchargement illimité", "Accès aux CV", "Programmes de formation"],
//   },
//   messaging: {
//     icon: MessageCircle,
//     title: "Fonctionnalité Premium",
//     description: "La messagerie est réservée aux abonnés Premium.",
//     benefits: ["Messagerie illimitée", "Notifications en temps réel", "Historique des conversations"],
//   },
//   conversion: {
//     icon: Crown,
//     title: "Fonctionnalité Premium",
//     description: "La conversion de My's est réservée aux abonnés Premium.",
//     benefits: ["Conversion illimitée", "Récompenses exclusives", "Cashback amélioré"],
//   },
// }

const LIMIT_CONFIG = {
  comments: {
    icon: MessageCircle,
    title: "Limite de commentaires atteinte",
    description: "En tant que professionnel, vous avez atteint votre limite de 1 commentaire par mois. Souscrivez à un abonnement pour débloquer l'accès illimité.",
    benefits: ["Commentaires illimités", "Accès aux contacts", "Messagerie intégrée"],
  },
  ads: {
    icon: FileText,
    title: "Limite d'annonces atteinte",
    description: "En tant que professionnel, vous avez atteint votre limite de 1 annonce par mois. Souscrivez à un abonnement pour débloquer l'accès illimité.",
    benefits: ["Publications illimitées", "Visibilité premium", "Partage de coordonnées"],
  },
  contacts: {
    icon: Zap,
    title: "Fonctionnalité Premium",
    description: "L'accès aux coordonnées de contact est réservé aux professionnels avec abonnement Premium.",
    benefits: ["Accès à tous les contacts", "Messagerie directe", "Documents téléchargeables"],
  },
  documents: {
    icon: FileText,
    title: "Fonctionnalité Premium",
    description: "Le téléchargement de documents est réservé aux professionnels avec abonnement Premium.",
    benefits: ["Téléchargement illimité", "Accès aux CV", "Programmes de formation"],
  },
  messaging: {
    icon: MessageCircle,
    title: "Fonctionnalité Premium",
    description: "La messagerie est réservée aux professionnels avec abonnement Premium.",
    benefits: ["Messagerie illimitée", "Notifications en temps réel", "Historique des conversations"],
  },
  conversion: {
    icon: Crown,
    title: "Fonctionnalité Premium",
    description: "La conversion de My's est réservée aux professionnels avec abonnement Premium.",
    benefits: ["Conversion illimitée", "Récompenses exclusives", "Cashback amélioré"],
  },
}

export default function LimitReachedModal({ open, onOpenChange, limitType, feature }: LimitReachedModalProps) {
  const [showSubscriptionModal, setShowSubscriptionModal] = useState(false)
  const config = LIMIT_CONFIG[limitType]
  const Icon = config.icon

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader className="text-center space-y-4">
            <div className="mx-auto w-16 h-16 bg-gradient-to-br from-amber-500 to-orange-600 rounded-full flex items-center justify-center">
              <Icon className="w-8 h-8 text-white" />
            </div>
            <DialogTitle className="text-xl font-bold">{config.title}</DialogTitle>
          </DialogHeader>
          
          <div className="space-y-6 py-4">
            <p className="text-center text-muted-foreground">{config.description}</p>
            
            <div className="space-y-3">
              <p className="font-semibold text-center">Passez à Premium pour débloquer :</p>
              <ul className="space-y-2">
                {config.benefits.map((benefit, index) => (
                  <li key={index} className="flex items-center gap-2">
                    <div className="w-2 h-2 bg-green-500 rounded-full" />
                    <span className="text-sm">{benefit}</span>
                  </li>
                ))}
              </ul>
            </div>
            
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => onOpenChange(false)} className="flex-1">
                Plus tard
              </Button>
              <Button
                onClick={() => {
                  onOpenChange(false)
                  setShowSubscriptionModal(true)
                }}
                className="flex-1 bg-gradient-to-r from-amber-500 to-orange-600 hover:from-orange-600 hover:to-amber-500"
              >
                <Crown className="w-4 h-4 mr-2" />
                Passer à Premium
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <SubscriptionModal
        open={showSubscriptionModal}
        onOpenChange={setShowSubscriptionModal}
      />
    </>
  )
}