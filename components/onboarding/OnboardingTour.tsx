"use client"

import { useEffect, useRef, useState } from "react"
import { useAuthStore } from "@/lib/auth-store"
import { TourProvider } from "@reactour/tour"
import { Button } from "@/components/ui/button"
import { toast } from "sonner"
import axios from "axios"
import { config } from "@/lib/config"

const API_URL = config.API_URL

export function OnboardingTour() {
  const { isAuthenticated, userId, urlPhotoProfil, fetchUserInfo } = useAuthStore()
  const [tourStarted, setTourStarted] = useState<boolean | null>(null)
  const [showTour, setShowTour] = useState(false)
  const [hasCheckedFirstLogin, setHasCheckedFirstLogin] = useState(false)
  const [userData, setUserData] = useState<any>(null)
  const [announcementsCount, setAnnouncementsCount] = useState(0)
  const [loading, setLoading] = useState(true)

  // Refs to keep latest values for the global event handler
  const isAuthRef = useRef(isAuthenticated)
  const userIdRef = useRef(userId)
  const tourStartedRef = useRef(tourStarted)

  useEffect(() => {
    isAuthRef.current = isAuthenticated
  }, [isAuthenticated])
  useEffect(() => {
    userIdRef.current = userId
  }, [userId])
  useEffect(() => {
    tourStartedRef.current = tourStarted
  }, [tourStarted])

  // Check user data and completed steps
  useEffect(() => {
    const checkUserProgress = async () => {
      if (!userId || !isAuthenticated) {
        setLoading(false)
        return
      }

      try {
        // Fetch user data
        const response = await axios.post(
          `${API_URL}/UserInfo.php`,
          { userid: userId, Method: "readAdsByCriteria" },
          { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
        )

        if (response.data.status === "success" && response.data.userInfo?.[0]) {
          setUserData(response.data.userInfo[0])
        }

        // Fetch announcements count
        try {
          const annoncesResponse = await axios.post(
            `${API_URL}/Annonces.php`,
            { userid: userId, Method: "readAllByUserId" },
            { headers: { "Content-Type": "application/x-www-form-urlencoded" } }
          )
          if (annoncesResponse.data.status === "success" && Array.isArray(annoncesResponse.data.annonces)) {
            setAnnouncementsCount(annoncesResponse.data.annonces.length)
          }
        } catch (err) {
          console.error("Error fetching announcements:", err)
        }
      } catch (error) {
        console.error("Error checking user progress:", error)
      } finally {
        setLoading(false)
      }
    }

    checkUserProgress()
  }, [userId, isAuthenticated])

  // Read persisted flag
  useEffect(() => {
    if (typeof window === "undefined") return
    try {
      const key = userId ? `onboarding-${userId}` : "onboarding-guest"
      const stored = localStorage.getItem(key)
      if (stored === "true") setTourStarted(true)
      else if (stored === "false") setTourStarted(false)
      else setTourStarted(false)
    } catch {
      setTourStarted(false)
    }
  }, [userId])

  // Check if this is the first login and auto-start tour
  useEffect(() => {
    if (typeof window === "undefined" || !isAuthenticated || !userId || tourStarted === null || hasCheckedFirstLogin || loading) return

    try {
      const firstLoginKey = `first-login-${userId}`
      const hasLoggedInBefore = localStorage.getItem(firstLoginKey) === "true"
      
      if (!hasLoggedInBefore && tourStarted !== true) {
        localStorage.setItem(firstLoginKey, "true")
        const timer = setTimeout(() => {
          setShowTour(true)
        }, 600)
        setHasCheckedFirstLogin(true)
        return () => clearTimeout(timer)
      } else {
        setHasCheckedFirstLogin(true)
      }
    } catch (error) {
      console.error("Error checking first login:", error)
      setHasCheckedFirstLogin(true)
    }
  }, [isAuthenticated, userId, tourStarted, hasCheckedFirstLogin, loading])

  // Register global event listener
  useEffect(() => {
    function handleStartEvent(e: Event) {
      const detail: any = (e as CustomEvent)?.detail || {}
      const force = detail.force === true

      if (force) {
        try {
          const key = userIdRef.current ? `onboarding-${userIdRef.current}` : "onboarding-guest"
          localStorage.setItem(key, "false")
          setTourStarted(false)
        } catch {}
        setShowTour(true)
        return
      }

      if (isAuthRef.current && !tourStartedRef.current) {
        setShowTour(true)
      }
    }

    window.addEventListener("startOnboarding", handleStartEvent as EventListener)
    return () => window.removeEventListener("startOnboarding", handleStartEvent as EventListener)
  }, [])

  if (!showTour) return null

  // Determine which steps to show based on user progress
  const hasPhoto = urlPhotoProfil && urlPhotoProfil.trim() !== ""
  const hasProfileInfo = userData && (
    (userData.pseudo && userData.pseudo.trim() !== "") ||
    (userData.nomsociete && userData.nomsociete.trim() !== "") ||
    (userData.telephone && userData.telephone.trim() !== "")
  )
  const hasAnnouncements = announcementsCount > 0

  const baseSteps = [
    {
      selector: "body",
      content: "Bienvenue sur MyReklam ! Laissez-nous vous montrer les points clés pour bien démarrer.",
      position: "center" as const,
      skip: false,
    },
    {
      selector: "[data-tour='dashboard-nav']",
      content: "Accédez à votre tableau de bord pour gérer vos annonces et votre profil.",
      skip: false,
    },
    {
      selector: "[data-tour='profile-photo']",
      content: hasPhoto
        ? "✓ Vous avez déjà une photo de profil !"
        : "Ajoutez une photo de profil pour personnaliser votre compte et inspirer confiance. Vous pourrez l'ajouter depuis votre tableau de bord.",
      skip: hasPhoto, // Skip if user already has photo
    },
    {
      selector: "[data-tour='complete-profile']",
      content: hasProfileInfo 
        ? "✓ Votre profil est déjà complété ! Plus votre profil est rempli, plus vous êtes visible !"
        : "Complétez votre profil avec vos informations. Plus votre profil est rempli, plus vous êtes visible !",
      skip: false,
    },
    {
      selector: "[data-tour='create-announcement']",
      content: "Commencez à créer vos premières annonces en cliquant ici.",
      skip: false,
    },
    {
      selector: "[data-tour='my-announcements']",
      content: hasAnnouncements
        ? `✓ Vous avez déjà ${announcementsCount} annonce${announcementsCount > 1 ? "s" : ""} publiée${announcementsCount > 1 ? "s" : ""} ! Consultez et gérez-les ici.`
        : "Consultez et gérez toutes vos annonces publiées.",
      skip: false,
    },
    {
      selector: "[data-tour='settings']",
      content: "Accédez à vos paramètres pour configurer vos préférences.",
      skip: false,
    },
  ]

  // Filter out skipped steps
  const filteredSteps = baseSteps
    .filter(step => !step.skip)
    .map(({ skip, ...step }) => step)

  const handleClose = (markDone = true) => {
    if (markDone) {
      try {
        const key = userId ? `onboarding-${userId}` : "onboarding-guest"
        if (typeof window !== "undefined") localStorage.setItem(key, "true")
      } catch {}
      setTourStarted(true)
    }
    setShowTour(false)
  }

  return (
    <TourProvider
      {...({
        steps: filteredSteps,
        showCloseButton: true,
        disableInteraction: false,
        styles: {
          popover: (base: any) => ({
            ...base,
            borderRadius: 12,
            padding: 20,
            background: "#fff",
            color: "#1f2937",
            maxWidth: 400,
            zIndex: 10000,
            boxShadow: "0 4px 30px rgba(0, 0, 0, 0.2)",
          }),
          maskArea: (base: any) => ({ ...base, rx: 8 }),
          maskWrapper: (base: any) => ({ ...base, backgroundColor: "rgba(0, 0, 0, 0.5)" }),
        },
        prevButton: ({ Button, ...props }: any) => (
          <Button {...props} className="mr-2">Précédent</Button>
        ),
        nextButton: ({ Button, currentStep, stepsLength, ...props }: any) => {
          const isLastStep = currentStep === stepsLength - 1
          return <Button {...props}>{isLastStep ? "Terminer" : "Suivant"}</Button>
        },
        closeButton: ({ Button, currentStep, ...props }: any) => {
          // Show "Faire plus tard" button if not on first step
          if (currentStep > 0) {
            return (
              <div className="flex gap-2">
                <Button
                  onClick={() => handleClose(false)}
                  variant="outline"
                  className="mr-2"
                >
                  Faire plus tard
                </Button>
                <Button onClick={() => handleClose(true)} variant="ghost">
                  Terminer
                </Button>
              </div>
            )
          }
          return <Button onClick={() => handleClose(true)} variant="ghost">Terminer</Button>
        },
      } as any)}
    />
  )
}
