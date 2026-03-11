"use client"

import { useEffect, useState } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { Award, Sparkles, X } from "lucide-react"
import { Button } from "@/components/ui/button"
import confetti from "canvas-confetti"

interface RewardPopupProps {
  isOpen: boolean
  amount: number
  title: string
  onClose: () => void
}

export function RewardPopup({ isOpen, amount, title, onClose }: RewardPopupProps) {
  const [show, setShow] = useState(false)

  useEffect(() => {
    if (isOpen) {
      setShow(true)
      // Lancer les confettis
      const duration = 3000
      const animationEnd = Date.now() + duration
      const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 9999 }

      function randomInRange(min: number, max: number) {
        return Math.random() * (max - min) + min
      }

      const interval: any = setInterval(function() {
        const timeLeft = animationEnd - Date.now()

        if (timeLeft <= 0) {
          return clearInterval(interval)
        }

        const particleCount = 50 * (timeLeft / duration)
        confetti({
          ...defaults,
          particleCount,
          origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 }
        })
        confetti({
          ...defaults,
          particleCount,
          origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 }
        })
      }, 250)

      // Auto-fermer après 5 secondes
      const timeout = setTimeout(() => {
        handleClose()
      }, 5000)

      return () => {
        clearInterval(interval)
        clearTimeout(timeout)
      }
    }
  }, [isOpen])

  const handleClose = () => {
    setShow(false)
    setTimeout(onClose, 300)
  }

  return (
    <AnimatePresence>
      {show && (
        <>
          {/* Overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-[9998]"
            onClick={handleClose}
          />

          {/* Popup */}
          <motion.div
            initial={{ scale: 0.5, opacity: 0, y: 50 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.5, opacity: 0, y: 50 }}
            transition={{ type: "spring", duration: 0.5 }}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[9999] w-full max-w-md mx-4"
          >
            <div className="bg-gradient-to-br from-primary via-primary/90 to-primary/80 rounded-2xl shadow-2xl p-8 relative overflow-hidden">
              {/* Animated background elements */}
              <div className="absolute inset-0 overflow-hidden">
                <motion.div
                  animate={{
                    scale: [1, 1.2, 1],
                    rotate: [0, 180, 360],
                  }}
                  transition={{
                    duration: 3,
                    repeat: Infinity,
                    ease: "linear"
                  }}
                  className="absolute -top-20 -right-20 w-40 h-40 bg-white/10 rounded-full blur-3xl"
                />
                <motion.div
                  animate={{
                    scale: [1, 1.3, 1],
                    rotate: [360, 180, 0],
                  }}
                  transition={{
                    duration: 4,
                    repeat: Infinity,
                    ease: "linear"
                  }}
                  className="absolute -bottom-20 -left-20 w-40 h-40 bg-white/10 rounded-full blur-3xl"
                />
              </div>

              {/* Close button */}
              <Button
                variant="ghost"
                size="icon"
                onClick={handleClose}
                className="absolute top-4 right-4 text-white hover:bg-white/20 z-10"
              >
                <X className="h-4 w-4" />
              </Button>

              {/* Content */}
              <div className="relative z-10 text-center">
                {/* Icon with animation */}
                <motion.div
                  animate={{
                    rotate: [0, 10, -10, 10, 0],
                    scale: [1, 1.1, 1, 1.1, 1],
                  }}
                  transition={{
                    duration: 0.5,
                    repeat: Infinity,
                    repeatDelay: 1
                  }}
                  className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full mb-6"
                >
                  <Award className="h-10 w-10 text-white" />
                </motion.div>

                {/* Title */}
                <h2 className="text-3xl font-bold text-white mb-2">
                  Félicitations ! 🎉
                </h2>

                {/* Reward amount */}
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 0.2, type: "spring" }}
                  className="mb-4"
                >
                  <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-sm px-6 py-3 rounded-full">
                    <Sparkles className="h-6 w-6 text-yellow-300" />
                    <span className="text-4xl font-bold text-white">+{amount}</span>
                    <span className="text-2xl font-semibold text-white/90">My's</span>
                  </div>
                </motion.div>

                {/* Description */}
                <p className="text-white/90 text-lg mb-6">
                  {title}
                </p>

                {/* Action button */}
                <Button
                  onClick={handleClose}
                  size="lg"
                  className="bg-white text-primary hover:bg-white/90 font-semibold"
                >
                  Super ! Continuer
                </Button>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
