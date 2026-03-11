"use client"

import { use, useEffect, useState, useCallback } from "react"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import Link from "next/link"
import {
  Heart,
  Share2,
  MapPin,
  Calendar,
  ExternalLink,
  Clock,
  Euro,
  Users,
  FileText,
  Target,
  CheckCircle2,
  Briefcase,
  ChevronRight,
  User,
  Mail,
  Home,
  Building2,
  Download,
  AlertCircle,
  Ticket,
  Globe,
  CalendarDays,
  Eye,
  ChevronLeft,
  MapPinned,
  Maximize,
  Map,
  LayoutGrid,
  Bed,
  Sofa,
  Locate,
} from "lucide-react"
import Image from "next/image"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { fetchDealImages, fetchPublisherData, toggleFavorite, startConversation, checkUserSubscription } from "@/lib/api"
import axios from "axios"
import { CommentsSection } from "@/components/comments/comments-section"
import { ShareModal } from "@/components/share-modal"
import { ProfileLinkGuard } from "@/components/profile-link-guard"
import { PublisherCard } from "@/components/publisher-card"
import { LocationMap } from "@/components/map/location-map"
import FeatureGuard from "@/components/subscription/feature-guard"
import { labelObject } from "@/lib/constants/label-object"
import { config } from "@/lib/config"
import { participateEvent, createApplication } from "@/lib/api"
import { formatDateRelative } from "@/lib/utils"
import { FaFacebook, FaInstagram, FaLinkedin, FaYoutube } from "react-icons/fa"
import { FaXTwitter } from "react-icons/fa6"
import { SiTiktok, SiSnapchat } from "react-icons/si"

interface InquiryDetail {
  id: string
  title: string
  description: string
  category: string
  userId: string
  createdat: string
  endDate?: string
  inquiryTitle?: string
  inquiryDescription?: string
  inquiryType?: string
  inquiryTypeCategory?: string
  inquiryTrainingCategory?: string
  inquiryTrainingType?: string
  inquiryTrainingStyle?: string
  inquiryTrainingFunding?: string
  inquiryContractType?: string
  inquiryEntitled?: string
  inquiryOccupationType?: string
  inquiryStudyLevel?: string
  inquiryXpLevel?: string
  inquiryUnitSalary?: string
  budgetMin?: string
  budgetMax?: string
  livingSpaceMin?: string
  livingSpaceMax?: string
  groundSpaceMin?: string
  groundSpaceMax?: string
  piece?: string
  bedroom?: string
  realEstateType?: string
  furniture?: string
  address?: string
  startDate?: string
  price?: string
  website?: string
  number_view?: number
  ray?: string
  telework?: boolean
  documents?: string
  flexibleDate?: boolean
  isFavorite?: boolean
  userInfo?: {
    pseudo?: string
    nomsociete?: string
    photoprofilurl?: string
    profiletype?: string
  }
  companyData?: {
    nomsociete?: string
    photoprofilurl?: string
    profiletype?: string
    activite?: string
    telephone?: string
    adresse?: string
    ville?: string
    codepostal?: string
    presentation?: string
  }
}

// Fonction pour construire correctement l'URL de l'image
const getImageUrl = (imagePath: string) => {
  if (!imagePath) return ""
  
  // Si c'est déjà une URL complète, la retourner telle quelle
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath
  }
  
  // S'assurer que le chemin commence par / pour un chemin absolu
  let cleanPath = imagePath
  if (!cleanPath.startsWith('/')) {
    cleanPath = '/' + cleanPath
  }
  
  // Remplacer /ads/ par /annonces/ si présent
  if (cleanPath.includes("/ads/")) {
    cleanPath = cleanPath.replace("/ads/", "/annonces/")
  }
  
  // Construire l'URL complète avec l'API_URL
  return `${config.API_URL}${cleanPath}`
}

// Fonction pour construire correctement l'URL d'un document
const getDocumentUrl = (docPath: string) => {
  if (!docPath) return ''
  
  if (docPath.startsWith('http://') || docPath.startsWith('https://')) {
    return docPath
  }
  
  if (docPath.startsWith('/')) {
    return `${config.API_URL}${docPath}`
  }
  
  return `${config.API_URL}/${docPath}`
}

const formatAddress = (addressData: any): string => {
  if (!addressData) return ""

  if (typeof addressData === "string") {
    try {
      const parsed = JSON.parse(addressData)
      addressData = parsed
    } catch {
      return addressData
    }
  }

  try {
    const parts = []
    if (addressData.line1 || addressData.adresse) parts.push(addressData.line1 || addressData.adresse)
    if (addressData.line2) parts.push(addressData.line2)
    if (addressData.line3) parts.push(addressData.line3)
    if (addressData.city || addressData.ville) parts.push(addressData.city || addressData.ville)
    if (addressData.zipcode || addressData.codepostal) parts.push(addressData.zipcode || addressData.codepostal)
    if (addressData.country || addressData.pays && addressData.country !== "France") {
      parts.push(addressData.country || addressData.pays)
    }

    return parts.filter(Boolean).join(", ")
  } catch (error) {
    console.error("Error formatting address:", error)
    return ""
  }
}

const formatEventTypeLabel = (eventType: string) => {
  return (labelObject as any)[eventType] || eventType
}

const formatSubCategoryLabel = (subCategory: string) => {
  return (labelObject as any)[subCategory] || subCategory
}

function sanitizeHtml(html: string): string {
  if (!html) return ""
  
  // Décoder les entités HTML en utilisant un élément DOM temporaire
  if (typeof document !== 'undefined') {
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = html
    const decodedHtml = tempDiv.innerHTML
    
    return decodedHtml
      .replace(/style="[^"]*"/g, '')
      .replace(/class="[^"]*"/g, '')
      .trim()
  }
  
  // Fallback pour le rendu côté serveur
  return html
    .replace(/style="[^"]*"/g, '')
    .replace(/class="[^"]*"/g, '')
    .trim()
}

