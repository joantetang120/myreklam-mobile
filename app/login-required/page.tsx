"use client"

import { useEffect, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Lock, ArrowRight, UserPlus, LogIn } from "lucide-react"
import { SignInModal } from "@/components/auth/sign-in-modal"
import { SignUpModal } from "@/components/auth/sign-up-modal"

export default function LoginRequiredPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [redirectPath, setRedirectPath] = useState<string>("/")
  const [showSignIn, setShowSignIn] = useState(false)
  const [showSignUp, setShowSignUp] = useState(false)

  useEffect(() => {
    const profileId = localStorage.getItem("profileId")
    if (profileId) {
      // User is logged in, redirect to intended page or dashboard
      const redirect = searchParams.get("redirect")
      router.push(redirect || "/dashboard")
      return
    }

    const redirect = searchParams.get("redirect")
    if (redirect) {
      setRedirectPath(redirect)
    }
  }, [searchParams, router])

  const getActionMessage = () => {
    if (redirectPath.includes("/announcements/create")) {
      return "poster une annonce"
    }
    if (redirectPath.includes("/profil-public")) {
      return "voir les profils publics"
    }
    if (redirectPath.includes("/messages")) {
      return "accéder à vos messages"
    }
    if (redirectPath.includes("/mes-recherches")) {
      return "sauvegarder vos recherches"
    }
    if (redirectPath.includes("/dashboard")) {
      return "accéder à votre tableau de bord"
    }
    return "effectuer cette action"
  }

  return (
    <>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary/5 via-background to-secondary/5 px-4 py-12">
        <Card className="w-full max-w-lg shadow-xl">
          <CardHeader className="text-center space-y-4">
            <div className="mx-auto w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
              <Lock className="w-8 h-8 text-primary" />
            </div>
            <CardTitle className="text-2xl font-bold">Connexion requise</CardTitle>
            <CardDescription className="text-base">Vous devez être connecté pour {getActionMessage()}</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="space-y-3">
              <Button onClick={() => setShowSignIn(true)} className="w-full h-12 text-base" size="lg">
                <LogIn className="w-5 h-5 mr-2" />
                Se connecter
                <ArrowRight className="w-5 h-5 ml-2" />
              </Button>
              <Button
                onClick={() => setShowSignUp(true)}
                variant="outline"
                className="w-full h-12 text-base bg-transparent"
                size="lg"
              >
                <UserPlus className="w-5 h-5 mr-2" />
                Créer un compte
              </Button>
            </div>

            <div className="pt-4 border-t">
              <p className="text-sm text-muted-foreground text-center mb-4">Avec un compte Myreklam, vous pouvez :</p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>Poster des annonces gratuitement</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>Postuler aux offres d'emploi et formations</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>Sauvegarder vos annonces favorites</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>Contacter directement les annonceurs</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">✓</span>
                  <span>Gagner des récompenses avec le programme ambassadeur</span>
                </li>
              </ul>
            </div>

            <Button variant="ghost" className="w-full" onClick={() => router.back()}>
              Retour
            </Button>
          </CardContent>
        </Card>
      </div>

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
