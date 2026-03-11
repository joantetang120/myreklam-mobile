"use client"

import { motion } from "framer-motion"
import {
  Smartphone,
  Gamepad2,
  ShoppingCart,
  Shirt,
  Heart,
  Baby,
  Home,
  Hammer,
  Car,
  Music,
  Dumbbell,
  Wifi,
  Plane,
  Briefcase,
} from "lucide-react"
import { labelObject } from "@/lib/constants/label-object"

const dealsCategories = [
  { id: "HighTech", icon: Smartphone, color: "from-blue-500 to-cyan-500" },
  { id: "ConsolesVideoGames", icon: Gamepad2, color: "from-purple-500 to-pink-500" },
  { id: "GroceriesShopping", icon: ShoppingCart, color: "from-green-500 to-emerald-500" },
  { id: "FashionAccessories", icon: Shirt, color: "from-pink-500 to-rose-500" },
  { id: "HealthBeauty", icon: Heart, color: "from-red-500 to-pink-500" },
  { id: "FamilyKids", icon: Baby, color: "from-yellow-500 to-orange-500" },
  { id: "HomeLiving", icon: Home, color: "from-indigo-500 to-purple-500" },
  { id: "GardenDIY", icon: Hammer, color: "from-amber-500 to-yellow-500" },
  { id: "Automotive", icon: Car, color: "from-gray-600 to-gray-800" },
  { id: "CultureEntertainment", icon: Music, color: "from-violet-500 to-purple-500" },
  { id: "SportsOutdoors", icon: Dumbbell, color: "from-teal-500 to-cyan-500" },
  { id: "MobileInternetPlans", icon: Wifi, color: "from-blue-600 to-indigo-600" },
  { id: "Travel", icon: Plane, color: "from-sky-500 to-blue-500" },
  { id: "Services", icon: Briefcase, color: "from-slate-600 to-gray-700" },
  { id: "FinanceInsurance", icon: Briefcase, color: "from-emerald-600 to-teal-600" },
]

const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: {
      staggerChildren: 0.05,
    },
  },
}

const item = {
  hidden: { opacity: 0, scale: 0.8 },
  show: { opacity: 1, scale: 1 },
}

interface DealsCategoriesProps {
  onSelectCategory: (category: string) => void
}

export function DealsCategories({ onSelectCategory }: DealsCategoriesProps) {
  return (
    <motion.div
      variants={container}
      initial="hidden"
      animate="show"
      className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 max-w-6xl mx-auto"
    >
      {dealsCategories.map((category) => {
        const Icon = category.icon
        const label = (labelObject as any)[category.id] || category.id

        return (
          <motion.button
            key={category.id}
            variants={item}
            whileHover={{ scale: 1.05, y: -5 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => onSelectCategory(category.id)}
            className="relative group"
          >
            <div className="bg-white rounded-2xl p-6 shadow-md hover:shadow-2xl transition-all duration-300 border-2 border-transparent hover:border-teal-500/30 h-full flex flex-col items-center justify-center gap-4">
              {/* Icon with gradient background */}
              <div
                className={`w-16 h-16 rounded-xl bg-gradient-to-br ${category.color} flex items-center justify-center shadow-lg group-hover:shadow-xl transition-shadow duration-300`}
              >
                <Icon className="w-8 h-8 text-white" />
              </div>

              {/* Label */}
              <div className="text-center">
                <h3 className="font-semibold text-gray-900 group-hover:text-teal-600 transition-colors duration-300 text-sm">
                  {label}
                </h3>
              </div>

              {/* Hover indicator */}
              <div className="absolute top-2 right-2 w-2 h-2 rounded-full bg-teal-500 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            </div>
          </motion.button>
        )
      })}
    </motion.div>
  )
}
