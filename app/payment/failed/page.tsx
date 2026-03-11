"use client"

import { useRouter } from "next/navigation"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { XCircle } from "lucide-react"

export default function FailedPage() {
  const router = useRouter()

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-accent/5 p-4">
      <Card className="max-w-md w-full p-8 text-center">
        <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-6">
          <XCircle className="w-12 h-12 text-red-600" />
        </div>
        <h1 className="text-3xl font-bold mb-4">Paiement annulé</h1>
        <p className="text-muted-foreground mb-8">
          Le processus de paiement a été annulé. Aucun montant n'a été débité de votre compte.
        </p>
        <div className="flex flex-col gap-3">
          <Button onClick={() => router.push("/subscription")} size="lg" className="w-full">
            Réessayer
          </Button>
          <Button onClick={() => router.push("/")} variant="outline" size="lg" className="w-full">
            Retour à l'accueil
          </Button>
        </div>
      </Card>
    </div>
  )
}
