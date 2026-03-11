"use client"

import { Copy, Share2 } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

interface SponsorshipLinkProps {
  link: string
  onCopy: () => void
  onShare: () => void
  sharingMessage: string
}

export function SponsorshipLink({ link, onCopy, onShare, sharingMessage }: SponsorshipLinkProps) {
  return (
    <Card className="p-6 w-full max-w-2xl hover:shadow-lg transition-shadow duration-300">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-800">Lien de parrainage</h3>
          <Share2 className="h-5 w-5 text-gray-400" />
        </div>
        <div className="flex items-center gap-3">
          <div className="flex-1 bg-gray-50 rounded-lg p-4 text-sm text-gray-700 break-all">{link}</div>
          <div className="flex gap-2 shrink-0">
            <Button onClick={onCopy} variant="outline" size="icon">
              <Copy className="h-4 w-4" />
            </Button>
            <Button onClick={onShare} variant="default" size="icon">
              <Share2 className="h-4 w-4" />
            </Button>
          </div>
        </div>
        <p className="text-sm text-gray-500">
          Partagez ce lien directement avec vos contacts pour faciliter leur inscription
        </p>
      </div>
    </Card>
  )
}
