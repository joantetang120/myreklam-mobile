import type React from "react"
import type { Metadata } from "next"
import { config } from "@/lib/config"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { fetchDealImages } from "@/lib/api"

// Génération des métadonnées pour le SEO et Open Graph
export async function generateMetadata({
  params,
}: {
  params: { announcementId: string }
}): Promise<Metadata> {
  // En développement avec localtonet, on génère quand même les métadonnées
  const isLocaltonet = config.SITE_URL && config.SITE_URL.includes("loclx.io")

  if (process.env.NODE_ENV === "development" && !isLocaltonet) {
    return {
      title: "MyReklam - Bon Plan",
      description: "Découvrez cette offre sur MyReklam",
      openGraph: {
        title: "MyReklam - Bon Plan",
        description: "Découvrez cette offre sur MyReklam",
        siteName: "MyReklam",
        type: "website",
      },
    }
  }

  try {
    // const { announcementId } = params
    const resolvedParams = await params
    const { announcementId } = resolvedParams

    // Récupérer les données de l'annonce côté serveur
    const deal = await fetchAnnouncementDetail(announcementId)
    const imagesResult = await fetchDealImages(announcementId)

    // Fallback si pas de données
    const title = deal ? `${deal.title} - MyReklam` : "MyReklam - Bon Plan"
    const description = deal?.description || "Découvrez cette offre sur MyReklam"
    const siteUrl = config.SITE_URL?.replace(/\/$/, "") || "https://myreklam.fr"
    const pageUrl = `${siteUrl}/announcements/deals/${announcementId}`

    // Image principale pour Open Graph - toujours une URL absolue
    let ogImage = `${siteUrl}/assets/images/logo/logo_clean.png`
    if (imagesResult?.success && imagesResult.images?.[0]) {
      // S'assurer que l'URL de l'image est absolue
      const imageUrl = imagesResult.images[0]
      ogImage = imageUrl.startsWith("http") ? imageUrl : `${config.API_URL}/${imageUrl}`
    }

    return {
      title,
      description,
      openGraph: {
        title,
        description,
        url: pageUrl,
        siteName: "MyReklam",
        images: [
          {
            url: ogImage,
            width: 1200,
            height: 630,
            alt: deal?.title || "MyReklam",
          },
        ],
        locale: "fr_FR",
        type: "website",
      },
      twitter: {
        card: "summary_large_image",
        title,
        description,
        images: [ogImage],
      },
      alternates: {
        canonical: pageUrl,
      },
      robots: {
        index: true,
        follow: true,
      },
    }
  } catch (error) {
    console.error("Erreur lors de la génération des métadonnées:", error)
    return {
      title: "MyReklam",
      description: "Découvrez les bons plans sur MyReklam",
    }
  }
}

export default function DealLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}
