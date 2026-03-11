"use client"

import type React from "react"
import { useRef, useState, useEffect } from "react"
import { motion } from "framer-motion"
import { ArrowLeft, Link2, Loader2, Upload, X, ImageIcon, Video, Check, Edit2, Trash2 } from "lucide-react"
import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"
import axios from "axios"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Stepper } from "@/components/ui/stepper"
import { Input } from "@/components/ui/input-select"
import { InputDescription } from "@/components/ui/input-description"
import { getScraping } from "@/lib/api/scraping"
import { AdFormProvider, useAdForm } from "@/lib/contexts/ad-form-context"
import { labelObject } from "@/lib/constants/label-object"
import { trainingTypes } from "@/lib/constants/training-categories-full"
import { getCategoriesByType, type Category } from "@/lib/api/categories"
import { teachingTypes, targetPublics, fundings } from "@/lib/constants/training-form-constants"
import citiesData from "@/lib/data/france-cities.json"
import { config } from "@/lib/config"
import { usePermissions } from "@/lib/hooks/use-permissions"
import { useProPlanModal } from "@/lib/hooks/use-pro-plan-modal"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import { MysCongratsModal } from "@/components/modals/mys-congrats-modal"
import { useUserData } from "@/lib/hooks/use-user-data"

const defaultValues = {
  title: "",
  description: "",
  trainingType: "",
  trainingCategory: "",
  trainingSubCategory: "",
  trainingStyle: [] as string[],
  trainingPublic: [] as string[],
  requiredLevels: [] as string[],
  price: "",
  priceType: "",
  public: "",
  tempo: "",
  trainingFunding: [] as string[],
  durationInH: "",
  duration: "",
  startDate: "",
  endDate: "",
  dateToDefine: false, // Added dateToDefine
  documents: [] as Array<{ id: string | number; url: string; name: string; type: string }>,
  documentsFiles: [] as File[],
  website: "",
  certification: [] as string[],
  address: {},
  show: false,
  media: [] as Array<{ type: "image" | "video"; url: string; file?: File }>,
  acceptMessages: false,
}

