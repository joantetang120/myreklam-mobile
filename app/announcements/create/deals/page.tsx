"use client"

import type React from "react"
import { useRef, useState, useEffect } from "react"
import { motion } from "framer-motion"
import { ArrowLeft, Link2, Loader2, Upload, X, ImageIcon, Video, Check, Edit2 } from "lucide-react"
import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"
import axios from "axios"
import { Button } from "@/components/ui/button"
import { Stepper } from "@/components/ui/stepper"
import { Input } from "@/components/ui/input-select"
import { InputDescription } from "@/components/ui/input-description"
import { getScraping } from "@/lib/api/scraping"
import { AdFormProvider, useAdForm } from "@/lib/contexts/ad-form-context"
import { labelObject } from "@/lib/constants/label-object"
import {
  dealTypes,
} from "@/lib/constants/deals-categories"
import { getCategoriesByType, type Category } from "@/lib/api/categories"
import citiesData from "@/lib/data/france-cities.json"
import { config } from "@/lib/config"
import { usePermissions } from "@/lib/hooks/use-permissions"
import { useProPlanModal } from "@/lib/hooks/use-pro-plan-modal"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import { AnnouncementSuccessModal } from "@/components/modals/announcement-success-modal"
import { ScrappingImagesSelector } from "@/components/announcements/scrapping-images-selector"
import {
  fetchAnnouncementDetail,
  fetchDealImages,
  uploadImages,
  createImageAnnouncementByUrlsAndAnnouncementId,
  type DealImageRecord,
} from "@/lib/api/deals"
import Switch from "react-switch";

const defaultValues = {
  title: "",
  description: "",
  dealType: "",
  dealCategory: "",
  subCategory: "",
  dealDeliveryType: "no_delivery",
  show: false,
  brand: "",
  initialPrice: 0,
  discountValue: 0,
  discountType: 1,
  finalPrice: 0,
  website: "",
  isOnline: false,
  shippingCost: 0,
  address: {},
  discountCode: "",
  drive: false,
  inStore: false,
  isDelivery: false,
  condition: "",
  tag: [],
  scrapping_images: [] as string[],
  message: false,
  startDate: "",
  endDate: "",
  media: [] as Array<{ type: "image" | "video"; url: string; file?: File }>,
  acceptMessages: false,
}

