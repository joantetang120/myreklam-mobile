"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card } from "@/components/ui/card"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { createUserInfo, verifySiret, contactSupport } from "@/lib/api"
import { toast } from "sonner"
import { Loader2, Building2 } from "lucide-react"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import SubscriptionModal from "@/components/subscription/subscription-modal"
import { useAuthStore } from "@/lib/auth-store"

interface ProfessionnelFormProps {
  onComplete: () => void
}

const activities = {
  agriculture: "Agriculture",
  automotive: "Automobile",
  construction: "Construction",
  bankingFinanceInsurance: "Banque, Finance, Assurance",
  retailDistribution: "Distribution de détail",
  education: "Éducation",
  employmentTrainingStaffing: "Emploi, Formation, Recrutement",
  industrialEnvironmental: "Industrie et Environnement",
  informationCommunication: "Information et Communication",
  realEstate: "Immobilier",
  publicServicesGovernment: "Services publics et Gouvernement",
  healthcare: "Santé",
  generalServices: "Services généraux",
  telecommunicationsMedia: "Télécommunications et Médias",
  tourism: "Tourisme",
  transportationLogistics: "Transport et Logistique",
  hospitality: "Hôtellerie",
  fashionTextilesLuxuryGoods: "Mode, Textiles et Produits de luxe",
  sports: "Sports",
  personalCareServices: "Soins personnels et services",
}

