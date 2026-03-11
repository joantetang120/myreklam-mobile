"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import type { ReactElement } from "react"
import { motion } from "framer-motion"
import { ArrowLeft, Link2, Loader2, Upload, X, ImageIcon, Video, Check, Edit2 } from "lucide-react"
import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"
import axios from "axios"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input-select"
import { InputDescription } from "@/components/ui/input-description"
import { Stepper } from "@/components/ui/stepper"
import { MysCongratsModal } from "@/components/modals/mys-congrats-modal"
import { usePermissions } from "@/lib/hooks/use-permissions"
import { useProPlanModal } from "@/lib/hooks/use-pro-plan-modal"
import { useAdForm, AdFormProvider } from "@/lib/contexts/ad-form-context"
import { useUserData } from "@/hooks/use-user-data" // Updated import path
import { config } from "@/lib/config"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import {
  fetchAnnouncementDetail,
  fetchDealImages,
  uploadImages,
  createImageAnnouncementByUrlsAndAnnouncementId,
} from "@/lib/api/deals"
import { getScraping } from "@/lib/api/scraping"
import { getCategoriesByType, type Category } from "@/lib/api/categories"
import citiesData from "@/lib/data/france-cities.json"
import Image from "next/image"

const navLabels = {
  prev: "Précédent",
  next: "Suivant",
}

interface Profile {
  id: string
  name: string
  email: string
  phoneNumber: string
  address: string
  organization: string
}

const defaultValues = {
  title: "",
  description: "",
  eventSubCategory: "",
  eventType: "",
  reservationMode: "",
  eventFormat: "",
  address: {},
  program: {},
  showAddress: false,
  isOrganizator: true,
  eventDurationType: "onDay",
  nameOrganizator: "",
  otherOrganizator: false,
  price: 0,
  priceType: null,
  startTime: "",
  endTime: "",
  startDate: null,
  endDate: null,
  message: false,
  website: "",
  isOneDay: true,
  isSeveralDays: false,
  isAllDays: false,
  scrapping_images: [] as string[],
  media: [] as Array<{ type: "image" | "video"; url: string; file?: File }>,
}

const formateDateToYYYYMMDD = (date: any) => {
  if (!date) return null
  const d = new Date(date)
  return d.toISOString().split("T")[0]
}

const isValidWebsite = (website: string): boolean => {
  return true
}

const onChangeHandler = (setValues: any) => (evt: any) => {
  if (evt?.target?.multiple) {
    const selecteds: any[] = []
    evt.target.childNodes.forEach((t: any) => {
      if (t.selected) {
        selecteds.push(t.value)
      }
    })
    return setValues((values: any) => ({
      ...values,
      [evt?.target?.name]: selecteds,
    }))
  }
  setValues((values: any) => ({
    ...values,
    [evt?.target?.name]: evt?.target?.value,
  }))
}

