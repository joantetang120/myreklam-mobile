"use client"

import type React from "react"
import { useState } from "react"
import { X, Lock, Loader2, Eye, EyeOff, CheckCircle, Check } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { toast } from "sonner"
import { config } from "@/lib/config"
import { isPasswordCompliant } from "@/lib/validation"

interface ResetPasswordModalProps {
  isOpen: boolean
  onClose: () => void
  onSuccess?: () => void
  email: string
  token?: string
}

export function ResetPasswordModal({ isOpen, onClose, onSuccess, email, token }: ResetPasswordModalProps) {
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [showNewPassword, setShowNewPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [passwordReset, setPasswordReset] = useState(false)
  const [errorMessage, setErrorMessage] = useState("")
  const [passwordMatchError, setPasswordMatchError] = useState(false)

  const passwordValidation = {
    minLength: newPassword.length >= 8,
    hasNumber: /\d/.test(newPassword),
    hasLetter: /[a-zA-Z]/.test(newPassword),
    hasSpecialChar: /[!@#$%^&*(),.?":{}|<>]/.test(newPassword),
  }

  const passwordsMatch = newPassword === confirmPassword
  const showPasswordError = confirmPassword.length > 0 && !passwordsMatch

  if (!isOpen) return null

  const validatePassword = () => {
    if (!isPasswordCompliant(newPassword)) {
      setErrorMessage("Le mot de passe doit contenir ≥8 caractères, 1 chiffre, 1 lettre et 1 caractère spécial.")
      return false
    }
    if (newPassword !== confirmPassword) {
      setPasswordMatchError(true)
      setErrorMessage("Les deux mots de passe ne sont pas identiques")
      return false
    }
    return true
  }

  const handleConfirmPasswordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setConfirmPassword(value)
    setErrorMessage("")
    
    if (passwordMatchError && value === newPassword) {
      setPasswordMatchError(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!validatePassword()) {
      toast.error(errorMessage)
      return
    }

    setIsLoading(true)
    setErrorMessage("")

    try {
      const formData = new URLSearchParams()
      formData.append("userEmail", email)
      formData.append("newPassword", newPassword)
      if (token) {
        formData.append("token", token)
      }
      formData.append("Method", "updatePassword")

      console.log("Sending password reset request:", {
        userEmail: email,
        hasToken: !!token,
        Method: "updatePassword"
      })

      const response = await fetch(`${config.API_URL}/LoginUser.php`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: formData.toString(),
      })

      const data = await response.json()
      
      console.log("Reset password response:", data)

      if (data.status === "success") {
        toast.success("✅ " + (data.message || "Mot de passe réinitialisé avec succès !"), {
          duration: 4000,
        })
        setTimeout(() => {
          setPasswordReset(true)
        }, 500)
      } else if (data.status === "error") {
        const errorMsg = data.message || "Une erreur s'est produite lors de la réinitialisation."
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
      console.error("Error resetting password:", error)
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
    setNewPassword("")
    setConfirmPassword("")
    setPasswordReset(false)
    setErrorMessage("")
    onClose()
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="relative w-full max-w-md rounded-lg bg-background p-6 shadow-lg">
        <button onClick={handleClose} className="absolute right-4 top-4 rounded-sm opacity-70 hover:opacity-100">
          <X className="h-4 w-4" />
          <span className="sr-only">Fermer</span>
        </button>

        {!passwordReset ? (
          <>
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-foreground">Réinitialiser le mot de passe</h2>
              <p className="text-sm text-muted-foreground mt-1">
                Créez un nouveau mot de passe pour <strong>{email}</strong>
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {errorMessage && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                  <p className="font-medium">❌ {errorMessage}</p>
                </div>
              )}

              <div className="space-y-2">
                <Label htmlFor="new-password">Nouveau mot de passe</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="new-password"
                    type={showNewPassword ? "text" : "password"}
                    placeholder="••••••••"
                    value={newPassword}
                    onChange={(e) => {
                      setNewPassword(e.target.value)
                      setErrorMessage("")
                    }}
                    className="pl-10 pr-10"
                    disabled={isLoading}
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowNewPassword(!showNewPassword)}
                    className="absolute right-3 top-3 text-muted-foreground hover:text-foreground"
                  >
                    {showNewPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
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
                    onChange={handleConfirmPasswordChange}
                    className={`pl-10 pr-10 ${
                      showPasswordError || passwordMatchError 
                        ? 'border-red-500 focus:border-red-500 focus:ring-red-500' 
                        : passwordsMatch && confirmPassword.length > 0 
                        ? 'border-green-500 focus:border-green-500 focus:ring-green-500'
                        : ''
                    }`}
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

              <Button type="submit" className="w-full" disabled={isLoading}>
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Réinitialisation...
                  </>
                ) : (
                  "Réinitialiser le mot de passe"
                )}
              </Button>
            </form>
          </>
        ) : (
          <>
            <div className="mb-6 text-center">
              <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <h2 className="text-2xl font-bold text-foreground mb-2">Mot de passe réinitialisé !</h2>
              <p className="text-sm text-muted-foreground">
                Votre mot de passe a été réinitialisé avec succès.
              </p>
              <p className="text-sm text-muted-foreground mt-2">
                Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.
              </p>
            </div>

            <Button 
              type="button" 
              className="w-full" 
              onClick={() => {
                if (onSuccess) {
                  onSuccess()
                } else {
                  handleClose()
                }
              }}
            >
              Se connecter
            </Button>
          </>
        )}
      </div>
    </div>
  )
}
