"use client"

import { useState } from "react"
import Link from "next/link"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ChevronRight } from "lucide-react"
import labelObject from "@/lib/constants/label-object"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

interface PublisherCardProps {
  publisherName: string
  announcementTitle: string
  announcementType: "formation" | "emploi" | "bon-plan" | "demande"
  userId: string
  photoUrl?: string | null
  isProfessional: boolean
  activite?: string
  ville?: string
  pays?: string
  telephone?: string
  email?: string
  adresse?: string
  codePostal?: string
  facebook?: string
  instagram?: string
  linkedin?: string
  twitter?: string
  youtube?: string
  tiktok?: string
  hasPremiumSubscription?: boolean
  currentUserIsPro?: boolean
  publishadresse?: string | boolean
}

export function PublisherCard({
  publisherName,
  announcementTitle,
  announcementType,
  userId,
  photoUrl,
  isProfessional,
  activite,
  ville,
  pays,
  telephone,
  email,
  adresse,
  codePostal,
  facebook,
  instagram,
  linkedin,
  twitter,
  youtube,
  tiktok,
  hasPremiumSubscription = false,
  currentUserIsPro = false,
  publishadresse,
}: PublisherCardProps) {
  const [showSubscribeModal, setShowSubscribeModal] = useState(false)
  
  console.log("📞 PublisherCard - currentUserIsPro:", currentUserIsPro, "telephone:", telephone, "isProfessional:", isProfessional)

  const getBannerColor = () => {
    if (isProfessional) {
      return "from-blue-700 to-blue-600"
    }
    return "from-green-700 to-green-600"
  }

  const formatAddress = () => {
    const parts = [adresse, codePostal, ville, pays].filter(
      (v) => v && v !== "undefined" && v !== "null"
    )
    return parts.join(", ")
  }

  return (
    <>
      <Card className="p-0 shadow-sm overflow-hidden">
        {/* Bannière avec image */}
        <div className={`relative h-32 bg-gradient-to-r ${getBannerColor()} flex items-center justify-between px-6`}>
          <div className="flex-1">
            <p className="text-white text-lg font-bold mb-3">
              {publisherName}
            </p>
            <button
              onClick={() => setShowSubscribeModal(true)}
              className="mt-2 bg-white text-blue-700 px-4 py-1 rounded text-sm font-bold hover:bg-gray-100"
            >
              S'abonner
            </button>
          </div>
          <Avatar className="w-20 h-20 border-4 border-white">
            <AvatarImage src={photoUrl || undefined} alt={publisherName} />
            <AvatarFallback className="bg-white text-red-700 font-bold text-2xl">
              {publisherName.substring(0, 2).toUpperCase()}
            </AvatarFallback>
          </Avatar>
        </div>

        <div className="p-6">
          {/* Nom et badges */}
          <div className="flex items-center gap-2 mb-2">
            <h3 className="font-bold text-lg text-gray-900">{publisherName}</h3>
            {isProfessional ? (
              <Badge className="bg-blue-500 text-white text-xs">Pro</Badge>
            ) : (
              <Badge className="bg-green-500 text-white text-xs">Particulier</Badge>
            )}
            {hasPremiumSubscription && (
              <Badge className="bg-gradient-to-r from-yellow-400 to-orange-500 text-white text-xs font-bold">⭐ Premium</Badge>
            )}
          </div>

          {/* Informations en grille */}
          <div className="space-y-2 text-sm mb-4">
            {activite && activite !== "undefined" && (
              <div className="flex">
                <span className="text-gray-600 w-24">Secteur</span>
                <span className="text-gray-900">
                  {labelObject[activite as keyof typeof labelObject] || activite}
                </span>
              </div>
            )}

            {isProfessional && (ville || pays) && (
              <div className="flex">
                <span className="text-gray-600 w-24">Bureaux</span>
                <span className="text-gray-900">
                  {[ville, pays]
                    .filter((v) => v && v !== "undefined" && v !== "null")
                    .join(", ")}
                </span>
              </div>
            )}
          </div>

          {/* Lien découvrir */}
          <Link
            href={`/profil-public?Id=${userId}`}
            className="text-sm text-red-600 hover:text-red-700 font-medium flex items-center gap-1 mb-4"
          >
            Découvrir {publisherName}
            <ChevronRight className="w-4 h-4" />
          </Link>

          {/* Réseaux sociaux */}
          {(facebook || instagram || linkedin || twitter || youtube || tiktok) && (
            <div className="mt-4 pt-4 border-t border-gray-200">
              <h4 className="font-bold text-sm text-gray-900 mb-3">Réseaux sociaux :</h4>
              <div className="flex flex-wrap gap-2">
                {facebook && (
                  <a
                    href={facebook.startsWith('http') ? facebook : `https://facebook.com/${facebook}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-xs font-medium transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
                    </svg>
                    Facebook
                  </a>
                )}
                {instagram && (
                  <a
                    href={instagram.startsWith('http') ? instagram : `https://instagram.com/${instagram}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-3 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white rounded-md text-xs font-medium transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                    </svg>
                    Instagram
                  </a>
                )}
                {linkedin && (
                  <a
                    href={linkedin.startsWith('http') ? linkedin : `https://linkedin.com/in/${linkedin}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-3 py-2 bg-blue-700 hover:bg-blue-800 text-white rounded-md text-xs font-medium transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/>
                    </svg>
                    LinkedIn
                  </a>
                )}
                {twitter && (
                  <a
                    href={twitter.startsWith('http') ? twitter : `https://twitter.com/${twitter}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-3 py-2 bg-black hover:bg-gray-800 text-white rounded-md text-xs font-medium transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
                    </svg>
                    X (Twitter)
                  </a>
                )}
                {youtube && (
                  <a
                    href={youtube.startsWith('http') ? youtube : `https://youtube.com/@${youtube}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-3 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md text-xs font-medium transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
                    </svg>
                    YouTube
                  </a>
                )}
                {tiktok && (
                  <a
                    href={tiktok.startsWith('http') ? tiktok : `https://tiktok.com/@${tiktok}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 px-3 py-2 bg-black hover:bg-gray-800 text-white rounded-md text-xs font-medium transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
                    </svg>
                    TikTok
                  </a>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Section Contact - Visible uniquement pour les pros */}
        {currentUserIsPro && telephone && (
          <div className="px-6 pb-4">
            <h4 className="font-bold text-sm text-gray-900 mb-1">Téléphone :</h4>
            <a
              href={`tel:${telephone}`}
              className="text-sm text-blue-600 hover:text-blue-700 font-medium"
            >
              {telephone}
            </a>
          </div>
        )}
        
        {currentUserIsPro && email && (
          <div className="px-6 pb-4">
            <h4 className="font-bold text-sm text-gray-900 mb-1">Email :</h4>
            <a
              href={`mailto:${email}`}
              className="text-sm text-blue-600 hover:text-blue-700 font-medium"
            >
              {email}
            </a>
          </div>
        )}

        {/* Section Adresse - visible uniquement si publishadresse est autorisé */}
        {adresse && (publishadresse === "true" || publishadresse === true || publishadresse === "1") && (
          <div className="px-6 pb-6">
            <h4 className="font-bold text-sm text-gray-900 mb-1">Adresse :</h4>
            <p className="text-sm text-gray-700">{formatAddress()}</p>
          </div>
        )}
      </Card>

      {/* Modal d'abonnement */}
      <Dialog open={showSubscribeModal} onOpenChange={setShowSubscribeModal}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-2xl font-bold text-gray-900">
              Fonctionnalité à venir
            </DialogTitle>
            <DialogDescription className="text-gray-600">
              L'abonnement aux entreprises sera bientôt disponible !
            </DialogDescription>
          </DialogHeader>
          
          <div className="py-6 text-center">
            <div className="text-6xl mb-4">🔔</div>
            <p className="text-gray-700 mb-2">
              Vous pourrez bientôt vous abonner à{" "}
              <span className="font-bold">{publisherName}</span> pour recevoir des
              notifications sur leurs nouvelles annonces.
            </p>
            <p className="text-sm text-gray-500 mt-4">
              Cette fonctionnalité sera disponible très prochainement.
            </p>
          </div>

          <DialogFooter>
            <Button
              onClick={() => setShowSubscribeModal(false)}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white"
            >
              Compris !
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
