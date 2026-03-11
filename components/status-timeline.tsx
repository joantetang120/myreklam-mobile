"use client"

import { useEffect, useState } from "react"
import { Check, TrendingUp, Sparkles } from "lucide-react"
import { Card } from "@/components/ui/card"
import Image from "next/image"

interface AmbassadorStatus {
  id?: string
  title: string
  valuemys: number
  star: number
  hexprimarycolor: string
  hexsecondarcolor: string
  hexlightcolor: string
  mincoins: number
  maxcoins: number
  raise: boolean
  status?: number
  showrank?: number
}

export function StatusTimeline({ userMys }: { userMys: number }) {
  const [statuses, setStatuses] = useState<AmbassadorStatus[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [animatedMys, setAnimatedMys] = useState(0)

  const hardcodedLevels: AmbassadorStatus[] = [
    {
      title: "SILVER",
      valuemys: 0,
      star: 1,
      hexprimarycolor: "#94a3b8",
      hexsecondarcolor: "#cbd5e1",
      hexlightcolor: "#f1f5f9",
      mincoins: 0,
      maxcoins: 50,
      raise: false,
    },
    {
      title: "GOLD",
      valuemys: 51,
      star: 2,
      hexprimarycolor: "#eab308",
      hexsecondarcolor: "#fbbf24",
      hexlightcolor: "#fef3c7",
      mincoins: 51,
      maxcoins: 200,
      raise: false,
    },
    {
      title: "PLATINUM",
      valuemys: 201,
      star: 3,
      hexprimarycolor: "#06b6d4",
      hexsecondarcolor: "#22d3ee",
      hexlightcolor: "#cffafe",
      mincoins: 201,
      maxcoins: Number.POSITIVE_INFINITY,
      raise: false,
    },
  ]

  useEffect(() => {
    const fetchStatuses = async () => {
      try {
        setStatuses(hardcodedLevels)
      } finally {
        setIsLoading(false)
      }
    }

    fetchStatuses()
  }, [])

  useEffect(() => {
    let start = 0
    const end = userMys
    const duration = 2000
    const increment = end / (duration / 16)

    const timer = setInterval(() => {
      start += increment
      if (start >= end) {
        setAnimatedMys(end)
        clearInterval(timer)
      } else {
        setAnimatedMys(Math.floor(start))
      }
    }, 16)

    return () => clearInterval(timer)
  }, [userMys])

  if (isLoading) {
    return <div className="w-full text-center text-gray-500">Chargement…</div>
  }

  const currentLevel = statuses.find((level) => userMys >= level.mincoins && userMys <= level.maxcoins)
  const currentLevelIndex = statuses.findIndex((level) => level === currentLevel)
  const nextLevel = statuses[currentLevelIndex + 1]

  const progressInCurrentLevel = currentLevel
    ? currentLevel.maxcoins === Number.POSITIVE_INFINITY
      ? 100
      : ((userMys - currentLevel.mincoins) / (currentLevel.maxcoins - currentLevel.mincoins)) * 100
    : 0

  const remainingToNext = nextLevel ? nextLevel.mincoins - userMys : 0

  return (
    <div className="w-full space-y-6 md:space-y-8">
      <div className="flex flex-col lg:flex-row items-center justify-center gap-8 lg:gap-12">
        {/* Circular Progress Gauge */}
        <div className="relative w-64 h-64 flex-shrink-0">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 200 200">
            {/* Background circle */}
            <circle cx="100" cy="100" r="80" fill="none" stroke="#e5e7eb" strokeWidth="20" className="opacity-30" />

            {/* Progress circles for each level */}
            {statuses.map((status, index) => {
              const isCompleted = userMys >= status.mincoins
              const isCurrentLevel = currentLevel === status
              const circumference = 2 * Math.PI * 80
              const segmentLength = circumference / statuses.length
              const offset = index * segmentLength

              let dashArray = `${segmentLength} ${circumference}`
              if (isCurrentLevel) {
                const currentProgress = (progressInCurrentLevel / 100) * segmentLength
                dashArray = `${currentProgress} ${circumference}`
              } else if (!isCompleted) {
                dashArray = `0 ${circumference}`
              }

              return (
                <circle
                  key={index}
                  cx="100"
                  cy="100"
                  r="80"
                  fill="none"
                  stroke={status.hexprimarycolor}
                  strokeWidth="20"
                  strokeDasharray={dashArray}
                  strokeDashoffset={-offset}
                  strokeLinecap="round"
                  className="transition-all duration-1000 ease-out"
                  style={{
                    filter: isCompleted || isCurrentLevel ? `drop-shadow(0 0 8px ${status.hexprimarycolor})` : "none",
                  }}
                />
              )
            })}
          </svg>

          {/* Center content */}
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <div className="relative w-16 h-16 mb-2 animate-float">
              <Image
                src="https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-BH0P219mQD5oZqFtLGEEi8E34PnLvr.png"
                alt="My's Coin"
                width={64}
                height={64}
                className="w-full h-full object-contain drop-shadow-2xl"
                style={{
                  filter: "brightness(1.1) contrast(1.2)",
                  mixBlendMode: "darken",
                }}
              />
            </div>
            <div className="text-4xl font-black bg-gradient-to-r from-amber-600 to-orange-600 bg-clip-text text-transparent">
              {animatedMys}
            </div>
            <div className="text-sm text-muted-foreground">My's</div>
          </div>
        </div>

        {/* Level milestones */}
        <div className="flex-1 w-full max-w-md space-y-4">
          {statuses.map((status, index) => {
            const isCompleted = userMys >= status.mincoins
            const isCurrentLevel = currentLevel === status
            const isFuture = userMys < status.mincoins

            return (
              <Card
                key={index}
                className={`relative overflow-hidden transition-all duration-500 ${
                  isCurrentLevel
                    ? "border-2 shadow-lg scale-105"
                    : isCompleted
                      ? "border-2 opacity-80"
                      : "border opacity-50"
                }`}
                style={{
                  borderColor: isCurrentLevel || isCompleted ? status.hexprimarycolor : undefined,
                  backgroundColor: isCurrentLevel ? status.hexlightcolor : undefined,
                }}
              >
                {isCurrentLevel && (
                  <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer" />
                )}

                <div className="p-4 flex items-center gap-4">
                  {/* Status icon */}
                  <div
                    className={`w-12 h-12 rounded-full flex items-center justify-center flex-shrink-0 transition-all duration-300 ${
                      isCompleted ? "scale-100" : "scale-90"
                    }`}
                    style={{
                      backgroundColor: isCompleted ? status.hexprimarycolor : "#e5e7eb",
                    }}
                  >
                    {isCompleted ? (
                      <Check className="w-6 h-6 text-white" />
                    ) : (
                      <div className="w-3 h-3 rounded-full bg-white/50" />
                    )}
                  </div>

                  {/* Level info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3
                        className="font-bold text-lg truncate"
                        style={{ color: isCompleted ? status.hexprimarycolor : undefined }}
                      >
                        {status.title}
                      </h3>
                      {isCurrentLevel && (
                        <span className="px-2 py-0.5 bg-amber-500 text-white text-xs rounded-full font-medium flex-shrink-0">
                          Actuel
                        </span>
                      )}
                    </div>
                    <div className="text-sm text-muted-foreground">
                      {status.maxcoins === Number.POSITIVE_INFINITY
                        ? `${status.mincoins}+ My's`
                        : `${status.mincoins} - ${status.maxcoins} My's`}
                    </div>

                    {/* Progress bar for current level */}
                    {isCurrentLevel && nextLevel && (
                      <div className="mt-2 space-y-1">
                        <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
                          <div
                            className="h-full transition-all duration-1000 ease-out rounded-full"
                            style={{
                              width: `${progressInCurrentLevel}%`,
                              backgroundColor: status.hexprimarycolor,
                            }}
                          />
                        </div>
                        <div className="flex items-center gap-1 text-xs text-muted-foreground">
                          <TrendingUp className="w-3 h-3" />
                          <span>
                            Plus que {remainingToNext} My's pour {nextLevel.title}
                          </span>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Sparkle effect for completed levels */}
                  {isCompleted && (
                    <Sparkles
                      className="w-5 h-5 flex-shrink-0 animate-pulse"
                      style={{ color: status.hexprimarycolor }}
                    />
                  )}
                </div>
              </Card>
            )
          })}
        </div>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-4 text-center bg-gradient-to-br from-gray-50 to-gray-100">
          <div className="text-2xl font-bold text-gray-700">{currentLevel?.title || "SILVER"}</div>
          <div className="text-sm text-muted-foreground">Niveau Actuel</div>
        </Card>
        <Card className="p-4 text-center bg-gradient-to-br from-amber-50 to-orange-50">
          <div className="text-2xl font-bold text-amber-600">{Math.round(progressInCurrentLevel)}%</div>
          <div className="text-sm text-muted-foreground">Progression</div>
        </Card>
        <Card className="p-4 text-center bg-gradient-to-br from-blue-50 to-cyan-50">
          <div className="text-2xl font-bold text-blue-600">{nextLevel ? remainingToNext : "∞"}</div>
          <div className="text-sm text-muted-foreground">{nextLevel ? `My's restants` : "Niveau Max"}</div>
        </Card>
      </div>
    </div>
  )
}
