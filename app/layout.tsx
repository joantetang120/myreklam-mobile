import type React from "react"
import type { Metadata } from "next"
import { Poppins } from "next/font/google"
import Script from "next/script"
import "./globals.css"
import { ToastersWrapper } from "@/components/toasters-wrapper"
import { PageLoadToast } from "@/components/page-load-toast"
import { Header } from "@/components/header"
import { Footer } from "@/components/footer"
import { GoogleOAuthProviderWrapper } from "@/components/providers/google-oauth-provider"

const poppins = Poppins({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700", "800"],
  variable: "--font-poppins",
  display: "swap",
})

export const metadata: Metadata = {
  title: "Myreklam - Plateforme de bouche-à-oreille digital",
  description:
    "Transformez vos recommandations en réseau digital. Partagez des bons plans, offres d'emploi, formations et événements.",
  icons: {
    icon: '/assets/images/logo/favicon.ico',
    shortcut: '/assets/images/logo/favicon.ico',
    apple: '/assets/images/logo/favicon.ico',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="fr" className={poppins.variable}>
      <body className="overflow-x-hidden">
        <Script
          async
          src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-1589925692796181"
          crossOrigin="anonymous"
          strategy="afterInteractive"
        />
        <GoogleOAuthProviderWrapper>
          <Header />
          <main className="min-h-screen">{children}</main>
          <Footer />
          <ToastersWrapper />
          <PageLoadToast />
        </GoogleOAuthProviderWrapper>
      </body>
    </html>
  )
}
