"use client"

import type React from "react"
import { useState } from "react"
import { X, Mail, Lock, Loader2, Eye, EyeOff } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useAuthStore } from "@/lib/auth-store"
import { isValidEmail } from "@/lib/validation"
import { toast } from "sonner"
import { ForgotPasswordModal } from "./forgot-password-modal"
import { useGoogleLogin } from "@react-oauth/google"

interface SignInModalProps {
  isOpen: boolean
  onClose: () => void
  onSwitchToSignUp: () => void
}

export function SignInModal({ isOpen, onClose, onSwitchToSignUp }: SignInModalProps) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [showForgotPassword, setShowForgotPassword] = useState(false)
  const [isGoogleLoading, setIsGoogleLoading] = useState(false)
  const { login, loginWithGoogle, isLoading: authIsLoading } = useAuthStore()

  // Vérifier si le client ID Google est configuré
  const isGoogleConfigured = typeof window !== "undefined" && !!process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    console.log("[v0] SignIn - Starting signin process")

    if (!isValidEmail(email)) {
      console.log("[v0] SignIn - Invalid email:", email)
      toast.error("Email invalide")
      return
    }

    if (!password) {
      console.log("[v0] SignIn - Missing password")
      toast.error("Mot de passe requis")
      return
    }

    const result = await login(email, password)

    if (result.success) {
      toast.success("Connexion réussie !")
      onClose()
      window.location.href = "/dashboard"
    } else if (result.message) {
      toast.error(result.message)
    }
  }

  const handleGoogleLogin = useGoogleLogin({
    onSuccess: async (tokenResponse) => {
      try {
        setIsGoogleLoading(true)
        console.log("[v0] SignIn - Google OAuth token received")

        // Récupérer les informations utilisateur depuis Google
        const userInfoResponse = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
          headers: {
            Authorization: `Bearer ${tokenResponse.access_token}`,
          },
        })

        if (!userInfoResponse.ok) {
          throw new Error("Failed to fetch user info from Google")
        }

        const userInfo = await userInfoResponse.json()
        console.log("[v0] SignIn - Google user info:", userInfo)

        // Appeler le backend avec les informations Google
        const result = await loginWithGoogle({
          idToken: tokenResponse.access_token,
          email: userInfo.email,
          name: userInfo.name,
          picture: userInfo.picture,
          googleId: userInfo.sub,
        })

        if (result.success) {
          // Connexion réussie (utilisateur existant ou vérifié)
          toast.success(result.isNewUser ? "Compte créé et connexion réussie avec Google !" : "Connexion réussie avec Google !")
          onClose()
          window.location.href = "/dashboard"
        } else if (result.requiresVerification) {
          // Nouvel utilisateur Google - email de vérification requis
          // Ne pas rediriger l'utilisateur, il reste sur la page
          toast.success("Compte créé avec succès !", {
            duration: 8000,
            description: "Un email de vérification a été envoyé. Veuillez vérifier votre boîte email pour activer votre compte.",
          })
          setTimeout(() => {
            toast.info("📧 Email non reçu ?", {
              description: "Vérifiez vos spams ou contactez le support si besoin.",
              duration: 6000,
            })
          }, 2000)
          // Fermer la modal mais ne pas rediriger - l'utilisateur reste sur la page
          onClose()
        } else {
          toast.error(result.message || "Erreur de connexion avec Google")
        }
      } catch (error: any) {
        console.error("[v0] SignIn - Google OAuth error:", error)
        toast.error("Erreur lors de la connexion avec Google")
      } finally {
        setIsGoogleLoading(false)
      }
    },
    onError: () => {
      console.error("[v0] SignIn - Google OAuth login failed")
      toast.error("Erreur lors de la connexion avec Google")
      setIsGoogleLoading(false)
    },
  })

  const isLoading = authIsLoading || isGoogleLoading

  const handleProviderSignIn = async (provider: "google" | "apple" | "facebook") => {
    if (provider === "google") {
      if (!isGoogleConfigured) {
        toast.error("L'authentification Google n'est pas configurée. Veuillez contacter le support.")
        return
      }
      handleGoogleLogin()
    } else {
      toast.info(`Connexion ${provider} sera bientôt disponible`)
    }
  }

  if (!isOpen && !showForgotPassword) return null

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="relative w-full max-w-md rounded-lg bg-background p-6 shadow-lg">
        <button onClick={onClose} className="absolute right-4 top-4 rounded-sm opacity-70 hover:opacity-100">
          <X className="h-4 w-4" />
          <span className="sr-only">Fermer</span>
        </button>

        <div className="mb-6">
          <h2 className="text-2xl font-bold text-foreground">Connexion</h2>
          <p className="text-sm text-muted-foreground mt-1">Connectez-vous à votre compte Myreklam</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <div className="relative">
              <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="email"
                type="email"
                placeholder="votre@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="pl-10"
                disabled={isLoading}
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="password">Mot de passe</Label>
              <button
                type="button"
                onClick={() => {
                  setShowForgotPassword(true)
                  onClose()
                }}
                className="text-xs text-primary hover:underline"
              >
                Mot de passe oublié ?
              </button>
            </div>
            <div className="relative">
              <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="pl-10 pr-10"
                disabled={isLoading}
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-3 text-muted-foreground hover:text-foreground"
              >
                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
          </div>

          <Button type="submit" className="w-full" disabled={isLoading}>
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Connexion...
              </>
            ) : (
              "Se connecter"
            )}
          </Button>
        </form>

        <div className="mt-6">
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-background px-2 text-muted-foreground">Ou continuer avec</span>
            </div>
          </div>

          <div className="mt-4">
            <Button
              type="button"
              variant="outline"
              className="w-full"
              onClick={() => handleProviderSignIn("google")}
              disabled={isLoading}
            >
              <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
              {isGoogleLoading ? "Connexion..." : "Continuer avec Google"}
            </Button>
          </div>
        </div>

        <div className="mt-6 text-center text-sm">
          <span className="text-muted-foreground">Pas encore de compte ? </span>
          <button onClick={onSwitchToSignUp} className="text-primary font-medium hover:underline">
            S'inscrire
          </button>
        </div>
          </div>
        </div>
      )}

      <ForgotPasswordModal
        isOpen={showForgotPassword}
        onClose={() => setShowForgotPassword(false)}
        onBackToSignIn={() => {
          setShowForgotPassword(false)
          // Réouvrir la modal de connexion en appelant une fonction qui gère l'état parent
          // Pour l'instant, on ne fait rien car isOpen est géré par le parent
        }}
      />
    </>
  )
}
