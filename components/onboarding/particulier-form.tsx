"use client"

import type React from "react"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card } from "@/components/ui/card"
import { createUserInfo } from "@/lib/api"
import { toast } from "sonner"
import { Upload, User } from "lucide-react"
import Image from "next/image"
import { useAuthStore } from "@/lib/auth-store"

interface ParticulierFormProps {
  onComplete: () => void
}

export default function ParticulierForm({ onComplete }: ParticulierFormProps) {
  const [formData, setFormData] = useState({
    pseudo: "",
    tel: "+33",
  })
  const [isSubmitting, setIsSubmitting] = useState(false)
  const { setUser, fetchUserInfo } = useAuthStore()

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!formData.pseudo) {
      toast.error("Veuillez remplir tous les champs obligatoires.")
      return
    }

    setIsSubmitting(true)

    try {
      const payload: any = {
        userid: localStorage.getItem("profileId") || "",
        profiletype: "particulier",
        pseudo: formData.pseudo,
        telephone: formData.tel,
        Method: "create",
      }

      console.log("[v0] Submitting particulier form:", payload)
      const response = await createUserInfo(payload)

      if (response.status === "success") {
        localStorage.setItem("profiletype", "particulier")
        // Mettre à jour l'état d'authentification
        const profileId = localStorage.getItem("profileId")
        if (profileId) {
          setUser(profileId)
          await fetchUserInfo()
        }
        
        toast.success("Informations enregistrées avec succès.")
        
        // Appeler onComplete qui va vérifier l'email puis rediriger
        onComplete()
      } else {
        toast.error(response.message || "Erreur lors de l'enregistrement")
      }
    } catch (error) {
      console.error("[v0] Error submitting form:", error)
      toast.error("Une erreur est survenue")
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-primary/5 p-4">
      <Card className="max-w-2xl w-full p-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Complétez votre profil</h1>
          <p className="text-muted-foreground">Quelques informations pour personnaliser votre expérience</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <Label htmlFor="pseudo">Pseudo *</Label>
            <Input
              id="pseudo"
              name="pseudo"
              value={formData.pseudo}
              onChange={handleChange}
              placeholder="Votre pseudo"
              required
            />
          </div>

            <div>
            <Label htmlFor="tel">Numéro de téléphone (recommandé)</Label>
            <Input
              id="tel"
              name="tel"
              type="tel"
              value={formData.tel}
              onChange={(e) => {
              const value = e.target.value;
              let filteredValue = "";
              
              // Only allow + at the beginning
              if (value.startsWith("+")) {
                filteredValue = "+";
                // Only allow digits after +
                const digits = value.slice(1).replace(/\D/g, "");
                
                // If starts with +33, max 12 characters total (including +33)
                if (value.startsWith("+33")) {
                filteredValue = "+33" + digits.slice(2, 11); // +33 + 9 digits max
                } else {
                // Other international formats, limit to reasonable length
                filteredValue = "+" + digits.slice(0, 11);
                }
              } else {
                // No +, only digits, max 10 characters
                filteredValue = value.replace(/\D/g, "").slice(0, 10);
              }
              
              setFormData((prev) => ({ ...prev, tel: filteredValue }));
              }}
              placeholder="+33 6 12 34 56 78"
            />
            </div>

          <Button type="submit" size="lg" className="w-full" disabled={isSubmitting}>
            {isSubmitting ? "Enregistrement..." : "Continuer"}
          </Button>
        </form>
      </Card>
    </div>
  )
}
