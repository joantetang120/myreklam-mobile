"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { motion } from "framer-motion"
import Link from "next/link"
import { ArrowLeft, ArrowRight, Check, Briefcase, FileText, User, ImageIcon, Link2, Loader2, Edit2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input as InputComponents } from "@/components/ui/input-select"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { useToast } from "@/hooks/use-toast"
import { useUserData } from "@/hooks/use-user-data"
import { getScraping } from "@/lib/api/scraping"
import {
  contractTypes,
  occupationTimeOptions,
  studyLevels,
  experienceLevels,
  jobBenefits,
} from "@/lib/constants/job-data-source"
import { getCategoriesByType, type Category } from "@/lib/api/categories"
import { labelObject } from "@/lib/constants/label-object"
import citiesData from "@/lib/data/france-cities.json"
import { InputDescription } from "@/components/ui/input-description"
import { config } from "@/lib/config"
import { MysCongratsModal } from "@/components/modals/mys-congrats-modal"

const STEPS = [
  { id: 1, name: "Catégorie", icon: Briefcase },
  { id: 2, name: "France Travail", icon: Link2 },
  { id: 3, name: "Description", icon: FileText },
  { id: 4, name: "Profil", icon: User },
  { id: 5, name: "Photos", icon: ImageIcon },
  { id: 6, name: "Résumé", icon: Check },
]

