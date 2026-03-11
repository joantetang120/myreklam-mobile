"use client"

import { Copy } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

interface SponsorshipCodeProps {
  code: string
  onCopy: () => void
}

export function SponsorshipCode({ code, onCopy }: SponsorshipCodeProps) {
  return (
    <Card className="p-6 w-full max-w-md hover:shadow-lg transition-shadow duration-300">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-800">Code de parrainage</h3>
          <Copy className="h-5 w-5 text-gray-400" />
        </div>
        <div className="flex items-center gap-3">
          <div className="flex-1 bg-gray-50 rounded-lg p-4 font-mono text-xl font-bold text-center text-primary">
            {code}
          </div>
          <Button onClick={onCopy} variant="outline" size="icon" className="shrink-0 bg-transparent">
            <Copy className="h-4 w-4" />
          </Button>
        </div>
        <p className="text-sm text-gray-500">
          Partagez ce code avec vos amis pour qu'ils puissent s'inscrire et vous faire gagner des My's
        </p>
      </div>
    </Card>
  )
}
