import type React from "react"
import type { Metadata } from "next"

export async function generateMetadata({ params }: { params: { announcementId: string } }): Promise<Metadata> {
  return {
    title: "Offre d'emploi | MyReklam",
    description: "Découvrez cette offre d'emploi sur MyReklam",
    openGraph: {
      title: "Offre d'emploi | MyReklam",
      description: "Découvrez cette offre d'emploi sur MyReklam",
      type: "website",
    },
  }
}

export default function JobLayout({ children }: { children: React.ReactNode }) {
  return children
}