function EventPage() {
  const { userData, loading: userLoading } = useUserData()
  const { checkAdPermission } = usePermissions()
  const { openProPlanModal } = useProPlanModal()

  const [mysCongratsModalOpen, setMysCongratsModalOpen] = useState<boolean>(false)
  const [values, setValues] = useState(defaultValues)
  const { adFormStep: step, setAdFormStep: setStep } = useAdForm()
  console.log("[v0] Current step:", step)

  const [loading, setLoading] = useState(false)
  const [id, setId] = useState<string | null>(null)
  const [isEditMode, setIsEditMode] = useState(false)
  const [medias, setMedias] = useState<File[]>([])
  const [images, setImages] = useState<File[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [documentsFiles, setDocumentsFiles] = useState<File[]>([])
  const [existingImages, setExistingImages] = useState<Array<{ id: string; url: string }>>([])
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [subCategoriesMap, setSubCategoriesMap] = useState<Record<number, Category[]>>({})
  const router = useRouter()
  const searchParams = useSearchParams()
  const stepperRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const announcementId = searchParams.get("id")
    if (announcementId) {
      setId(announcementId)
      setIsEditMode(true)
      fetchAnnouncement(announcementId)
    }
  }, [searchParams])

  const fetchAnnouncement = async (id: string) => {
    try {
      setLoading(true)
      const annonce = await fetchAnnouncementDetail(id)

      if (annonce) {
        setValues({
          ...defaultValues,
          ...annonce,
          title: annonce.title,
          description: annonce.description,
          eventType: annonce.eventType,
          address: annonce.address ? JSON.parse(annonce.address) : {},
          program: annonce.program,
          showAddress: annonce.showAddress,
          nameOrganizator: annonce.nameOrganizator,
          otherOrganizator: annonce.otherOrganizator,
          eventDurationType: annonce.eventDurationType,
          isOrganizator: annonce.isOrganizator,
          price: annonce.price,
          startTime: annonce.startTime,
          endTime: annonce.endTime,
          startDate: formateDateToYYYYMMDD(annonce.startDate),
          endDate: formateDateToYYYYMMDD(annonce.endDate),
          message: annonce.message,
          website: annonce.website,
          isOneDay: annonce.isOneDay,
          isSeveralDays: annonce.isSeveralDays,
          isAllDays: annonce.isAllDays,
          eventSubCategory: annonce.subCategory,
          reservationMode: annonce.modereservation,
          eventFormat: annonce.formatevent,
          media: annonce.media || [],
        })

        const imagesData = await fetchDealImages(id)
        if (imagesData.success) {
          const records = (imagesData.records as Array<{ id: string; url: string }>) || []
          setExistingImages(records.filter((record) => record.id && record.url))
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
    } finally {
      setLoading(false)
    }
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)
      setImages((prevImages) => [...prevImages, ...files])
      setMedias((prevMedias) => [...prevMedias, ...files])

      const urls = files.map((file) => URL.createObjectURL(file))
      setPreviewUrls((prevUrls) => [...prevUrls, ...urls])
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
      toastError("Certaines images n'ont pas pu être supprimées")
    }
  }

  const isNextStepDisabled = () => {
    if (step === 1) return !values?.eventType || !values?.eventSubCategory || !values?.eventFormat
    if (step === 2) return false
    if (step === 3) {
      let organisation = values.isOrganizator
      if (!values.isOrganizator) {
        if (values.nameOrganizator.length < 3) {
          return true
        }
        organisation = true
      }
      return !(values?.description && values?.title && values?.address && organisation)
    }
    if (step === 4) return !values?.startTime
    return false
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
    const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

    if (!userId) {
      toastError("Vous devez être connecté pour publier une annonce.")
      return
    }

    const adPermission = await checkAdPermission(userId)
    if (!adPermission.canCreateAd && profileType === "professionnel") {
      toastError(`Vous avez atteint votre limite d'annonces ce mois-ci. Passez au Premium pour publier en illimité !`)
      openProPlanModal()
      return
    }

    onSubmit()
  }

  const onSubmit = async () => {
    setLoading(true)

    if (!isValidWebsite(values?.website) && values?.website !== "") {
      toastError("Veuillez entrer une URL valide")
      setLoading(false)
      return
    }

    try {
      const userId = localStorage.getItem("profileId")
      const payload = {
        userId,
        title: values.title,
        description: values.description,
        eventType: values.eventType,
        address: values.address,
        program: values.program,
        showAddress: values.showAddress,
        nameOrganizator: values.nameOrganizator,
        otherOrganizator: values.otherOrganizator,
        eventDurationType: values.eventDurationType,
        isOrganizator: values.isOrganizator,
        price: values.price,
        priceType: values.priceType,
        endTime: values.endTime,
        startTime: values.startTime,
        startDate: values.startDate,
        endDate: values.endDate,
        message: values.message,
        website: values.website,
        isOneDay: values.isOneDay,
        isSeveralDays: values.isSeveralDays,
        isAllDays: values.isAllDays,
        category: "evenements",
        subCategory: values.eventSubCategory,
        modereservation: values.reservationMode,
        formatevent: values.eventFormat,
        ...(id ? { id, Method: "updateAnnonce" } : { Method: "create" }),
      }

      const response = await axios.post(`${config.API_URL}/Ads.php`, payload, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      })

      if (response.data.status === "success") {
        const annonceId = id ? id : response.data.id

        if (medias.length > 0) {
          const formData = new FormData()
          formData.append("annonceId", annonceId)
          formData.append("Method", "create")
          medias.forEach((file) => formData.append("media[]", file))

          await axios.post(`${config.API_URL}/ImageAnnonce.php`, formData, {
            headers: { "Content-Type": "multipart/form-data" },
          })
        }

        if (values.scrapping_images.length > 0) {
          const imagesUrlsUploaded = await uploadImages(values.scrapping_images)
          const urls = imagesUrlsUploaded.map((image) => image.url)
          await createImageAnnouncementByUrlsAndAnnouncementId(urls, annonceId)
        }

        // Handle media uploads
        if (values.media && values.media.length > 0) {
          const mediaFormData = new FormData()
          mediaFormData.append("annonceId", annonceId)
          mediaFormData.append("Method", "create")
          values.media.forEach((item) => {
            if (item.file) {
              mediaFormData.append("media[]", item.file)
            }
          })

          await axios.post(`${config.API_URL}/ImageAnnonce.php`, mediaFormData, {
            headers: { "Content-Type": "multipart/form-data" },
          })
        }

        // Upload des documents si ils existent
        if (documentsFiles.length > 0) {
          try {
            console.log("[v0] Uploading", documentsFiles.length, "documents for event...")
            
            const formDataDoc = new FormData()
            formDataDoc.append("annonceId", annonceId)
            formDataDoc.append("Method", "create_ads_file")
            formDataDoc.append("user_id", userId)
            formDataDoc.append("category", "evenements")

            documentsFiles.forEach((file: File, idx: number) => {
              formDataDoc.append(`documents[${idx}]`, file, file.name)
            })

            const docResponse = await axios.post(`${config.API_URL}/DocumentFiles.php`, formDataDoc, {
              headers: { "Content-Type": "multipart/form-data" },
            })
            
            console.log("[v0] Documents uploaded successfully:", docResponse.data)
          } catch (docError) {
            console.error("[v0] Error uploading documents:", docError)
            toastError("Erreur lors de l'upload des documents")
          }
        }

        // Supprimer les images marquées pour suppression
        if (imagesToDelete.length > 0 && id) {
          await deleteAnnonceImages(imagesToDelete, annonceId)
          setImagesToDelete([])
        }

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
              },
            )
            
            if (coinsResponse.data.status === "success") {
              console.log("[v0] Coins awarded successfully:", 2)
              toastSuccess(`Vous avez gagné 2 my's pour la publication de votre annonce !`)
            }
          } catch (coinError) {
            console.error("[v0] Error awarding coins:", coinError)
          }
        }
        
        setStep(7)
        if (!id) {
          setMysCongratsModalOpen(true)
          // Déclencher l'événement pour rafraîchir les limites d'annonces
          window.dispatchEvent(new Event('adCreated'))
        }

        toastSuccess(id ? "Événement modifié avec succès" : "Événement publié avec succès")
      } else {
        toastError(id ? "Erreur lors de la modification" : "Erreur lors de la création")
      }
    } catch (error) {
      console.error("[v0] Error submitting event:", error)
      toastError("Une erreur est survenue")
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const userId = localStorage.getItem("profileId")
    if (!userId) router.replace("/")
  }, [router])

  // Charger les catégories depuis l'API
  useEffect(() => {
    const loadCategories = async () => {
      try {
        const response = await getCategoriesByType("evenements")
        if (response && response.data) {
          const mainCategories = response.data.main || []
          const subs = response.data.subs || {}
          setCategories(mainCategories)
          setSubCategoriesMap(subs)
        }
      } catch (error) {
        console.error("[v0] Error loading categories:", error)
      }
    }
    loadCategories()
  }, [])

  const handleScroll = () => {
    if (stepperRef.current) {
      const scrollPosition = stepperRef.current.offsetTop - 100
      window.scrollTo({ top: scrollPosition, behavior: "smooth" })
    }
  }

  const handleNext = () => {
    console.log("[v0] handleNext called, current step:", step)
    setStep((prevStep: number) => {
      console.log("[v0] Previous step:", prevStep, "Next step:", prevStep + 1)
      return prevStep + 1
    })
    handleScroll()
  }

  const handlePrevious = () => {
    console.log("[v0] handlePrevious called, current step:", step)
    setStep((prevStep: number) => {
      console.log("[v0] Previous step:", prevStep, "Next step:", prevStep - 1)
      return prevStep - 1
    })
    handleScroll()
  }

  const iconEdit = (stepNumber: number) => (
    <button
      onClick={() => {
        setStep(stepNumber)
        handleScroll()
      }}
      className="text-primary hover:text-primary/80 transition-colors"
    >
      <Edit2 className="h-4 w-4" />
    </button>
  )

  if (userLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  // Function to render the final success message
  const renderSuccessMessage = () => {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-emerald-50 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center"
        >
          <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <Check className="w-10 h-10 text-green-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-4">
            {id ? "Votre événement a bien été modifié" : "Votre événement a bien été publié"}
          </h2>
          <div className="space-y-3">
            <Link href="/" className="block">
              <Button variant="outline" className="w-full bg-transparent">
                Retour à l'accueil
              </Button>
            </Link>
            <Link href="/dashboard/mes-annonces" className="block">
              <Button className="w-full bg-gradient-to-r from-green-500 to-green-600">Voir mes annonces</Button>
            </Link>
          </div>
        </motion.div>
      </div>
    )
  }

  if (step === 7) {
    return renderSuccessMessage()
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-emerald-50">
      <MysCongratsModal
        isOpen={mysCongratsModalOpen}
        onClose={() => setMysCongratsModalOpen(false)}
        content={
          <>
            Vous avez gagné <span className="text-green-600 font-bold">2 my's</span> suite à votre publication
            d'événement.
          </>
        }
      />

      {/* Updated header with gradient background */}
      <div className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Link href="/announcements/create">
              <Button variant="ghost" size="icon" className="rounded-full">
                <ArrowLeft className="h-5 w-5" />
              </Button>
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {id ? "Modifier un événement" : "Créer un événement"}
              </h1>
              <p className="text-sm text-gray-600">Partagez vos événements avec la communauté</p>
            </div>
          </div>
        </div>
      </div>

      <div ref={stepperRef} id="custom-stepper" className="container mx-auto px-4 py-8">
        <div className="max-w-3xl mx-auto">
          <Stepper
            steps={[
              { nb: 1, label: "Catégorie" },
              { nb: 2, label: "Lien" },
              { nb: 3, label: "Description" },
              { nb: 4, label: "Informations" },
              { nb: 5, label: "Photos" },
              { nb: 6, label: id ? "Revoir & Modifier" : "Revoir & Poster" },
            ]}
            setStep={setStep}
            current={step}
          />

          <motion.div
            className="bg-white rounded-2xl shadow-lg p-8 mt-8"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
          >
            {step === 1 && <EventFormFirstStep {...{ values, setValues, isEditMode }} />}

            {step === 2 && (
              <DealFormScrappingStep
                subtitle="Entrez le lien de la page où se trouve les informations de l'événement."
                inputPlaceholder="https://www.example.com/evenements"
                values={values}
                onChangeValues={(scraping) => {
                  setValues({
                    ...values,
                    website: values.website,
                    title: scraping.title,
                    description: scraping.description,
                    scrapping_images: scraping.images?.length > 0 ? scraping.images.slice(0, 9) : [],
                    startDate: scraping.event_date ? new Date(scraping.event_date) : values.startDate,
                  })
                }}
                onNext={handleNext}
              />
            )}

            {step === 3 && <EventFormSecondStep {...{ values, setValues, iconEdit }} />}

            {step === 4 && <EventFormThirdStep {...{ values, setValues }} />}

            {step === 5 && (
              <EventFormMediaStep
                values={values}
                setValues={(newValues: any) => setValues({ ...values, ...newValues })}
                existingImages={existingImages}
                onRemoveExistingImage={handleRemoveExistingImage}
                previewUrls={previewUrls}
                setPreviewUrls={setPreviewUrls}
                images={images}
                setImages={setImages}
                medias={medias}
                setMedias={setMedias}
                handleFileChange={handleFileChange}
              />
            )}

            {step === 6 && (
              <div className="flex flex-col gap-4">
                <h2 className="text-2xl font-bold text-center mb-4">Résumé de votre événement</h2>

                <div className="space-y-3">
                  <SummaryRow
                    label="Catégorie"
                    value={categories.find(cat => cat.code === values.eventType)?.label || values.eventType}
                    step={1}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Sous-catégorie"
                    value={
                      (() => {
                        const selectedCategory = categories.find(cat => cat.code === values.eventType)
                        if (selectedCategory) {
                          const subs = subCategoriesMap[selectedCategory.id] || []
                          const subCategory = subs.find(sub => sub.code === values.eventSubCategory)
                          return subCategory?.label || values.eventSubCategory
                        }
                        return values.eventSubCategory
                      })()
                    }
                    step={1}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Format"
                    value={
                      values.eventFormat === "in_person"
                        ? "Présentiel"
                        : values.eventFormat === "online"
                          ? "En ligne"
                          : "Hybride"
                    }
                    step={1}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow label="Titre" value={values.title} step={3} iconEdit={iconEdit} />
                  <SummaryRow
                    label="Description"
                    value={
                      values.description?.replace(/<[^>]+>/g, "").substring(0, 100) +
                      (values.description?.length > 100 ? "..." : "")
                    }
                    step={3}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Organisateur"
                    value={values.nameOrganizator || "Vous-même"}
                    step={3}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Adresse"
                    value={
                      values?.address?.country
                        ? `${values?.address?.line1 || ""}${values?.address?.line1 ? ", " : ""}${values?.address?.zipcode || ""} ${values?.address?.city || ""}`
                        : ""
                    }
                    step={3}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Prix"
                    value={Number(values?.price) ? `${Number(values?.price)} €` : "Gratuit"}
                    step={3}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Mode de réservation"
                    value={values.reservationMode || "Non spécifié"}
                    step={3}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow label="Site web" value={values.website || "Non renseigné"} step={3} iconEdit={iconEdit} />
                  <SummaryRow
                    label="Durée"
                    value={
                      values.startDate && values.endDate && values.startDate !== values.endDate
                        ? "Sur plusieurs jours"
                        : values.startDate
                          ? "Sur une journée"
                          : "Permanent"
                    }
                    step={4}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Date"
                    value={
                      values.startDate && values.endDate && values.startDate !== values.endDate
                        ? `Du ${new Date(values?.startDate).toLocaleDateString()} au ${new Date(values?.endDate).toLocaleDateString()}`
                        : values.startDate
                          ? `${new Date(values?.startDate).toLocaleDateString()}`
                          : "Maintenant"
                    }
                    step={4}
                    iconEdit={iconEdit}
                  />
                  <SummaryRow
                    label="Horaire"
                    value={`${values.endTime ? "De " + values.startTime + " à " + values.endTime : "À partir de " + values.startTime}`}
                    step={4}
                    iconEdit={iconEdit}
                  />
                </div>

                {/* Displaying media previews */}
                {(values.media && values.media.length > 0) && (
                  <div className="mt-6">
                    <div className="flex items-center justify-between mb-3">
                      <h3 className="text-sm font-bold">Médias</h3>
                      {iconEdit(5)}
                    </div>
                    <div className="flex gap-4 flex-wrap">
                      {values.media?.map((media, index) => (
                        <div key={index} className="relative w-24 h-24">
                          {media.type === "image" ? (
                            <Image
                              src={media.url || "/placeholder.svg"}
                              alt={`Media ${index}`}
                              layout="fill"
                              className="object-cover rounded-md"
                            />
                          ) : (
                            <div className="w-full h-full bg-gray-900 flex items-center justify-center rounded-md">
                              <Video className="w-8 h-8 text-white" />
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <hr className="my-4" />
                <div className="flex justify-center items-center gap-3">
                  <Input.Toggle
                    name="message"
                    checked={values.message}
                    onChange={(e) => setValues({ ...values, message: e.target.checked })}
                  />
                  <p className="text-xs flex items-center">
                    Autoriser les utilisateurs à m'envoyer des messages pour cette annonce
                  </p>
                </div>
              </div>
            )}
          </motion.div>

          {step < 6 && (
            <div className="flex justify-between mt-8">
              <Button variant="outline" onClick={handlePrevious} disabled={step === 1} className="px-8 bg-transparent">
                Précédent
              </Button>

              <Button
                onClick={handleNext}
                disabled={isNextStepDisabled()}
                className="px-8 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
              >
                Suivant
              </Button>
            </div>
          )}

          {step === 6 && (
            <div className="flex justify-center gap-4 mt-8">
              <Button
                variant="outline"
                disabled={loading}
                onClick={() => {
                  setStep((s: number) => s - 1)
                  handleScroll()
                }}
                className="px-8"
              >
                Précédent
              </Button>

              <Button
                disabled={loading}
                onClick={handleSubmit}
                className="px-8 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    {id ? "Modification..." : "Publication..."}
                  </>
                ) : (
                  <>{id ? "Modifier l'événement" : "Publier l'événement"}</>
                )}
              </Button>
            </div>
          )}

          {step < 6 && (
            <div className="mt-4">
              <p className="text-sm text-red-500">* Champ Obligatoire</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

const WrappedEventPage = () => {
  return (
    <AdFormProvider>
      {/* Removed NextIntlClientProvider wrapper */}
      <EventPage />
    </AdFormProvider>
  )
}

export default WrappedEventPage

function SummaryRow({
  label,
  value,
  step,
  iconEdit,
}: { label: string; value: string; step: number; iconEdit: (step: number) => ReactElement }) {
  return (
    <div className="grid md:grid-cols-3 w-full gap-2 items-center hover:bg-base-200 p-2 rounded-lg transition-colors">
      <span className="font-semibold text-gray-700">{label}:</span>
      <div className="flex items-center justify-between md:col-span-2">
        <span className="text-gray-900 truncate flex-1">{value}</span>
        <div className="ml-2">{iconEdit(step)}</div>
      </div>
    </div>
  )
}

function EventFormFirstStep({ values, setValues, isEditMode }: any) {
  const [categories, setCategories] = useState<Category[]>([])
  const [subCategories, setSubCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadCategories = async () => {
      try {
        setLoading(true)
        const response = await getCategoriesByType("evenements")
        if (response && response.data) {
          const mainCategories = response.data.main || []
          setCategories(mainCategories)
        }
      } catch (error) {
        console.error("[v0] Error loading categories:", error)
      } finally {
        setLoading(false)
      }
    }
    loadCategories()
  }, [])

  useEffect(() => {
    const loadSubCategories = async () => {
      if (!values.eventType) {
        setSubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("evenements")
        if (response && response.data) {
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === values.eventType || cat.id === values.eventType
          )

          if (selectedCategory) {
            const subs = response.data.subs[selectedCategory.id] || []
            setSubCategories(subs)
          } else {
            setSubCategories([])
          }
        }
      } catch (error) {
        console.error("[v0] Error loading subcategories:", error)
        setSubCategories([])
      }
    }
    loadSubCategories()
  }, [values.eventType])

  const onChange = onChangeHandler((newValues: any) => {
    // Réinitialiser la sous-catégorie si la catégorie change
    if (newValues.eventType !== values.eventType) {
      newValues.eventSubCategory = ""
    }
    setValues(newValues)
  })

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-center py-8">
          <Loader2 className="w-6 h-6 animate-spin text-green-600" />
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <Input.Select
        step={1}
        label="Premièrement, choisissez une catégorie :"
        placeholder="Catégorie d'évènement"
        name="eventType"
        onChange={onChange}
        options={categories.map((cat) => ({ id: cat.code, name: cat.label }))}
        value={values?.eventType || ""}
      >
        <option value={""} disabled>
          {"Catégorie d'évènement"}
        </option>
        {categories.map((category) => (
          <option key={`eventType-${category.id}`} value={category.code}>
            {category.label}
          </option>
        ))}
      </Input.Select>

      <Input.Select
        step={1}
        label="Et maintenant, le type d'évènement :"
        name={"eventSubCategory"}
        onChange={onChange}
        required
        value={values.eventSubCategory || ""}
        options={subCategories.map((sub) => ({ id: sub.code, name: sub.label }))}
      >
        <option value={""} disabled>
          {!values.eventType ? "Sélectionnez d'abord une catégorie" : subCategories.length === 0 ? "Aucune sous-catégorie disponible" : "Sélectionnez un type"}
        </option>
        {subCategories.map((sub) => (
          <option key={`eventSubCategory-${sub.id}`} value={sub.code}>
            {sub.label}
          </option>
        ))}
      </Input.Select>

      <Input.Select
        step={1}
        label="Format de l'événement :"
        name="eventFormat"
        onChange={onChange}
        required
        value={values.eventFormat || ""}
        options={[
          { id: "in_person", name: "Présentiel" },
          { id: "online", name: "En ligne" },
          { id: "hybrid", name: "Hybride" },
        ]}
      >
        <option value={""} disabled>
          {"Sélectionnez un format"}
        </option>
        <option value="in_person">Présentiel</option>
        <option value="online">En ligne</option>
        <option value="hybrid">Hybride</option>
      </Input.Select>
    </div>
  )
}

type DealFormScrappingStepProps = {
  subtitle: string
  inputPlaceholder: string
  values: any
  onChangeValues: (values: any) => void
  onNext: () => void
}

const DealFormScrappingStep = ({
  subtitle,
  inputPlaceholder,
  values,
  onChangeValues,
  onNext,
}: DealFormScrappingStepProps) => {
  const [isLoading, setIsLoading] = useState(false)
  const [message, setMessage] = useState({ success: false, message: "" })
  const [websiteUrl, setWebsiteUrl] = useState(values.id ? "" : values.website || "")

  const isValidUrl = (url: string) => {
    try {
      new URL(url)
      return true
    } catch (err) {
      return false
    }
  }

  const handleScraping = async () => {
    console.log("[v0] handleScraping called")
    if (!websiteUrl) {
      setMessage({ success: false, message: "Veuillez entrer un lien" })
      return
    }

    if (!isValidUrl(websiteUrl)) {
      setMessage({ success: false, message: "Le lien n'est pas valide" })
      return
    }

    setIsLoading(true)
    try {
      const { success, scraping } = await getScraping(websiteUrl)

      if (success) {
        onChangeValues({ ...values, website: websiteUrl, ...scraping })
        console.log("[v0] Scraping successful, calling onNext")
        onNext()
        setMessage({
          success: true,
          message: "Récupération des informations réussie",
        })
      } else {
        setMessage({
          success: false,
          message: "Récupération des informations impossible",
        })
      }
    } catch (error) {
      console.error("[v0] Scraping error:", error)
      setMessage({
        success: false,
        message: "Erreur lors de la récupération des informations",
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleWebsiteChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setWebsiteUrl(e.target.value)
  }

  return (
    <div className="flex flex-col gap-6 py-8">
      <div className="text-center">
        <p className="text-gray-600">{subtitle}</p>
      </div>

      <div className="flex flex-col gap-4">
        <div className="relative mb-6">
          <div className="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
            <Link2 className="w-4 h-4 text-gray-500" />
          </div>
          <div className="flex justify-between gap-6">
            <input
              type="url"
              className="w-full pl-10 pr-4 py-2 border rounded-md focus:ring-2 focus:ring-primary focus:border-primary transition-all"
              placeholder={inputPlaceholder}
              value={websiteUrl}
              onChange={handleWebsiteChange}
            />
            <Button
              disabled={isLoading}
              className="w-32 self-center transition-all hover:scale-105"
              onClick={handleScraping}
            >
              {isLoading ? "Chargement..." : "Continuer"}
            </Button>
          </div>
        </div>
        {message.success && <p className="text-green-500 text-sm self-center">{message.message}</p>}
        {message.success === false && message.message && (
          <p className="text-red-500 text-xs font-semibold self-center">{message.message}</p>
        )}
        <button
          className="text-primary text-sm hover:underline self-center transition-all"
          onClick={() => {
            console.log("[v0] 'Je n'ai pas de lien' clicked")
            onNext()
          }}
        >
          Je n'ai pas de lien
        </button>
      </div>
    </div>
  )
}

function capitalizeFirstLetter(text: any) {
  if (!text) return ""
  const lines = text.split("\n")
  const capitalizedLines = lines.map((line: any) => {
    const phrases = line.split(". ")
    const capitalizedPhrases = phrases.map((phrase: any) => {
      if (!phrase) return ""
      return phrase.charAt(0).toUpperCase() + phrase.slice(1)
    })
    return capitalizedPhrases.join(". ")
  })
  return capitalizedLines.join("\n")
}

function EventFormSecondStep({ values, setValues, iconEdit }: any) {
  const [isOrganizator, setIsOrganizator] = useState(values.isOrganizator)
  const [isFree, setIsFree] = useState(!values.price ? false : true)
  const [selectedCity, setSelectedCity] = useState(values?.address?.country === "France" ? "France" : "")

  const onChange = onChangeHandler(setValues)

  return (
    <div className="space-y-6">
      <Input.Base
        step={3}
        name="title"
        onChange={onChange}
        value={values.title || ""}
        required
        placeholder={"Titre ex : salon de l'automobile"}
        helperText={"Quelque chose de court et percutant."}
        label="Quel est votre titre ?"
      />

      <InputDescription
        value={values.description}
        onChange={(desc) => setValues({ ...values, description: desc })}
        label="Décrivez l'évènement :"
        required
        placeholder="Description"
      />

      <div className="space-y-4">
        <label className="block text-sm font-medium text-gray-700">
          {"Etes-vous l'organisateur de cet évènement ?"}
        </label>

        <div className="flex flex-col md:flex-row md:items-center gap-4">
          <div className="flex items-center gap-4">
            <Input.Radio
              id="is-organizator-yes"
              name="isOrganizator"
              checked={isOrganizator}
              onChange={({ target: { checked } }) => {
                if (checked) {
                  setIsOrganizator(true)
                  setValues({
                    ...values,
                    nameOrganizator: "",
                    isOrganizator: true,
                  })
                }
              }}
              value="yes"
            >
              Oui
            </Input.Radio>

            <Input.Radio
              id="is-organizator-no"
              name="isOrganizator"
              checked={!isOrganizator}
              onChange={({ target: { checked } }) => {
                if (checked) {
                  setIsOrganizator(false)
                  setValues({
                    ...values,
                    nameOrganizator: "",
                    isOrganizator: false,
                  })
                }
              }}
              value="no"
            >
              Non
            </Input.Radio>
          </div>

          <div className="flex-1">
            <Input.Base
              step={3}
              name="nameOrganizator"
              onChange={onChange}
              value={values.nameOrganizator || ""}
              placeholder={"Précisez le nom de l'organisateur"}
              disabled={isOrganizator}
              required={!isOrganizator}
            />
          </div>
        </div>
      </div>

      <div className="space-y-4">
        {/* CHANGE> Using Input.Autocomplete instead of Input.Address for city autocomplete */}
        <Input.Autocomplete
          label={"Lieu"}
          helperText={"Précisez la ville/région où cette offre est valide"}
          address={values?.address}
          setAddress={(address: any) => setValues((values: any) => ({ ...values, address }))}
          extraClass="w-full"
          cities={citiesData}
          disabled={selectedCity === "France"}
        />
        <Input.Toggle
          onChange={(event: any) => {
            const isChecked = event?.target?.checked
            setValues((prevValues: any) => ({
              ...prevValues,
              address: isChecked
                ? {
                    line1: "",
                    line2: "",
                    line3: "",
                    zipcode: "",
                    city: "",
                    country: "France",
                  }
                : {
                    line1: "",
                    line2: "",
                    line3: "",
                    zipcode: "",
                    city: "",
                    country: "",
                  },
            }))
            setSelectedCity(isChecked ? "France" : "")
          }}
          name="wholeFrance"
          label="Toute la France"
          value={(selectedCity === "France").toString()}
          checked={selectedCity === "France"}
        />
      </div>

      <div className="space-y-4">
        <label className="block text-sm font-medium text-gray-700">
          {"Prix d'entrée :"}
          <span className="text-error">*</span>
        </label>

        <div className="flex flex-col md:flex-row md:items-center gap-4">
          <div className="flex items-center gap-4">
            <Input.Radio
              id={"is-free"}
              checked={!isFree}
              onChange={({ target: { checked } }) => {
                setIsFree(!checked)
                setValues({
                  ...values,
                  price: 0,
                  priceType: "2", // 2 = Gratuit
                })
              }}
              value={0}
            >
              {"Gratuit"}
            </Input.Radio>
            <Input.Radio
              id={"is-paid"}
              checked={isFree}
              onChange={({ target: { checked } }) => {
                setIsFree(checked)
                setValues({
                  ...values,
                  priceType: "1", // 1 = Payant
                })
              }}
              value={0}
            >
              {"Payant"}
            </Input.Radio>
          </div>
          <div className="flex items-center gap-2">
            <Input.Base
              step={3}
              name="price"
              onChange={(e) => {
                const newPrice = parseFloat(e.target.value) || 0
                setValues({
                  ...values,
                  price: newPrice,
                  priceType: newPrice > 0 ? "1" : values.priceType, // Garde le priceType existant si prix = 0
                })
              }}
              value={values.price || ""}
              type="number"
              disabled={!isFree}
              className="w-24"
            />
            <Image src={"/assets/images/icons/euro.svg"} alt="logo euro" height={20} width={20} />
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <label className="block text-sm font-medium text-gray-700">
          {"Mode de reservation :"}
          <span className="text-error">*</span>
        </label>
        <div className="flex flex-col md:flex-row md:items-center gap-4">
          <div className="flex flex-wrap gap-4">
            <Input.Radio
              id={"no-registration"}
              checked={values.reservationMode === "Sans inscription"}
              onChange={({ target: { checked } }) => {
                if (checked) {
                  setValues({
                    ...values,
                    reservationMode: "Sans inscription",
                  })
                }
              }}
              value={0}
            >
              {"Sans inscription"}
            </Input.Radio>
            <Input.Radio
              id={"registration-required"}
              checked={values.reservationMode === "Inscription requise"}
              onChange={({ target: { checked } }) => {
                if (checked) {
                  setValues({
                    ...values,
                    reservationMode: "Inscription requise",
                  })
                }
              }}
              value={0}
            >
              {"Inscription requise"}
            </Input.Radio>
            <Input.Radio
              id={"ticket-purchase-required"}
              checked={values.reservationMode === "Achat de billet obligatoire"}
              onChange={({ target: { checked } }) => {
                if (checked) {
                  setValues({
                    ...values,
                    reservationMode: "Achat de billet obligatoire",
                  })
                }
              }}
              value={0}
            >
              {"Achat de billet obligatoire"}
            </Input.Radio>
          </div>
        </div>
      </div>

      <Input.Url
        step={3}
        name="website"
        onChange={onChange}
        value={values.website || ""}
        placeholder={"Entrer le site web"}
        label={"Site web"}
        helperText={"ex : www.websitepromo/code-save-10/"}
      />
    </div>
  )
}

type EventDurationType = "onDay" | "anyDay" | "permanent"

function EventFormThirdStep({ values, setValues }: any) {
  const [eventDurationType, setEventDurationType] = useState<EventDurationType>(
    values?.isOneDay ? "onDay" : values?.isSeveralDays ? "anyDay" : values?.isAllDays ? "permanent" : "onDay",
  )

  const handleDurationTypeChange = (type: EventDurationType) => {
    setEventDurationType(type)
    setValues({
      ...values,
      startDate: type === "permanent" ? null : values.startDate,
      endDate: type === "permanent" ? null : values.endDate,
      isOneDay: type === "onDay",
      isSeveralDays: type === "anyDay",
      isAllDays: type === "permanent",
      eventDurationType: type,
    })
  }

  return (
    <div className="space-y-6">
      <div>
        <label htmlFor="" className="font-semibold text-neutral/80 block mb-4">
          {"Durée de l'évènement :"}
          <span className="text-error">*</span>
        </label>

        <div className="space-y-4">
          <div>
            <Input.Radio
              id={"duration-one-day"}
              checked={eventDurationType === "onDay"}
              onChange={() => handleDurationTypeChange("onDay")}
              value={0}
            >
              {"Sur une journée"}
            </Input.Radio>
            {eventDurationType === "onDay" && (
              <div className="flex items-center gap-2 pl-4 py-2 animate-in slide-in-from-left duration-200">
                <p className="text-sm font-normal text-neutral">{"Date: "}</p>
                <Input.Date
                  disabled={eventDurationType !== "onDay"}
                  name="startDate"
                  onChange={(event: any) => {
                    setValues({
                      ...values,
                      startDate: event?.target?.value,
                    })
                  }}
                  value={values?.startDate || ""}
                  min={new Date().toISOString().split("T")[0]}
                  max={values?.endDate || ""}
                />
              </div>
            )}
          </div>

          <div>
            <Input.Radio
              id={"duration-several-days"}
              checked={eventDurationType === "anyDay"}
              onChange={() => handleDurationTypeChange("anyDay")}
              value={0}
            >
              {"Sur plusieurs jours"}
            </Input.Radio>
            {eventDurationType === "anyDay" && (
              <div className="flex flex-col gap-2 pl-4 py-2 animate-in slide-in-from-left duration-200">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-normal text-neutral w-24">{"À partir de"}</p>
                  <Input.Date
                    disabled={eventDurationType !== "anyDay"}
                    name="startDate"
                    onChange={(e) => {
                      setValues({
                        ...values,
                        startDate: e.target.value,
                      })
                    }}
                    value={values?.startDate || ""}
                    min={new Date().toISOString().split("T")[0]}
                    max={values?.endDate || ""}
                  />
                </div>
                <div className="flex items-center gap-2">
                  <p className="text-sm font-normal text-neutral w-24">{"Jusqu'à"}</p>
                  <Input.Date
                    disabled={eventDurationType !== "anyDay"}
                    name="endDate"
                    onChange={(e) => {
                      setValues({
                        ...values,
                        endDate: e.target.value,
                      })
                    }}
                    value={values?.endDate || ""}
                    min={values?.startDate || ""}
                  />
                </div>
              </div>
            )}
          </div>

          <div>
            <Input.Radio
              id={"duration-permanent"}
              checked={eventDurationType === "permanent"}
              onChange={() => handleDurationTypeChange("permanent")}
              value={0}
            >
              {"Permanent"}
            </Input.Radio>
          </div>
        </div>
      </div>

      <div>
        <label htmlFor="" className="font-semibold text-neutral/80 block mb-4">
          {"Horaires :"}
        </label>
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex items-center gap-2 flex-1">
            <p className="text-sm font-normal text-neutral w-12">{"De"}</p>
            <Input.Base
              step={4}
              type="time"
              name="startTime"
              onChange={(e) => {
                setValues({
                  ...values,
                  startTime: e.target.value,
                })
              }}
              value={values.startTime || ""}
            />
          </div>
          <div className="flex items-center gap-2 flex-1">
            <p className="text-sm font-normal text-neutral w-12">{"À"}</p>
            <Input.Base
              step={4}
              type="time"
              name="endTime"
              onChange={(e) => {
                setValues({
                  ...values,
                  endTime: e.target.value,
                })
              }}
              value={values.endTime || ""}
            />
          </div>
        </div>
      </div>
    </div>
  )
}

function EventFormMediaStep({ 
  values, 
  setValues, 
  existingImages = [], 
  onRemoveExistingImage,
  previewUrls = [],
  setPreviewUrls,
  images = [],
  setImages,
  medias = [],
  setMedias,
  handleFileChange
}: any) {
  const [mediaFiles, setMediaFiles] = useState<Array<{ type: "image" | "video"; url: string; file?: File }>>(
    values.media || [],
  )
  const [isDragging, setIsDragging] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileSelect = (files: FileList | null) => {
    if (!files) return

    const newFiles = Array.from(files).map((file) => ({
      type: file.type.startsWith("video/") ? ("video" as const) : ("image" as const),
      url: URL.createObjectURL(file),
      file,
    }))

    const updatedMedia = [...mediaFiles, ...newFiles]
    setMediaFiles(updatedMedia)
    setValues({ ...values, media: updatedMedia })
    
    if (handleFileChange) {
      const event = { target: { files } } as any
      handleFileChange(event)
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    handleFileSelect(e.dataTransfer.files)
  }

  const removeMedia = (index: number) => {
    const updatedMedia = mediaFiles.filter((_, i) => i !== index)
    setMediaFiles(updatedMedia)
    setValues({ ...values, media: updatedMedia })
  }

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
    <div className="space-y-6">
      {existingImages.length > 0 && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h4 className="text-lg font-semibold text-gray-900">Photos déjà publiées</h4>
              <p className="text-sm text-gray-600">Supprimez les photos que vous ne souhaitez plus afficher.</p>
            </div>
            <span className="text-sm font-medium text-gray-500">{existingImages.length} photo(s)</span>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {existingImages.map((image: { id: string; url: string }) => (
              <div
                key={image.id}
                className="relative rounded-lg overflow-hidden border-2 border-gray-200 hover:border-red-400 transition"
              >
                <img src={getImageUrl(image.url)} alt="Image existante" className="w-full h-40 object-cover" />
                <button
                  type="button"
                  onClick={() => onRemoveExistingImage && onRemoveExistingImage(image.id)}
                  className="absolute top-2 right-2 w-8 h-8 bg-red-500 hover:bg-red-600 text-white rounded-full flex items-center justify-center shadow-lg"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="text-center mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Ajoutez des photos et vidéos</h3>
        <p className="text-sm text-gray-600">
          Illustrez votre événement avec des images et vidéos pour le rendre plus attractif
        </p>
      </div>

      <div
        className={`border-2 border-dashed rounded-xl p-8 text-center transition-all ${
          isDragging ? "border-green-500 bg-green-50" : "border-gray-300 hover:border-green-400 hover:bg-gray-50"
        }`}
        onDragOver={(e) => {
          e.preventDefault()
          setIsDragging(true)
        }}
        onDragLeave={() => setIsDragging(false)}
        onDrop={handleDrop}
      >
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*,video/*"
          multiple
          className="hidden"
          onChange={(e) => handleFileSelect(e.target.files)}
        />

        <div className="flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center">
            <Upload className="w-8 h-8 text-green-600" />
          </div>
          <div>
            <p className="text-gray-700 font-medium mb-1">Glissez-déposez vos fichiers ici</p>
            <p className="text-sm text-gray-500">ou</p>
          </div>
          <Button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700"
          >
            Parcourir les fichiers
          </Button>
          <p className="text-xs text-gray-500">Images (JPG, PNG, GIF) et vidéos (MP4, MOV) acceptées</p>
        </div>
      </div>

      {mediaFiles.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
          {mediaFiles.map((media, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              className="relative group rounded-lg overflow-hidden border-2 border-gray-200 hover:border-green-500 transition-all"
            >
              {media.type === "image" ? (
                <img
                  src={media.url || "/placeholder.svg"}
                  alt={`Media ${index + 1}`}
                  className="w-full h-40 object-cover"
                />
              ) : (
                <div className="w-full h-40 bg-gray-900 flex items-center justify-center">
                  <Video className="w-12 h-12 text-white" />
                </div>
              )}
              <button
                type="button"
                onClick={() => removeMedia(index)}
                className="absolute top-2 right-2 w-8 h-8 bg-red-500 hover:bg-red-600 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
              >
                <X className="w-4 h-4" />
              </button>
              <div className="absolute bottom-2 left-2 px-2 py-1 bg-black/70 text-white text-xs rounded">
                {media.type === "image" ? <ImageIcon className="w-3 h-3" /> : <Video className="w-3 h-3" />}
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  )
}
