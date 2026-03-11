"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Facebook, Twitter, Linkedin, Mail, MessageSquare, Link2, Check, Instagram } from "lucide-react"
import { FaWhatsapp } from "react-icons/fa"

interface ShareModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  url: string
  description?: string
}

export function ShareModal({ isOpen, onClose, title, url, description }: ShareModalProps) {
  const [copied, setCopied] = useState(false)

  const shareUrl = url.startsWith("http") ? url : `${typeof window !== "undefined" ? window.location.origin : ""}${url}`
  const encodedUrl = encodeURIComponent(shareUrl)
  const encodedTitle = encodeURIComponent(title)
  const encodedDescription = encodeURIComponent(description || title)

  const shareMessage =
    "Bonjour, j'ai trouvé une annonce qui devrait vous intéresser sur MyReklam. Voici le lien pour y accéder :"
  const encodedShareMessage = encodeURIComponent(shareMessage)
  const fullWhatsAppMessage = encodeURIComponent(`${shareMessage}\n\n${title}\n${shareUrl}`)
  const fullEmailBody = encodeURIComponent(`${shareMessage}\n\n${title}\n\n${shareUrl}`)
  const fullSMSMessage = encodeURIComponent(`${shareMessage}\n\n${title}\n${shareUrl}`)

  const handleCopyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (error) {
      console.error("Erreur lors de la copie:", error)
    }
  }

  const shareOptions = [
    {
      name: "WhatsApp",
      icon: FaWhatsapp,
      color: "bg-green-500 hover:bg-green-600",
      action: () => {
        window.open(`https://wa.me/?text=${fullWhatsAppMessage}`, "_blank")
      },
    },
    {
      name: "Facebook",
      icon: Facebook,
      color: "bg-blue-600 hover:bg-blue-700",
      action: () => {
        window.open(`https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`, "_blank")
      },
    },
    {
      name: "Twitter",
      icon: Twitter,
      color: "bg-sky-500 hover:bg-sky-600",
      action: () => {
        window.open(
          `https://twitter.com/intent/tweet?text=${encodedShareMessage}%0A%0A${encodedTitle}&url=${encodedUrl}`,
          "_blank",
        )
      },
    },
    {
      name: "LinkedIn",
      icon: Linkedin,
      color: "bg-blue-700 hover:bg-blue-800",
      action: () => {
        window.open(`https://www.linkedin.com/sharing/share-offsite/?url=${encodedUrl}`, "_blank")
      },
    },
    {
      name: "Email",
      icon: Mail,
      color: "bg-gray-600 hover:bg-gray-700",
      action: () => {
        window.location.href = `mailto:?subject=${encodedTitle}&body=${fullEmailBody}`
      },
    },
    {
      name: "SMS",
      icon: MessageSquare,
      color: "bg-purple-600 hover:bg-purple-700",
      action: () => {
        window.location.href = `sms:?body=${fullSMSMessage}`
      },
    },
  ]

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-center text-xl font-semibold">Partager cette annonce</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {/* Social media share buttons */}
          <div className="grid grid-cols-3 gap-3">
            {shareOptions.map((option) => {
              const Icon = option.icon
              return (
                <button
                  key={option.name}
                  onClick={option.action}
                  className={`flex flex-col items-center gap-2 p-4 rounded-lg text-white transition-colors ${option.color}`}
                >
                  <Icon className="w-6 h-6" />
                  <span className="text-xs font-medium">{option.name}</span>
                </button>
              )
            })}
          </div>

          {/* Instagram note */}
          <div className="flex items-center gap-2 p-3 bg-gradient-to-r from-purple-500 via-pink-500 to-orange-500 rounded-lg text-white">
            <Instagram className="w-5 h-5 flex-shrink-0" />
            <p className="text-xs">Pour Instagram, copiez le lien et partagez-le dans votre story ou post</p>
          </div>

          {/* Copy link section */}
          <div className="space-y-2">
            <p className="text-sm font-medium text-gray-700">Ou copiez le lien</p>
            <div className="flex gap-2">
              <input
                type="text"
                value={shareUrl}
                readOnly
                className="flex-1 px-3 py-2 text-sm border border-gray-300 rounded-lg bg-gray-50 focus:outline-none focus:ring-2 focus:ring-primary"
              />
              <Button onClick={handleCopyLink} variant={copied ? "default" : "outline"} className="gap-2">
                {copied ? (
                  <>
                    <Check className="w-4 h-4" />
                    Copié
                  </>
                ) : (
                  <>
                    <Link2 className="w-4 h-4" />
                    Copier
                  </>
                )}
              </Button>
            </div>
          </div>
        </div>

        <div className="flex justify-center pt-2">
          <Button variant="ghost" onClick={onClose} className="text-gray-600">
            Annuler
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