function TrainingFormFirstStep({ values, setValues, reviewing = false }: any) {
  const [categories, setCategories] = useState<Category[]>([])
  const [subCategories, setSubCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadCategories = async () => {
      try {
        setLoading(true)
        const response = await getCategoriesByType("formations")
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
      if (!values.trainingCategory) {
        setSubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("formations")
        if (response && response.data) {
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === values.trainingCategory || cat.id === values.trainingCategory
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
  }, [values.trainingCategory])

  const onChange = (evt: React.ChangeEvent<HTMLSelectElement | HTMLInputElement>) => {
    if (evt?.target?.name === "trainingCategory") {
      setValues({
        ...values,
        [evt?.target?.name]: evt?.target?.value,
        trainingSubCategory: "", // Reset sub-category
      })
    } else {
      setValues({
        ...values,
        [evt?.target?.name]: evt?.target?.value,
      })
    }
  }

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
        label={!reviewing ? "Premièrement, choisissez la catégorie de la formation :" : "Catégorie :"}
        name="trainingCategory"
        onChange={onChange}
        required
        value={values.trainingCategory || ""}
        reviewing={reviewing}
      >
        <option value="" disabled>
          Catégorie de la formation
        </option>
        {categories.map((category) => (
          <option key={`trainingCategory-${category.id}`} value={category.code}>
            {category.label}
          </option>
        ))}
      </Input.Select>

      {values.trainingCategory && (
        <Input.Select
          label={!reviewing ? "Et maintenant, le secteur de formation :" : "Secteur :"}
          name="trainingSubCategory"
          onChange={onChange}
          required
          value={values.trainingSubCategory || ""}
          reviewing={reviewing}
        >
          <option value="" disabled>
            {subCategories.length === 0 ? "Aucune sous-catégorie disponible" : "Sélectionnez un secteur"}
          </option>
          {subCategories.map((subCategory) => (
            <option key={`trainingSubCategory-${subCategory.id}`} value={subCategory.code}>
              {subCategory.label}
            </option>
          ))}
        </Input.Select>
      )}

      <Input.Select
        label={!reviewing ? "Type de formation :" : "Type :"}
        name="trainingType"
        onChange={onChange}
        required
        value={values.trainingType || ""}
        reviewing={reviewing}
      >
        <option value="" disabled>
          Sélectionnez un type de formation
        </option>
        {trainingTypes.map((type) => (
          <option key={`trainingType-${type}`} value={type}>
            {(labelObject as any)[type] || type}
          </option>
        ))}
      </Input.Select>
    </div>
  )
}

function TrainingFormScrappingStep({ values, onChangeValues, handleNext }: any) {
  const [isLoading, setIsLoading] = useState(false)
  const [message, setMessage] = useState({ success: false, message: "" })
  const [websiteUrl, setWebsiteUrl] = useState(values.website || "")

  const isValidUrl = (url: string) => {
    try {
      new URL(url)
      return true
    } catch (err) {
      return false
    }
  }

  const handleScraping = async () => {
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
        handleNext()
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
      console.error("[v0] Erreur lors du scraping:", error)
      setMessage({
        success: false,
        message: "Erreur lors de la récupération des informations",
      })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <motion.div
      className="flex flex-col gap-6 py-8"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="text-center">
        <p className="text-gray-600">
          Entrez le lien de la page de la formation pour récupérer automatiquement les informations.
        </p>
      </div>

      <div className="flex flex-col gap-4">
        <div className="relative">
          <div className="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none">
            <Link2 className="w-5 h-5 text-gray-400" />
          </div>
          <input
            type="url"
            className="w-full pl-12 pr-4 py-4 border-2 border-gray-200 rounded-xl focus:border-green-500 focus:ring-4 focus:ring-green-100 transition-all text-gray-700"
            placeholder="https://www.example.com/formation"
            value={websiteUrl}
            onChange={(e) => setWebsiteUrl(e.target.value)}
          />
        </div>

        <Button
          onClick={handleScraping}
          disabled={isLoading}
          className="w-full py-6 bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-lg font-semibold"
        >
          {isLoading ? (
            <>
              <Loader2 className="w-5 h-5 mr-2 animate-spin" />
              Récupération en cours...
            </>
          ) : (
            "Continuer"
          )}
        </Button>

        {message.message && (
          <p className={`text-sm text-center font-semibold ${message.success ? "text-green-600" : "text-red-600"}`}>
            {message.message}
          </p>
        )}

        <button
          type="button"
          className="text-green-600 text-sm hover:underline self-center font-medium"
          onClick={handleNext}
        >
          Je n'ai pas de lien
        </button>
      </div>
    </motion.div>
  )
}

function TrainingFormDescriptionStep({ values, setValues, reviewing }: any) {
  const onChange = (evt: any) => {
    setValues({
      ...values,
      [evt?.target?.name]: evt?.target?.value,
    })
  }

  const inputRef = useRef<HTMLInputElement>(null)
  const [isShow, setIsShow] = useState(values?.show)
  const [medias, setMedias] = useState<any[]>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])
  const [dateToDefine, setDateToDefine] = useState(values?.dateToDefine || false) // Initialize dateToDefine from values
  const [existingImages, setExistingImages] = useState<Array<{ id: string; url: string }>>([])
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([])

  useEffect(() => {
    setIsShow(values?.show)
  }, [values?.show])

  useEffect(() => {
    if (dateToDefine) {
      setValues((prev: any) => ({
        ...prev,
        startDate: "",
        endDate: "",
      }))
    }
  }, [dateToDefine])

  useEffect(() => {
    if (typeof values.requiredLevels === "string") {
      const requiredLevels = values.requiredLevels.replace(/[{}]/g, "").split(",")
      setValues((prev: any) => ({
        ...prev,
        requiredLevels,
      }))
    }

    if (typeof values.certification === "string") {
      const certification = values.certification.replace(/[{}]/g, "").split(",")
      setValues((prev: any) => ({
        ...prev,
        certification,
      }))
    }
  }, [])

  useEffect(() => {
    if (values.startDate) {
      setValues((prev: any) => ({
        ...prev,
        startDate: values?.startDate?.split(" ")[0],
      }))
    }

    if (values.endDate) {
      setValues((prev: any) => ({
        ...prev,
        endDate: values?.endDate?.split(" ")[0],
      }))
    }
  }, [])

  const getPriceLabel = () => {
    switch (values.priceType) {
      case "1":
        return " NET"
      case "2":
        return " HT"
      case "3":
        return " TTC"
      default:
        return ""
    }
  }

  const getDurationLabel = () => {
    switch (values.duration) {
      case "0":
        return " /h"
      case "1":
        return " /j"
      case "2":
        return " /s"
      case "3":
        return " /m"
      case "4":
        return " /a"
      default:
        return ""
    }
  }

  const handleDocumentChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files)

      const docsMeta = files.map((file) => ({
        id: file.name + Date.now(),
        url: URL.createObjectURL(file),
        name: file.name,
        type: file.type,
      }))

      setValues((prev: any) => ({
        ...prev,
        documents: [...(prev.documents || []), ...docsMeta],
        documentsFiles: [...(prev.documentsFiles || []), ...files],
      }))

      setMedias((prevMedias) => [
        ...prevMedias,
        ...files.map((file) => ({
          id: file.name,
          url: URL.createObjectURL(file),
          name: file.name,
          type: file.type,
        })),
      ])

      const urls = files.map((file) => URL.createObjectURL(file))
      setPreviewUrls((prevUrls) => [...prevUrls, ...urls])
    }
  }

  const addSvg = (
    <svg viewBox="0 0 41 41" fill="current" xmlns="http://www.w3.org/2000/svg">
      <path
        fillRule="evenodd"
        clipRule="evenodd"
        d="M20.5 0C9.17841 0 0 9.17841 0 20.5C0 31.8216 9.17841 41 20.5 41C31.8216 41 41 31.8216 41 20.5C41 9.17841 31.8216 0 20.5 0ZM22.3636 27.9545C22.3636 28.4488 22.1673 28.9228 21.8178 29.2723C21.4683 29.6218 20.9943 29.8182 20.5 29.8182C20.0057 29.8182 19.5317 29.6218 19.1822 29.2723C18.8327 28.9228 18.6364 28.4488 18.6364 27.9545V22.3636H13.0455C12.5512 22.3636 12.0772 22.1673 11.7277 21.8178C11.3782 21.4683 11.1818 20.9943 11.1818 20.5C11.1818 20.0057 11.3782 19.5317 11.7277 19.1822C12.0772 18.8327 12.5512 18.6364 13.0455 18.6364H18.6364V13.0455C18.6364 12.5512 18.8327 12.0772 19.1822 11.7277C19.5317 11.3782 20.0057 11.1818 20.5 11.1818C20.9943 11.1818 21.4683 11.3782 21.8178 11.7277C22.1673 12.0772 22.3636 12.5512 22.3636 13.0455V18.6364H27.9545C28.4488 18.6364 28.9228 18.8327 29.2723 19.1822C29.6218 19.5317 29.8182 20.0057 29.8182 20.5C29.8182 20.9943 29.6218 21.4683 29.2723 21.8178C28.9228 22.1673 28.4488 22.3636 27.9545 22.3636H22.3636V27.9545Z"
        fill="url(#paint0_linear_6769_101181)"
      />
      <defs>
        <linearGradient
          id="paint0_linear_6769_101181"
          x1="2.5274"
          y1="2.24658"
          x2="37.6301"
          y2="39.8767"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#55D870" />
          <stop offset="0.857292" stopColor="#277C45" />
        </linearGradient>
      </defs>
    </svg>
  )

  return (
    <div className="space-y-6">
      {/* Titre */}
      <Input.Base
        reviewing={reviewing}
        onChange={onChange}
        required
        type="text"
        name="title"
        placeholder="ex : formation aide soignante"
        label={!reviewing ? "Quel est votre titre ?" : "Titre :"}
        helperText="Quelque chose de court et percutant."
        value={values?.title || ""}
      />

      {/* Type d'enseignement */}
      {!reviewing ? (
        <div className="my-2">
          <label htmlFor="" className="font-semibold text-gray-700">
            {"Type d'enseignement :"}
            <span className="text-xs text-gray-500 font-light ml-1">{"Choix multiple possible"}</span>
            <span className="text-red-500 ml-1">{"*"}</span>
          </label>
          <div className="flex flex-col h-32 overflow-auto bg-gray-50 rounded-lg p-2 mt-2">
            {teachingTypes.map((teaching: any) => (
              <div key={`trainingStyle-${teaching}`} className="flex items-center py-1">
                <input
                  type="checkbox"
                  onChange={(event: any) => {
                    const isChecked = event.target.checked
                    const indifferentId = teachingTypes.find((type) => type === "Indifferent")

                    if (teaching === indifferentId) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        trainingStyle: isChecked ? teachingTypes.map((trainingStyle: any) => trainingStyle) : [],
                      }))
                    } else {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        trainingStyle: isChecked
                          ? [...prevValues.trainingStyle, teaching]
                          : prevValues.trainingStyle.filter((value: any) => value !== teaching),
                      }))

                      if (!isChecked && values.trainingStyle.includes(indifferentId)) {
                        setValues((prevValues: any) => ({
                          ...prevValues,
                          trainingStyle: prevValues.trainingStyle.filter((value: any) => value !== indifferentId),
                        }))
                      }
                    }
                  }}
                  checked={values.trainingStyle.includes(teaching)}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span className="mx-2 flex items-center text-gray-700">
                  {(labelObject as any)[teaching] || teaching}
                </span>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Type d'enseignement :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {values.trainingStyle.includes(teachingTypes.find((name: any) => name === "Indifferent"))
              ? "Tout"
              : teachingTypes
                  .filter((id: any) => values?.trainingStyle.includes(id))
                  .map((name: any) => (labelObject as any)[name] || name)
                  .join(", ")}
          </span>
        </div>
      )}

      {/* Public visé */}
      {!reviewing ? (
        <div className="my-2">
          <label htmlFor="" className="font-semibold text-gray-700">
            {"Public visé :"}
            <span className="text-xs text-gray-500 font-light ml-1">{"Choix multiple possible"}</span>
            <span className="text-red-500 ml-1">{"*"}</span>
          </label>
          <div className="flex flex-col h-32 overflow-auto bg-gray-50 rounded-lg p-2 mt-2">
            {targetPublics?.map((targetPublic: any) => (
              <div key={`trainingPublic-${targetPublic}`} className="flex items-center py-1">
                <input
                  type="checkbox"
                  onChange={(event: any) => {
                    const isChecked = event.target.checked
                    const allPublicId = targetPublics.find((trainingPublic: any) => trainingPublic === "AllPublic")

                    if (targetPublic === allPublicId) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        trainingPublic: isChecked ? targetPublics.map((trainingPublic: any) => trainingPublic) : [],
                      }))
                    } else {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        trainingPublic: isChecked
                          ? [...prevValues.trainingPublic, targetPublic]
                          : prevValues.trainingPublic.filter((value: any) => value !== targetPublic),
                      }))

                      if (!isChecked && values.trainingPublic.includes(allPublicId)) {
                        setValues((prevValues: any) => ({
                          ...prevValues,
                          trainingPublic: prevValues.trainingPublic.filter((value: any) => value !== allPublicId),
                        }))
                      }
                    }
                  }}
                  checked={values.trainingPublic.includes(targetPublic)}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span className="mx-2 flex items-center text-gray-700">
                  {(labelObject as any)[targetPublic] || targetPublic}
                </span>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Public visé :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {values.trainingPublic.includes(targetPublics.find((name: any) => name === "AllPublic"))
              ? "Tout public"
              : targetPublics
                  .filter((id: any) => values?.trainingPublic.includes(id))
                  .map((name: any) => (labelObject as any)[name] || name)
                  .join(", ")}
          </span>
        </div>
      )}

      {/* Niveau requis */}
      {!reviewing ? (
        <div className="my-2">
          <label htmlFor="" className="font-semibold text-gray-700">
            {"Niveau requis :"}
            <span className="text-xs text-gray-500 font-light ml-1">{"Choix multiple possible"}</span>
            <span className="text-red-500 ml-1">{"*"}</span>
          </label>
          <div className="flex flex-col h-32 overflow-auto bg-gray-50 rounded-lg p-2 mt-2">
            {["Aucun prérequis", "CAP/BEP", "Bac", "Bac+2", "Bac+3", "Bac+5 et plus"].map((level) => (
              <div key={`requiredLevel-${level}`} className="flex items-center py-1">
                <input
                  type="checkbox"
                  onChange={(event) => {
                    const isChecked = event.target.checked
                    setValues((prevValues: any) => ({
                      ...prevValues,
                      requiredLevels: Array.isArray(prevValues.requiredLevels)
                        ? isChecked
                          ? [...prevValues.requiredLevels, level]
                          : prevValues.requiredLevels.filter((value: any) => value !== level)
                        : isChecked
                          ? [level]
                          : [],
                    }))
                  }}
                  checked={Array.isArray(values?.requiredLevels) && values.requiredLevels.includes(level)}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span className="mx-2 text-gray-700">{level}</span>
              </div>
            ))}

            {Array.isArray(values?.requiredLevels) &&
              values.requiredLevels
                .filter(
                  (level: string) =>
                    !["Aucun prérequis", "CAP/BEP", "Bac", "Bac+2", "Bac+3", "Bac+5 et plus"].includes(level),
                )
                .map((level: string, index: number) => (
                  <div key={`customRequiredLevel-${index}`} className="flex items-center mt-2 gap-2">
                    <input
                      type="text"
                      value={level}
                      onChange={(event) => {
                        const newLevel = event.target.value
                        setValues((prevValues: any) => {
                          const updatedLevels = [
                            ...(Array.isArray(prevValues.requiredLevels) ? prevValues.requiredLevels : []),
                          ]
                          const baseIndex = 6 + index
                          updatedLevels[baseIndex] = newLevel
                          return {
                            ...prevValues,
                            requiredLevels: updatedLevels,
                          }
                        })
                      }}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    />
                    <button
                      type="button"
                      className="text-red-500 hover:text-red-700"
                      onClick={() => {
                        setValues((prevValues: any) => ({
                          ...prevValues,
                          requiredLevels: Array.isArray(prevValues.requiredLevels)
                            ? prevValues.requiredLevels.filter((l: string) => l !== level)
                            : [],
                        }))
                      }}
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}

            <div className="flex items-center mt-2 gap-2">
              <input
                type="text"
                placeholder="Ajouter un niveau"
                ref={inputRef}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                onKeyDown={(event) => {
                  if (event.key === "Enter" && inputRef.current && inputRef.current.value.trim() !== "") {
                    const newLevel = inputRef.current.value.trim()
                    if (!Array.isArray(values.requiredLevels)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        requiredLevels: [newLevel],
                      }))
                    } else if (!values.requiredLevels.includes(newLevel)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        requiredLevels: [...prevValues.requiredLevels, newLevel],
                      }))
                    }
                    inputRef.current.value = ""
                  }
                }}
              />
              <button
                type="button"
                className="px-4 py-2 text-green-600 border border-green-600 rounded-lg hover:bg-green-50 transition-colors"
                onClick={() => {
                  if (inputRef.current && inputRef.current.value.trim() !== "") {
                    const newLevel = inputRef.current.value.trim()
                    if (!Array.isArray(values.requiredLevels)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        requiredLevels: [newLevel],
                      }))
                    } else if (!values.requiredLevels.includes(newLevel)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        requiredLevels: [...prevValues.requiredLevels, newLevel],
                      }))
                    }
                    inputRef.current.value = ""
                  }
                }}
              >
                Ajouter +
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Niveau requis :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {Array.isArray(values.requiredLevels) ? values.requiredLevels.join(", ") : ""}
          </span>
        </div>
      )}

      {/* Prix de la formation */}
      {!reviewing ? (
        <div>
          <label htmlFor="" className="font-semibold text-gray-700 mt-2 block mb-2">
            {"Prix de la formation :"}
            <span className="text-red-500 ml-1">{"*"}</span>
          </label>
          <div className="flex items-center gap-2 mb-4">
            <div className="flex-1 relative">
              <input
                type="number"
                name="price"
                value={values?.price > 0 ? values?.price : ""}
                onChange={onChange}
                disabled={values?.priceType === "4" || values?.priceType === "5"}
                className="w-full px-4 py-2 pr-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
                placeholder="Prix"
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium">€</span>
            </div>
            
          </div>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-2 mb-4">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="priceType"
                value="1"
                checked={values?.priceType === "1"}
                onChange={onChange}
                className="w-4 h-4 text-green-600"
              />
              <span className="text-sm text-gray-700">Prix NET</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="priceType"
                value="2"
                checked={values?.priceType === "2"}
                onChange={onChange}
                className="w-4 h-4 text-green-600"
              />
              <span className="text-sm text-gray-700">Prix HT</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="priceType"
                value="3"
                checked={values?.priceType === "3"}
                onChange={onChange}
                className="w-4 h-4 text-green-600"
              />
              <span className="text-sm text-gray-700">Prix TTC</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="priceType"
                value="4"
                checked={values?.priceType === "4"}
                onChange={(event: any) => {
                  const isChecked = event?.target?.checked
                  setValues((prevValues: any) => ({
                    ...prevValues,
                    priceType: isChecked ? "4" : "",
                    price: 0,
                  }))
                }}
                className="w-4 h-4 text-green-600"
              />
              <span className="text-sm text-gray-700">Gratuit</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="priceType"
                value="5"
                checked={values?.priceType === "5"}
                onChange={(event: any) => {
                  const isChecked = event?.target?.checked
                  setValues((prevValues: any) => ({
                    ...prevValues,
                    priceType: isChecked ? "5" : "",
                    price: 0,
                  }))
                }}
                className="w-4 h-4 text-green-600"
              />
              <span className="text-sm text-gray-700">Devis sur-mesure</span>
            </label>
          </div>
          <div className="grid md:grid-cols-2 gap-4">
            <select
              name="public"
              value={values?.public || ""}
              onChange={onChange}
              disabled={values?.priceType === "4" || values?.priceType === "5"}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
            >
              <option value={""} disabled>
                {"Tarif appliqué"}
              </option>
              <option value={"personne"}>{"Par personne"}</option>
              <option value={"groupe"}>{"Par groupe"}</option>
            </select>

            <select
              name="tempo"
              value={values?.tempo || ""}
              onChange={onChange}
              disabled={values?.priceType === "4" || values?.priceType === "5"}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
            >
              <option value={""} disabled>
                {"Temporalité"}
              </option>
              <option value={"heure"}>{"par heure"}</option>
              <option value={"jour"}>{"par jour"}</option>
              <option value={"semaine"}>{"par semaine"}</option>
              <option value={"mois"}>{"par mois"}</option>
              <option value={"an"}>{"par an"}</option>
              <option value={"all"}>{"pour toute la formation"}</option>
            </select>
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Prix :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {values.priceType === "5"
              ? "Devis sur-mesure"
              : values.priceType === "4" || values.price === 0
                ? "Gratuit"
                : `${values.price}€${getPriceLabel()}${getDurationLabel()} ${values.public ? `/${values.public}` : ""} ${
                    values.tempo && values.tempo != "all" ? `/${values.tempo}` : ""
                  }`}
          </span>
        </div>
      )}

      {/* Financement */}
      {!reviewing ? (
        <div className="my-2">
          <label htmlFor="" className="font-semibold text-gray-700">
            {"Financement :"}
            <span className="text-xs text-gray-500 font-light ml-1">{"Choix multiple possible"}</span>
            <span className="text-red-500 ml-1">{"*"}</span>
          </label>
          <div className="flex flex-col h-32 overflow-auto bg-gray-50 rounded-lg p-2 mt-2">
            {fundings?.map((fund: any) => (
              <div key={`trainingFunding-${fund}`} className="flex items-center py-1">
                <input
                  type="checkbox"
                  onChange={(event: any) => {
                    const isChecked = event.target.checked
                    const indifferentId = fundings.find((trainingFunding) => trainingFunding === "Indifferent")

                    if (fund === indifferentId) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        trainingFunding: isChecked ? fundings.map((trainingFunding: any) => trainingFunding) : [],
                      }))
                    } else {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        trainingFunding: isChecked
                          ? [...prevValues.trainingFunding, fund]
                          : prevValues.trainingFunding.filter((value: any) => value !== fund),
                      }))

                      if (!isChecked && values.trainingFunding.includes(indifferentId)) {
                        setValues((prevValues: any) => ({
                          ...prevValues,
                          trainingFunding: prevValues.trainingFunding.filter((value: any) => value !== indifferentId),
                        }))
                      }
                    }
                  }}
                  checked={values.trainingFunding.includes(fund)}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span className="mx-2 flex items-center text-gray-700">{(labelObject as any)[fund] || fund}</span>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Financement :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {values.trainingFunding.includes(fundings.find((name: any) => name === "Indifferent"))
              ? "Indifferent"
              : fundings
                  .filter((id: any) => values?.trainingFunding.includes(id))
                  .map((name: any) => (labelObject as any)[name] || name)
                  .join(", ")}
          </span>
        </div>
      )}

      {/* Durée de la formation */}
      {!reviewing ? (
        <div className="grid md:grid-cols-2 gap-4">
          <input
            type="number"
            name="durationInH"
            value={values?.durationInH > 0 ? values?.durationInH : ""}
            onChange={onChange}
            placeholder="Durée"
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
          <select
            name="duration"
            value={values?.duration || ""}
            onChange={onChange}
            disabled={!(values?.durationInH > 0)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed"
          >
            <option disabled value={""}>
              {"Temporalité"}
            </option>
            <option value={"0"}>{"Heure(s)"}</option>
            <option value={"1"}>{"Jour(s)"}</option>
            <option value={"2"}>{"Semaine(s)"}</option>
            <option value={"3"}>{"Mois"}</option>
            <option value={"4"}>{"An(s)"}</option>
          </select>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Durée :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {values?.durationInH
              ? `${Math.round(values?.durationInH)} ${
                  values?.duration === "0"
                    ? "heure(s)"
                    : values?.duration === "1"
                      ? "jour(s)"
                      : values?.duration === "2"
                        ? "semaines"
                        : values?.duration === "3"
                          ? "mois"
                          : values?.duration === "4"
                            ? "ans"
                            : ""
                }`
              : ""}
          </span>
        </div>
      )}

      {/* Dates */}
      {!reviewing ? (
        <div className="space-y-4">
          <div className="flex items-center gap-6">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="dateOption"
                checked={!dateToDefine}
                onChange={() => {
                  setDateToDefine(false)
                  setValues((prev: any) => ({ ...prev, dateToDefine: false }))
                }}
                className="w-4 h-4 text-green-600 focus:ring-green-500"
              />
              <span className="text-sm font-medium text-gray-700">Dates définies</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="dateOption"
                checked={dateToDefine}
                onChange={() => {
                  setDateToDefine(true)
                  setValues((prev: any) => ({ ...prev, dateToDefine: true }))
                }}
                className="w-4 h-4 text-green-600 focus:ring-green-500"
              />
              <span className="text-sm font-medium text-gray-700">Date à définir</span>
            </label>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Date de début</label>
              <input
                type="date"
                name="startDate"
                value={values?.startDate || ""}
                onChange={(e) => {
                  onChange(e)
                  setDateToDefine(false) // Ensure dateToDefine is false if dates are entered
                  setValues((prev: any) => ({ ...prev, dateToDefine: false }))
                }}
                max={values?.endDate}
                disabled={dateToDefine}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-60"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">Date de fin</label>
              <input
                type="date"
                name="endDate"
                value={values?.endDate || ""}
                onChange={(e) => {
                  onChange(e)
                  setDateToDefine(false) // Ensure dateToDefine is false if dates are entered
                  setValues((prev: any) => ({ ...prev, dateToDefine: false }))
                }}
                min={values?.startDate}
                disabled={dateToDefine}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent disabled:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-60"
              />
            </div>
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Date :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {dateToDefine || (!values?.startDate && !values?.endDate)
              ? "Date à définir"
              : values?.startDate && values?.endDate && values?.startDate !== values?.endDate
                ? `Du ${new Date(values?.startDate).toLocaleDateString()} au ${new Date(
                    values?.endDate,
                  ).toLocaleDateString()}`
                : values?.startDate
                  ? `À partir du ${new Date(values?.startDate).toLocaleDateString()}`
                  : values?.endDate
                    ? `Ce termine le ${new Date(values?.endDate).toLocaleDateString()}`
                    : "Date à définir"}
          </span>
        </div>
      )}

      {/* Description */}
      {reviewing ? (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Description :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {values.description
              ? values.description.replace(/<[^>]+>/g, "").substring(0, 60) +
                (values.description.replace(/<[^>]+>/g, "").length > 60 ? "..." : "")
              : ""}
          </span>
        </div>
      ) : (
        <InputDescription
          value={values.description}
          onChange={(desc) => setValues({ ...values, description: desc })}
          label="Décrivez votre offre :"
          required
          placeholder="Description"
        />
      )}

      {/* Documents */}
      <div>
        {!reviewing ? (
          <label htmlFor="" className="text-gray-700 font-semibold block mb-2">
            {"Ajouter un document "}
            <span className="text-xs font-normal italic text-gray-500">
              {"(le programme de la formation, le règlement intérieur, etc.)"}
            </span>
          </label>
        ) : values.documents?.length && reviewing ? (
          <label htmlFor="" className="text-gray-600 block mb-2">
            {"Documents :"}
          </label>
        ) : null}

        <div>
          {Array.isArray(values?.documents) &&
            values?.documents
              ?.filter((doc: any) => doc)
              .map(({ name, id, type, url }: any) => (
                <div key={`documents-${id}`} className="flex my-2">
                  <div className="bg-gray-100 flex rounded-lg p-2 items-center gap-2">
                    {type?.startsWith("image/") ? (
                      <Image src={url || "/placeholder.svg"} alt={name} width={20} height={20} className="rounded" />
                    ) : type?.startsWith("video/") ? (
                      <Video className="w-5 h-5 text-gray-600" />
                    ) : (
                      <Image src={"/assets/images/offerJob/upload.svg"} alt="logo document" width={20} height={20} />
                    )}
                    <p className="text-sm text-gray-700">{name}</p>
                    <button
                      type="button"
                      className="ml-2 text-red-500 hover:text-red-700"
                      onClick={() => {
                        setValues((prevValues: any) => ({
                          ...prevValues,
                          documents: prevValues.documents.filter((doc: any) => doc.id !== id),
                        }))
                      }}
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
        </div>

        {!reviewing && (
          <div className="w-full">
            <div className="flex relative flex-wrap size-full gap-2 justify-center items-center">
              <div className="flex flex-col">
                <div className="form-control">
                  <label className="label size-32 w-full hover:cursor-pointer hover:opacity-70 flex border-dashed border-2 border-gray-300 rounded-lg items-center justify-center">
                    <input
                      type="file"
                      accept="image/*,video/*,.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx"
                      multiple
                      onChange={handleDocumentChange}
                      className="hidden"
                    />
                    <span className="label-text">
                      <span className="text-gray-600 flex gap-2 items-center flex-col">
                        <span className="size-8">{addSvg}</span>
                        <span className="text-nowrap text-sm">{"Ajouter un fichier"}</span>
                      </span>
                    </span>
                  </label>
                </div>
              </div>
            </div>

            {previewUrls.length > 0 && (
              <div className="mt-4">
                <h3 className="text-sm font-bold mb-3 text-gray-700">Fichiers téléchargés</h3>
                <div className="flex flex-wrap items-center gap-4">
                  {previewUrls.map((url, index) => (
                    <div key={index} className="relative w-24 h-24">
                      <a href={url} target="_blank" rel="noopener noreferrer">
                        {medias[index].type.startsWith("image/") ? (
                          <img
                            src={url || "/placeholder.svg"}
                            alt={`Preview ${index}`}
                            className="w-full h-full object-cover rounded-lg border-2 border-gray-200"
                          />
                        ) : medias[index].type.startsWith("video/") ? (
                          <div className="w-full h-full bg-gray-900 rounded-lg flex items-center justify-center">
                            <Video className="w-8 h-8 text-white" />
                          </div>
                        ) : (
                          <div className="w-full h-full bg-gray-100 rounded-lg flex items-center justify-center">
                            <span className="text-xs text-gray-600 text-center p-1">{medias[index].name}</span>
                          </div>
                        )}
                      </a>
                      <button
                        type="button"
                        onClick={() => {
                          setPreviewUrls(previewUrls.filter((_, i) => i !== index))
                          setMedias(medias.filter((_, i) => i !== index))
                        }}
                        className="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Site web */}
      {!reviewing ? (
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Site web de l'organisme</label>
          <input
            type="url"
            name="website"
            value={values?.website || ""}
            onChange={onChange}
            placeholder="ex : https://www.websitepromo/code-save-10/"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Site web :</span>
          <span className="font-semibold text-gray-900 md:col-span-2 break-words">
            {values?.website && values.website.length > 50 ? values.website.substring(0, 50) + "..." : values?.website}
          </span>
        </div>
      )}

      {/* Certifications */}
      {!reviewing ? (
        <div className="my-2">
          <label htmlFor="" className="font-semibold text-gray-700 flex items-center gap-2 mb-2">
            {"Êtes-vous certifié ?"}
          </label>
          <div className="flex flex-col h-32 overflow-auto bg-gray-50 rounded-lg p-2">
            {["Qualiopi", "Datadock"].map((certification) => (
              <div key={`certification-${certification}`} className="flex items-center py-1">
                <input
                  type="checkbox"
                  onChange={(event) => {
                    const isChecked = event.target.checked
                    setValues((prevValues: any) => ({
                      ...prevValues,
                      certification: Array.isArray(prevValues.certification)
                        ? isChecked
                          ? [...prevValues.certification, certification]
                          : prevValues.certification.filter((value: any) => value !== certification)
                        : isChecked
                          ? [certification]
                          : [],
                    }))
                  }}
                  checked={Array.isArray(values?.certification) && values.certification.includes(certification)}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span className="mx-2 text-gray-700">{certification}</span>
              </div>
            ))}

            {Array.isArray(values?.certification) &&
              values.certification
                .filter((certification: string) => !["Qualiopi", "Datadock"].includes(certification))
                .map((certification: string, index: number) => (
                  <div key={`customCertification-${index}`} className="flex items-center mt-2 gap-2">
                    <input
                      type="text"
                      value={certification}
                      onChange={(event) => {
                        const newCertification = event.target.value
                        setValues((prevValues: any) => {
                          const updatedCertifications = [
                            ...(Array.isArray(prevValues.certification) ? prevValues.certification : []),
                          ]
                          const baseIndex = 2 + index
                          updatedCertifications[baseIndex] = newCertification
                          return {
                            ...prevValues,
                            certification: updatedCertifications,
                          }
                        })
                      }}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    />
                    <button
                      type="button"
                      className="text-red-500 hover:text-red-700"
                      onClick={() => {
                        setValues((prevValues: any) => ({
                          ...prevValues,
                          certification: Array.isArray(prevValues.certification)
                            ? prevValues.certification.filter((c: string) => c !== certification)
                            : [],
                        }))
                      }}
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}

            <div className="flex items-center mt-2 gap-2">
              <input
                type="text"
                placeholder="Ajouter une certification"
                ref={inputRef}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                onKeyDown={(event) => {
                  if (event.key === "Enter" && inputRef.current && inputRef.current.value.trim() !== "") {
                    const newCertification = inputRef.current.value.trim()
                    if (!Array.isArray(values.certification)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        certification: [newCertification],
                      }))
                    } else if (!values.certification.includes(newCertification)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        certification: [...prevValues.certification, newCertification],
                      }))
                    }
                    inputRef.current.value = ""
                  }
                }}
              />
              <button
                type="button"
                className="px-4 py-2 text-green-600 border border-green-600 rounded-lg hover:bg-green-50 transition-colors"
                onClick={() => {
                  if (inputRef.current && inputRef.current.value.trim() !== "") {
                    const newCertification = inputRef.current.value.trim()
                    if (!Array.isArray(values.certification)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        certification: [newCertification],
                      }))
                    } else if (!values.certification.includes(newCertification)) {
                      setValues((prevValues: any) => ({
                        ...prevValues,
                        certification: [...prevValues.certification, newCertification],
                      }))
                    }
                    inputRef.current.value = ""
                  }
                }}
              >
                Ajouter +
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span className="text-gray-600">Certifications :</span>
          <span className="font-semibold text-gray-900 md:col-span-2">
            {Array.isArray(values.certification) ? values.certification.join(", ") : ""}
          </span>
        </div>
      )}

      {/* Lieu - Masqué pour les formations en ligne (Elearning) */}
      {values.trainingType !== "Elearning" && (
        <>
          {!reviewing ? (
            <div>
              <Input.Autocomplete
                label="Lieu"
                helperText="Précisez la ville/région où cette offre est valide"
                address={values?.address}
                setAddress={(address: any) => setValues((values: any) => ({ ...values, address }))}
                extraClass="w-full"
                cities={citiesData}
              />
              <div className="flex items-center gap-2 mt-2">
                <input
                  type="checkbox"
                  id="show"
                  name="show"
                  checked={isShow}
                  onChange={(event: any) => {
                    const isChecked = event?.target?.checked
                    setValues((prevValues: any) => ({
                      ...prevValues,
                      show: isChecked,
                    }))
                    setIsShow(isChecked)
                  }}
                  className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <label htmlFor="show" className="text-sm text-gray-700 cursor-pointer">
                  Afficher la localisation Google sur l'annonce.
                </label>
              </div>
            </div>
          ) : (
            <div className="grid md:grid-cols-3 w-full gap-2 my-2">
              <span className="text-gray-600">Adresse :</span>
              <span className="font-semibold text-gray-900 md:col-span-2">
                {values?.address?.country
                  ? `${values?.address?.line1 || ""}${values?.address?.line1 ? "," : ""}
            ${values?.address?.line2 || ""}${values?.address?.line2 ? "," : ""}
            ${values?.address?.line3 || ""}${values?.address?.line3 ? "," : ""}
            ${values?.address?.zipcode || ""} ${values?.address?.zipcode ? "," : ""}
            ${values?.address?.city || ""}${values?.address?.city ? "," : ""}
             ${values?.address?.country || ""}`
                  : ""}
              </span>
            </div>
          )}
        </>
      )}
    </div>
  )
}

function TrainingFormDetailsStep({ values, setValues, reviewing }: any) {
  return null
}

function TrainingFormMediaStep({ values, setValues }: any) {
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

  return (
    <div className="space-y-6">
      <div className="text-center mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Ajoutez des photos et vidéos</h3>
        <p className="text-sm text-gray-600">
          Illustrez votre formation avec des images et vidéos pour la rendre plus attractive
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

function TrainingFormReviewStep({ values, setStep, setValues }: any) {
  const [expandedItems, setExpandedItems] = useState<{ [key: string]: boolean }>({})
  const [acceptMessages, setAcceptMessages] = useState(values.acceptMessages || false)

  // Determine if dates are defined or not for review
  const datesDefined = values.startDate || values.endDate || values.dateToDefine

  const toggleExpand = (key: string) => {
    setExpandedItems((prev) => ({ ...prev, [key]: !prev[key] }))
  }

  const truncateText = (text: string, maxLength = 60) => {
    if (!text) return "Non renseigné"
    if (text.length <= maxLength) return text
    return text.substring(0, maxLength) + "..."
  }

  const sections = [
    {
      title: "Informations générales",
      step: 1,
      items: [
        { label: "Type", value: (labelObject as any)[values.trainingType] || values.trainingType },
        { label: "Catégorie", value: (labelObject as any)[values.trainingCategory] || values.trainingCategory },
        { label: "Secteur", value: (labelObject as any)[values.trainingSubCategory] || values.trainingSubCategory },
      ],
    },
    // Description section simplified
    {
      title: "Description",
      step: 3, // Corresponds to the Description step
      items: [
        {
          label: "Titre",
          value: values.title,
          key: "title",
          expandable: values.title?.length > 60,
        },
        {
          label: "Description",
          value: values.description?.replace(/<[^>]+>/g, ""),
          key: "description",
          expandable: values.description?.replace(/<[^>]+>/g, "").length > 100,
        },
      ],
    },
    // Updated "Détails" section to include new fields and removed old ones
    {
      title: "Détails",
      step: 3, // Corresponds to the Description step which now contains these details
      items: [
        // Type d'enseignement
        {
          label: "Type d'enseignement",
          value: values.trainingStyle.includes(teachingTypes.find((name: any) => name === "Indifferent"))
            ? "Tout"
            : teachingTypes
                .filter((id: any) => values?.trainingStyle.includes(id))
                .map((name: any) => (labelObject as any)[name] || name)
                .join(", "),
          key: "trainingStyle",
          expandable: true,
        },
        // Public visé
        {
          label: "Public visé",
          value: values.trainingPublic.includes(targetPublics.find((name: any) => name === "AllPublic"))
            ? "Tout public"
            : targetPublics
                .filter((id: any) => values?.trainingPublic.includes(id))
                .map((name: any) => (labelObject as any)[name] || name)
                .join(", "),
          key: "trainingPublic",
          expandable: true,
        },
        // Niveau requis
        {
          label: "Niveau requis",
          value: Array.isArray(values.requiredLevels) ? values.requiredLevels.join(", ") : "",
          key: "requiredLevels",
          expandable: true,
        },
        // Prix de la formation
        {
          label: "Prix",
          value:
            values.priceType === "5"
              ? "Devis sur-mesure"
              : values.priceType === "4" || values.price === 0
                ? "Gratuit"
                : `${values.price}€${(() => {
                    switch (values.priceType) {
                      case "1":
                        return " NET"
                      case "2":
                        return " HT"
                      case "3":
                        return " TTC"
                      default:
                        return ""
                    }
                  })()}${(() => {
                    switch (values.duration) {
                      case "0":
                        return " /h"
                      case "1":
                        return " /j"
                      case "2":
                        return " /s"
                      case "3":
                        return " /m"
                      case "4":
                        return " /a"
                      default:
                        return ""
                    }
                  })()} ${values.public ? `/${values.public}` : ""} ${
                    values.tempo && values.tempo !== "all" ? `/${values.tempo}` : ""
                  }`,
          key: "price",
          expandable: true,
        },
        // Financement
        {
          label: "Financement",
          value: values.trainingFunding.includes(fundings.find((name: any) => name === "Indifferent"))
            ? "Indifferent"
            : fundings
                .filter((id: any) => values?.trainingFunding.includes(id))
                .map((name: any) => (labelObject as any)[name] || name)
                .join(", "),
          key: "trainingFunding",
          expandable: true,
        },
        // Durée de la formation
        {
          label: "Durée",
          value: values?.durationInH
            ? `${Math.round(values?.durationInH)} ${
                values?.duration === "0"
                  ? "heure(s)"
                  : values?.duration === "1"
                    ? "jour(s)"
                    : values?.duration === "2"
                      ? "semaines"
                      : values?.duration === "3"
                        ? "mois"
                        : values?.duration === "4"
                          ? "ans"
                          : ""
              }`
            : "Non spécifié",
          key: "duration",
          expandable: true,
        },
        // Dates
        {
          label: "Date",
          // Display "Date à définir" correctly in review
          value:
            values.dateToDefine || (!values.startDate && !values.endDate)
              ? "Date à définir"
              : values.startDate && values.endDate && values.startDate !== values.endDate
                ? `Du ${new Date(values.startDate).toLocaleDateString()} au ${new Date(
                    values.endDate,
                  ).toLocaleDateString()}`
                : values.startDate
                  ? `À partir du ${new Date(values.startDate).toLocaleDateString()}`
                  : values.endDate
                    ? `Ce termine le ${new Date(values.endDate).toLocaleDateString()}`
                    : "Date à définir",
          key: "dates",
          expandable: true,
        },
        // Site web
        {
          label: "Site web",
          value: values.website,
          key: "website",
          expandable: values.website?.length > 60,
        },
        // Certifications
        {
          label: "Certifications",
          value: Array.isArray(values.certification) ? values.certification.join(", ") : "Non spécifié",
          key: "certification",
          expandable: true,
        },
        // Lieu - Masqué pour les formations en ligne (Elearning)
        ...(values.trainingType !== "Elearning" ? [{
          label: "Lieu",
          value: values?.address?.country
            ? `${values?.address?.line1 || ""}${values?.address?.line1 ? "," : ""}
            ${values?.address?.line2 || ""}${values?.address?.line2 ? "," : ""}
            ${values?.address?.line3 || ""}${values?.address?.line3 ? "," : ""}
            ${values?.address?.zipcode || ""} ${values?.address?.zipcode ? "," : ""}
            ${values?.address?.city || ""}${values?.address?.city ? "," : ""}
             ${values?.address?.country || ""}`
            : "Non spécifié",
          key: "address",
          expandable: true,
        }] : []),
      ].filter(Boolean),
    },
    {
      title: "Médias",
      step: 4, // Corresponds to the Media step
      items: [{ label: "Photos et vidéos", value: `${values.media?.length || 0} fichier(s)` }],
    },
  ]

  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Check className="w-8 h-8 text-green-600" />
        </div>
        <h3 className="text-2xl font-bold text-gray-900 mb-2">Vérifiez votre annonce</h3>
        <p className="text-gray-600">Relisez les informations avant de publier votre formation</p>
      </div>

      {sections.map((section, sectionIndex) => (
        <motion.div
          key={sectionIndex}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: sectionIndex * 0.1 }}
          className="bg-gray-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-gray-900">{section.title}</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setStep(section.step)}
              className="text-green-600 hover:text-green-700 hover:bg-green-50"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="space-y-3">
            {section.items.map((item: any, itemIndex) => {
              const isExpanded = expandedItems[item.key]
              const displayValue =
                item.expandable && !isExpanded
                  ? truncateText(item.value, item.key === "description" ? 100 : 60)
                  : item.value || "Non renseigné"

              return (
                <div key={itemIndex} className="flex justify-between items-start gap-4">
                  <span className="text-sm text-gray-600 font-medium flex-shrink-0">{item.label}</span>
                  <div className="flex flex-col items-end flex-1 min-w-0">
                    <span className="text-sm text-gray-900 font-semibold text-right break-words w-full">
                      {displayValue}
                    </span>
                    {item.expandable && (
                      <button
                        onClick={() => toggleExpand(item.key)}
                        className="text-xs text-green-600 hover:text-green-700 mt-1 font-medium"
                      >
                        {isExpanded ? "Voir moins" : "Voir plus"}
                      </button>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        </motion.div>
      ))}

      {values.media && values.media.length > 0 && (
        <div className="bg-gray-50 rounded-xl p-6">
          <h4 className="text-lg font-semibold text-gray-900 mb-4">Aperçu des médias</h4>
          <div className="grid grid-cols-3 md:grid-cols-4 gap-3">
            {values.media.map((media: any, index: number) => (
              <div key={index} className="relative rounded-lg overflow-hidden border-2 border-gray-200">
                {media.type === "image" ? (
                  <img
                    src={media.url || "/placeholder.svg"}
                    alt={`Media ${index + 1}`}
                    className="w-full h-24 object-cover"
                  />
                ) : (
                  <div className="w-full h-24 bg-gray-900 flex items-center justify-center">
                    <Video className="w-6 h-6 text-white" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Documents Review */}
      {values.documents && values.documents.length > 0 && (
        <div className="bg-gray-50 rounded-xl p-6">
          <h4 className="text-lg font-semibold text-gray-900 mb-4">Documents</h4>
          <div className="space-y-2">
            {values.documents.map(({ name, id, type, url }: any) => (
              <div key={`documents-${id}`} className="flex items-center gap-3">
                {type?.startsWith("image/") ? (
                  <Image src={url || "/placeholder.svg"} alt={name} width={30} height={30} className="rounded" />
                ) : type?.startsWith("video/") ? (
                  <Video className="w-6 h-6 text-gray-600" />
                ) : (
                  <Image src={"/assets/images/offerJob/upload.svg"} alt="logo document" width={30} height={30} />
                )}
                <p className="text-sm text-gray-700 flex-1">{name}</p>
                <Link
                  href={url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-green-600 hover:underline"
                >
                  Voir
                </Link>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-6">
        <div className="flex items-start gap-4">
          <input
            type="checkbox"
            id="acceptMessages"
            checked={acceptMessages}
            onChange={(e) => {
              setAcceptMessages(e.target.checked)
              setValues({ ...values, acceptMessages: e.target.checked })
            }}
            className="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500 mt-1"
          />
          <label htmlFor="acceptMessages" className="flex-1 cursor-pointer">
            <span className="font-semibold text-gray-900 block mb-1">
              Accepter de recevoir des messages concernant cette annonce
            </span>
            <span className="text-sm text-gray-600">
              Les autres utilisateurs pourront vous contacter pour poser des questions sur cette formation
            </span>
          </label>
        </div>
      </div>
    </div>
  )
}

function TrainingForm() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const { setAdFormStep: setStep, adFormStep: step } = useAdForm()
  const { checkAdPermission } = usePermissions()
  const { openProPlanModal } = useProPlanModal()
  const { userData, loading: userLoading } = useUserData()

  const [values, setValues] = useState(defaultValues)
  const [loading, setLoading] = useState(false)
  const [id, setId] = useState<string | null>(null)
  const [isEditMode, setIsEditMode] = useState(false)
  const [mysCongratsModalOpen, setMysCongratsModalOpen] = useState<boolean>(false)
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([])
  const [existingImages, setExistingImages] = useState<Array<{ id: string; url: string }>>([])
  const [previewUrls, setPreviewUrls] = useState<string[]>([])

  useEffect(() => {
    const announcementId = searchParams.get("id")
    if (announcementId) {
      setId(announcementId)
      setIsEditMode(true)
      fetchAnnouncement(announcementId)
    }
  }, [searchParams])

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

  const fetchAnnouncement = async (announcementId: string) => {
    try {
      setLoading(true)
      const { fetchAnnouncementDetail, fetchDealImages } = await import("@/lib/api/deals")
      const announcement = await fetchAnnouncementDetail(announcementId)

      if (announcement) {
        setValues({
          ...defaultValues,
          ...announcement,
        })

        // Charger les images existantes
        const imagesData = await fetchDealImages(announcementId)
        if (imagesData.success) {
          const records = (imagesData.records as Array<{ id: string; url: string }>) || []
          setExistingImages(records.filter((record) => record.id && record.url))
          const imageUrls = records.map((record) => {
            const url = record.url
            if (url.startsWith("http://") || url.startsWith("https://")) {
              return url
            }
            const normalizedPath = url.startsWith("/") ? url : `/${url}`
            const patchedPath = normalizedPath.replace("/ads/", "/annonces/")
            return `${config.API_URL}${patchedPath}`
          })
          setPreviewUrls(imageUrls)
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

  useEffect(() => {
    const userId = localStorage.getItem("profileId")
    if (!userId) {
      router.replace("/")
    }
  }, [router])

  const handleNext = () => {
    console.log("[v0] Moving to next step, current step:", step)
    setStep((prevStep: number) => prevStep + 1)
    handleScroll()
  }

  const handlePrevious = () => {
    console.log("[v0] Moving to previous step, current step:", step)
    setStep((prevStep: number) => prevStep - 1)
    handleScroll()
  }

  const handleScroll = () => {
    const stepper = document.getElementById("custom-stepper")
    if (stepper) {
      const scrollPosition = stepper.offsetTop - 100
      window.scrollTo({
        top: scrollPosition,
        behavior: "smooth",
      })
    }
  }

  const isNextStepDisabled = () => {
    if (step === 1) {
      return !(values?.trainingType && values?.trainingCategory && values?.trainingSubCategory)
    }
    if (step === 2) {
      return false
    }
    if (step === 3) {
      return !(
        values?.title &&
        values?.trainingStyle?.length > 0 &&
        values?.trainingPublic?.length > 0 &&
        values?.requiredLevels?.length > 0 &&
        values?.priceType &&
        values?.trainingFunding?.length > 0 &&
        values?.description
      )
    }
    if (step === 4) {
      return false
    }
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

    try {
      // const adPermission = await checkAdPermission(userId)
      // if (!adPermission.canCreateAd && profileType === "professionnel") {
      //   toastError(`Vous avez atteint votre limite d'annonces ce mois-ci. Passez au Premium pour publier en illimité !`)
      //   openProPlanModal()
      //   return
      // }
    } catch (error: any) {
      // Silently continue if API is not accessible (preview environment limitation)
      // Only log if it's not a 404 error
      if (error?.response?.status !== 404) {
        console.error("[v0] Error checking ad permission:", error)
      }
    }

    onSubmit()
  }

  const onSubmit = async () => {
    setLoading(true)

    try {
      const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : undefined

      if (!userId) {
        toastError("Vous devez être connecté pour publier une annonce.")
        setLoading(false)
        return
      }

      console.log("[v0] Values before submit:", values)
      console.log("[v0] Title value:", values.title)
      console.log("[v0] Description value:", values.description)

      const response = await axios.post(
        `${config.API_URL}/Ads.php`,
        {
          userId: userId,
          title: values.title,
          description: values.description,
          trainingType: values.trainingType,
          trainingCategory: values.trainingCategory,
          trainingSubCategory: values.trainingSubCategory,
          trainingStyle: values.trainingStyle,
          trainingPublic: values.trainingPublic,
          requiredLevels: values.requiredLevels,
          price: values.price,
          priceType: values.priceType,
          public: values.public,
          tempo: values.tempo,
          trainingFunding: values.trainingFunding,
          durationInH: values.durationInH,
          duration: values.duration,
          startDate: values.dateToDefine ? null : values.startDate,
          endDate: values.dateToDefine ? null : values.endDate,
          dateToDefine: values.dateToDefine || false,
          documents: values.documents,
          website: values.website,
          certification: values.certification,
          address: values.address,
          show: values.show,
          message: values.acceptMessages,
          category: "formations",
          ...(id
            ? {
                id: id,
                Method: "updateAnnonce",
              }
            : {
                Method: "create",
              }),
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      if (response.data.status === "success") {
        const annonceId = id ? id : response.data.id
        console.log("[v0] Announcement created/updated with ID:", annonceId)

        // Étape 2: Uploader les documents si ils existent
        if (values.documentsFiles && values.documentsFiles.length > 0) {
          try {
            console.log("[v0] Uploading", values.documentsFiles.length, "documents...")
            
            // Uploader les documents par batch pour éviter de dépasser la limite
            const batchSize = 3
            for (let i = 0; i < values.documentsFiles.length; i += batchSize) {
              const batch = values.documentsFiles.slice(i, i + batchSize)
              const formData = new FormData()
              
              batch.forEach((file, index) => {
                formData.append(`documents[]`, file)
              })
              formData.append("annonceId", annonceId)
               formData.append("user_id", userId)
               formData.append("category", "formations") 
              formData.append("Method", "create_ads_file")

              await axios.post(`${config.API_URL}/DocumentFiles.php`, formData, {
                headers: {
                  "Content-Type": "multipart/form-data",
                },
                maxContentLength: 50 * 1024 * 1024, // 50MB
                maxBodyLength: 50 * 1024 * 1024, // 50MB
              })
            }
            console.log("[v0] Documents uploaded successfully")
          } catch (docError) {
            console.error("[v0] Error uploading documents:", docError)
            toastError("Erreur lors de l'upload des documents")
          }
        }
         // Étape 3: Uploader les médias si ils existent
        if (values.media && values.media.length > 0) {
          try {
            console.log("[v0] Uploading", values.media.length, "media files...")
            
            // Uploader les médias avec media[] pour que le backend le traite comme un tableau
            const mediaFormData = new FormData()
            mediaFormData.append("annonceId", annonceId)
            mediaFormData.append("Method", "create")
            
            values.media.forEach((media) => {
              if (media.file) {
                mediaFormData.append("media[]", media.file)
              }
            })

            await axios.post(`${config.API_URL}/ImageAnnonce.php`, mediaFormData, {
              headers: {
                "Content-Type": "multipart/form-data",
              },
              maxContentLength: 50 * 1024 * 1024, // 50MB total
              maxBodyLength: 50 * 1024 * 1024, // 50MB total
            })
            console.log("[v0] Media files uploaded successfully")
          } catch (mediaError) {
            console.error("[v0] Error uploading media:", mediaError)
            toastError("Erreur lors de l'upload des médias")
          }
        }

        // Supprimer les images marquées pour suppression
        if (imagesToDelete.length > 0 && id) {
          await deleteAnnonceImages(imagesToDelete, annonceId)
          setImagesToDelete([])
        }

        // Étape 4: Attribuer les coins si c'est une nouvelle annonce
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

        // if (values.documentsFiles.length > 0) {
        //   const formData = new FormData()
        //   values.documentsFiles.forEach((file) => {
        //     formData.append("documents[]", file)
        //   })
        //   formData.append("annonceId", annonceId)
        //   formData.append("Method", "create_ads_file")

        //   await axios.post(`${config.API_API_URL}/DocumentFiles.php`, formData, {
        //     // Corrected API URL
        //     headers: {
        //       "Content-Type": "multipart/form-data",
        //     },
        //   })
        // }

        // if (values.media.length > 0) {
        //   const mediaFormData = new FormData()
        //   values.media.forEach((media, index) => {
        //     if (media.file) {
        //       mediaFormData.append(`media[${index}][file]`, media.file)
        //       mediaFormData.append(`media[${index}][type]`, media.type)
        //     }
        //   })
        //   mediaFormData.append("annonceId", annonceId)
        //   mediaFormData.append("Method", "create")

        //   await axios.post(`${config.API_URL}/ImageAnnonce.php`, mediaFormData, {
        //     // Corrected API URL
        //     headers: {
        //       "Content-Type": "multipart/form-data",
        //     },
        //   })
        // }

        // if (!id) {
        //   await axios.post(
        //     `${config.API_URL}/HistoryCoins.php`,
        //     {
        //       userId,
        //       valueCoin: 2,
        //       eventName: "publish_ad",
        //       description: "Coins added for: publish_ad",
        //       generateBy: "system_event",
        //       Method: "create_history_coin",
        //     },
        //     {
        //       headers: {
        //         "Content-Type": "application/x-www-form-urlencoded",
        //       },
        //     },
        //   )
        // }

        // Afficher le message de succès
        toastSuccess(id ? "Annonce formation modifiée avec succès" : "Annonce formation publiée avec succès")
        
        // Passer à l'étape finale et afficher la modal si nouvelle annonce
        setStep(6)
        if (!id) {
          setMysCongratsModalOpen(true)
          // Déclencher l'événement pour rafraîchir les limites d'annonces
          window.dispatchEvent(new Event('adCreated'))
        }
      } else {
        // Si le status n'est pas "success", afficher l'erreur
        console.error("[v0] API returned non-success status:", response.data)
        toastError(response.data.message || (id ? "Erreur lors de la mise à jour de l'annonce." : "Erreur lors de la création de l'annonce."))
      }
    } catch (e: any) {
      console.error("[v0] Error submitting announcement:", e)
      if (e.response?.status === 404) {
        toastError(
          "L'API n'est pas accessible depuis l'environnement de prévisualisation. Le code fonctionnera correctement une fois déployé.",
        )
      } else {
        toastError("Une erreur est survenue lors de la soumission")
      }
    } finally {
      setLoading(false)
    }
  }

  if (userLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-cyan-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-green-600" />
      </div>
    )
  }

  if (step === 6) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-cyan-50 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center"
        >
          <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <Check className="w-10 h-10 text-green-600" />
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-4">
            {id ? "Votre annonce a bien été modifiée" : "Votre annonce a bien été publiée"}
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

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-cyan-50">
      <MysCongratsModal
        isOpen={mysCongratsModalOpen}
        onClose={() => setMysCongratsModalOpen(false)}
        content={
          <>
            Vous avez gagné <span className="text-green-600 font-bold">2 my's</span> suite à votre publication de
            formation.
          </>
        }
      />

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
                {id ? "Modifier une formation" : "Créer une formation"}
              </h1>
              <p className="text-sm text-gray-600">Partagez une opportunité de formation avec la communauté</p>
            </div>
          </div>
        </div>
      </div>

      <div id="custom-stepper" className="container mx-auto px-4 py-8">
        <div className="max-w-3xl mx-auto">
          <Stepper
            steps={[
              { nb: 1, label: "Type" },
              { nb: 2, label: "France Travail" },
              { nb: 3, label: "Description" },
              { nb: 4, label: "Photos" },
              { nb: 5, label: id ? "Revoir & Modifier" : "Revoir & Poster" },
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
            {step === 1 && <TrainingFormFirstStep values={values} setValues={setValues} reviewing={false} />}
            {step === 2 && (
              <TrainingFormScrappingStep values={values} onChangeValues={setValues} handleNext={handleNext} />
            )}
            {step === 3 && <TrainingFormDescriptionStep values={values} setValues={setValues} reviewing={false} />}
            {step === 4 && <TrainingFormMediaStep values={values} setValues={setValues} />}
            {step === 5 && <TrainingFormReviewStep values={values} setStep={setStep} setValues={setValues} />}
          </motion.div>

          {step < 5 && (
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

          {step === 5 && (
            <div className="flex justify-center gap-4 mt-8">
              <Button variant="outline" disabled={loading} onClick={handlePrevious} className="px-8 bg-transparent">
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
                  <>{id ? "Modifier l'annonce" : "Publier l'annonce"}</>
                )}
              </Button>
            </div>
          )}

          {step < 5 && (
            <div className="mt-4">
              <p className="text-sm text-red-500">* Champ Obligatoire</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default function CreateTrainingPage() {
  return (
    <AdFormProvider>
      <TrainingForm />
    </AdFormProvider>
  )
}
