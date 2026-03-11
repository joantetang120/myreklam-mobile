"use client"

import { useEffect, useState } from "react"
import { Card } from "@/components/ui/card"
import { getAffiliateList, type AffiliateItem } from "@/lib/api"
import { Users, TrendingUp } from "lucide-react"

export function SponsorshipHistory() {
  const [affiliates, setAffiliates] = useState<AffiliateItem[]>([])
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchAffiliates = async () => {
      const data = await getAffiliateList()
      const sortedData = data.sort((a, b) => 
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      )
      setAffiliates(sortedData)
      setIsLoading(false)
    }

    fetchAffiliates()
  }, [])

  if (isLoading) {
    return (
      <Card className="p-6 w-full">
        <div className="text-center text-gray-500">Chargement de l'historique...</div>
      </Card>
    )
  }

  const totalMys = affiliates.reduce((sum, affiliate) => sum + affiliate.commission, 0)

  return (
    <Card className="p-6 w-full">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
            <Users className="h-5 w-5" />
            Historique des parrainages
          </h3>
          <div className="flex items-center gap-2 text-green-600 font-semibold">
            <TrendingUp className="h-5 w-5" />
            {totalMys} My's gagnés
          </div>
        </div>

        {affiliates.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            <Users className="h-12 w-12 mx-auto mb-3 text-gray-300" />
            <p>Aucun parrainage pour le moment</p>
            <p className="text-sm mt-2">Commencez à partager votre code pour gagner des My's !</p>
          </div>
        ) : (
          <div className="space-y-3">
            {affiliates.map((affiliate) => (
              <div
                key={affiliate.id}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
              >
                <div className="flex-1">
                  <p className="font-medium text-gray-800">
                    {affiliate.referred_pseudo || affiliate.referred_nomsociete}
                  </p>
                  <p className="text-sm text-gray-500">{affiliate.desciption}</p>
                  <p className="text-xs text-gray-400 mt-1">
                    {new Date(affiliate.created_at).toLocaleDateString("fr-FR")}
                  </p>
                </div>
                <div className="text-right">
                  <p className="font-bold text-green-600">+{affiliate.commission} My's</p>
                  <p className="text-xs text-gray-500 capitalize">{affiliate.referred_profile_type}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Card>
  )
}
