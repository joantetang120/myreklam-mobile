"use client"
import { Card } from "@/components/ui/card"
import { Star } from "lucide-react"

interface AmbassadorStatus {
  title: string
  valuemys: number
  star: number
  hexprimarycolor: string
  hexsecondarcolor: string
  hexlightcolor: string
  mincoins: number
  maxcoins: number
}

interface AmbassadorStatusCardProps {
  title: string
  valuemys: number
  star: number
  hexprimarycolor: string
  hexsecondarcolor: string
  hexlightcolor: string
  asShadow: boolean
  showText: boolean
}

function AmbassadorStatusCard({
  title,
  valuemys,
  star,
  hexprimarycolor,
  hexsecondarcolor,
  hexlightcolor,
  asShadow,
  showText,
}: AmbassadorStatusCardProps) {
  return (
    <Card
      className={`p-6 rounded-2xl transition-all duration-300 ${
        asShadow ? "shadow-xl scale-105" : "shadow-sm opacity-60"
      }`}
      style={{
        backgroundColor: hexlightcolor,
        borderColor: hexprimarycolor,
        borderWidth: "2px",
      }}
    >
      <div className="flex flex-col items-center gap-3">
        <div className="flex gap-1">
          {Array.from({ length: star }).map((_, i) => (
            <Star key={i} className="h-5 w-5" style={{ fill: hexprimarycolor, color: hexprimarycolor }} />
          ))}
        </div>
        {showText && (
          <>
            <h3 className="font-bold text-lg" style={{ color: hexprimarycolor }}>
              {title}
            </h3>
            <p className="text-sm text-gray-600">
              {valuemys === 0 ? "0-50" : valuemys === 51 ? "51-200" : "201+"} my's
            </p>
          </>
        )}
      </div>
    </Card>
  )
}

export function UserAmbassadorStatus({ userMys }: { userMys: number }) {
  const colorsNotSelected = "#E2EBFF"

  const statuses: AmbassadorStatus[] = [
    {
      title: "SILVER",
      valuemys: 0,
      star: 1,
      hexprimarycolor: "#94a3b8",
      hexsecondarcolor: "#cbd5e1",
      hexlightcolor: "#f1f5f9",
      mincoins: 0,
      maxcoins: 50,
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
    },
  ]

  const isStatusActive = (status: AmbassadorStatus) => {
    return userMys >= status.mincoins && userMys <= status.maxcoins
  }

  return (
    <div className="w-full">
      {/* Version Desktop */}
      <div className="hidden md:flex justify-center items-center gap-4 flex-wrap">
        {statuses.map((status, index) => (
          <div key={index} className={isStatusActive(status) ? "z-20" : ""}>
            <AmbassadorStatusCard
              title={status.title}
              valuemys={status.valuemys}
              star={status.star}
              hexprimarycolor={isStatusActive(status) ? status.hexprimarycolor : colorsNotSelected}
              hexsecondarcolor={isStatusActive(status) ? status.hexsecondarcolor : colorsNotSelected}
              hexlightcolor={isStatusActive(status) ? status.hexlightcolor : colorsNotSelected}
              asShadow={isStatusActive(status)}
              showText={isStatusActive(status)}
            />
          </div>
        ))}
      </div>

      {/* Version Mobile */}
      <div className="md:hidden flex flex-col items-center gap-4">
        {statuses.map((status, index) => (
          <div key={index} className={isStatusActive(status) ? "scale-105 z-20" : ""}>
            <AmbassadorStatusCard
              title={status.title}
              valuemys={status.valuemys}
              star={status.star}
              hexprimarycolor={isStatusActive(status) ? status.hexprimarycolor : colorsNotSelected}
              hexsecondarcolor={isStatusActive(status) ? status.hexsecondarcolor : colorsNotSelected}
              hexlightcolor={isStatusActive(status) ? status.hexlightcolor : colorsNotSelected}
              asShadow={isStatusActive(status)}
              showText={isStatusActive(status)}
            />
          </div>
        ))}
      </div>
    </div>
  )
}
