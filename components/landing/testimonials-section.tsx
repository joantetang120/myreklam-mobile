"use client"

import { motion } from "framer-motion"
import { Card } from "@/components/ui/card"
import { Star } from "lucide-react"

const testimonials = [
  {
    name: "Sophie Martin",
    role: "Développeuse Web",
    content:
      "J'ai trouvé mon emploi actuel sur Myreklam et j'ai gagné 150 my's que j'ai convertis en carte cadeau Amazon. Une plateforme géniale !",
    rating: 5,
  },
  {
    name: "Thomas Dubois",
    role: "DRH chez TechCorp",
    content:
      "Nous avons recruté 5 personnes via Myreklam. Le système de récompenses motive vraiment les candidats et les recommandations.",
    rating: 5,
  },
  {
    name: "Marie Lefebvre",
    role: "Chef de projet",
    content:
      "Le concept est innovant. J'ai recommandé 3 personnes et gagné 150 my's. C'est win-win pour tout le monde !",
    rating: 5,
  },
]

export function TestimonialsSection() {
  return (
    <section className="py-24 bg-muted/30">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold mb-4">Ils nous font confiance</h2>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Découvrez ce que nos utilisateurs pensent de Myreklam
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
          {testimonials.map((testimonial, index) => (
            <motion.div
              key={testimonial.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="p-6 h-full hover:shadow-lg transition-shadow">
                <div className="flex gap-1 mb-4">
                  {Array.from({ length: testimonial.rating }).map((_, i) => (
                    <Star key={i} className="w-5 h-5 fill-yellow-400 text-yellow-400" />
                  ))}
                </div>

                <p className="text-muted-foreground mb-6 italic">"{testimonial.content}"</p>

                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-primary/10" />
                  <div>
                    <p className="font-semibold">{testimonial.name}</p>
                    <p className="text-sm text-muted-foreground">{testimonial.role}</p>
                  </div>
                </div>
              </Card>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