export default function CreateJobPage() {
  const router = useRouter()
  const { toast } = useToast()
  const { companyData: userData, loading: userDataLoading } = useUserData()
  const searchParams = useSearchParams()
  const [currentStep, setCurrentStep] = useState(1)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [images, setImages] = useState<File[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [documentsFiles, setDocumentsFiles] = useState<File[]>([])
  const [existingImages, setExistingImages] = useState<Array<{ id: string; url: string }>>([])
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([])
  const [isScrapingLoading, setIsScrapingLoading] = useState(false)
  const [scrapingMessage, setScrapingMessage] = useState({ success: false, message: "" })
  const [websiteUrl, setWebsiteUrl] = useState("")
  const [id, setId] = useState<string | null>(null)
  const [isEditMode, setIsEditMode] = useState(false)
  const [loading, setLoading] = useState(false)
  const [mysCongratsModalOpen, setMysCongratsModalOpen] = useState<boolean>(false)

  const [formData, setFormData] = useState({
    activity: "",
    jobFunction: "",
    title: "",
    description: "",
    contractType: "",
    occupationTime: "",
    salaryType: "range", // "range", "exact", "profile"
    minSalary: "",
    maxSalary: "",
    netSalary: "raw",
    unitSalary: "month",
    studyLevel: "",
    xpLevel: "",
    remote: false,
    address: {} as any,
    showAddress: false,
    business: "" as string,
    showpresentation: false,
    website: "",
    availabilityType: "immediate", // "immediate", "from"
    startDate: "",
    endDate: "",
    benefits: [] as string[],
    descriptionprofil: "", 
    acceptMessages: false, // Added for the new update
  })

  const [selectedCity, setSelectedCity] = useState("")
  const [categories, setCategories] = useState<Category[]>([])
  const [subCategories, setSubCategories] = useState<Category[]>([])
  const [categoriesLoading, setCategoriesLoading] = useState(true)

  // Charger les catégories depuis l'API
  useEffect(() => {
    const loadCategories = async () => {
      try {
        setCategoriesLoading(true)
        const response = await getCategoriesByType("offres_emploi")
        if (response && response.data) {
          const mainCategories = response.data.main || []
          setCategories(mainCategories)
        }
      } catch (error) {
        console.error("[v0] Error loading job categories:", error)
      } finally {
        setCategoriesLoading(false)
      }
    }
    loadCategories()
  }, [])

  // Charger les sous-catégories quand une catégorie est sélectionnée
  useEffect(() => {
    const loadSubCategories = async () => {
      if (!formData.activity) {
        setSubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("offres_emploi")
        if (response && response.data) {
          // Trouver la catégorie principale sélectionnée
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === formData.activity || cat.id === formData.activity
          )

          if (selectedCategory) {
            // Récupérer les sous-catégories pour cette catégorie principale
            const subs = response.data.subs[selectedCategory.id] || []
            setSubCategories(subs)
          } else {
            setSubCategories([])
          }
        }
      } catch (error) {
        console.error("[v0] Error loading job subcategories:", error)
        setSubCategories([])
      }
    }
    loadSubCategories()
  }, [formData.activity])

  useEffect(() => {
    const announcementId = searchParams.get("id")

    if (announcementId) {
      setId(announcementId)
      setIsEditMode(true)
      fetchAnnouncement(announcementId)
    }
  }, [searchParams])

  const fetchAnnouncement = async (announcementId: string) => {
    try {
      setLoading(true)
      // Import fetchAnnouncementDetail and fetchDealImages from lib/api/deals
      const { fetchAnnouncementDetail, fetchDealImages } = await import("@/lib/api/deals")
      const announcement = await fetchAnnouncementDetail(announcementId)

      if (announcement) {
        // Pre-fill form data with announcement data
        setFormData({
          activity: announcement.activity || "",
          jobFunction: announcement.jobFunction || "",
          title: announcement.title || "",
          description: announcement.description || "",
          contractType: announcement.contractType || "",
          occupationTime: announcement.occupationTime || "",
          salaryType: announcement.salaryType || "range",
          minSalary: announcement.minSalary || "",
          maxSalary: announcement.maxSalary || "",
          netSalary: announcement.netSalary || "raw",
          unitSalary: announcement.unitSalary || "month",
          studyLevel: announcement.studyLevel || "",
          xpLevel: announcement.xpLevel || "",
          remote: announcement.remote || false,
          address: announcement.address
            ? typeof announcement.address === "string"
              ? JSON.parse(announcement.address)
              : announcement.address
            : {},
          showAddress: announcement.showAddress || false,
          website: announcement.website || "",
          availabilityType: announcement.startDate ? "from" : "immediate",
          startDate: announcement.startDate || "",
          endDate: announcement.endDate || "",
          benefits: announcement.benefits || [],
          acceptMessages: announcement.acceptMessages || false,
        })

        // Fetch and set images if they exist
        const imagesData = await fetchDealImages(announcementId)
        if (imagesData.success) {
          const records = (imagesData.records as Array<{ id: string; url: string }>) || []
          setExistingImages(records.filter((record) => record.id && record.url))
          const { config } = await import("@/lib/config")
          setPreviewUrls(records.map((record) => {
            const url = record.url
            if (url.startsWith("http://") || url.startsWith("https://")) {
              return url
            }
            const normalizedPath = url.startsWith("/") ? url : `/${url}`
            const patchedPath = normalizedPath.replace("/ads/", "/annonces/")
            return `${config.API_URL}${patchedPath}`
          }))
          setImagesToDelete([])
        } else {
          setExistingImages([])
        }
      }
    } catch (error) {
      console.error("[v0] Error fetching announcement:", error)
      toast({
        title: "Erreur",
        description: "Impossible de charger l'annonce",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  const handleRemoveExistingImage = (imageId: string) => {
    if (!imageId) return
    setExistingImages((prev) => prev.filter((image) => image.id !== imageId))
    setPreviewUrls((prev) => prev.filter((_, index) => existingImages[index]?.id !== imageId))
    setImagesToDelete((prev) => (prev.includes(imageId) ? prev : [...prev, imageId]))
  }

  const deleteAnnonceImages = async (imageIds: string[], annonceId: string) => {
    const ids = imageIds.filter(Boolean)
    if (ids.length === 0) return

    try {
      await Promise.all(
        ids.map((imageId) => {
          const formBody = new URLSearchParams()
          formBody.append("Id", imageId)
          formBody.append("Method", "delete")

          return axios.post(`${config.API_URL}/ImageAnnonce.php`, formBody, {
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
            },
          })
        }),
      )
      console.log(`[v0] Deleted ${ids.length} image(s) for annonce ${annonceId}`)
    } catch (error) {
      console.error("[v0] Error deleting images:", error)
      toast({
        title: "Attention",
        description: "Certaines images n'ont pas pu être supprimées",
        variant: "destructive",
      })
    }
  }

  const handleScraping = async () => {
    if (!websiteUrl) {
      setScrapingMessage({ success: false, message: "Veuillez entrer un lien" })
      return
    }

    const isValidUrl = (url: string) => {
      try {
        new URL(url)
        return true
      } catch (err) {
        return false
      }
    }

    if (!isValidUrl(websiteUrl)) {
      setScrapingMessage({ success: false, message: "Le lien n'est pas valide" })
      return
    }

    setIsScrapingLoading(true)
    try {
      const { success, scraping } = await getScraping(websiteUrl)

      if (success) {
        setFormData({
          ...formData,
          website: websiteUrl,
          title: scraping.title || formData.title,
          description: scraping.description || formData.description,
        })
        setCurrentStep(currentStep + 1)
        setScrapingMessage({
          success: true,
          message: "Récupération des informations réussie",
        })
      } else {
        setScrapingMessage({
          success: false,
          message: "Récupération des informations impossible",
        })
      }
    } catch (error) {
      console.error("[v0] Erreur lors du scraping:", error)
      setScrapingMessage({
        success: false,
        message: "Erreur lors de la récupération des informations",
      })
    } finally {
      setIsScrapingLoading(false)
    }
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)
      setImages((prev) => [...prev, ...files])

      const urls = files.map((file) => URL.createObjectURL(file))
      setPreviewUrls((prev) => [...prev, ...urls])
    }
  }

  const handleNext = () => {
    if (currentStep < STEPS.length) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1)
    }
  }

  const handleSubmit = async () => {
    setIsSubmitting(true)
    
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
    const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

    if (!userId) {
      toast({
        title: "Erreur",
        description: "Vous devez être connecté pour publier une annonce.",
        variant: "destructive",
      })
      setIsSubmitting(false)
      return
    }
    try {
      // Simulate API call
      // await new Promise((resolve) => setTimeout(resolve, 2000))

      // toast({
      //   title: isEditMode ? "Offre modifiée !" : "Offre publiée !",
      //   description: isEditMode
      //     ? "Votre offre d'emploi a été modifiée avec succès."
      //     : "Votre offre d'emploi a été publiée avec succès.",
      // })
       // Import des utilitaires nécessaires
      const { config } = await import("@/lib/config")
      const axios = (await import("axios")).default

      // Préparer les données de l'annonce
      const announcementData = {
        userId,
        category: "emplois",
        title: formData.title,
        description: formData.description,
        activity: formData.activity,
        jobFunction: formData.jobFunction,
        contractType: formData.contractType,
        occupationTime: formData.occupationTime,
        salaryType: formData.salaryType,
        minSalary: formData.minSalary,
        maxSalary: formData.maxSalary,
        netSalary: formData.netSalary,
        unitSalary: formData.unitSalary,
        studyLevel: formData.studyLevel,
        xpLevel: formData.xpLevel,
        remote: formData.remote,
        address: JSON.stringify(formData.address),
        showAddress: formData.showAddress,
        // business: formData.business,
        // Convertir business en tableau si c'est une chaîne
        business: Array.isArray(formData.business) 
          ? JSON.stringify(formData.business) 
          : JSON.stringify(formData.business ? [formData.business] : []),
        showpresentation: formData.showpresentation,
        website: formData.website,
        startDate: formData.availabilityType === "from" ? formData.startDate : "",
        endDate: formData.endDate,
        benefits: JSON.stringify(formData.benefits),
        descriptionprofil: formData.descriptionprofil,
        acceptMessages: formData.acceptMessages,
        Method: isEditMode ? "update" : "create",
      }

      // Si c'est une modification, ajouter l'ID
      if (isEditMode && id) {
        announcementData.id = id
      }

      // Créer l'annonce
      const response = await axios.post(`${config.API_URL}/Ads.php`, announcementData, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      })

      console.log("[v0] Response:", response.data)

      if (response.data.status === "success") {
        const annonceId = isEditMode && id ? id : response.data.id
        console.log("[v0] Job created/updated with ID:", annonceId)

        // Upload des images si elles existent
        if (images.length > 0) {
          try {
            console.log("[v0] Uploading", images.length, "images for job...")
            
            const imageFormData = new FormData()
            imageFormData.append("annonceId", annonceId)
            imageFormData.append("Method", "create")
            
            images.forEach((image) => {
              imageFormData.append("media[]", image)
            })

            const imageResponse = await axios.post(`${config.API_URL}/ImageAnnonce.php`, imageFormData, {
              headers: { "Content-Type": "multipart/form-data" },
            })
            
            console.log("[v0] Images uploaded successfully:", imageResponse.data)
          } catch (imageError) {
            console.error("[v0] Error uploading images:", imageError)
            toast({
              title: "Attention",
              description: "L'offre a été publiée mais il y a eu une erreur avec les images.",
              variant: "destructive",
            })
          }
        }

        // Upload des documents si ils existent
        if (documentsFiles.length > 0) {
          try {
            console.log("[v0] Uploading", documentsFiles.length, "documents for job...")
            
            const formDataDoc = new FormData()
            formDataDoc.append("annonceId", annonceId)
            formDataDoc.append("Method", "create_ads_file")
            formDataDoc.append("user_id", userId)
            formDataDoc.append("category", "emplois")

            documentsFiles.forEach((file: File, idx: number) => {
              formDataDoc.append(`documents[${idx}]`, file, file.name)
            })

            const docResponse = await axios.post(`${config.API_URL}/DocumentFiles.php`, formDataDoc, {
              headers: { "Content-Type": "multipart/form-data" },
            })
            
            console.log("[v0] Documents uploaded successfully:", docResponse.data)
          } catch (docError) {
            console.error("[v0] Error uploading documents:", docError)
            toast({
              title: "Attention",
              description: "L'offre a été publiée mais il y a eu une erreur avec les documents.",
              variant: "destructive",
            })
          }
        }

        // Supprimer les images marquées pour suppression
        if (imagesToDelete.length > 0 && id) {
          await deleteAnnonceImages(imagesToDelete, annonceId)
          setImagesToDelete([])
        }

        // Attribuer des coins pour la publication (seulement pour les nouvelles annonces)
        if (!id) {
          try {
            const coinsResponse = await axios.post(
              `${config.API_URL}/HistoryCoins.php`,
              {
                userId,
                valueCoin: 2,
                eventName: "publish_ad",
                description: "Coins added for: publish_ad",
                generateBy: "system_event",
                Method: "create_history_coin",
              },
              {
                headers: {
                  "Content-Type": "application/x-www-form-urlencoded",
                },
              }
            )
            
            if (coinsResponse.data.status === "success") {
              console.log("[v0] Coins awarded successfully:", 2)
              toast({
                title: "My's gagnés !",
                description: "Vous avez gagné 2 my's pour la publication de votre annonce !",
                variant: "default",
              })
            }
          } catch (coinError) {
            console.error("[v0] Error awarding coins:", coinError)
          }
        }

        // Afficher le message de succès
        toast({
          title: isEditMode ? "Offre modifiée !" : "Offre publiée !",
          description: isEditMode
            ? "Votre offre d'emploi a été modifiée avec succès."
            : "Votre offre d'emploi a été publiée avec succès.",
        })

        // Redirection ou modal
        if (!id) {
          setMysCongratsModalOpen(true)
          // Déclencher l'événement pour rafraîchir les limites d'annonces
          window.dispatchEvent(new Event('adCreated'))
        } else {
          setTimeout(() => {
            router.push("/offres-emploi")
          }, 1500)
        }
      } else {
        // Si le status n'est pas "success", afficher l'erreur
        console.error("[v0] API returned non-success status:", response.data)
        toast({
          title: "Erreur",
          description: response.data.message || "Une erreur est survenue lors de la publication.",
          variant: "destructive",
        })
      }
    } catch (error) {
      console.error("[v0] Error in handleSubmit:", error)
      toast({
        title: "Erreur",
        description: isEditMode
          ? "Une erreur est survenue lors de la modification."
          : "Une erreur est survenue lors de la publication.",
        variant: "destructive",
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  // Utiliser les sous-catégories depuis la base de données
  const availableJobFunctions = subCategories

  // Display loading state if fetching announcement data
  if (loading || userDataLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-yellow-50 via-white to-orange-50">
        <Loader2 className="w-10 h-10 text-yellow-600 animate-spin" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-yellow-50 via-white to-orange-50 py-8 px-4 mt-20">
      <MysCongratsModal
        isOpen={mysCongratsModalOpen}
        onClose={() => {
          setMysCongratsModalOpen(false)
          // Rediriger après la fermeture de la popup
          router.push("/offres-emploi")
        }}
        content={
          <>
            Vous avez gagné <span className="text-green-600 font-bold">2 my's</span> suite à votre publication d'offre d'emploi.
          </>
        }
      />
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="mb-8">
          <Link
            href="/announcements/create"
            className="inline-flex items-center text-yellow-600 hover:text-yellow-700 mb-4"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour aux catégories
          </Link>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            {isEditMode ? "Modifier une offre d'emploi" : "Créer une offre d'emploi"}
          </h1>
          <p className="text-gray-600">
            {isEditMode
              ? "Modifiez votre offre et mettez-la à jour"
              : "Publiez votre offre et trouvez les meilleurs talents"}
          </p>
        </motion.div>

        {/* Progress Steps */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            {STEPS.map((step, index) => (
              <div key={step.id} className="flex items-center flex-1">
                <div className="flex flex-col items-center flex-1">
                  <div
                    className={`w-12 h-12 rounded-full flex items-center justify-center border-2 transition-all ${
                      currentStep >= step.id
                        ? "bg-yellow-600 border-yellow-600 text-white"
                        : "bg-white border-gray-300 text-gray-400"
                    }`}
                  >
                    <step.icon className="w-6 h-6" />
                  </div>
                  <span
                    className={`mt-2 text-sm font-medium ${
                      currentStep >= step.id ? "text-yellow-600" : "text-gray-400"
                    }`}
                  >
                    {step.name}
                  </span>
                </div>
                {index < STEPS.length - 1 && (
                  <div
                    className={`h-1 flex-1 mx-2 rounded transition-all ${
                      currentStep > step.id ? "bg-yellow-600" : "bg-gray-200"
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Form Content */}
        <motion.div
          key={currentStep}
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -20 }}
          className="bg-white rounded-2xl shadow-xl p-8 mb-6"
        >
          {/* Step 1: Category */}
          {currentStep === 1 && (
            <div className="space-y-6">
              {categoriesLoading ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="w-6 h-6 animate-spin text-yellow-600" />
                </div>
              ) : (
                <>
                  <InputComponents.Select
                    label="Choisissez un secteur d'activité :"
                    name="activity"
                    onChange={(e) => setFormData({ ...formData, activity: e.target.value, jobFunction: "" })}
                    required
                    value={formData.activity || ""}
                    reviewing={false}
                  >
                    <option value="" disabled>
                      Sélectionnez un secteur d'activité
                    </option>
                    {categories.map((category) => (
                      <option key={category.id} value={category.code}>
                        {category.label}
                      </option>
                    ))}
                  </InputComponents.Select>

                  {formData.activity && (
                    <motion.div
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: "auto" }}
                      transition={{ duration: 0.3 }}
                    >
                      <InputComponents.Select
                        label="Choisissez une fonction :"
                        name="jobFunction"
                        onChange={(e) => setFormData({ ...formData, jobFunction: e.target.value })}
                        required
                        value={formData.jobFunction || ""}
                        reviewing={false}
                      >
                        <option value="" disabled>
                          {subCategories.length === 0 ? "Aucune sous-catégorie disponible" : "Sélectionnez une fonction"}
                        </option>
                        {availableJobFunctions.map((subCategory: Category) => (
                          <option key={subCategory.id} value={subCategory.code}>
                            {subCategory.label}
                          </option>
                        ))}
                      </InputComponents.Select>
                    </motion.div>
                  )}

                  {formData.activity && availableJobFunctions.length === 0 && (
                    <motion.div
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
                    >
                      <p className="text-sm text-yellow-800">
                        Aucune fonction disponible pour ce secteur d'activité. Vous pouvez continuer sans sélectionner de
                        fonction.
                      </p>
                    </motion.div>
                  )}
                </>
              )}
            </div>
          )}

          {currentStep === 2 && (
            <motion.div
              className="flex flex-col gap-6 py-8"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3 }}
            >
              <div className="text-center">
                <h3 className="text-xl font-semibold text-gray-900 mb-2">Lien de l'offre d'emploi</h3>
                <p className="text-gray-600">
                  Entrez le lien de la page où vous avez publié cette offre ou obtenir plus d'informations à son sujet.
                </p>
              </div>

              <div className="flex flex-col gap-4">
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
                    <Link2 className="w-5 h-5 text-gray-400" />
                  </div>
                  <input
                    type="url"
                    className="w-full pl-12 pr-4 py-4 border-2 border-gray-200 rounded-xl focus:border-yellow-500 focus:ring-4 focus:ring-yellow-100 transition-all text-gray-700"
                    placeholder="https://www.example.com/offres-emploi"
                    value={websiteUrl}
                    onChange={(e) => setWebsiteUrl(e.target.value)}
                  />
                </div>

                <Button
                  onClick={handleScraping}
                  disabled={isScrapingLoading}
                  className="w-full py-6 bg-gradient-to-r from-yellow-500 to-yellow-600 hover:from-yellow-600 hover:to-yellow-700 text-lg font-semibold"
                >
                  {isScrapingLoading ? (
                    <>
                      <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                      Récupération en cours...
                    </>
                  ) : (
                    "Continuer"
                  )}
                </Button>

                {scrapingMessage.message && (
                  <p
                    className={`text-sm text-center font-semibold ${scrapingMessage.success ? "text-green-600" : "text-red-600"}`}
                  >
                    {scrapingMessage.message}
                  </p>
                )}

                <button
                  type="button"
                  className="text-yellow-600 text-sm hover:underline self-center font-medium"
                  onClick={() => setCurrentStep(currentStep + 1)}
                >
                  Je n'ai pas de lien
                </button>
              </div>
            </motion.div>
          )}

          {currentStep === 3 && (
            <div className="space-y-6">
              <div>
                <Label htmlFor="title">Intitulé du poste *</Label>
                <Input
                  id="title"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  placeholder="Ex: Développeur Full Stack Senior"
                />
              </div>

              <InputDescription
                value={formData.description}
                onChange={(desc) => setFormData({ ...formData, description: desc })}
                label="Description du poste *"
                required
                placeholder="Décrivez le poste, les missions, l'environnement de travail..."
              />

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="contractType">Type de contrat *</Label>
                  <Select
                    value={formData.contractType}
                    onValueChange={(value) => setFormData({ ...formData, contractType: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Type de contrat" />
                    </SelectTrigger>
                    <SelectContent>
                      {contractTypes.map((type) => (
                        <SelectItem key={type} value={type}>
                          {(labelObject as any)[type] || type}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label htmlFor="occupationTime">Temps de travail *</Label>
                  <Select
                    value={formData.occupationTime}
                    onValueChange={(value) => setFormData({ ...formData, occupationTime: value })}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Temps plein/partiel" />
                    </SelectTrigger>
                    <SelectContent>
                      {occupationTimeOptions.map((option) => (
                        <SelectItem key={option} value={option}>
                          {(labelObject as any)[option] || option}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="space-y-4">
                <Label>Comment souhaitez-vous indiquer la rémunération ?</Label>
                <div className="flex flex-col gap-3">
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      id="salary-range"
                      name="salaryType"
                      checked={formData.salaryType === "range"}
                      onChange={() => setFormData({ ...formData, salaryType: "range", minSalary: "", maxSalary: "" })}
                      className="w-4 h-4 text-yellow-600 border-gray-300 focus:ring-yellow-500"
                    />
                    <Label htmlFor="salary-range" className="cursor-pointer font-normal">
                      Tranche salariale
                    </Label>
                  </div>
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      id="salary-exact"
                      name="salaryType"
                      checked={formData.salaryType === "exact"}
                      onChange={() => setFormData({ ...formData, salaryType: "exact", maxSalary: "" })}
                      className="w-4 h-4 text-yellow-600 border-gray-300 focus:ring-yellow-500"
                    />
                    <Label htmlFor="salary-exact" className="cursor-pointer font-normal">
                      Salaire exact
                    </Label>
                  </div>
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      id="salary-profile"
                      name="salaryType"
                      checked={formData.salaryType === "profile"}
                      onChange={() => setFormData({ ...formData, salaryType: "profile", minSalary: "", maxSalary: "" })}
                      className="w-4 h-4 text-yellow-600 border-gray-300 focus:ring-yellow-500"
                    />
                    <Label htmlFor="salary-profile" className="cursor-pointer font-normal">
                      Salaire selon le profil
                    </Label>
                  </div>
                </div>
              </div>

              {formData.salaryType !== "profile" && (
                <div className="grid grid-cols-2 gap-4">
                  {formData.salaryType === "range" && (
                    <>
                      <div>
                        <Label htmlFor="minSalary">Salaire minimum (€)</Label>
                        <Input
                          id="minSalary"
                          type="number"
                          value={formData.minSalary}
                          onChange={(e) => setFormData({ ...formData, minSalary: e.target.value })}
                          placeholder="Ex: 35000"
                        />
                      </div>
                      <div>
                        <Label htmlFor="maxSalary">Salaire maximum (€)</Label>
                        <Input
                          id="maxSalary"
                          type="number"
                          value={formData.maxSalary}
                          onChange={(e) => setFormData({ ...formData, maxSalary: e.target.value })}
                          placeholder="Ex: 45000"
                        />
                      </div>
                    </>
                  )}
                  {formData.salaryType === "exact" && (
                    <div className="col-span-2">
                      <Label htmlFor="minSalary">Salaire exact (€)</Label>
                      <Input
                        id="minSalary"
                        type="number"
                        value={formData.minSalary}
                        onChange={(e) => setFormData({ ...formData, minSalary: e.target.value })}
                        placeholder="Ex: 40000"
                      />
                    </div>
                  )}
                  
                   {/* Ajout des champs brut/net et indice temporel */}
                  <div className="flex justify-start gap-4 items-center">
                    <div className="flex-1">
                      <Select
                        value={formData.netSalary}
                        onValueChange={(value) => setFormData({ ...formData, netSalary: value })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Brut ou net" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="raw">Brut</SelectItem>
                          <SelectItem value="net">Net</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="flex-1">
                      <Label>Indice temporel</Label>
                      <Select
                        value={formData.unitSalary}
                        onValueChange={(value) => setFormData({ ...formData, unitSalary: value })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Indice temporel" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="monthly">{(labelObject as any)["monthly"] || "Mensuel"}</SelectItem>
                          <SelectItem value="yearly">{(labelObject as any)["yearly"] || "Annuel"}</SelectItem>
                          <SelectItem value="daily">{(labelObject as any)["daily"] || "Journalier"}</SelectItem>
                          <SelectItem value="hourly">{(labelObject as any)["hourly"] || "Horaire"}</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                </div>
              )}

              <div className="space-y-4">
                <Label>Offre à pourvoir :</Label>
                <div className="flex flex-col gap-3">
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      id="availability-immediate"
                      name="availabilityType"
                      checked={formData.availabilityType === "immediate"}
                      onChange={() => setFormData({ ...formData, availabilityType: "immediate", startDate: "" })}
                      className="w-4 h-4 text-yellow-600 border-gray-300 focus:ring-yellow-500"
                    />
                    <Label htmlFor="availability-immediate" className="cursor-pointer font-normal">
                      Immédiatement
                    </Label>
                  </div>
                  {formData.availabilityType === "immediate" && (
                    <div className="ml-6">
                      <Label htmlFor="endDate" className="text-sm">
                        Jusqu'au (optionnel)
                      </Label>
                      <Input
                        id="endDate"
                        type="date"
                        value={formData.endDate}
                        onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                        className="mt-1"
                      />
                    </div>
                  )}
                  <div className="flex items-center gap-2">
                    <input
                      type="radio"
                      id="availability-from"
                      name="availabilityType"
                      checked={formData.availabilityType === "from"}
                      onChange={() => setFormData({ ...formData, availabilityType: "from" })}
                      className="w-4 h-4 text-yellow-600 border-gray-300 focus:ring-yellow-500"
                    />
                    <Label htmlFor="availability-from" className="cursor-pointer font-normal">
                      A partir de
                    </Label>
                  </div>
                  {formData.availabilityType === "from" && (
                    <div className="ml-6 grid grid-cols-2 gap-4">
                      <div>
                        <Label htmlFor="startDate" className="text-sm">
                          Date de début
                        </Label>
                        <Input
                          id="startDate"
                          type="date"
                          value={formData.startDate}
                          onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                          className="mt-1"
                        />
                      </div>
                      <div>
                        <Label htmlFor="endDate" className="text-sm">
                          Jusqu'au (optionnel)
                        </Label>
                        <Input
                          id="endDate"
                          type="date"
                          value={formData.endDate}
                          onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                          min={formData.startDate}
                          className="mt-1"
                        />
                      </div>
                    </div>
                  )}
                </div>
              </div>

              <div className="space-y-4">
                <Label>Avantages :</Label>
                <div className="max-h-64 overflow-y-auto border rounded-lg p-4 space-y-2">
                  {jobBenefits.map((benefit) => (
                    <div key={benefit} className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        id={`benefit-${benefit}`}
                        checked={formData.benefits.includes(benefit)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setFormData({ ...formData, benefits: [...formData.benefits, benefit] })
                          } else {
                            setFormData({
                              ...formData,
                              benefits: formData.benefits.filter((b) => b !== benefit),
                            })
                          }
                        }}
                        className="w-4 h-4 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500"
                      />
                      <Label htmlFor={`benefit-${benefit}`} className="cursor-pointer font-normal">
                        {(labelObject as any)[benefit] || benefit}
                      </Label>
                    </div>
                  ))}
                </div>
              </div>
              
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="remote"
                  checked={formData.remote}
                  onChange={(e) => setFormData({ ...formData, remote: e.target.checked })}
                  className="w-4 h-4 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500"
                />
                <Label htmlFor="remote" className="cursor-pointer">
                  Télétravail possible
                </Label>
              </div>

              <div className="space-y-4">
                <InputComponents.Autocomplete
                  label="Lieu"
                  helperText="Précisez la ville/région où cette offre est valide"
                  address={formData.address}
                  setAddress={(address: any) => setFormData({ ...formData, address })}
                  extraClass="w-full"
                  cities={citiesData}
                  disabled={selectedCity === "France"}
                />
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="wholeFrance"
                    checked={selectedCity === "France"}
                    onChange={(e) => {
                      if (e.target.checked) {
                        setSelectedCity("France")
                        setFormData({
                          ...formData,
                          address: {
                            line1: "",
                            line2: "",
                            line3: "",
                            zipcode: "",
                            city: "",
                            country: "France",
                          },
                        })
                      } else {
                        setSelectedCity("")
                        setFormData({
                          ...formData,
                          address: {
                            line1: "",
                            line2: "",
                            line3: "",
                            zipcode: "",
                            city: "",
                            country: "",
                          },
                        })
                      }
                    }}
                    className="w-4 h-4 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500"
                  />
                  <Label htmlFor="wholeFrance" className="cursor-pointer">
                    Toute la France
                  </Label>
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="showAddress"
                    checked={formData.showAddress}
                    onChange={(e) => setFormData({ ...formData, showAddress: e.target.checked })}
                    className="w-4 h-4 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500"
                  />
                  <Label htmlFor="showAddress" className="cursor-pointer">
                    Afficher la localisation Google sur l'annonce
                  </Label>
                </div>
              </div>

                {/* Nom de l'entreprise */}
              <div>
                <Label htmlFor="business">Entreprise</Label>
                <Input
                  id="business"
                  type="text"
                  value={formData.business}
                  onChange={(e) => setFormData({ ...formData, business: e.target.value })}
                  placeholder="Ex: Tech Innovate, Samsung"
                />
              </div>

              {/* Option d'affichage de la présentation */}
              <div className="flex items-start gap-3 p-4 bg-blue-50 border-2 border-blue-200 rounded-lg">
                <input
                  type="checkbox"
                  id="showpresentation"
                  checked={formData.showpresentation}
                  onChange={(e) => {
                    console.log('présentation userdata', userData)
                    const isChecked = e.target.checked
                    if (isChecked && (!userData?.presentation || userData.presentation.trim() === "")) {
                      toast({
                        title: "Attention",
                        description: "Veuillez remplir la description de l'entreprise dans le tableau de bord avant de cocher cette case.",
                        variant: "destructive",
                      })
                      return
                    }
                    setFormData({ ...formData, showpresentation: isChecked })
                  }}
                  className="w-5 h-5 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500 mt-0.5"
                />
                <label htmlFor="showpresentation" className="flex-1 cursor-pointer">
                  <span className="font-semibold text-gray-900 block">
                    Afficher la présentation de mon entreprise (Qui sommes-nous ?) sur mon annonce depuis mon profil entreprise
                  </span>
                  <span className="text-sm text-gray-600 mt-1 block">
                    Cette option affichera automatiquement la description de votre entreprise configurée dans votre tableau de bord
                  </span>
                </label>
              </div>


              <div>
                <Label htmlFor="website">Site web de l'entreprise</Label>
                <Input
                  id="website"
                  type="url"
                  value={formData.website}
                  onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                  placeholder="https://www.example.com"
                />
              </div>
            </div>
          )}

          {currentStep === 4 && (
            <div className="space-y-6">
              <div>
                <Label htmlFor="studyLevel">Niveau d'études requis *</Label>
                <Select
                  value={formData.studyLevel}
                  onValueChange={(value) => setFormData({ ...formData, studyLevel: value })}
                >
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Niveau d'études" />
                  </SelectTrigger>
                  <SelectContent>
                    {studyLevels.map((level) => (
                      <SelectItem key={level} value={level}>
                        {(labelObject as any)[level] || level}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label htmlFor="xpLevel">Niveau d'expérience requis *</Label>
                <Select
                  value={formData.xpLevel}
                  onValueChange={(value) => setFormData({ ...formData, xpLevel: value })}
                >
                  <SelectTrigger className="h-12">
                    <SelectValue placeholder="Niveau d'expérience" />
                  </SelectTrigger>
                  <SelectContent>
                    {experienceLevels.map((level) => (
                      <SelectItem key={level} value={level}>
                        {(labelObject as any)[level] || level}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Description du profil recherché */}
              <div>
                <InputDescription
                  value={formData.descriptionprofil}
                  onChange={(desc) => setFormData({ ...formData, descriptionprofil: desc })}
                  label="Description du profil recherché :"
                  required={false}
                  placeholder="Décrivez le profil idéal pour ce poste : compétences techniques, qualités humaines, expériences spécifiques..."
                />
              </div>

              {/* Removed old date inputs as they are now handled in Step 2 */}
            </div>
          )}

          {currentStep === 5 && (
            <div className="space-y-6">
              <div>
                <Label htmlFor="images">Photos de l'entreprise ou du poste</Label>
                <div className="mt-2">
                  <label
                    htmlFor="images"
                    className="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100"
                  >
                    <div className="flex flex-col items-center justify-center pt-5 pb-6">
                      <ImageIcon className="w-10 h-10 mb-3 text-gray-400" />
                      <p className="mb-2 text-sm text-gray-500">
                        <span className="font-semibold">Cliquez pour ajouter</span> ou glissez-déposez
                      </p>
                      <p className="text-xs text-gray-500">PNG, JPG jusqu'à 10MB</p>
                    </div>
                    <input
                      id="images"
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={handleFileChange}
                      className="hidden"
                    />
                  </label>
                </div>
              </div>

              {existingImages.length > 0 && (
                <div className="mb-6">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-sm font-medium">Photos déjà publiées</h3>
                    <span className="text-xs text-gray-500">{existingImages.length} photo(s)</span>
                  </div>
                  <div className="grid grid-cols-3 gap-4">
                    {existingImages.map((image) => {
                      const getImageUrl = (url: string) => {
                        if (!url) return "/placeholder.svg"
                        if (url.startsWith("http://") || url.startsWith("https://")) {
                          return url
                        }
                        const normalizedPath = url.startsWith("/") ? url : `/${url}`
                        const patchedPath = normalizedPath.replace("/ads/", "/annonces/")
                        return `${config.API_URL}${patchedPath}`
                      }
                      return (
                        <div key={image.id} className="relative aspect-square">
                          <img
                            src={getImageUrl(image.url)}
                            alt="Image existante"
                            className="w-full h-full object-cover rounded-lg"
                          />
                          <button
                            onClick={() => handleRemoveExistingImage(image.id)}
                            className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M6 18L18 6M6 6l12 12"
                              />
                            </svg>
                          </button>
                        </div>
                      )
                    })}
                  </div>
                </div>
              )}

              {previewUrls.length > 0 && (
                <div>
                  <h3 className="text-sm font-medium mb-3">Nouvelles photos ajoutées</h3>
                  <div className="grid grid-cols-3 gap-4">
                    {previewUrls.map((url, index) => (
                      <div key={index} className="relative aspect-square">
                        <img
                          src={url || "/placeholder.svg"}
                          alt={`Preview ${index + 1}`}
                          className="w-full h-full object-cover rounded-lg"
                        />
                        <button
                          onClick={() => {
                            setImages(images.filter((_, i) => i !== index))
                            setPreviewUrls(previewUrls.filter((_, i) => i !== index))
                          }}
                          className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                        >
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M6 18L18 6M6 6l12 12"
                            />
                          </svg>
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {currentStep === 6 && (
            <div className="space-y-6">
              <div className="text-center mb-8">
                <div className="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Check className="w-8 h-8 text-yellow-600" />
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">Vérifiez votre offre</h3>
                <p className="text-gray-600">Relisez les informations avant de publier votre offre d'emploi</p>
              </div>

              {/* Informations générales */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0 }}
                className="bg-gray-50 rounded-xl p-6"
              >
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-semibold text-gray-900">Informations générales</h4>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setCurrentStep(1)}
                    className="text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50"
                  >
                    <Edit2 className="w-4 h-4 mr-2" />
                    Modifier
                  </Button>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Secteur</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {categories.find(cat => cat.code === formData.activity)?.label || formData.activity}
                    </span>
                  </div>
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Fonction</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {subCategories.find(sub => sub.code === formData.jobFunction)?.label || formData.jobFunction}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* Description */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="bg-gray-50 rounded-xl p-6"
              >
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-semibold text-gray-900">Description</h4>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setCurrentStep(3)}
                    className="text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50"
                  >
                    <Edit2 className="w-4 h-4 mr-2" />
                    Modifier
                  </Button>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Titre</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {formData.title}
                    </span>
                  </div>
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Description</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {formData.description?.substring(0, 100)}
                      {formData.description?.length > 100 && "..."}
                    </span>
                  </div>
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Type de contrat</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {(labelObject as any)[formData.contractType] || formData.contractType}
                    </span>
                  </div>
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Temps de travail</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {(labelObject as any)[formData.occupationTime] || formData.occupationTime}
                    </span>
                  </div>
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Rémunération</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {formData.salaryType === "profile"
                        ? "Salaire selon le profil"
                        : formData.salaryType === "exact"
                          ? `${formData.minSalary}€`
                          : formData.minSalary && formData.maxSalary
                            ? `${formData.minSalary}€ - ${formData.maxSalary}€`
                            : "Non spécifié"}
                    </span>
                  </div>
                   {/* Ajout de l'entreprise dans le résumé */}
                  {formData.business && (
                    <div className="flex justify-between items-start gap-4">
                      <span className="text-sm text-gray-600 font-medium flex-shrink-0">Entreprise</span>
                      <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                        {formData.business}
                      </span>
                    </div>
                  )}
                  {/* Affichage présentation */}
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Présentation entreprise</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {formData.showpresentation ? "Oui" : "Non"}
                    </span>
                  </div>

                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Disponibilité</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {formData.availabilityType === "immediate"
                        ? formData.endDate
                          ? `Immédiatement jusqu'au ${new Date(formData.endDate).toLocaleDateString()}`
                          : "Immédiatement"
                        : formData.startDate
                          ? `A partir du ${new Date(formData.startDate).toLocaleDateString()}${formData.endDate ? ` jusqu'au ${new Date(formData.endDate).toLocaleDateString()}` : ""}`
                          : "Non spécifié"}
                    </span>
                  </div>
                  {formData.benefits.length > 0 && (
                    <div className="flex justify-between items-start gap-4">
                      <span className="text-sm text-gray-600 font-medium flex-shrink-0">Avantages</span>
                      <div className="flex flex-wrap gap-2 justify-end flex-1">
                        {formData.benefits.map((benefit: string) => (
                          <span
                            key={benefit}
                            className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-full text-xs font-medium"
                          >
                            {(labelObject as any)[benefit] || benefit}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                  {formData.address?.country && (
                    <div className="flex justify-between items-start gap-4">
                      <span className="text-sm text-gray-600 font-medium flex-shrink-0">Localisation</span>
                      <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                        {formData.address.country === "France" && !formData.address.city
                          ? "Toute la France"
                          : `${formData.address.city || ""} ${formData.address.zipcode || ""}`}
                      </span>
                    </div>
                  )}
                  {formData.website && (
                    <div className="flex justify-between items-start gap-4">
                      <span className="text-sm text-gray-600 font-medium flex-shrink-0">Site web</span>
                      <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                        {formData.website}
                      </span>
                    </div>
                  )}
                </div>
              </motion.div>

              {/* Profil recherché */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="bg-gray-50 rounded-xl p-6"
              >
                <div className="flex items-center justify-between mb-4">
                  <h4 className="text-lg font-semibold text-gray-900">Profil recherché</h4>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setCurrentStep(4)}
                    className="text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50"
                  >
                    <Edit2 className="w-4 h-4 mr-2" />
                    Modifier
                  </Button>
                </div>
                <div className="space-y-3">
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Niveau d'études</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {(labelObject as any)[formData.studyLevel] || formData.studyLevel}
                    </span>
                  </div>
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Expérience</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {(labelObject as any)[formData.xpLevel] || formData.xpLevel}
                    </span>
                  </div>
                  {formData.descriptionprofil && (
                    <div className="flex justify-between items-start gap-4">
                      <span className="text-sm text-gray-600 font-medium flex-shrink-0">Description du profil</span>
                      <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                        {formData.descriptionprofil.replace(/<[^>]+>/g, "").substring(0, 100)}
                        {formData.descriptionprofil.replace(/<[^>]+>/g, "").length > 100 && "..."}
                      </span>
                    </div>
                  )}
                  <div className="flex justify-between items-start gap-4">
                    <span className="text-sm text-gray-600 font-medium flex-shrink-0">Télétravail</span>
                    <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                      {formData.remote ? "Oui" : "Non"}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* Photos */}
              {previewUrls.length > 0 && (
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.3 }}
                  className="bg-gray-50 rounded-xl p-6"
                >
                  <div className="flex items-center justify-between mb-4">
                    <h4 className="text-lg font-semibold text-gray-900">Aperçu des photos</h4>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setCurrentStep(5)}
                      className="text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50"
                    >
                      <Edit2 className="w-4 h-4 mr-2" />
                      Modifier
                    </Button>
                  </div>
                  <div className="grid grid-cols-3 md:grid-cols-4 gap-3">
                    {previewUrls.map((url, index) => (
                      <div key={index} className="relative rounded-lg overflow-hidden border-2 border-gray-200">
                        <img
                          src={url || "/placeholder.svg"}
                          alt={`Preview ${index + 1}`}
                          className="w-full h-24 object-cover"
                        />
                      </div>
                    ))}
                  </div>
                </motion.div>
              )}

              {/* Messages section */}
              <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-6">
                <div className="flex items-start gap-4">
                  <input
                    type="checkbox"
                    id="acceptMessages"
                    checked={formData.acceptMessages}
                    onChange={(e) => setFormData({ ...formData, acceptMessages: e.target.checked })}
                    className="w-5 h-5 text-yellow-600 border-gray-300 rounded focus:ring-yellow-500 mt-1"
                  />
                  <label htmlFor="acceptMessages" className="flex-1 cursor-pointer">
                    <span className="font-semibold text-gray-900 block mb-1">
                      Accepter de recevoir des messages concernant cette annonce
                    </span>
                    <span className="text-sm text-gray-600">
                      Les autres utilisateurs pourront vous contacter pour poser des questions sur cette offre d'emploi
                    </span>
                  </label>
                </div>
              </div>

              {/* Ready to publish */}
              <div className="bg-yellow-50 border-2 border-yellow-200 rounded-xl p-6 text-center">
                <p className="text-yellow-800 font-medium">Votre offre d'emploi est prête à être publiée !</p>
              </div>
            </div>
          )}
        </motion.div>

        {/* Navigation Buttons */}
        <div className="flex justify-between">
          <Button
            variant="outline"
            onClick={handlePrevious}
            disabled={currentStep === 1}
            className="flex items-center gap-2 bg-transparent"
          >
            <ArrowLeft className="w-4 h-4" />
            Précédent
          </Button>

          {currentStep < STEPS.length ? (
            <Button
              onClick={handleNext}
              disabled={
                (currentStep === 1 && (!formData.activity || !formData.jobFunction)) ||
                (currentStep === 3 &&
                  (!formData.title ||
                    !formData.description ||
                    !formData.contractType ||
                    !formData.occupationTime ||
                    (formData.salaryType !== "profile" && !formData.minSalary) ||
                    (formData.salaryType === "range" && !formData.maxSalary) ||
                    (formData.availabilityType === "from" && !formData.startDate))) ||
                (currentStep === 4 && (!formData.studyLevel || !formData.xpLevel))
              }
              className="flex items-center gap-2 bg-yellow-600 hover:bg-yellow-700"
            >
              Suivant
              <ArrowRight className="w-4 h-4" />
            </Button>
          ) : (
            <Button
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="flex items-center gap-2 bg-yellow-600 hover:bg-yellow-700"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                  {isEditMode ? "Modification..." : "Publication..."}
                </>
              ) : (
                <>
                  <Check className="w-4 h-4" />
                  {isEditMode ? "Modifier l'offre" : "Publier l'offre"}
                </>
              )}
            </Button>
          )}
        </div>
      </div>
    </div>
  )
}
