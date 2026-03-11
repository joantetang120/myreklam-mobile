"use client"

import { useState, useEffect } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { loadStripe } from "@stripe/stripe-js"
import { stripeConfig } from "@/lib/stripe-config"
import { createCheckoutSession } from "@/lib/api"
import { toast } from "sonner"
import { Loader2 } from "lucide-react"
import FeaturesTable from "@/components/subscription/features-table"

const stripePromise = loadStripe(stripeConfig.publicKey)

export default function SubscriptionPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [isAnnual, setIsAnnual] = useState(true)
  const [loadingPlan, setLoadingPlan] = useState<string | null>(null)
  const [isConnected, setIsConnected] = useState(false)

  const success = searchParams.get("success")
  const canceled = searchParams.get("canceled")
  const action = searchParams.get("action")
  const plan = searchParams.get("plan")

  useEffect(() => {
    if (success) {
      toast.success("Paiement réussi! Votre abonnement a été activé.")
    }
    if (canceled) {
      toast.info("Le processus de paiement a été annulé.")
    }

    const userId = localStorage.getItem("profileId")
    if (userId) {
      setIsConnected(true)
    } else {
      router.push("/?login=true")
    }

    // Auto-trigger subscription if params present
    if (isConnected && action === "subscribe" && plan) {
      if (plan === "yearly" || plan === "annual") {
        setIsAnnual(true)
      } else if (plan === "monthly") {
        setIsAnnual(false)
      }
      handleAutoPayment()
    }
  }, [success, canceled, action, plan, isConnected, router])

  const handleAutoPayment = async () => {
    try {
      if (!isConnected) {
        router.push("/?login=true")
        return
      }

      setLoadingPlan("premium")
      localStorage.setItem("isAnnual", JSON.stringify(isAnnual))
      toast.info("Initialisation du paiement...")

      const stripe = await stripePromise
      if (!stripe) throw new Error("Stripe n'a pas pu être chargé.")

      const priceId = stripeConfig.plans[isAnnual ? 1 : 2]?.priceId

      if (!priceId) throw new Error("ID de prix non trouvé")

      const successUrl = `${window.location.origin}/payment/success-${isAnnual ? "yearly" : "monthly"}`
      const cancelUrl = `${window.location.origin}/payment/failed`

      const response = await createCheckoutSession({
        priceId,
        isAnnual,
        price: 5,
        successUrl,
        cancelUrl,
      })

      const session = response.data
      localStorage.setItem("customerId", session.customerId)

      await stripe.redirectToCheckout({
        sessionId: session.id,
      })
    } catch (error: any) {
      console.error("Erreur lors du processus de paiement automatique:", error)
      toast.error("Une erreur s'est produite. Veuillez réessayer plus tard.")
      setLoadingPlan(null)
    }
  }

  const handlePayment = async (planType: "free" | "premium") => {
    if (planType === "free") {
      router.push("/payment/success-free")
      return
    }

    setLoadingPlan("premium")

    try {
      localStorage.setItem("isAnnual", JSON.stringify(isAnnual))
      toast.info("Paiement en cours...")

      const stripe = await stripePromise
      if (!stripe) throw new Error("Stripe n'a pas pu être chargé.")

      const priceId = stripeConfig.plans[isAnnual ? 1 : 2]?.priceId

      if (!priceId) throw new Error("ID de prix non trouvé")

      const successUrl = `${window.location.origin}/payment/success-${isAnnual ? "yearly" : "monthly"}`
      const cancelUrl = `${window.location.origin}/payment/failed`

      const response = await createCheckoutSession({
        priceId,
        isAnnual,
        price: isAnnual ? 59.9 : 6.99,
        successUrl,
        cancelUrl,
      })

      const session = response.data
      console.log("[v0] Session Stripe:", session)
      localStorage.setItem("customerId", session.customerId)

      await stripe.redirectToCheckout({
        sessionId: session.id,
      })
    } catch (error: any) {
      console.error("Erreur lors du processus de paiement:", error)
      toast.error("Une erreur s'est produite. Veuillez réessayer plus tard.")
    } finally {
      setLoadingPlan(null)
    }
  }

  const handleSwitch = (choice: boolean) => {
    setIsAnnual(choice)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-accent/5 py-16 px-4">
      <div className="max-w-6xl mx-auto">
        <h2 className="text-4xl font-bold text-center mb-4">Choisissez votre plan</h2>
        <p className="text-center text-muted-foreground mb-12">
          Sélectionnez l'offre qui correspond le mieux à vos besoins
        </p>

        <div className="grid md:grid-cols-2 gap-8 mb-16">
          {/* Plan Gratuit */}
          <Card className="p-8 flex flex-col justify-between hover:shadow-lg transition-shadow">
            <div>
              <h3 className="text-2xl font-semibold mb-2">
                Version <span className="text-primary">GRATUITE</span>
              </h3>
              <p className="text-muted-foreground mb-4">
                Explorez la plateforme avec ses fonctionnalités de base. Profitez-en à vie, sans aucun frais !
              </p>
              <p className="text-sm text-muted-foreground mb-6">
                Limité : pas de publication d'offres d'emploi, formations ou appels d'offres.
              </p>
              <div className="mb-6">
                <p className="text-5xl font-bold text-primary">0€</p>
                <p className="text-sm text-muted-foreground">Aucune carte bancaire nécessaire</p>
              </div>
            </div>
            <Button
              onClick={() => handlePayment("free")}
              variant="outline"
              size="lg"
              className="w-full"
              disabled={loadingPlan !== null}
            >
              Rester en version gratuite
            </Button>
          </Card>

          {/* Plan Premium */}
          <Card className="p-8 flex flex-col justify-between border-2 border-accent hover:shadow-xl transition-shadow bg-gradient-to-br from-accent/5 to-accent/10">
            <div>
              <div className="inline-block bg-accent text-accent-foreground px-3 py-1 rounded-full text-sm font-semibold mb-4">
                RECOMMANDÉ
              </div>
              <h3 className="text-2xl font-semibold mb-2">
                Version <span className="text-accent">PREMIUM</span>
              </h3>
              <p className="text-muted-foreground mb-6">
                Accédez à toutes les fonctionnalités de la plateforme, boostez votre visibilité et bénéficiez de
                recommandations.
              </p>

              {/* Switch Mensuel/Annuel */}
              <div className="mb-6 flex flex-col items-center">
                <div className="relative w-48 h-12 bg-muted rounded-full p-1 flex items-center mb-4">
                  <div
                    className={`absolute h-10 w-24 bg-accent rounded-full shadow-md flex items-center justify-center text-accent-foreground font-bold transition-transform duration-300 ${
                      isAnnual ? "translate-x-24" : "translate-x-0"
                    }`}
                  >
                    {isAnnual ? "Annuel" : "Mensuel"}
                  </div>
                  <button
                    className={`flex-1 text-sm font-semibold transition z-10 ${
                      !isAnnual ? "text-accent-foreground" : "text-muted-foreground"
                    }`}
                    onClick={() => handleSwitch(false)}
                  >
                    Mensuel
                  </button>
                  <button
                    className={`flex-1 text-sm font-semibold transition z-10 ${
                      isAnnual ? "text-accent-foreground" : "text-muted-foreground"
                    }`}
                    onClick={() => handleSwitch(true)}
                  >
                    Annuel
                  </button>
                </div>

                {isAnnual ? (
                  <div className="text-center">
                    <p className="text-5xl font-bold text-accent">4.99€</p>
                    <p className="text-sm text-muted-foreground">Facturé 59.90€/an</p>
                    <p className="text-sm text-green-600 font-semibold">Vous économisez 22.90€</p>
                    <p className="text-sm text-accent font-semibold">1 mois offert</p>
                  </div>
                ) : (
                  <div className="text-center">
                    <p className="text-5xl font-bold text-accent">6.99€</p>
                    <p className="text-sm text-muted-foreground">Facturé mensuellement</p>
                  </div>
                )}
              </div>
            </div>
            <Button
              onClick={() => handlePayment("premium")}
              size="lg"
              className="w-full"
              disabled={loadingPlan !== null}
            >
              {loadingPlan === "premium" ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Chargement...
                </>
              ) : (
                "Commencer maintenant"
              )}
            </Button>
          </Card>
        </div>

        {/* Features Table */}
        <FeaturesTable />
      </div>
    </div>
  )
}