function DealFormFirstStep({ values, setValues, reviewing = false }: any) {
  const [categories, setCategories] = useState<Category[]>([])
  const [subCategories, setSubCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadCategories = async () => {
      try {
        setLoading(true)
        const response = await getCategoriesByType("bons_plans")
        if (response && response.data) {
          // Organiser les catégories principales
          const mainCategories = response.data.main || []
          setCategories(mainCategories)
          
          if (mainCategories.length === 0) {
            console.warn("[v0] No categories found for type 'bons_plans'. The database might not have categories for this type yet.")
          }
        } else {
          console.warn("[v0] Failed to load categories: response is null or invalid")
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
      if (!values.dealCategory) {
        setSubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("bons_plans")
        if (response && response.data) {
          // Trouver la catégorie principale sélectionnée
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === values.dealCategory || cat.id === values.dealCategory
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
        console.error("[v0] Error loading subcategories:", error)
        setSubCategories([])
      }
    }
    loadSubCategories()
  }, [values.dealCategory])

  const onChange = (evt: React.ChangeEvent<HTMLSelectElement | HTMLInputElement>) => {
    const newValues: any = {
      ...values,
      [evt?.target?.name]: evt?.target?.value,
    }
    
    // Réinitialiser la sous-catégorie si la catégorie change
    if (evt?.target?.name === "dealCategory") {
      newValues.subCategory = ""
    }
    
    setValues(newValues)
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
        label={!reviewing ? "Choisissez une catégorie :" : "Catégorie :"}
        name="dealCategory"
        onChange={onChange}
        required
        value={values.dealCategory || ""}
        reviewing={reviewing}
      >
        <option value="" disabled>
          Sélectionnez une catégorie
        </option>
        {categories.map((category) => (
          <option key={`dealCategory-${category.id}`} value={category.code}>
            {category.label}
          </option>
        ))}
      </Input.Select>

      <Input.Select
        label={!reviewing ? "Choisissez une sous-catégorie :" : "Sous-catégorie :"}
        name="subCategory"
        onChange={onChange}
        required
        value={values.subCategory || ""}
        reviewing={reviewing}
      >
        <option value="" disabled>
          {!values.dealCategory ? "Sélectionnez d'abord une catégorie" : subCategories.length === 0 ? "Aucune sous-catégorie disponible" : "Sélectionnez une sous-catégorie"}
        </option>
        {subCategories.map((sub) => (
          <option key={`dealSubCategory-${sub.id}`} value={sub.code}>
            {sub.label}
          </option>
        ))}
      </Input.Select>

      <Input.Select
        label={!reviewing ? "De quel type de bon plan s'agit-il ?" : "Type :"}
        name="dealType"
        required
        onChange={onChange}
        value={values?.dealType || ""}
        reviewing={reviewing}
      >
        <option value="" disabled>
          Sélectionnez un type de bon plan
        </option>
        {dealTypes.map((entry) => (
          <option key={`dealType-${entry}`} value={entry}>
            {(labelObject as any)[entry] || entry}
          </option>
        ))}
      </Input.Select>
    </div>
  )
}

function DealFormScrappingStep({ values, onChangeValues, setStep }: any) {
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
        setStep((prevStep: number) => prevStep + 1)
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
          Entrez le lien de la page où vous pouvez bénéficier de ce bon plan ou obtenir plus d'informations à son sujet.
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
            placeholder="https://www.example.com/bons-plans"
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
          onClick={() => setStep((prevStep: number) => prevStep + 1)}
        >
          Je n'ai pas de lien
        </button>
      </div>
    </motion.div>
  )
}

function DealFormThirdStep({ values, setValues, reviewing }: any) {
  const onChange = (evt: any) => {
    setValues({
      ...values,
      [evt?.target?.name]: evt?.target?.value,
    })
  }

  const inputRef = useRef<HTMLInputElement>(null)
  const [brand, setBrand] = useState<string>("")

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const input = e.target.value
    setBrand(input)

    const brandArray = input
      .split(",")
      .map((item) => item.trim())
      .filter((item) => item.length > 0)

    setValues({
      ...values,
      brand: brandArray,
    })
  }

  useEffect(() => {
    if (Array.isArray(values.brand)) {
      setBrand(values.brand.join(", "))
    } else if (typeof values.brand === "string") {
      const brand = values.brand
        .replace(/[{}]/g, "")
        .split(",")
        .map((str: any) => str.replace(/"/g, "").trim())

      setBrand(brand.join(", "))
      setValues((prev: any) => ({
        ...prev,
        brand,
      }))
    }
  }, [])

  return (
    <div className="space-y-6">
      <Input.Base
        step={2}
        reviewing={reviewing}
        onChange={onChange}
        required
        helperText="Quelque chose de court et percutant."
        type="text"
        name="title"
        placeholder="ex : 20% promo forfait free mobile"
        label={!reviewing ? "Quel est votre titre ?" : "Titre :"}
        value={values?.title}
      />

      {reviewing ? (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span>Description :</span>
          <div className="flex">
            <span className="font-semibold w-full">
              {values.description
                ? values.description.replace(/<[^>]+>/g, "").substring(0, 60) +
                  (values.description.replace(/<[^>]+>/g, "").length > 60 ? "..." : "")
                : ""}
            </span>
          </div>
        </div>
      ) : (
        <InputDescription
          value={values.description}
          onChange={(desc) => setValues({ ...values, description: desc })}
          label="Décrivez votre offre :"
          required
          placeholder="Description détaillée de votre bon plan..."
        />
      )}

      {!reviewing && (
        <Input.Base
          step={2}
          ref={inputRef}
          placeholder="Ex : Free, Samsung"
          name="brand"
          value={brand}
          onChange={handleChange}
          reviewing={reviewing}
          label="Bon plan disponible chez:"
        />
      )}

      {reviewing ? (
        <div className="grid md:grid-cols-3 w-full gap-2 my-2">
          <span>Disponible chez :</span>
          <span className="font-semibold">{brand}</span>
        </div>
      ) : (
        <Input.Select
          step={2}
          reviewing={reviewing}
          label="Où cette offre est-elle disponible ?"
          name="isOnline"
          onChange={(event: any) => {
            setValues({
              ...values,
              isOnline: event.target.value === "true",
            })
          }}
          value={values.isOnline?.toString() || "false"}
        >
          <option value="" disabled>
            En magasin, ...
          </option>
          <option value="false">En magasin</option>
          <option value="true">En Ligne</option>
        </Input.Select>
      )}
    </div>
  )
}

function DealFormSecondStep({ values, setValues, reviewing }: any) {
  const [isEmergent, setIsEmergent] = useState(true)
  const [dealDeliveryType, setDealDeliveryType] = useState(values?.dealDeliveryType || "no_delivery")
  const [isDrive, setIsDrive] = useState(values?.drive)
  const [isStore, setIsStore] = useState(values?.inStore)
  const [isDelivery, setIsDelivery] = useState(values?.isDelivery)
  const [remise, setRemise] = useState(values?.discountType || 1)
  const [selectedCity, setSelectedCity] = useState("")
  const [isShow, setIsShow] = useState(values?.show)
  const [offerType, setOfferType] = useState<"permanent" | "dated">(
    values.startDate || values.endDate ? "dated" : "permanent",
  )

  const onChange = (evt: any) => {
    setValues({
      ...values,
      [evt?.target?.name]: evt?.target?.value,
    })
  }

  useEffect(() => {
    if (values.startDate || values.endDate) {
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
      setIsEmergent(false)
    } else {
      setIsEmergent(true)
    }
  }, [values.endDate, values.startDate])

  useEffect(() => {
    if (values?.initialPrice && values?.finalPrice) {
      const discountPercentage = (
        Number(values?.discountType) === 2
          ? Number(values.initialPrice) - Number(values.finalPrice)
          : ((Number(values.initialPrice) - Number(values.finalPrice)) / Number(values.initialPrice)) * 100
      ).toFixed(2)

      setValues((prev: any) => ({
        ...prev,
        discountValue: discountPercentage,
      }))
    }
    setIsShow(values?.show)
  }, [values?.initialPrice, values?.finalPrice, values?.discountType, values?.show])

  if (reviewing) {
    return (
      <div className="space-y-4">
        {!["free", "info"].includes(values.dealType) && (
          <div className="grid md:grid-cols-3 w-full gap-2">
            <label className="font-semibold text-gray-700">Prix :</label>
            <p className="font-semibold">
              {values?.initialPrice && values?.finalPrice ? (
                <div>
                  <span className="line-through">{values.initialPrice + "€"}</span>
                  {` > Remise de ${values.discountValue}${Number(remise) === 2 ? "€" : "%"} > `}
                  <span className="bg-green-500 text-white rounded px-2 py-1">{values.finalPrice + "€"}</span>
                </div>
              ) : (
                <span className="bg-green-500 text-white rounded px-2 py-1">
                  {(values.finalPrice || values.initialPrice) + "€"}
                </span>
              )}
            </p>
          </div>
        )}
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {!["free", "info"].includes(values.dealType) && (
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-4">Prix :</label>
          <div className="grid md:grid-cols-3 gap-4 items-end">
            <Input.Price
              step={3}
              reviewing={reviewing}
              name="initialPrice"
              placeholder="Prix avant réduction"
              onChange={onChange}
              value={values?.initialPrice || ""}
              min={0}
            />
            <Input.Base
              step={3}
              reviewing={reviewing}
              name="discountValue"
              placeholder="Remise"
              onChange={onChange}
              value={values?.discountValue >= 0 ? values.discountValue : ""}
              type="number"
              disabled
            />
            <div className="space-y-2">
              <Input.Radio
                reviewing={reviewing}
                id="isPercentDiscount"
                name="discountType"
                checked={remise === 1}
                onChange={() => {
                  const discountPercentage = (
                    ((Number(values.initialPrice) - Number(values.finalPrice)) / Number(values.initialPrice)) *
                    100
                  ).toFixed(2)

                  setValues((prev: any) => ({
                    ...prev,
                    discountType: 1,
                    discountValue: discountPercentage,
                  }))
                  setRemise(1)
                }}
              >
                <span>%</span>
              </Input.Radio>

              <Input.Radio
                reviewing={reviewing}
                id="isEurDiscount"
                name="discountType"
                checked={remise === 2}
                onChange={() => {
                  const discountPercentage = (Number(values.initialPrice) - Number(values.finalPrice)).toFixed(2)

                  setValues((prev: any) => ({
                    ...prev,
                    discountType: 2,
                    discountValue: discountPercentage,
                  }))
                  setRemise(2)
                }}
              >
                <span>€</span>
              </Input.Radio>
            </div>
          </div>
          <Input.Price
            step={3}
            reviewing={reviewing}
            name="finalPrice"
            label="Prix final"
            onChange={onChange}
            placeholder="Prix après réduction"
            value={values?.finalPrice || ""}
            min={0}
          />
        </div>
      )}

      {values.isOnline === false && (
        <Input.Url
          step={3}
          onChange={onChange}
          name="website"
          placeholder="ex : www.websitepromo/code-save-10/"
          value={values?.website}
          label="Site web de l'enseigne:"
          helperText="Entrer le site web"
          reviewing={reviewing}
        />
      )}

      {values?.isOnline === true && (
        <div className="space-y-6">
          <div className="space-y-4">
            <label className="block text-sm font-semibold text-gray-700">Livraison :</label>
            <div className="px-4 space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-sm font-normal">Livraison gratuite</span>
                <Switch
                  checked={dealDeliveryType === "free_delivery"}
                  onChange={(checked) => {
                    if (checked) {
                      setValues({
                        ...values,
                        dealDeliveryType: "free_delivery",
                        shippingCost: 0,
                      });
                      setDealDeliveryType("free_delivery");
                    } else {
                      setValues({
                        ...values,
                        dealDeliveryType: "no_delivery",
                        shippingCost: 0,
                      });
                      setDealDeliveryType("no_delivery");
                    }
                  }}
                  onColor="#10b981"
                  offColor="#d1d5db"
                  height={24}
                  width={48}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <span className="text-sm font-normal">Frais de port</span>
                  {dealDeliveryType === "paid_delivery" && (
                    <Input.Price
                      step={3}
                      reviewing={reviewing}
                      name="shippingCost"
                      label=""
                      onChange={onChange}
                      placeholder="ex : 5.99"
                      value={values?.shippingCost || ""}
                      min={0}
                    />
                    
                  )}
                  
                </div>
                <Switch
                  checked={dealDeliveryType === "paid_delivery"}
                  onChange={(checked) => {
                    if (checked) {
                      setValues({
                        ...values,
                        dealDeliveryType: "paid_delivery",
                      });
                      setDealDeliveryType("paid_delivery");
                    } else {
                      setValues({
                        ...values,
                        dealDeliveryType: "no_delivery",
                        shippingCost: 0,
                      });
                      setDealDeliveryType("no_delivery");
                    }
                  }}
                  onColor="#10b981"
                  offColor="#d1d5db"
                  height={24}
                  width={48}
                />
              </div>
            </div>
          </div>

          <div className="bg-gray-50 p-6 rounded-xl space-y-4">
            <label className="block text-sm font-semibold text-gray-700">Comment l'obtenir ?</label>
            {values.dealType === "code" && (
              <Input.Base
                step={3}
                reviewing={reviewing}
                onChange={onChange}
                placeholder="ex : CODESAVE10X"
                label="Quel est le code promo ?"
                helperText="Facultatif"
                name="discountCode"
                value={values?.discountCode?.toUpperCase()}
              />
            )}
            <Input.Url
              step={3}
              reviewing={reviewing}
              onChange={onChange}
              placeholder="ex : www.websitepromo/code-save-10/"
              label="Où trouver le bon plan ?"
              helperText="Entrer le site web"
              name="website"
              value={values?.website}
            />
          </div>

          <div className="space-y-4">
            <label className="block text-sm font-semibold text-gray-700">Quand cette offre est-elle valide ?</label>

            <div className="space-y-3">
              <Input.Radio
                id="offer-permanent"
                name="offerType"
                checked={offerType === "permanent"}
                reviewing={reviewing}
                onChange={() => {
                  setOfferType("permanent")
                  setIsEmergent(true)
                  setValues({
                    ...values,
                    endDate: "",
                    startDate: "",
                  })
                }}
              >
                <span className="font-medium">Offre permanente</span>
                <span className="text-sm text-gray-500 block">Aucune date de fin</span>
              </Input.Radio>

              <Input.Radio
                id="offer-dated"
                name="offerType"
                checked={offerType === "dated"}
                reviewing={reviewing}
                onChange={() => {
                  setOfferType("dated")
                  setIsEmergent(false)
                }}
              >
                <span className="font-medium">Offre avec dates</span>
                <span className="text-sm text-gray-500 block">Définir une période de validité</span>
              </Input.Radio>
            </div>

            {offerType === "dated" && (
              <div className="grid md:grid-cols-2 gap-4 mt-4 pl-8">
                <Input.Date
                  reviewing={reviewing}
                  name="startDate"
                  label="À partir du :"
                  onChange={onChange}
                  value={values?.startDate}
                  max={values?.endDate}
                />
                <Input.Date
                  name="endDate"
                  label="Jusqu'au (facultatif) :"
                  onChange={onChange}
                  value={values?.endDate}
                  min={values?.startDate}
                />
              </div>
            )}
          </div>
        </div>
      )}

      {values?.isOnline === false && (
        <div className="space-y-6">
          <div className="space-y-4">
            <label className="block text-sm font-semibold text-gray-700">Quand cette offre est-elle valide ?</label>

            <div className="space-y-3">
              <Input.Radio
                id="offer-permanent-offline"
                name="offerTypeOffline"
                checked={offerType === "permanent"}
                reviewing={reviewing}
                onChange={() => {
                  setOfferType("permanent")
                  setIsEmergent(true)
                  setValues({
                    ...values,
                    endDate: "",
                    startDate: "",
                  })
                }}
              >
                <span className="font-medium">Offre permanente</span>
                <span className="text-sm text-gray-500 block">Aucune date de fin</span>
              </Input.Radio>

              <Input.Radio
                id="offer-dated-offline"
                name="offerTypeOffline"
                checked={offerType === "dated"}
                reviewing={reviewing}
                onChange={() => {
                  setOfferType("dated")
                  setIsEmergent(false)
                }}
              >
                <span className="font-medium">Offre avec dates</span>
                <span className="text-sm text-gray-500 block">Définir une période de validité</span>
              </Input.Radio>
            </div>

            {offerType === "dated" && (
              <div className="grid md:grid-cols-2 gap-4 mt-4 pl-8">
                <Input.Date
                  reviewing={reviewing}
                  name="startDate"
                  label="À partir du :"
                  onChange={onChange}
                  value={values?.startDate}
                  max={values?.endDate}
                />
                <Input.Date
                  name="endDate"
                  label="Jusqu'au (facultatif) :"
                  onChange={onChange}
                  value={values?.endDate}
                  min={values?.startDate}
                />
              </div>
            )}
          </div>

          <Input.Autocomplete
            label="Lieu"
            helperText="Commencez à taper un code postal ou un nom de ville"
            address={values?.address}
            setAddress={(address: any) => setValues((values: any) => ({ ...values, address }))}
            extraClass="w-full"
            disabled={selectedCity === "France"}
            cities={citiesData}
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

          <Input.Toggle
            onChange={(event: any) => {
              const isChecked = event?.target?.checked
              setValues((prevValues: any) => ({
                ...prevValues,
                show: isChecked,
              }))
              setIsShow(isChecked)
            }}
            name="show"
            label="Afficher la localisation Google sur l'annonce."
            value={isShow?.toString() || "false"}
            checked={isShow}
          />

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-4">
              Moyen de retrait :<span className="text-red-500 ml-1">*</span>
            </label>
            <div className="grid md:grid-cols-3 gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  id="isDrive"
                  name="drive"
                  checked={isDrive}
                  onChange={({ target: { checked } }) => {
                    setValues({
                      ...values,
                      drive: checked,
                    })
                    setIsDrive(checked)
                  }}
                  className="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span>Drive</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  id="isStore"
                  name="inStore"
                  checked={isStore}
                  onChange={({ target: { checked } }) => {
                    setValues({
                      ...values,
                      inStore: checked,
                    })
                    setIsStore(checked)
                  }}
                  className="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span>En magasin</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  id="isDelivery"
                  name="isDelivery"
                  checked={isDelivery}
                  onChange={({ target: { checked } }) => {
                    setValues({
                      ...values,
                      isDelivery: checked,
                    })
                    setIsDelivery(checked)
                  }}
                  className="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500"
                />
                <span>Livraison</span>
              </label>
            </div>
          </div>
        </div>
      )}

      <Input.Base
        step={3}
        reviewing={reviewing}
        onChange={onChange}
        placeholder="ex : nouveaux membres uniquement"
        name="condition"
        value={values?.condition}
        helperText="Facultatif"
        label="Conditions pour profiter de cette offre :"
      />
    </div>
  )
}

type DealFormMediaStepProps = {
  values: any
  setValues: (values: any) => void
  medias: File[]
  setMedias: (files: File[]) => void
  existingImages: DealImageRecord[]
  onRemoveExistingImage: (imageId: string) => void
}

function DealFormMediaStep({
  values,
  setValues,
  medias,
  setMedias,
  existingImages,
  onRemoveExistingImage,
}: DealFormMediaStepProps) {
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

     // AJOUT: Mettre à jour le state des médias pour l'upload
    const allFiles = [...medias, ...Array.from(files)]
    setMedias(allFiles)
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
    
    // AJOUT: Mettre à jour aussi le state des médias
    const updatedFiles = medias.filter((_: File, i: number) => i !== index)
    setMedias(updatedFiles)
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
            {existingImages.map((image) => (
              <div
                key={image.id}
                className="relative rounded-lg overflow-hidden border-2 border-gray-200 hover:border-red-400 transition"
              >
                <img src={getImageUrl(image.url)} alt="Image existante" className="w-full h-40 object-cover" />
                <button
                  type="button"
                  onClick={() => onRemoveExistingImage(image.id)}
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
          Illustrez votre bon plan avec des images et vidéos pour le rendre plus attractif
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

// function DealFormReviewStep({ values, setStep, setValues }: any) {
//   const [expandedItems, setExpandedItems] = useState<{ [key: string]: boolean }>({})
//   const [acceptMessages, setAcceptMessages] = useState(values.acceptMessages || false)

//   const toggleExpand = (key: string) => {
//     setExpandedItems((prev) => ({ ...prev, [key]: !prev[key] }))
//   }

//   const truncateText = (text: string, maxLength = 60) => {
//     if (!text) return "Non renseigné"
//     if (text.length <= maxLength) return text
//     return text.substring(0, maxLength) + "..."
//   }

//   const sections = [
//     {
//       title: "Informations générales",
//       step: 1,
//       items: [
//         { label: "Catégorie", value: (labelObject as any)[values.dealCategory] || values.dealCategory },
//         { label: "Sous-catégorie", value: (labelObject as any)[values.subCategory] || values.subCategory },
//         { label: "Type", value: (labelObject as any)[values.dealType] || values.dealType },
//       ],
//     },
//     {
//       title: "Description",
//       step: 3,
//       items: [
//         {
//           label: "Titre",
//           value: values.title,
//           key: "title",
//           expandable: values.title?.length > 60,
//         },
//         {
//           label: "Description",
//           value: values.description?.replace(/<[^>]+>/g, ""),
//           key: "description",
//           expandable: values.description?.replace(/<[^>]+>/g, "").length > 100,
//         },
//         {
//           label: "Marque(s)",
//           value: Array.isArray(values.brand) ? values.brand.join(", ") : values.brand,
//           key: "brand",
//           expandable: (Array.isArray(values.brand) ? values.brand.join(", ") : values.brand)?.length > 60,
//         },
//         { label: "Disponibilité", value: values.isOnline ? "En ligne" : "En magasin" },
//       ],
//     },
//     {
//       title: "Prix et détails",
//       step: 4,
//       items: [
//         !["free", "info"].includes(values.dealType) &&
//           values.initialPrice && {
//             label: "Prix initial",
//             value: `${values.initialPrice}€`,
//           },
//         !["free", "info"].includes(values.dealType) &&
//           values.finalPrice && {
//             label: "Prix final",
//             value: `${values.finalPrice}€`,
//           },
//         !["free", "info"].includes(values.dealType) &&
//           values.discountValue && {
//             label: "Réduction",
//             value: `${values.discountValue}${values.discountType === 2 ? "€" : "%"}`,
//           },
//         values.website && {
//           label: "Site web",
//           value: values.website,
//           key: "website",
//           expandable: values.website?.length > 60,
//         },
//         values.discountCode && { label: "Code promo", value: values.discountCode },
//         values.startDate && { label: "Date de début", value: values.startDate },
//         values.endDate && { label: "Date de fin", value: values.endDate },
//         !values.startDate && !values.endDate && { label: "Validité", value: "Offre permanente" },
//         values.address?.city && { label: "Localisation", value: values.address.city },
//         values.condition && {
//           label: "Conditions",
//           value: values.condition,
//           key: "condition",
//           expandable: values.condition?.length > 60,
//         },
//       ].filter(Boolean),
//     },
//     {
//       title: "Médias",
//       step: 5,
//       items: [{ label: "Photos et vidéos", value: `${values.media?.length || 0} fichier(s)` }],
//     },
//   ]

//   return (
//     <div className="space-y-6">
//       <div className="text-center mb-8">
//         <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
//           <Check className="w-8 h-8 text-green-600" />
//         </div>
//         <h3 className="text-2xl font-bold text-gray-900 mb-2">Vérifiez votre annonce</h3>
//         <p className="text-gray-600">Relisez les informations avant de publier votre bon plan</p>
//       </div>

//       {sections.map((section, sectionIndex) => (
//         <motion.div
//           key={sectionIndex}
//           initial={{ opacity: 0, y: 20 }}
//           animate={{ opacity: 1, y: 0 }}
//           transition={{ delay: sectionIndex * 0.1 }}
//           className="bg-gray-50 rounded-xl p-6"
//         >
//           <div className="flex items-center justify-between mb-4">
//             <h4 className="text-lg font-semibold text-gray-900">{section.title}</h4>
//             <Button
//               variant="ghost"
//               size="sm"
//               onClick={() => setStep(section.step)}
//               className="text-green-600 hover:text-green-700 hover:bg-green-50"
//             >
//               <Edit2 className="w-4 h-4 mr-2" />
//               Modifier
//             </Button>
//           </div>
//           <div className="space-y-3">
//             {section.items.map((item: any, itemIndex) => {
//               const isExpanded = expandedItems[item.key]
//               const displayValue =
//                 item.expandable && !isExpanded
//                   ? truncateText(item.value, item.key === "description" ? 100 : 60)
//                   : item.value || "Non renseigné"

//               return (
//                 <div key={itemIndex} className="flex justify-between items-start gap-4">
//                   <span className="text-sm text-gray-600 font-medium flex-shrink-0">{item.label}</span>
//                   <div className="flex flex-col items-end flex-1 min-w-0">
//                     <span className="text-sm text-gray-900 font-semibold text-right break-words w-full">
//                       {displayValue}
//                     </span>
//                     {item.expandable && (
//                       <button
//                         onClick={() => toggleExpand(item.key)}
//                         className="text-xs text-green-600 hover:text-green-700 mt-1 font-medium"
//                       >
//                         {isExpanded ? "Voir moins" : "Voir plus"}
//                       </button>
//                     )}
//                   </div>
//                 </div>
//               )
//             })}
//           </div>
//         </motion.div>
//       ))}

//       {values.media && values.media.length > 0 && (
//         <div className="bg-gray-50 rounded-xl p-6">
//           <h4 className="text-lg font-semibold text-gray-900 mb-4">Aperçu des médias</h4>
//           <div className="grid grid-cols-3 md:grid-cols-4 gap-3">
//             {values.media.map((media: any, index: number) => (
//               <div key={index} className="relative rounded-lg overflow-hidden border-2 border-gray-200">
//                 {media.type === "image" ? (
//                   <img
//                     src={media.url || "/placeholder.svg"}
//                     alt={`Media ${index + 1}`}
//                     className="w-full h-24 object-cover"
//                   />
//                 ) : (
//                   <div className="w-full h-24 bg-gray-900 flex items-center justify-center">
//                     <Video className="w-6 h-6 text-white" />
//                   </div>
//                 )}
//               </div>
//             ))}
//           </div>
//         </div>
//       )}

//       <div className="bg-blue-50 border-2 border-blue-200 rounded-xl p-6">
//         <div className="flex items-start gap-4">
//           <input
//             type="checkbox"
//             id="acceptMessages"
//             checked={acceptMessages}
//             onChange={(e) => {
//               setAcceptMessages(e.target.checked)
//               setValues({ ...values, acceptMessages: e.target.checked })
//             }}
//             className="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500 mt-1"
//           />
//           <label htmlFor="acceptMessages" className="flex-1 cursor-pointer">
//             <span className="font-semibold text-gray-900 block mb-1">
//               Accepter de recevoir des messages concernant cette annonce
//             </span>
//             <span className="text-sm text-gray-600">
//               Les autres utilisateurs pourront vous contacter pour poser des questions sur ce bon plan
//             </span>
//           </label>
//         </div>
//       </div>

//       <div className="bg-green-50 border-2 border-green-200 rounded-xl p-6 text-center">
//         <p className="text-green-800 font-medium mb-4">Votre bon plan est prêt à être publié !</p>
       
//       </div>
//     </div>
//   )
// }

function DealFormReviewStep({ values, setStep, setValues }: any) {
  const [expandedItems, setExpandedItems] = useState<{ [key: string]: boolean }>({})
  const [acceptMessages, setAcceptMessages] = useState(values.acceptMessages || false)

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
        { label: "Catégorie", value: (labelObject as any)[values.dealCategory] || values.dealCategory },
        { label: "Sous-catégorie", value: (labelObject as any)[values.subCategory] || values.subCategory },
        { label: "Type", value: (labelObject as any)[values.dealType] || values.dealType },
      ].filter(Boolean),
    },
    {
      title: "Description",
      step: 3,
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
        {
          label: "Marque(s)",
          value: Array.isArray(values.brand) ? values.brand.join(", ") : values.brand,
          key: "brand",
          expandable: (Array.isArray(values.brand) ? values.brand.join(", ") : values.brand)?.length > 60,
        },
        { label: "Disponibilité", value: values.isOnline ? "En ligne" : "En magasin" },
      ].filter(item => item.value),
    },
    {
      title: "Prix et détails",
      step: 4,
      items: [
        // Prix
        !["free", "info"].includes(values.dealType) && values.initialPrice && {
          label: "Prix initial",
          value: `${values.initialPrice}€`,
        },
        !["free", "info"].includes(values.dealType) && values.finalPrice && {
          label: "Prix final",
          value: `${values.finalPrice}€`,
        },
        !["free", "info"].includes(values.dealType) && values.discountValue && {
          label: "Réduction",
          value: `${values.discountValue}${values.discountType === 2 ? "€" : "%"}`,
        },
        
        // Site web
        values.website && {
          label: "Site web",
          value: values.website,
          key: "website",
          expandable: values.website?.length > 60,
        },
        
        // Code promo
        values.discountCode && { 
          label: "Code promo", 
          value: values.discountCode 
        },
        
        // Dates
        values.startDate && { 
          label: "Date de début", 
          value: new Date(values.startDate).toLocaleDateString("fr-FR")
        },
        values.endDate && { 
          label: "Date de fin", 
          value: new Date(values.endDate).toLocaleDateString("fr-FR")
        },
        !values.startDate && !values.endDate && { 
          label: "Validité", 
          value: "Offre permanente" 
        },
        
        // Localisation
        values.address?.city && { 
          label: "Localisation", 
          value: `${values.address.city}${values.address.zipcode ? `, ${values.address.zipcode}` : ''}` 
        },
        values.show && { 
          label: "Afficher la localisation", 
          value: "Oui" 
        },
        
        // Conditions
        values.condition && {
          label: "Conditions",
          value: values.condition,
          key: "condition",
          expandable: values.condition?.length > 60,
        },
        
        // Options de livraison/retrait pour en ligne
        values.isOnline && {
          label: "Type de livraison",
          value: values.dealDeliveryType === "free_delivery" 
            ? "Livraison gratuite" 
            : values.dealDeliveryType === "paid_delivery" 
            ? `Livraison payante (${values.shippingCost || 0}€)`
            : "Pas de livraison",
        },
        
        // Options de retrait pour magasin
        !values.isOnline && (values.drive || values.inStore || values.isDelivery) && {
          label: "Moyens de retrait",
          value: [
            values.drive && "Drive",
            values.inStore && "En magasin", 
            values.isDelivery && "Livraison"
          ].filter(Boolean).join(", "),
        },
        
        // Frais de port (si applicable)
        values.isOnline && values.shippingCost > 0 && {
          label: "Frais de port",
          value: `${values.shippingCost}€`,
        },
        
      ].filter(Boolean),
    },
    {
      title: "Médias",
      step: 5,
      items: [
        { 
          label: "Photos uploadées", 
          value: `${values.media?.length || 0} fichier(s)` 
        },
        values.scrapping_images?.length > 0 && {
          label: "Images du site web",
          value: `${values.scrapping_images.length} image(s) sélectionnée(s)`
        }
      ].filter(Boolean),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="text-center mb-8">
        <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <Check className="w-8 h-8 text-green-600" />
        </div>
        <h3 className="text-2xl font-bold text-gray-900 mb-2">Vérifiez votre annonce</h3>
        <p className="text-gray-600">Relisez les informations avant de publier votre bon plan</p>
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
              if (!item || !item.value) return null
              
              const isExpanded = expandedItems[item.key]
              const shouldTruncate = item.expandable && !isExpanded

              return (
                <div key={itemIndex} className="flex flex-col gap-1">
                  <div className="flex items-start justify-between">
                    <span className="text-sm font-medium text-gray-600 w-1/3">{item.label}:</span>
                    <div className="flex-1 text-right">
                      <span className="text-sm text-gray-900">
                        {shouldTruncate ? truncateText(item.value) : item.value}
                      </span>
                      {item.expandable && (
                        <button
                          onClick={() => toggleExpand(item.key)}
                          className="ml-2 text-xs text-green-600 hover:text-green-700"
                        >
                          {isExpanded ? "Voir moins" : "Voir plus"}
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        </motion.div>
      ))}

      {/* Aperçu des médias */}
      {values.media && values.media.length > 0 && (
        <div className="bg-gray-50 rounded-xl p-6">
          <h4 className="text-lg font-semibold text-gray-900 mb-4">Aperçu des médias uploadés</h4>
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

      {/* Aperçu des images de scrapping */}
      {values.scrapping_images && values.scrapping_images.length > 0 && (
        <div className="bg-gray-50 rounded-xl p-6">
          <h4 className="text-lg font-semibold text-gray-900 mb-4">Images sélectionnées du site web</h4>
          <div className="grid grid-cols-3 md:grid-cols-4 gap-3">
            {values.scrapping_images.map((imageUrl: string, index: number) => (
              <div key={index} className="relative rounded-lg overflow-hidden border-2 border-gray-200">
                <img
                  src={imageUrl}
                  alt={`Scrapped image ${index + 1}`}
                  className="w-full h-24 object-cover"
                />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Toggle pour les messages */}
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
              Les autres utilisateurs pourront vous contacter pour poser des questions sur ce bon plan
            </span>
          </label>
        </div>
      </div>

      <div className="bg-green-50 border-2 border-green-200 rounded-xl p-6 text-center">
        <p className="text-green-800 font-medium mb-4">Votre bon plan est prêt à être publié !</p>
      </div>
    </div>
  )
}


function DealForm() {
  const searchParams = useSearchParams()
  const router = useRouter()
  const { setAdFormStep: setStep, adFormStep: step } = useAdForm()
  const { checkAdPermission } = usePermissions()
  const { openProPlanModal } = useProPlanModal()

  const [values, setValues] = useState(defaultValues)
  const [loading, setLoading] = useState(false)
  const [id, setId] = useState<string | null>(null)
  const [isEditMode, setIsEditMode] = useState(false)
  const [showSuccessModal, setShowSuccessModal] = useState<boolean>(false)

  const [medias, setMedias] = useState<File[]>([])
  const [documentsFiles, setDocumentsFiles] = useState<File[]>([])
  const [existingImages, setExistingImages] = useState<DealImageRecord[]>([])
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([])

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
        })

        const imagesData = await fetchDealImages(id)
        if (imagesData.success) {
          const records = (imagesData.records as DealImageRecord[]) || []
          setExistingImages(records.filter((record) => record.id && record.url))
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

  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      e.preventDefault()
      e.returnValue = ""
    }

    window.addEventListener("beforeunload", handleBeforeUnload)

    return () => {
      window.removeEventListener("beforeunload", handleBeforeUnload)
    }
  }, [])

  const handleRemoveExistingImage = (imageId: string) => {
    if (!imageId) return
    setExistingImages((prev) => prev.filter((image) => image.id !== imageId))
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
    if (step === 1) {
      return !(values?.dealCategory && values?.subCategory && values?.dealType)
    }
    if (step === 2) {
      return false
    }
    if (step === 3) {
      return !(values?.title && values?.description)
    }
    // if (step === 4) {
    //   return !(
    //     (values?.isOnline === false ? values.isDelivery || values.drive || values.inStore : true) &&
    //     (values?.finalPrice > 0 || values?.dealType === "info" || values?.dealType === "free")
    //   )
    // }

    if (step === 4) {
    // Vérification des moyens de retrait pour les offres hors ligne
    const deliveryCondition = values?.isOnline === false 
      ? values.isDelivery || values.drive || values.inStore 
      : true

    // Vérification du prix selon le type de deal
    const priceCondition = 
      values?.dealType === "info" || values?.dealType === "free" 
        ? true 
        : values?.finalPrice > 0

    return !(deliveryCondition && priceCondition)
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

    if (
      Number(values?.initialPrice) < Number(values?.finalPrice) &&
      Number(values?.finalPrice) !== 0 &&
      Number(values?.initialPrice) !== 0
    ) {
      toastError("La valeur avant réduction doit être supérieure à la valeur après réduction")
      setLoading(false)
      return
    }

    if (Number(values?.finalPrice) < 0 || Number(values?.initialPrice) < 0) {
      toastError("Les valeurs ne peuvent pas être négatives")
      setLoading(false)
      return
    }

    try {
      const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : undefined

      const response = await axios.post(
        `${config.API_URL}/Ads.php`,
        {
          userId: userId,
          title: values.title,
          description: values.description,
          dealType: values.dealType,
          dealCategory: values.dealCategory,
          subCategory: values.subCategory,
          dealDeliveryType: values.dealDeliveryType,
          show: values.show,
          brand: values.brand,
          initialPrice: values.initialPrice,
          discountValue: values.discountValue,
          discountType: values.discountType,
          finalPrice: values.finalPrice,
          website: values.website,
          isOnline: values.isOnline,
          shippingCost: values.shippingCost,
          address: values.address,
          discountCode: values.discountCode,
          drive: values.drive,
          inStore: values.inStore,
          isDelivery: values.isDelivery,
          condition: values.condition,
          tag: values.tag,
          message: values.acceptMessages,
          startDate: values.startDate,
          endDate: values.endDate,
          category: "bons_plans",
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

        // Upload media files
        // if (medias.length > 0) {
        //   await axios.post(
        //     `${config.API_URL}/ImageAnnonce.php`,
        //     {
        //       annonceId: annonceId,
        //       media: medias,
        //       Method: "create",
        //     },
        //     {
        //       headers: {
        //         "Content-Type": "multipart/form-data",
        //       },
        //     },
        //   )
        // }

        // Upload des médias uploadés par l'utilisateur
      // if (medias.length > 0) {
      //   const formData = new FormData()
      //   formData.append("annonceId", annonceId)
      //   formData.append("Method", "create")
        
      //   medias.forEach((file, index) => {
      //     formData.append(`media`, file)
      //   })

      //   await axios.post(`${config.API_URL}/ImageAnnonce.php`, formData, {
      //     headers: {
      //       "Content-Type": "multipart/form-data",
      //     },
      //   })
      // }
       // CORRECTION: Upload des médias uploadés par l'utilisateur
      if (medias.length > 0) {
        console.log("[v0] Uploading", medias.length, "media files")
        
        const formData = new FormData()
        formData.append("annonceId", annonceId)
        formData.append("Method", "create")
        
        // Ajouter chaque fichier avec media[] pour que le backend le traite comme un tableau
        medias.forEach((file) => {
          formData.append("media[]", file)
        })

        console.log("[v0] FormData entries:", Array.from(formData.entries()))

        try {
          const imageResponse = await axios.post(`${config.API_URL}/ImageAnnonce.php`, formData, {
            headers: {
              "Content-Type": "multipart/form-data",
            },
          })
          console.log("[v0] ImageAnnonce.php Response:", imageResponse.data)
        } catch (imageError) {
          console.error("[v0] Error uploading images:", imageError)
          toastError("Erreur lors de l'upload des images")
        }
      }


        // Upload scrapped images
        // if (values.scrapping_images.length > 0) {
        //   const imagesUrlsUploaded = await uploadImages(values.scrapping_images)
        //   const urls = imagesUrlsUploaded.map((image) => image.url)
        //   await createImageAnnouncementByUrlsAndAnnouncementId(urls, annonceId)
        // }

         // Upload des images de scrapping
      if (values.scrapping_images.length > 0) {
        console.log("[v0] Uploading", values.scrapping_images.length, "scrapped images")
        try {
          const imagesUrlsUploaded = await uploadImages(values.scrapping_images)
          const urls = imagesUrlsUploaded.map((image) => image.url)
          await createImageAnnouncementByUrlsAndAnnouncementId(urls, annonceId)
        } catch (scrappingError) {
          console.error("[v0] Error uploading scrapped images:", scrappingError)
          toastError("Erreur lors de l'upload des images du site web")
        }
      }

        // Upload des documents si ils existent
        if (documentsFiles.length > 0) {
          try {
            console.log("[v0] Uploading", documentsFiles.length, "documents for deal...")
            
            const formDataDoc = new FormData()
            formDataDoc.append("annonceId", annonceId)
            formDataDoc.append("Method", "create_ads_file")
            formDataDoc.append("user_id", userId)
            formDataDoc.append("category", "bons_plans")

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

        if (imagesToDelete.length > 0 && id) {
          await deleteAnnonceImages(imagesToDelete, annonceId)
          setImagesToDelete([])
        }

        // Award coins for publishing
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

        if (!id) {
          setShowSuccessModal(true)
          // Déclencher l'événement pour rafraîchir les limites d'annonces
          window.dispatchEvent(new Event('adCreated'))
        } else {
          // En mode édition, rester sur le step 6
          toastSuccess("Annonce bon plan modifié avec succès")
        }
      } else {
        toastError(id ? "Erreur lors de la mise à jour de l'annonce." : "Erreur lors de la création de l'annonce.")
      }
    } catch (e: any) {
      console.error("[v0] Error submitting announcement:", e)
      toastError("Une erreur est survenue lors de la soumission")
    } finally {
      setLoading(false)
    }
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


  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 via-white to-cyan-50">
      <AnnouncementSuccessModal
        isOpen={showSuccessModal}
        onClose={() => setShowSuccessModal(false)}
        isEditMode={!!id}
        redirectPath="/dashboard/mes-annonces"
      />

      {/* Header */}
      <div className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-4">
            <Link href="/announcements/create">
              <Button variant="ghost" size="icon" className="rounded-full">
                <ArrowLeft className="h-5 w-5" />
              </Button>
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{id ? "Modifier un bon plan" : "Créer un bon plan"}</h1>
              <p className="text-sm text-gray-600">Partagez vos meilleures trouvailles avec la communauté</p>
            </div>
          </div>
        </div>
      </div>

      {/* Content */}
      <div id="custom-stepper" className="container mx-auto px-4 py-8">
        <div className="max-w-3xl mx-auto">
          <Stepper
            steps={[
              { nb: 1, label: "Informations" },
              { nb: 2, label: "Lien" },
              { nb: 3, label: "Description" },
              { nb: 4, label: "Détails" },
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
            {step === 1 && <DealFormFirstStep values={values} setValues={setValues} reviewing={false} />}
            {step === 2 && <DealFormScrappingStep values={values} onChangeValues={setValues} setStep={setStep} />}
            {step === 3 && <DealFormThirdStep values={values} setValues={setValues} reviewing={false} />}
            {step === 4 && <DealFormSecondStep values={values} setValues={setValues} reviewing={false} />}
            {step === 5 && (
              <div className="space-y-6">
                <DealFormMediaStep
                  values={values}
                  setValues={setValues}
                  medias={medias}
                  setMedias={setMedias}
                  existingImages={existingImages}
                  onRemoveExistingImage={handleRemoveExistingImage}
                />
                {values.scrapping_images.length > 0 && (
                  <ScrappingImagesSelector
                    images={values.scrapping_images}
                    onImagesChange={(selectedImages) => {
                      setValues({
                        ...values,
                        scrapping_images: selectedImages,
                      })
                    }}
                  />
                )}
              </div>
            )}
            {step === 6 && <DealFormReviewStep values={values} setStep={setStep} setValues={setValues} />}
          </motion.div>

          {step < 6 && (
            <div className="flex justify-between mt-8">
              <Button
                variant="outline"
                onClick={() => {
                  setStep((prevStep: number) => prevStep - 1)
                  handleScroll()
                }}
                disabled={step === 1}
                className="px-8"
              >
                Précédent
              </Button>

              <Button
                onClick={() => {
                  setStep((prevStep: number) => prevStep + 1)
                  handleScroll()
                }}
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
                  <>{id ? "Modifier l'annonce" : "Publier l'annonce"}</>
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

export default function CreateDealPage() {
  return (
    <AdFormProvider>
      <DealForm />
    </AdFormProvider>
  )
}
