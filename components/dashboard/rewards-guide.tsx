"use client"

import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { 
  CheckCircle2, 
  Circle, 
  User, 
  Megaphone, 
  MessageCircle, 
  Star,
  Share2,
  Briefcase,
  Calendar,
  Users,
  Gift,
  Rocket,
  Award
} from "lucide-react"

interface RewardAction {
  id: string
  title: string
  description: string
  icon: any
  reward: number
  emoji: string
}

export function RewardsGuide() {
  const rewardActions: RewardAction[] = [
    {
      id: "complete_profile",
      title: "Compléter son profil",
      description: "Un profil complet, c'est toujours plus avantageux.",
      icon: User,
      reward: 2,
      emoji: "✅"
    },
    {
      id: "publish_announcement",
      title: "Publication d'une annonce",
      description: "Publiez une annonce et recevez une récompense immédiate !",
      icon: Megaphone,
      reward: 2,
      emoji: "📢"
    },
    {
      id: "comment_announcement",
      title: "Commenter une annonce",
      description: "Laissez un commentaire et gagnez des points à chaque interaction !",
      icon: MessageCircle,
      reward: 1,
      emoji: "💬"
    },
    {
      id: "leave_review",
      title: "Laisser un avis sur un profil entreprise",
      description: "Donnez votre avis sur une entreprise et soyez récompensé pour votre contribution !",
      icon: Star,
      reward: 1,
      emoji: "⭐"
    },
    {
      id: "share_announcement",
      title: "Recommander une annonce",
      description: "Partagez une annonce sur vos réseaux et empochez des points en un clic !",
      icon: Share2,
      reward: 1,
      emoji: "📲"
    },
    {
      id: "apply_job",
      title: "Postuler à une offre d'emploi ou de formation",
      description: "Postulez à une offre et recevez des points pour chaque candidature !",
      icon: Briefcase,
      reward: 1,
      emoji: "📩"
    },
    {
      id: "participate_event",
      title: "Participer à un événement",
      description: "Inscrivez-vous à un événement et gagnez des récompenses en participant !",
      icon: Calendar,
      reward: 1,
      emoji: "📆"
    },
    {
      id: "referral_individual",
      title: "Parrainage particulier",
      description: "Parrainez un particulier et gagnez à chaque nouvelle inscription !",
      icon: Users,
      reward: 2,
      emoji: "👥"
    },
    {
      id: "referral_business_free",
      title: "Parrainage d'entreprise version gratuite",
      description: "Parrainez une entreprise et gagnez vos premiers my's dès son inscription !",
      icon: Gift,
      reward: 2,
      emoji: "🎁"
    },
    {
      id: "referral_business_premium",
      title: "Parrainage d'entreprise Premium",
      description: "Une entreprise abonnée à l'offre Premium ? C'est 5 my's gagnés pour vous !",
      icon: Rocket,
      reward: 5,
      emoji: "🚀"
    }
  ]

  const totalPossibleRewards = rewardActions.reduce((sum, action) => sum + action.reward, 0)

  return (
    <Card className="p-6 bg-gradient-to-br from-primary/5 via-background to-primary/10 border-2 border-primary/20">
      <div className="flex items-center gap-3 mb-6">
        <div className="p-2 bg-primary/10 rounded-lg">
          <Award className="h-6 w-6 text-primary" />
        </div>
        <div>
          <h3 className="text-xl font-bold">Comment gagner des My's ?</h3>
          <p className="text-sm text-muted-foreground">
            Gagnez des récompenses en interagissant avec la plateforme
          </p>
        </div>
      </div>

      <div className="mb-4 p-4 bg-primary/10 rounded-lg border border-primary/20">
        <p className="text-sm text-center">
          <span className="font-semibold text-primary">Jusqu'à {totalPossibleRewards} My's</span> à gagner avec toutes les actions disponibles !
        </p>
      </div>

      <div className="space-y-3">
        {rewardActions.map((action) => {
          const Icon = action.icon
          return (
            <div
              key={action.id}
              className="flex items-start gap-3 p-4 rounded-lg bg-background border border-border hover:border-primary/50 transition-all hover:shadow-md"
            >
              <div className="text-2xl mt-0.5">{action.emoji}</div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <Icon className="h-4 w-4 text-muted-foreground" />
                  <h4 className="font-medium text-sm">{action.title}</h4>
                </div>
                <p className="text-xs text-muted-foreground">{action.description}</p>
              </div>
              <Badge variant="secondary" className="bg-primary/10 text-primary font-bold shrink-0">
                +{action.reward} My's
              </Badge>
            </div>
          )
        })}
      </div>

      <div className="mt-6 p-4 bg-gradient-to-r from-primary/10 to-primary/5 rounded-lg border border-primary/20">
        <p className="text-sm text-center font-medium">
          💡 <span className="text-primary">Astuce :</span> Plus vous êtes actif sur la plateforme, plus vous gagnez de My's !
        </p>
      </div>
    </Card>
  )
}
