"use client"

import type React from "react"

import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Sparkles } from "lucide-react"
import { motion } from "framer-motion"

interface MysCongratsModalProps {
  isOpen: boolean
  onClose: () => void
  content: React.ReactNode
}

export function MysCongratsModal({ isOpen, onClose, content }: MysCongratsModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-center text-2xl font-bold">Félicitations !</DialogTitle>
        </DialogHeader>
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: "spring", duration: 0.5 }}
          className="flex flex-col items-center gap-6 py-6"
        >
          <div className="w-20 h-20 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center">
            <Sparkles className="w-10 h-10 text-white" />
          </div>
          <div className="text-center text-gray-700">{content}</div>
          <Button onClick={onClose} className="w-full bg-gradient-to-r from-green-500 to-green-600">
            Continuer
          </Button>
        </motion.div>
      </DialogContent>
    </Dialog>
  )
}
