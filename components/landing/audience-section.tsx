"use client"

import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Building2, User, ArrowRight } from "lucide-react"
import Link from "next/link"
import { useRouter } from "next/navigation"

const audiences = [
  {
    icon: Building2,
    title: "Pour les professionnels",
    description: "Recrutez efficacement et récompensez les recommandations",
    features: [
      "Publiez vos offres d'emploi gratuitement",
      "Accédez à un vivier de candidats qualifiés",
      "Gagnez des my's pour chaque publication",
      "Système de recommandation intégré",
    ],
    cta: "Rejoignez maintenant",
    gradient: "from-primary/10 to-primary/5",
  },
  {
    icon: User,
    title: "Pour les particuliers",
    description: "Trouvez votre prochain emploi et gagnez des récompenses",
    features: [
      "Postulez aux offres qui vous correspondent",
      "Gagnez des my's à chaque candidature",
      "Recommandez vos contacts et soyez récompensé",
      "Convertissez vos my's en cadeaux",
    ],
    cta: "Rejoignez maintenant",
    gradient: "from-accent/10 to-accent/5",
  },
]

export function AudienceSection() {
  const router = useRouter()

  const handleClick = () => {
    // Vérifier si l'utilisateur est connecté
    const token = localStorage.getItem("token")
    
    if (!token) {
      // Rediriger vers login-required si non connecté
      router.push("/login-required")
    } else {
      // Rediriger vers le dashboard si connecté
      router.push("/dashboard")
    }
  }

  return (
    <section className="py-24 bg-background">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-4">Myreklam pour tous</h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Que vous soyez recruteur ou candidat, Myreklam vous récompense
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {audiences.map((audience, index) => (
            <motion.div
              key={audience.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
            >
              <Card
                className={`p-8 h-full bg-gradient-to-br ${audience.gradient} border-2 hover:shadow-xl transition-all`}
              >
                <div className="w-16 h-16 rounded-2xl bg-background flex items-center justify-center mb-6">
                  <audience.icon className="w-8 h-8 text-primary" />
                </div>

                <h3 className="text-2xl font-bold mb-3">{audience.title}</h3>
                <p className="text-muted-foreground mb-6">{audience.description}</p>

                <ul className="space-y-3 mb-8">
                  {audience.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-3">
                      <div className="w-5 h-5 rounded-full bg-primary/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <div className="w-2 h-2 rounded-full bg-primary" />
                      </div>
                      <span className="text-sm">{feature}</span>
                    </li>
                  ))}
                </ul>

                <Button 
                  className="w-full group" 
                  size="lg"
                  onClick={handleClick}
                >
                  {audience.cta}
                  <ArrowRight className="ml-2 w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </Button>
              </Card>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
