"use client"

import { useEffect, useState } from "react"
import { getUserCoin } from "@/lib/api"

interface AmbassadorStatus {
  level: "SILVER" | "GOLD" | "PLATINUM"
  min: number
  max: number
  hexprimarycolor: string
  icon: string
}

const levels: AmbassadorStatus[] = [
  { level: "SILVER", min: 0, max: 50, hexprimarycolor: "#9CA3AF", icon: "🥈" },
  { level: "GOLD", min: 51, max: 200, hexprimarycolor: "#EAB308", icon: "🥇" },
  { level: "PLATINUM", min: 201, max: Number.POSITIVE_INFINITY, hexprimarycolor: "#06B6D4", icon: "💎" },
]

export function useAmbassadorStatus(userId: string) {
  const [activeStatus, setActiveStatus] = useState<AmbassadorStatus | null>(null)
  const [totalCoins, setTotalCoins] = useState<number>(0)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchStatus = async () => {
      if (!userId) {
        setLoading(false)
        return
      }

      try {
        const coins = await getUserCoin(userId)
        setTotalCoins(coins)

        const status = levels.find((level) => coins >= level.min && coins <= level.max)
        setActiveStatus(status || levels[0])
      } catch (error) {
        console.error("[v0] Error fetching ambassador status:", error)
        setActiveStatus(levels[0])
      } finally {
        setLoading(false)
      }
    }

    fetchStatus()
  }, [userId])

  return { activeStatus, totalCoins, loading }
}
