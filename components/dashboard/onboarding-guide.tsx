"use client"

import { useState, useEffect } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import { 
  CheckCircle2, 
  Circle, 
  User, 
  Phone, 
  Building2, 
  Image as ImageIcon,
  FileText,
  Share2,
  Award,
  X
} from "lucide-react"

interface OnboardingStep {
  id: string
  title: string
  description: string
  icon: any
  completed: boolean
  reward: number
  scrollTo?: string
  actionLabel?: string
  onClick?: () => void
}

interface OnboardingGuideProps {
  userData: any
  onClose: () => void
  onReward: (amount: number, stepTitle: string) => void
  onOpenPhotoModal?: () => void
  onComplete?: () => void
  onChangeTab?: (tab: string) => void
}

export function OnboardingGuide({ userData, onClose, onReward, onOpenPhotoModal, onComplete, onChangeTab }: OnboardingGuideProps) {
  const [steps, setSteps] = useState<OnboardingStep[]>([])
  const [completedSteps, setCompletedSteps] = useState<string[]>([])

  const handleScrollTo = (sectionId: string) => {
    const element = document.getElementById(sectionId)
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'center' })
      
      // Ajouter un effet visuel temporaire avec ring
      element.classList.add('ring-2', 'ring-primary', 'ring-offset-2')
      
      // Créer et ajouter un pointeur animé avec un conteneur fixe
      const pointerContainer = document.createElement('div')
      pointerContainer.style.cssText = `
        position: fixed;
        top: 50%;
        left: 20px;
        transform: translateY(-50%);
        font-size: 48px;
        z-index: 9999;
        pointer-events: none;
        animation: pointAndBounce 1s ease-in-out infinite;
      `
      pointerContainer.innerHTML = '👉'
      
      // Ajouter l'animation si elle n'existe pas
      if (!document.getElementById('pointer-animation')) {
        const style = document.createElement('style')
        style.id = 'pointer-animation'
        style.textContent = `
          @keyframes pointAndBounce {
            0%, 100% { 
              transform: translateY(-50%) translateX(0);
              opacity: 1;
            }
            50% { 
              transform: translateY(-50%) translateX(10px);
              opacity: 0.8;
            }
          }
        `
        document.head.appendChild(style)
      }
      
      document.body.appendChild(pointerContainer)
      
      setTimeout(() => {
        element.classList.remove('ring-2', 'ring-primary', 'ring-offset-2')
        pointerContainer.remove()
      }, 3000)
    }
  }

  useEffect(() => {
    const profileSteps: OnboardingStep[] = []
    
    // Étapes différentes selon le type de profil
    if (userData?.profiletype === "professionnel") {
      // Pour les professionnels : pas de pseudo, réseaux sociaux = 5 My's
      profileSteps.push(
        {
          id: "social",
          title: "Ajouter un réseau social",
          description: "Connectez au moins un de vos profils sociaux",
          icon: Share2,
          completed: !!(userData?.facebook || userData?.instagram || userData?.linkedin || userData?.x || userData?.youtube || userData?.tiktok || userData?.snapchat),
          reward: 5,
          onClick: () => {
            if (onChangeTab) {
              onChangeTab('medias')
            }
          },
          actionLabel: "Ajouter"
        },
        {
          id: "phone",
          title: "Ajouter un numéro de téléphone",
          description: "Facilitez le contact avec vos clients",
          icon: Phone,
          completed: !!userData?.telephone && userData.telephone.length > 4 && userData.telephone.replace(/[\s\-\+]/g, '').length >= 10,
          reward: 0.5,
          scrollTo: "personal-info-section",
          actionLabel: "Compléter"
        },
        {
          id: "photo",
          title: "Ajouter une photo de profil",
          description: "Personnalisez votre profil avec une photo",
          icon: ImageIcon,
          completed: !!userData?.photoprofilurl,
          reward: 0.5,
          onClick: onOpenPhotoModal,
          actionLabel: "Ajouter"
        }
      )
    } else {
      // Pour les particuliers : toutes les étapes avec 0.5 My's
      profileSteps.push(
        {
          id: "pseudo",
          title: "Ajouter un pseudo",
          description: "Choisissez un nom d'utilisateur unique",
          icon: User,
          completed: !!userData?.pseudo,
          reward: 0.5,
          scrollTo: "personal-info-section",
          actionLabel: "Compléter"
        },
        {
          id: "social",
          title: "Ajouter un réseau social",
          description: "Connectez au moins un de vos profils sociaux",
          icon: Share2,
          completed: !!(userData?.facebook || userData?.instagram || userData?.linkedin || userData?.x || userData?.youtube || userData?.tiktok || userData?.snapchat),
          reward: 0.5,
          onClick: () => {
            if (onChangeTab) {
              onChangeTab('medias')
            }
          },
          actionLabel: "Ajouter"
        },
        {
          id: "phone",
          title: "Ajouter un numéro de téléphone",
          description: "Facilitez le contact avec vos clients",
          icon: Phone,
          completed: !!userData?.telephone && userData.telephone.length > 4 && userData.telephone.replace(/[\s\-\+]/g, '').length >= 10,
          reward: 0.5,
          scrollTo: "personal-info-section",
          actionLabel: "Compléter"
        },
        {
          id: "photo",
          title: "Ajouter une photo de profil",
          description: "Personnalisez votre profil avec une photo",
          icon: ImageIcon,
          completed: !!userData?.photoprofilurl,
          reward: 0.5,
          onClick: onOpenPhotoModal,
          actionLabel: "Ajouter"
        }
      )
    }

    setSteps(profileSteps)

    // Vérifier les étapes nouvellement complétées
    const previouslyCompleted = JSON.parse(localStorage.getItem("completedOnboardingSteps") || "[]")
    const newlyCompleted = profileSteps
      .filter(step => step.completed && !previouslyCompleted.includes(step.id))
      .map(step => step.id)

    if (newlyCompleted.length > 0) {
      // Déclencher les récompenses pour les nouvelles étapes
      newlyCompleted.forEach(stepId => {
        const step = profileSteps.find(s => s.id === stepId)
        if (step) {
          setTimeout(() => {
            onReward(step.reward, step.title)
          }, 500)
        }
      })

      // Mettre à jour le localStorage
      const allCompleted = [...previouslyCompleted, ...newlyCompleted]
      localStorage.setItem("completedOnboardingSteps", JSON.stringify(allCompleted))
      setCompletedSteps(allCompleted)
      
      // Vérifier si toutes les étapes sont complétées
      const allStepsCompleted = profileSteps.every(step => step.completed)
      const wasAlreadyCompleted = localStorage.getItem("profileCompletionCelebrated") === "true"
      
      console.log("[v0] OnboardingGuide - Checking completion:")
      console.log("[v0] - Total steps:", profileSteps.length)
      console.log("[v0] - Completed steps:", profileSteps.filter(s => s.completed).length)
      console.log("[v0] - Steps details:", profileSteps.map(s => ({ id: s.id, title: s.title, completed: s.completed })))
      console.log("[v0] - All steps completed:", allStepsCompleted)
      console.log("[v0] - Was already completed:", wasAlreadyCompleted)
      console.log("[v0] - onComplete callback exists:", !!onComplete)
      console.log("[v0] - userData.photoprofilurl:", userData?.photoprofilurl)
      console.log("[v0] - userData.pseudo:", userData?.pseudo)
      console.log("[v0] - userData.telephone:", userData?.telephone)
      
      if (allStepsCompleted && !wasAlreadyCompleted && onComplete) {
        console.log("[v0] OnboardingGuide - 🎉 TRIGGERING COMPLETION MODAL!")
        localStorage.setItem("profileCompletionCelebrated", "true")
        setTimeout(() => {
          onComplete()
        }, 1500)
      } else {
        console.log("[v0] OnboardingGuide - Completion modal NOT triggered because:")
        if (!allStepsCompleted) console.log("[v0]   - Not all steps completed")
        if (wasAlreadyCompleted) console.log("[v0]   - Already celebrated")
        if (!onComplete) console.log("[v0]   - No onComplete callback")
      }
    } else {
      setCompletedSteps(previouslyCompleted)
    }
  }, [userData, userData?.photoprofilurl, userData?.pseudo, userData?.telephone, onReward])

  const totalSteps = steps.length
  const completedCount = steps.filter(s => s.completed).length
  const progress = (completedCount / totalSteps) * 100
  const totalRewards = steps.reduce((sum, step) => sum + (step.completed ? step.reward : 0), 0)
  const maxRewards = steps.reduce((sum, step) => sum + step.reward, 0)

  if (completedCount === totalSteps) {
    return null // Ne pas afficher si tout est complété
  }

  return (
    <Card className="p-6 bg-gradient-to-br from-primary/5 via-background to-primary/10 border-2 border-primary/20">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-primary/10 rounded-lg">
            <Award className="h-6 w-6 text-primary" />
          </div>
          <div>
            <h3 className="text-xl font-bold">Complétez votre profil</h3>
            <p className="text-sm text-muted-foreground">
              Gagnez des My's en complétant votre profil
            </p>
          </div>
        </div>
        <Button variant="ghost" size="icon" onClick={onClose}>
          <X className="h-4 w-4" />
        </Button>
      </div>

      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium">
            {completedCount} / {totalSteps} étapes complétées
          </span>
          <Badge variant="secondary" className="bg-primary/10 text-primary">
            {totalRewards.toFixed(1)} / {maxRewards.toFixed(1)} My's
          </Badge>
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      <div className="space-y-3">
        {steps.map((step) => {
          const Icon = step.icon
          return (
            <div
              key={step.id}
              className={`flex items-start gap-3 p-3 rounded-lg transition-all ${
                step.completed
                  ? "bg-green-50 border border-green-200"
                  : "bg-background border border-border hover:border-primary/50"
              }`}
            >
              <div className="mt-0.5">
                {step.completed ? (
                  <CheckCircle2 className="h-5 w-5 text-green-600" />
                ) : (
                  <Circle className="h-5 w-5 text-muted-foreground" />
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <Icon className="h-4 w-4 text-muted-foreground" />
                  <h4 className={`font-medium text-sm ${step.completed ? "text-green-700" : ""}`}>
                    {step.title}
                  </h4>
                </div>
                <p className="text-xs text-muted-foreground">{step.description}</p>
              </div>
              <div className="flex items-center gap-2">
                {step.reward > 0 && (
                  <Badge 
                    variant={step.completed ? "default" : "secondary"}
                    className={step.completed ? "bg-green-600" : ""}
                  >
                    +{step.reward} My's
                  </Badge>
                )}
                {!step.completed && step.actionLabel && (step.scrollTo || step.onClick) && (
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => {
                      if (step.onClick) {
                        step.onClick()
                      } else if (step.scrollTo) {
                        handleScrollTo(step.scrollTo)
                      }
                    }}
                    className="text-xs h-7 px-3 hover:bg-primary hover:text-white"
                  >
                    {step.actionLabel}
                  </Button>
                )}
              </div>
            </div>
          )
        })}
      </div>

      {completedCount > 0 && completedCount < totalSteps && (
        <div className="mt-4 p-3 bg-primary/5 rounded-lg border border-primary/20">
          <p className="text-sm text-center">
            <span className="font-semibold text-primary">Continuez !</span> Il vous reste{" "}
            {totalSteps - completedCount} étape{totalSteps - completedCount > 1 ? "s" : ""} pour gagner{" "}
            <span className="font-bold">{(maxRewards - totalRewards).toFixed(1)} My's</span> supplémentaires
          </p>
        </div>
      )}
    </Card>
  )
}
