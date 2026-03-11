"use client"

import { useEffect, useState } from "react"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Card } from "@/components/ui/card"
import { formatDate } from "@/lib/utils"
import { getHistoryCoins, getUserCoin, type HistoryCoin } from "@/lib/api"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { TrendingUp, Filter } from "lucide-react"

export function HistoryEventCoinsTable() {
  const [history, setHistory] = useState<HistoryCoin[]>([])
  const [filteredHistory, setFilteredHistory] = useState<HistoryCoin[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [totalCoins, setTotalCoins] = useState<number>(0)
  const [filter, setFilter] = useState<string>("all")

  useEffect(() => {
    const fetchHistory = async () => {
      const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
      if (!userId) {
        setIsLoading(false)
        return
      }

      try {
        const [data, total] = await Promise.all([
          getHistoryCoins(userId),
          getUserCoin(userId)
        ])
        console.log("[HistoryEventCoinsTable] Data received:", data)
        setHistory(data)
        setTotalCoins(total || 0)
        setFilteredHistory(data)
      } catch (error) {
        console.error("Erreur lors de la récupération de l'historique:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchHistory()
  }, [])

  useEffect(() => {
    if (filter === "all") {
      setFilteredHistory(history)
    } else if (filter === "parrainage") {
      setFilteredHistory(history.filter(item => 
        item.title?.toLowerCase().includes("parrain") || 
        item.description?.toLowerCase().includes("parrain") ||
        item.eventname === "parrainage"
      ))
    } else if (filter === "recent") {
      const thirtyDaysAgo = new Date()
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
      setFilteredHistory(history.filter(item => 
        new Date(item.createdat) >= thirtyDaysAgo
      ))
    }
  }, [filter, history])

  if (isLoading) {
    return <div className="text-center py-8">Chargement...</div>
  }

  const totalFiltered = filteredHistory.reduce((sum, item) => sum + item.coins, 0)

  return (
    <div className="space-y-4">
      {/* Statistiques et filtres */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-gradient-to-br from-green-50 to-emerald-50 rounded-lg border border-green-200">
            <div className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-green-600" />
              <div>
                <p className="text-xs text-gray-600">Total My's</p>
                <p className="text-xl font-bold text-green-600">{totalCoins}</p>
              </div>
            </div>
          </div>
          {filter !== "all" && (
            <div className="p-3 bg-blue-50 rounded-lg border border-blue-200">
              <div>
                <p className="text-xs text-gray-600">Filtré</p>
                <p className="text-xl font-bold text-blue-600">{totalFiltered}</p>
              </div>
            </div>
          )}
        </div>
        <div className="flex items-center gap-2">
          <Filter className="w-4 h-4 text-gray-500" />
          <Select value={filter} onValueChange={setFilter}>
            <SelectTrigger className="w-full sm:w-[180px]">
              <SelectValue placeholder="Filtrer" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Tous</SelectItem>
              <SelectItem value="parrainage">Parrainage</SelectItem>
              <SelectItem value="recent">30 derniers jours</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {filteredHistory.length === 0 ? (
        <Card className="p-8 text-center">
          <p className="text-gray-500">
            {history.length === 0 
              ? "Aucun historique de récompenses pour le moment" 
              : "Aucun résultat pour ce filtre"}
          </p>
        </Card>
      ) : (
        <div className="overflow-x-auto">
          <div className="hidden sm:grid grid-cols-[120px_1fr_100px] gap-4 mb-4 px-4 py-2 font-semibold text-sm">
            <div>Date</div>
            <div>Action</div>
            <div className="text-right">Points</div>
          </div>
          <div className="space-y-2">
            {filteredHistory.map((item, index) => (
          <div
            key={item.history_id}
            className="flex flex-col sm:grid sm:grid-cols-[120px_1fr_100px] gap-3 sm:gap-4 sm:items-center p-4 bg-green-50 rounded-lg"
          >
            {/* Date avec icône */}
            <div className="flex items-center justify-between sm:justify-start gap-2">
              <span className="text-xs sm:text-sm text-gray-600">{formatDate(item.createdat)}</span>
              <span className="sm:hidden inline-block px-3 py-1 bg-green-600 text-white font-semibold rounded-md text-xs">
                {item.coins} my's
              </span>
            </div>

            {/* Action avec icône, titre et description */}
            <div className="flex items-start gap-3">
              <div className="flex-shrink-0 w-10 h-10 bg-white rounded-lg flex items-center justify-center text-2xl shadow-sm">
                {item.icon}
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="font-semibold text-gray-900 mb-1 text-sm sm:text-base">{item.title}</h4>
                <p className="text-xs sm:text-sm text-gray-600 break-words">{item.description}</p>
              </div>
            </div>

            {/* Points - Desktop only */}
            <div className="hidden sm:block text-right">
              <span className="inline-block px-3 py-1 bg-green-600 text-white font-semibold rounded-md text-sm">
                {item.coins} my's
              </span>
            </div>
            </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
