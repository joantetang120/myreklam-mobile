"use client"

import { motion } from "framer-motion"
import { Search, Share2, Users, MessageCircle, ThumbsUp } from "lucide-react"

const steps = [
  {
    icon: Search,
    title: "Trouver",
    description: "Les réponses à mes demandes et mes besoins. Les bons contacts, Le bon public.",
  },
  {
    icon: Share2,
    title: "Diffuser",
    description: "Mes offres et services.",
  },
  {
    icon: Users,
    title: "Partager",
    description: "Nos bons plans et bons contacts.",
  },
  {
    icon: MessageCircle,
    title: "Communiquer",
    description: "En direct via la plateforme.",
  },
  {
    icon: ThumbsUp,
    title: "Recommander",
    description: "Et faire confiance à la communauté.",
  },
]

export function HowItWorksSection() {
  return (
    <section id="comment-ca-marche" className="py-24 bg-background">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-4">Comment ça marche</h2>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-5 gap-6">
          {steps.map((step, index) => (
            <motion.div
              key={step.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="relative"
            >
              <div className="bg-card border border-border rounded-2xl p-6 hover:shadow-lg transition-shadow h-full flex flex-col items-center text-center">
                <div className="w-16 h-16 rounded-full bg-teal-100 dark:bg-teal-900/30 flex items-center justify-center mb-4">
                  <step.icon className="w-8 h-8 text-teal-600 dark:text-teal-400" />
                </div>

                <h3 className="text-xl font-semibold mb-3">{step.title}</h3>
                <p className="text-muted-foreground text-sm">{step.description}</p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
