import type React from "react"
import type { Metadata } from "next"

export async function generateMetadata({ 
  params 
}: { 
  params: Promise<{ announcementId: string }> 
}): Promise<Metadata> {
  // Unwrap params
  const resolvedParams = await params
  const { announcementId } = resolvedParams

  return {
    title: "Formation | MyReklam",
    description: "Découvrez cette formation sur MyReklam",
    openGraph: {
      title: "Formation | MyReklam",
      description: "Découvrez cette formation sur MyReklam",
      type: "website",
    },
  }
}

export default function TrainingLayout({ children }: { children: React.ReactNode }) {
  return children
}