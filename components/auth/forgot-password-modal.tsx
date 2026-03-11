"use client"

import type React from "react"
import { useState } from "react"
import { X, Mail, Loader2, ArrowLeft } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { isValidEmail } from "@/lib/validation"
import { toast } from "sonner"
import { config } from "@/lib/config"

interface ForgotPasswordModalProps {
  isOpen: boolean
  onClose: () => void
  onBackToSignIn?: () => void
}

export function ForgotPasswordModal({ isOpen, onClose, onBackToSignIn }: ForgotPasswordModalProps) {
  const [email, setEmail] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [emailSent, setEmailSent] = useState(false)
  const [errorMessage, setErrorMessage] = useState("")

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!isValidEmail(email)) {
      toast.error("Veuillez entrer une adresse email valide")
      return
    }

    setIsLoading(true)
    setErrorMessage("") // Réinitialiser le message d'erreur

    try {
      // Récupérer l'URL actuelle du serveur
      const currentUrl = typeof window !== "undefined" ? window.location.origin : "https://myreklam.fr"
      
      const formData = new URLSearchParams()
      formData.append("userEmail", email)
      formData.append("Name", "Link")
      formData.append("Link", currentUrl)
      formData.append("Method", "resetPassword")

      const response = await fetch(`${config.API_URL}/LoginUser.php`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: formData.toString(),
      })

      const data = await response.json()
      
      console.log("Reset password response:", data)
      console.log("Reset password emailSent status:", data.emailSent)

      if (data.status === "success") {
        // Vérifier si l'email a vraiment été envoyé
        // L'API retourne soit emailSent=true, soit un message contenant "email envoyé"
        const emailActuallySent = 
          data.emailSent === true || 
          data.emailSent === "true" || 
          data.emailSent === 1 ||
          (data.message && data.message.toLowerCase().includes("email envoyé"))
        
        console.log("[ForgotPassword] emailSent check:", emailActuallySent)
        console.log("[ForgotPassword] Response message:", data.message)
        
        if (emailActuallySent) {
          toast.success("✅ " + (data.message || "Email envoyé avec succès !"), {
            duration: 4000,
          })
          // Petit délai pour que le toast soit visible avant de changer d'état
          setTimeout(() => {
            setEmailSent(true)
          }, 500)
        } else {
          // Email NON envoyé - problème serveur
          console.error("[ForgotPassword] ERREUR: Email non envoyé par le serveur (emailSent: false)")
          const errorMsg = "⚠️ Demande traitée mais l'email n'a pas pu être envoyé. Veuillez contacter le support."
          setErrorMessage(errorMsg)
          toast.error(errorMsg, {
            duration: 8000,
          })
          setTimeout(() => {
            toast.warning("🔧 Problème technique détecté", {
              description: "Le serveur ne peut pas envoyer d'emails. Contactez le support technique.",
              duration: 8000,
            })
          }, 2000)
        }
      } else if (data.status === "error") {
        const errorMsg = data.message || "Aucun utilisateur trouvé avec cette adresse email."
        setErrorMessage(errorMsg)
        toast.error("❌ " + errorMsg, {
          duration: 5000,
        })
      } else {
        const errorMsg = "Une erreur s'est produite. Veuillez réessayer."
        setErrorMessage(errorMsg)
        toast.error("❌ " + errorMsg, {
          duration: 5000,
        })
      }
    } catch (error) {
      console.error("Error sending reset email:", error)
      const errorMsg = "Une erreur s'est produite. Veuillez réessayer."
      setErrorMessage(errorMsg)
      toast.error("❌ " + errorMsg, {
        duration: 5000,
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    setEmail("")
    setEmailSent(false)
    onClose()
  }

  const handleBackToSignIn = () => {
    handleClose()
    if (onBackToSignIn) {
      onBackToSignIn()
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="relative w-full max-w-md rounded-lg bg-background p-6 shadow-lg">
        <button onClick={handleClose} className="absolute right-4 top-4 rounded-sm opacity-70 hover:opacity-100">
          <X className="h-4 w-4" />
          <span className="sr-only">Fermer</span>
        </button>

        {!emailSent ? (
          <>
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-foreground">Mot de passe oublié</h2>
              <p className="text-sm text-muted-foreground mt-1">
                Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {errorMessage && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                  <p className="font-medium">❌ {errorMessage}</p>
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="reset-email">Email</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="reset-email"
                    type="email"
                    placeholder="votre@email.com"
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value)
                      setErrorMessage("") // Effacer l'erreur quand l'utilisateur tape
                    }}
                    className="pl-10"
                    disabled={isLoading}
                    required
                  />
                </div>
              </div>

              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Envoi en cours...
                  </>
                ) : (
                  "Envoyer le lien de réinitialisation"
                )}
              </Button>
            </form>

            <div className="mt-4">
              <Button
                type="button"
                variant="ghost"
                className="w-full"
                onClick={handleBackToSignIn}
                disabled={isLoading}
              >
                <ArrowLeft className="mr-2 h-4 w-4" />
                Retour à la connexion
              </Button>
            </div>
          </>
        ) : (
          <>
            <div className="mb-6 text-center">
              <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
                <Mail className="h-6 w-6 text-green-600" />
              </div>
              <h2 className="text-2xl font-bold text-foreground mb-2">Email envoyé !</h2>
              <p className="text-sm text-muted-foreground">
                Nous avons envoyé un lien de réinitialisation à <strong>{email}</strong>
              </p>
              <p className="text-sm text-muted-foreground mt-2">
                Vérifiez votre boîte de réception et cliquez sur le lien pour réinitialiser votre mot de passe.
              </p>
            </div>

            <div className="space-y-2">
              <Button type="button" className="w-full" onClick={handleBackToSignIn}>
                Retour à la connexion
              </Button>
              <Button
                type="button"
                variant="outline"
                className="w-full bg-transparent"
                onClick={() => setEmailSent(false)}
              >
                Renvoyer l'email
              </Button>
            </div>

            <p className="text-xs text-muted-foreground text-center mt-4">
              Vous n'avez pas reçu l'email ? Vérifiez vos spams ou réessayez.
            </p>
          </>
        )}
      </div>
    </div>
  )
}
