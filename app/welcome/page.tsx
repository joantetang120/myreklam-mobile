"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { User, Building2 } from "lucide-react"
import ParticulierForm from "@/components/onboarding/particulier-form"
import ProfessionnelForm from "@/components/onboarding/professionnel-form"
import { useAuthStore } from "@/lib/auth-store"

export default function WelcomePage() {
  const router = useRouter()
  const { setUser, fetchUserInfo } = useAuthStore()
  const [selectedType, setSelectedType] = useState<"particulier" | "professionnel" | null>(null)

  const handleComplete = async () => {
    // Connecter l'utilisateur dans le store après avoir complété le formulaire
    const profileId = localStorage.getItem("profileId")
    if (profileId) {
      console.log("[v0] Welcome - Connecting user after profile completion, ID:", profileId)
      try {
        // Set user ID first to update auth state
        setUser(profileId)
        // Then load user info to get profile details
        await fetchUserInfo()
        console.log("[v0] Welcome - User connected successfully, redirecting to dashboard")
      } catch (error) {
        console.error("[v0] Welcome - Error connecting user:", error)
        // Even on error, set the user ID so they appear logged in
        setUser(profileId)
      }
    } else {
      console.warn("[v0] Welcome - No profileId found in localStorage")
    }
    router.push("/dashboard")
  }

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
