"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { loadStripe } from "@stripe/stripe-js"
import { stripeConfig } from "@/lib/stripe-config"
import { createCheckoutSession } from "@/lib/api"
import { toast } from "sonner"
import { Loader2, Check, X, Sparkles, Zap, TrendingUp, Shield } from "lucide-react"

const stripePromise = loadStripe(stripeConfig.publicKey)

interface SubscriptionModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
}

function SubscriptionModal({ open, onOpenChange }: SubscriptionModalProps) {
  const [isAnnual, setIsAnnual] = useState(true)
  const [loadingPlan, setLoadingPlan] = useState<string | null>(null)

  const handlePayment = async (planType: "free" | "premium") => {
    if (planType === "free") {
      window.location.href = "/payment/success-free"
      return
    }

    setLoadingPlan("premium")

    try {
      // Récupérer l'email et l'userId depuis localStorage
      const userEmail = localStorage.getItem("userEmail")
      const userId = localStorage.getItem("profileId")
      
      if (!userEmail) {
        toast.error("Email utilisateur non trouvé. Veuillez vous reconnecter.")
        setLoadingPlan(null)
        return
      }

      localStorage.setItem("isAnnual", JSON.stringify(isAnnual))
      toast.info("Paiement en cours...")

      const stripe = await stripePromise
      if (!stripe) throw new Error("Stripe n'a pas pu être chargé.")

      const priceId = stripeConfig.plans[isAnnual ? 1 : 2]?.priceId

      if (!priceId) throw new Error("ID de prix non trouvé")

      const successUrl = `${window.location.origin}/payment/success-${isAnnual ? "yearly" : "monthly"}`
      const cancelUrl = `${window.location.origin}/payment/failed`

      console.log("[SubscriptionModal] Sending checkout session request with:", {
        priceId,
        isAnnual,
        price: isAnnual ? 59.9 : 6.99,
        customerEmail: userEmail,
        userId,
      })

      const response = await createCheckoutSession({
        priceId,
        isAnnual,
        price: isAnnual ? 59.9 : 6.99,
        successUrl,
        cancelUrl,
        customerEmail: userEmail,
        userId: userId || undefined,
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

  const featureCategories = [
    {
      category: "TROUVER",
      features: [
        { text: "Consulter les annonces", free: "Illimité", premium: "Illimité" },
        { text: "Commenter ou réagir aux annonces", free: "1/mois", premium: "Illimité" },
        { text: "Obtenir un numéro ou email de contact", free: false, premium: true },
        { text: "Voir les documents partagés", free: false, premium: true },
        { text: "Télécharger les programmes de formation", free: false, premium: true },
      ],
    },
    {
      category: "PROMOUVOIR",
      features: [
        { text: "Poster une annonce", free: "1/mois", premium: "Illimité" },
        { text: "Partager mes coordonnées sur mes annonces", free: false, premium: true },
      ],
    },
    {
      category: "COMMUNIQUER",
      features: [
        { text: "Accès à la messagerie", free: false, premium: true },
        { text: "Convertir mes MY's en récompense", free: false, premium: true },
      ],
    },
    {
      category: "DIFFUSER",
      features: [
        { text: "Profil", free: "Basique", premium: "Premium" },
        { text: "Badge \"Profil vérifié\"", free: false, premium: true },
        { text: "Répondre aux avis", free: false, premium: true },
      ],
    },
  ]

  const premiumBenefits = [
    { icon: Zap, text: "Visibilité maximale" },
    { icon: TrendingUp, text: "Croissance accélérée" },
    { icon: Shield, text: "Support dédié" },
    { icon: Sparkles, text: "Profil vérifié" },
  ]

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="w-[90vw] sm:w-[85vw] md:w-[85vw] lg:w-[80vw] max-w-[1400px] max-h-[95vh] overflow-hidden p-0 gap-0">
        <div className="bg-gradient-to-br from-primary/5 via-accent/5 to-primary/10 px-4 sm:px-6 py-6 sm:py-8 border-b">
          <DialogHeader className="space-y-3">
            <DialogTitle className="text-2xl sm:text-3xl lg:text-4xl font-bold text-center bg-gradient-to-r from-primary via-accent to-primary bg-clip-text text-transparent">
              Choisissez votre abonnement
            </DialogTitle>
            <DialogDescription className="text-center text-sm sm:text-base max-w-2xl mx-auto leading-relaxed">
              Développez votre activité avec Myreklam. Choisissez l'offre qui correspond à vos ambitions.
            </DialogDescription>
          </DialogHeader>
        </div>

        <div className="p-4 sm:p-6 lg:p-8 overflow-y-auto max-h-[calc(95vh-160px)]">
          <div className="grid md:grid-cols-2 gap-4 sm:gap-6 lg:gap-8 mb-6">
            {/* Plan Gratuit */}
            <Card className="p-5 sm:p-6 lg:p-8 flex flex-col justify-between hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 border-2 hover:border-primary/50 bg-gradient-to-br from-background to-muted/20">
              <div>
                <div className="mb-4">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="h-10 w-1 bg-primary rounded-full"></div>
                    <h3 className="text-xl sm:text-2xl lg:text-3xl font-bold">
                      Version <span className="text-primary">GRATUITE</span>
                    </h3>
                  </div>
                  <p className="text-muted-foreground mb-4 text-sm sm:text-base leading-relaxed">
                    Découvrez la plateforme avec des fonctionnalités de base.
                  </p>

                  <div className="mb-6 p-4 sm:p-5 bg-gradient-to-br from-primary/5 to-primary/10 rounded-xl border border-primary/20">
                    <div className="flex items-baseline gap-2 mb-1">
                      <p className="text-4xl sm:text-5xl font-bold text-primary">0€</p>
                      <span className="text-lg text-muted-foreground">/mois</span>
                    </div>
                    <p className="text-xs sm:text-sm text-muted-foreground font-medium">Gratuit à vie • Sans engagement</p>
                  </div>
                </div>

                <div className="space-y-4 mb-6">
                  {featureCategories.map((category, catIndex) => (
                    <div key={catIndex}>
                      <h4 className="text-xs sm:text-sm font-bold text-primary mb-2 uppercase tracking-wider flex items-center gap-2">
                        <div className="h-0.5 w-4 bg-primary rounded"></div>
                        {category.category}
                      </h4>
                      <div className="space-y-2 pl-6">
                        {category.features.map((feature, index) => (
                          <div key={index} className="flex items-start gap-2">
                            {feature.free === true ? (
                              <div className="mt-0.5 p-0.5 bg-green-100 rounded-full">
                                <Check className="w-3 h-3 text-green-600 flex-shrink-0" />
                              </div>
                            ) : feature.free === false ? (
                              <div className="mt-0.5 p-0.5 bg-muted rounded-full">
                                <X className="w-3 h-3 text-muted-foreground flex-shrink-0" />
                              </div>
                            ) : (
                              <div className="mt-0.5 p-0.5 bg-yellow-100 rounded-full">
                                <span className="w-3 h-3 text-yellow-600 flex-shrink-0 text-xs">⚠</span>
                              </div>
                            )}
                            <span className={`text-xs sm:text-sm ${
                              feature.free === true ? "font-medium text-foreground" : 
                              feature.free === false ? "text-muted-foreground line-through" :
                              "font-medium text-foreground"
                            }`}>
                              {feature.text}
                              {typeof feature.free === 'string' && (
                                <span className="text-xs text-muted-foreground ml-1">({feature.free})</span>
                              )}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <Button
                onClick={() => handlePayment("free")}
                variant="outline"
                size="lg"
                className="w-full h-12 sm:h-14 text-sm sm:text-base font-semibold hover:bg-primary/5 hover:border-primary transition-all"
                disabled={loadingPlan !== null}
              >
                <span>Continuer en gratuit</span>
              </Button>
            </Card>

            {/* Plan Premium */}
            <Card className="p-5 sm:p-6 lg:p-8 flex flex-col justify-between border-4 border-accent hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 bg-gradient-to-br from-accent/5 via-white to-accent/10 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-48 sm:w-64 h-48 sm:h-64 bg-accent/10 rounded-full blur-3xl -z-10" />
              <div className="absolute bottom-0 left-0 w-48 sm:w-64 h-48 sm:h-64 bg-primary/10 rounded-full blur-3xl -z-10" />
              <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-accent via-primary to-accent"></div>

              <div>
                <div className="inline-flex items-center gap-1.5 bg-gradient-to-r from-accent to-accent/80 text-white px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-bold mb-3 shadow-lg animate-pulse">
                  <Sparkles className="w-3 h-3 sm:w-4 sm:h-4" />
                  RECOMMANDÉ POUR LES PROS
                </div>

                <div className="mb-4">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="h-10 w-1 bg-accent rounded-full"></div>
                    <h3 className="text-xl sm:text-2xl lg:text-3xl font-bold">
                      Version <span className="text-accent">PREMIUM</span>
                    </h3>
                  </div>
                  <p className="text-muted-foreground mb-4 text-sm sm:text-base leading-relaxed">
                    Maximisez votre visibilité et développez votre activité sans limites.
                  </p>
                </div>

                <div className="mb-6 flex flex-col items-center bg-gradient-to-br from-accent/5 to-accent/10 p-4 sm:p-5 rounded-xl border border-accent/20">
                  <div className="relative w-full max-w-[200px] sm:max-w-[240px] h-11 sm:h-12 bg-background rounded-full p-1 flex items-center mb-4 shadow-inner border border-accent/20">
                    <div
                      className={`absolute h-9 sm:h-10 w-[calc(50%-4px)] bg-gradient-to-r from-accent to-accent/80 rounded-full shadow-lg flex items-center justify-center text-white font-bold transition-all duration-300 ease-in-out ${
                        isAnnual ? "translate-x-[calc(100%+8px)]" : "translate-x-0"
                      }`}
                    >
                      {isAnnual ? "Annuel" : "Mensuel"}
                    </div>
                    <button
                      className={`flex-1 text-xs sm:text-sm font-bold transition-all z-10 ${
                        !isAnnual ? "text-white" : "text-muted-foreground hover:text-foreground"
                      }`}
                      onClick={() => handleSwitch(false)}
                    >
                      Mensuel
                    </button>
                    <button
                      className={`flex-1 text-xs sm:text-sm font-bold transition-all z-10 ${
                        isAnnual ? "text-white" : "text-muted-foreground hover:text-foreground"
                      }`}
                      onClick={() => handleSwitch(true)}
                    >
                      Annuel
                    </button>
                  </div>

                  {isAnnual ? (
                    <div className="text-center">
                      <div className="flex items-baseline justify-center gap-2 mb-2">
                        <p className="text-4xl sm:text-5xl font-bold text-accent">4.99€</p>
                        <span className="text-base sm:text-lg text-muted-foreground">/mois</span>
                      </div>
                      <p className="text-xs sm:text-sm text-muted-foreground mb-2 font-medium">Facturé 59.90€/an</p>
                      <div className="inline-flex items-center gap-1.5 bg-gradient-to-r from-green-100 to-emerald-100 text-green-700 px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-bold shadow-sm">
                        <TrendingUp className="w-3 h-3 sm:w-4 sm:h-4" />
                        Économisez 22.90€/an
                      </div>
                    </div>
                  ) : (
                    <div className="text-center">
                      <div className="flex items-baseline justify-center gap-2 mb-2">
                        <p className="text-4xl sm:text-5xl font-bold text-accent">6.99€</p>
                        <span className="text-base sm:text-lg text-muted-foreground">/mois</span>
                      </div>
                      <p className="text-xs sm:text-sm text-muted-foreground font-medium">Sans engagement • Annulez quand vous voulez</p>
                    </div>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-2 sm:gap-3 mb-6 p-3 sm:p-4 bg-gradient-to-br from-accent/5 to-accent/10 rounded-xl border border-accent/10">
                  {premiumBenefits.map((benefit, index) => (
                    <div key={index} className="flex items-center gap-2 sm:gap-2.5">
                      <div className="p-1.5 sm:p-2 bg-gradient-to-br from-accent/10 to-accent/20 rounded-lg">
                        <benefit.icon className="w-3.5 h-3.5 sm:w-4 sm:h-4 text-accent" />
                      </div>
                      <p className="font-semibold text-[10px] sm:text-xs leading-tight">{benefit.text}</p>
                    </div>
                  ))}
                </div>

                <div className="space-y-4 mb-6">
                  {featureCategories.map((category, catIndex) => (
                    <div key={catIndex}>
                      <h4 className="text-xs sm:text-sm font-bold text-accent mb-2 uppercase tracking-wider flex items-center gap-2">
                        <div className="h-0.5 w-4 bg-accent rounded"></div>
                        {category.category}
                      </h4>
                      <div className="space-y-3 pl-6">
                        {category.features.map((feature, index) => (
                          <div key={index} className="flex items-start gap-2">
                            <div className="mt-0.5 p-0.5 bg-green-100 rounded-full">
                              <Check className="w-3 h-3 text-green-600 flex-shrink-0" />
                            </div>
                            <span className="text-xs sm:text-sm font-medium text-foreground">
                              {feature.text}
                              {typeof feature.premium === 'string' && (
                                <span className="text-xs text-green-700 ml-1 font-bold">({feature.premium})</span>
                              )}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <Button
                onClick={() => handlePayment("premium")}
                size="lg"
                className="w-full h-12 sm:h-14 text-sm sm:text-base font-bold bg-gradient-to-r from-accent via-accent/90 to-accent/80 hover:from-accent/90 hover:via-accent hover:to-accent shadow-lg hover:shadow-2xl transition-all hover:scale-[1.02]"
                disabled={loadingPlan !== null}
              >
                {loadingPlan === "premium" ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 sm:h-5 sm:w-5 animate-spin" />
                    <span>Chargement...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="mr-2 h-4 w-4 sm:h-5 sm:w-5" />
                    <span>Passer à Premium</span>
                  </>
                )}
              </Button>
            </Card>
          </div>

          <div className="text-center text-xs sm:text-sm text-muted-foreground pt-4 sm:pt-6 mt-4 sm:mt-6 border-t">
            <p className="flex flex-wrap items-center justify-center gap-2 sm:gap-3">
              <span className="flex items-center gap-1.5">
                <Shield className="w-3 h-3 sm:w-4 sm:h-4 text-green-600" />
                <span className="font-medium">Paiement sécurisé</span>
              </span>
              <span className="hidden sm:inline text-muted-foreground/50">•</span>
              <span className="font-medium">Annulation à tout moment</span>
              <span className="hidden sm:inline text-muted-foreground/50">•</span>
              <span className="font-medium">Garantie 30 jours</span>
            </p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

export { SubscriptionModal }
export default SubscriptionModal