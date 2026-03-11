"use client"

import { useEffect, useState, Suspense } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { verifyEmail } from "@/lib/api"
import { useAuthStore } from "@/lib/auth-store"
import { Loader2, CheckCircle2, XCircle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { User, Building2 } from "lucide-react"
import ParticulierForm from "@/components/onboarding/particulier-form"
import ProfessionnelForm from "@/components/onboarding/professionnel-form"

function VerifyContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { setUser, fetchUserInfo } = useAuthStore()
  const [message, setMessage] = useState("Vérification en cours...")
  const [status, setStatus] = useState<"loading" | "success" | "error" | "chooseType">("loading")
  const [selectedType, setSelectedType] = useState<"particulier" | "professionnel" | null>(null)

  const token = searchParams?.get("token")
  const email = searchParams?.get("email")
  const isPwd = searchParams?.get("pwd")

  useEffect(() => {
    // Si c'est un reset de mot de passe, vérifier et rediriger vers dashboard
    if (isPwd && token && email) {
      verifyAndRedirect()
    } 
    // Si c'est une inscription, vérifier et afficher le choix de type de compte
    else if (!isPwd && token && email) {
      verifyAndShowTypeChoice()
    }
    // Si les paramètres sont manquants
    else if (!token || !email) {
      setMessage("Paramètres manquants. Veuillez vérifier le lien.")
      setStatus("error")
    }
  }, [email, token, isPwd])

  const verifyAndShowTypeChoice = async () => {
    if (!email || !token) {
      setMessage("Paramètres manquants. Veuillez vérifier le lien.")
      setStatus("error")
      return
    }

    try {
      console.log("[v0] Verifying email for new user:", email)
      const response = await verifyEmail({
        userEmail: email,
        token: token,
        Method: "verify",
      })

      console.log("[v0] Verification response:", response)

      if (response.status === "success" && response.id) {
        localStorage.setItem("profileId", response.id)
        setUser(response.id)
        setStatus("chooseType")
      } else {
        setMessage(response.message || "Token invalide ou expiré")
        setStatus("error")
      }
    } catch (error) {
      console.error("[v0] Error verifying email:", error)
      setMessage("Une erreur est survenue lors de la vérification")
      setStatus("error")
    }
  }

  const verifyAndRedirect = async () => {
    if (!email || !token) {
      setMessage("Paramètres manquants. Veuillez vérifier le lien.")
      setStatus("error")
      return
    }

    try {
      console.log("[v0] Verifying email for password reset:", email)
      const response = await verifyEmail({
        userEmail: email,
        token: token,
        Method: "verify",
      })

      console.log("[v0] Verification response:", response)

      if (response.status === "success") {
        const userId = response.data?.id || response.id
        localStorage.setItem("profileId", userId)
        setUser(userId)
        await fetchUserInfo()
        setMessage("Votre compte a été vérifié avec succès. Vous serez redirigé.")
        setStatus("success")
        setTimeout(() => {
          router.push("/dashboard")
        }, 2000)
      } else {
        setMessage(response.message || "Erreur lors de la vérification")
        setStatus("error")
      }
    } catch (error) {
      console.error("[v0] Verification error:", error)
      setMessage("Une erreur est survenue lors de la vérification")
      setStatus("error")
    }
  }

  const handleComplete = async () => {
    // Après avoir complété le profil, rediriger vers le dashboard
    console.log("[v0] Profile completed, redirecting to dashboard")
    setMessage("Profil complété avec succès ! Redirection...")
    setStatus("success")
    setTimeout(() => {
      router.push("/dashboard")
    }, 1500)
  }

  // Si l'utilisateur doit choisir son type de compte
  if (status === "chooseType") {
    if (selectedType === "particulier") {
      return <ParticulierForm onComplete={handleComplete} />
    }

    if (selectedType === "professionnel") {
      return <ProfessionnelForm onComplete={handleComplete} />
    }

    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
        <div className="max-w-4xl w-full">
          <div className="text-center mb-12">
            <h1 className="text-4xl font-bold mb-4">Bienvenue sur Myreklam !</h1>
            <p className="text-xl text-muted-foreground">Pour commencer, dites-nous qui vous êtes</p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <Card
              className="p-8 cursor-pointer hover:shadow-xl transition-all hover:scale-105 border-2 hover:border-primary"
              onClick={() => setSelectedType("particulier")}
            >
              <div className="text-center">
                <div className="w-20 h-20 mx-auto mb-6 bg-primary/10 rounded-full flex items-center justify-center">
                  <User className="w-10 h-10 text-primary" />
                </div>
                <h2 className="text-2xl font-bold mb-3">Particulier</h2>
                <p className="text-muted-foreground mb-6">
                  Je souhaite découvrir et partager des bons plans, événements et opportunités
                </p>
                <Button size="lg" className="w-full">
                  Continuer en tant que particulier
                </Button>
              </div>
            </Card>

            <Card
              className="p-8 cursor-pointer hover:shadow-xl transition-all hover:scale-105 border-2 hover:border-primary"
              onClick={() => setSelectedType("professionnel")}
            >
              <div className="text-center">
                <div className="w-20 h-20 mx-auto mb-6 bg-accent/10 rounded-full flex items-center justify-center">
                  <Building2 className="w-10 h-10 text-accent" />
                </div>
                <h2 className="text-2xl font-bold mb-3">Professionnel</h2>
                <p className="text-muted-foreground mb-6">
                  Je représente une entreprise et souhaite promouvoir mes services et offres
                </p>
                <Button size="lg" variant="secondary" className="w-full">
                  Continuer en tant que professionnel
                </Button>
              </div>
            </Card>
          </div>
        </div>
      </div>
    )
  }

  // Affichage pour la vérification (reset de mot de passe ou après complétion du profil)
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
      <div className="max-w-md w-full bg-card rounded-2xl shadow-xl p-8 text-center">
        <div className="mb-6">
          {status === "loading" && <Loader2 className="w-16 h-16 mx-auto text-primary animate-spin" />}
          {status === "success" && <CheckCircle2 className="w-16 h-16 mx-auto text-green-600" />}
          {status === "error" && <XCircle className="w-16 h-16 mx-auto text-red-600" />}
        </div>
        <h1 className="text-2xl font-bold mb-4">Vérification de votre compte</h1>
        <p className="text-muted-foreground">{message}</p>
      </div>
    </div>
  )
}

export default function VerifyPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <Loader2 className="w-8 h-8 animate-spin text-primary" />
        </div>
      }
    >
      <VerifyContent />
    </Suspense>
  )
}
