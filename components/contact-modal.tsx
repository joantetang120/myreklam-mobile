"use client"

import { Dialog, DialogContent } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Phone, Mail, X } from "lucide-react"

interface ContactModalProps {
  isOpen: boolean
  onClose: () => void
  phoneNumber?: string
  onMessageClick: () => void
}

export function ContactModal({ isOpen, onClose, phoneNumber, onMessageClick }: ContactModalProps) {
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md p-0 gap-0">
        <div className="relative p-8">
          <button
            onClick={onClose}
            className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground"
          >
            <X className="h-4 w-4" />
            <span className="sr-only">Fermer</span>
          </button>

          <h2 className="text-2xl font-bold text-center mb-8 text-gray-900">
            Comment souhaitez-vous
            <br />
            contacter cette personne ?
          </h2>

          <div className="space-y-4">
            {phoneNumber && (
              <Button
                onClick={() => {
                  window.location.href = `tel:${phoneNumber}`
                  onClose()
                }}
                className="w-full h-auto py-4 bg-green-600 hover:bg-green-700 text-white text-base font-semibold"
              >
                <Phone className="h-5 w-5 mr-3" />
                Par téléphone au {phoneNumber}
              </Button>
            )}

            <div className="text-center text-sm text-gray-500 font-medium">Ou</div>

            <Button
              onClick={() => {
                onMessageClick()
                onClose()
              }}
              variant="outline"
              className="w-full h-auto py-4 bg-yellow-50 hover:bg-yellow-100 border-yellow-200 text-gray-900 text-base font-semibold"
            >
              <Mail className="h-5 w-5 mr-3" />
              Par mail en cliquant ici
            </Button>
          </div>

          <button
            onClick={onClose}
            className="w-full text-center mt-6 text-sm text-gray-500 hover:text-gray-700 transition-colors"
          >
            Annuler
          </button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
