import type React from "react"
import type { Metadata } from "next"

export async function generateMetadata({ params }: { params: { announcementId: string } }): Promise<Metadata> {
  const resolvedParams = await params
  const { announcementId } = resolvedParams

  return {
    title: "Événement | MyReklam",
    description: "Découvrez cet événement sur MyReklam",
    openGraph: {
      title: "Événement | MyReklam",
      description: "Découvrez cet événement sur MyReklam",
      type: "website",
    },
  }
}

export default function EventLayout({ children }: { children: React.ReactNode }) {
  return children
}
