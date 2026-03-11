"use client"

// import { useState } from "react"

import type React from "react"
import { useState, useEffect, useMemo } from "react"
import { motion, AnimatePresence } from "framer-motion"
import { useRouter, useSearchParams } from "next/navigation"
import Link from "next/link"
import { ArrowLeft, ArrowRight, Check, HelpCircle, FileText, ImageIcon, Euro, Edit2, Loader2, MapPin } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { InputDescription } from "@/components/ui/input-description"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { useToast } from "@/hooks/use-toast"
import { useUserData } from "@/hooks/use-user-data"
import { labelObject } from "@/lib/constants/label-object"
import { Slider } from "@/components/ui/slider"
import dynamic from "next/dynamic"
import "@/app/leaflet.css"

const MapWithRadius = dynamic(() => import("@/components/map-with-radius").then(mod => ({ default: mod.MapWithRadius })), {
  ssr: false,
  loading: () => <div className="h-[300px] bg-gray-100 rounded-lg animate-pulse flex items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-gray-400" /></div>
})
import {
  realEstateTypes,
  // trainingTypes,
  trainingStyles,
  trainingFunding,
  serviceTypes,
  urgencyLevels,
  getFallbackInquirySubCategories,
} from "@/lib/constants/inquiry-categories"
import { 
  // activities, 
  contractTypes, occupationTimeOptions } from "@/lib/constants/categories"
import { getCategoriesByType, type Category } from "@/lib/api/categories"
import citiesData from "@/lib/data/france-cities.json"
import { Input as InputComponents } from "@/components/ui/input-select"
import { Locate } from "lucide-react"
import { 
  studyLevels,
  experienceLevels,
  trainingTypes 
} from "@/lib/constants/training-categories-full"
import { 
  goodTypes, 
  professionalSpaceGood,
  typeRealEstates
} from "@/lib/constants/real-estate-types"

import { teachingTypes, fundings } from "@/lib/constants/training-form-constants"
// Ajoutez ces imports en haut du fichier
import { config } from "@/lib/config"
import { AnnouncementSuccessModal } from "@/components/modals/announcement-success-modal"
import ChooseSocial from "@/components/forms/ChooseSocial"

import axios from "axios"

const STEPS = [
  { id: 1, name: "Nature", icon: HelpCircle },
  { id: 2, name: "Détails", icon: FileText },
  { id: 3, name: "Localisation", icon: MapPin },
  { id: 4, name: "Photos", icon: ImageIcon },
  { id: 5, name: "Résumé", icon: Check },
]

const URGENCY_CONFIG = {
  low: { label: "Pas urgent", color: "border-green-500", bgColor: "bg-green-50", textColor: "text-green-700" },
  medium: { label: "Modéré", color: "border-yellow-500", bgColor: "bg-yellow-50", textColor: "text-yellow-700" },
  high: { label: "Urgent", color: "border-orange-500", bgColor: "bg-orange-50", textColor: "text-orange-700" },
  critical: {
    label: "Très urgent",
    color: "border-red-500",
    bgColor: "bg-red-50",
    textColor: "text-red-700",
  },
}


// Ajouter les fonctions utilitaires
function capitalizeFirstLetter(text: any) {
  if (!text) return "";
  let lines = text.split("\n");
  let capitalizedLines = lines.map((line: any) => {
    let phrases = line.split(". ");
    let capitalizedPhrases = phrases.map((phrase: any) => {
      if (!phrase) return "";
      return phrase.charAt(0).toUpperCase() + phrase.slice(1);
    });
    return capitalizedPhrases.join(". ");
  });
  return capitalizedLines.join("\n");
}

function addDurationToDate(
  startDate: string,
  duration: number,
  unit: string
): string {
  const date = new Date(startDate);
  switch (unit) {
    case "1":
      date.setHours(date.getHours() + duration);
      break;
    case "2":
      date.setDate(date.getDate() + duration);
      break;
    case "3":
      date.setMonth(date.getMonth() + duration);
      break;
    case "4":
      date.setFullYear(date.getFullYear() + duration);
      break;
    default:
      console.error("Unité de temps non prise en charge");
  }
  return date.toISOString().split("T")[0];
}

// Add this component at the top of the file, before the main export
function CandidateDocuments({ formData, setFormData, addSvg, handleDocumentChange }: any) {
  const [documents, setDocuments] = useState<any>({
    cv: [],
    motivationLetter: [],
    portfolio: [],
  })
  const [isDocumentEmpty, setIsDocumentEmpty] = useState(true)
  const [showAll, setShowAll] = useState(true)
  const [isLoading, setIsLoading] = useState(true)
  const [uploadModalOpen, setUploadModalOpen] = useState(false)
  const [currentSection, setCurrentSection] = useState<'cv' | 'motivationLetter' | 'portfolio'>('cv')

  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""

  // Function to load documents from candidate space
  const loadDocuments = async () => {
    setIsLoading(true)
    try {
      // Import the function dynamically
      const { getUserDocumentFiles } = await import("@/lib/api")
      const allDocuments = await getUserDocumentFiles(userId ?? "")

      setIsDocumentEmpty(allDocuments.length === 0)

      const organizedDocs: any = {
        cv: [],
        motivationLetter: [],
        portfolio: [],
      }

      allDocuments.forEach((doc: any) => {
        if (doc.category === 'cv') organizedDocs.cv.push(doc)
        else if (doc.category === 'motivation_letter') organizedDocs.motivationLetter.push(doc)
        else if (doc.category === 'portfolio') organizedDocs.portfolio.push(doc)
      })
      
      setDocuments(organizedDocs)
      
      const allShown = allDocuments.every((doc: any) => doc.show_public)
      setShowAll(allShown)
    } catch (error) {
      console.error("Erreur lors du chargement des documents:", error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    if (userId) {
      loadDocuments()
    }
  }, [userId])

  // Function to handle document selection
  const handleDocumentSelection = (doc: any, isSelected: boolean) => {
    if (isSelected) {
      setFormData((prevValues: any) => ({
        ...prevValues,
        selectedDocuments: [...(prevValues.selectedDocuments || []), doc.id],
        documentsFiles: [...(prevValues.documentsFiles || []), {
          id: doc.id,
          name: doc.name,
          url: doc.url,
          category: doc.category,
          user_id: doc.user_id,
          show_public: doc.show_public,
          is_external_link: doc.is_external_link
        }],
        useCandidateDocuments: true
      }))
    } else {
      setFormData((prevValues: any) => ({
        ...prevValues,
        selectedDocuments: prevValues.selectedDocuments?.filter((id: string) => id !== doc.id) || [],
        documentsFiles: prevValues.documentsFiles?.filter((file: any) => file.id !== doc.id) || [],
      useCandidateDocuments: (prevValues.selectedDocuments || []).filter((d: any) => d.id !== doc.id).length > 0
      }))
    }
  }

  // Function to add document
  const addDocument = (section: 'cv' | 'motivationLetter' | 'portfolio') => {
    setCurrentSection(section)
    setUploadModalOpen(true)
  }

  // Function to save document
  const handleSaveDocument = async (file: File | null, link?: string) => {
    try {
      // Import functions dynamically
      const { uploadFile, createDocumentFile } = await import("@/lib/api")
      
      let apiCategory: string = currentSection
      if (currentSection === 'motivationLetter') {
        apiCategory = 'motivation_letter'
      }
      
      if (file) {
        const uploadResult = await uploadFile(file)
        
        await createDocumentFile({
          user_id: userId,
          name: file.name,
          category: apiCategory,
          url: uploadResult.url,
          show_public: showAll ? 1 : 0,
        })

        const docMeta = {
          id: Date.now().toString(),
          name: file.name,
          url: uploadResult.url,
          category: apiCategory,
          user_id: userId,
          show_public: showAll,
          file: file
        }

        setFormData((prev: any) => ({
          ...prev,
          documentsFiles: [...(prev.documentsFiles || []), docMeta],
          useCandidateDocuments: true
        }))
      } else if (link) {
        let fileName = 'Lien externe'
        try {
          const url = new URL(link)
          fileName = url.hostname
          
          if (!fileName || fileName.length < 3) {
            fileName = `Lien externe - ${new Date().toLocaleDateString()}`
          }
        } catch (e) {
          console.error("URL malformée:", e)
          return
        }
        
        await createDocumentFile({
          user_id: userId,
          name: fileName,
          category: apiCategory,
          url: link,
          show_public: showAll ? 1 : 0,
          is_external_link: true
        })

        const linkMeta = {
          id: Date.now().toString(),
          name: fileName,
          url: link,
          category: apiCategory,
          user_id: userId,
          show_public: showAll,
          is_external_link: true
        }

        setFormData((prev: any) => ({
          ...prev,
          documentsFiles: [...(prev.documentsFiles || []), linkMeta],
          useCandidateDocuments: true
        }))
      }
      
      await loadDocuments()
      setFormData({
        ...formData,
        useCandidateDocuments: true
      })
      
      setUploadModalOpen(false)
    } catch (error) {
      console.error("Erreur lors de la sauvegarde du document:", error)
    }
  }

  return (
    <div>
      <div className="flex items-center space-x-2 mb-4">
        <Checkbox
          id="use-candidate-docs"
          checked={formData.useCandidateDocuments}
          onCheckedChange={(checked) => setFormData({ 
            ...formData, 
            useCandidateDocuments: checked as boolean 
          })}
          disabled={isDocumentEmpty}
        />
        <Label htmlFor="use-candidate-docs" className="cursor-pointer">
          Utiliser les documents de l'espace candidat
        </Label>
      </div>

      {!isDocumentEmpty && documents && formData.useCandidateDocuments && (
        <div className="space-y-4 mb-4">
          {Object.entries(documents).map(([category, docs]: [string, any]) => (
            <div key={category} className="space-y-2">
              <h4 className="font-semibold text-sm text-gray-700">
                {category === 'cv' ? 'CV' : 
                 category === 'motivationLetter' ? 'Lettres de motivation' : 
                 'Portfolio'}
              </h4>
              {docs.map((doc: any) => (
                <div key={doc.id} className="flex items-center justify-between bg-gray-100 p-2 rounded">
                  <div className="flex items-center gap-2">
                    <FileText className="w-4 h-4 text-gray-500" />
                    <span className="text-sm">{doc.name}</span>
                  </div>
                  <Checkbox
                    checked={formData.selectedDocuments?.includes(doc.id) || false}
                    onCheckedChange={(checked) => handleDocumentSelection(doc, checked as boolean)}
                  />
                </div>
              ))}
            </div>
          ))}
        </div>
      )}

      {(isDocumentEmpty || 1 == 1) && (
        <div className="flex flex-col items-center gap-4 p-4 border-2 border-dashed border-gray-300 rounded-lg">
          <p className="text-gray-600 text-center">Aucun document dans l'espace candidat</p>
          
          <div className="flex flex-wrap gap-2 justify-center">
            <Button
              type="button"
              onClick={() => addDocument('cv')}
              variant="outline"
              size="sm"
            >
              <FileText className="w-4 h-4 mr-2" />
              Ajouter un CV
            </Button>
            
            <Button
              type="button"
              onClick={() => addDocument('motivationLetter')}
              variant="outline"
              size="sm"
            >
              <FileText className="w-4 h-4 mr-2" />
              Ajouter une lettre de motivation
            </Button>
            
            <Button
              type="button"
              onClick={() => addDocument('portfolio')}
              variant="outline"
              size="sm"
            >
              <FileText className="w-4 h-4 mr-2" />
              Ajouter un portfolio
            </Button>
          </div>
        </div>
      )}

      {/* Documents existants */}
      {formData.documents.length > 0 && (
        <div className="space-y-2 mb-4">
          <Label>Documents sélectionnés :</Label>
          {formData.documents.map((doc: any, index: number) => (
            <div key={doc.id} className="flex items-center justify-between bg-gray-100 p-2 rounded">
              <div className="flex items-center gap-2">
                <FileText className="w-4 h-4" />
                <span className="text-sm">{doc.name}</span>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setFormData({
                    ...formData,
                    documents: formData.documents.filter((_: any, i: number) => i !== index),
                    documentsFiles: formData.documentsFiles.filter((_: any, i: number) => i !== index)
                  })
                }}
              >
                ✕
              </Button>
            </div>
          ))}
        </div>
      )}

      {/* Zone d'upload */}
      <div>
        <Label>
          Ajouter des documents{" "}
          <span className="text-xs font-normal italic text-gray-500">
            (CV, Lettre de motivation, Portfolio etc...)
          </span>
        </Label>
        
        <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-green-400 transition-colors mt-2">
          <input
            type="file"
            accept=".pdf,.doc,.docx,.txt,.jpg,.jpeg,.png"
            multiple
            onChange={handleDocumentChange}
            className="hidden"
            id="job-document-upload"
          />
          <label htmlFor="job-document-upload" className="cursor-pointer">
            <div className="w-8 h-8 mx-auto mb-2">{addSvg}</div>
            <p className="text-gray-600">Ajouter des documents</p>
          </label>
        </div>
      </div>

      {/* Modal d'upload */}
      {uploadModalOpen && (
        <MediaUploadModal
          title={`Ajouter un document - ${
            currentSection === 'cv' ? 'CV' : 
            currentSection === 'motivationLetter' ? 'Lettre de motivation' : 
            'Portfolio / Site web'
          }`}
          isOpen={uploadModalOpen}
          onClose={() => setUploadModalOpen(false)}
          onSave={handleSaveDocument}
          imageAccept=".pdf,.doc,.docx,.txt,.jpg,.jpeg,.png"
          allowLinks={currentSection === 'portfolio'}
        />
      )}
    </div>
  )
}

// MediaUploadModal component (add this as well)
function MediaUploadModal({ title, imageAccept, isOpen, onClose, onSave, allowLinks = false }: any) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [isLinkMode, setIsLinkMode] = useState(false)
  const [link, setLink] = useState('')
  const [linkError, setLinkError] = useState('')

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setSelectedFile(file)
      setLink('')
    }
  }

  const handleLinkChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setLink(value)
    setSelectedFile(null)
    
    if (linkError) setLinkError('')
  }

  const validateUrl = (url: string): boolean => {
    try {
      new URL(url)
      return true
    } catch (e) {
      return false
    }
  }

  const handleSaveClick = async () => {
    if (isLinkMode && link) {
      if (!validateUrl(link)) {
        setLinkError('Veuillez entrer une URL valide (commençant par http:// ou https://)')
        return
      }
    }
    
    setIsLoading(true)
    try {
      if (isLinkMode && link) {
        await onSave(null, link)
      } else if (selectedFile) {
        await onSave(selectedFile)
      }
      setSelectedFile(null)
      setLink('')
      setLinkError('')
      onClose()
    } finally {
      setIsLoading(false)
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
      <div className="z-50 bg-white p-6 rounded-lg shadow-lg w-96">
        <h2 className="text-lg font-bold text-gray-600 mb-4">
          {title || 'Ajouter des médias'}
        </h2>
        
        {allowLinks && (
          <div className="mb-4">
            <div className="flex justify-between mb-2">
              <Button
                type="button"
                onClick={() => setIsLinkMode(false)}
                variant={!isLinkMode ? "default" : "outline"}
                size="sm"
              >
                Importer un fichier
              </Button>
              <Button
                type="button"
                onClick={() => setIsLinkMode(true)}
                variant={isLinkMode ? "default" : "outline"}
                size="sm"
              >
                Ajouter un lien
              </Button>
            </div>
          </div>
        )}
        
        {isLinkMode && allowLinks ? (
          <div className="mt-2 mb-4">
            <Label className="block text-sm font-medium text-gray-700 mb-1">
              URL du document
            </Label>
            <Input
              type="url"
              value={link}
              onChange={handleLinkChange}
              placeholder="https://..."
              className={linkError ? 'border-red-500' : ''}
              disabled={isLoading}
            />
            {linkError && (
              <p className="mt-1 text-sm text-red-600">{linkError}</p>
            )}
          </div>
        ) : (
          <Input
            type="file"
            accept={imageAccept || "image/*,video/*"}
            onChange={handleFileChange}
            className="block w-full mt-2"
            disabled={isLoading}
          />
        )}
        
        <div className="flex justify-end space-x-4 mt-4">
          <Button
            onClick={onClose}
            variant="outline"
            disabled={isLoading}
          >
            Annuler
          </Button>
          <Button
            onClick={handleSaveClick}
            disabled={(!selectedFile && !link) || isLoading}
          >
            {isLoading ? "Chargement..." : "Enregistrer"}
          </Button>
        </div>
      </div>
    </div>
  )
}

