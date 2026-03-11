"use client"

import { useEffect, useState } from "react"
import { Share2, Users, Gift, Sparkles, Copy, Check, TrendingUp, Award } from "lucide-react"
import { getAffiliateCode, getAffiliateList, getUserCoin, sponsorshipCodeParam, type AffiliateItem } from "@/lib/api"
import { SponsorshipCode } from "@/components/sponsorship-code"
import { SponsorshipLink } from "@/components/sponsorship-link"
import { SponsorshipHistory } from "@/components/sponsorship-history"
import { useToast } from "@/hooks/use-toast"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

export function MonParrainageContent() {
  const [sponsorshipCode, setSponsorshipCode] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [sponsorshipLink, setSponsorshipLink] = useState<string>("")
  const [sharingMessage, setSharingMessage] = useState<string>("")
  const [copied, setCopied] = useState(false)
  const [affiliates, setAffiliates] = useState<AffiliateItem[]>([])
  const [totalMysFromParrainage, setTotalMysFromParrainage] = useState<number>(0)
  const [totalMys, setTotalMys] = useState<number>(0)
  const { toast } = useToast()

  useEffect(() => {
    const fetchData = async () => {
      try {
        const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
        console.log("[v0] Parrainage - userId:", userId)
        
        const [code, affiliateList, totalCoins] = await Promise.all([
          getAffiliateCode(),
          getAffiliateList(),
          userId ? getUserCoin(userId) : Promise.resolve(0)
        ])
        
        console.log("[v0] Parrainage - code reçu:", code)
        console.log("[v0] Parrainage - affiliateList:", affiliateList)
        console.log("[v0] Parrainage - totalCoins:", totalCoins)
        
        setSponsorshipCode(code)
        setAffiliates(affiliateList)
        setTotalMys(totalCoins || 0)
        
        // Calculer le total des my's gagnés via parrainage
        const mysFromParrainage = affiliateList.reduce((sum, affiliate) => sum + affiliate.commission, 0)
        setTotalMysFromParrainage(mysFromParrainage)

        if (code && typeof window !== "undefined") {
          const link = `${window.location.origin}/?${sponsorshipCodeParam}=${code}`
          setSponsorshipLink(link)
          setSharingMessage(
            `Bonjour, j'utilise myreklam et j'en suis vraiment satisfait. Voici un lien de parrainage qui te permet de t'inscrire et de bénéficier de nombreux avantages. En utilisant ce lien, tu m'aideras à gagner des points My's que je pourrai échanger contre des récompenses ! Merci d'avance ! ${link}`,
          )
        }
      } catch (error) {
        console.error("Erreur lors du chargement des données:", error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchData()
  }, [])

  const handleCopy = (text: string = sharingMessage) => {
    navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
    toast({
      title: "Copié !",
      description: "Le contenu a été copié dans le presse-papiers",
    })
  }

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: "Mon code parrainage",
          text: sharingMessage,
          url: sponsorshipLink,
        })
      } catch (error) {
        console.error("Erreur lors du partage:", error)
      }
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-pink-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4" />
          <p className="text-muted-foreground">Chargement...</p>
        </div>
      </div>
    )
  }

  if (!sponsorshipCode) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-pink-50 flex items-center justify-center p-4">
        <Card className="max-w-md border-2">
          <CardContent className="p-8 text-center space-y-4">
            <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto">
              <Users className="w-8 h-8 text-purple-600" />
            </div>
            <h2 className="text-2xl font-bold">Complétez votre profil</h2>
            <p className="text-muted-foreground">
              Pour obtenir votre code parrainage et commencer à gagner des récompenses, veuillez compléter votre profil.
            </p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-pink-50 p-4 md:p-8">
      <div className="max-w-6xl mx-auto space-y-8">
        <div className="text-center space-y-4">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-purple-100 rounded-full text-purple-800 text-sm font-medium">
            <Sparkles className="w-4 h-4" />
            Programme de Parrainage
          </div>
          <h1 className="text-4xl md:text-5xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
            Parrainez & Gagnez
          </h1>
          <p className="text-muted-foreground max-w-2xl mx-auto">
            Invitez vos amis à rejoindre Myreklam et gagnez des My's à chaque inscription réussie
          </p>
        </div>

        {/* Statistiques globales */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <Card className="border-2 border-green-200 bg-gradient-to-br from-green-50 to-emerald-50">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600 mb-1">Total My's gagnés</p>
                  <p className="text-3xl font-bold text-green-600">{totalMys}</p>
                </div>
                <div className="w-12 h-12 bg-green-200 rounded-full flex items-center justify-center">
                  <Award className="w-6 h-6 text-green-600" />
                </div>
              </div>
            </CardContent>
          </Card>
          <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-pink-50">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600 mb-1">My's via parrainage</p>
                  <p className="text-3xl font-bold text-purple-600">{totalMysFromParrainage}</p>
                  <p className="text-xs text-gray-500 mt-1">{affiliates.length} parrainage{affiliates.length > 1 ? 's' : ''}</p>
                </div>
                <div className="w-12 h-12 bg-purple-200 rounded-full flex items-center justify-center">
                  <TrendingUp className="w-6 h-6 text-purple-600" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card className="border-2 border-purple-200 bg-gradient-to-br from-purple-50 to-purple-100 hover:shadow-lg transition-shadow">
            <CardContent className="p-6 text-center space-y-2">
              <div className="w-12 h-12 bg-purple-200 rounded-full flex items-center justify-center mx-auto">
                <Users className="w-6 h-6 text-purple-600" />
              </div>
              <p className="font-semibold text-purple-900">Particulier parrainé</p>
              <p className="text-3xl font-bold text-purple-600">2 My's</p>
            </CardContent>
          </Card>
          <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-blue-100 hover:shadow-lg transition-shadow">
            <CardContent className="p-6 text-center space-y-2">
              <div className="w-12 h-12 bg-blue-200 rounded-full flex items-center justify-center mx-auto">
                <Gift className="w-6 h-6 text-blue-600" />
              </div>
              <p className="font-semibold text-blue-900">Entreprise gratuite</p>
              <p className="text-3xl font-bold text-blue-600">2 My's</p>
            </CardContent>
          </Card>
          <Card className="border-2 border-amber-200 bg-gradient-to-br from-amber-50 to-amber-100 hover:shadow-lg transition-shadow">
            <CardContent className="p-6 text-center space-y-2">
              <div className="w-12 h-12 bg-amber-200 rounded-full flex items-center justify-center mx-auto">
                <Sparkles className="w-6 h-6 text-amber-600" />
              </div>
              <p className="font-semibold text-amber-900">Entreprise premium</p>
              <p className="text-3xl font-bold text-amber-600">5 My's</p>
            </CardContent>
          </Card>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card className="border-2 hover:border-purple-300 transition-colors">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Share2 className="w-5 h-5 text-purple-600" />
                Votre Code de Parrainage
              </CardTitle>
            </CardHeader>
            <CardContent>
              <SponsorshipCode
                code={sponsorshipCode}
                onCopy={() => {
                  sponsorshipCode && handleCopy(sponsorshipCode)
                }}
              />
            </CardContent>
          </Card>

          <Card className="border-2 hover:border-purple-300 transition-colors">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Share2 className="w-5 h-5 text-purple-600" />
                Votre Lien de Parrainage
              </CardTitle>
            </CardHeader>
            <CardContent>
              <SponsorshipLink
                link={sponsorshipLink}
                onCopy={() => {
                  sponsorshipLink && handleCopy(sponsorshipLink)
                }}
                onShare={handleShare}
                sharingMessage={sharingMessage}
              />
            </CardContent>
          </Card>
        </div>

        <Card className="border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-cyan-50">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Share2 className="w-5 h-5 text-blue-600" />
              Message de Partage
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="p-4 bg-white rounded-lg border-2 border-blue-100">
              <p className="text-sm text-gray-700 leading-relaxed">{sharingMessage}</p>
            </div>
            <Button
              onClick={() => handleCopy(sharingMessage)}
              className="w-full bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600"
            >
              {copied ? (
                <>
                  <Check className="w-4 h-4 mr-2" />
                  Copié !
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4 mr-2" />
                  Copier le Message
                </>
              )}
            </Button>
          </CardContent>
        </Card>

        <Card className="border-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5 text-purple-600" />
              Historique de Parrainage
            </CardTitle>
          </CardHeader>
          <CardContent>
            <SponsorshipHistory />
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
