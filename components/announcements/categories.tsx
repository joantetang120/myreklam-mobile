"use client"

import Link from "next/link"
import { motion } from "framer-motion"
import { useUserData } from "@/hooks/use-user-data"
import { ShoppingBag, Briefcase, GraduationCap, Calendar, MessageSquare } from "lucide-react"
import Image from "next/image"

const actions = [
  {
    title: "Bons plans",
    href: "/announcements/create/deals",
    icon: ShoppingBag,
    iconForeground: "text-white",
    iconBackground: "bg-gradient-to-br from-teal-500 to-teal-600",
    backgroundColorGradient: "from-teal-500/20 to-teal-600/40",
    imageSrc: "/shopping-deals-discount.jpg",
    isVisible: ["particulier", "professionnel"],
    description: "Partagez vos meilleures trouvailles",
    accentColor: "teal",
  },
  {
    title: "Offres d'emploi",
    href: "/announcements/create/jobs",
    icon: Briefcase,
    iconForeground: "text-white",
    iconBackground: "bg-gradient-to-br from-amber-500 to-orange-600",
    backgroundColorGradient: "from-amber-500/20 to-orange-600/40",
    imageSrc: "/job-recruitment-office.jpg",
    isVisible: ["professionnel"],
    description: "Recrutez les meilleurs talents",
    accentColor: "amber",
  },
  {
    title: "Formations",
    href: "/announcements/create/trainings",
    icon: GraduationCap,
    iconForeground: "text-white",
    iconBackground: "bg-gradient-to-br from-purple-500 to-purple-600",
    backgroundColorGradient: "from-purple-500/20 to-purple-600/40",
    imageSrc: "/training-education-learning.jpg",
    isVisible: ["professionnel"],
    description: "Proposez vos formations",
    accentColor: "purple",
  },
  {
    title: "Événements",
    href: "/announcements/create/events",
    icon: Calendar,
    iconForeground: "text-white",
    iconBackground: "bg-gradient-to-br from-green-500 to-emerald-600",
    backgroundColorGradient: "from-green-500/20 to-emerald-600/40",
    imageSrc: "/event-conference-meeting.jpg",
    isVisible: ["professionnel", "particulier"],
    description: "Organisez des événements",
    accentColor: "green",
  },
  {
    title: "Demandes",
    href: "/announcements/create/inquiries",
    icon: MessageSquare,
    iconForeground: "text-white",
    iconBackground: "bg-gradient-to-br from-indigo-500 to-indigo-600",
    backgroundColorGradient: "from-indigo-500/20 to-indigo-600/40",
    imageSrc: "/request-inquiry-question.jpg",
    isVisible: ["professionnel", "particulier"],
    description: "Trouvez ce que vous cherchez",
    accentColor: "indigo",
  },
]

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.12,
      delayChildren: 0.3,
    },
  },
}

const item = {
  hidden: { opacity: 0, y: 30, scale: 0.95 },
  show: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      type: "spring" as const,
      stiffness: 100,
      damping: 15,
    },
  },
}

export default function Categories() {
  const { companyData } = useUserData()

  const filteredActions = actions.filter((action) => action.isVisible.includes(companyData?.profiletype || ""))

  return (
    <motion.div
      variants={container}
      initial="hidden"
      animate="show"
      className="flex flex-col md:flex-row flex-wrap justify-center items-stretch gap-8 pb-12"
    >
      {filteredActions.map((action) => (
        <motion.div key={action.title} variants={item}>
          <Link
            href={action.href}
            className="relative overflow-hidden rounded-3xl group h-96 w-80 bg-white shadow-xl hover:shadow-2xl transition-all duration-500 transform hover:-translate-y-3 hover:scale-105 block"
          >
            <div className="absolute inset-0 opacity-20 group-hover:opacity-30 transition-opacity duration-500">
              <Image src={action.imageSrc || "/placeholder.svg"} alt={action.title} fill className="object-cover" />
            </div>

            {/* Gradient overlay */}
            <div
              className={`absolute inset-0 bg-gradient-to-b ${action.backgroundColorGradient} opacity-60 group-hover:opacity-80 transition-opacity duration-500`}
            ></div>

            {/* Animated border */}
            <div
              className={`absolute inset-0 rounded-3xl border-2 border-transparent group-hover:border-${action.accentColor}-400 transition-colors duration-500`}
            ></div>

            {/* Shine effect on hover */}
            <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500">
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000"></div>
            </div>

            <div className="relative h-full flex flex-col p-8">
              <div className="flex items-center justify-center flex-1">
                <motion.div
                  whileHover={{ scale: 1.15, rotate: 5 }}
                  transition={{ type: "spring", stiffness: 400, damping: 10 }}
                  className="relative"
                >
                  <div
                    className={`absolute inset-0 ${action.iconBackground} rounded-2xl blur-xl opacity-50 group-hover:opacity-100 transition-opacity duration-500`}
                  ></div>
                  <span
                    className={`relative inline-flex rounded-2xl p-8 ${action.iconBackground} ${action.iconForeground} shadow-2xl group-hover:shadow-3xl transition-all duration-500`}
                  >
                    <action.icon aria-hidden="true" className="size-24" strokeWidth={1.5} />
                  </span>
                </motion.div>
              </div>

              <div className="relative bg-white/95 backdrop-blur-md -mx-8 -mb-8 py-6 px-8 text-center border-t border-gray-100 rounded-b-3xl">
                <motion.h3
                  className={`text-2xl font-bold text-gray-900 mb-2 group-hover:text-${action.accentColor}-600 transition-colors duration-300`}
                >
                  {action.title}
                </motion.h3>
                <p className="text-sm text-gray-600 font-medium">{action.description}</p>

                {/* Animated indicator */}
                <motion.div
                  initial={{ width: 0 }}
                  whileHover={{ width: "100%" }}
                  className={`h-1 bg-gradient-to-r from-${action.accentColor}-400 to-${action.accentColor}-600 rounded-full mt-3 mx-auto`}
                ></motion.div>
              </div>

              {/* Corner accent */}
              <div
                className={`absolute top-6 right-6 w-3 h-3 rounded-full bg-${action.accentColor}-500 opacity-0 group-hover:opacity-100 transition-all duration-500 group-hover:scale-150`}
              ></div>
            </div>
          </Link>
        </motion.div>
      ))}
    </motion.div>
  )
}
