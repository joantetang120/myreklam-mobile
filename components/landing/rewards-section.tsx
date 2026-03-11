"use client"

import { motion } from "framer-motion"
import { 
  Coins, 
  TrendingUp, 
  Zap, 
  Users, 
  Gift, 
  Share2, 
  User, 
  Megaphone, 
  MessageCircle, 
  Star, 
  Briefcase, 
  Calendar, 
  Building2, 
  Rocket 
} from "lucide-react"
import Image from "next/image"
import { Card } from "@/components/ui/card"

const rewards = [
  {
    action: "Compléter son profil",
    description: "Un profil complet, c’est toujours plus avantageux.",
    coins: 2,
    icon: User,
  },
  {
    action: "Publication d'une annonce",
    description: "Publiez une annonce et recevez une récompense immédiate !",
    coins: 2,
    icon: Megaphone,
  },
  {
    action: "Commenter une annonce",
    description: "Laissez un commentaire et gagnez des points à chaque interaction !",
    coins: 1,
    icon: MessageCircle,
  },
  {
    action: "Laisser un avis sur un profil entreprise",
    description: "Donnez votre avis sur une entreprise et soyez récompensé pour votre contribution !",
    coins: 1,
    icon: Star,
  },
  {
    action: "Recommander une annonce",
    description: "Partagez une annonce sur vos réseaux et empochez des points en un clic !",
    coins: 1,
    icon: Share2,
  },
  {
    action: "Postuler à une offre",
    description: "Postulez à une offre et recevez des points pour chaque candidature !",
    coins: 1,
    icon: Briefcase,
  },
  {
    action: "Participer à un événement",
    description: "Inscrivez-vous à un événement et gagnez des récompenses en participant !",
    coins: 1,
    icon: Calendar,
  },
  {
    action: "Parrainage particulier",
    description: "Parrainez un particulier et gagnez à chaque nouvelle inscription !",
    coins: 2,
    icon: Users,
  },
  {
    action: "Parrainage d'entreprise gratuit",
    description: "Parrainez une entreprise et gagnez vos premiers my’s dès son inscription !",
    coins: 2,
    icon: Building2,
  },
  {
    action: "Parrainage d'entreprise Premium",
    description: "Une entreprise abonnée à l’offre Premium ? C’est 5 my’s gagnés pour vous !",
    coins: 5,
    icon: Rocket,
  },
]

export function RewardsSection() {
  return (
    <section className="py-24 bg-gradient-to-b from-primary/5 to-background relative overflow-hidden">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left content */}
          <motion.div initial={{ opacity: 0, x: -20 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }}>
            <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-6">
              Chaque action <span className="text-primary">vous récompense</span>
            </h2>
            <p className="text-lg text-muted-foreground mb-8">
              Sur Myreklam, votre engagement est valorisé. Que vous partagiez un bon plan, postuliez à une offre,
              recommandiez un contact ou participiez à un événement, gagnez des my's à chaque interaction.
              Convertissez-les ensuite en récompenses concrètes : cartes cadeaux Amazon, Fnac, Decathlon, réductions
              exclusives et bien plus encore.
            </p>

            <div className="grid sm:grid-cols-2 gap-3">
              {rewards.map((reward, index) => (
                <motion.div
                  key={reward.action}
                  initial={{ opacity: 0, x: -20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: index * 0.05 }}
                >
                  <Card className="p-3 flex items-center gap-3 hover:shadow-md transition-all hover:scale-[1.02] h-full">
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <reward.icon className="w-5 h-5 text-primary" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-sm leading-tight mb-0.5">{reward.action}</p>
                      <p className="text-xs text-muted-foreground line-clamp-2">{reward.description}</p>
                    </div>
                    <div className="flex items-center gap-1 text-primary font-bold flex-shrink-0">
                      <span className="text-lg">+{reward.coins}</span>
                      <Image
                        src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
                        alt="my's"
                        width={20}
                        height={20}
                        className="mix-blend-darken dark:mix-blend-lighten"
                      />
                    </div>
                  </Card>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Right content - Rewards showcase */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="relative"
          >
            <div className="relative aspect-square max-w-md mx-auto">
              {/* Large coin in center */}
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 20, repeat: Number.POSITIVE_INFINITY, ease: "linear" }}
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48"
              >
                <Image
                  src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
                  alt="My's coin"
                  width={192}
                  height={192}
                  className="mix-blend-darken dark:mix-blend-lighten drop-shadow-2xl"
                />
              </motion.div>

              {/* Floating reward cards */}
              <motion.div
                animate={{ y: [0, -15, 0] }}
                transition={{ duration: 3, repeat: Number.POSITIVE_INFINITY, ease: "easeInOut" }}
                className="absolute top-0 right-0 bg-card border border-border rounded-xl p-4 shadow-lg"
              >
                <p className="text-sm font-semibold mb-1">Niveau GOLD</p>
                <p className="text-xs text-muted-foreground">150 my's</p>
              </motion.div>

              <motion.div
                animate={{ y: [0, 15, 0] }}
                transition={{ duration: 4, repeat: Number.POSITIVE_INFINITY, ease: "easeInOut", delay: 1 }}
                className="absolute bottom-0 left-0 bg-card border border-border rounded-xl p-4 shadow-lg"
              >
                <p className="text-sm font-semibold mb-1">Récompense</p>
                <p className="text-xs text-muted-foreground">Carte cadeau 50€</p>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
