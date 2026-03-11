"use client"

import { useEffect, useState } from "react"
import { Lightbulb, Loader2 } from "lucide-react"
import { getEventCoins } from "@/lib/api"

interface EventCoin {
  id: string
  slug: string
  title: string
  description: string
  coins: number
  status: boolean
  icon: string
  rank: number
  createdat?: string
  date?: string
}

export function ActionEventCoinsTable() {
  const [actions, setActions] = useState<EventCoin[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchEventCoins = async () => {
      try {
        setIsLoading(true)
        setError(null)
        console.log("[ActionEventCoinsTable] Fetching event coins from API...")
        
        const eventCoins = await getEventCoins()
        console.log("[ActionEventCoinsTable] Event coins received:", eventCoins)
        
        // L'API filtre déjà avec status = true, mais on double-vérifie
        // Convertir les données en format local avec tous les champs
        const activeActions = (eventCoins as any[])
          .filter((coin: any) => {
            // Gérer différents formats de status (boolean, number, string)
            const status = coin.status
            return status === true || status === "true" || status === 1 || status === "1"
          })
          .map((coin: any) => ({
            id: coin.id,
            slug: coin.slug,
            title: coin.title,
            description: coin.description,
            coins: Number(coin.coins) || 0,
            status: coin.status,
            icon: coin.icon || "📌",
            rank: Number(coin.rank) || 0,
            createdat: coin.createdat,
            date: coin.date,
          }))
        
        // Trier par rank (croissant)
        activeActions.sort((a: EventCoin, b: EventCoin) => a.rank - b.rank)
        
        setActions(activeActions)
      } catch (err: any) {
        console.error("[ActionEventCoinsTable] Error fetching event coins:", err)
        setError("Erreur lors du chargement des actions")
      } finally {
        setIsLoading(false)
      }
    }

    fetchEventCoins()
  }, [])

  if (isLoading) {
    return (
      <div className="overflow-x-auto">
        <div className="flex items-center gap-2 mb-4 px-4">
          <Lightbulb className="w-5 h-5 text-amber-600" />
          <h3 className="font-semibold text-lg">Tips</h3>
        </div>
        <div className="flex items-center justify-center py-8">
          <Loader2 className="w-6 h-6 animate-spin text-amber-600" />
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="overflow-x-auto">
        <div className="flex items-center gap-2 mb-4 px-4">
          <Lightbulb className="w-5 h-5 text-amber-600" />
          <h3 className="font-semibold text-lg">Tips</h3>
        </div>
        <div className="text-center py-8 text-red-600">
          <p>{error}</p>
        </div>
      </div>
    )
  }

  if (actions.length === 0) {
    return (
      <div className="overflow-x-auto">
        <div className="flex items-center gap-2 mb-4 px-4">
          <Lightbulb className="w-5 h-5 text-amber-600" />
          <h3 className="font-semibold text-lg">Tips</h3>
        </div>
        <div className="text-center py-8 text-gray-500">
          <p>Aucune action disponible</p>
        </div>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto">
      {/* En-tête */}
      <div className="flex items-center gap-2 mb-4 px-4">
        <Lightbulb className="w-5 h-5 text-amber-600" />
        <h3 className="font-semibold text-lg">Tips</h3>
      </div>

      {/* En-têtes de colonnes */}
      <div className="grid grid-cols-[60px_1fr_100px] gap-4 mb-4 px-4 py-2 font-semibold text-sm border-b">
        <div></div>
        <div>Action</div>
        <div className="text-right">My's</div>
      </div>

      {/* Liste des actions */}
      <div className="space-y-3">
        {actions.map((action) => (
          <div
            key={action.id}
            className="grid grid-cols-[60px_1fr_100px] gap-4 items-start px-4 py-3 hover:bg-gray-50 transition-colors"
          >
            {/* Icône */}
            <div className="flex items-start justify-center pt-1">
              <span className="text-2xl">{action.icon || "📌"}</span>
            </div>

            {/* Titre et description */}
            <div className="flex-1 min-w-0">
              <h4 className="font-semibold text-gray-900 mb-1">{action.title}</h4>
              <p className="text-sm text-gray-600">{action.description}</p>
            </div>

            {/* Points */}
            <div className="flex items-start justify-end pt-1">
              <span className="inline-block px-3 py-1 bg-green-100 text-green-700 font-semibold rounded-md text-sm">
                {action.coins} my's
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