export default function CreateInquiryPage() {
  const router = useRouter()
  const { toast } = useToast()
  const { userData } = useUserData()
  const searchParams = useSearchParams()
  const [currentStep, setCurrentStep] = useState(1)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [id, setId] = useState<string | null>(null)
  const [isEditMode, setIsEditMode] = useState(false)
  const [loading, setLoading] = useState(false)

   // États supplémentaires pour la formation
  const [isEmergent, setIsEmergent] = useState(true)
  const [documents, setDocuments] = useState<any[]>([])

  const [showSuccessModal, setShowSuccessModal] = useState(false)

  // City search state
  const [citySearchTerm, setCitySearchTerm] = useState("")
  const [showCitySuggestions, setShowCitySuggestions] = useState(false)

  // Filtrer et limiter les suggestions de villes
  const citySuggestions = useMemo(() => {
    if (!citySearchTerm || citySearchTerm.length < 2) return []
    
    const filtered = (citiesData as Array<{ name: string; zipcode: string; region: string }>).filter(city => 
      city.name.toLowerCase().includes(citySearchTerm.toLowerCase()) ||
      city.zipcode.includes(citySearchTerm)
    ).slice(0, 8) // Limiter à 8 suggestions
    
    return filtered
  }, [citySearchTerm])

  // Form data
  const [formData, setFormData] = useState({
    // Step 1: Nature
    inquiryType: "",

    // Step 2: Details - Common fields
    title: "",
    description: "",
    budget: "",
    urgency: "medium",
    deadline: "",
    
    // Step 3: Location
    location: "",
    allFrance: false,
    address: {
      city: "",
      zipcode: "",
      country: "France",
      latitude: 46.603354,
      longitude: 1.888334,
      line1: "",
      line2: "",
    },
    ray: 0, // Distance en km
    useGeolocation: false,
    show: false, // Afficher la localisation Google

    // Job Search specific - Using MyReklam-Web-Old field names
    activity: "", // Keep for compatibility
    inquiryTypeCategory: "", // Sector d'activité (from MyReklam-Web-Old)
    jobFunction: "", // Keep for compatibility
    inquiryEntitled: "", // Fonction (from MyReklam-Web-Old)
    contractType: [] as string[], // Keep for compatibility
    inquiryContractType: [] as string[], // Type de contrat (from MyReklam-Web-Old)
    occupationTime: "", // Keep for compatibility
    inquiryOccupationType: "", // Temps plein/partiel (from MyReklam-Web-Old)
    studyLevel: "", // Keep for compatibility
    inquiryStudyLevel: "", // Niveau d'étude (from MyReklam-Web-Old)
    experienceLevel: "", // Keep for compatibility
    inquiryXpLevel: "", // Niveau d'expérience (from MyReklam-Web-Old)
    minSalary: "", // Keep for compatibility
    maxSalary: "", // Keep for compatibility
    salaireMin: "", // Salaire min (from MyReklam-Web-Old)
    salaireMax: "", // Salaire max (from MyReklam-Web-Old)
    salaryExpectation: 0, // 0=none, 1=exact, 2=range (from MyReklam-Web-Old)
    salaryType: "none", // "range", "exact", "none" - Keep for compatibility
    netSalary: "brut", // Keep for compatibility
    inquiryNetSalary: "", // Net ou Brut (from MyReklam-Web-Old)
    unitSalary: "monthly", // Keep for compatibility
    inquiryUnitSalary: "years", // Indice temporel (from MyReklam-Web-Old) - Default to "years"
    inquiryTitle: "",
    inquiryDescription: "",
    telework: false,
    useCandidateDocuments: false,
    selectedDocuments: [] as string[], // IDs des documents sélectionnés

    // Training specific
    // trainingCategory: "",
    // trainingType: "",
    // trainingStyle: "",
    // trainingFunding: "",
    // trainingDuration: "",
     inquiryTrainingCategory: "",
    inquirytrainingsecteur: "",
    inquiryTrainingType: "",
    inquiryTitle: "",
    inquiryTrainingStyle: [] as string[],
    inquiryTrainingFunding: [] as string[],
    inquiryDescription: "",
    startDate: "",
    endDate: "",
    inquiryStudyLevel: "",
    inquiryXpLevel: "",
    nbrpeople: "",
    nbrgroup: "",
    indifferent: false,
    documents: [] as any[],
    documentsFiles: [] as File[],


    // Real Estate specific
    // realEstateType: "",
      realEstateType: [] as string[], // ← Changer de "" à [] as string[]

    propertyType: "",
    surface: "",
    rooms: "",
    maxPrice: "",
    inquiryTypeCategory: "",
    budgetMin: "",
    budgetMax: "",
    livingSpaceMin: "",
    livingSpaceMax: "",
    groundSpaceMin: "",
    groundSpaceMax: "",
    piece: "",
    bedroom: "",
    furniture: "",

    // Services specific
    serviceType: "",
    serviceFrequency: "",

    // Step 3: Photos
    photos: [] as File[],

      // Autres types de demandes
  inquiryTypeCategory: "",
  budgetMin: "",
  budgetMax: "",
  flexible: false,

    acceptMessages: true,
  })

  // États pour la prétention salariale (MyReklam-Web-Old style) - Après formData
  const [isSalaryBracket, setIsSalaryBracket] = useState(
    formData.salaireMin && formData.salaireMax ? true : false
  )
  const [isExactSalary, setIsExactSalary] = useState(
    (formData.salaireMin || formData.salaireMax) &&
      !(formData.salaireMax && formData.salaireMin)
      ? true
      : false
  )
  const [isNoSalary, setIsNoSalary] = useState(
    !(formData.salaireMax || formData.salaireMin) ? true : false
  )
  const [isTelework, setIsTelework] = useState(formData.telework || false)
  
  // Synchroniser les états locaux avec formData
  useEffect(() => {
    if (formData.salaireMin && formData.salaireMax) {
      setIsSalaryBracket(true)
      setIsExactSalary(false)
      setIsNoSalary(false)
    } else if (formData.salaireMin || formData.salaireMax) {
      setIsSalaryBracket(false)
      setIsExactSalary(true)
      setIsNoSalary(false)
    } else {
      setIsSalaryBracket(false)
      setIsExactSalary(false)
      setIsNoSalary(true)
    }
    setIsTelework(formData.telework || false)
  }, [formData.salaireMin, formData.salaireMax, formData.telework])

  const onChange = (evt: any) => {
    setFormData({
      ...formData,
      [evt?.target?.name]: evt?.target?.value
    });
  };

  const handleDocumentChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files);
  
      const docsMeta = files.map((file) => ({
        id: file.name + Date.now(),
        url: URL.createObjectURL(file),
        name: file.name,
        type: file.type,
      }));
  
      setFormData((prev: any) => ({
        ...prev,
        documents: [...(prev.documents || []), ...docsMeta],
        documentsFiles: [...(prev.documentsFiles || []), ...files],
      }));
    }
  };

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
  );

  // États pour les catégories depuis l'API
  const [inquiryCategories, setInquiryCategories] = useState<Category[]>([])
  const [inquirySubCategories, setInquirySubCategories] = useState<Category[]>([])
  const [jobCategories, setJobCategories] = useState<Category[]>([])
  const [jobSubCategories, setJobSubCategories] = useState<Category[]>([])
  const [trainingCategories, setTrainingCategories] = useState<Category[]>([])
  const [trainingSubCategories, setTrainingSubCategories] = useState<Category[]>([])
  const [categoriesLoading, setCategoriesLoading] = useState(true)

  // Charger les catégories principales des demandes
  useEffect(() => {
    const loadInquiryCategories = async () => {
      try {
        setCategoriesLoading(true)
        const response = await getCategoriesByType("demandes")
        if (response && response.data) {
          let mainCategories = response.data.main || []
          
          // Vérifier si SearchInternship existe déjà
          const hasSearchInternship = mainCategories.some((cat: Category) => cat.code === "SearchInternship")
          
          // Si SearchInternship n'existe pas dans l'API, l'ajouter manuellement
          if (!hasSearchInternship) {
            const searchInternshipCategory: Category = {
              id: "search-internship-fallback",
              code: "SearchInternship",
              label: labelObject.SearchInternship || "Recherche de stage / Alternance",
              type: "demandes",
              parentId: null,
              order: 0,
              isActive: true
            }
            
            // Trouver l'index de JobSearchInternship pour insérer juste après
            const jobSearchIndex = mainCategories.findIndex((cat: Category) => cat.code === "JobSearchInternship")
            if (jobSearchIndex !== -1) {
              mainCategories = [
                ...mainCategories.slice(0, jobSearchIndex + 1),
                searchInternshipCategory,
                ...mainCategories.slice(jobSearchIndex + 1)
              ]
            } else {
              // Si JobSearchInternship n'existe pas non plus, ajouter au début
              mainCategories = [searchInternshipCategory, ...mainCategories]
            }
          }
          
          setInquiryCategories(mainCategories)
        }
      } catch (error) {
        console.error("[v0] Error loading inquiry categories:", error)
      } finally {
        setCategoriesLoading(false)
      }
    }
    loadInquiryCategories()
  }, [])

  // Charger les catégories d'emploi
  useEffect(() => {
    const loadJobCategories = async () => {
      try {
        const response = await getCategoriesByType("offres_emploi")
        if (response && response.data) {
          const mainCategories = response.data.main || []
          setJobCategories(mainCategories)
        }
      } catch (error) {
        console.error("[v0] Error loading job categories:", error)
      }
    }
    loadJobCategories()
  }, [])

  // Charger les catégories de formation
  useEffect(() => {
    const loadTrainingCategories = async () => {
      try {
        const response = await getCategoriesByType("formations")
        if (response && response.data) {
          const mainCategories = response.data.main || []
          setTrainingCategories(mainCategories)
        }
      } catch (error) {
        console.error("[v0] Error loading training categories:", error)
      }
    }
    loadTrainingCategories()
  }, [])

  // Charger les sous-catégories des demandes quand un type est sélectionné
  useEffect(() => {
    const loadInquirySubCategories = async () => {
      if (!formData.inquiryType) {
        setInquirySubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("demandes")
        if (response && response.data) {
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === formData.inquiryType || cat.id === formData.inquiryType
          )

          if (selectedCategory) {
            const subs = response.data.subs[selectedCategory.id] || []
            setInquirySubCategories(subs)
          } else {
            // Si pas de catégorie trouvée dans l'API, utiliser les constantes de fallback
            const fallbackSubs = getFallbackInquirySubCategories(formData.inquiryType)
            const fallbackCategories: Category[] = fallbackSubs.map((code, index) => ({
              id: `fallback-${index}`,
              code: code,
              label: (labelObject as any)[code] || code,
            }))
            setInquirySubCategories(fallbackCategories)
          }
        } else {
          // Si l'API ne renvoie pas de données, utiliser les constantes de fallback
          const fallbackSubs = getFallbackInquirySubCategories(formData.inquiryType)
          const fallbackCategories: Category[] = fallbackSubs.map((code, index) => ({
            id: `fallback-${index}`,
            code: code,
            label: (labelObject as any)[code] || code,
          }))
          setInquirySubCategories(fallbackCategories)
        }
      } catch (error) {
        console.error("[v0] Error loading inquiry subcategories:", error)
        // En cas d'erreur, utiliser les constantes de fallback
        const fallbackSubs = getFallbackInquirySubCategories(formData.inquiryType)
        const fallbackCategories: Category[] = fallbackSubs.map((code, index) => ({
          id: `fallback-${index}`,
          code: code,
          label: (labelObject as any)[code] || code,
        }))
        setInquirySubCategories(fallbackCategories)
      }
    }
    loadInquirySubCategories()
  }, [formData.inquiryType])

  // Charger les sous-catégories d'emploi quand une activité est sélectionnée (MyReklam-Web-Old style)
  useEffect(() => {
    const loadJobSubCategories = async () => {
      // Use inquiryTypeCategory (MyReklam-Web-Old) or activity (compatibility)
      const selectedActivity = formData.inquiryTypeCategory || formData.activity
      if (!selectedActivity) {
        setJobSubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("offres_emploi")
        if (response && response.data) {
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === selectedActivity || cat.id === selectedActivity
          )

          if (selectedCategory) {
            const subs = response.data.subs[selectedCategory.id] || []
            setJobSubCategories(subs)
          } else {
            setJobSubCategories([])
          }
        }
      } catch (error) {
        console.error("[v0] Error loading job subcategories:", error)
        setJobSubCategories([])
      }
    }
    loadJobSubCategories()
  }, [formData.inquiryTypeCategory, formData.activity])

  // Charger les sous-catégories de formation quand une catégorie est sélectionnée
  useEffect(() => {
    const loadTrainingSubCategories = async () => {
      if (!formData.inquiryTrainingCategory) {
        setTrainingSubCategories([])
        return
      }

      try {
        const response = await getCategoriesByType("formations")
        if (response && response.data) {
          const selectedCategory = response.data.main.find(
            (cat: Category) => cat.code === formData.inquiryTrainingCategory || cat.id === formData.inquiryTrainingCategory
          )

          if (selectedCategory) {
            const subs = response.data.subs[selectedCategory.id] || []
            setTrainingSubCategories(subs)
          } else {
            setTrainingSubCategories([])
          }
        }
      } catch (error) {
        console.error("[v0] Error loading training subcategories:", error)
        setTrainingSubCategories([])
      }
    }
    loadTrainingSubCategories()
  }, [formData.inquiryTrainingCategory])

  const profiletype = typeof window !== "undefined" ? localStorage.getItem("profiletype") || "" : "";
  // Use inquiryTypeCategory (MyReklam-Web-Old) or activity (compatibility)
  const selectedActivity = formData.inquiryTypeCategory || formData.activity
  const availableJobFunctions = jobSubCategories
  const filteredInquiryNatures = profiletype !== "particulier"
    ? inquiryCategories.filter((cat: Category) => cat.code !== "JobSearchInternship" && cat.code !== "SearchInternship" && cat.code !== "SearchJob")
    : inquiryCategories;
  
  // Helper to check if it's a job search inquiry
  const isJobSearchInquiry = formData.inquiryType === "JobSearchInternship" || formData.inquiryType === "SearchInternship" || formData.inquiryType === "SearchJob"
  
  // Debug: Log inquiryType to help troubleshoot
  useEffect(() => {
    if (formData.inquiryType) {
      console.log("Current inquiryType:", formData.inquiryType, "isJobSearchInquiry:", isJobSearchInquiry)
    }
  }, [formData.inquiryType, isJobSearchInquiry])
  
  // Helper to get job subcategories options (MyReklam-Web-Old style)
  const getJobSubCategoryOptions = () => {
    if (!selectedActivity || availableJobFunctions.length === 0) return []
    return availableJobFunctions
      .filter((sub: Category) => sub.code !== "All")
      .map((sub: Category) => ({
        value: sub.code,
        label: sub.label || (labelObject as any)[sub.code] || sub.code,
      }))
  }

  const subCategories = trainingSubCategories


  useEffect(() => {
    const announcementId = searchParams.get("id")

    if (announcementId) {
      setId(announcementId)
      setIsEditMode(true)
      fetchAnnouncement(announcementId)
    }
  }, [searchParams])

  const [existingImages, setExistingImages] = useState<Array<{ id: string; url: string }>>([])
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([])

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
      toast({
        title: "Attention",
        description: "Certaines images n'ont pas pu être supprimées",
        variant: "destructive",
      })
    }
  }

  const fetchAnnouncement = async (announcementId: string) => {
    try {
      setLoading(true)
      const { fetchAnnouncementDetail, fetchDealImages } = await import("@/lib/api/deals")
      const announcement = await fetchAnnouncementDetail(announcementId)

      if (announcement) {
        setFormData({
          inquiryType: announcement.inquiryType || "",
          title: announcement.title || "",
          description: announcement.inquiryDescription || announcement.description || "",
          budget: announcement.budget || "",
          urgency: announcement.urgency || "medium",
          location: announcement.location || "",
          allFrance: announcement.allFrance || false,
          deadline: announcement.inquiryDeadline || announcement.deadline || "",
          address: announcement.address 
            ? (typeof announcement.address === 'string' 
                ? JSON.parse(announcement.address) 
                : announcement.address)
            : {
                city: announcement.location?.split('(')[0]?.trim() || "",
                zipcode: announcement.location?.match(/\(([^)]+)\)/)?.[1] || "",
                country: "France",
                latitude: announcement.latitude || 46.603354,
                longitude: announcement.longitude || 1.888334,
                line1: "",
                line2: "",
              },
          ray: announcement.ray || 0,
          useGeolocation: announcement.useGeolocation || false,
          show: announcement.show || false,
          activity: announcement.activity || announcement.inquiryTypeCategory || "",
          inquiryTypeCategory: announcement.inquiryTypeCategory || announcement.activity || "",
          jobFunction: announcement.jobFunction || announcement.inquiryEntitled || "",
          inquiryEntitled: announcement.inquiryEntitled || announcement.jobFunction || "",
          contractType: Array.isArray(announcement.contractType) ? announcement.contractType : (Array.isArray(announcement.inquiryContractType) ? announcement.inquiryContractType : []),
          inquiryContractType: Array.isArray(announcement.inquiryContractType) ? announcement.inquiryContractType : (Array.isArray(announcement.contractType) ? announcement.contractType : []),
          occupationTime: announcement.occupationTime || announcement.inquiryOccupationType || "",
          inquiryOccupationType: announcement.inquiryOccupationType || announcement.occupationTime || "",
          studyLevel: announcement.studyLevel || announcement.inquiryStudyLevel || "",
          inquiryStudyLevel: announcement.inquiryStudyLevel || announcement.studyLevel || "",
          experienceLevel: announcement.experienceLevel || announcement.inquiryXpLevel || "",
          inquiryXpLevel: announcement.inquiryXpLevel || announcement.experienceLevel || "",
          minSalary: announcement.minSalary || announcement.salaireMin || "",
          maxSalary: announcement.maxSalary || announcement.salaireMax || "",
          salaireMin: announcement.salaireMin || announcement.minSalary || "",
          salaireMax: announcement.salaireMax || announcement.maxSalary || "",
          salaryExpectation: announcement.salaryExpectation || (announcement.salaireMin && announcement.salaireMax ? 2 : announcement.salaireMin ? 1 : 0),
          inquiryNetSalary: announcement.inquiryNetSalary || announcement.netSalary || "",
          inquiryUnitSalary: announcement.inquiryUnitSalary || announcement.unitSalary || "",
          trainingCategory: announcement.trainingCategory || "",
          trainingType: announcement.trainingType || "",
          trainingStyle: announcement.trainingStyle || "",
          trainingFunding: announcement.trainingFunding || "",
          trainingDuration: announcement.trainingDuration || "",
          realEstateType: announcement.realEstateType || "",
          propertyType: announcement.propertyType || "",
          surface: announcement.surface || "",
          rooms: announcement.rooms || "",
          maxPrice: announcement.maxPrice || "",
          serviceType: announcement.serviceType || "",
          serviceFrequency: announcement.serviceFrequency || "",
          photos: [],
        })
        // Initialiser citySearchTerm avec la localisation existante
        if (announcement.location) {
          setCitySearchTerm(announcement.location)
        }

        // Charger les images existantes
        const imagesData = await fetchDealImages(announcementId)
        if (imagesData.success) {
          const records = (imagesData.records as Array<{ id: string; url: string }>) || []
          setExistingImages(records.filter((record) => record.id && record.url))
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

  const getLabel = (key: string) => {
    // Map PartTime to PartialTime for translation
    if (key === "PartTime") {
      return (labelObject as any)["PartialTime"] || "Temps partiel"
    }
    return (labelObject as any)[key] || key
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

  const isStepValid = () => {
    if (currentStep === 1) {
      return formData.inquiryType !== ""
    }
    // if (currentStep === 2) {
    //   return formData.title !== "" && formData.description !== ""
    // }
    return true
  }

  const validateFormData = () => {
  const errors: string[] = []

  console.log("=== VALIDATION DEBUG ===")
  console.log("inquiryType:", formData.inquiryType)
  console.log("description:", formData.description)
  console.log("inquiryDescription:", formData.inquiryDescription)

  if (!formData.inquiryType) {
    errors.push("Le type de demande est requis")
  }

  if (!formData.title && !formData.inquiryTitle) {
    errors.push("Le titre est requis")
  }

  // Validation de la description - accepter soit description soit inquiryDescription
  const hasDescription = (formData.description && formData.description.trim() !== "") || 
                         (formData.inquiryDescription && formData.inquiryDescription.trim() !== "")
  
  console.log("hasDescription:", hasDescription)
  
  if (!hasDescription) {
    console.log("Aucune description trouvée !")
    errors.push("La description est requise")
  }

  // Validation spécifique pour les demandes d'emploi
  if (formData.inquiryType === "JobSearchInternship" || formData.inquiryType === "SearchInternship" || formData.inquiryType === "SearchJob") {
    console.log("Type emploi détecté, vérification des champs supplémentaires")
    const activity = formData.inquiryTypeCategory || formData.activity
    const jobFunction = formData.inquiryEntitled || formData.jobFunction
    if (!activity) {
      errors.push("Le secteur d'activité est requis pour les demandes d'emploi")
    }
    if (!jobFunction) {
      errors.push("La fonction recherchée est requise pour les demandes d'emploi")
    }
  }

  console.log("Erreurs de validation:", errors)
  return errors
}

  const handleSubmit = async () => {
      // Valider les données avant soumission
  const validationErrors = validateFormData()
  if (validationErrors.length > 0) {
    toast({
      title: "Erreur de validation",
      description: validationErrors.join(", "),
      variant: "destructive",
    })
    // Log the validation errors for debugging
    console.error("Validation errors:", validationErrors)
    // Optionally, set the step back to where the first error occurs
    if (validationErrors.some(error => error.includes("type de demande"))) {
      setCurrentStep(1)
    } else if (validationErrors.some(error => error.includes("titre") || error.includes("description") || error.includes("secteur") || error.includes("fonction"))) {
      setCurrentStep(2)
    }
    return
  }
  setIsSubmitting(true)
  
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
  
  if (!userId) {
    toast({
      title: "Erreur",
      description: "Vous devez être connecté pour publier une demande.",
      variant: "destructive",
    })
    setIsSubmitting(false)
    return
  }

  try {
    // Import des utilitaires nécessaires
    const { config } = await import("@/lib/config")
    const axios = (await import("axios")).default

    // Fonction helper pour formater les arrays PostgreSQL
    const formatArrayForPostgreSQL = (value: any): string => {
      if (!value) return ""
      if (typeof value === 'string') return value
      if (Array.isArray(value)) {
        if (value.length === 0) return ""
        // Format PostgreSQL: {value1,value2,value3}
        const escapedValues = value.map((v: any) => {
          const str = String(v).replace(/"/g, '\\"').replace(/\\/g, '\\\\')
          return `"${str}"`
        })
        return `{${escapedValues.join(',')}}`
      }
      return String(value)
    }

    // Préparer les données de l'annonce
    const announcementData = {
      userId,
      category: "demandes",
      inquiryType: formData.inquiryType,
      title: formData.title || formData.inquiryTitle,
      description: formData.description || formData.inquiryDescription,
      urgency: formData.urgency,
      location: formData.location,
      allFrance: formData.allFrance,
      deadline: formData.deadline,
      address: JSON.stringify(formData.address),
      ray: formData.ray || 0,
      useGeolocation: formData.useGeolocation,
      show: formData.show,
      
      // AJOUT: Champ pour accepter les messages
      acceptMessages: formData.acceptMessages,
      message: formData.acceptMessages, // Pour compatibilité avec le backend
      
      // Job Search specific - MyReklam-Web-Old style
      activity: formData.activity || formData.inquiryTypeCategory, // Keep for compatibility
      inquiryTypeCategory: formData.inquiryTypeCategory || formData.activity, // MyReklam-Web-Old
      jobFunction: formData.jobFunction || formData.inquiryEntitled, // Keep for compatibility
      inquiryEntitled: formData.inquiryEntitled || formData.jobFunction, // MyReklam-Web-Old
      contractType: formatArrayForPostgreSQL(formData.contractType.length > 0 ? formData.contractType : formData.inquiryContractType), // Keep for compatibility
      inquiryContractType: formatArrayForPostgreSQL(formData.inquiryContractType.length > 0 ? formData.inquiryContractType : formData.contractType), // MyReklam-Web-Old
      occupationTime: formData.occupationTime || formData.inquiryOccupationType, // Keep for compatibility
      inquiryOccupationType: formData.inquiryOccupationType || formData.occupationTime, // MyReklam-Web-Old
      studyLevel: formData.studyLevel || formData.inquiryStudyLevel, // Keep for compatibility
      inquiryStudyLevel: formData.inquiryStudyLevel || formData.studyLevel, // MyReklam-Web-Old
      experienceLevel: formData.experienceLevel || formData.inquiryXpLevel, // Keep for compatibility
      inquiryXpLevel: formData.inquiryXpLevel || formData.experienceLevel, // MyReklam-Web-Old
      minSalary: formData.minSalary || formData.salaireMin, // Keep for compatibility
      maxSalary: formData.maxSalary || formData.salaireMax, // Keep for compatibility
      salaireMin: formData.salaireMin || formData.minSalary, // MyReklam-Web-Old
      salaireMax: formData.salaireMax || formData.maxSalary, // MyReklam-Web-Old
      salaryExpectation: formData.salaryExpectation, // MyReklam-Web-Old (0=none, 1=exact, 2=range)
      inquiryTitle: formData.inquiryTitle,
      inquiryDescription: formData.inquiryDescription,
      telework: formData.telework,
      salaryType: formData.salaryType, // Keep for compatibility
      netSalary: formData.netSalary || formData.inquiryNetSalary, // Keep for compatibility
      inquiryNetSalary: formData.inquiryNetSalary || formData.netSalary, // MyReklam-Web-Old
      unitSalary: formData.unitSalary || formData.inquiryUnitSalary, // Keep for compatibility
      inquiryUnitSalary: formData.inquiryUnitSalary || formData.unitSalary, // MyReklam-Web-Old

      // Training specific
      trainingType: formData.trainingType,
      inquiryTrainingCategory: formData.inquiryTrainingCategory,
      trainingSubCategory: formData.trainingSubCategory,
      trainingStyle: formatArrayForPostgreSQL(formData.trainingStyle),
      trainingFunding: formatArrayForPostgreSQL(formData.trainingFunding),
      startDate: formData.startDate,
      endDate: formData.endDate,
      inquiryStudyLevel: formData.inquiryStudyLevel,
      inquiryXpLevel: formData.inquiryXpLevel,
      nbrpeople: formData.nbrpeople,
      nbrgroup: formData.nbrgroup,
      indifferent: formData.indifferent,

      // Real Estate specific
      realEstateType: formatArrayForPostgreSQL(formData.realEstateType),
      propertyType: formData.propertyType,
      surface: formData.surface,
      rooms: formData.rooms,
      maxPrice: formData.maxPrice,
      budgetMin: formData.budgetMin,
      budgetMax: formData.budgetMax,
      livingSpaceMin: formData.livingSpaceMin,
      livingSpaceMax: formData.livingSpaceMax,
      groundSpaceMin: formData.groundSpaceMin,
      groundSpaceMax: formData.groundSpaceMax,
      piece: formData.piece,
      bedroom: formData.bedroom,
      furniture: formData.furniture,

      // Services specific
      serviceType: formData.serviceType,
      serviceFrequency: formData.serviceFrequency,

      // Autres types de demandes
      inquiryTypeCategory: formData.inquiryTypeCategory,
      budgetMin: formData.budgetMin,
      budgetMax: formData.budgetMax,
      flexible: formData.flexible,

      // Metadata
      Method: isEditMode ? "updateAnnonce" : "create", // Changer "updateAd" en "updateAnnonce"
    }

    // Si c'est une modification, ajouter l'ID
    if (isEditMode && id) {
      announcementData.id = id
    }

    console.log("[v0] Submitting announcement data:", announcementData)

    // MODIFICATION: Envoyer d'abord les données de base sans les fichiers
    const response = await axios.post(`${config.API_URL}/Ads.php`, announcementData, {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    })

    console.log("[v0] Response:", response.data)

    if (response.data.status === "success") {
      const annonceId = isEditMode ? id : response.data.id
      console.log("[v0] Announcement created/updated with ID:", annonceId)

      // GESTION SÉPARÉE: Upload des photos
      if (formData.photos && formData.photos.length > 0) {
        try {
          console.log("[v0] Uploading", formData.photos.length, "photos...")
          
          const photoFormData = new FormData()
          photoFormData.append("annonceId", annonceId)
          photoFormData.append("Method", "create")
          
          formData.photos.forEach((photo) => {
            photoFormData.append("media[]", photo)
          })

          const photoResponse = await axios.post(`${config.API_URL}/ImageAnnonce.php`, photoFormData, {
            headers: { "Content-Type": "multipart/form-data" },
          })
          
          console.log("[v0] Photos uploaded successfully:", photoResponse.data)
        } catch (photoError) {
          console.error("[v0] Error uploading photos:", photoError)
          // Ne pas bloquer la publication pour cette erreur
        }
      }

      // Supprimer les images marquées pour suppression
      if (imagesToDelete.length > 0 && isEditMode) {
        await deleteAnnonceImages(imagesToDelete, annonceId)
        setImagesToDelete([])
      }

      // GESTION SÉPARÉE: Upload des documents pour toutes les demandes
      if (formData.documentsFiles && formData.documentsFiles.length > 0) {
        try {
          console.log("[v0] Uploading job documents for announcement:", annonceId)
          
          const formDataDoc = new FormData()
          formDataDoc.append("annonceId", annonceId)
          formDataDoc.append("Method", "create_ads_file")
          formDataDoc.append("user_id", userId)
          formDataDoc.append("category", "demandes")

          // Ajouter les fichiers réels
          const realFiles = formData.documentsFiles.filter((item: any) => item instanceof File)
          realFiles.forEach((file: File, idx: number) => {
            formDataDoc.append(`documents[${idx}]`, file, file.name)
          })

          // Ajouter les IDs des documents existants de l'espace candidat
          const existingDocIds = formData.documentsFiles
            .filter((item: any) => !(item instanceof File) && item.id)
            .map((item: any) => item.id)
          
          if (existingDocIds.length > 0) {
            existingDocIds.forEach((docId: string, idx: number) => {
              formDataDoc.append(`document_ids[${idx}]`, docId)
            })
          }

          if (realFiles.length > 0 || existingDocIds.length > 0) {
            const docResponse = await axios.post(`${config.API_URL}/DocumentFiles.php`, formDataDoc, {
              headers: { "Content-Type": "multipart/form-data" },
            })
            console.log("[v0] Documents uploaded successfully:", docResponse.data)
          }
        } catch (docError) {
          console.error("[v0] Error uploading documents:", docError)
          // Ne pas bloquer la publication pour cette erreur
        }
      }

      // Attribuer des coins pour la publication (seulement pour les nouvelles annonces)
      if (!isEditMode) {
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

      // Afficher la popup de succès
      setShowSuccessModal(true)
      // Déclencher l'événement pour rafraîchir les limites d'annonces
      if (!isEditMode) {
        window.dispatchEvent(new Event('adCreated'))
      }
    } else {
      throw new Error(response.data.message || "Erreur lors de la publication")
    }
  } catch (error: any) {
    console.error("[v0] Error submitting announcement:", error)
    
    let errorMessage = "Une erreur est survenue lors de la publication."
    
    if (error?.response?.status === 500) {
      errorMessage = "Erreur serveur. Vérifiez les données saisies."
    } else if (error?.response?.data?.message) {
      errorMessage = error.response.data.message
    } else if (error?.message) {
      errorMessage = error.message
    }

    toast({
      title: "Erreur",
      description: isEditMode
        ? "Une erreur est survenue lors de la modification."
        : errorMessage,
      variant: "destructive",
    })
  } finally {
    setIsSubmitting(false)
  }
}
//   const handleSubmit = async () => {
//   setIsSubmitting(true)
  
//   const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
//   const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null

//   if (!userId) {
//     toast({
//       title: "Erreur",
//       description: "Vous devez être connecté pour publier une demande.",
//       variant: "destructive",
//     })
//     setIsSubmitting(false)
//     return
//   }

//   try {
//     // Import des utilitaires nécessaires
//     const { config } = await import("@/lib/config")
//     const axios = (await import("axios")).default

//     // Fonction helper pour formater les arrays PostgreSQL
//     const formatArrayForPostgreSQL = (value: any): string => {
//       if (!value) return ""
//       if (typeof value === 'string') return value
//       if (Array.isArray(value)) {
//         if (value.length === 0) return ""
//         // Format PostgreSQL: {value1,value2,value3}
//         const escapedValues = value.map(v => {
//           const str = String(v).replace(/"/g, '\\"').replace(/\\/g, '\\\\')
//           return `"${str}"`
//         })
//         return `{${escapedValues.join(',')}}`
//       }
//       return String(value)
//     }

//     // Préparer les données de l'annonce
//     const announcementData = {
//       userId,
//       category: "demandes",
//       inquiryType: formData.inquiryType,
//       title: formData.title || formData.inquiryTitle,
//       description: formData.description || formData.inquiryDescription,
//       urgency: formData.urgency,
//       location: formData.location,
//       allFrance: formData.allFrance,
//       deadline: formData.deadline,
      
//       // Job Search specific
//       activity: formData.activity,
//       jobFunction: formData.jobFunction,
//       contractType: formatArrayForPostgreSQL(formData.contractType),
//       occupationTime: formData.occupationTime,
//       studyLevel: formData.studyLevel,
//       experienceLevel: formData.experienceLevel,
//       minSalary: formData.minSalary,
//       maxSalary: formData.maxSalary,
//       salaryType: formData.salaryType,
//       netSalary: formData.netSalary,
//       unitSalary: formData.unitSalary,
//       telework: formData.telework,
//       useCandidateDocuments: formData.useCandidateDocuments,
      
//       // Training specific
//       inquiryTrainingCategory: formData.inquiryTrainingCategory,
//       inquirytrainingsecteur: formData.inquirytrainingsecteur,
//       inquiryTrainingType: formData.inquiryTrainingType,
//       inquiryTrainingStyle: formatArrayForPostgreSQL(formData.inquiryTrainingStyle),
//       inquiryTrainingFunding: formatArrayForPostgreSQL(formData.inquiryTrainingFunding),
//       startDate: formData.startDate,
//       endDate: formData.endDate,
//       inquiryStudyLevel: formData.inquiryStudyLevel,
//       inquiryXpLevel: formData.inquiryXpLevel,
//       nbrpeople: formData.nbrpeople,
//       nbrgroup: formData.nbrgroup,
//       indifferent: formData.indifferent,
      
//       // Real Estate specific
//       inquiryTypeCategory: formData.inquiryTypeCategory,
//       realEstateType: formatArrayForPostgreSQL(formData.realEstateType),
//       budgetMin: formData.budgetMin,
//       budgetMax: formData.budgetMax,
//       livingSpaceMin: formData.livingSpaceMin,
//       livingSpaceMax: formData.livingSpaceMax,
//       groundSpaceMin: formData.groundSpaceMin,
//       groundSpaceMax: formData.groundSpaceMax,
//       piece: formData.piece,
//       bedroom: formData.bedroom,
//       furniture: formData.furniture,
      
//       // Services specific
//       serviceType: formData.serviceType,
//       serviceFrequency: formData.serviceFrequency,
      
//       // Method
//       Method: isEditMode ? "updateAd" : "create",
//     }

//     // Si c'est une modification, ajouter l'ID
//     if (isEditMode && id) {
//       announcementData.id = id
//     }

//     // Créer le FormData pour inclure les fichiers
//     const formDataToSend = new FormData()

//     // Ajouter toutes les données de l'annonce
//     Object.entries(announcementData).forEach(([key, value]) => {
//       if (value !== null && value !== undefined) {
//         formDataToSend.append(key, value.toString())
//       }
//     })

//     // Ajouter les images si elles existent
//     formData.photos.forEach((photo, index) => {
//       formDataToSend.append(`media`, photo)
//     })

//     // Ajouter les documents si ils existent
//     formData.documentsFiles.forEach((document, index) => {
//       formDataToSend.append(`documents`, document)
//     })

//     console.log("[v0] Submitting announcement data:", announcementData)

//     // Envoyer la requête
//     const response = await axios.post(`${config.API_URL}/Ads.php`, formDataToSend, {
//       headers: {
//         "Content-Type": "multipart/form-data",
//       },
//     })

//     console.log("[v0] Response:", response.data)

//     if (response.data.status === "success") {
//       // Attribuer des coins pour la publication (seulement pour les nouvelles annonces)
//       if (!isEditMode) {
//         try {
//           await axios.post(
//             `${config.API_URL}/HistoryCoins.php`,
//             {
//               userId,
//               valueCoin: 2,
//               eventName: "publish_ad",
//               description: "Coins added for: publish_ad",
//               generateBy: "system_event",
//               Method: "create_history_coin",
//             },
//             {
//               headers: {
//                 "Content-Type": "application/x-www-form-urlencoded",
//               },
//             }
//           )
//         } catch (coinError) {
//           console.error("[v0] Error awarding coins:", coinError)
//         }
//       }

//       toast({
//         title: isEditMode ? "Demande modifiée !" : "Demande publiée !",
//         description: isEditMode
//           ? "Votre demande a été modifiée avec succès."
//           : "Votre demande a été publiée avec succès.",
//       })

//       // Rediriger vers la page des demandes
//       setTimeout(() => {
//         router.push("/demandes")
//       }, 1500)
//     } else {
//       throw new Error(response.data.message || "Erreur lors de la publication")
//     }
//   } catch (error: any) {
//     console.error("[v0] Error submitting announcement:", error)
    
//     let errorMessage = "Une erreur est survenue lors de la publication."
    
//     if (error?.response?.data?.message) {
//       errorMessage = error.response.data.message
//     } else if (error?.message) {
//       errorMessage = error.message
//     }

//     toast({
//       title: "Erreur",
//       description: isEditMode
//         ? "Une erreur est survenue lors de la modification."
//         : errorMessage,
//       variant: "destructive",
//     })
//   } finally {
//     setIsSubmitting(false)
//   }
// }

  const handleSubmit0 = async () => {
    setIsSubmitting(true)
    try {
      await new Promise((resolve) => setTimeout(resolve, 2000))

      toast({
        title: isEditMode ? "Demande modifiée !" : "Demande publiée !",
        description: isEditMode
          ? "Votre demande a été modifiée avec succès."
          : "Votre demande a été publiée avec succès.",
      })

      router.push("/demandes")
    } catch (error) {
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

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const newPhotos = Array.from(e.target.files)
      setFormData({ ...formData, photos: [...formData.photos, ...newPhotos] })
    }
  }

  const removePhoto = (index: number) => {
    const newPhotos = formData.photos.filter((_, i) => i !== index)
    setFormData({ ...formData, photos: newPhotos })
  }

  // const availableJobFunctions = formData.activity ? activityToJobFunctionsMapping[formData.activity] || [] : []
// const profiletype = typeof window !== "undefined" ? localStorage.getItem("profiletype") || "" : "";

  
  // Filtrer inquiryNatures si profiletype n'est pas "particulier"
  // const filteredInquiryNatures = profiletype !== "particulier"
  //   ? inquiryNatures.filter((item: string) => item !== "JobSearchInternship")
  //   : inquiryNatures;

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-pink-50 py-8 px-4 mt-20">
      <AnnouncementSuccessModal
        isOpen={showSuccessModal}
        onClose={() => setShowSuccessModal(false)}
        isEditMode={isEditMode}
        redirectPath="/demandes"
      />
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="mb-8">
          <Link
            href="/announcements/create"
            className="inline-flex items-center text-purple-600 hover:text-purple-700 mb-4"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Retour aux catégories
          </Link>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            {isEditMode ? "Modifier une demande" : "Créer une demande"}
          </h1>
          <p className="text-gray-600">
            {isEditMode
              ? "Modifiez votre demande et mettez-la à jour"
              : "Décrivez ce que vous recherchez et recevez des propositions"}
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
                        ? "bg-purple-600 border-purple-600 text-white"
                        : "bg-white border-gray-300 text-gray-400"
                    }`}
                  >
                    <step.icon className="w-6 h-6" />
                  </div>
                  <span
                    className={`mt-2 text-sm font-medium ${
                      currentStep >= step.id ? "text-purple-600" : "text-gray-400"
                    }`}
                  >
                    {step.name}
                  </span>
                </div>
                {index < STEPS.length - 1 && (
                  <div
                    className={`h-1 flex-1 mx-2 rounded transition-all ${
                      currentStep > step.id ? "bg-purple-600" : "bg-gray-200"
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
          <AnimatePresence mode="wait">
            {/* Step 1: Nature */}
            {currentStep === 1 && (
              <motion.div
                key="step1"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="space-y-6"
              >
                {categoriesLoading ? (
                  <div className="flex items-center justify-center py-8">
                    <Loader2 className="w-6 h-6 animate-spin text-purple-600" />
                  </div>
                ) : (
                  <>
                    <div>
                      <Label htmlFor="inquiryType">Nature de la demande *</Label>
                      <Select
                        value={formData.inquiryType}
                        onValueChange={(value) => setFormData({ ...formData, inquiryType: value })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Sélectionnez la nature de votre demande" />
                        </SelectTrigger>
                        <SelectContent>
                          {filteredInquiryNatures.map((category: Category) => (
                            <SelectItem key={category.id} value={category.code}>
                              {category.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    {formData.inquiryType && (
                      <div className="mt-4 p-4 bg-purple-50 rounded-lg">
                        <p className="text-sm text-purple-700">
                          <strong>Type sélectionné:</strong> {inquiryCategories.find(cat => cat.code === formData.inquiryType)?.label || formData.inquiryType}
                        </p>
                      </div>
                    )}
                  </>
                )}
              </motion.div>
            )}

            {/* Step 2: Details */}
            {currentStep === 2 && (
              <motion.div
                key="step2"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="space-y-6"
              >
                {/* Type de demande - Affiché pour tous les types sauf Training et JobSearchInternship/SearchInternship/SearchJob */}
                {formData.inquiryType && 
                 !["Training", "JobSearchInternship", "SearchInternship", "SearchJob"].includes(formData.inquiryType) && 
                 (inquirySubCategories.length > 0 || getFallbackInquirySubCategories(formData.inquiryType).length > 0) && (
                  <div className="mb-6">
                    <Label>Type de demande *</Label>
                    <Select
                      value={formData.inquiryTypeCategory}
                      onValueChange={(value) => setFormData({ 
                        ...formData, 
                        inquiryTypeCategory: value,
                        // Reset les champs spécifiques si nécessaire
                        ...(formData.inquiryType === "RealEstate" ? { realEstateType: [] } : {})
                      })}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Sélectionnez un type de demande" />
                      </SelectTrigger>
                      <SelectContent>
                        {inquirySubCategories.length > 0 ? (
                          inquirySubCategories.map((subCategory: Category) => (
                            <SelectItem key={subCategory.id} value={subCategory.code}>
                              {subCategory.label}
                            </SelectItem>
                          ))
                        ) : (
                          // Utiliser les constantes de fallback si l'API n'a pas renvoyé de sous-catégories
                          getFallbackInquirySubCategories(formData.inquiryType).map((code, index) => (
                            <SelectItem key={`fallback-${index}`} value={code}>
                              {(labelObject as any)[code] || code}
                            </SelectItem>
                          ))
                        )}
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-gray-500 mt-1">
                      Sélectionnez le type de demande selon la nature choisie
                    </p>
                  </div>
                )}

                {/* Common fields for all inquiry types */}
                {/* {formData.inquiryType !== "Training" && formData.inquiryType !== "JobSearchInternship"  && formData.inquiryType !== "RealEstate" && formData.inquiryType === "" && (
                  <>
                <div>
                  <Label htmlFor="title">Titre de votre demande *</Label>
                  <Input
                    id="title"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    placeholder="Ex: Recherche plombier pour rénovation"
                  />
                </div>

                <div>
                  <Label htmlFor="description">Description détaillée *</Label>
                  <Textarea
                    id="description"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Décrivez en détail ce que vous recherchez..."
                    rows={6}
                  />
                </div> 
                </>)} */}

                {/* Job Search specific fields */}
               {/* Job Search specific fields */}

                  {/* Job Search specific fields - MyReklam-Web-Old InquiryJob exact implementation */}
{isJobSearchInquiry && (
  <div className="space-y-6 bg-green-50 p-6 rounded-lg border-2 border-green-500">
    <h3 className="text-lg font-semibold text-green-800 mb-4">Détails du poste recherché</h3>
    {/* Debug: This section should be visible when inquiryType is JobSearchInternship or SearchJob */}
    
    {/* Secteur d'activité - MyReklam-Web-Old style */}
    <div>
      <Label>Secteur d'activité *</Label>
      <Select
        value={formData.inquiryTypeCategory || formData.activity}
        onValueChange={(value) => setFormData({ 
          ...formData, 
          inquiryTypeCategory: value, 
          activity: value, // Keep for compatibility
          inquiryEntitled: "", 
          jobFunction: "" // Keep for compatibility
        })}
      >
        <SelectTrigger>
          <SelectValue placeholder="Sélectionnez un secteur d'activité" />
        </SelectTrigger>
        <SelectContent>
          {jobCategories.map((category) => (
            <SelectItem key={category.id} value={category.code}>
              {category.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>

    {/* Fonction recherchée - MyReklam-Web-Old style */}
    {selectedActivity && availableJobFunctions.length > 0 && (
      <div>
        <Label>Fonction recherchée *</Label>
        <Select
          value={formData.inquiryEntitled || formData.jobFunction}
          onValueChange={(value) => setFormData({ 
            ...formData, 
            inquiryEntitled: value,
            jobFunction: value // Keep for compatibility
          })}
        >
          <SelectTrigger>
            <SelectValue placeholder="Sélectionnez une fonction" />
          </SelectTrigger>
          <SelectContent>
            {getJobSubCategoryOptions().map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
    )}

    {/* Titre du poste recherché - MyReklam-Web-Old style */}
    <div>
      <Label htmlFor="inquiryTitle">Quel est le poste recherché ? *</Label>
      <Input
        id="inquiryTitle"
        value={formData.inquiryTitle}
        onChange={(e) => setFormData({ ...formData, inquiryTitle: e.target.value })}
        placeholder="Titre ex : mecanicien automobile"
      />
      <p className="text-sm text-gray-500 mt-1">Quelque chose de court et percutant.</p>
    </div>

    {/* Type de contrat recherché - MyReklam-Web-Old style */}
    <div>
      <Label>Type de contrat recherché * (Choix multiple)</Label>
      <div className="grid grid-cols-2 gap-2 max-h-32 overflow-auto bg-gray-50 p-3 rounded-lg">
        {(() => {
          console.log("[Contract Filter] inquiryType:", formData.inquiryType)
          return contractTypes
            .filter((type) => {
              // Si c'est "Recherche de stage / Alternance", afficher uniquement Apprenticeship et Internship
              if (formData.inquiryType === "SearchInternship") {
                console.log("[Contract Filter] SearchInternship - showing only Apprenticeship and Internship")
                return type === "Apprenticeship" || type === "Internship"
              }
              // Si c'est "Recherche d'emploi / Alternance", exclure UNIQUEMENT Apprenticeship et Internship (garder Volunteering)
              if (formData.inquiryType === "JobSearchInternship" || formData.inquiryType === "SearchJob") {
                console.log("[Contract Filter] JobSearchInternship/SearchJob - excluding Apprenticeship and Internship only")
                return type !== "Apprenticeship" && type !== "Internship"
              }
              // Sinon, afficher tous les types de contrat
              console.log("[Contract Filter] Default - showing all contract types")
              return true
            })
        })()
          .map((type) => {
          const contractArray = formData.inquiryContractType.length > 0 ? formData.inquiryContractType : formData.contractType
          return (
            <div key={type} className="flex items-center space-x-2">
              <Checkbox
                id={`contract-${type}`}
                checked={contractArray.includes(type)}
                onCheckedChange={(checked) => {
                  if (checked) {
                    setFormData({ 
                      ...formData, 
                      inquiryContractType: [...contractArray, type],
                      contractType: [...contractArray, type] // Keep for compatibility
                    })
                  } else {
                    setFormData({
                      ...formData,
                      inquiryContractType: contractArray.filter((t) => t !== type),
                      contractType: contractArray.filter((t) => t !== type), // Keep for compatibility
                    })
                  }
                }}
              />
              <Label htmlFor={`contract-${type}`} className="cursor-pointer font-normal">
                {getLabel(type)}
              </Label>
            </div>
          )
        })}
      </div>
    </div>

    {/* Temps de travail - MyReklam-Web-Old style avec traduction corrigée */}
    <div className="space-y-3">
      <Label className="text-sm font-medium text-gray-700">Temps plein ou temps partiel ? *</Label>
      <RadioGroup
        value={formData.inquiryOccupationType || formData.occupationTime}
        onValueChange={(value) => setFormData({ 
          ...formData, 
          inquiryOccupationType: value,
          occupationTime: value // Keep for compatibility
        })}
        className="flex flex-row gap-6"
      >
        {occupationTimeOptions.map((option) => (
          <div key={option} className="flex items-center space-x-2">
            <RadioGroupItem value={option} id={option} />
            <Label htmlFor={option} className="font-normal cursor-pointer text-base">
              {getLabel(option)}
            </Label>
          </div>
        ))}
      </RadioGroup>
    </div>

    {/* Niveau d'étude - MyReklam-Web-Old style */}
    <div>
      <Label>Quel est votre niveau d'étude ? *</Label>
      <Select
        value={formData.inquiryStudyLevel || formData.studyLevel}
        onValueChange={(value) => setFormData({ 
          ...formData, 
          inquiryStudyLevel: value,
          studyLevel: value // Keep for compatibility
        })}
      >
        <SelectTrigger>
          <SelectValue placeholder="Niveau d'étude" />
        </SelectTrigger>
        <SelectContent>
          {studyLevels.map((level) => (
            <SelectItem key={level} value={level}>
              {getLabel(level)}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>

    {/* Niveau d'expérience - MyReklam-Web-Old style */}
    <div>
      <Label>Quel est votre niveau d'expérience ? *</Label>
      <Select
        value={formData.inquiryXpLevel || formData.experienceLevel}
        onValueChange={(value) => setFormData({ 
          ...formData, 
          inquiryXpLevel: value,
          experienceLevel: value // Keep for compatibility
        })}
      >
        <SelectTrigger>
          <SelectValue placeholder="Niveau d'expérience" />
        </SelectTrigger>
        <SelectContent>
          {experienceLevels.map((level) => (
            <SelectItem key={level} value={level}>
              {getLabel(level)}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>

    {/* Disponibilités - MyReklam-Web-Old style */}
    <div className={currentStep !== 5 ? "my-4" : ""}>
      <Label className="text-neutral/80 font-semibold">
        Quelles-sont vos disponibilités ?
      </Label>
      <div className={currentStep !== 5 ? "my-2" : ""}>
        <div className={currentStep !== 5 ? "my-4" : ""}>
          <div className="flex items-center">
            <Checkbox
              id="is-emergent-checkbox"
              checked={isEmergent}
              onCheckedChange={(checked) => {
                if (checked) {
                  setFormData({
                    ...formData,
                    endDate: "",
                    startDate: ""
                  })
                }
                setIsEmergent(checked as boolean)
              }}
              className="mr-2"
            />
            <Label htmlFor="is-emergent-checkbox" className="cursor-pointer ml-2">
              Dans l'immédiat
            </Label>
          </div>
        </div>

        <div className={`flex ${currentStep === 5 ? "hidden" : ""} justify-between gap-2 items-center`}>
          <div className="md:block hidden">
            <Checkbox
              id="is-not-emergent-checkbox"
              checked={!isEmergent}
              onCheckedChange={(checked) => {
                setIsEmergent(!checked)
              }}
              className="mr-2"
            />
          </div>
          <div className="flex justify-around gap-2 items-center md:flex-row flex-col w-full">
            <div className="flex flex-col">
              <Label className="text-center text-neutral/70 font-semibold">
                A partir du :
              </Label>
              <Input
                type="date"
                disabled={isEmergent}
                name="startDate"
                value={formData.startDate || ""}
                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                max={formData.endDate}
                className="mt-1"
              />
            </div>

            <div className="flex flex-col">
              <Label className="md:flex items-center justify-center text-neutral/70 font-semibold">
                Jusqu'au
                <span className="text-xs text-neutral/60 font-light ml-1">
                  (facultatif)
                </span>
              </Label>
              <Input
                type="date"
                disabled={isEmergent}
                name="endDate"
                value={formData.endDate || ""}
                onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                min={formData.startDate}
                className="mt-1"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    {/* Prétention salariale - MyReklam-Web-Old style exact avec meilleur alignement */}
    <div className={currentStep !== 5 ? "my-8 space-y-4" : "grid grid-cols-3 w-full gap-2 my-2"}>
      <Label className="text-neutral/80 font-semibold block mb-4">
        Quel est votre prétention salariale ?
      </Label>
      <div className="flex my-4 md:flex-row flex-col justify-start align-center gap-4">
        <RadioGroup
          value={isSalaryBracket ? "range" : isExactSalary ? "exact" : "none"}
          onValueChange={(value) => {
            if (value === "range") {
              setIsSalaryBracket(true)
              setIsExactSalary(false)
              setIsNoSalary(false)
              setFormData({
                ...formData,
                salaryExpectation: 2,
                salaireMin: "",
                salaireMax: "",
                minSalary: "", // Keep for compatibility
                maxSalary: "" // Keep for compatibility
              })
            } else if (value === "exact") {
              setIsSalaryBracket(false)
              setIsExactSalary(true)
              setIsNoSalary(false)
              setFormData({
                ...formData,
                salaryExpectation: 1,
                salaireMin: "",
                salaireMax: "",
                minSalary: "", // Keep for compatibility
                maxSalary: "" // Keep for compatibility
              })
            } else {
              setIsSalaryBracket(false)
              setIsExactSalary(false)
              setIsNoSalary(true)
              setFormData({
                ...formData,
                salaryExpectation: 0,
                salaireMin: "",
                salaireMax: "",
                minSalary: "", // Keep for compatibility
                maxSalary: "" // Keep for compatibility
              })
            }
          }}
          className="flex md:flex-row flex-col gap-4"
        >
          <div className="md:mb-0 mb-2 flex items-center">
            <RadioGroupItem value="range" id="salary-bracket-radio" className="mr-2" />
            <Label htmlFor="salary-bracket-radio" className="cursor-pointer">
              Tranche salariale
            </Label>
          </div>
          <div className="my-2 flex items-center">
            <RadioGroupItem value="exact" id="salary-exact-radio" className="mr-2" />
            <Label htmlFor="salary-exact-radio" className="cursor-pointer">
              Salaire exact
            </Label>
          </div>
          <div className="mt-2 flex items-center">
            <RadioGroupItem value="none" id="no-salary-radio" className="mr-2" />
            <Label htmlFor="no-salary-radio" className="cursor-pointer">
              Aucune
            </Label>
          </div>
        </RadioGroup>
      </div>

      {/* Champs de salaire avec icônes euro - Agrandis et mieux alignés */}
      <div className="mt-4">
        {isSalaryBracket && (
          <div className="space-y-4">
            <Label className="text-sm font-medium text-gray-700">Tranche salariale</Label>
            <div className="flex flex-row items-center gap-3">
              <div className="flex-1 flex items-center gap-2 border rounded-lg px-3 py-2 bg-white">
                <Input
                  type="number"
                  name="salaireMin"
                  value={formData.salaireMin || formData.minSalary || ""}
                  onChange={(e) => setFormData({ 
                    ...formData, 
                    salaireMin: e.target.value,
                    minSalary: e.target.value // Keep for compatibility
                  })}
                  placeholder="Min"
                  className="border-0 focus-visible:ring-0 focus-visible:ring-offset-0 p-0 h-auto text-base"
                />
                <Euro className="w-5 h-5 text-gray-500 flex-shrink-0" />
              </div>
              <span className="text-gray-500 font-medium">-</span>
              <div className="flex-1 flex items-center gap-2 border rounded-lg px-3 py-2 bg-white">
                <Input
                  type="number"
                  name="salaireMax"
                  value={formData.salaireMax || formData.maxSalary || ""}
                  onChange={(e) => setFormData({ 
                    ...formData, 
                    salaireMax: e.target.value,
                    maxSalary: e.target.value // Keep for compatibility
                  })}
                  placeholder="Max"
                  className="border-0 focus-visible:ring-0 focus-visible:ring-offset-0 p-0 h-auto text-base"
                />
                <Euro className="w-5 h-5 text-gray-500 flex-shrink-0" />
              </div>
            </div>
          </div>
        )}
        {isExactSalary && (
          <div className="space-y-4">
            <Label className="text-sm font-medium text-gray-700">Salaire exact</Label>
            <div className="flex items-center gap-2 border rounded-lg px-3 py-2 bg-white max-w-md">
              <Input
                type="number"
                name="salaireMin"
                value={formData.salaireMin || formData.minSalary || ""}
                onChange={(e) => setFormData({ 
                  ...formData, 
                  salaireMin: e.target.value,
                  minSalary: e.target.value // Keep for compatibility
                })}
                placeholder="Montant"
                className="border-0 focus-visible:ring-0 focus-visible:ring-offset-0 p-0 h-auto text-base flex-1"
              />
              <Euro className="w-5 h-5 text-gray-500 flex-shrink-0" />
            </div>
          </div>
        )}
      </div>

      {/* Options supplémentaires pour le salaire - Mieux alignées */}
      {(isExactSalary || isSalaryBracket) && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-6">
          <div className="space-y-2">
            <Label className="text-sm font-medium text-gray-700">Net ou Brut ?</Label>
            <Select
              value={formData.inquiryNetSalary || formData.netSalary || ""}
              onValueChange={(value) => setFormData({ 
                ...formData, 
                inquiryNetSalary: value,
                netSalary: value // Keep for compatibility
              })}
            >
              <SelectTrigger className="h-11">
                <SelectValue placeholder="Net ou Brut ?" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="net">Net</SelectItem>
                <SelectItem value="brut">Brut</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label className="text-sm font-medium text-gray-700">Indice temporel</Label>
            <Select
              value={formData.inquiryUnitSalary || formData.unitSalary || "years"}
              onValueChange={(value) => setFormData({ 
                ...formData, 
                inquiryUnitSalary: value,
                unitSalary: value // Keep for compatibility
              })}
            >
              <SelectTrigger className="h-11">
                <SelectValue placeholder="Indice temporel" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="hours">Heures</SelectItem>
                <SelectItem value="days">Jours</SelectItem>
                <SelectItem value="weeks">Semaines</SelectItem>
                <SelectItem value="months">Mois</SelectItem>
                <SelectItem value="years">Années</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      )}
    </div>

    {/* Télétravail - MyReklam-Web-Old style */}
    <div className={currentStep !== 5 ? "my-8" : ""}>
      <Label className="text-neutral/80 font-semibold">
        Accepteriez-vous un poste en télétravail ?
      </Label>
      <div className="flex my-4 md:flex-row flex-col">
        <RadioGroup
          value={isTelework ? "yes" : "no"}
          onValueChange={(value) => {
            const teleworkValue = value === "yes"
            setIsTelework(teleworkValue)
            setFormData({
              ...formData,
              telework: teleworkValue
            })
          }}
          className="flex md:flex-row flex-col gap-4"
        >
          <div className="w-1/3 mb-2 flex items-center">
            <RadioGroupItem value="yes" id="telework-yes-radio" className="mr-2" />
            <Label htmlFor="telework-yes-radio" className="cursor-pointer">
              Oui
            </Label>
          </div>
          <div className="mt-2 flex items-center">
            <RadioGroupItem value="no" id="telework-no-radio" className="mr-2" />
            <Label htmlFor="telework-no-radio" className="cursor-pointer">
              Non
            </Label>
          </div>
        </RadioGroup>
      </div>
    </div>

    {/* Description de la demande - MyReklam-Web-Old style */}
    <div>
      {currentStep !== 5 ? (
        <InputDescription
          value={formData.inquiryDescription || ""}
          onChange={(value) => setFormData({ 
            ...formData, 
            inquiryDescription: value
          })}
          label="Décrivez votre demande :"
          required
          placeholder="Décrivez en détail ce que vous recherchez..."
        />
      ) : (
        <div>
          <Label htmlFor="inquiryDescription-job">Description :</Label>
          <p className="text-sm text-gray-700 mt-2">
            {formData.inquiryDescription && formData.inquiryDescription.length > 140
              ? formData.inquiryDescription.replace(/<[^>]*>/g, '').substring(0, 140) + "..."
              : formData.inquiryDescription?.replace(/<[^>]*>/g, '') || ""}
          </p>
        </div>
      )}
    </div>

    {/* Documents candidat - MyReklam-Web-Old style */}
    <div className={currentStep !== 5 ? "my-8" : ""}>
      {profiletype === "particulier" && (
        <CandidateDocuments 
          formData={formData}
          setFormData={setFormData}
          addSvg={addSvg}
          handleDocumentChange={handleDocumentChange}
        />
      )}
    </div>

    {/* Réseaux sociaux - MyReklam-Web-Old style (seulement si step != 5) */}
    {currentStep !== 5 && (
      <div className="my-8">
        <Label className="text-neutral/80 font-semibold">
          Partager vos réseaux sociaux professionnels{" "}
          <span className="text-xs font-normal italic">
            (Ceux renseignés dans votre profil):
          </span>
        </Label>
        <ChooseSocial formData={formData} setFormData={setFormData} />
      </div>
    )}
  </div>
)}

                {/* Training specific fields */}
                 {formData.inquiryType === "Training" && (
                  <div className="space-y-6 bg-blue-50 p-6 rounded-lg">
                    <h3 className="text-lg font-semibold text-blue-800 mb-4">Détails de la formation recherchée</h3>
                    
                    {/* Catégorie de formation */}
                    <div>
                      <Label>Catégorie de la formation recherchée *</Label>
                      <Select
                        value={formData.inquiryTrainingCategory}
                        onValueChange={(value) => setFormData({ 
                          ...formData, 
                          inquiryTrainingCategory: value,
                          inquirytrainingsecteur: "" // Reset secteur
                        })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Sélectionnez une catégorie" />
                        </SelectTrigger>
                        <SelectContent>
                          {trainingCategories.map((category) => (
                            <SelectItem key={category.id} value={category.code}>
                              {category.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    {/* Secteur de formation */}
                    {formData.inquiryTrainingCategory && subCategories.length > 0 && (
                      <div>
                        <Label>Secteur de formation recherché *</Label>
                        <Select
                          value={formData.inquirytrainingsecteur}
                          onValueChange={(value) => setFormData({ ...formData, inquirytrainingsecteur: value })}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Sélectionnez un secteur" />
                          </SelectTrigger>
                          <SelectContent>
                            {subCategories.map((subCategory: Category) => (
                              <SelectItem key={subCategory.id} value={subCategory.code}>
                                {subCategory.label}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    )}

                    {/* Type de formation */}
                    <div>
                      <Label>Type de formation recherché *</Label>
                      <Select
                        value={formData.inquiryTrainingType}
                        onValueChange={(value) => setFormData({ ...formData, inquiryTrainingType: value })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Sélectionnez un type" />
                        </SelectTrigger>
                        <SelectContent>
                          {trainingTypes.map((type) => (
                            <SelectItem key={type} value={type}>
                              {getLabel(type)}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    {/* Intitulé de la formation */}
                    <div>
                      <Label htmlFor="inquiryTitle">Intitulé de la formation recherchée *</Label>
                      <Input
                        id="inquiryTitle"
                        value={formData.inquiryTitle}
                        onChange={(e) => setFormData({ ...formData, inquiryTitle: e.target.value })}
                        placeholder="Ex: Formation aide soignante"
                      />
                    </div>

                    {/* Type d'enseignement */}
                    <div>
                      <Label>Type d'enseignement * (Choix multiple possible)</Label>
                      <div className="grid grid-cols-2 gap-2 max-h-32 overflow-auto bg-gray-50 p-3 rounded-lg">
                        {teachingTypes.map((type) => (
                          <div key={type} className="flex items-center space-x-2">
                            <Checkbox
                              id={`teaching-${type}`}
                              checked={formData.inquiryTrainingStyle.includes(type)}
                              onCheckedChange={(checked) => {
                                if (checked) {
                                  // Si "Indifferent" est sélectionné, sélectionner tous
                                  if (type === "Indifferent") {
                                    setFormData({ ...formData, inquiryTrainingStyle: [...teachingTypes] })
                                  } else {
                                    setFormData({ 
                                      ...formData, 
                                      inquiryTrainingStyle: [...formData.inquiryTrainingStyle, type] 
                                    })
                                  }
                                } else {
                                  // Retirer le type ou tout déselectionner si "Indifferent"
                                  if (type === "Indifferent") {
                                    setFormData({ ...formData, inquiryTrainingStyle: [] })
                                  } else {
                                    setFormData({ 
                                      ...formData, 
                                      inquiryTrainingStyle: formData.inquiryTrainingStyle.filter(t => t !== type && t !== "Indifferent") 
                                    })
                                  }
                                }
                              }}
                            />
                            <Label htmlFor={`teaching-${type}`} className="cursor-pointer font-normal">
                              {getLabel(type)}
                            </Label>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Financement */}
                    <div>
                      <Label>Financement * (Choix multiple possible)</Label>
                      <div className="grid grid-cols-2 gap-2 max-h-32 overflow-auto bg-gray-50 p-3 rounded-lg">
                        {fundings.map((funding) => (
                          <div key={funding} className="flex items-center space-x-2">
                            <Checkbox
                              id={`funding-${funding}`}
                              checked={formData.inquiryTrainingFunding.includes(funding)}
                              onCheckedChange={(checked) => {
                                if (checked) {
                                  if (funding === "Indifferent") {
                                    setFormData({ ...formData, inquiryTrainingFunding: [...fundings] })
                                  } else {
                                    setFormData({ 
                                      ...formData, 
                                      inquiryTrainingFunding: [...formData.inquiryTrainingFunding, funding] 
                                    })
                                  }
                                } else {
                                  if (funding === "Indifferent") {
                                    setFormData({ ...formData, inquiryTrainingFunding: [] })
                                  } else {
                                    setFormData({ 
                                      ...formData, 
                                      inquiryTrainingFunding: formData.inquiryTrainingFunding.filter(f => f !== funding && f !== "Indifferent") 
                                    })
                                  }
                                }
                              }}
                            />
                            <Label htmlFor={`funding-${funding}`} className="cursor-pointer font-normal">
                              {getLabel(funding)}
                            </Label>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Disponibilités */}
                    <div>
                      <Label>Quelles sont vos disponibilités ?</Label>
                      <div className="space-y-4 mt-2">
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="immediate"
                            checked={isEmergent}
                            onCheckedChange={(checked) => {
                              setIsEmergent(checked as boolean)
                              if (checked) {
                                setFormData({ ...formData, startDate: "", endDate: "" })
                              }
                            }}
                          />
                          <Label htmlFor="immediate" className="cursor-pointer">
                            Dans l'immédiat
                          </Label>
                        </div>
                        
                        {!isEmergent && (
                          <div className="grid grid-cols-2 gap-4 ml-6">
                            <div>
                              <Label htmlFor="startDate">À partir du :</Label>
                              <Input
                                id="startDate"
                                type="date"
                                value={formData.startDate}
                                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                                max={formData.endDate}
                              />
                            </div>
                            <div>
                              <Label htmlFor="endDate">Jusqu'au (facultatif) :</Label>
                              <Input
                                id="endDate"
                                type="date"
                                value={formData.endDate}
                                onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                                min={formData.startDate}
                              />
                            </div>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Niveau d'étude et expérience pour particuliers */}
                    {profiletype === "particulier" && 
                     formData.inquiryTrainingType !== "CertificationProgram" && 
                     formData.inquiryTrainingType !== "ContinuingEducation" && (
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label>Votre niveau d'étude *</Label>
                          <Select
                            value={formData.inquiryStudyLevel}
                            onValueChange={(value) => setFormData({ ...formData, inquiryStudyLevel: value })}
                          >
                            <SelectTrigger>
                              <SelectValue placeholder="Niveau d'étude" />
                            </SelectTrigger>
                            <SelectContent>
                              {studyLevels.map((level) => (
                                <SelectItem key={level} value={level}>
                                  {getLabel(level)}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>
                        <div>
                          <Label>Votre niveau d'expérience *</Label>
                          <Select
                            value={formData.inquiryXpLevel}
                            onValueChange={(value) => setFormData({ ...formData, inquiryXpLevel: value })}
                          >
                            <SelectTrigger>
                              <SelectValue placeholder="Niveau d'expérience" />
                            </SelectTrigger>
                            <SelectContent>
                              {experienceLevels.map((level) => (
                                <SelectItem key={level} value={level}>
                                  {getLabel(level)}
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>
                      </div>
                    )}

                    {/* Description de la demande */}
                    <InputDescription
                      value={formData.inquiryDescription || ""}
                      onChange={(value) => setFormData({ 
                        ...formData, 
                        inquiryDescription: value
                      })}
                      label="Décrivez votre demande de formation *"
                      required
                      placeholder="Décrivez en détail la formation que vous recherchez..."
                    />

                    {/* Documents */}
                    <div>
                      <Label>
                        Ajouter des documents{" "}
                        <span className="text-xs font-normal italic text-gray-500">
                          {profiletype === "particulier" 
                            ? "(CV, Lettre de motivation, Portfolio etc...)" 
                            : "(Portfolio etc...)"}
                        </span>
                      </Label>
                      
                      {/* Documents existants */}
                      {formData.documents.length > 0 && (
                        <div className="space-y-2 mb-4">
                          {formData.documents.map((doc, index) => (
                            <div key={doc.id} className="flex items-center justify-between bg-gray-100 p-2 rounded">
                              <div className="flex items-center gap-2">
                                <FileText className="w-4 h-4" />
                                <span className="text-sm">{doc.name}</span>
                              </div>
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => {
                                  setFormData({
                                    ...formData,
                                    documents: formData.documents.filter((_, i) => i !== index),
                                    documentsFiles: formData.documentsFiles.filter((_, i) => i !== index)
                                  })
                                }}
                              >
                                ✕
                              </Button>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Zone d'upload */}
                      <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-purple-400 transition-colors">
                        <input
                          type="file"
                          accept="image/*,video/*,.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx"
                          multiple
                          onChange={handleDocumentChange}
                          className="hidden"
                          id="document-upload"
                        />
                        <label htmlFor="document-upload" className="cursor-pointer">
                          <div className="w-8 h-8 mx-auto mb-2">{addSvg}</div>
                          <p className="text-gray-600">Ajouter des fichiers</p>
                        </label>
                      </div>
                    </div>

                    {/* Nombre de personnes (pour professionnels) */}
                    {profiletype !== "particulier" && (
                      <div>
                        <Label>Nombre de personnes ou de groupes à former *</Label>
                        <div className="flex flex-wrap gap-4 mt-2">
                          <div className="flex items-center gap-2">
                            <Input
                              type="number"
                              placeholder="Nb personnes"
                              value={formData.nbrpeople}
                              onChange={(e) => setFormData({ 
                                ...formData, 
                                nbrpeople: e.target.value,
                                nbrgroup: Math.min(Number(formData.nbrgroup) || 0, Number(e.target.value) || 0).toString()
                              })}
                              disabled={formData.indifferent}
                              className="w-32"
                            />
                            <span>Personne(s)</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <Input
                              type="number"
                              placeholder="Nb groupes"
                              value={formData.nbrgroup}
                              onChange={(e) => setFormData({ ...formData, nbrgroup: e.target.value })}
                              disabled={formData.indifferent}
                              className="w-32"
                            />
                            <span>Groupe(s)</span>
                          </div>
                          <div className="flex items-center gap-2">
                            <Checkbox
                              id="indifferent"
                              checked={formData.indifferent}
                              onCheckedChange={(checked) => setFormData({ 
                                ...formData, 
                                indifferent: checked as boolean,
                                nbrpeople: checked ? "" : formData.nbrpeople,
                                nbrgroup: checked ? "" : formData.nbrgroup
                              })}
                            />
                            <Label htmlFor="indifferent" className="cursor-pointer">
                              À définir
                            </Label>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Réseaux sociaux - MyReklam-Web-Old style (seulement si step != 5) */}
                    {currentStep !== 5 && (
                      <div className="my-8">
                        <Label className="text-neutral/80 font-semibold">
                          Partager vos réseaux sociaux professionnels{" "}
                          <span className="text-xs font-normal italic">
                            (Ceux renseignés dans votre profil):
                          </span>
                        </Label>
                        <ChooseSocial formData={formData} setFormData={setFormData} />
                      </div>
                    )}
                  </div>
                )}


                {/* Real Estate specific fields */}
                {/* {formData.inquiryType === "RealEstate" && (
                  <>
                    <div>
                      <Label>Type de bien</Label>
                      <Select
                        value={formData.realEstateType}
                        onValueChange={(value) => setFormData({ ...formData, realEstateType: value })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Sélectionnez un type" />
                        </SelectTrigger>
                        <SelectContent>
                          {realEstateTypes.map((type) => (
                            <SelectItem key={type} value={type}>
                              {getLabel(type)}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <Label htmlFor="surface">Surface (m²)</Label>
                        <Input
                          id="surface"
                          type="number"
                          value={formData.surface}
                          onChange={(e) => setFormData({ ...formData, surface: e.target.value })}
                          placeholder="Ex: 80"
                        />
                      </div>
                      <div>
                        <Label htmlFor="rooms">Nombre de pièces</Label>
                        <Input
                          id="rooms"
                          type="number"
                          value={formData.rooms}
                          onChange={(e) => setFormData({ ...formData, rooms: e.target.value })}
                          placeholder="Ex: 3"
                        />
                      </div>
                    </div>

                    <div>
                      <Label htmlFor="maxPrice">Budget maximum (€)</Label>
                      <Input
                        id="maxPrice"
                        type="number"
                        value={formData.maxPrice}
                        onChange={(e) => setFormData({ ...formData, maxPrice: e.target.value })}
                        placeholder="Ex: 250000"
                      />
                    </div>
                  </>
                )} */}

{/* Real Estate specific fields */}
{formData.inquiryType === "RealEstate" && (
  <div className="space-y-6 bg-orange-50 p-6 rounded-lg">
    <h3 className="text-lg font-semibold text-orange-800 mb-4">Détails de votre recherche immobilière</h3>

    {/* Type de bien */}
    {formData.inquiryTypeCategory && (
      <div>
        <Label>Type de bien * (Choix multiple possible)</Label>
        <div className="grid grid-cols-2 gap-2 max-h-32 overflow-auto bg-gray-50 p-3 rounded-lg">
          {(formData.inquiryTypeCategory === "LookingForProfessionalSpace" 
            ? professionalSpaceGood 
            : goodTypes
          ).map((type) => (
            <div key={type} className="flex items-center space-x-2">
              <Checkbox
                id={`realEstate-${type}`}
                checked={formData.realEstateType.includes(type)}
                onCheckedChange={(checked) => {
                  if (checked) {
                    setFormData({ 
                      ...formData, 
                      realEstateType: [...formData.realEstateType, type] 
                    })
                  } else {
                    setFormData({
                      ...formData,
                      realEstateType: formData.realEstateType.filter((t: string) => t !== type),
                    })
                  }
                }}
              />
              <Label htmlFor={`realEstate-${type}`} className="cursor-pointer font-normal">
                {getLabel(type)}
              </Label>
            </div>
          ))}
        </div>
      </div>
    )}

    {/* Titre de la demande */}
    <div>
      <Label htmlFor="inquiryTitle-real">Quel est le titre de la demande ? *</Label>
      <Input
        id="inquiryTitle-real"
        value={formData.inquiryTitle}
        onChange={(e) => setFormData({ ...formData, inquiryTitle: e.target.value })}
        placeholder="Ex: Appartement 3 pièces centre-ville"
      />
      <p className="text-xs text-gray-500 mt-1">Inutile de préciser le mot "recherche"</p>
    </div>

    {/* Budget */}
    <div>
      <Label>Quel est votre budget ?</Label>
      <p className="text-xs text-gray-500 mb-2">Vous pouvez n'indiquer qu'un seul des deux, les deux ou aucun</p>
      <div className="grid grid-cols-2 gap-4">
        <div className="relative">
          <Input
            type="number"
            placeholder="Budget minimum"
            value={formData.budgetMin}
            onChange={(e) => setFormData({ ...formData, budgetMin: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">€</span>
        </div>
        <div className="relative">
          <Input
            type="number"
            placeholder="Budget maximum"
            value={formData.budgetMax}
            onChange={(e) => setFormData({ ...formData, budgetMax: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">€</span>
        </div>
      </div>
    </div>

    {/* Surface habitable */}
    <div>
      <Label>Pour quelle surface habitable ?</Label>
      <div className="grid grid-cols-2 gap-4">
        <div className="relative">
          <Input
            type="number"
            placeholder="Minimum"
            value={formData.livingSpaceMin}
            onChange={(e) => setFormData({ ...formData, livingSpaceMin: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">m²</span>
        </div>
        <div className="relative">
          <Input
            type="number"
            placeholder="Maximum"
            value={formData.livingSpaceMax}
            onChange={(e) => setFormData({ ...formData, livingSpaceMax: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">m²</span>
        </div>
      </div>
    </div>

    {/* Surface terrain */}
    <div>
      <Label>Pour quelle surface de terrain ?</Label>
      <div className="grid grid-cols-2 gap-4">
        <div className="relative">
          <Input
            type="number"
            placeholder="Minimum"
            value={formData.groundSpaceMin}
            onChange={(e) => setFormData({ ...formData, groundSpaceMin: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">m²</span>
        </div>
        <div className="relative">
          <Input
            type="number"
            placeholder="Maximum"
            value={formData.groundSpaceMax}
            onChange={(e) => setFormData({ ...formData, groundSpaceMax: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">m²</span>
        </div>
      </div>
    </div>

    {/* Nombre de pièces (sauf pour les locaux professionnels) */}
    {formData.inquiryTypeCategory !== "LookingForProfessionalSpace" && (
      <div>
        <Label>Combien de pièces souhaitez-vous ?</Label>
        <div className="flex flex-wrap gap-3 mt-2">
          {["1", "2", "3", "4", "5", "0"].map((piece) => (
            <label
              key={piece}
              className={`flex items-center gap-2 px-4 py-2 border rounded-full cursor-pointer transition-colors ${
                formData.piece === piece
                  ? "bg-orange-600 text-white border-orange-600"
                  : "bg-white text-gray-700 border-gray-300 hover:border-orange-400"
              }`}
            >
              <input
                type="radio"
                name="piece"
                value={piece}
                checked={formData.piece === piece}
                onChange={() => setFormData({ ...formData, piece })}
                className="hidden"
              />
              {piece === "0" ? "Indifférent" : piece === "5" ? "5 ou +" : piece}
            </label>
          ))}
        </div>
      </div>
    )}

    {/* Nombre de chambres (sauf pour les locaux professionnels) */}
    {formData.inquiryTypeCategory !== "LookingForProfessionalSpace" && (
      <div>
        <Label>Combien de chambres souhaitez-vous ?</Label>
        <div className="flex flex-wrap gap-3 mt-2">
          {["1", "2", "3", "4", "5", "0"].map((bedroom) => (
            <label
              key={bedroom}
              className={`flex items-center gap-2 px-4 py-2 border rounded-full cursor-pointer transition-colors ${
                formData.bedroom === bedroom
                  ? "bg-orange-600 text-white border-orange-600"
                  : "bg-white text-gray-700 border-gray-300 hover:border-orange-400"
              }`}
            >
              <input
                type="radio"
                name="bedroom"
                value={bedroom}
                checked={formData.bedroom === bedroom}
                onChange={() => setFormData({ ...formData, bedroom })}
                className="hidden"
              />
              {bedroom === "0" ? "Indifférent" : bedroom === "5" ? "5 ou +" : bedroom}
            </label>
          ))}
        </div>
      </div>
    )}

    {/* Meublé/Non-meublé (sauf pour investissement) */}
    {formData.inquiryTypeCategory !== "RealEstateInvestment" && (
      <div>
        <Label>Meublé / Non-Meublé</Label>
        <div className="flex flex-wrap gap-3 mt-2">
          {[
            { label: "Meublé", value: "0" },
            { label: "Non-Meublé", value: "1" },
            { label: "Indifférent", value: "2" }
          ].map(({ label, value }) => (
            <label
              key={value}
              className={`flex items-center gap-2 px-4 py-2 border rounded-full cursor-pointer transition-colors ${
                formData.furniture === value
                  ? "bg-orange-600 text-white border-orange-600"
                  : "bg-white text-gray-700 border-gray-300 hover:border-orange-400"
              }`}
            >
              <input
                type="radio"
                name="furniture"
                value={value}
                checked={formData.furniture === value}
                onChange={() => setFormData({ ...formData, furniture: value })}
                className="hidden"
              />
              {label}
            </label>
          ))}
        </div>
      </div>
    )}

    {/* Description */}
    <InputDescription
      value={formData.inquiryDescription || ""}
      onChange={(value) => setFormData({ 
        ...formData, 
        inquiryDescription: value
      })}
      label="Décrivez votre demande *"
      required
      placeholder="Décrivez en détail ce que vous recherchez..."
    />
  </div>
)}

{/* Autres types de demandes (Services, Equipements, etc.) */}
    {!["Training", "JobSearchInternship", "SearchInternship", "SearchJob", "RealEstate"].includes(formData.inquiryType) && formData.inquiryType && (
  <div className="space-y-6 bg-indigo-50 p-6 rounded-lg">
    <h3 className="text-lg font-semibold text-indigo-800 mb-4">
      Détails de votre demande
    </h3>

    {/* Titre */}
    <div>
      <Label htmlFor="inquiryTitle-other">Titre de votre demande *</Label>
      <Input
        id="inquiryTitle-other"
        value={formData.inquiryTitle}
        onChange={(e) => setFormData({ ...formData, inquiryTitle: e.target.value })}
        placeholder="Titre de l'annonce"
      />
    </div>

    {/* Description */}
    <InputDescription
      value={formData.inquiryDescription || ""}
      onChange={(value) => setFormData({ 
        ...formData, 
        inquiryDescription: value
      })}
      label="Description de votre demande *"
      required
      placeholder="Décrivez en détail votre demande..."
    />

    {/* Disponibilités */}
    <div>
      <Label>Quel serait le délai idéal pour répondre à votre demande ?</Label>
      <div className="space-y-4 mt-2">
        <div className="flex items-center space-x-2">
          <Checkbox
            id="immediate-other"
            checked={isEmergent}
            onCheckedChange={(checked) => {
              setIsEmergent(checked as boolean)
              if (checked) {
                setFormData({ ...formData, startDate: "", endDate: "" })
              }
            }}
          />
          <Label htmlFor="immediate-other" className="cursor-pointer">
            Dans l'immédiat
          </Label>
        </div>
        
        {!isEmergent && (
          <div className="grid grid-cols-2 gap-4 ml-6">
            <div>
              <Label htmlFor="startDate-other">À partir du :</Label>
              <Input
                id="startDate-other"
                type="date"
                value={formData.startDate}
                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                max={formData.endDate}
              />
            </div>
            <div>
              <Label htmlFor="endDate-other">Jusqu'au (facultatif) :</Label>
              <Input
                id="endDate-other"
                type="date"
                value={formData.endDate}
                onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
                min={formData.startDate}
              />
            </div>
          </div>
        )}
      </div>
    </div>

    {/* Date flexible (pour les vacances) */}
    {formData.inquiryType === "Vacations" && (
      <div className="flex items-center space-x-2">
        <Checkbox
          id="flexible"
          checked={formData.flexible}
          onCheckedChange={(checked) => setFormData({ ...formData, flexible: checked as boolean })}
        />
        <Label htmlFor="flexible" className="cursor-pointer">
          <span className="font-medium">Date flexible</span>
          <span className="text-sm text-gray-500 ml-2">(Dates +/- 1 à 3 jours)</span>
        </Label>
      </div>
    )}

    {/* Budget */}
    <div>
      <Label>Quel est votre budget ?</Label>
      <p className="text-xs text-gray-500 mb-2">
        Vous pouvez n'indiquer qu'un seul des deux, les deux ou aucun (facultatif)
      </p>
      <div className="grid grid-cols-2 gap-4">
        <div className="relative">
          <Input
            type="number"
            placeholder="Budget minimum"
            value={formData.budgetMin}
            onChange={(e) => setFormData({ ...formData, budgetMin: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">€</span>
        </div>
        <div className="relative">
          <Input
            type="number"
            placeholder="Budget maximum"
            value={formData.budgetMax}
            onChange={(e) => setFormData({ ...formData, budgetMax: e.target.value })}
          />
          <span className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400">€</span>
        </div>
      </div>
    </div>
  </div>
)}
                {/* Services specific fields */}
                {/* {formData.inquiryType === "ServicesAssistance" && (
                  <>
                    <div>
                      <Label>Type de service</Label>
                      <Select
                        value={formData.serviceType}
                        onValueChange={(value) => setFormData({ ...formData, serviceType: value })}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Sélectionnez un type" />
                        </SelectTrigger>
                        <SelectContent>
                          {serviceTypes.map((type) => (
                            <SelectItem key={type} value={type}>
                              {getLabel(type)}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>

                    <div>
                      <Label htmlFor="serviceFrequency">Fréquence souhaitée</Label>
                      <Input
                        id="serviceFrequency"
                        value={formData.serviceFrequency}
                        onChange={(e) => setFormData({ ...formData, serviceFrequency: e.target.value })}
                        placeholder="Ex: Une fois, Hebdomadaire, Mensuel..."
                      />
                    </div>
                  </>
                )} */}

                {/* Common fields continued */}
                {/* <div>
                  <Label htmlFor="budget">Budget estimé (€)</Label>
                  <div className="relative">
                    <Euro className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <Input
                      id="budget"
                      type="number"
                      value={formData.budget}
                      onChange={(e) => setFormData({ ...formData, budget: e.target.value })}
                      placeholder="Ex: 500"
                      className="pl-10"
                    />
                  </div>
                </div> */}

                {/* <div>
                  <Label htmlFor="urgency">Niveau d'urgence *</Label>
                  <Select
                    value={formData.urgency}
                    onValueChange={(value) => setFormData({ ...formData, urgency: value })}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {urgencyLevels.map((level) => (
                        <SelectItem key={level} value={level}>
                          <span className={URGENCY_CONFIG[level as keyof typeof URGENCY_CONFIG].textColor}>
                            {URGENCY_CONFIG[level as keyof typeof URGENCY_CONFIG].label}
                          </span>
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div> */}

                {/* <div>
                  <div className="flex items-center space-x-2 mb-2">
                    <Checkbox
                      id="allFrance"
                      checked={formData.allFrance}
                      onCheckedChange={(checked) => setFormData({ ...formData, allFrance: checked as boolean })}
                    />
                    <Label htmlFor="allFrance" className="font-normal cursor-pointer">
                      Toute la France
                    </Label>
                  </div>

                  {!formData.allFrance && (
                    <div>
                      <Label>Localisation</Label>
                      <InputComponents.Autocomplete
                        label=""
                        value={formData.location}
                        onChange={(value) => setFormData({ ...formData, location: value })}
                          options={citiesData.map((city) => ({
                            value: `${city.name} (${city.zipcode})`,
                            label: `${city.name} (${city.zipcode})`,
                          }))}
                        placeholder="Rechercher une commune..."
                      />
                    </div>
                  )}
                </div> */}

                {/* <div>
                  <Label htmlFor="deadline">Date limite (optionnel)</Label>
                  <Input
                    id="deadline"
                    type="date"
                    value={formData.deadline}
                    onChange={(e) => setFormData({ ...formData, deadline: e.target.value })}
                  />
                </div> */}
              </motion.div>
            )}

            {/* Step 3: Location */}
            {currentStep === 3 && (
              <motion.div
                key="step3"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="space-y-6"
              >
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 mb-4">Localisation de votre demande</h3>
                  
                  {/* Toute la France */}
                  <div className="mb-4">
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="allFrance-location"
                        checked={formData.allFrance}
                        onCheckedChange={(checked) => {
                          setFormData({ 
                            ...formData, 
                            allFrance: checked as boolean,
                            address: checked ? {
                              country: "France",
                              city: "",
                              zipcode: "",
                              latitude: 46.603354,
                              longitude: 1.888334,
                              line1: "",
                              line2: "",
                            } : formData.address,
                            ray: checked ? 0 : formData.ray,
                          })
                        }}
                      />
                      <Label htmlFor="allFrance-location" className="cursor-pointer font-medium">
                        Toute la France
                      </Label>
                    </div>
                  </div>

                  {!formData.allFrance && (
                    <>
                      {/* Recherche de ville */}
                      <div className="mb-4 relative">
                        <Label htmlFor="city-search">Localisation *</Label>
                        <div className="relative">
                          <MapPin className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
                          <Input 
                            id="city-search" 
                            type="text" 
                            placeholder="Ville, code postal..." 
                            className="pl-10 pr-12"
                            value={citySearchTerm || formData.location || ""}
                            onChange={(e) => {
                              const value = e.target.value
                              setCitySearchTerm(value)
                              setShowCitySuggestions(value.length >= 2)
                              // Mettre à jour formData.location pour l'affichage
                              setFormData({
                                ...formData,
                                location: value,
                              })
                            }}
                            onFocus={() => (citySearchTerm || formData.location || "").length >= 2 && setShowCitySuggestions(true)}
                            onBlur={() => setTimeout(() => setShowCitySuggestions(false), 200)}
                          />
                        </div>

                        {/* Suggestions de villes */}
                        {showCitySuggestions && citySuggestions.length > 0 && (
                          <div className="absolute z-50 mt-1 w-full bg-white border border-gray-200 rounded-md shadow-lg max-h-60 overflow-auto">
                            {citySuggestions.map((city, index) => (
                              <button
                                key={`${city.name}-${city.zipcode}-${index}`}
                                type="button"
                                className="w-full px-4 py-2 text-left hover:bg-gray-50 flex items-center justify-between"
                                onClick={async () => {
                                  const cityValue = `${city.name} (${city.zipcode})`
                                  setCitySearchTerm(cityValue)
                                  setShowCitySuggestions(false)
                                  
                                  // Géocoder la ville pour obtenir les coordonnées
                                  try {
                                    const response = await fetch(
                                      `https://nominatim.openstreetmap.org/search?city=${encodeURIComponent(city.name)}&postalcode=${city.zipcode}&country=France&format=json&limit=1`,
                                      {
                                        headers: {
                                          'User-Agent': 'MyReklam-Web'
                                        }
                                      }
                                    )
                                    const data = await response.json()
                                    
                                    if (data && data.length > 0) {
                                      setFormData({
                                        ...formData,
                                        address: {
                                          ...formData.address,
                                          city: city.name,
                                          zipcode: city.zipcode,
                                          country: "France",
                                          latitude: parseFloat(data[0].lat),
                                          longitude: parseFloat(data[0].lon),
                                        },
                                        location: cityValue,
                                      })
                                    } else {
                                      // Si pas de résultat, on met quand même la ville sans coordonnées
                                      setFormData({
                                        ...formData,
                                        address: {
                                          ...formData.address,
                                          city: city.name,
                                          zipcode: city.zipcode,
                                          country: "France",
                                        },
                                        location: cityValue,
                                      })
                                    }
                                  } catch (error) {
                                    console.error('Erreur de géocodage:', error)
                                    // En cas d'erreur, on met quand même la ville
                                    setFormData({
                                      ...formData,
                                      address: {
                                        ...formData.address,
                                        city: city.name,
                                        zipcode: city.zipcode,
                                        country: "France",
                                      },
                                      location: cityValue,
                                    })
                                  }
                                }}
                              >
                                <div>
                                  <div className="font-medium">{city.name}</div>
                                  <div className="text-sm text-gray-500">{city.region}</div>
                                </div>
                                <div className="text-sm text-gray-400">{city.zipcode}</div>
                              </button>
                            ))}
                          </div>
                        )}
                      </div>

                      {/* Géolocalisation */}
                      <div className="mb-4">
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id="useGeolocation"
                            checked={formData.useGeolocation}
                            onCheckedChange={(checked) => {
                              setFormData({ 
                                ...formData, 
                                useGeolocation: checked as boolean 
                              })
                              
                              if (checked && navigator.geolocation) {
                                navigator.geolocation.getCurrentPosition(
                                  async (position) => {
                                    const lat = position.coords.latitude
                                    const lon = position.coords.longitude
                                    
                                    try {
                                      // Utiliser l'API Nominatim pour le reverse geocoding
                                      const response = await fetch(
                                        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=10&addressdetails=1`,
                                        {
                                          headers: {
                                            'User-Agent': 'MyReklam-Web'
                                          }
                                        }
                                      )
                                      const data = await response.json()
                                      
                                      const city = data.address?.city || data.address?.town || data.address?.village || ""
                                      const zipcode = data.address?.postcode || ""
                                      
                                      if (city) {
                                        setFormData({
                                          ...formData,
                                          address: {
                                            ...formData.address,
                                            city: city,
                                            zipcode: zipcode,
                                            country: "France",
                                            latitude: lat,
                                            longitude: lon,
                                          },
                                          location: zipcode ? `${city} (${zipcode})` : city,
                                          useGeolocation: true,
                                        })
                                      } else {
                                        // Si on ne trouve pas de ville, juste mettre les coordonnées
                                        setFormData({
                                          ...formData,
                                          address: {
                                            ...formData.address,
                                            latitude: lat,
                                            longitude: lon,
                                          },
                                          location: "Ma position",
                                          useGeolocation: true,
                                        })
                                      }
                                    } catch (error) {
                                      console.error("Erreur lors du reverse geocoding:", error)
                                      // En cas d'erreur, juste mettre les coordonnées
                                      setFormData({
                                        ...formData,
                                        address: {
                                          ...formData.address,
                                          latitude: lat,
                                          longitude: lon,
                                        },
                                        location: "Ma position",
                                        useGeolocation: true,
                                      })
                                    }
                                  },
                                  (error) => {
                                    console.error("Error getting geolocation:", error)
                                    setFormData({ 
                                      ...formData, 
                                      useGeolocation: false 
                                    })
                                  }
                                )
                              }
                            }}
                          />
                          <Label htmlFor="useGeolocation" className="cursor-pointer">
                            Utiliser ma position actuelle
                          </Label>
                        </div>
                      </div>

                      {/* Distance avec slider et carte */}
                      <div className="mb-4 space-y-4">
                        <div className="flex items-center justify-between">
                          <Label>Rayon de recherche</Label>
                          <span className="text-sm font-semibold text-teal-600">
                            {formData.ray === 0 ? "Ville uniquement" : `${formData.ray} km`}
                          </span>
                        </div>
                        <Slider
                          value={[formData.ray || 0]}
                          onValueChange={(value) => {
                            setFormData({
                              ...formData,
                              ray: value[0],
                            })
                          }}
                          max={200}
                          step={5}
                          className="w-full"
                        />
                        <div className="flex justify-between text-xs text-gray-500">
                          <span>0 km</span>
                          <span>50 km</span>
                          <span>100 km</span>
                          <span>150 km</span>
                          <span>200 km</span>
                        </div>
                        
                        {/* Carte interactive avec rayon */}
                        {formData.address?.latitude && formData.address?.longitude && formData.ray > 0 && (
                          <div className="mt-4">
                            <MapWithRadius
                              center={[formData.address.latitude, formData.address.longitude]}
                              radius={formData.ray}
                              locationName={formData.address.city || ''}
                            />
                          </div>
                        )}
                      </div>
                    </>
                  )}

                  {/* Afficher la localisation Google */}
                  <div className="mb-4">
                    <div className="flex items-center space-x-2">
                      <Checkbox
                        id="show-location"
                        checked={formData.show}
                        onCheckedChange={(checked) => {
                          setFormData({ 
                            ...formData, 
                            show: checked as boolean 
                          })
                        }}
                      />
                      <Label htmlFor="show-location" className="cursor-pointer">
                        Afficher la localisation Google sur l'annonce
                      </Label>
                    </div>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Step 4: Photos */}
            {currentStep === 4 && (
              <motion.div
                key="step4"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="space-y-6"
              >
                {existingImages.length > 0 && (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="text-lg font-semibold text-gray-900">Photos déjà publiées</h4>
                        <p className="text-sm text-gray-600">Supprimez les photos que vous ne souhaitez plus afficher.</p>
                      </div>
                      <span className="text-sm font-medium text-gray-500">{existingImages.length} photo(s)</span>
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

                <div>
                  <Label>Photos (optionnel)</Label>
                  <p className="text-sm text-gray-500 mb-4">
                    Ajoutez des photos pour illustrer votre demande (maximum 5 photos)
                  </p>

                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-purple-400 transition-colors">
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={handlePhotoUpload}
                      className="hidden"
                      id="photo-upload"
                      disabled={formData.photos.length >= 5}
                    />
                    <label htmlFor="photo-upload" className="cursor-pointer">
                      <ImageIcon className="w-12 h-12 mx-auto text-gray-400 mb-4" />
                      <p className="text-gray-600 mb-2">
                        {formData.photos.length >= 5
                          ? "Limite de 5 photos atteinte"
                          : "Cliquez pour ajouter des photos"}
                      </p>
                      <p className="text-sm text-gray-400">PNG, JPG jusqu'à 10MB</p>
                    </label>
                  </div>

                  {formData.photos.length > 0 && (
                    <div className="grid grid-cols-3 gap-4 mt-4">
                      {formData.photos.map((photo, index) => (
                        <div key={index} className="relative group">
                          <img
                            src={URL.createObjectURL(photo) || "/placeholder.svg"}
                            alt={`Photo ${index + 1}`}
                            className="w-full h-32 object-cover rounded-lg"
                          />
                          <button
                            onClick={() => removePhoto(index)}
                            className="absolute top-2 right-2 bg-red-500 text-white rounded-full p-1 opacity-0 group-hover:opacity-100 transition-opacity"
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
                  )}
                </div>
              </motion.div>
            )}

            {/* Step 5: Summary */}
            {/* Step 5: Summary */}
{currentStep === 5 && (
  <motion.div
    key="step4"
    initial={{ opacity: 0 }}
    animate={{ opacity: 1 }}
    exit={{ opacity: 0 }}
    className="space-y-6"
  >
    <div className="text-center mb-6">
      <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-purple-500 to-purple-600 rounded-full shadow-lg mb-4">
        <Check className="w-8 h-8 text-white" />
      </div>
      <h3 className="text-2xl font-bold text-gray-900 mb-2">Vérifiez votre demande</h3>
      <p className="text-gray-600">Relisez les informations avant de publier votre demande</p>
    </div>

    <div className="space-y-6">
      {/* Nature de la demande */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0 }}
        className="bg-gray-50 rounded-xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h4 className="text-lg font-semibold text-gray-900">Nature de la demande</h4>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setCurrentStep(1)}
            className="text-purple-600 hover:text-purple-700 hover:bg-purple-50"
          >
            <Edit2 className="w-4 h-4 mr-2" />
            Modifier
          </Button>
        </div>
        <div className="space-y-3">
          <div className="flex justify-between items-start gap-4">
            <span className="text-sm text-gray-600 font-medium flex-shrink-0">Type</span>
            <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
              {inquiryCategories.find(cat => cat.code === formData.inquiryType)?.label || formData.inquiryType}
            </span>
          </div>
        </div>
      </motion.div>

      {/* Informations générales */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bg-gray-50 rounded-xl p-6"
      >
        <div className="flex items-center justify-between mb-4">
          <h4 className="text-lg font-semibold text-gray-900">Informations générales</h4>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setCurrentStep(2)}
            className="text-purple-600 hover:text-purple-700 hover:bg-purple-50"
          >
            <Edit2 className="w-4 h-4 mr-2" />
            Modifier
          </Button>
        </div>
        <div className="space-y-3">
          {(formData.title || formData.inquiryTitle) && (
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-gray-600 font-medium flex-shrink-0">Titre</span>
              <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                {formData.title || formData.inquiryTitle}
              </span>
            </div>
          )}
          {(formData.description || formData.inquiryDescription) && (
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-gray-600 font-medium flex-shrink-0">Description</span>
              <span className="text-sm text-gray-900 text-right break-words flex-1">
                {(formData.description || formData.inquiryDescription).length > 100 
                  ? `${(formData.description || formData.inquiryDescription).substring(0, 100)}...`
                  : (formData.description || formData.inquiryDescription)}
              </span>
            </div>
          )}
          {formData.budget && (
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-gray-600 font-medium flex-shrink-0">Budget</span>
              <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                {formData.budget} €
              </span>
            </div>
          )}
          <div className="flex justify-between items-start gap-4">
            <span className="text-sm text-gray-600 font-medium flex-shrink-0">Urgence</span>
            <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
              {URGENCY_CONFIG[formData.urgency as keyof typeof URGENCY_CONFIG].label}
            </span>
          </div>
          {(formData.location || formData.allFrance) && (
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-gray-600 font-medium flex-shrink-0">Localisation</span>
              <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                {formData.allFrance 
                  ? "Toute la France" 
                  : formData.location || `${formData.address.city || ""} ${formData.address.zipcode || ""}`.trim() || "Non spécifiée"}
                {!formData.allFrance && formData.ray > 0 && ` (rayon: ${formData.ray} km)`}
              </span>
            </div>
          )}
          {formData.useGeolocation && (
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-gray-600 font-medium flex-shrink-0">Géolocalisation</span>
              <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                Position actuelle utilisée
              </span>
            </div>
          )}
          {formData.deadline && (
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-gray-600 font-medium flex-shrink-0">Date limite</span>
              <span className="text-sm text-gray-900 font-semibold text-right break-words flex-1">
                {new Date(formData.deadline).toLocaleDateString("fr-FR")}
              </span>
            </div>
          )}
        </div>
      </motion.div>

      {/* Détails spécifiques - Job Search */}
      {(formData.inquiryType === "JobSearchInternship" || formData.inquiryType === "SearchInternship" || formData.inquiryType === "SearchJob") && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-green-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-green-800">Détails du poste recherché</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentStep(2)}
              className="text-green-600 hover:text-green-700 hover:bg-green-100"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="space-y-3">
            {formData.activity && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Secteur d'activité</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {jobCategories.find(cat => cat.code === formData.activity)?.label || formData.activity}
                </span>
              </div>
            )}
            {formData.jobFunction && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Fonction</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {jobSubCategories.find(sub => sub.code === formData.jobFunction)?.label || formData.jobFunction}
                </span>
              </div>
            )}
            {formData.contractType.length > 0 && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Type de contrat</span>
                <div className="flex flex-wrap gap-1 justify-end flex-1">
                  {formData.contractType.map((type: string) => (
                    <span
                      key={type}
                      className="px-2 py-1 bg-green-100 text-green-800 rounded-full text-xs font-medium"
                    >
                      {getLabel(type)}
                    </span>
                  ))}
                </div>
              </div>
            )}
            {formData.occupationTime && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Temps de travail</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {getLabel(formData.occupationTime)}
                </span>
              </div>
            )}
            {formData.studyLevel && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Niveau d'étude</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {getLabel(formData.studyLevel)}
                </span>
              </div>
            )}
            {formData.experienceLevel && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Niveau d'expérience</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {getLabel(formData.experienceLevel)}
                </span>
              </div>
            )}
            {formData.salaryType !== "none" && (formData.minSalary || formData.maxSalary) && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Prétention salariale</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {formData.salaryType === "range" && formData.minSalary && formData.maxSalary
                    ? `${formData.minSalary}€ - ${formData.maxSalary}€`
                    : formData.salaryType === "exact" && formData.minSalary
                    ? `${formData.minSalary}€`
                    : "Non spécifié"}
                  {(formData.minSalary || formData.maxSalary) && ` (${formData.netSalary}, ${getLabel(formData.unitSalary)})`}
                </span>
              </div>
            )}
            <div className="flex justify-between items-start gap-4">
              <span className="text-sm text-green-700 font-medium flex-shrink-0">Télétravail</span>
              <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                {formData.telework ? "Accepté" : "Non accepté"}
              </span>
            </div>
            {(formData.startDate || formData.endDate || isEmergent) && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Disponibilités</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  {isEmergent
                    ? "Dans l'immédiat"
                    : `${formData.startDate ? `À partir du ${new Date(formData.startDate).toLocaleDateString("fr-FR")}` : ""}${
                        formData.startDate && formData.endDate ? " " : ""
                      }${formData.endDate ? `jusqu'au ${new Date(formData.endDate).toLocaleDateString("fr-FR")}` : ""}`}
                </span>
              </div>
            )}
            {formData.useCandidateDocuments && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-green-700 font-medium flex-shrink-0">Documents candidat</span>
                <span className="text-sm text-green-900 font-semibold text-right break-words flex-1">
                  Utilisation activée
                </span>
              </div>
            )}
          </div>
        </motion.div>
      )}

      {/* Détails spécifiques - Training */}
      {formData.inquiryType === "Training" && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-blue-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-blue-800">Détails de la formation</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentStep(2)}
              className="text-blue-600 hover:text-blue-700 hover:bg-blue-100"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="space-y-3">
            {formData.inquiryTrainingCategory && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Catégorie</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {trainingCategories.find(cat => cat.code === formData.inquiryTrainingCategory)?.label || formData.inquiryTrainingCategory}
                </span>
              </div>
            )}
            {formData.inquirytrainingsecteur && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Secteur</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {trainingSubCategories.find(sub => sub.code === formData.inquirytrainingsecteur)?.label || formData.inquirytrainingsecteur}
                </span>
              </div>
            )}
            {formData.inquiryTrainingType && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Type de formation</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {getLabel(formData.inquiryTrainingType)}
                </span>
              </div>
            )}
            {formData.inquiryTrainingStyle.length > 0 && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Type d'enseignement</span>
                <div className="flex flex-wrap gap-1 justify-end flex-1">
                  {formData.inquiryTrainingStyle.includes("Indifferent") ? (
                    <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium">
                      Tout
                    </span>
                  ) : (
                    formData.inquiryTrainingStyle.map((style: string) => (
                      <span
                        key={style}
                        className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium"
                      >
                        {getLabel(style)}
                      </span>
                    ))
                  )}
                </div>
              </div>
            )}
            {formData.inquiryTrainingFunding.length > 0 && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Financement</span>
                <div className="flex flex-wrap gap-1 justify-end flex-1">
                  {formData.inquiryTrainingFunding.includes("Indifferent") ? (
                    <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium">
                      Tout
                    </span>
                  ) : (
                    formData.inquiryTrainingFunding.map((funding: string) => (
                      <span
                        key={funding}
                        className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-xs font-medium"
                      >
                        {getLabel(funding)}
                      </span>
                    ))
                  )}
                </div>
              </div>
            )}
            {(formData.startDate || formData.endDate || isEmergent) && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Disponibilités</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {isEmergent
                    ? "Dans l'immédiat"
                    : `${formData.startDate ? `À partir du ${new Date(formData.startDate).toLocaleDateString("fr-FR")}` : ""}${
                        formData.startDate && formData.endDate ? " " : ""
                      }${formData.endDate ? `jusqu'au ${new Date(formData.endDate).toLocaleDateString("fr-FR")}` : ""}`}
                </span>
              </div>
            )}
            {(formData.nbrpeople || formData.nbrgroup || formData.indifferent) && profiletype !== "particulier" && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Nombre à former</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {formData.indifferent
                    ? "À définir"
                    : `${formData.nbrpeople ? `${formData.nbrpeople} personne(s)` : ""}${
                        formData.nbrpeople && formData.nbrgroup ? " - " : ""
                      }${formData.nbrgroup ? `${formData.nbrgroup} groupe(s)` : ""}`
                  }
                </span>
              </div>
            )}
            {formData.inquiryStudyLevel && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Niveau d'étude</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {getLabel(formData.inquiryStudyLevel)}
                </span>
              </div>
            )}
            {formData.inquiryXpLevel && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Niveau d'expérience</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {getLabel(formData.inquiryXpLevel)}
                </span>
              </div>
            )}
            {(formData.nbrpeople || formData.nbrgroup || formData.indifferent) && profiletype !== "particulier" && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-blue-700 font-medium flex-shrink-0">Nombre à former</span>
                <span className="text-sm text-blue-900 font-semibold text-right break-words flex-1">
                  {formData.indifferent
                    ? "À définir"
                    : `${formData.nbrpeople ? `${formData.nbrpeople} personne(s)` : ""}${
                        formData.nbrpeople && formData.nbrgroup ? " - " : ""
                      }${formData.nbrgroup ? `${formData.nbrgroup} groupe(s)` : ""}`}
                </span>
              </div>
            )}
          </div>
        </motion.div>
      )}

      {/* Détails spécifiques - Real Estate */}
      {formData.inquiryType === "RealEstate" && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-orange-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-orange-800">Détails du bien immobilier</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentStep(2)}
              className="text-orange-600 hover:text-orange-700 hover:bg-orange-100"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="space-y-3">
            {formData.inquiryTypeCategory && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Type de demande</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {inquirySubCategories.find(sub => sub.code === formData.inquiryTypeCategory)?.label || formData.inquiryTypeCategory}
                </span>
              </div>
            )}
            {Array.isArray(formData.realEstateType) && formData.realEstateType.length > 0 && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Type de bien</span>
                <div className="flex flex-wrap gap-1 justify-end flex-1">
                  {formData.realEstateType.map((type: string) => (
                    <span
                      key={type}
                      className="px-2 py-1 bg-orange-100 text-orange-800 rounded-full text-xs font-medium"
                    >
                      {getLabel(type)}
                    </span>
                  ))}
                </div>
              </div>
            )}
            {(formData.budgetMin || formData.budgetMax) && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Budget</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {formData.budgetMin && formData.budgetMax
                    ? `${formData.budgetMin}€ - ${formData.budgetMax}€`
                    : formData.budgetMin
                    ? `À partir de ${formData.budgetMin}€`
                    : `Jusqu'à ${formData.budgetMax}€`}
                </span>
              </div>
            )}
            {(formData.livingSpaceMin || formData.livingSpaceMax) && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Surface habitable</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {formData.livingSpaceMin && formData.livingSpaceMax
                    ? `${formData.livingSpaceMin}m² - ${formData.livingSpaceMax}m²`
                    : formData.livingSpaceMin
                    ? `À partir de ${formData.livingSpaceMin}m²`
                    : `Jusqu'à ${formData.livingSpaceMax}m²`}
                </span>
              </div>
            )}
            {(formData.groundSpaceMin || formData.groundSpaceMax) && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Surface terrain</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {formData.groundSpaceMin && formData.groundSpaceMax
                    ? `${formData.groundSpaceMin}m² - ${formData.groundSpaceMax}m²`
                    : formData.groundSpaceMin
                    ? `À partir de ${formData.groundSpaceMin}m²`
                    : `Jusqu'à ${formData.groundSpaceMax}m²`}
                </span>
              </div>
            )}
            {formData.piece && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Nombre de pièces</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {formData.piece === "0" ? "Indifférent" : formData.piece === "5" ? "5 ou +" : formData.piece}
                </span>
              </div>
            )}
            {formData.bedroom && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Nombre de chambres</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {formData.bedroom === "0" ? "Indifférent" : formData.bedroom === "5" ? "5 ou +" : formData.bedroom}
                </span>
              </div>
            )}
            {formData.furniture && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-orange-700 font-medium flex-shrink-0">Meublé</span>
                <span className="text-sm text-orange-900 font-semibold text-right break-words flex-1">
                  {formData.furniture === "0" ? "Meublé" : formData.furniture === "1" ? "Non meublé" : "Indifférent"}
                </span>
              </div>
            )}
          </div>
        </motion.div>
      )}

      {/* Détails spécifiques - Services */}
      {formData.inquiryType === "ServicesAssistance" && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="bg-indigo-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-indigo-800">Détails du service</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentStep(2)}
              className="text-indigo-600 hover:text-indigo-700 hover:bg-indigo-100"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="space-y-3">
            {formData.inquiryTypeCategory && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-indigo-700 font-medium flex-shrink-0">Type de demande</span>
                <span className="text-sm text-indigo-900 font-semibold text-right break-words flex-1">
                  {inquirySubCategories.find(sub => sub.code === formData.inquiryTypeCategory)?.label || formData.inquiryTypeCategory}
                </span>
              </div>
            )}
            {formData.serviceFrequency && (
              <div className="flex justify-between items-start gap-4">
                <span className="text-sm text-indigo-700 font-medium flex-shrink-0">Fréquence</span>
                <span className="text-sm text-indigo-900 font-semibold text-right break-words flex-1">
                  {formData.serviceFrequency}
                </span>
              </div>
            )}
          </div>
        </motion.div>
      )}

      {/* Documents */}
      {formData.documents.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-gray-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-gray-900">Documents ({formData.documents.length})</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentStep(2)}
              className="text-purple-600 hover:text-purple-700 hover:bg-purple-50"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {formData.documents.map((doc, index) => (
              <div key={doc.id} className="flex items-center gap-2 p-2 bg-white rounded-lg">
                <FileText className="w-4 h-4 text-gray-500" />
                <span className="text-sm text-gray-700 truncate">{doc.name}</span>
              </div>
            ))}
          </div>
        </motion.div>
      )}

      {/* Photos */}
      {formData.photos.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-gray-50 rounded-xl p-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h4 className="text-lg font-semibold text-gray-900">Photos ({formData.photos.length})</h4>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCurrentStep(4)}
              className="text-purple-600 hover:text-purple-700 hover:bg-purple-50"
            >
              <Edit2 className="w-4 h-4 mr-2" />
              Modifier
            </Button>
          </div>
          <div className="grid grid-cols-4 gap-2">
            {formData.photos.map((photo, index) => (
              <img
                key={index}
                src={URL.createObjectURL(photo) || "/placeholder.svg"}
                alt={`Photo ${index + 1}`}
                className="w-full h-20 object-cover rounded-lg"
              />
            ))}
          </div>
        </motion.div>
      )}

       <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: 0.6 }}
      className="bg-green-50 border-2 border-green-200 rounded-xl p-6"
    >
      <div className="flex items-start gap-4">
        <Checkbox
          id="acceptMessages"
          checked={formData.acceptMessages}
          onCheckedChange={(checked) => setFormData({ 
            ...formData, 
            acceptMessages: checked as boolean 
          })}
          className="w-5 h-5 text-green-600 border-gray-300 rounded focus:ring-green-500 mt-1"
        />
        <label htmlFor="acceptMessages" className="flex-1 cursor-pointer">
          <span className="font-semibold text-gray-900 block mb-1">
            Accepter de recevoir des messages concernant cette demande
          </span>
          <span className="text-sm text-gray-600">
            Les autres utilisateurs pourront vous contacter pour proposer leurs services ou répondre à votre demande
          </span>
        </label>
      </div>
    </motion.div>


      {/* Confirmation */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="bg-purple-50 border-2 border-purple-200 rounded-xl p-6 text-center"
      >
        <p className="text-purple-800 font-medium mb-4">Votre demande est prête à être publiée !</p>
        <p className="text-sm text-purple-600">
          Une fois publiée, votre demande sera visible par la communauté et vous pourrez recevoir des propositions.
        </p>
      </motion.div>
      
    </div>
  </motion.div>
)}
            
          </AnimatePresence>
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
              disabled={!isStepValid()}
              className="flex items-center gap-2 bg-purple-600 hover:bg-purple-700"
            >
              Suivant
              <ArrowRight className="w-4 h-4" />
            </Button>
          ) : (
            <Button
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="flex items-center gap-2 bg-purple-600 hover:bg-purple-700"
            >
              {isSubmitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                  {isEditMode ? "Modification..." : "Publication..."}
                </>
              ) : (
                <>
                  <Check className="w-4 h-4" />
                  {isEditMode ? "Modifier la demande" : "Publier la demande"}
                </>
              )}
            </Button>
          )}

        </div>
      </div>
    </div>
  )
}
