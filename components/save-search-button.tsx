"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { toast } from "sonner"
import { saveSearch } from "@/lib/saved-searches"

interface SaveSearchButtonProps {
  searchTerm?: string
  category?: string
  location?: string
  radius?: number
  searchAllFrance?: boolean
  useGeolocation?: boolean
  userPosition?: any
  currentUrl?: string
  className?: string
}

export function SaveSearchButton({ 
  searchTerm = "",
  category = "",
  location = "",
  radius = 10,
  searchAllFrance = false,
  useGeolocation = false,
  userPosition = null,
  currentUrl = "",
  className 
}: SaveSearchButtonProps) {
  const router = useRouter()
  const [open, setOpen] = useState(false)
  const [searchName, setSearchName] = useState("")
  const [notificationEnabled, setNotificationEnabled] = useState(true)
  const [loading, setLoading] = useState(false)

  const handleOpenDialog = () => {
    // Vérifier si l'utilisateur est connecté avant d'ouvrir le dialog
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
    if (!userId) {
      router.push("/login-required")
      return
    }
    setOpen(true)
  }

  const handleSaveSearch = async () => {
    const userId = localStorage.getItem("profileId")
    if (!userId) {
      router.push("/login-required")
      return
    }

    if (!searchName.trim()) {
      toast.error("Veuillez donner un nom à votre recherche")
      return
    }

    setLoading(true)

    // Extraire la ville et le code postal de la localisation
    let city = ""
    let postalCode = ""
    
    if (location && !searchAllFrance) {
      // Format: "Paris (75001)" ou juste "Paris"
      const match = location.match(/^(.+?)\s*\((\d{5})\)$/)
      if (match) {
        city = match[1].trim()
        postalCode = match[2]
      } else {
        city = location.trim()
      }
    }

    const result = await saveSearch({
      user_id: userId,
      name: searchName.trim(),
      search_term: searchTerm || "",
      category: category || "",
      city: searchAllFrance ? "" : city,
      postal_code: searchAllFrance ? "" : postalCode,
      distance: searchAllFrance ? 0 : radius,
      use_geolocation: useGeolocation || false,
      all_france: searchAllFrance || false,
      user_position: userPosition,
    })

    setLoading(false)

    if (result.success) {
      toast.success(result.message)
      setOpen(false)
      setSearchName("")
      setNotificationEnabled(true)
    } else {
      toast.error(result.error)
    }
  }

  return (
    <>
      <Button variant="outline" onClick={handleOpenDialog} className={className}>
        <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
          />
        </svg>
        Sauvegarder cette recherche
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Sauvegarder cette recherche</DialogTitle>
            <DialogDescription>
              Sauvegardez vos critères de recherche pour les retrouver facilement plus tard.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="search-name">Nom de la recherche *</Label>
              <Input
                id="search-name"
                placeholder="Ex: Offres d'emploi à Paris"
                value={searchName}
                onChange={(e) => setSearchName(e.target.value)}
              />
            </div>

            {/* Aperçu des critères */}
            <div className="rounded-lg bg-muted p-3 space-y-2">
              <p className="text-sm font-medium">Critères à sauvegarder :</p>
              <div className="text-sm text-muted-foreground space-y-1">
                {searchTerm && <p>• Terme: "{searchTerm}"</p>}
                {category && <p>• Catégorie: {category}</p>}
                {searchAllFrance ? (
                  <p>• Zone: Toute la France</p>
                ) : (
                  <>
                    {location && <p>• Lieu: {location}</p>}
                    {radius > 0 && <p>• Rayon: {radius} km</p>}
                  </>
                )}
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setOpen(false)}>
              Annuler
            </Button>
            <Button onClick={handleSaveSearch} disabled={loading || !searchName.trim()}>
              {loading ? "Sauvegarde..." : "Sauvegarder"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}