// Modal simple de prévisualisation de fichier
const SimpleFilePreviewModal = ({ isOpen, onClose, fileUrl, fileName }: {
  isOpen: boolean
  onClose: () => void
  fileUrl: string
  fileName: string
}) => {
  if (!isOpen) return null

  const isImage = fileName.toLowerCase().match(/\.(jpg|jpeg|png|gif|bmp|webp)$/i)
  const isPdf = fileName.toLowerCase().endsWith('.pdf')

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg w-full max-w-4xl max-h-[90vh] overflow-hidden">
        <div className="flex justify-between items-center p-4 border-b">
          <h2 className="text-lg font-semibold">{fileName}</h2>
          <button
            onClick={onClose}
            className="p-2 rounded-full hover:bg-gray-200"
          >
            <AlertCircle className="h-5 w-5" />
          </button>
        </div>
        <div className="flex-1 overflow-auto max-h-[calc(90vh-80px)]">
          {isImage ? (
            <div className="p-4">
              <img 
                src={fileUrl} 
                alt={fileName}
                className="w-full h-auto max-w-full object-contain"
              />
            </div>
          ) : isPdf ? (
            <iframe
              src={fileUrl}
              className="w-full h-96"
              title={fileName}
            />
          ) : (
            <div className="p-8 text-center">
              <FileText className="h-16 w-16 mx-auto text-gray-400 mb-4" />
              <p className="text-gray-600 mb-4">Aperçu non disponible pour ce type de fichier</p>
              <a
                href={fileUrl}
                download={fileName}
                className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              >
                <Download className="h-4 w-4" />
                Télécharger
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

// Fonction pour obtenir les fichiers de documents
const getDocumentFiles = async (announcementId: string) => {
  try {
    console.log("🔵 Fetching documents for ad_id:", announcementId)
    
    const formData = new URLSearchParams()
    formData.append("Method", "get_ad_document_files")
    formData.append("ad_id", announcementId)

    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )

    console.log("📥 Documents API full response:", response)
    console.log("📥 Documents API response.data:", response.data)
    console.log("📥 Type of response.data:", typeof response.data)
    console.log("📥 Is Array?", Array.isArray(response.data))

    // Gérer différents formats de réponse
    let files = []
    
    // Format 1: Tableau direct
    if (Array.isArray(response.data)) {
      files = response.data
    }
    // Format 2: Objet avec propriété document_files
    else if (response.data && response.data.document_files && Array.isArray(response.data.document_files)) {
      files = response.data.document_files
    }
    // Format 3: Objet avec propriété files
    else if (response.data && response.data.files && Array.isArray(response.data.files)) {
      files = response.data.files
    }
    // Format 4: Objet avec propriété data
    else if (response.data && response.data.data && Array.isArray(response.data.data)) {
      files = response.data.data
    }
    // Format 5: Status success avec files
    else if (response.data && response.data.status === "success" && response.data.files) {
      files = Array.isArray(response.data.files) ? response.data.files : [response.data.files]
    }

    console.log("📄 Files extracted:", files)
    console.log("📄 Files count:", files.length)

    if (files.length > 0) {
      const mappedFiles = files.map((file: any) => {
        console.log("📄 Processing file:", file)
        return {
          id: file.id,
          name: file.file_name || file.filename || file.name || "Document",
          url: file.file_path || file.filepath || file.url || file.path || "",
          size: file.file_size || file.size,
          type: file.file_type || file.type,
          uploadedAt: file.uploaded_at || file.createdat,
          ...file
        }
      })
      console.log("✅ Mapped files:", mappedFiles)
      return mappedFiles
    }
    
    console.log("⚠️ No files found")
    return []
  } catch (error) {
    console.error("❌ Error fetching documents:", error)
    if (axios.isAxiosError(error)) {
      console.error("❌ Axios error details:", error.response?.data)
    }
    return []
  }
}

const InquiryDetailsSidebar = ({ inquiry }: { inquiry: InquiryDetail }) => {
  const inquiryType = inquiry.inquiryType || "";
  
  // Fonction pour construire les features selon le type de demande
  const buildFeatures = () => {
    const features = [];

    // Catégorie (affichée uniquement pour les demandes NON emploi/stage ET NON immobilier)
    if (inquiry.inquiryTypeCategory && inquiryType !== "JobSearch" && inquiryType !== "JobSearchInternship" && inquiryType !== "RealEstate") {
      features.push({
        icon: "ticket",
        title: "Catégorie",
        description: (labelObject as any)[inquiry.inquiryTypeCategory] || inquiry.inquiryTypeCategory,
      });
    }

    // ========== DEMANDES IMMOBILIÈRES (RealEstate) ==========
    if (inquiryType === "RealEstate") {
      // Type de bien (EN PREMIER)
      if (inquiry.realEstateType && inquiry.realEstateType !== "{}") {
        const types = inquiry.realEstateType.replace(/[{}]/g, '').split(',').map((t: any) => {
          const translated = (labelObject as any)[t.trim()] || t.trim();
          return `<span class="inline-block px-3 py-1 bg-purple-600 text-white text-xs font-medium rounded-full mr-2 mb-2">${translated}</span>`;
        }).join('');
        features.push({
          icon: "home",
          title: "Type de bien",
          description: types,
        });
      }

      // Surface habitable
      if ((inquiry.livingSpaceMin && parseInt(inquiry.livingSpaceMin) > 0) || 
          (inquiry.livingSpaceMax && parseInt(inquiry.livingSpaceMax) > 0)) {
        const minText = inquiry.livingSpaceMin && parseInt(inquiry.livingSpaceMin) > 0 ? `Min: <strong>${inquiry.livingSpaceMin}m²</strong>` : null;
        const maxText = inquiry.livingSpaceMax && parseInt(inquiry.livingSpaceMax) > 0 ? `Max: <strong>${inquiry.livingSpaceMax}m²</strong>` : null;
        
        features.push({
          icon: "maximize",
          title: "Surface habitable",
          description: [minText, maxText].filter(Boolean).join(' - '),
        });
      }

      // Surface terrain
      if ((inquiry.groundSpaceMin && parseInt(inquiry.groundSpaceMin) > 0) || 
          (inquiry.groundSpaceMax && parseInt(inquiry.groundSpaceMax) > 0)) {
        const minText = inquiry.groundSpaceMin && parseInt(inquiry.groundSpaceMin) > 0 ? `Min: <strong>${inquiry.groundSpaceMin}m²</strong>` : null;
        const maxText = inquiry.groundSpaceMax && parseInt(inquiry.groundSpaceMax) > 0 ? `Max: <strong>${inquiry.groundSpaceMax}m²</strong>` : null;
        
        features.push({
          icon: "map",
          title: "Surface terrain",
          description: [minText, maxText].filter(Boolean).join(' - '),
        });
      }

      // Pièces
      if (inquiry.piece && parseInt(inquiry.piece) > 0 && inquiry.piece && parseInt(inquiry.piece) < 5) {
        features.push({
          icon: "layout-grid",
          title: "Nombre de pièces",
          description: `<strong>${inquiry.piece}</strong> pièce${parseInt(inquiry.piece) > 1 ? 's' : ''}`,
        });
      }

      if (inquiry.piece && parseInt(inquiry.piece) > 4) {
        features.push({
          icon: "layout-grid",
          title: "Nombre de pièces",
          description: `<strong>${inquiry.piece}</strong> pièces ou plus`,
        });
      }
      if (inquiry.piece && parseInt(inquiry.piece) == 0) {
        features.push({
          icon: "layout-grid",
          title: "Nombre de pièces",
          description: `<strong>Indifférent</strong>`,
        });
      }
      // Chambres (toujours afficher)
      if (inquiry.bedroom !== undefined && inquiry.bedroom !== null) {
        const bedroomCount = parseInt(inquiry.bedroom);
        features.push({
          icon: "bed",
          title: "Chambres",
          description: bedroomCount > 0 
            ? `<strong>${inquiry.bedroom}</strong> chambre${bedroomCount > 1 ? 's' : ''}  ${bedroomCount > 4 ? ' ou  plus' : ''}`
            : "Indifférent",
        });
      }

      // Meublé (toujours afficher)
      if (inquiry.furniture !== undefined && inquiry.furniture !== null) {
        features.push({
          icon: "sofa",
          title: "Meublé",
          description: inquiry.furniture === "0" ? "Meublé" : inquiry.furniture === "1" ? "Non meublé" : "Indifférent",
        });
      }

      // Budget (EN DERNIER)
      const hasBudgetRealEstate = (inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0) ||
                                  (inquiry.budgetMax && parseInt(inquiry.budgetMax) > 0);

      if (hasBudgetRealEstate) {
        features.push({
          icon: "euro-sign",
          title: "Budget",
          description: inquiry.budgetMin && inquiry.budgetMax && parseInt(inquiry.budgetMin) > 0 && parseInt(inquiry.budgetMax) > 0
            ? `<strong>${inquiry.budgetMin}€</strong> - <strong>${inquiry.budgetMax}€</strong>`
            : inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0
              ? `À partir de <strong>${inquiry.budgetMin}€</strong>`
              : `Jusqu'à <strong>${inquiry.budgetMax}€</strong>`,
          bold: true,
          color: "text-green-600",
        });
      }
    }

    // ========== DEMANDES D'EMPLOI / STAGE (JobSearch / JobSearchInternship) ==========
    if (inquiryType === "JobSearch" || inquiryType === "JobSearchInternship") {
      // Fonction recherchée
      if (inquiry.inquiryEntitled) {
        const translatedTitle = (labelObject as any)[inquiry.inquiryEntitled] || inquiry.inquiryEntitled;
        features.push({
          icon: "briefcase",
          title: "Fonction recherchée",
          description: translatedTitle,
        });
      }

      // Type de contrat recherché
      if (inquiry.inquiryContractType && inquiry.inquiryContractType !== "{}") {
        const contracts = inquiry.inquiryContractType.replace(/[{}]/g, '').split(',').map((t: any) => {
          const translated = (labelObject as any)[t.trim()] || t.trim();
          return `<span class="inline-block px-3 py-1 bg-blue-600 text-white text-xs font-medium rounded-full mr-2 mb-2">${translated}</span>`;
        }).join('');
        features.push({
          icon: "briefcase",
          title: "Type de contrat recherché",
          description: contracts,
        });
      }

      // Temps de travail souhaité
      if (inquiry.inquiryOccupationType) {
        const occupationType = (labelObject as any)[inquiry.inquiryOccupationType] || inquiry.inquiryOccupationType;
        features.push({
          icon: "clock",
          title: "Temps de travail souhaité",
          description: occupationType,
        });
      }

      // Niveau d'études
      if (inquiry.inquiryStudyLevel) {
        const studyLevel = (labelObject as any)[inquiry.inquiryStudyLevel] || inquiry.inquiryStudyLevel;
        features.push({
          icon: "graduation-cap",
          title: "Niveau d'études",
          description: studyLevel,
        });
      }

      // Niveau d'expérience
      if (inquiry.inquiryXpLevel) {
        const xpLevel = (labelObject as any)[inquiry.inquiryXpLevel] || inquiry.inquiryXpLevel;
        features.push({
          icon: "briefcase",
          title: "Expérience",
          description: xpLevel,
        });
      }

      // Télétravail
      if (inquiry.telework) {
        features.push({
          icon: "globe",
          title: "Télétravail",
          description: "Souhaité",
        });
      }

      // Salaire avec unité
      const hasSalary = (inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0) || 
                        (inquiry.budgetMax && parseInt(inquiry.budgetMax) > 0);
      
      if (hasSalary) {
        const unitTranslated = inquiry.inquiryUnitSalary 
          ? (labelObject as any)[inquiry.inquiryUnitSalary] || inquiry.inquiryUnitSalary 
          : "";
        const unitText = unitTranslated ? ` / ${unitTranslated}` : "";
        
        features.push({
          icon: "euro-sign",
          title: "Salaire souhaité",
          description: inquiry.budgetMin && inquiry.budgetMax 
            ? `${inquiry.budgetMin}€ - ${inquiry.budgetMax}€${unitText}`
            : inquiry.budgetMin
              ? `À partir de ${inquiry.budgetMin}€${unitText}`
              : `Jusqu'à ${inquiry.budgetMax}€${unitText}`,
          bold: true,
          color: "text-green-600",
        });
      }
    }

    // ========== DEMANDES DE FORMATION (TrainingSearch ou Training) ==========
    if (inquiryType === "TrainingSearch" || inquiryType === "Training") {
      // Secteur de formation
      if ((inquiry as any).inquirytrainingsecteur) {
        features.push({
          icon: "briefcase",
          title: "Secteur",
          description: (labelObject as any)[(inquiry as any).inquirytrainingsecteur] || (inquiry as any).inquirytrainingsecteur,
        });
      }

      // Format de formation (avec tags)
      if (inquiry.inquiryTrainingStyle) {
        try {
          const styles = typeof inquiry.inquiryTrainingStyle === 'string' && inquiry.inquiryTrainingStyle.startsWith('[')
            ? JSON.parse(inquiry.inquiryTrainingStyle)
            : [inquiry.inquiryTrainingStyle];
          
          // Filtrer "Indifferent"
          const filteredStyles = styles.filter((s: string) => s !== "Indifferent");
          
          if (filteredStyles.length > 0) {
            const styleTags = filteredStyles.map((s: string) => {
              const translated = (labelObject as any)[s] || s;
              return `<span class="inline-block px-3 py-1 bg-green-600 text-white text-xs font-medium rounded-full mr-2 mb-2">${translated}</span>`;
            }).join('');
            
            features.push({
              icon: "globe",
              title: "Format souhaité",
              description: styleTags,
            });
          }
        } catch {
          const style = inquiry.inquiryTrainingStyle;
          if (style !== "Indifferent") {
            features.push({
              icon: "globe",
              title: "Format souhaité",
              description: (labelObject as any)[style] || style,
            });
          }
        }
      }

      // Financement (avec tags)
      if (inquiry.inquiryTrainingFunding) {
        try {
          const fundings = typeof inquiry.inquiryTrainingFunding === 'string' && inquiry.inquiryTrainingFunding.startsWith('[')
            ? JSON.parse(inquiry.inquiryTrainingFunding)
            : [inquiry.inquiryTrainingFunding];
          
          // Filtrer "Indifferent"
          const filteredFundings = fundings.filter((f: string) => f !== "Indifferent");
          
          if (filteredFundings.length > 0) {
            const fundingTags = filteredFundings.map((f: string) => {
              const translated = (labelObject as any)[f] || f;
              return `<span class="inline-block px-3 py-1 bg-orange-600 text-white text-xs font-medium rounded-full mr-2 mb-2">${translated}</span>`;
            }).join('');
            
            features.push({
              icon: "euro-sign",
              title: "Financement possible",
              description: fundingTags,
            });
          }
        } catch {
          const funding = inquiry.inquiryTrainingFunding;
          if (funding !== "Indifferent") {
            features.push({
              icon: "euro-sign",
              title: "Financement possible",
              description: (labelObject as any)[funding] || funding,
            });
          }
        }
      }

      // Participants
      const nbrpeople = (inquiry as any).nbrpeople ? parseInt((inquiry as any).nbrpeople) : 0;
      const nbrgroup = (inquiry as any).nbrgroup ? parseInt((inquiry as any).nbrgroup) : 0;
      
      if (nbrpeople > 0 || nbrgroup > 0) {
        const people = nbrpeople > 0 
          ? `<strong>${nbrpeople}</strong> personne${nbrpeople > 1 ? 's' : ''}` 
          : null;
        const groups = nbrgroup > 0 
          ? `<strong>${nbrgroup}</strong> groupe${nbrgroup > 1 ? 's' : ''}` 
          : null;
        
        const description = [people, groups].filter(Boolean).join(' en ');
        
        features.push({
          icon: "users",
          title: "Participants",
          description: description,
        });
      } else if ((inquiry as any).nbrpeople !== undefined || (inquiry as any).nbrgroup !== undefined) {
        // Si les champs existent mais sont à 0
        features.push({
          icon: "users",
          title: "Participants",
          description: "À définir",
          color: "text-gray-600",
        });
      }

      // Budget
      const hasBudgetTraining = (inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0) ||
                                (inquiry.budgetMax && parseInt(inquiry.budgetMax) > 0);

      if (hasBudgetTraining) {
        features.push({
          icon: "euro-sign",
          title: "Budget",
          description: inquiry.budgetMin && inquiry.budgetMax && parseInt(inquiry.budgetMin) > 0 && parseInt(inquiry.budgetMax) > 0
            ? `<strong>${inquiry.budgetMin}€</strong> - <strong>${inquiry.budgetMax}€</strong>`
            : inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0
              ? `À partir de <strong>${inquiry.budgetMin}€</strong>`
              : `Jusqu'à <strong>${inquiry.budgetMax}€</strong>`,
          bold: true,
          color: "text-green-600",
        });
      }
    }

    // ========== DEMANDES DE SERVICES (ServicesAssistance / ServiceHelp) ==========
    if (inquiryType === "ServicesAssistance" || inquiryType === "ServiceHelp") {
      // Catégorie de service (si disponible et différente de ServiceProvision)
      if (inquiry.inquiryTypeCategory && inquiry.inquiryTypeCategory !== "ServiceProvision") {
        features.push({
          icon: "briefcase",
          title: "Type de service",
          description: (labelObject as any)[inquiry.inquiryTypeCategory] || inquiry.inquiryTypeCategory,
        });
      }

      // Budget
      const hasBudget = (inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0) ||
                        (inquiry.budgetMax && parseInt(inquiry.budgetMax) > 0);

      if (hasBudget) {
        features.push({
          icon: "euro-sign",
          title: "Budget",
          description: inquiry.budgetMin && inquiry.budgetMax && parseInt(inquiry.budgetMin) > 0 && parseInt(inquiry.budgetMax) > 0
            ? `<strong>${inquiry.budgetMin}€</strong> - <strong>${inquiry.budgetMax}€</strong>`
            : inquiry.budgetMin && parseInt(inquiry.budgetMin) > 0
              ? `À partir de <strong>${inquiry.budgetMin}€</strong>`
              : `Jusqu'à <strong>${inquiry.budgetMax}€</strong>`,
          bold: true,
          color: "text-green-600",
        });
      }
    }

    // ========== INFORMATIONS COMMUNES À TOUS LES TYPES ==========

    // Disponibilité
    if (inquiry.startDate || inquiry.endDate) {
      let dateDescription = "";
      const formatDate = (dateStr: string) => {
        try {
          return new Date(dateStr).toLocaleDateString("fr-FR", {
            day: "numeric",
            month: "long",
            year: "numeric"
          });
        } catch {
          return dateStr;
        }
      };

      if (inquiry.startDate && inquiry.endDate) {
        // Si les deux dates sont identiques
        if (inquiry.startDate === inquiry.endDate) {
          dateDescription = `Le ${formatDate(inquiry.startDate)}`;
        } else {
          // Entre deux dates
          dateDescription = `Du ${formatDate(inquiry.startDate)} au ${formatDate(inquiry.endDate)}`;
        }
      } else if (inquiry.startDate) {
        // Seulement date de début
        dateDescription = `À partir du ${formatDate(inquiry.startDate)}`;
      } else if (inquiry.endDate) {
        // Seulement date de fin
        dateDescription = `Jusqu'au ${formatDate(inquiry.endDate)}`;
      }

      if (dateDescription) {
        features.push({
          icon: "calendar",
          title: "Disponibilité",
          description: dateDescription,
        });
      }
    }

    // Nombre de vues
    if (inquiry.number_view && inquiry.number_view > 0) {
      features.push({
        icon: "eye",
        title: "Vues",
        description: `${inquiry.number_view} vue${inquiry.number_view > 1 ? 's' : ''}`,
      });
    }

    return features.filter(Boolean);
  };

  const inquiryFeatures = buildFeatures();

  return (
    <div className="border border-gray-200 p-6 rounded-none">
      <h2 className="text-2xl font-bold mb-6">Détails de la demande</h2>
      {inquiryFeatures.length > 0 ? (
        <InquiryFeatureList features={inquiryFeatures} />
      ) : (
        <p className="text-gray-500 text-sm">Aucun détail disponible</p>
      )}
    </div>
  );
};

// Composant pour afficher la liste des caractéristiques
const InquiryFeatureList = ({ features }: { features: any[] }) => {
  const getIconComponent = (iconName: string) => {
    const iconMap: Record<string, any> = {
      calendar: Calendar,
      ticket: Ticket,
      globe: Globe,
      building: Building2,
      clock: Clock,
      "euro-sign": Euro,
      "calendar-days": CalendarDays,
      users: Users,
      "map-pin": MapPin,
      eye: Eye,
      briefcase: Briefcase,
      "graduation-cap": Users,
      book: FileText,
      home: Home,
      maximize: Maximize,
      map: Map,
      "layout-grid": LayoutGrid,
      bed: Bed,
      sofa: Sofa,
    }
    return iconMap[iconName] || Calendar
  }

  return (
    <div className="space-y-4">
      {features.map((feature: any, index: number) => {
        const IconComponent = getIconComponent(feature.icon)
        
        return (
          <div key={index} className="flex items-start gap-3">
            <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
              <IconComponent className="w-5 h-5 text-green-600" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 mb-1">{feature.title}</p>
              {feature.badge ? (
                <Badge className="bg-blue-100 text-blue-700 border-blue-200">
                  {feature.description}
                </Badge>
              ) : (
                <div className={`text-sm ${feature.color || "text-gray-700"} ${feature.bold ? "font-bold text-lg" : ""}`}
                     dangerouslySetInnerHTML={{ __html: feature.description }} />
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// Composant pour les informations supplémentaires sur la demande
const InquiryAdditionalInfo = ({ inquiry }: { inquiry: InquiryDetail }) => {
  // Pour les demandes, on peut afficher des informations complémentaires si nécessaire
  // Pour l'instant, ce composant retourne null car les demandes n'ont pas ces champs
  return null;
};

// Composant pour la carte d'action (répondre à la demande)
const EventActionCard = ({
  website,
  onParticipate,
  isParticipating,
  isExpired,
  eventPrice = 0,
}: {
  website?: string
  onParticipate: () => void
  isParticipating: boolean
  isExpired: boolean
  eventPrice?: number
}) => {
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null

  return (
    <div className="border border-gray-200 p-6 rounded-none">
      <div className="flex items-center justify-between mb-6">
        <div className="text-lg font-medium">Répondre à cette demande</div>
      </div>

      <div className="space-y-3">
        {website && (
          <a
            href={website}
            target="_blank"
            rel="noopener noreferrer"
            className="block w-full py-3 px-4 text-center bg-blue-500 hover:bg-blue-600 text-white rounded transition-colors flex items-center justify-center gap-2"
          >
            <Globe className="w-5 h-5" />
            <span>Site web</span>
          </a>
        )}
        
        <button
          onClick={onParticipate}
          disabled={isExpired || isParticipating || !userId}
          className="w-full py-3 px-4 text-center bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white rounded transition-colors flex items-center justify-center gap-2"
        >
          <Mail className="w-5 h-5" />
          <span>
            {!userId
              ? "Connectez-vous pour répondre"
              : isExpired 
                ? "Demande expirée" 
                : isParticipating 
                  ? "Envoi en cours..."
                  : "Répondre à la demande"
            }
          </span>
        </button>
      </div>
    </div>
  )
};

// Composant pour la carte organisateur
const EventOrganizerCard = ({
  userData,
  showMessageButton,
  userId,
  announcementId,
  onContact,
  isContactingLoading,
  displayName,
  isOrganizationPro,
  getOrganizerPhoto,
}: {
  userData: any
  showMessageButton: boolean
  userId: string
  announcementId: string
  onContact: () => void
  isContactingLoading: boolean
  displayName: string
  isOrganizationPro: boolean
  getOrganizerPhoto: () => string | null
}) => (
  <div className="border border-gray-200 p-6 rounded-none">
    <h2 className="text-2xl font-bold mb-6">À propos de l'organisateur</h2>
    
    <ProfileLinkGuard userId={userId} className="flex items-center gap-4 mb-4">
      <div className="relative w-16 h-16 rounded-full bg-gray-200 overflow-hidden">
        {getOrganizerPhoto() ? (
          <Image
            src={getOrganizerPhoto()!}
            alt={`Photo de ${displayName}`}
            width={64}
            height={64}
            className="object-cover w-full h-full"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center text-gray-500">
            {isOrganizationPro ? (
              <Briefcase className="h-8 w-8" />
            ) : (
              <User className="h-8 w-8" />
            )}
          </div>
        )}
      </div>
      <div>
        <div className="flex items-center gap-2">
          <p className="font-medium">{displayName}</p>
        </div>
        <p className="text-xs py-1 px-2 bg-green-500 rounded-sm text-white font-medium uppercase">
          {isOrganizationPro ? "Professionnel" : "Particulier"}
        </p>
      </div>
    </ProfileLinkGuard>

    {userData?.activite && (
      <p className="text-sm text-gray-600 mb-4">{userData.activite}</p>
    )}

    {userData?.presentation && (
      <div className="mb-4">
        <p className="text-xs font-semibold text-gray-900 mb-1">Présentation :</p>
        <p className="text-xs text-gray-700 leading-relaxed">{userData.presentation}</p>
      </div>
    )}

    {showMessageButton && (
      <FeatureGuard feature="messaging">
        <button
          onClick={onContact}
          disabled={isContactingLoading}
          className="w-full py-2 px-4 border border-gray-300 rounded flex items-center justify-center gap-2 hover:bg-gray-50 transition-colors"
        >
          <Mail className="w-5 h-5" />
          <span>
            {isContactingLoading ? "Connexion en cours..." : "Contacter"}
          </span>
        </button>
      </FeatureGuard>
    )}
  </div>
);

// Composant ImageCarousel avec gestion d'erreurs robuste
function ImageCarousel({ images }: { images: string[] }) {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [imageErrors, setImageErrors] = useState<Set<number>>(new Set())

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100">
        <Calendar className="w-24 h-24 text-orange-300" />
      </div>
    )
  }

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % images.length)
  }

  const prevImage = () => {
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length)
  }

  const handleImageError = (index: number) => {
    setImageErrors(prev => new Set(prev).add(index))
  }

  const currentImageHasError = imageErrors.has(currentIndex)

  return (
    <div className="relative h-[400px] md:h-[500px] w-full overflow-hidden group border border-gray-100/30 rounded-none">
      {currentImageHasError ? (
        <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100">
          <div className="text-center">
            <Calendar className="w-24 h-24 text-orange-300 mx-auto mb-4" />
            <p className="text-gray-500">Image non disponible</p>
          </div>
        </div>
      ) : (
        <Image
          src={getImageUrl(images[currentIndex])}
          alt="Event image"
          fill
          className="object-cover"
          onError={() => handleImageError(currentIndex)}
          unoptimized
          priority={currentIndex === 0}
        />
      )}
      
      {images.length > 1 && (
        <>
          <button
            onClick={prevImage}
            className="absolute left-4 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/80 text-white p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-200 backdrop-blur-sm"
            aria-label="Image précédente"
          >
            <ChevronLeft className="w-6 h-6" />
          </button>
          <button
            onClick={nextImage}
            className="absolute right-4 top-1/2 -translate-y-1/2 bg-black/60 hover:bg-black/80 text-white p-3 rounded-full opacity-0 group-hover:opacity-100 transition-all duration-200 backdrop-blur-sm"
            aria-label="Image suivante"
          >
            <ChevronRight className="w-6 h-6" />
          </button>
          <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-2 bg-black/40 backdrop-blur-sm px-3 py-2 rounded-full">
            {images.map((_, idx) => (
              <button
                key={idx}
                onClick={() => setCurrentIndex(idx)}
                className={`w-2 h-2 rounded-full transition-all ${
                  idx === currentIndex ? "bg-white w-6" : "bg-white/60 hover:bg-white/80"
                } ${imageErrors.has(idx) ? "bg-red-500" : ""}`}
                aria-label={`Aller à l'image ${idx + 1}`}
              />
            ))}
          </div>
        </>
      )}
      
      {/* Date de l'annonce */}
      <div className="absolute top-4 left-4 bg-black/60 backdrop-blur-sm px-3 py-1 rounded text-white text-sm">
        {formatDateRelative(new Date().toISOString())}
      </div>
    </div>
  )
}

export default function InquiryDetailPage({ params }: { params: Promise<{ announcementId: string }> }) {
  const resolvedParams = use(params)
  const announcementId = resolvedParams.announcementId

  const router = useRouter()

  const [event, setEvent] = useState<InquiryDetail | null>(null)
  const [images, setImages] = useState<string[]>([])
  const [publisher, setPublisher] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [isFavorite, setIsFavorite] = useState(false)
  const [userId, setUserId] = useState<string | null>(null)
  const [isContactingLoading, setIsContactingLoading] = useState(false)
  const [showShareModal, setShowShareModal] = useState(false)
  const [relatedEvents, setRelatedEvents] = useState<any[]>([])
  const [isParticipating, setIsParticipating] = useState(false)
  const [documents, setDocuments] = useState<any[]>([])
  const [isDocsModalOpen, setIsDocsModalOpen] = useState(false)
  const [previewFile, setPreviewFile] = useState<{ url: string; name: string } | null>(null)

  useEffect(() => {
    const storedUserId = localStorage.getItem("profileId")
    setUserId(storedUserId)
    loadEventData()
  }, [announcementId])

  // Charger les événements similaires
  useEffect(() => {
    if (event) {
      const loadRelatedEvents = async () => {
        try {
          const response = await axios.post(
            `${config.API_URL}/Ads.php`,
            {
              Method: "readAdsByCriteria",
              category: "demandes",
            },
            {
              headers: {
                "Content-Type": "application/x-www-form-urlencoded",
              },
            }
          )
          
          if (response.data.status === "success" && response.data.ads) {
            const filtered = response.data.ads
              .filter((d: any) => d.id !== announcementId)
              .slice(-4)
              .reverse()
            
            // Charger les données utilisateur pour chaque demande
            const inquiriesWithUserData = await Promise.all(
              filtered.map(async (inquiryItem: any) => {
                try {
                  if (inquiryItem.userId) {
                    const userResult = await fetchPublisherData(inquiryItem.userId)
                    if (userResult.success) {
                      return { ...inquiryItem, companyData: userResult.userData.companyData }
                    }
                  }
                  return inquiryItem
                } catch (error) {
                  console.error(`Erreur chargement données utilisateur pour ${inquiryItem.id}:`, error)
                  return inquiryItem
                }
              })
            )
            
            setRelatedEvents(inquiriesWithUserData)
          }
        } catch (error) {
          console.error("Error loading related events:", error)
        }
      }
      loadRelatedEvents()
    }
  }, [event, announcementId])

  const handleParticipate = async () => {
    console.log("🔵 handleParticipate called")
    console.log("🔵 userId:", userId)
    console.log("🔵 announcementId:", announcementId)
    
    if (!userId) {
      console.log("❌ No userId, showing error")
      toastError("Vous devez être connecté pour répondre à cette demande")
      return
    }

    setIsParticipating(true)

    try {
      console.log("📤 Calling startConversation (Message.php)...")
      const conversationId = await startConversation(announcementId)

      if (!conversationId) {
        toastError("Erreur lors du démarrage de la conversation")
        return
      }

      toastSuccess("Conversation démarrée")
      router.push(`/messages?action=conversation&conversationId=${conversationId}`)
    } catch (error) {
      console.error("❌ Error responding to inquiry:", error)
      toastError("Une erreur est survenue lors de la réponse")
    } finally {
      setIsParticipating(false)
      console.log("🏁 Participation process finished")
    }
  }

  const loadEventData = async () => {
    setLoading(true)
    try {
      await updateViewCount(announcementId)

      const eventResult = await fetchAnnouncementDetail(announcementId)

      if (!eventResult) {
        toastError("Demande introuvable")
        router.push("/demandes")
        return
      }

      setEvent(eventResult)
      setIsFavorite(eventResult.isFavorite || false)

      const imagesResult = await fetchDealImages(announcementId)
      if (imagesResult.success && imagesResult.images) {
        setImages(imagesResult.images)
      }

      const publisherResult = await fetchPublisherData(eventResult.userId)
      if (publisherResult.success) {
        setPublisher(publisherResult.userData)
      }

      // Charger les documents avec la fonction simplifiée (en arrière-plan)
      try {
        const documentsResult = await getDocumentFiles(announcementId)
        setDocuments(documentsResult)
      } catch (docError) {
        // Ne pas bloquer le chargement de la page si les documents ne sont pas disponibles
        console.warn("Documents not available for this announcement")
        setDocuments([])
      }

    } catch (error) {
      console.error("Error loading inquiry:", error)
      toastError("Erreur lors du chargement de la demande")
    } finally {
      setLoading(false)
    }
  }

  async function updateViewCount(announcementId: string) {
    try {
      console.log("[v0] Updating view count for inquiry announcement:", announcementId)
      const response = await axios.post(
        `${config.API_URL}/Ads.php`,
        {
          id: announcementId,
          Method: "updateNumberViewAds",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )
      console.log("[v0] View count update response:", response.data)
    } catch (error) {
      console.error("[v0] Error updating view count:", error)
    }
  }

  const handleToggleFavorite = async () => {
    if (!userId) {
      toastError("Vous devez être connecté")
      return
    }

    try {
      const result = await toggleFavorite(userId, announcementId, !isFavorite)
      if (result.success) {
        setIsFavorite(!isFavorite)
        toastSuccess(result.message || (isFavorite ? "Retiré des favoris" : "Ajouté aux favoris"))
      }
    } catch (error) {
      toastError("Erreur lors de la mise à jour")
    }
  }

  const handleShare = async () => {
    setShowShareModal(true)
  }

  const handleContact = async () => {
    if (!userId) {
      router.push("/login-required")
      return
    }

    setIsContactingLoading(true)
    try {
      const conversationId = await startConversation(announcementId)

      if (!conversationId) {
        toastError("Erreur lors du démarrage de la conversation")
        return
      }

      router.push(`/messages?conversation=${conversationId}`)
      toastSuccess("Conversation démarrée")
    } catch (error) {
      toastError("Erreur lors du démarrage de la conversation")
    } finally {
      setIsContactingLoading(false)
    }
  }

  const isExpired = event?.endDate ? new Date(event.endDate) < new Date() : false
  const eventPrice = event?.price ? Number.parseFloat(event.price) : 0

  const getOrganizerName = () => {
    if (publisher?.companyData?.profiletype === "professionnel") {
      return publisher?.companyData?.nomsociete || "Entreprise"
    }
    
    return publisher?.companyData?.pseudo || "Demandeur"
  }

  const getPublisherName = () => {
    if (publisher?.companyData?.profiletype === "professionnel") {
      return publisher?.companyData?.nomsociete || "Entreprise"
    }
    return publisher?.companyData?.pseudo || "Utilisateur"
  }

  const isOrganizationPro = () => {
    return publisher?.companyData?.profiletype === "professionnel"
  }

  const getOrganizerPhoto = () => {
    const photoUrl = publisher?.companyData?.photoprofilurl || publisher?.photoprofilurl
    if (!photoUrl) return null
    
    if (photoUrl.startsWith("http")) {
      return photoUrl
    }
    
    return `${config.API_URL}${photoUrl}`
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40">
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Chargement de la demande...</p>
          </div>
        </div>
      </div>
    )
  }

  if (!event) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40">
        <div className="flex items-center justify-center h-96">
          <div className="text-center">
            <AlertCircle className="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h2 className="text-2xl font-bold mb-2">Demande introuvable</h2>
            <p className="text-gray-600 mb-4">Cette demande n'existe pas ou a été supprimée</p>
            <Button onClick={() => router.push("/demandes")}>Retour aux demandes</Button>
          </div>
        </div>
      </div>
    )
  }

  const address = event.address ? (typeof event.address === 'string' ? JSON.parse(event.address) : event.address) : {}
  const showMessageButton = typeof window !== "undefined" && 
    localStorage.getItem("profileId") !== event?.userId && 
    (event?.acceptMessages === true || event?.message === true) &&
    !isExpired

  const sponsorshipLink = typeof window !== "undefined"
    ? `${window.location.origin}/announcements/inquiries/${event?.id}`
    : ""

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40 overflow-x-hidden">
      {/* Breadcrumb */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center gap-2 text-sm text-gray-600">
            <Link href="/" className="hover:text-purple-600 transition-colors">
              Accueil
            </Link>
            <ChevronRight className="w-4 h-4" />
            <Link href="/demandes" className="hover:text-purple-600 transition-colors">
              Demandes
            </Link>
            <ChevronRight className="w-4 h-4" />
            <span className="text-gray-900 font-medium truncate">{event.inquiryTitle || event.title}</span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Image en pleine largeur AVANT le layout */}
        {images.length > 0 && (
          <div className="mb-8">
            <div className="relative h-[300px] md:h-[400px] rounded-2xl overflow-hidden shadow-xl">
              <ImageCarousel images={images} />
              {isExpired && (
                <div className="absolute top-4 right-4 z-10">
                  <Badge className="bg-red-600 text-white border-2 border-white shadow-lg text-sm px-4 py-2">
                    EXPIRÉ
                  </Badge>
                </div>
              )}
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6 lg:gap-8">
          {/* Contenu principal - 2/3 colonnes */}
          <div className="lg:col-span-2 space-y-6 sm:space-y-8 lg:space-y-10">
            {/* Card avec titre, badges et actions */}
            <Card className={`p-6 sm:p-8 lg:p-10 ${isExpired ? "border-2 border-red-500" : ""}`}>
              <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4 sm:mb-6 lg:mb-8">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-3 flex-wrap">
                    {event.inquiryType && (
                      <Badge variant="secondary" className="bg-purple-100 text-purple-700">
                        {(labelObject as any)[event.inquiryType] || event.inquiryType}
                      </Badge>
                    )}
                    {(event.inquiryType === "Training" || event.inquiryType === "TrainingSearch") && event.inquiryTrainingCategory && (
                      <Badge variant="outline" className="bg-white text-gray-700 border-gray-300">
                        {(labelObject as any)[event.inquiryTrainingCategory] || event.inquiryTrainingCategory}
                      </Badge>
                    )}
                    {(event.inquiryType === "Training" || event.inquiryType === "TrainingSearch") && event.inquiryTrainingType && (
                      <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
                        {(labelObject as any)[event.inquiryTrainingType] || event.inquiryTrainingType}
                      </Badge>
                    )}
                    {event.inquiryTypeCategory && event.inquiryType !== "Training" && event.inquiryType !== "TrainingSearch" && (
                      <Badge variant="outline" className="bg-blue-50 text-blue-700">
                        {(labelObject as any)[event.inquiryTypeCategory] || event.inquiryTypeCategory}
                      </Badge>
                    )}
                    {isExpired && images.length === 0 && (
                      <Badge className="bg-red-600 text-white border-2 border-white shadow-lg">
                        EXPIRÉ
                      </Badge>
                    )}
                  </div>
                  <h1 className={`text-3xl font-bold mb-3 ${isExpired ? "text-gray-500" : "text-gray-900"}`}>
                    {event.inquiryTitle || event.title}
                  </h1>
                  <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4" />
                      <span>Publié {formatDateRelative(event.createdat)}</span>
                    </div>
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={handleToggleFavorite}
                    className="hover:bg-red-50"
                  >
                    <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : ""}`} />
                  </Button>
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={handleShare}
                    className="hover:bg-blue-50 bg-transparent"
                  >
                    <Share2 className="w-5 h-5" />
                  </Button>
                </div>
              </div>
            </Card>

            {/* Description */}
            <Card className="p-6">
              <h2 className="text-2xl font-bold mb-4">Description</h2>
              <div 
                className="prose prose-slate max-w-none text-gray-700 leading-relaxed"
                dangerouslySetInnerHTML={{ __html: sanitizeHtml(event.inquiryDescription || event.description) }}
              />
            </Card>

            {/* Localisation - visible uniquement si publishadresse est autorisé */}
            {event.address && publisher && publisher.companyData && (publisher.companyData.publishadresse === "true" || publisher.companyData.publishadresse === true || publisher.companyData.publishadresse === "1") && (
              <Card className="p-6">
                <h2 className="text-2xl font-bold mb-4">Localisation</h2>
                <div className="space-y-4">
                  {/* Afficher l'adresse seulement si ce n'est pas "Toute la France" */}
                  {event.ray !== "0" && (
                    <div>
                      <p className="text-sm font-semibold text-gray-900 mb-1">Adresse :</p>
                      <p className="text-sm text-gray-700">{formatAddress(event.address)}</p>
                    </div>
                  )}
                  {event.ray && (
                    <div>
                      <p className="text-sm font-semibold text-gray-900 mb-1">Rayon :</p>
                      <p className="text-sm text-gray-700">{event.ray === "0" ? "Toute la France" : `${event.ray} km`}</p>
                    </div>
                  )}
                  <LocationMap 
                    address={event.address} 
                    title={event.inquiryTitle || event.title}
                    ray={event.ray}
                    className="rounded-lg h-[300px]"
                  />
                </div>
              </Card>
            )}

            {/* Commentaires */}
            <CommentsSection announcementId={announcementId} />
          </div>

          {/* Sidebar - 1/3 colonne */}
          <div className="lg:col-span-1 space-y-6">
          {/* Carousel d'images - visible sur mobile */}
          {images.length > 0 && (
            <div className="block md:hidden">
              <ImageCarousel images={images} />
              <div className="text-gray-500 text-sm text-left mt-2">
                {formatDateRelative(event.createdat)}
              </div>
            </div>
          )}

          {/* Détails de la demande */}
          <InquiryDetailsSidebar inquiry={event} />

          {/* Actions de participation */}
          <EventActionCard
            website={event.website}
            onParticipate={handleParticipate}
            isParticipating={isParticipating}
            isExpired={isExpired}
            eventPrice={eventPrice}
          />

          {/* Documents de l'événement */}
          {documents.length > 0 && (
            <div className="border border-gray-200 p-6 rounded-none">
              <div className="flex items-center justify-between mb-6">
                <div className="text-lg font-medium">Documents de la demande</div>
              </div>
              <div className="space-y-2">
                <button
                  onClick={() => {
                    if (!userId) {
                      router.push("/login-required")
                      return
                    }
                    setIsDocsModalOpen(true)
                  }}
                  className="block w-full py-3 px-4 text-center bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
                >
                  <FileText className="w-5 h-5" />
                  {userId ? `Voir les documents (${documents.length})` : "Connectez-vous pour voir les documents"}
                </button>
              </div>
            </div>
          )}

          {/* Organisateur */}
          {publisher && publisher.companyData && (
            <PublisherCard
              publisherName={getPublisherName()}
              announcementTitle={event.inquiryTitle || event.title}
              announcementType="demande"
              userId={event.userId}
              photoUrl={getOrganizerPhoto()}
              isProfessional={isOrganizationPro()}
              activite={publisher.companyData.activite}
              ville={publisher.companyData.ville}
              pays={publisher.companyData.pays}
              telephone={""}
              adresse={publisher.companyData.adresse}
              codePostal={publisher.companyData.codepostal}
              facebook={publisher.companyData.facebook}
              instagram={publisher.companyData.instagram}
              linkedin={publisher.companyData.linkedin}
              twitter={publisher.companyData.twitter}
              youtube={publisher.companyData.youtube}
              tiktok={publisher.companyData.tiktok}
              publishadresse={publisher.companyData.publishadresse}
            />
          )}
        </div>
      </div>
    </div>

    {/* Section Événements similaires */}
    {relatedEvents.length > 0 && (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mt-16 py-12 bg-gradient-to-b from-gray-50 to-white rounded-lg">
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Autres demandes</h2>
            <p className="text-gray-600">Découvrez d'autres demandes qui pourraient vous intéresser</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6">
            {relatedEvents.map((relatedInquiry) => {
              // Fonctions helper
              const formatAddress = (addr: any): string => {
                if (!addr) return ""
                if (typeof addr === "string") {
                  if (addr.trim().startsWith("{") || addr.trim().startsWith("[")) {
                    try {
                      const parsed = JSON.parse(addr)
                      return formatAddress(parsed)
                    } catch { return addr }
                  }
                  return addr
                }
                if (typeof addr === "object") {
                  const parts = []
                  if (addr.zipcode || addr.postalCode || addr.codepostal) parts.push(addr.zipcode || addr.postalCode || addr.codepostal)
                  if (addr.city || addr.ville) parts.push(addr.city || addr.ville)
                  if (addr.country || addr.pays) parts.push(addr.country || addr.pays)
                  return parts.filter(Boolean).join(", ")
                }
                return ""
              }

              const getUserDisplayName = () => {
                if (relatedInquiry.userInfo?.profiletype === "professionnel" || relatedInquiry.companyData?.profiletype === "professionnel") {
                  return relatedInquiry.userInfo?.nomsociete || relatedInquiry.companyData?.nomsociete || "Entreprise"
                }
                return relatedInquiry.userInfo?.pseudo || relatedInquiry.companyData?.pseudo || "Particulier"
              }

              const getUserPhoto = () => {
                const photoUrl = relatedInquiry.userInfo?.photoprofilurl || relatedInquiry.companyData?.photoprofilurl
                if (!photoUrl) return null
                if (photoUrl.startsWith("http")) return photoUrl
                return `${config.API_URL}${photoUrl}`
              }

              const getTimeAgo = (date: string) => {
                const now = new Date()
                const past = new Date(date)
                const diffInMs = now.getTime() - past.getTime()
                const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
                const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
                const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
                const diffInMonths = Math.floor(diffInDays / 30)

                if (diffInMinutes < 60) return `Il y a ${diffInMinutes} min`
                if (diffInHours < 24) return `Il y a ${diffInHours}h`
                if (diffInDays < 30) return `Il y a ${diffInDays} jour${diffInDays > 1 ? "s" : ""}`
                return `Il y a ${diffInMonths} mois`
              }

              const getCleanDescription = () => {
                const desc = relatedInquiry.inquiryDescription || relatedInquiry.description
                if (!desc) return ""
                const cleanText = desc.replace(/<[^>]*>/g, ' ')
                const normalized = cleanText.replace(/\s+/g, ' ').trim()
                return normalized
              }

              const userName = getUserDisplayName()
              const userAvatar = getUserPhoto()
              const timeAgo = relatedInquiry.createdat ? getTimeAgo(relatedInquiry.createdat) : ""
              
              const category = relatedInquiry.inquiryType 
                ? (labelObject[relatedInquiry.inquiryType as keyof typeof labelObject] || relatedInquiry.inquiryType) 
                : "Divers"
                
              const nature = category
              
              const location = relatedInquiry.address ? formatAddress(relatedInquiry.address) : ""
              
              const isExpired = relatedInquiry.endDate ? new Date(relatedInquiry.endDate) < new Date() : false
              
              const isProfessional = relatedInquiry.userInfo?.profiletype === "professionnel" || relatedInquiry.companyData?.profiletype === "professionnel"
              
              const displayTitle = relatedInquiry.inquiryTitle || relatedInquiry.title || "Demande sans titre"
              
              return (
                <Link 
                  key={relatedInquiry.id}
                  href={`/announcements/inquiries/${relatedInquiry.id}`}
                  onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
                >
                  <Card
                    className={`h-full hover:shadow-2xl hover:-translate-y-2 transition-all duration-500 overflow-hidden group cursor-pointer border-0 bg-white/90 backdrop-blur-md flex flex-col ${
                      isExpired ? "opacity-60 grayscale" : "hover:shadow-indigo-200/60"
                    }`}
                  >
                    <div className="p-5 h-full flex flex-col">
                      {/* Header with user info */}
                      <div className="flex items-start gap-3 mb-4">
                        <div className="relative w-12 h-12 flex-shrink-0">
                          {/* Fallback */}
                          <div className="absolute inset-0 w-12 h-12 rounded-full bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center shadow-md ring-2 ring-indigo-100">
                            {isProfessional ? (
                              <Briefcase className="w-6 h-6 text-white" />
                            ) : (
                              <User className="w-6 h-6 text-white" />
                            )}
                          </div>
                          {/* Image */}
                          {userAvatar && (
                            <img
                              src={userAvatar}
                              alt={userName}
                              className="absolute inset-0 w-12 h-12 rounded-full object-cover ring-2 ring-indigo-100 shadow-md bg-white"
                              onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}
                            />
                          )}
                        </div>

                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between">
                            <div>
                              <div className="flex items-center gap-1.5 mb-0.5">
                                <p className="font-semibold text-gray-900 text-sm truncate">{userName}</p>
                                <span className="text-xs text-gray-500">• {isProfessional ? "Pro" : "Particulier"}</span>
                              </div>
                              <p className="text-xs text-gray-600">
                                {nature}
                              </p>
                            </div>
                            <div className="flex items-center gap-1">
                              <Button variant="ghost" size="icon" className="h-7 w-7 hover:bg-gray-100" onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}>
                                <Heart className="w-3.5 h-3.5 text-gray-400" />
                              </Button>
                              <Button variant="ghost" size="icon" className="h-7 w-7 hover:bg-gray-100" onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}>
                                <Share2 className="w-3.5 h-3.5 text-gray-400" />
                              </Button>
                            </div>
                          </div>

                          {/* Badges */}
                          <div className="flex items-center gap-1.5 mt-2 flex-wrap">
                            {isExpired && (
                              <Badge className="bg-red-600 text-white border-2 border-white font-bold text-xs">EXPIRÉ</Badge>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Title */}
                      <h3
                        className={`text-lg font-bold mb-2 line-clamp-2 group-hover:text-indigo-600 transition-colors ${
                          isExpired ? "text-gray-400" : "text-gray-900"
                        }`}
                      >
                        {displayTitle}
                      </h3>

                      {/* Meta info */}
                      <div className="flex items-center gap-3 text-xs text-gray-500 mb-3">
                        {location && (
                          <div className="flex items-center gap-1">
                            <MapPin className="w-3.5 h-3.5" />
                            <span className="truncate">{location}</span>
                          </div>
                        )}
                        {relatedInquiry.ray && (
                          <div className="flex items-center gap-1">
                            <Locate className="w-3.5 h-3.5" />
                            <span>{relatedInquiry.ray === "0" ? "Toute la France" : `Rayon ${relatedInquiry.ray}km`}</span>
                          </div>
                        )}
                      </div>

                      {/* Description */}
                      <p className="text-sm text-gray-600 mb-4 line-clamp-3 leading-relaxed">{getCleanDescription()}</p>

                      {/* Footer */}
                      <div className="space-y-3 mt-auto">
                        <div className="flex flex-col gap-2">
                          <Button
                            size="sm"
                            className={
                              isExpired
                                ? "w-full bg-gray-400 cursor-not-allowed text-white text-sm"
                                : "w-full bg-indigo-600 hover:bg-indigo-700 text-white text-sm"
                            }
                            disabled={isExpired}
                          >
                            {isExpired ? "Expiré" : "Voir la demande"}
                          </Button>
                          <span className="text-xs text-gray-500 text-center">{timeAgo}</span>
                        </div>
                      </div>
                    </div>
                  </Card>
                </Link>
              )
            })}
          </div>
        </div>
      </div>
    )}

    {/* Modal de liste des documents */}
    {isDocsModalOpen && (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white p-6 rounded-lg w-full max-w-lg max-h-[80vh] overflow-y-auto">
          <h2 className="text-xl font-bold mb-4">Documents disponibles</h2>
          {documents.length > 0 ? (
            <div className="space-y-3">
              {documents.map((doc, idx) => (
                <div key={idx} className="flex items-center p-2 hover:bg-gray-100 rounded-md">
                  <FileText
                    strokeWidth={2}
                    size={24}
                    className={`${doc.name?.toLowerCase().endsWith('.pdf') ? 'text-red-700' : 'text-blue-700'} mr-2`}
                  />
                  <span className="flex-1 font-medium">{doc.name}</span>
                  <button
                    className="p-2 rounded-full hover:bg-gray-200 mr-2"
                    title="Voir le document"
                    onClick={() => setPreviewFile({ url: getDocumentUrl(doc.url), name: doc.name })}
                  >
                    <Eye size={20} />
                  </button>
                  <a
                    href={getDocumentUrl(doc.url)}
                    download={doc.name}
                    className="p-2 rounded-full hover:bg-gray-200"
                    title="Télécharger"
                    onClick={e => e.stopPropagation()}
                  >
                    <Download size={20} />
                  </a>
                </div>
              ))}
            </div>
          ) : (
            <p>Aucun document disponible</p>
          )}
          <div className="mt-4 flex justify-end">
            <button
              className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
              onClick={() => setIsDocsModalOpen(false)}
            >
              Fermer
            </button>
          </div>
        </div>
      </div>
    )}

    {/* Modal de prévisualisation simple */}
    <SimpleFilePreviewModal
      isOpen={!!previewFile}
      onClose={() => setPreviewFile(null)}
      fileUrl={previewFile?.url || ''}
      fileName={previewFile?.name || ''}
    />

    <ShareModal
      isOpen={showShareModal}
      onClose={() => setShowShareModal(false)}
      title={event?.inquiryTitle || event?.title || ""}
      url={`/announcements/inquiries/${announcementId}`}
      description={event?.inquiryDescription || event?.description}
    />
  </div>
  )
}