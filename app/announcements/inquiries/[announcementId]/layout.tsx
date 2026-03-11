import type React from "react"
import type { Metadata } from "next"

export async function generateMetadata({ params }: { params: { announcementId: string } }): Promise<Metadata> {
  return {
    title: "Demande | MyReklam",
    description: "Découvrez cette demande sur MyReklam",
    openGraph: {
      title: "Demande | MyReklam",
      description: "Découvrez cette demande sur MyReklam",
      type: "website",
    },
  }
}

export default function InquiryLayout({ children }: { children: React.ReactNode }) {
  return children
}
