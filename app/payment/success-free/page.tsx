"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"

export default function SuccessFreePage() {
  const router = useRouter()

  useEffect(() => {
    // Store subscription type
    localStorage.setItem("subscriptionType", "gratuit")
    
    // Mark subscription as completed (onboarding will trigger on dashboard)
    const profileId = localStorage.getItem("profileId")
    if (profileId) {
      localStorage.setItem(`subscription-completed-${profileId}`, "true")
    }

    // Show success toast
    toast.success("Bienvenue sur Myreklam !", {
      description: "Votre compte gratuit a été créé avec succès.",
      duration: 5000,
    })

    // Redirect to dashboard after a short delay
    const timer = setTimeout(() => {
      router.push("/dashboard")
    }, 1000)

    return () => clearTimeout(timer)
  }, [router])

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-accent/5">
      <div className="text-center">
        <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
        <p className="mt-4 text-muted-foreground">Redirection vers votre profil...</p>
      </div>
    </div>
  )
}
