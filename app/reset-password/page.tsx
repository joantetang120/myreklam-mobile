"use client"

import { useEffect, useState } from "react"
import { useSearchParams, useRouter } from "next/navigation"
import { ResetPasswordModal } from "@/components/auth/reset-password-modal"
import { SignInModal } from "@/components/auth/sign-in-modal"
import { SignUpModal } from "@/components/auth/sign-up-modal"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { AlertCircle } from "lucide-react"
import { Button } from "@/components/ui/button"

export default function ResetPasswordPage() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const [showResetModal, setShowResetModal] = useState(false)
  const [showSignInModal, setShowSignInModal] = useState(false)
  const [showSignUpModal, setShowSignUpModal] = useState(false)
  const [email, setEmail] = useState("")
  const [token, setToken] = useState("")
  const [hasParams, setHasParams] = useState(true)

  useEffect(() => {
    // Récupérer les paramètres de l'URL
    const emailParam = searchParams.get("email")
    const tokenParam = searchParams.get("token")

    console.log("Reset password page - URL params:", { email: emailParam, token: tokenParam })
    console.log("Full URL:", window.location.href)

    if (emailParam) {
      setEmail(emailParam)
      setToken(tokenParam || "")
      setShowResetModal(true)
      setHasParams(true)
    } else {
      // Si pas d'email, afficher un message d'erreur
      setHasParams(false)
    }
  }, [searchParams])

  const handleCloseReset = () => {
    setShowResetModal(false)
    // Rediriger vers la page d'accueil après fermeture
    router.push("/")
  }

  const handlePasswordResetSuccess = () => {
    // Fermer la modal de reset et ouvrir la modal de connexion
    setShowResetModal(false)
    setShowSignInModal(true)
  }

  if (!hasParams) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary/5 via-background to-secondary/5 p-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="mx-auto w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-4">
              <AlertCircle className="w-6 h-6 text-red-600" />
            </div>
            <CardTitle>Lien invalide</CardTitle>
            <CardDescription>
              Le lien de réinitialisation est invalide ou a expiré.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-muted-foreground text-center">
              Veuillez demander un nouveau lien de réinitialisation depuis la page de connexion.
            </p>
            <Button onClick={() => router.push("/")} className="w-full">
              Retour à l'accueil
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <>
      {/* Iframe de la page d'accueil en arrière-plan */}
      <div className="fixed inset-0 -z-10">
        <iframe
          src="/"
          className="w-full h-full border-0"
          title="Page d'accueil"
        />
      </div>

      {/* Modals */}
      <ResetPasswordModal
        isOpen={showResetModal}
        onClose={handleCloseReset}
        onSuccess={handlePasswordResetSuccess}
        email={email}
        token={token}
      />
      
      <SignInModal
        isOpen={showSignInModal}
        onClose={() => {
          setShowSignInModal(false)
          router.push("/")
        }}
        onSwitchToSignUp={() => {
          setShowSignInModal(false)
          setShowSignUpModal(true)
        }}
      />
      
      <SignUpModal
        isOpen={showSignUpModal}
        onClose={() => {
          setShowSignUpModal(false)
          router.push("/")
        }}
        onSwitchToSignIn={() => {
          setShowSignUpModal(false)
          setShowSignInModal(true)
        }}
      />
    </>
  )
}
