"use client"

import { useState } from "react"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { ArrowRight, Sparkles } from "lucide-react"
import Image from "next/image"
import { SignUpModal } from "@/components/auth/sign-up-modal"
import { SignInModal } from "@/components/auth/sign-in-modal"

export function CTASection() {
  const [showSignUp, setShowSignUp] = useState(false)
  const [showSignIn, setShowSignIn] = useState(false)

  return (
    <>
    <section className="py-24 bg-gradient-to-br from-primary via-primary to-primary/80 relative overflow-hidden">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center max-w-3xl mx-auto"
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/20 text-white text-sm font-medium mb-6">
            <Sparkles className="w-4 h-4" />
            Rejoignez des milliers d'utilisateurs satisfaits
          </div>

          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-6">
            Rejoignez la révolution du recrutement récompensé
          </h2>

          <p className="text-lg text-white/90 mb-8">
            Inscrivez-vous gratuitement et commencez à gagner des my's dès aujourd'hui. Sans engagement, sans frais
            cachés.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
            <Button 
              size="lg" 
              variant="secondary" 
              className="text-lg h-14 px-8 group"
              onClick={() => setShowSignUp(true)}
            >
              Créer mon compte gratuit
              <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="text-lg h-14 px-8 bg-transparent text-white border-white hover:bg-white/10"
              onClick={() => setShowSignIn(true)}
            >
              Se connecter
            </Button>
          </div>

          <div className="flex items-center justify-center gap-4">
            <Image
              src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
              alt="My's coin"
              width={40}
              height={40}
              className="mix-blend-lighten animate-bounce"
            />
            <p className="text-white/80 text-sm">Bonus de bienvenue : 25 my's offerts à l'inscription</p>
          </div>
        </motion.div>
      </div>
    </section>

    {/* Modals */}
    <SignUpModal 
      isOpen={showSignUp} 
      onClose={() => setShowSignUp(false)}
      onSwitchToSignIn={() => {
        setShowSignUp(false)
        setShowSignIn(true)
      }}
    />
    <SignInModal 
      isOpen={showSignIn} 
      onClose={() => setShowSignIn(false)}
      onSwitchToSignUp={() => {
        setShowSignIn(false)
        setShowSignUp(true)
      }}
    />
    </>
  )
}
