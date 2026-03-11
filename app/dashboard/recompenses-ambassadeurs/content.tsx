"use client"

import { useEffect, useState } from "react"
import { Coins, Award, Clock, Lightbulb, RefreshCcw, TrendingUp, Star, Zap } from "lucide-react"
import { getUserCoin, conversionCoins } from "@/lib/api"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { StatusTimeline } from "@/components/status-timeline"
import { UserAmbassadorStatus } from "@/components/user-ambassador-status"
import { HistoryEventCoinsTable } from "@/components/history-event-coins-table"
import { ActionEventCoinsTable } from "@/components/action-event-coins-table"
import { useToast } from "@/hooks/use-toast"
import { Progress } from "@/components/ui/progress"
import Image from "next/image"
import FeatureGuard from "@/components/subscription/feature-guard"

export function RecompensesContent() {
  const [userTotalCoins, setUserTotalCoins] = useState<number | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [isConverting, setIsConverting] = useState(false)
  const [showAnimation, setShowAnimation] = useState(false)
  const { toast } = useToast()

  const levels = [
    { name: "SILVER", min: 0, max: 50, color: "from-gray-400 to-gray-300", bgColor: "bg-gray-100", icon: "🥈" },
    { name: "GOLD", min: 51, max: 200, color: "from-yellow-500 to-yellow-300", bgColor: "bg-yellow-50", icon: "🥇" },
    {
      name: "PLATINUM",
      min: 201,
      max: Number.POSITIVE_INFINITY,
      color: "from-cyan-400 to-blue-500",
      bgColor: "bg-cyan-50",
      icon: "💎",
    },
  ]

  const currentLevel = levels.find((level) => (userTotalCoins || 0) >= level.min && (userTotalCoins || 0) <= level.max)
  const nextLevel = levels[levels.indexOf(currentLevel!) + 1]
  const progress = currentLevel
    ? currentLevel.max === Number.POSITIVE_INFINITY
      ? 100
      : (((userTotalCoins || 0) - currentLevel.min) / (currentLevel.max - currentLevel.min)) * 100
    : 0

  useEffect(() => {
    const fetchData = async () => {
      try {
        setIsLoading(true)
        const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
        if (userId) {
          const coins = await getUserCoin(userId)
          setUserTotalCoins(coins)
          setTimeout(() => setShowAnimation(true), 100)
        }
      } catch (error) {
        console.error("Erreur lors de la récupération des données:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchData()
  }, [])

  const handleConversion = async () => {
    setIsConverting(true)
    try {
      const result = await conversionCoins()
      if (result.success) {
        toast({
          title: "Succès",
          description: result.message || "Conversion en cours",
        })
      } else {
        toast({
          title: "Erreur",
          description: result.message || "Erreur lors de la conversion",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Une erreur est survenue",
        variant: "destructive",
      })
    } finally {
      setIsConverting(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-amber-50 via-white to-orange-50 p-4 md:p-8">
      <div className="max-w-7xl mx-auto space-y-6 md:space-y-8">
        <div
          className={`text-center space-y-4 transition-all duration-1000 ${
            showAnimation ? "opacity-100 translate-y-0" : "opacity-0 -translate-y-4"
          }`}
        >
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-amber-100 rounded-full text-amber-800 text-sm font-medium">
            <Star className="w-4 h-4 fill-amber-500 text-amber-500" />
            Programme Ambassadeur
          </div>
          <h1 className="text-3xl md:text-5xl font-bold bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">
            Vos Récompenses
          </h1>
          <p className="text-muted-foreground max-w-2xl mx-auto text-sm md:text-base px-4">
            Gagnez des My's en parrainant vos amis et débloquez des récompenses exclusives
          </p>
        </div>

        <Card
          className={`relative overflow-hidden border-2 border-amber-200 bg-gradient-to-br from-amber-50 to-orange-50 transition-all duration-1000 ${
            showAnimation ? "opacity-100 scale-100" : "opacity-0 scale-95"
          }`}
        >
          <div className="absolute inset-0 shimmer opacity-30" />
          <CardContent className="p-6 md:p-12">
            <div className="flex flex-col md:flex-row items-center justify-between gap-6 md:gap-8">
              <div className="flex-1 w-full text-center md:text-left space-y-4">
                <div className="flex items-center gap-2 justify-center md:justify-start">
                  <Coins className="w-5 h-5 md:w-6 md:h-6 text-amber-600" />
                  <h2 className="text-xl md:text-2xl font-bold text-gray-800">Votre Solde</h2>
                </div>
                {isLoading ? (
                  <div className="text-muted-foreground">Chargement...</div>
                ) : (
                  <div className="space-y-4">
                    <div className="flex items-center gap-3 md:gap-4 justify-center md:justify-start flex-wrap">
                      <span className="text-5xl md:text-7xl font-black bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">
                        {userTotalCoins || 0}
                      </span>
                      <div className="animate-float">
                        <div className="relative w-14 h-14 md:w-20 md:h-20">
                          <Image
                            src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
                            alt="My's Coin"
                            width={80}
                            height={80}
                            className="w-full h-full object-contain drop-shadow-2xl"
                            style={{
                              filter: "brightness(1.1) contrast(1.2)",
                              mixBlendMode: "darken",
                            }}
                          />
                        </div>
                      </div>
                    </div>
                    {currentLevel && (
                      <div className="space-y-2">
                        <div className="flex flex-col sm:flex-row items-center justify-between gap-2 text-sm">
                          <span className="font-medium text-gray-700 flex items-center gap-2">
                            <span className="text-xl md:text-2xl">{currentLevel.icon}</span>
                            <span className="text-sm md:text-base">Niveau {currentLevel.name}</span>
                          </span>
                          {nextLevel ? (
                            <span className="text-muted-foreground text-xs md:text-sm text-center">
                              {nextLevel.min - (userTotalCoins || 0)} My's jusqu'au {nextLevel.name}
                            </span>
                          ) : (
                            <span className="text-amber-600 font-semibold text-xs md:text-sm">
                              Niveau Maximum Atteint! 🎉
                            </span>
                          )}
                        </div>
                        <div className="relative">
                          <Progress value={progress} className="h-2 md:h-3" />
                          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer" />
                        </div>
                        <div className="flex justify-between text-xs text-muted-foreground">
                          <span>{currentLevel.min} My's</span>
                          {currentLevel.max !== Number.POSITIVE_INFINITY && <span>{currentLevel.max} My's</span>}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
              <div className="flex flex-col gap-3 md:gap-4 w-full md:w-auto">
                <FeatureGuard feature="conversion">
                <Button
                  onClick={handleConversion}
                  disabled={isConverting}
                  size="lg"
                  className="w-full md:w-auto bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-white font-bold shadow-lg hover:shadow-xl transition-all animate-pulse-glow text-sm md:text-base"
                >
                  <RefreshCcw className={`mr-2 h-4 w-4 md:h-5 md:w-5 ${isConverting ? "animate-spin" : ""}`} />
                  Convertir en Récompenses
                </Button>
                </FeatureGuard>
                <p className="text-xs text-center text-muted-foreground px-2">
                  Échangez vos My's contre des avantages exclusifs
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 md:gap-4">
          <Card className="border-2 hover:border-amber-300 transition-colors">
            <CardContent className="p-4 md:p-6">
              <div className="flex items-center gap-3 md:gap-4">
                <div className="p-2 md:p-3 bg-amber-100 rounded-xl flex-shrink-0">
                  <TrendingUp className="w-5 h-5 md:w-6 md:h-6 text-amber-600" />
                </div>
                <div className="min-w-0">
                  <p className="text-xs md:text-sm text-muted-foreground truncate">Progression</p>
                  <p className="text-xl md:text-2xl font-bold">{Math.round(progress)}%</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card className="border-2 hover:border-amber-300 transition-colors">
            <CardContent className="p-4 md:p-6">
              <div className="flex items-center gap-3 md:gap-4">
                <div className="p-2 md:p-3 bg-orange-100 rounded-xl flex-shrink-0">
                  <Award className="w-5 h-5 md:w-6 md:h-6 text-orange-600" />
                </div>
                <div className="min-w-0">
                  <p className="text-xs md:text-sm text-muted-foreground truncate">Niveau Actuel</p>
                  <p className="text-xl md:text-2xl font-bold flex items-center gap-2">
                    <span className="text-lg md:text-xl">{currentLevel?.icon}</span>
                    <span className="truncate">{currentLevel?.name || "SILVER"}</span>
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card className="border-2 hover:border-amber-300 transition-colors sm:col-span-2 lg:col-span-1">
            <CardContent className="p-4 md:p-6">
              <div className="flex items-center gap-3 md:gap-4">
                <div className="p-2 md:p-3 bg-yellow-100 rounded-xl flex-shrink-0">
                  <Zap className="w-5 h-5 md:w-6 md:h-6 text-yellow-600" />
                </div>
                <div className="min-w-0">
                  <p className="text-xs md:text-sm text-muted-foreground truncate">Prochain Niveau</p>
                  <p className="text-xl md:text-2xl font-bold flex items-center gap-2">
                    {nextLevel ? (
                      <>
                        <span className="text-lg md:text-xl">{nextLevel.icon}</span>
                        <span className="truncate">{nextLevel.name}</span>
                      </>
                    ) : (
                      "Max 🎉"
                    )}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <Card className="border-2">
          <CardHeader className="px-4 md:px-6">
            <CardTitle className="flex items-center gap-2 text-lg md:text-xl">
              <Award className="w-4 h-4 md:w-5 md:h-5 text-amber-600 flex-shrink-0" />
              <span className="truncate">Votre Statut Ambassadeur</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 md:space-y-6 px-4 md:px-6">
            <StatusTimeline userMys={userTotalCoins || 0} />
            <UserAmbassadorStatus userMys={userTotalCoins || 0} />
          </CardContent>
        </Card>

        <Card className="border-2">
          <CardHeader className="px-4 md:px-6">
            <CardTitle className="flex items-center gap-2 text-lg md:text-xl">
              <Clock className="w-4 h-4 md:w-5 md:h-5 text-amber-600 flex-shrink-0" />
              <span className="truncate">Historique des Récompenses</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="px-4 md:px-6 overflow-x-auto">
            <HistoryEventCoinsTable />
          </CardContent>
        </Card>

        <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-cyan-50">
          <CardHeader className="px-4 md:px-6">
            <CardTitle className="flex items-center gap-2 text-lg md:text-xl">
              <Lightbulb className="w-4 h-4 md:w-5 md:h-5 text-blue-600 flex-shrink-0" />
              <span className="truncate">Comment Gagner Plus de My's</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="px-4 md:px-6 overflow-x-auto">
            <ActionEventCoinsTable />
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
