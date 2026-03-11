"use client"

import { useState, useEffect } from "react"
import axios from "axios"
import { toast } from "sonner"
import { ButtonGeneral } from "@/components/ui/button-general"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { SubscriptionModal } from "@/components/subscription/subscription-modal"
import { cancelStripeSubscription, createBillingPortalSession } from "@/lib/api"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Check, CreditCard, Calendar, AlertCircle, Crown, Sparkles } from "lucide-react"
import { config } from "@/lib/config"

const API_URL = config?.API_URL

interface Subscription {
  id: string
  userid?: string
  typeabo?: string
  dateabo?: string
  customerid?: string
}

export default function GererAbonnementContent() {
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([])
  const [isModalResiliationOpen, setIsModalResiliationOpen] = useState(false)
  const [isSubscriptionModalOpen, setIsSubscriptionModalOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [abonnementActuel, setAbonnementActuel] = useState<Subscription | null>(null)

  useEffect(() => {
    fetchSubscriptions()
  }, [])

  const fetchSubscriptions = async () => {
    try {
      const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
      if (!userId) return

      const response = await axios.post(
        `${API_URL}/Abonnement.php`,
        {
          Id: userId,
          Method: "readAllByUserId",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      if (response.data.status === "success") {
        const subs: Subscription[] = response.data.subscriptions || []
        const validSubs = subs.filter((sub) => sub.dateabo && sub.customerid)
        const sortedSubs = [...validSubs].sort((a, b) => {
          const dateA = new Date(a.dateabo!).getTime()
          const dateB = new Date(b.dateabo!).getTime()
          return dateB - dateA
        })
        setSubscriptions(sortedSubs)
        setAbonnementActuel(sortedSubs.length > 0 ? sortedSubs[0] : null)
      } else {
        toast.error("Erreur lors de la récupération des abonnements")
      }
    } catch (error) {
      console.error("Error fetching subscriptions:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleFacture = async () => {
    try {
      const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
      if (!userId) {
        toast.error("Utilisateur non connecté")
        return
      }

      if (!abonnementActuel?.customerid) {
        toast.error("Impossible de récupérer l'abonnement")
        return
      }

      const response = await createBillingPortalSession(abonnementActuel.customerid, window.location.origin)

      if (response.status === "success" && response.data?.url) {
        window.open(response.data.url, "_blank")
      } else {
        toast.error(response.message || "Impossible d'accéder au portail de facturation")
      }
    } catch (error) {
      console.error("Error creating billing portal session:", error)
      toast.error("Une erreur est survenue")
    }
  }

  const getCurrentSubscriptionType = () => {
    if (!subscriptions || subscriptions.length === 0) {
      return "gratuit"
    }

    const activeSubscription = subscriptions.find((sub) => {
      if (!sub.dateabo || !sub.typeabo) return false

      const subscriptionDate = new Date(sub.dateabo)
      const now = new Date()
      const expirationDate = new Date(subscriptionDate)

      if (sub.typeabo === "annuel") {
        expirationDate.setFullYear(expirationDate.getFullYear() + 1)
      } else if (sub.typeabo === "mensuel") {
        expirationDate.setMonth(expirationDate.getMonth() + 1)
      }

      return now <= expirationDate
    })

    return activeSubscription ? activeSubscription.typeabo : "gratuit"
  }

  const getRenewalDate = () => {
    if (!subscriptions || subscriptions.length === 0) return null

    const subscription = subscriptions[0]
    if (!subscription.dateabo || !subscription.typeabo) return null

    const renewalDate = new Date(subscription.dateabo)
    if (subscription.typeabo === "annuel") {
      renewalDate.setFullYear(renewalDate.getFullYear() + 1)
    } else if (subscription.typeabo === "mensuel") {
      renewalDate.setMonth(renewalDate.getMonth() + 1)
    }

    return renewalDate.toLocaleDateString("fr-FR", { day: "numeric", month: "long", year: "numeric" })
  }

  const handleCancelSubscription = async () => {
    if (!abonnementActuel?.customerid) {
      toast.error("Impossible de récupérer l'abonnement")
      return
    }

    try {
      const response = await cancelStripeSubscription(abonnementActuel.customerid)

      if (response.status === "success") {
        toast.success("Abonnement résilié avec succès")
        setIsModalResiliationOpen(false)
        window.location.reload()
      } else {
        toast.error(response.message || "Erreur lors de la résiliation")
      }
    } catch (error) {
      console.error("Error canceling subscription:", error)
      toast.error("Erreur lors de la résiliation")
    }
  }

  const currentSubscriptionType = getCurrentSubscriptionType()
  const renewalDate = getRenewalDate()

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-emerald-600 border-t-transparent rounded-full animate-spin" />
          <p className="text-muted-foreground">Chargement de votre abonnement...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-4xl font-bold tracking-tight">Gérer mon abonnement</h1>
        <p className="text-lg text-muted-foreground">
          Gérez votre abonnement premium et accédez à toutes vos factures en un clic.
        </p>
      </div>

      <Card className="border-2">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <CardTitle className="text-2xl">Mon abonnement actuel</CardTitle>
              <CardDescription>Votre plan et ses avantages</CardDescription>
            </div>
            {currentSubscriptionType !== "gratuit" && (
              <Badge variant="secondary" className="gap-1.5 px-3 py-1.5">
                <Crown className="h-4 w-4" />
                Premium
              </Badge>
            )}
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center gap-4 p-6 rounded-lg bg-muted/50">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-900/20">
              {currentSubscriptionType === "gratuit" ? (
                <Sparkles className="h-7 w-7 text-emerald-600" />
              ) : (
                <Crown className="h-7 w-7 text-emerald-600" />
              )}
            </div>
            <div className="flex-1">
              <p className="text-sm font-medium text-muted-foreground">Plan actuel</p>
              <p className="text-2xl font-bold">
                {currentSubscriptionType === "annuel"
                  ? "Premium Annuel"
                  : currentSubscriptionType === "mensuel"
                    ? "Premium Mensuel"
                    : "Gratuit"}
              </p>
            </div>
          </div>

          {renewalDate && currentSubscriptionType !== "gratuit" && (
            <div className="flex items-start gap-3 p-4 rounded-lg border bg-card">
              <Calendar className="h-5 w-5 text-emerald-600 mt-0.5" />
              <div>
                <p className="font-medium">Prochain renouvellement</p>
                <p className="text-sm text-muted-foreground">{renewalDate}</p>
              </div>
            </div>
          )}

          {currentSubscriptionType !== "gratuit" && (
            <div className="space-y-3">
              <p className="text-sm font-medium">Avantages inclus :</p>
              <div className="grid gap-2">
                {[
                  "Accès illimité aux annonces",
                  "Mise en avant de vos offres",
                  "Statistiques détaillées",
                  "Support prioritaire",
                ].map((feature, index) => (
                  <div key={index} className="flex items-center gap-2">
                    <div className="flex h-5 w-5 items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-900/20">
                      <Check className="h-3 w-3 text-emerald-600" />
                    </div>
                    <span className="text-sm">{feature}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
        <CardFooter className="flex flex-col sm:flex-row gap-3 pt-6 border-t">
          {currentSubscriptionType === "gratuit" && (
            <ButtonGeneral
              is="green"
              size="lg"
              onClick={() => setIsSubscriptionModalOpen(true)}
              className="w-full sm:w-auto"
            >
              <Crown className="h-4 w-4 mr-2" />
              Passer à Premium
            </ButtonGeneral>
          )}

          {currentSubscriptionType === "mensuel" && (
            <>
              <ButtonGeneral
                is="light"
                size="lg"
                onClick={() => setIsSubscriptionModalOpen(true)}
                className="flex-1 border-2 border-emerald-500 text-emerald-600 hover:bg-emerald-50"
              >
                Modifier le plan
              </ButtonGeneral>
              <ButtonGeneral
                is="red"
                size="lg"
                onClick={() => setIsModalResiliationOpen(true)}
                className="flex-1 border-2"
              >
                Résilier
              </ButtonGeneral>
            </>
          )}

          {currentSubscriptionType === "annuel" && (
            <ButtonGeneral
              is="red"
              size="lg"
              onClick={() => setIsModalResiliationOpen(true)}
              className="w-full sm:w-auto border-2"
            >
              Résilier l'abonnement
            </ButtonGeneral>
          )}
        </CardFooter>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100 dark:bg-emerald-900/20">
              <CreditCard className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <CardTitle>Facturation</CardTitle>
              <CardDescription>Gérez vos factures et moyens de paiement</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-4">
            Accédez à toutes vos factures, mettez à jour vos informations de paiement et consultez votre historique de
            transactions depuis le portail sécurisé Stripe.
          </p>
        </CardContent>
        <CardFooter>
          <ButtonGeneral
            is="light"
            size="lg"
            onClick={handleFacture}
            className="w-full sm:w-auto border-2 border-emerald-500 text-emerald-600 hover:bg-emerald-50"
          >
            <CreditCard className="h-4 w-4 mr-2" />
            Accéder au portail de facturation
          </ButtonGeneral>
        </CardFooter>
      </Card>

      <Dialog open={isModalResiliationOpen} onOpenChange={setIsModalResiliationOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="flex items-center gap-3 mb-2">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/20">
                <AlertCircle className="h-5 w-5 text-red-600" />
              </div>
              <DialogTitle className="text-xl">Résilier l'abonnement</DialogTitle>
            </div>
            <DialogDescription className="text-base pt-2">
              Êtes-vous sûr de vouloir résilier votre abonnement Premium ? Vous perdrez immédiatement l'accès à toutes
              les fonctionnalités premium et cette action est irréversible.
            </DialogDescription>
          </DialogHeader>
          <div className="flex flex-col-reverse sm:flex-row gap-3 mt-6">
            <ButtonGeneral is="light" size="lg" onClick={() => setIsModalResiliationOpen(false)} className="flex-1">
              Annuler
            </ButtonGeneral>
            <ButtonGeneral is="red" size="lg" onClick={handleCancelSubscription} className="flex-1">
              Confirmer la résiliation
            </ButtonGeneral>
          </div>
        </DialogContent>
      </Dialog>

      <SubscriptionModal open={isSubscriptionModalOpen} onClose={() => setIsSubscriptionModalOpen(false)} />
    </div>
  )
}
