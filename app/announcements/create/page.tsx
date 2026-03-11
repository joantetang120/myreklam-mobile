"use client"

import { Suspense } from "react"
import { motion } from "framer-motion"
import Categories from "@/components/announcements/categories"

import { useRef, useState, useEffect } from "react"

export default function CreationAnnonce() {
  const [profileType, setProfileType] = useState<string>("")

  useEffect(() => {
    // Récupérer le type de profil depuis localStorage
    const userProfileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : ""
    setProfileType(userProfileType || "")
  }, [])

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-cyan-50 relative overflow-hidden p-6 md:p-10 mt-20">
      {/* Animated background pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-0 left-0 w-96 h-96 bg-teal-500 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-cyan-500 rounded-full blur-3xl animate-pulse delay-1000"></div>
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="max-w-7xl mx-auto relative z-10"
      >
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.6, delay: 0.2, ease: "easeOut" }}
          className="text-center mb-12 md:mb-16"
        >
          <motion.h1 className="text-3xl md:text-5xl font-bold mb-4 bg-gradient-to-r from-teal-600 via-cyan-600 to-teal-600 bg-clip-text text-transparent bg-[length:200%_auto] animate-gradient">
            Quelle catégorie d'annonce souhaitez-vous déposer ?
          </motion.h1>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="text-gray-600 text-lg"
          >
            Choisissez la catégorie qui correspond le mieux à votre annonce
          </motion.p>

           {/* Message d'information pour les particuliers */}
          {profileType === "particulier" && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.6 }}
              className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg mx-auto max-w-2xl"
            >
              <p className="text-blue-700 text-sm">
                <strong>Note :</strong> En tant que particulier, vous pouvez publier des bons plans, événements et demandes. 
                Les offres d'emploi et formations sont réservées aux professionnels.
              </p>
            </motion.div>
          )}
        </motion.div>

        <Suspense
          fallback={
            <div className="flex flex-col items-center justify-center py-20">
              <div className="relative">
                <div className="animate-spin rounded-full h-16 w-16 border-4 border-teal-200"></div>
                <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-teal-600 absolute top-0 left-0"></div>
              </div>
              <span className="mt-4 text-gray-600 font-medium">Chargement des catégories...</span>
            </div>
          }
        >
          <Categories />
        </Suspense>
      </motion.div>
    </div>
  )
}
