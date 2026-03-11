"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { X, Mail, Lock, Loader2, Eye, EyeOff, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useAuthStore } from "@/lib/auth-store"
import { isValidEmail, isPasswordCompliant } from "@/lib/validation"
import { signUpUser } from "@/lib/api"
import { toast } from "sonner"
import { useGoogleLogin } from "@react-oauth/google"

interface SignUpModalProps {
  isOpen: boolean
  onClose: () => void
  onSwitchToSignIn: () => void
}

export function SignUpModal({ isOpen, onClose, onSwitchToSignIn }: SignUpModalProps) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [refParrainCode, setRefParrainCode] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [passwordMatchError, setPasswordMatchError] = useState(false)
  const [isGoogleLoading, setIsGoogleLoading] = useState(false)

  const { loginWithGoogle } = useAuthStore()

  const passwordValidation = {
    minLength: password.length >= 8,
    hasNumber: /\d/.test(password),
    hasLetter: /[a-zA-Z]/.test(password),
    hasSpecialChar: /[!@#$%^&*(),.?":{}|<>]/.test(password),
  }

  const passwordsMatch = password === confirmPassword
  const showPasswordError = confirmPassword.length > 0 && !passwordsMatch

  useEffect(() => {
    if (typeof window !== "undefined") {
      // Vérifier d'abord l'URL pour le paramètre ref-parrain
      const params = new URLSearchParams(window.location.search)
      const refParrainFromUrl = params.get("ref-parrain") || params.get("refParrain")
      
      // Vérifier aussi le localStorage pour un code parrain stocké
      const refParrainFromStorage = localStorage.getItem("refParrain")
      
      // Priorité: URL > localStorage
      if (refParrainFromUrl) {
        setRefParrainCode(refParrainFromUrl)
        localStorage.setItem("refParrain", refParrainFromUrl)
      } else if (refParrainFromStorage) {
        setRefParrainCode(refParrainFromStorage)
      }
    }
  }, [])

  // Vérifier si le client ID Google est configuré
  const isGoogleConfigured = typeof window !== "undefined" && !!process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID

  const handleGoogleLogin = useGoogleLogin({
    onSuccess: async (tokenResponse) => {
      try {
        setIsGoogleLoading(true)
        console.log("[v0] SignUp - Google OAuth token received")

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
        console.log("[v0] SignUp - Google user info:", userInfo)

        // Appeler le backend avec les informations Google
        const result = await loginWithGoogle({
          idToken: tokenResponse.access_token,
          email: userInfo.email,
          name: userInfo.name,
          picture: userInfo.picture,
          googleId: userInfo.sub,
        })

        console.log("[v0] SignUp - Google login result:", result)
        console.log("[v0] SignUp - Result details:", {
          success: result.success,
          requiresVerification: result.requiresVerification,
          isNewUser: result.isNewUser,
          hasToken: !!result.token,
          hasEmail: !!result.email
        })

        // PRIORITÉ 1: Si success=true ET isNewUser=true, rediriger vers /welcome pour choisir le type de compte
        if (result.success && result.isNewUser) {
          console.log("[v0] SignUp - Nouvel utilisateur Google avec success=true, redirection vers /welcome")
          // Stocker l'ID utilisateur dans localStorage pour la page welcome
          if (result.id) {
            localStorage.setItem("profileId", result.id)
            console.log("[v0] SignUp - profileId stocké:", result.id)
          }
          onClose()
          window.location.href = "/welcome"
          return
        }

        // PRIORITÉ 2: Si requiresVerification, rediriger vers /welcome pour choisir le type de compte
        if (result.requiresVerification) {
          // Nouvel utilisateur Google - rediriger vers /welcome
          console.log("[v0] SignUp - Nouvel utilisateur détecté (requiresVerification=true), redirection vers /welcome")
          // Stocker l'ID utilisateur dans localStorage pour la page welcome
          if (result.id) {
            localStorage.setItem("profileId", result.id)
            console.log("[v0] SignUp - profileId stocké:", result.id)
          }
          onClose()
          window.location.href = "/welcome"
          return
        }

        // PRIORITÉ 3: Si success=true ET que ce n'est PAS un nouvel utilisateur, c'est un utilisateur existant vérifié -> rediriger vers dashboard
        if (result.success && !result.isNewUser) {
          console.log("[v0] SignUp - Utilisateur existant vérifié, redirection vers /dashboard")
          toast.success("Connexion réussie avec Google !")
          onClose()
          window.location.href = "/dashboard"
          return
        }

        // Fallback: Erreur
        toast.error(result.message || "Erreur de connexion avec Google")
      } catch (error: any) {
        console.error("[v0] SignUp - Google OAuth error:", error)
        toast.error("Erreur lors de la connexion avec Google")
      } finally {
        setIsGoogleLoading(false)
      }
    },
    onError: () => {
      console.error("[v0] SignUp - Google OAuth login failed")
      toast.error("Erreur lors de la connexion avec Google")
      setIsGoogleLoading(false)
    },
  })

  const handleProviderSignIn = async (provider: "google" | "apple" | "facebook") => {
    if (provider === "google") {
      if (!isGoogleConfigured) {
        toast.error("L'authentification Google n'est pas configurée. Veuillez contacter le support.")
        return
      }
      handleGoogleLogin()
    } else {
      toast.info(`Inscription ${provider} sera bientôt disponible`)
    }
  }

   // AJOUT: Fonction pour gérer le changement du mot de passe de confirmation
  const handleConfirmPasswordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setConfirmPassword(value)
    
    // Réinitialiser l'erreur si les mots de passe correspondent maintenant
    if (passwordMatchError && value === password) {
      setPasswordMatchError(false)
    }
  }

  // Réinitialiser les états quand le modal se rouvre
  useEffect(() => {
    if (isOpen) {
      setEmail("")
      setPassword("")
      setConfirmPassword("")
      setPasswordMatchError(false)
    }
  }, [isOpen])

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    console.log("[v0] SignUp - Starting signup process")

    // Validation email
    if (!isValidEmail(email)) {
      console.log("[v0] SignUp - Invalid email:", email)
      toast.error("Email invalide")
      return
    }

    // Validation mot de passe requis
    if (!password) {
      console.log("[v0] SignUp - Missing password")
      toast.error("Mot de passe requis pour l'inscription")
      return
    }

    // Validation correspondance mots de passe
    const pwd = password.trim()
    const confirm = confirmPassword.trim()

    if (pwd !== confirm) {
      console.log("[v0] SignUp - Passwords do not match")
      setPasswordMatchError(true)
      toast.error("Les deux mots de passe ne sont pas identiques")
      return
    }

    // Validation complexité mot de passe
    if (!isPasswordCompliant(pwd)) {
      console.log("[v0] SignUp - Password not compliant")
      toast.error("Le mot de passe doit contenir ≥8 caractères, 1 chiffre, 1 lettre et 1 caractère spécial.")
      return
    }

    setIsSubmitting(true)

    try {
      const payload = {
        userEmail: email,
        userPassword: password,
        Name: " ",
        Link: window.location.origin,
        Method: "create" as const,
        refParrain: refParrainCode || null,
      }

      console.log("[v0] SignUp - Sending request to API")
      const response = await signUpUser(payload)

      console.log("[v0] SignUp - API response:", response)
      console.log("[v0] SignUp - emailSent status:", response.emailSent)

      if (response.status === "success") {
        if (refParrainCode) {
          localStorage.setItem("refParrain", refParrainCode)
          console.log("[v0] SignUp - refParrain stored:", refParrainCode)
        }

        // Stocker l'ID utilisateur si disponible
        if (response.id || response.data?.id) {
          localStorage.setItem("profileId", response.id || response.data.id)
          console.log("[v0] SignUp - profileId stored:", response.id || response.data.id)
        }

        // Vérifier si l'email a vraiment été envoyé
        // L'API retourne soit emailSent=true, soit un message contenant "email envoyé"
        const emailActuallySent = 
          response.emailSent === true || 
          response.emailSent === "true" || 
          response.emailSent === 1 ||
          (response.message && response.message.toLowerCase().includes("email envoyé"))
        
        console.log("[v0] SignUp - Inscription classique réussie, emailSent:", emailActuallySent)
        console.log("[v0] SignUp - Response message:", response.message)
        
        if (emailActuallySent) {
          // Email envoyé avec succès - fermer le modal et afficher le toast
          onClose()
          toast.success("Inscription réussie !", {
            duration: 8000,
            description: "Un email de vérification a été envoyé. Vérifiez votre boîte email pour activer votre compte.",
          })
          
          setTimeout(() => {
            toast.info("📧 Email non reçu ?", {
              description: "Vérifiez vos spams ou contactez le support si besoin.",
              duration: 6000,
            })
          }, 3000)
        } else {
          // Email NON envoyé - problème serveur - fermer le modal et afficher l'erreur
          onClose()
          console.error("[v0] SignUp - ERREUR: Email non envoyé par le serveur (emailSent: false)")
          toast.error("⚠️ Compte créé mais email non envoyé", {
            duration: 10000,
            description: "Votre compte a été créé mais l'email de vérification n'a pas pu être envoyé. Veuillez contacter le support avec votre email: " + email,
          })
          
          // Afficher aussi un toast d'information pour contacter le support
          setTimeout(() => {
            toast.warning("🔧 Problème technique détecté", {
              description: "Le serveur ne peut pas envoyer d'emails. Contactez le support technique pour activer votre compte manuellement.",
              duration: 10000,
            })
          }, 2000)
        }
      } else {
        console.log("[v0] SignUp - Signup failed:", response.message)
        toast.error(response.message || "Erreur lors de l'inscription")
      }
    } catch (error) {
      console.error("[v0] SignUp - Error:", error)
      toast.error("Une erreur est survenue lors de l'inscription.")
    } finally {
      setIsSubmitting(false)
    }
  }

  const isLoading = isSubmitting || isGoogleLoading

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
        <div className="relative w-full max-w-md rounded-lg bg-background p-6 shadow-lg max-h-[90vh] overflow-y-auto">
          <button onClick={onClose} className="absolute right-4 top-4 rounded-sm opacity-70 hover:opacity-100">
            <X className="h-4 w-4" />
            <span className="sr-only">Fermer</span>
          </button>

          <div className="mb-6">
            <h2 className="text-2xl font-bold text-foreground">Inscription</h2>
            <p className="text-sm text-muted-foreground mt-1">Créez votre compte Myreklam gratuitement</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="signup-email">Email</Label>
              <div className="relative">
                <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="signup-email"
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
              <Label htmlFor="signup-password">Mot de passe</Label>
              <div className="relative">
                <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="signup-password"
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
              <div className="space-y-1 text-xs">
                <div
                  className={`flex items-center gap-1 ${passwordValidation.minLength ? "text-green-600" : "text-muted-foreground"}`}
                >
                  {passwordValidation.minLength && <Check className="h-3 w-3" />}
                  <span>Minimum 8 caractères</span>
                </div>
                <div
                  className={`flex items-center gap-1 ${passwordValidation.hasNumber ? "text-green-600" : "text-muted-foreground"}`}
                >
                  {passwordValidation.hasNumber && <Check className="h-3 w-3" />}
                  <span>Au moins 1 chiffre</span>
                </div>
                <div
                  className={`flex items-center gap-1 ${passwordValidation.hasLetter ? "text-green-600" : "text-muted-foreground"}`}
                >
                  {passwordValidation.hasLetter && <Check className="h-3 w-3" />}
                  <span>Au moins 1 lettre</span>
                </div>
                <div
                  className={`flex items-center gap-1 ${passwordValidation.hasSpecialChar ? "text-green-600" : "text-muted-foreground"}`}
                >
                  {passwordValidation.hasSpecialChar && <Check className="h-3 w-3" />}
                  <span>Au moins 1 caractère spécial (!@#$%^&*...)</span>
                </div>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="confirm-password">Confirmer le mot de passe</Label>
              <div className="relative">
                <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  id="confirm-password"
                  type={showConfirmPassword ? "text" : "password"}
                  placeholder="••••••••"
                  value={confirmPassword}
                  // onChange={(e) => setConfirmPassword(e.target.value)}
                  onChange={handleConfirmPasswordChange}
                  className={`pl-10 pr-10 ${
                    showPasswordError || passwordMatchError 
                      ? 'border-red-500 focus:border-red-500 focus:ring-red-500' 
                      : passwordsMatch && confirmPassword.length > 0 
                      ? 'border-green-500 focus:border-green-500 focus:ring-green-500'
                      : ''
                  }`}
                  className="pl-10 pr-10"
                  disabled={isLoading}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-3 top-3 text-muted-foreground hover:text-foreground"
                >
                  {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {/* AJOUT: Message de validation en temps réel */}
              {confirmPassword.length > 0 && (
                <div className={`text-xs flex items-center gap-1 ${
                  passwordsMatch ? 'text-green-600' : 'text-red-500'
                }`}>
                  {passwordsMatch ? (
                    <>
                      <Check className="h-3 w-3" />
                      <span>Les mots de passe correspondent</span>
                    </>
                  ) : (
                    <>
                      <X className="h-3 w-3" />
                      <span>Les mots de passe ne correspondent pas</span>
                    </>
                  )}
                </div>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="refParrain" className="flex items-center gap-2">
                <span>Code parrain</span>
                <span className="text-xs text-muted-foreground font-normal">(optionnel)</span>
              </Label>
              <Input
                id="refParrain"
                type="text"
                placeholder="Entrez le code parrain si vous en avez un"
                value={refParrainCode}
                onChange={(e) => setRefParrainCode(e.target.value)}
                disabled={isLoading}
                className={refParrainCode ? "bg-green-50 border-green-300" : ""}
              />
              {refParrainCode && (
                <p className="text-xs text-green-600 flex items-center gap-1">
                  <Check className="h-3 w-3" />
                  Code parrain détecté ! Vous bénéficierez d'avantages supplémentaires.
                </p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Inscription...
                </>
              ) : (
                "Créer mon compte"
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
                {isGoogleLoading ? "Inscription..." : "Continuer avec Google"}
              </Button>
            </div>
          </div>

          <div className="mt-6 text-center text-sm">
            <span className="text-muted-foreground">Déjà un compte ? </span>
            <button onClick={onSwitchToSignIn} className="text-primary font-medium hover:underline">
              Se connecter
            </button>
          </div>
        </div>
      </div>

    </>
  )
}
