"use client"

import type React from "react"
import { motion, AnimatePresence } from "framer-motion"
import Link from "next/link"
import { Check } from "lucide-react"
import { Button } from "@/components/ui/button"

interface AnnouncementSuccessModalProps {
  isOpen: boolean
  onClose: () => void
  isEditMode?: boolean
  redirectPath?: string
}

export function AnnouncementSuccessModal({
  isOpen,
  onClose,
  isEditMode = false,
  redirectPath,
}: AnnouncementSuccessModalProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <div 
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50" 
          onClick={onClose}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            onClick={(e) => e.stopPropagation()}
            className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center"
          >
            <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <Check className="w-10 h-10 text-green-600" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              {isEditMode ? "Votre annonce a bien été modifiée" : "Votre annonce a bien été publiée"}
            </h2>
            <div className="space-y-3">
              <Link href="/" className="block" onClick={onClose}>
                <Button variant="outline" className="w-full bg-transparent">
                  Retour à l'accueil
                </Button>
              </Link>
              <Link 
                href={redirectPath || "/dashboard/mes-annonces"} 
                className="block"
                onClick={onClose}
              >
                <Button className="w-full bg-gradient-to-r from-green-500 to-green-600">
                  Voir mes annonces
                </Button>
              </Link>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  )
}