export default function ProfessionnelForm({ onComplete }: ProfessionnelFormProps) {
  const router = useRouter()
  // Ajout de 'other' comme valeur possible pour l'activité
  type ActivityType = keyof typeof activities | 'other';

  const [formData, setFormData] = useState({
    siret: "",
    nomsociete: "",
    activity: "" as ActivityType,
    otherActivity: "", // Nouveau champ pour stocker l'activité personnalisée
    tel: "+33",
    address: {
      line1: "",
      city: "",
      zipcode: "",
      country: "FR",
    },
  })
  const [loadingSiret, setLoadingSiret] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [showContactPopup, setShowContactPopup] = useState(false)
  const [showSubscriptionModal, setShowSubscriptionModal] = useState(false)
  const [contactForm, setContactForm] = useState({
    name: "",
    email: "",
    message: "",
    kbisFile: null as File | null,
  })
  const [subscriptionCompleted, setSubscriptionCompleted] = useState(false)
  const { setUser, fetchUserInfo } = useAuthStore()

  const [isUploadingKbis, setIsUploadingKbis] = useState(false)

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    if (name.startsWith("address.")) {
      const addressField = name.split(".")[1]
      setFormData((prev) => ({
        ...prev,
        address: { ...prev.address, [addressField]: value },
      }))
    } else {
      setFormData((prev) => ({ ...prev, [name]: value }))
    }
  }

  const handleActivityChange = (value: string) => {
    // Vérifier si la valeur est 'other' ou une des clés d'activités existantes
    const activityKey = (value === 'other' || value in activities) 
      ? value as ActivityType 
      : 'other';
    
    setFormData(prev => ({
      ...prev,
      activity: activityKey
    }));
  }

  const handleKbisFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      if (file.type !== "application/pdf") {
        toast.error("Veuillez sélectionner un fichier PDF pour le KBIS.")
        return
      }
      if (file.size > 5 * 1024 * 1024) {
        toast.error("Le fichier KBIS ne doit pas dépasser 5 MB.")
        return
      }
      setContactForm((prev) => ({ ...prev, kbisFile: file }))
    }
  }

  const verifySiretNumber = async (siret: string) => {
    if (siret.length !== 14) return

    setLoadingSiret(true)
    try {
      console.log("[v0] Verifying SIRET:", siret)
      const response = await verifySiret({ Siret: siret, Method: "insee" })

      if (response.status === "success" && response.companyData) {
        const data = response.companyData
        // S'assurer que l'activité est un type valide
        const activityKey = Object.keys(activities).find(
          key => activities[key as keyof typeof activities] === data.activity
        ) as keyof typeof activities || 'other';
        
        setFormData(prev => ({
          ...prev,
          nomsociete: data.name,
          activity: activities[activityKey] ? activityKey : 'other',
          address: {
            ...prev.address,
            line1: `${data.address.numeroVoie} ${data.address.typeVoie} ${data.address.libelleVoie}`.trim(),
            city: data.address.commune,
            zipcode: data.address.codePostal,
            country: data.address.country || "FR",
          },
        }))
        toast.success("SIRET vérifié avec succès")
      } else {
        setShowContactPopup(true)
        toast.error("SIRET non trouvé dans la base de données")
      }
    } catch (error) {
      console.error("[v0] SIRET verification error:", error)
      setShowContactPopup(true)
      toast.error("Erreur lors de la vérification du SIRET")
    } finally {
      setLoadingSiret(false)
    }
  }

  useEffect(() => {
    if (formData.siret.length === 14) {
      verifySiretNumber(formData.siret)
    }
  }, [formData.siret])

  const handleContactSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!contactForm.name || !contactForm.email || !contactForm.message) {
      toast.error("Veuillez remplir tous les champs obligatoires.")
      return
    }

    setIsUploadingKbis(true)

    try {
      await contactSupport({
        ...contactForm,
        subject: "SIRET introuvable - Validation manuelle demandée",
        siret: formData.siret,
        companyName: formData.nomsociete,
        userId: localStorage.getItem("profileId"),
        requestType: "siret_validation",
      })

      setShowContactPopup(false)
      setContactForm({ name: "", email: "", message: "", kbisFile: null })
      toast.success("Votre demande a été envoyée. Nous vous contacterons rapidement.")
    } catch (error) {
      console.error("[v0] Contact support error:", error)
      toast.error("Erreur lors de l'envoi de votre demande")
    } finally {
      setIsUploadingKbis(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    // Validation de tous les champs obligatoires (sauf téléphone)
    if (!formData.siret || !formData.nomsociete || !formData.activity || 
        !formData.address.line1 || !formData.address.city || !formData.address.zipcode) {
      toast.error("Veuillez remplir tous les champs obligatoires marqués d'une astérisque (*).")
      return
    }

    // Validation spécifique pour "Autre" activité
    if (formData.activity === 'other' && !formData.otherActivity.trim()) {
      toast.error("Veuillez préciser votre secteur d'activité.")
      return
    }

    setIsSubmitting(true)

    try {
      const payload: any = {
        userid: localStorage.getItem("profileId") || "",
        profiletype: "professionnel",
        siret: formData.siret,
        nomsociete: formData.nomsociete,
        activite: formData.activity === 'other' ? formData.otherActivity : formData.activity,
        telephone: formData.tel,
        adresse: formData.address.line1,
        ville: formData.address.city,
        codepostal: formData.address.zipcode,
        pays: formData.address.country,
        Method: "create",
      }

      console.log("[v0] Submitting professionnel form:", payload)
      const response = await createUserInfo(payload)

      if (response.status === "success") {
        localStorage.setItem("profiletype", "professionnel")
        // Mettre à jour l'état d'authentification
        const profileId = localStorage.getItem("profileId")
        if (profileId) {
          setUser(profileId)
          await fetchUserInfo()
        }
        
        toast.success("Informations enregistrées avec succès.")
        setShowSubscriptionModal(true)
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
    <>
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background via-background to-accent/5 p-4">
        <Card className="max-w-3xl w-full p-8">
          <div className="mb-8 flex items-center gap-4">
            <div className="w-16 h-16 bg-accent/10 rounded-full flex items-center justify-center">
              <Building2 className="w-8 h-8 text-accent" />
            </div>
            <div>
              <h1 className="text-3xl font-bold">Informations professionnelles</h1>
              <p className="text-muted-foreground">Complétez les informations de votre entreprise</p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <Label htmlFor="siret">Numéro SIRET *</Label>
              <div className="relative">
                <Input
                  id="siret"
                  name="siret"
                  value={formData.siret}
                  onChange={handleChange}
                  placeholder="14 chiffres"
                  maxLength={14}
                  required
                />
                {loadingSiret && (
                  <Loader2 className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 animate-spin text-primary" />
                )}
              </div>
              <p className="text-sm text-muted-foreground mt-1">Les informations seront automatiquement remplies</p>
            </div>

            <div>
              <Label htmlFor="nomsociete">Nom de la société *</Label>
              <Input
                id="nomsociete"
                name="nomsociete"
                value={formData.nomsociete}
                onChange={handleChange}
                placeholder="Nom de votre entreprise"
                required
              />
            </div>

            <div>
              <Label htmlFor="activity">Secteur d'activité *</Label>
              <Select value={formData.activity} onValueChange={handleActivityChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Sélectionnez un secteur" />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(activities).map(([key, value]) => (
                    <SelectItem key={key} value={key}>
                      {value}
                    </SelectItem>
                  ))}
                  <SelectItem value="other">Autre (précisez)</SelectItem>
                </SelectContent>
              </Select>
              {formData.activity === 'other' && (
                <div className="mt-2">
                  <Input
                    value={formData.otherActivity || ''}
                    onChange={(e) => setFormData(prev => ({
                      ...prev,
                      otherActivity: e.target.value
                    }))}
                    placeholder="Veuillez préciser votre secteur d'activité"
                    required
                  />
                </div>
              )}
            </div>

            <div>
              <Label htmlFor="tel">Numéro de téléphone</Label>
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
              placeholder="+33 6 12 34 56 78 (optionnel)"
              />
            </div>

            <div className="space-y-4">
              <h3 className="font-semibold">Adresse</h3>
              <div>
                <Label htmlFor="address.line1">Adresse *</Label>
                <Input
                  id="address.line1"
                  name="address.line1"
                  value={formData.address.line1}
                  onChange={handleChange}
                  placeholder="Numéro et nom de rue"
                  required
                />
              </div>
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="address.zipcode">Code postal *</Label>
                  <Input
                    id="address.zipcode"
                    name="address.zipcode"
                    value={formData.address.zipcode}
                    onChange={handleChange}
                    placeholder="75001"
                    required
                  />
                </div>
                <div>
                  <Label htmlFor="address.city">Ville *</Label>
                  <Input
                    id="address.city"
                    name="address.city"
                    value={formData.address.city}
                    onChange={handleChange}
                    placeholder="Paris"
                    required
                  />
                </div>
              </div>
            </div>

            <Button type="submit" size="lg" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? "Enregistrement..." : "Valider mon profil"}
            </Button>
          </form>
        </Card>
      </div>

      <Dialog open={showContactPopup} onOpenChange={setShowContactPopup}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>SIRET non trouvé</DialogTitle>
            <DialogDescription>
              Nous n'avons pas pu vérifier votre SIRET automatiquement. Contactez notre support pour une validation
              manuelle.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleContactSubmit} className="space-y-4">
            <div>
              <Label htmlFor="contact-name">Nom *</Label>
              <Input
                id="contact-name"
                value={contactForm.name}
                onChange={(e) => setContactForm((prev) => ({ ...prev, name: e.target.value }))}
                required
              />
            </div>
            <div>
              <Label htmlFor="contact-email">Email *</Label>
              <Input
                id="contact-email"
                type="email"
                value={contactForm.email}
                onChange={(e) => setContactForm((prev) => ({ ...prev, email: e.target.value }))}
                required
              />
            </div>
            <div>
              <Label htmlFor="contact-message">Message *</Label>
              <Textarea
                id="contact-message"
                value={contactForm.message}
                onChange={(e) => setContactForm((prev) => ({ ...prev, message: e.target.value }))}
                placeholder="Décrivez votre situation..."
                rows={4}
                required
              />
            </div>
            <div>
              <Label htmlFor="kbis-upload">KBIS (PDF, max 5MB)</Label>
              <div className="flex items-center gap-2">
                <Input
                  id="kbis-upload"
                  type="file"
                  accept="application/pdf"
                  onChange={handleKbisFileChange}
                  className="flex-1"
                />
                {contactForm.kbisFile && <span className="text-sm text-green-600">✓ Fichier sélectionné</span>}
              </div>
            </div>
            <Button type="submit" className="w-full" disabled={isUploadingKbis}>
              {isUploadingKbis ? "Envoi en cours..." : "Envoyer la demande"}
            </Button>
          </form>
        </DialogContent>
      </Dialog>

      {/* <SubscriptionModal open={showSubscriptionModal} onOpenChange={setShowSubscriptionModal} /> */}
      <SubscriptionModal 
        open={showSubscriptionModal} 
        onOpenChange={(open) => {
          setShowSubscriptionModal(open)
          
          // Si le modal se ferme et qu'il était ouvert, déclencher la vérification de l'email
          if (!open && showSubscriptionModal) {
            toast.success("Configuration terminée !")
            
            // Mettre à jour l'état d'authentification avant de rediriger
            const profileId = localStorage.getItem("profileId")
            if (profileId) {
              setUser(profileId)
              fetchUserInfo().then(() => {
                // Appeler onComplete qui va vérifier l'email puis rediriger vers la page d'accueil
                onComplete()
              })
            } else {
              onComplete()
            }
          }
        }} 
      />
    </>
  )
}
