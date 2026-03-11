"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { User, Trash2 } from "lucide-react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { useUserData } from "@/hooks/use-user-data"
import { deleteAccount, getUserSubscriptions, getUserCoin } from "@/lib/api"
import { useToast } from "@/hooks/use-toast"

export function AccountSettings() {
  const { companyData, email, loading } = useUserData()
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [showProDeleteBlocked, setShowProDeleteBlocked] = useState(false)
  const [showMysCoinWarning, setShowMysCoinWarning] = useState(false)
  const [hasActiveSubscriptionState, setHasActiveSubscriptionState] = useState(false)
  const [userCoins, setUserCoins] = useState(0)
  const [subscriptions, setSubscriptions] = useState<any[]>([])
  const { toast } = useToast()
  const router = useRouter()

  console.log("[AccountSettings] Email received:", email)
  console.log("[AccountSettings] CompanyData:", companyData)

  useEffect(() => {
    const fetchData = async () => {
      if (companyData?.profiletype === "professionnel") {
        try {
          const userSubscriptions = await getUserSubscriptions(companyData.id || "")
          setSubscriptions(userSubscriptions)

          const active = userSubscriptions?.some(
            (sub: any) =>
              sub.typeabo &&
              sub.dateabo &&
              new Date(sub.dateabo).getTime() + (sub.typeabo === "annuel" ? 365 : 30) * 24 * 60 * 60 * 1000 >
                Date.now(),
          )
          setHasActiveSubscriptionState(active)

          const coins = await getUserCoin(companyData.localUserId || companyData.id || "")
          setUserCoins(coins || 0)
        } catch (error) {
          console.error("Erreur lors de la récupération des données:", error)
        }
      }
    }
    fetchData()
  }, [companyData])

  const performAccountDeletion = async () => {
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null

    if (!userId) {
      toast({
        title: "Erreur",
        description: "Nous n'avons pas pu supprimer votre compte.",
        variant: "destructive",
      })
      return
    }

    try {
      const result = await deleteAccount(userId)

      if (!result.success) {
        toast({
          title: "Erreur",
          description: "Nous n'avons pas pu supprimer votre compte.",
          variant: "destructive",
        })
        return
      }

      toast({
        title: "Succès",
        description: "Compte supprimé avec succès",
      })

      if (typeof window !== "undefined") {
        localStorage.removeItem("profileId")
        window.location.href = "/"
      }
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Nous n'avons pas pu supprimer votre compte.",
        variant: "destructive",
      })
      console.error("Erreur lors de la suppression du compte:", error)
    }
  }

  const handleDeleteAccount = async () => {
    if (companyData?.profiletype === "professionnel" && hasActiveSubscriptionState) {
      setShowProDeleteBlocked(true)
      return
    }

    if (userCoins > 0) {
      setShowMysCoinWarning(true)
      return
    }

    await performAccountDeletion()
  }

  if (loading) {
    return (
      <Card className="p-6">
        <div className="text-center">Chargement des informations du compte...</div>
      </Card>
    )
  }

  return (
    <>
      <Card className="p-6">
        <h3 className="text-xl font-semibold text-gray-700 mb-4 flex items-center gap-2">
          <User className="h-5 w-5" />
          Mon compte
        </h3>

        {companyData && (
          <div className="mb-8">
            <h4 className="text-lg font-medium text-gray-700 mb-4">Informations du compte</h4>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500">Email</p>
                <p className="text-gray-700">{email || "Non renseigné"}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Type de compte</p>
                <p className="text-gray-700">
                  {companyData.profiletype === "particulier" ? "Particulier" : "Professionnel"}
                </p>
              </div>
            </div>
          </div>
        )}

        <div className="border-t pt-6">
          <h4 className="text-lg font-medium text-gray-700 mb-4">Actions du compte</h4>

          <div className="space-y-4">
            {!showDeleteConfirm ? (
              <Button
                onClick={() => setShowDeleteConfirm(true)}
                variant="destructive"
                className="flex items-center gap-2"
              >
                <Trash2 size={18} />
                <span>Supprimer mon compte</span>
              </Button>
            ) : (
              <div className="bg-red-50 p-4 rounded-md border border-red-200">
                <h2 className="text-lg font-bold text-red-700 mb-2">Attention</h2>
                <p className="text-red-700 mb-3">
                  Êtes-vous sûr de vouloir supprimer votre compte ?<br />
                  Cette action est irréversible. Toutes vos annonces actives seront supprimées.
                </p>
                <div className="flex space-x-3">
                  <Button onClick={handleDeleteAccount} variant="destructive">
                    Confirmer la suppression
                  </Button>
                  <Button onClick={() => setShowDeleteConfirm(false)} variant="outline">
                    Annuler
                  </Button>
                </div>
              </div>
            )}
          </div>
        </div>
      </Card>

      <Dialog open={showProDeleteBlocked} onOpenChange={setShowProDeleteBlocked}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>🚫 Suppression du compte impossible</DialogTitle>
            <DialogDescription asChild>
              <div className="space-y-3">
                <p>Vous ne pouvez pas supprimer votre compte professionnel tant qu'un abonnement est actif.</p>

                <div className="bg-amber-50 p-3 rounded border border-amber-200">
                  <p className="text-amber-800 text-sm">
                    <span className="font-semibold">⚠️ Information importante :</span>
                    <br />
                    Lors de la suppression définitive, tous vos my's non utilisés seront perdus définitivement.
                    <br />
                    <span className="font-medium">Vous avez actuellement {userCoins} my's.</span>
                  </p>
                </div>

                {subscriptions.length > 0 && (
                  <div className="bg-gray-50 p-3 rounded text-sm">
                    <p className="font-medium text-gray-700 mb-2">Abonnement actuel :</p>
                    {(() => {
                      const sortedSubs = [...subscriptions].sort(
                        (a, b) => new Date(b.dateabo).getTime() - new Date(a.dateabo).getTime(),
                      )
                      const sub = sortedSubs[0]
                      const endDate = new Date(sub.dateabo)
                      if (sub.typeabo === "annuel") {
                        endDate.setFullYear(endDate.getFullYear() + 1)
                      } else if (sub.typeabo === "mensuel") {
                        endDate.setMonth(endDate.getMonth() + 1)
                      }
                      return (
                        <div className="text-gray-600">
                          <p>Type : {sub.typeabo}</p>
                          <p>Date de souscription : {new Date(sub.dateabo).toLocaleDateString("fr-FR")}</p>
                          <p>Expire le : {endDate.toLocaleDateString("fr-FR")}</p>
                        </div>
                      )
                    })()}
                  </div>
                )}
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              onClick={() => {
                setShowProDeleteBlocked(false)
                router.push("/dashboard/gerer-abonnement")
              }}
            >
              Gérer mon abonnement
            </Button>
            <Button variant="outline" onClick={() => setShowProDeleteBlocked(false)}>
              Fermer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={showMysCoinWarning} onOpenChange={setShowMysCoinWarning}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>⚠️ Perte de my's</DialogTitle>
            <DialogDescription asChild>
              <div className="space-y-3">
                <p>
                  Vous avez actuellement <span className="font-bold text-green-600">{userCoins} my's</span> sur votre
                  compte.
                </p>

                <div className="bg-red-50 p-3 rounded border border-red-200">
                  <p className="text-red-800 text-sm">
                    <span className="font-semibold">⚠️ Attention :</span>
                    <br />
                    La suppression de votre compte entraînera la perte définitive de tous vos my's non utilisés. Cette
                    action est irréversible.
                  </p>
                </div>

                <p className="text-sm">
                  Êtes-vous sûr de vouloir continuer et perdre définitivement vos {userCoins} my's ?
                </p>
              </div>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="flex-col sm:flex-row gap-2">
            <Button
              variant="destructive"
              onClick={() => {
                setShowMysCoinWarning(false)
                performAccountDeletion()
              }}
            >
              Oui, supprimer quand même
            </Button>
            <Button variant="outline" onClick={() => setShowMysCoinWarning(false)}>
              Annuler
            </Button>
            <Button
              onClick={() => {
                setShowMysCoinWarning(false)
                router.push("/dashboard/recompenses-ambassadeurs")
              }}
            >
              Utiliser mes my's
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}
