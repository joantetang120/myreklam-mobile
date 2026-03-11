"use client"

import { motion } from "framer-motion"
import { Users, Briefcase, Award, TrendingUp } from "lucide-react"

const stats = [
  {
    icon: Users,
    value: "15K+",
    label: "Utilisateurs actifs",
    description: "Particuliers et professionnels",
  },
  {
    icon: Briefcase,
    value: "8K+",
    label: "Offres publiées",
    description: "Dans tous les secteurs",
  },
  {
    icon: Award,
    value: "1M+",
    label: "My's distribués",
    description: "En récompenses",
  },
  {
    icon: TrendingUp,
    value: "98%",
    label: "Taux de satisfaction",
    description: "De nos utilisateurs",
  },
]

export function StatsSection() {
  return (
    <section className="py-16 bg-muted/30">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
          {stats.map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className="text-center"
            >
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 text-primary mb-4">
                <stat.icon className="w-6 h-6" />
              </div>
              <div className="text-3xl sm:text-4xl font-bold mb-2">{stat.value}</div>
              <div className="font-semibold text-foreground mb-1">{stat.label}</div>
              <div className="text-sm text-muted-foreground">{stat.description}</div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
