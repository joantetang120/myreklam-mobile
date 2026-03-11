"use client"

import { use, useEffect, useState } from "react"
import { notFound } from "next/navigation"
import { fetchAnnouncementDetail } from "@/lib/api/deals"
import { fetchDealImages, fetchPublisherData, toggleFavorite, startConversation, createApplication, checkUserSubscription } from "@/lib/api"
import { config } from "@/lib/config"
import axios from "axios"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  Heart,
  Share2,
  MapPin,
  Calendar,
  ExternalLink,
  Briefcase,
  Clock,
  DollarSign,
  GraduationCap,
  Home,
  ChevronRight,
  Building2,
  User,
  CheckCircle2,
  Gift,
  Wifi,
  CalendarClock,
  Mail,
  FileText,
  Euro,
} from "lucide-react"
import { toastSuccess, toastError } from "@/lib/utils/toast"
import labelObject from "@/lib/constants/label-object"
import Image from "next/image"
import { formatDateRelative } from "@/lib/utils"
import Link from "next/link"
import { CommentsSection } from "@/components/comments/comments-section"
import { useRouter } from "next/navigation"
import { ShareModal } from "@/components/share-modal"
import { PublisherCard } from "@/components/publisher-card"
import { LocationMap } from "@/components/map/location-map"
import { ProfileLinkGuard } from "@/components/profile-link-guard"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { FeatureList } from "@/components/FeatureList"
// import { LocationMap } from "@/components/map/location-map"
import { toast } from "sonner"

function formatAddress(address: any): string {
  if (!address) return ""

  if (typeof address === "string") {
    try {
      address = JSON.parse(address)
    } catch {
      return address
    }
  }

  const parts = []

  if (address.line1 || address.adresse) parts.push(address.line1 || address.adresse)
  if (address.city || address.ville) parts.push(address.city || address.ville)
  if (address.zipcode || address.codepostal) parts.push(address.zipcode || address.codepostal)
  if (address.country || address.pays) {
    if (address.country === "France" && !address.city && !address.ville) {
      return "Toute la France"
    }
    if (address.country !== "France" || parts.length === 0) {
      parts.push(address.country || address.pays)
    }
  }

  return parts.filter(Boolean).join(", ") || "Non spécifié"
}

function sanitizeHtml(html: string): string {
  if (!html) return ""
  // Nettoyer les styles inline excessifs mais garder la structure HTML
  return html
    .replace(/style="[^"]*"/g, '') // Supprimer les styles inline
    .replace(/class="[^"]*"/g, '') // Supprimer les classes
    .trim()
}

async function updateViewCount(announcementId: string) {
  try {
    console.log("[v0] Updating view count for job announcement:", announcementId)
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

function ImageCarousel({ images }: { images: string[] }) {
  const [currentIndex, setCurrentIndex] = useState(0)
  const [imageErrors, setImageErrors] = useState<Set<number>>(new Set())

  if (!images || images.length === 0) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-yellow-50 to-orange-50">
        <Briefcase className="w-24 h-24 text-yellow-300" />
      </div>
    )
  }

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % images.length)
  }

  const prevImage = () => {
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length)
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

  const handleImageError = (index: number) => {
    console.error(`Erreur de chargement pour l'image ${index}:`, getImageUrl(images[index]))
    setImageErrors(prev => new Set(prev).add(index))
  }

  // Vérifier si l'image courante a une erreur
  const currentImageHasError = imageErrors.has(currentIndex)
  
  
  return (
    <div className="relative w-full h-full group">
      {/* <Image
        // src={`${config.API_URL}${images[currentIndex]}`}
        src={getImageUrl(images[currentIndex])}
        alt="Job image"
        fill
        className="object-cover"
        onError={(e) => {
          const target = e.target as HTMLImageElement
          target.style.display = "none"
        }}
        unoptimized
      /> */}
      {currentImageHasError ? (
        <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-yellow-50 to-orange-50">
          <div className="text-center">
            <Briefcase className="w-24 h-24 text-yellow-300 mx-auto mb-4" />
            <p className="text-gray-500">Image non disponible</p>
            <p className="text-xs text-gray-400 mt-2">Bloquée par le navigateur</p>
          </div>
        </div>
      ) : (
        <Image
          src={getImageUrl(images[currentIndex])}
          alt="Job image"
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
            <ChevronRight className="w-6 h-6 rotate-180" />
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
                }`}
                aria-label={`Aller à l'image ${idx + 1}`}
              />
            ))}
          </div>
        </>
      )}
    </div>
  )
}


const JobDetailsSidebar = ({ job }: { job: any }) => {
  const address = job?.address ? (typeof job.address === "string" ? JSON.parse(job.address) : job.address) : null;

  // Description de l'offre sur la date
  let descriptionDate = "Immédiatement";
  if (!job.startDate) {
    descriptionDate = `Immédiatement ${job.endDate ? `jusqu'au ${formatSimpleDate(job.endDate)}` : ""}`;
  } else {
    descriptionDate = `A partir du ${formatSimpleDate(job.startDate)} ${job.endDate ? `jusqu'au ${formatSimpleDate(job.endDate)}` : ""}`;
  }

  const program = job.program ? job.program.replace(/[{}"]/g, "") : "Non spécifiée";

  const jobFeatures = [
    // Type de contrat
    job.contractType && {
      icon: "file-text",
      title: "Type de contrat",
      description: labelObject[job.contractType as keyof typeof labelObject] || job.contractType,
    },

    // Condition d'emploi
    job.condition && {
      icon: "credit-card", 
      title: "Condition",
      description: labelObject[job.condition as keyof typeof labelObject] || job.condition,
    },

    // Offre à pourvoir
    {
      icon: "calendar",
      title: "Offre à pourvoir", 
      description: descriptionDate,
    },

    // Programme
    program !== "Non spécifiée" && {
      icon: "check-circle",
      title: "Programme",
      description: program,
    },

    // Télétravail
    {
      icon: "home",
      title: "Télétravail possible",
      description: job.remote ? "Oui" : "Non",
    },

    // Durée/temps de travail
    job.occupationTime && {
      icon: "clock",
      title: "Durée",
      description: labelObject[job.occupationTime as keyof typeof labelObject] || job.occupationTime,
    },

    // Fonction du poste
    job.jobFunction && {
      icon: "briefcase",
      title: "Fonction",
      description: labelObject[job.jobFunction as keyof typeof labelObject] || job.jobFunction,
    },

    // Secteur d'activité
    job.activity && {
      icon: "building",
      title: "Secteur d'activité",
      description: labelObject[job.activity as keyof typeof labelObject] || job.activity,
    },

    // Sous-catégorie
    job.subCategory && {
      icon: "tag",
      title: "Catégorie du poste",
      description: labelObject[job.subCategory as keyof typeof labelObject] || job.subCategory,
    },

    // Niveau d'études
    job.studyLevel && {
      icon: "graduation-cap",
      title: "Niveau d'études requis",
      description: labelObject[job.studyLevel as keyof typeof labelObject] || job.studyLevel,
    },

    // Niveau d'expérience
    job.xpLevel && {
      icon: "briefcase",
      title: "Niveau d'expérience",
      description: labelObject[job.xpLevel as keyof typeof labelObject] || job.xpLevel,
    },

    // Salaire - utiliser la fonction getSalaryDisplay
    (() => {
      // Si salaire basé sur profil
      if (job.issalarybasedonprofile) {
        return {
          icon: "euro-sign",
          title: "Salaire",
          description: "Selon le profil",
          bold: true,
        };
      }
      
      // Si pas de données de salaire
      if (!job.minSalary && !job.maxSalary && !job.salary) return null;

      // Déterminer le type de salaire (brut/net)
      const salaryType = job.netSalary === "raw" ? "brut" : job.netSalary === "net" ? "net" : "";
      
      // Déterminer la période
      let period = "";
      if (job.unitSalary === "years") period = " /an";
      else if (job.unitSalary === "month") period = " /mois";
      else if (job.unitSalary === "day" || job.unitSalary === "days") period = " /jour";
      else if (job.unitSalary === "hour" || job.unitSalary === "hours") period = " /heure";

      let salaryDisplay = "";

      // Debug logs
      console.log('Salary Debug:', {
        salaryExact: job.salaryExact,
        minSalary: job.minSalary,
        maxSalary: job.maxSalary,
        netSalary: job.netSalary,
        unitSalary: job.unitSalary,
        issalarybasedonprofile: job.issalarybasedonprofile
      });

      // Si salaryExact est true, afficher uniquement maxSalary
      const isSalaryExact = job.salaryExact === true || job.salaryExact === "true";
      
      if (isSalaryExact && job.maxSalary && job.maxSalary !== "0.00" && job.maxSalary !== "0") {
        const max = parseFloat(job.maxSalary);
        console.log('Displaying exact salary:', max);
        if (!isNaN(max) && max > 0) {
          salaryDisplay = `<span class='text-green-600 font-bold'>${max.toLocaleString('fr-FR')}€</span> <span class='text-gray-900'>${salaryType}${period}</span>`;
        }
      }
      // Sinon afficher la fourchette
      else if (job.minSalary && job.maxSalary && !isSalaryExact) {
        const min = parseFloat(job.minSalary);
        const max = parseFloat(job.maxSalary);
        console.log('Displaying salary range:', min, max);
        if (!isNaN(min) && !isNaN(max) && (min > 0 || max > 0)) {
          salaryDisplay = `<span class='text-green-600 font-bold'>${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€</span> <span class='text-gray-900'>${salaryType}${period}</span>`;
        }
      }
      else if (job.minSalary && job.minSalary !== "0.00" && job.minSalary !== "0") {
        const min = parseFloat(job.minSalary);
        console.log('Displaying min salary:', min);
        if (!isNaN(min) && min > 0) {
          salaryDisplay = `<span class='text-gray-900'>À partir de</span> <span class='text-green-600 font-bold'>${min.toLocaleString('fr-FR')}€</span> <span class='text-gray-900'>${salaryType}${period}</span>`;
        }
      }

      if (salaryDisplay) {
        return {
          icon: "euro-sign",
          title: "Salaire",
          description: salaryDisplay.trim(),
          bold: true,
        };
      }

      return null;
    })(),

    // Type de rémunération
    job.salaryType && {
      icon: "credit-card",
      title: "Type de rémunération", 
      description: job.salaryType === 'range' ? 'Tranche salariale' :
                   job.salaryType === 'exact' ? 'Salaire exact' :
                   job.salaryType === 'profile' ? 'Selon profil' : job.salaryType,
    },

    // Messages autorisés
    job.acceptMessages !== undefined && {
      icon: "mail",
      title: "Messages autorisés",
      description: job.acceptMessages ? "Oui" : "Non",
    },

    // Affichage adresse
    job.showAddress !== undefined && {
      icon: "map-pin",
      title: "Affichage adresse",
      description: job.showAddress ? "Adresse visible" : "Adresse masquée",
    },

    // Présentation entreprise
    job.showpresentation !== undefined && {
      icon: "building",
      title: "Présentation entreprise",
      description: job.showpresentation ? "Affichée" : "Masquée",
    },

    // Localisation
    address && {
      icon: "map-pin",
      title: "Localisation",
      description: formatAddress(address),
    },

    // Date de publication
    job.createdat && {
      icon: "calendar",
      title: "Publié",
      description: formatDateRelative(job.createdat),
    },

    // Nombre de vues
    job.number_view && {
      icon: "eye",
      title: "Vues",
      description: `${job.number_view} vue${job.number_view > 1 ? 's' : ''}`,
    },
  ].filter(Boolean);

  return (
    <Card className="p-6 bg-orange-50/30 border-orange-200">
      <div className="space-y-3">
        {/* Fonction */}
        {job.jobFunction && (
          <div className="flex items-start gap-3">
            <div className="bg-orange-100 rounded-lg p-2 flex-shrink-0">
              <Briefcase className="w-5 h-5 text-orange-600" />
            </div>
            <div className="flex-1">
              <p className="text-xs text-gray-600 font-medium">Fonction</p>
              <p className="text-sm font-bold text-gray-900">{labelObject[job.jobFunction as keyof typeof labelObject] || job.jobFunction}</p>
            </div>
          </div>
        )}

        {/* Type de contrat */}
        {job.contractType && (
          <div className="flex items-start gap-3">
            <div className="bg-blue-100 rounded-lg p-2 flex-shrink-0">
              <FileText className="w-5 h-5 text-blue-600" />
            </div>
            <div className="flex-1">
              <p className="text-xs text-gray-600 font-medium">Contrat</p>
              <p className="text-sm font-bold text-gray-900">{labelObject[job.contractType as keyof typeof labelObject] || job.contractType}</p>
            </div>
          </div>
        )}

        {/* Offre à pourvoir */}
        <div className="flex items-start gap-3">
          <div className="bg-indigo-100 rounded-lg p-2 flex-shrink-0">
            <CalendarClock className="w-5 h-5 text-indigo-600" />
          </div>
          <div className="flex-1">
            <p className="text-xs text-gray-600 font-medium">Offre à pourvoir</p>
            <p className="text-sm font-bold text-gray-900">
              {!job.startDate 
                ? `Immédiatement${job.endDate ? ` jusqu'au ${formatSimpleDate(job.endDate)}` : ""}`
                : `À partir du ${formatSimpleDate(job.startDate)}${job.endDate ? ` jusqu'au ${formatSimpleDate(job.endDate)}` : ""}`
              }
            </p>
          </div>
        </div>

        {/* Télétravail */}
        <div className="flex items-start gap-3">
          <div className={`${job.remote && job.remote !== 'f' && job.remote !== null ? 'bg-green-100' : 'bg-red-100'} rounded-lg p-2 flex-shrink-0`}>
            {job.remote && job.remote !== 'f' && job.remote !== null ? <Wifi className="w-5 h-5 text-green-600" /> : <Home className="w-5 h-5 text-red-600" />}
          </div>
          <div className="flex-1">
            <p className="text-xs text-gray-600 font-medium">Politique de télétravail</p>
            <p className={`text-sm font-bold ${job.remote && job.remote !== 'f' && job.remote !== null ? 'text-green-600' : 'text-red-600'}`}>
              {job.remote && job.remote !== 'f' && job.remote !== null ? 'Télétravail possible' : 'Pas de télétravail'}
            </p>
          </div>
        </div>

        {/* Niveau d'études */}
        {job.studyLevel && (
          <div className="flex items-start gap-3">
            <div className="bg-purple-100 rounded-lg p-2 flex-shrink-0">
              <GraduationCap className="w-5 h-5 text-purple-600" />
            </div>
            <div className="flex-1">
              <p className="text-xs text-gray-600 font-medium">Formation</p>
              <p className="text-sm font-bold text-gray-900">{labelObject[job.studyLevel as keyof typeof labelObject] || job.studyLevel}</p>
            </div>
          </div>
        )}

        {/* Expérience */}
        {job.xpLevel && (
          <div className="flex items-start gap-3">
            <div className="bg-green-100 rounded-lg p-2 flex-shrink-0">
              <Briefcase className="w-5 h-5 text-green-600" />
            </div>
            <div className="flex-1">
              <p className="text-xs text-gray-600 font-medium">Expérience</p>
              <p className="text-sm font-bold text-gray-900">{labelObject[job.xpLevel as keyof typeof labelObject] || job.xpLevel}</p>
            </div>
          </div>
        )}

        {/* Temps de travail */}
        {job.occupationTime && (
          <div className="flex items-start gap-3">
            <div className="bg-yellow-100 rounded-lg p-2 flex-shrink-0">
              <Clock className="w-5 h-5 text-yellow-600" />
            </div>
            <div className="flex-1">
              <p className="text-xs text-gray-600 font-medium">Temps de travail</p>
              <p className="text-sm font-bold text-gray-900">{labelObject[job.occupationTime as keyof typeof labelObject] || job.occupationTime}</p>
            </div>
          </div>
        )}

        {/* Salaire */}
        {(job.minSalary || job.maxSalary || job.salaryExact || job.issalarybasedonprofile) && (() => {
          const isSalaryExact = job.salaryExact === true || job.salaryExact === "true";
          const salaryType = job.netSalary === "raw" ? "brut" : job.netSalary === "net" ? "net" : "";
          let period = "";
          if (job.unitSalary === "years") period = " /an";
          else if (job.unitSalary === "month") period = " /mois";
          else if (job.unitSalary === "day" || job.unitSalary === "days") period = " /jour";
          else if (job.unitSalary === "hour" || job.unitSalary === "hours") period = " /heure";
          
          console.log('Sidebar Salary - unitSalary:', job.unitSalary, 'period:', period);

          let salaryText = 'Non communiqué';
          
          if (job.issalarybasedonprofile) {
            salaryText = 'Selon le profil';
          } else if (isSalaryExact && job.maxSalary) {
            const max = parseFloat(job.maxSalary);
            if (!isNaN(max) && max > 0) {
              salaryText = `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim();
            }
          } else if (job.minSalary && job.maxSalary && job.maxSalary !== job.minSalary) {
            const min = parseFloat(job.minSalary);
            const max = parseFloat(job.maxSalary);
            if (!isNaN(min) && !isNaN(max)) {
              salaryText = `${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim();
            }
          } else if (job.minSalary) {
            const min = parseFloat(job.minSalary);
            if (!isNaN(min) && min > 0) {
              salaryText = `${min.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim();
            }
          }

          return (
            <div className="flex items-start gap-3">
              <div className="bg-green-100 rounded-lg p-2 flex-shrink-0">
                <Euro className="w-5 h-5 text-green-600" />
              </div>
              <div className="flex-1">
                <p className="text-xs text-gray-600 font-medium">Salaire</p>
                <p className="text-sm font-bold text-green-600">{salaryText}</p>
              </div>
            </div>
          );
        })()}
      </div>
    </Card>
  );
};

// Composant pour les entreprises partenaires
const JobBusinessPartners = ({ business }: { business: string }) => {
  if (!business || business === '{}') return null;

  let businesses: string[] = [];
  try {
    businesses = typeof business === 'string' 
      ? JSON.parse(business.replace(/[{}]/g, '').split(',').map(s => `"${s.trim()}"`).join(','))
      : business;
  } catch {
    return null;
  }

  if (!Array.isArray(businesses) || businesses.length === 0) return null;

  return (
    <div className="space-y-3">
      <h2 className="text-xl font-semibold text-gray-900 flex items-center gap-2">
        <Building2 className="h-5 w-5" />
        Entreprises partenaires
      </h2>
      <div className="flex flex-wrap gap-2">
        {businesses.map((biz: string, idx: number) => (
          <Badge key={idx} variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
            <Building2 className="w-3 h-3 mr-1" />
            {biz}
          </Badge>
        ))}
      </div>
    </div>
  );
};

// Composant pour les compétences
const JobSkills = ({ skills }: { skills: string }) => {
  if (!skills) return null;

  return (
    <div className="border border-gray-200 p-6 rounded-none">
      <h2 className="text-2xl font-bold mb-6 flex items-center gap-2">
        <CheckCircle2 className="w-6 h-6 text-green-600" />
        Compétences requises
      </h2>
      <div 
        className="prose prose-slate max-w-none text-gray-700 leading-relaxed"
        dangerouslySetInnerHTML={{ __html: sanitizeHtml(skills) }}
      />
    </div>
  );
};

// Composant pour les avantages
const JobBenefits = ({ benefits }: { benefits: string[] | string }) => {
  console.log('JobBenefits - Raw benefits:', benefits);
  console.log('JobBenefits - Type:', typeof benefits);
  
  let benefitsList: string[] = [];
  
  try {
    if (benefits) {
      if (Array.isArray(benefits)) {
        benefitsList = benefits;
      } else if (typeof benefits === 'string') {
        // Nettoyer le format PostgreSQL {value1,value2} ou {"value"}
        const cleaned = benefits.replace(/[{}"]/g, '').trim();
        console.log('JobBenefits - Cleaned:', cleaned);
        if (cleaned) {
          benefitsList = cleaned.split(',').map(b => b.trim()).filter(Boolean);
        }
      } else if (typeof benefits === 'object') {
        // Si c'est un objet, essayer de le convertir
        benefitsList = Object.values(benefits).filter(Boolean);
      }
    }
  } catch (error) {
    console.error('Error parsing benefits:', error);
  }

  console.log('JobBenefits - Final list:', benefitsList);

  if (benefitsList.length === 0) {
    console.log('JobBenefits - No benefits to display');
    return null;
  }

  return (
    <Card className="p-6 shadow-sm">
      <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
        <Gift className="w-6 h-6 text-yellow-600" />
        Avantages
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {benefitsList.map((benefit: string, index: number) => (
          <div key={index} className="flex items-center gap-2 text-gray-700">
            <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />
            <span className="text-sm">{labelObject[benefit as keyof typeof labelObject] || benefit}</span>
          </div>
        ))}
      </div>
    </Card>
  );
};

// Composant pour le profil recherché  
const JobProfile = ({ job }: { job: any }) => {
  const hasProfileInfo = job.descriptionprofil || job.profileDescription || job.studyLevel || job.xpLevel || job.contractType || job.occupationTime;
  
  if (!hasProfileInfo) return null;

  const getOccupationTimeLabel = () => {
    if (job.occupationTime === "fullTime") return "Temps plein"
    if (job.occupationTime === "partTime") return "Temps partiel"
    return null
  }

  return (
    <Card className="p-6 shadow-sm overflow-hidden">
      <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
        <User className="w-6 h-6 text-yellow-600" />
        Profil recherché
      </h2>
      
      {/* Badges - Same as listing page */}
      <div className="flex flex-wrap items-center gap-2 mb-6">
        {/* Type de contrat */}
        {job.contractType && (
          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
            <FileText className="w-3 h-3 mr-1 inline" />
            {labelObject[job.contractType as keyof typeof labelObject] || job.contractType}
          </Badge>
        )}

        {/* Niveau d'études */}
        {job.studyLevel && (
          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
            <GraduationCap className="w-3 h-3 mr-1 inline" />
            {labelObject[job.studyLevel as keyof typeof labelObject] || job.studyLevel}
          </Badge>
        )}

        {/* Niveau d'expérience */}
        {job.xpLevel && (
          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
            <Briefcase className="w-3 h-3 mr-1 inline" />
            {labelObject[job.xpLevel as keyof typeof labelObject] || job.xpLevel}
          </Badge>
        )}

        {/* Temps de travail */}
        {getOccupationTimeLabel() && (
          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
            <Clock className="w-3 h-3 mr-1 inline" />
            {getOccupationTimeLabel()}
          </Badge>
        )}

        {/* Télétravail */}
        {job.remote !== null && job.remote !== undefined && (
          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
            {job.remote === 't' || job.remote === true ? (
              <>
                <Wifi className="w-3 h-3 mr-1 inline" />
                Télétravail possible
              </>
            ) : (
              <>
                <Home className="w-3 h-3 mr-1 inline" />
                Présentiel uniquement
              </>
            )}
          </Badge>
        )}
      </div>

      {/* Description du profil */}
      {(job.descriptionprofil || job.profileDescription) && (
        <div>
          <p className="text-sm font-semibold text-gray-900 mb-2">Description du profil :</p>
          <div 
            className="prose prose-slate max-w-none text-gray-700 leading-relaxed break-words overflow-wrap-anywhere"
            dangerouslySetInnerHTML={{ __html: sanitizeHtml(job.descriptionprofil || job.profileDescription) }}
          />
        </div>
      )}
    </Card>
  );
};

// Fonction utilitaire pour formater une date simple
const formatSimpleDate = (dateString: string): string => {
  try {
    return new Date(dateString).toLocaleDateString("fr-FR", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  } catch {
    return dateString;
  }
};


export default function JobPage({ params }: { params: { announcementId: string } }) {
  const resolvedParams = use(params)
  const announcementId = resolvedParams.announcementId

  const [job, setJob] = useState<any>(null)
  const [images, setImages] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [isFavorite, setIsFavorite] = useState(false)
  const [relatedJobs, setRelatedJobs] = useState<any[]>([])
  const [companyData, setCompanyData] = useState<any>(null)
  const [currentUserData, setCurrentUserData] = useState<any>(null)
  const [publisherHasSubscription, setPublisherHasSubscription] = useState(false)
  const router = useRouter()
  const [isContactingLoading, setIsContactingLoading] = useState(false)
  const [showShareModal, setShowShareModal] = useState(false)
  
  const currentUserIsPro = currentUserData?.companyData?.profiletype === "professionnel"
  const [showApplicationDialog, setShowApplicationDialog] = useState(false)
  const [isApplying, setIsApplying] = useState(false)
  const [applicationResult, setApplicationResult] = useState<{
    success: boolean
    message: string
  } | null>(null)

  // const announcementId = params.announcementId
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") || "" : ""

  const isExpired = job?.endDate ? new Date(job.endDate) < new Date() : false

  const handleFavorite = async (newFavoriteState: boolean) => {
    const result = await toggleFavorite(userId, job?.id || "", newFavoriteState)
    if (result.success) {
      toastSuccess(result.message || "Favori mis à jour")
      setIsFavorite(newFavoriteState)
    } else {
      toastError(result.error || "Erreur lors de la mise à jour")
    }
  }

  const handleShare = () => {
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

  const handleApplyClick = () => {
    if (!userId) {
      router.push("/login-required")
      return
    }
    setShowApplicationDialog(true)
  }

  const handleConfirmApplication = async () => {
    setIsApplying(true)
    try {
      const result = await createApplication(announcementId, userId, 1)
      
      if (result.status === "success") {
        setApplicationResult({
          success: true,
          message: result.message || "Candidature créée avec succès"
        })
      } else {
        setApplicationResult({
          success: false,
          message: result.message || "Erreur lors de la création de la candidature"
        })
      }
    } catch (error) {
      console.error("Erreur lors de la candidature:", error)
      setApplicationResult({
        success: false,
        message: "Erreur lors de la création de la candidature"
      })
    } finally {
      setIsApplying(false)
      setShowApplicationDialog(false)
    }
  }

  useEffect(() => {
    if (!announcementId) return

    const fetchJobData = async () => {
      try {
        const fetchedJob = await fetchAnnouncementDetail(announcementId)
        if (!fetchedJob) {
          notFound()
        }
        setJob(fetchedJob)
        setIsFavorite(fetchedJob.isFavorite || false)

        await updateViewCount(announcementId)

        const imagesResult = await fetchDealImages(announcementId)
        if (imagesResult.success) {
          setImages(imagesResult.images)
        }
      } catch (error) {
        console.error("Error loading job data:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchJobData()
  }, [announcementId])

  useEffect(() => {
    if (job?.userId) {
      const loadPublisherData = async () => {
        const result = await fetchPublisherData(job.userId)
        if (result.success) {
          setCompanyData(result.userData.companyData)
          // Vérifier si le publisher a un abonnement
          const hasSubscription = await checkUserSubscription(job.userId)
          setPublisherHasSubscription(hasSubscription)
        }
      }
      loadPublisherData()
    }
  }, [job?.userId])

  // Charger les données de l'utilisateur connecté
  useEffect(() => {
    if (userId) {
      const loadCurrentUserData = async () => {
        const result = await fetchPublisherData(userId)
        if (result.success) {
          setCurrentUserData(result.userData)
        }
      }
      loadCurrentUserData()
    }
  }, [userId])

  // Charger les offres d'emploi similaires
  useEffect(() => {
    if (job) {
      const loadRelatedJobs = async () => {
        try {
          const response = await axios.post(
            "https://api.myreklam.fr/Ads.php",
            {
              Method: "readAdsByCriteria",
              category: "emplois",
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
            setRelatedJobs(filtered)
          }
        } catch (error) {
          console.error("Error loading related jobs:", error)
        }
      }
      loadRelatedJobs()
    }
  }, [job, announcementId])

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-24 mb-40">
        <div className="animate-pulse space-y-8">
          <div className="h-8 bg-gray-200 rounded w-3/4"></div>
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-4">
              <div className="h-96 bg-gray-200 rounded"></div>
              <div className="h-32 bg-gray-200 rounded"></div>
            </div>
            <div className="space-y-4">
              <div className="h-64 bg-gray-200 rounded"></div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!job) {
    notFound()
  }

  const getSalaryDisplay = () => {
    // Si salaire basé sur profil
    if (job.issalarybasedonprofile) return "Salaire selon profil"
    
    // Si pas de données de salaire
    if (!job.minSalary && !job.maxSalary && !job.salary) return "Salaire selon profil"

    // Déterminer le type de salaire (brut/net)
    const salaryType = job.netSalary === "raw" ? "brut" : job.netSalary === "net" ? "net" : ""
    
    // Déterminer la période
    let period = ""
    if (job.unitSalary === "years") period = " /an"
    else if (job.unitSalary === "month") period = " /mois"
    else if (job.unitSalary === "day" || job.unitSalary === "days") period = " /jour"
    else if (job.unitSalary === "hour" || job.unitSalary === "hours") period = " /heure"

    // Si salaryExact est true, afficher uniquement maxSalary
    const isSalaryExact = job.salaryExact === true || job.salaryExact === "true";
    
    if (isSalaryExact && job.maxSalary) {
      const max = parseFloat(job.maxSalary)
      if (max === 0) return "Salaire selon profil"
      return `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    // Sinon afficher la fourchette
    if (job.minSalary && job.maxSalary && !isSalaryExact) {
      const min = parseFloat(job.minSalary)
      const max = parseFloat(job.maxSalary)
      if (min === 0 && max === 0) return "Salaire selon profil"
      return `${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }
    
    if (job.minSalary) {
      const min = parseFloat(job.minSalary)
      if (min === 0) return "Salaire selon profil"
      return `À partir de ${min.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
    }

    // Fallback sur job.salary si présent
    if (job.salary) return job.salary

    return "Salaire selon profil"
  }

  const benefits = job.benefits ? (typeof job.benefits === "string" ? JSON.parse(job.benefits) : job.benefits) : []

  const getCompanyName = () => {
    if (!companyData) return "Entreprise"
    return companyData.profiletype === "professionnel"
      ? companyData.nomsociete || "Entreprise"
      : companyData.pseudo || "Particulier"
  }

  const getCompanyInitials = () => {
    const name = getCompanyName()
    return name.substring(0, 2).toUpperCase()
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <nav className="flex items-center gap-2 text-sm">
            <Link href="/" className="text-gray-500 hover:text-gray-700 flex items-center gap-1">
              <Home className="w-4 h-4" />
              Accueil
            </Link>
            <ChevronRight className="w-4 h-4 text-gray-400" />
            <Link href="/offres-emploi" className="text-gray-500 hover:text-gray-700">
              Offres d'emploi
            </Link>
            <ChevronRight className="w-4 h-4 text-gray-400" />
            <span className="text-gray-900 font-medium truncate max-w-md">{job.title}</span>
          </nav>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8 py-6 sm:py-8 md:py-12">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden mb-8">
            {/* Image Carousel */}
            {images.length > 0 && (
              <div className="relative h-[300px] md:h-[400px]">
                <ImageCarousel images={images} />
                {isExpired && (
                  <div className="absolute top-4 right-4 z-10">
                    <Badge className="bg-red-600 text-white border-2 border-white shadow-lg text-sm px-3 py-1">
                      EXPIRÉ
                    </Badge>
                  </div>
                )}
              </div>
            )}

          {/* Job Header */}
          <div className="p-6 md:p-8">
            <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-6">
              <div className="flex-1">
                <div className="flex flex-wrap items-center gap-2 mb-3">
                  <Badge className="bg-yellow-100 text-yellow-800 hover:bg-yellow-100">
                    {labelObject[job.jobCategory as keyof typeof labelObject] || job.jobCategory || "Emploi"}
                  </Badge>
                  {job.contractType && (
                    <Badge variant="outline" className="border-gray-300">
                      {labelObject[job.contractType as keyof typeof labelObject] || job.contractType}
                    </Badge>
                  )}
                  {isExpired && <Badge className="bg-red-100 text-red-800 border-red-200">Offre expirée</Badge>}
                </div>
                <h1 className={`text-3xl md:text-4xl font-bold mb-4 ${isExpired ? "text-gray-500" : "text-gray-900"}`}>
                  {job.title}
                </h1>

                {/* Company Info */}
                <div className="flex items-center gap-3 mb-4">
                  <Avatar className="w-12 h-12 border-2 border-gray-200">
                    <AvatarImage
                      src={companyData?.photoprofilurl ? `${config.API_URL}${companyData.photoprofilurl}` : undefined}
                      alt={getCompanyName()}
                    />
                    <AvatarFallback className="bg-gradient-to-br from-yellow-400 to-orange-500 text-white font-semibold">
                      {getCompanyInitials()}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="flex items-center gap-2">
                      <ProfileLinkGuard
                        userId={job.userId}
                        className="font-semibold text-gray-900 hover:text-yellow-600 transition-colors cursor-pointer"
                      >
                        {getCompanyName()}
                      </ProfileLinkGuard>
                      {companyData?.profiletype === "professionnel" ? (
                        <Badge className="bg-blue-100 text-blue-800 text-xs">
                          <Building2 className="w-3 h-3 mr-1" />
                          Pro
                        </Badge>
                      ) : (
                        <Badge className="bg-gray-100 text-gray-800 text-xs">
                          <User className="w-3 h-3 mr-1" />
                          Particulier
                        </Badge>
                      )}
                    </div>
                    {companyData?.activite && companyData.activite !== "informationCommunication" && (
                      <p className="text-sm text-gray-600">
                        {labelObject[companyData.activite as keyof typeof labelObject] || companyData.activite}
                      </p>
                    )}
                  </div>
                </div>

                {/* Key Info Row */}
                <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
                  {job.location && (
                    <div className="flex items-center gap-1.5">
                      <MapPin className="w-4 h-4 text-yellow-600" />
                      <span>{formatAddress(job.address)}</span>
                    </div>
                  )}
                  <div className="flex items-center gap-1.5">
                    <Calendar className="w-4 h-4 text-gray-400" />
                    <span className="text-gray-500">{formatDateRelative(job.createdat)}</span>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="icon"
                  onClick={() => handleFavorite(!isFavorite)}
                  className="hover:bg-red-50 hover:border-red-200"
                >
                  <Heart className={`w-5 h-5 ${isFavorite ? "fill-red-500 text-red-500" : "text-gray-600"}`} />
                </Button>
                <Button
                  variant="outline"
                  size="icon"
                  onClick={handleShare}
                  className="hover:bg-blue-50 hover:border-blue-200 bg-transparent"
                >
                  <Share2 className="w-5 h-5 text-gray-600" />
                </Button>
              </div>
            </div>

            {/* Salary Display */}
            {job.salary && (
              <div className="bg-gradient-to-r from-yellow-50 to-orange-50 border-2 border-yellow-200 rounded-xl p-4 inline-flex items-center gap-3">
                <div className="bg-yellow-500 rounded-full p-2">
                  <DollarSign className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className="text-xs text-gray-600 font-medium">Rémunération</p>
                  <p className={`text-xl font-bold ${isExpired ? "text-gray-400 line-through" : "text-gray-900"}`}>
                    {getSalaryDisplay()}
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 order-2 lg:order-1">
            {/* Sections d'information */}
            <div className="space-y-6">
              {/* Qui Sommes Nous ? */}
              {companyData?.presentation && (
                <Card className="p-6 shadow-sm">
                  <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                    <Building2 className="w-6 h-6 text-yellow-600" />
                    Qui Sommes Nous ?
                  </h2>
                  <div 
                    className="text-gray-700 leading-relaxed prose prose-slate max-w-none"
                    dangerouslySetInnerHTML={{ __html: sanitizeHtml(companyData.presentation) }}
                  />
                </Card>
              )}

              {/* Description du poste */}
              <Card className="p-6 shadow-sm">
                <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                  <FileText className="w-6 h-6 text-yellow-600" />
                  Description du poste
                </h2>
                <div 
                  className="prose prose-slate max-w-none text-gray-700 leading-relaxed break-words overflow-wrap-anywhere"
                  dangerouslySetInnerHTML={{ __html: sanitizeHtml(job.description) }}
                />
              </Card>

              {/* Entreprises partenaires */}
              <JobBusinessPartners business={job.business} />

              {/* Profil recherché */}
              <JobProfile job={job} />

              {/* Avantages */}
              <JobBenefits benefits={job.benefit || job.benefits} />

              {/* Compétences requises */}
              <JobSkills skills={job.skills} />

              {/* Localisation - visible uniquement si publishadresse est autorisé */}
              {job.address && companyData && (companyData.publishadresse === "true" || companyData.publishadresse === true || companyData.publishadresse === "1") && (
                <Card className="p-6 shadow-sm">
                  <h2 className="text-2xl font-bold text-gray-900 mb-4 flex items-center gap-2">
                    <MapPin className="w-6 h-6 text-yellow-600" />
                    Localisation
                  </h2>
                  <div className="space-y-4">
                    <div className="flex items-start gap-3">
                      <div className="bg-red-100 rounded-lg p-2">
                        <MapPin className="w-5 h-5 text-red-600" />
                      </div>
                      <div>
                        <p className="font-semibold text-gray-900">{formatAddress(job.address)}</p>
                      </div>
                    </div>
                    <LocationMap 
                      address={job.address} 
                      title={job.title}
                    />
                  </div>
                </Card>
              )}

              {/* Commentaires */}
              <CommentsSection announcementId={announcementId} announcementType="job" />
            </div>
          </div>
          <div className="lg:col-span-1 order-1 lg:order-2 space-y-8">
            {/* Détails de l'offre */}
            <JobDetailsSidebar job={job} />

            {/* Actions Postuler */}
            <Card className="p-6 shadow-lg border-2 border-yellow-200">
              <h3 className="font-bold text-lg mb-4">Postuler à cette offre</h3>
              <div className="space-y-3">
                {currentUserIsPro ? (
                  <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                    <p className="text-sm text-blue-800 text-center">
                      <strong>Information :</strong> Les comptes professionnels ne peuvent pas postuler aux offres d'emploi.
                    </p>
                  </div>
                ) : (
                  <Button
                    className={`w-full h-12 text-lg font-semibold ${
                      isExpired
                        ? "bg-gray-400 cursor-not-allowed"
                        : "bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600"
                    }`}
                    disabled={isExpired}
                    onClick={handleApplyClick}
                  >
                    {isExpired ? (
                      "Offre expirée"
                    ) : (
                      <>
                        <ExternalLink className="w-5 h-5 mr-2" />
                        Postuler
                      </>
                    )}
                  </Button>
                )}
                {userId !== job?.userId && (job?.acceptMessages === true || job?.message === true) && (
                  <Button
                    variant="outline"
                    className="w-full h-12 text-lg font-semibold border-2 border-yellow-500 text-yellow-700 hover:bg-yellow-50"
                    onClick={handleContact}
                    disabled={isExpired || isContactingLoading}
                  >
                    {isContactingLoading ? (
                      "Chargement..."
                    ) : (
                      <>
                        <Mail className="w-5 h-5 mr-2" />
                        Contacter
                      </>
                    )}
                  </Button>
                )}
                {job.website && !isExpired && (
                  <a
                    href={job.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block text-center text-sm text-yellow-600 hover:text-yellow-700 font-medium"
                  >
                    Voir le site de l'entreprise →
                  </a>
                )}
              </div>
            </Card>

            {/* Découvrez-nous */}
            {companyData && (
              <PublisherCard
                publisherName={getCompanyName()}
                announcementTitle={job.title}
                announcementType="emploi"
                userId={job.userId}
                photoUrl={companyData.photoprofilurl ? `${config.API_URL}${companyData.photoprofilurl}` : null}
                isProfessional={companyData.profiletype === "professionnel"}
                activite={companyData.activite}
                ville={companyData.ville}
                pays={companyData.pays}
                telephone={""}
                email={""}
                adresse={companyData.adresse}
                codePostal={companyData.codepostal}
                hasPremiumSubscription={publisherHasSubscription}
                currentUserIsPro={currentUserIsPro}
                publishadresse={companyData.publishadresse}
              />
            )}
          </div>
        </div>
      </div>

      {/* Section Offres d'emploi similaires */}
      {relatedJobs.length > 0 && (
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 bg-gradient-to-b from-gray-50 to-white">
          <div className="mb-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-2">Autres offres d'emploi</h2>
            <p className="text-gray-600">Découvrez d'autres opportunités qui pourraient vous intéresser</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {relatedJobs.map((relatedJob) => {
              const isExpired = relatedJob.endDate ? new Date(relatedJob.endDate) < new Date() : false
              
              const getTimeAgo = (date: string) => {
                const now = new Date()
                const created = new Date(date)
                const diffInMs = now.getTime() - created.getTime()
                const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))
                const diffInMonths = Math.floor(diffInDays / 30)
                if (diffInMonths > 0) return `Il y a ${diffInMonths} mois`
                if (diffInDays > 0) return `Il y a ${diffInDays} jour${diffInDays > 1 ? "s" : ""}`
                return "Aujourd'hui"
              }
              
              const getUserDisplayName = () => {
                if (relatedJob.business) {
                  try {
                    if (typeof relatedJob.business === 'string') {
                      const cleaned = relatedJob.business.replace(/[{}"]/g, '').trim()
                      if (cleaned) return cleaned
                    }
                  } catch (error) {}
                }
                const companyData = relatedJob.companyData
                if (!companyData) return "Entreprise"
                if (companyData.profiletype === "professionnel") {
                  return companyData.nomsociete || "Entreprise"
                }
                return companyData.pseudo || "Particulier"
              }
              
              const getUserPhoto = () => {
                const companyData = relatedJob.companyData
                if (!companyData || !companyData.photoprofilurl) return null
                return companyData.photoprofilurl
              }
              
              const isProfessional = relatedJob.companyData?.profiletype === "professionnel"
              const displayName = getUserDisplayName()
              const displayPhoto = getUserPhoto()
              
              const getLabel = (key: string) => {
                return labelObject[key as keyof typeof labelObject] || key
              }
              
              const getFormattedLocation = () => {
                if (!relatedJob.location && !relatedJob.address) return ""
                const locationData = relatedJob.location || relatedJob.address
                if (typeof locationData === 'string') {
                  try {
                    const parsed = JSON.parse(locationData)
                    return formatAddress(parsed)
                  } catch {
                    return locationData
                  }
                }
                return formatAddress(locationData)
              }
              
              const getOccupationTimeLabel = () => {
                if (relatedJob.occupationTime === "fullTime") return "Temps plein"
                if (relatedJob.occupationTime === "partTime") return "Temps partiel"
                return null
              }
              
              const getSalaryDisplay = () => {
                if (relatedJob.issalarybasedonprofile) return "Selon profil"
                if (!relatedJob.minSalary && !relatedJob.maxSalary && !relatedJob.salary) return null
                const salaryType = relatedJob.netSalary === "raw" ? "brut" : relatedJob.netSalary === "net" ? "net" : ""
                let period = ""
                if (relatedJob.unitSalary === "years") period = " /an"
                else if (relatedJob.unitSalary === "month") period = " /mois"
                else if (relatedJob.unitSalary === "day" || relatedJob.unitSalary === "days") period = " /jour"
                else if (relatedJob.unitSalary === "hour" || relatedJob.unitSalary === "hours") period = " /heure"
                const isSalaryExact = relatedJob.salaryExact === true || relatedJob.salaryExact === "true"
                if (isSalaryExact && relatedJob.maxSalary) {
                  const max = parseFloat(relatedJob.maxSalary)
                  if (max === 0) return null
                  return `${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
                }
                if (relatedJob.minSalary && relatedJob.maxSalary && !isSalaryExact) {
                  const min = parseFloat(relatedJob.minSalary)
                  const max = parseFloat(relatedJob.maxSalary)
                  if (min === 0 && max === 0) return null
                  return `${min.toLocaleString('fr-FR')}€ - ${max.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
                }
                if (relatedJob.minSalary) {
                  const min = parseFloat(relatedJob.minSalary)
                  if (min === 0) return null
                  return `À partir de ${min.toLocaleString('fr-FR')}€ ${salaryType}${period}`.trim()
                }
                if (relatedJob.salary) return relatedJob.salary
                return null
              }
              
              const getCleanDescription = () => {
                if (!relatedJob.description) return ""
                const cleanText = relatedJob.description.replace(/<[^>]*>/g, ' ')
                const normalized = cleanText.replace(/\s+/g, ' ').trim()
                return normalized
              }
              
              return (
                <Link key={relatedJob.id} href={`/announcements/jobs/${relatedJob.id}`}>
                  <Card
                    className={`h-full hover:shadow-2xl hover:scale-[1.02] transition-all duration-300 overflow-hidden group cursor-pointer flex flex-col border-2 ${
                      isExpired ? "opacity-75 border-red-200 bg-gray-50/50" : "border-gray-100 hover:border-blue-200"
                    }`}
                  >
                    <div className="p-6 pb-4 border-b bg-gradient-to-br from-blue-50/30 to-white relative">
                      {isExpired && (
                        <div className="absolute top-3 left-3 z-10">
                          <Badge className="bg-red-600 text-white border-2 border-white font-bold shadow-lg">EXPIRÉ</Badge>
                        </div>
                      )}
                      <div className="flex items-start justify-between mb-3">
                        <Avatar
                          className={`w-16 h-16 border-4 border-white shadow-lg ring-2 ring-blue-100 ${
                            isExpired ? "grayscale brightness-75" : ""
                          }`}
                        >
                          <AvatarImage
                            src={
                              displayPhoto
                                ? displayPhoto.startsWith("http")
                                  ? displayPhoto
                                  : `${config.API_URL}${displayPhoto}`
                                : undefined
                            }
                          />
                          <AvatarFallback className="bg-gradient-to-br from-blue-500 to-blue-600">
                            {isProfessional ? (
                              <Building2 className="w-8 h-8 text-white" />
                            ) : (
                              <User className="w-8 h-8 text-white" />
                            )}
                          </AvatarFallback>
                        </Avatar>
                        <div className="flex gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 rounded-full hover:bg-white"
                            onClick={(e) => {
                              e.preventDefault()
                              e.stopPropagation()
                            }}
                          >
                            <Heart className="w-4 h-4 text-gray-400" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8 rounded-full hover:bg-white"
                            onClick={(e) => {
                              e.preventDefault()
                              e.stopPropagation()
                            }}
                          >
                            <Share2 className="w-4 h-4 text-gray-400" />
                          </Button>
                        </div>
                      </div>
                      <h3
                        className={`font-bold text-xl mb-2 line-clamp-2 group-hover:text-blue-600 transition-colors ${
                          isExpired ? "text-gray-500" : "text-gray-900"
                        }`}
                      >
                        {relatedJob.title}
                      </h3>
                      <div className="flex items-center gap-2">
                        <p className="text-sm text-gray-700 font-semibold">{displayName}</p>
                        {isProfessional && (
                          <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200 text-xs">
                            Pro
                          </Badge>
                        )}
                      </div>
                    </div>
                    <div className="p-6 flex-1 flex flex-col">
                      <div className="flex flex-wrap items-center gap-2 mb-4">
                        {relatedJob.contractType && (
                          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                            <FileText className="w-3 h-3 mr-1 inline" />
                            {getLabel(relatedJob.contractType)}
                          </Badge>
                        )}
                        {getFormattedLocation() && (
                          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                            <MapPin className="w-3 h-3 mr-1 inline" />
                            {getFormattedLocation()}
                          </Badge>
                        )}
                        {relatedJob.studyLevel && (
                          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                            <GraduationCap className="w-3 h-3 mr-1 inline" />
                            {getLabel(relatedJob.studyLevel)}
                          </Badge>
                        )}
                        {relatedJob.xpLevel && (
                          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                            <Briefcase className="w-3 h-3 mr-1 inline" />
                            {getLabel(relatedJob.xpLevel)}
                          </Badge>
                        )}
                        {getOccupationTimeLabel() && (
                          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                            <Clock className="w-3 h-3 mr-1 inline" />
                            {getOccupationTimeLabel()}
                          </Badge>
                        )}
                        {relatedJob.remote !== null && relatedJob.remote !== undefined && (
                          <Badge variant="outline" className="bg-gray-50 text-gray-700 border-gray-300 text-xs">
                            {relatedJob.remote === 't' || relatedJob.remote === true ? (
                              <><Wifi className="w-3 h-3 mr-1 inline" />Télétravail possible</>
                            ) : (
                              <><Home className="w-3 h-3 mr-1 inline" />Présentiel uniquement</>
                            )}
                          </Badge>
                        )}
                        {getSalaryDisplay() && (
                          <Badge className="bg-green-50 text-green-700 border-green-200 text-xs">
                            <Euro className="w-3 h-3 mr-1 inline" />
                            {getSalaryDisplay()}
                          </Badge>
                        )}
                      </div>
                      <p className="text-sm text-gray-700 mb-4 line-clamp-3 flex-1 leading-relaxed">
                        {getCleanDescription()}
                      </p>
                      <div className="flex items-center justify-between pt-4 border-t mt-auto">
                        {relatedJob.createdat && (
                          <div className="flex items-center gap-1.5 text-xs text-gray-600">
                            <Clock className="w-3.5 h-3.5" />
                            <span>{getTimeAgo(relatedJob.createdat)}</span>
                          </div>
                        )}
                        <Button
                          size="sm"
                          className={
                            isExpired
                              ? "bg-gray-400 cursor-not-allowed text-xs px-4"
                              : "bg-blue-500 hover:bg-blue-600 text-white text-xs px-4"
                          }
                          disabled={isExpired}
                        >
                          {isExpired ? "Expiré" : "Voir l'offre"}
                        </Button>
                      </div>
                    </div>
                  </Card>
                </Link>
              )
            })}
          </div>
        </div>
      )}

      <ShareModal
        isOpen={showShareModal}
        onClose={() => setShowShareModal(false)}
        title={job?.title || ""}
        url={`/announcements/jobs/${announcementId}`}
        description={job?.description}
      />

      {/* Dialog de confirmation de candidature */}
      <Dialog open={showApplicationDialog} onOpenChange={setShowApplicationDialog}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Postuler à cette offre ?</DialogTitle>
            <DialogDescription>
              Confirmez votre candidature pour cette offre d'emploi. Nous enverrons votre candidature à l'employeur.
            </DialogDescription>
          </DialogHeader>

          <DialogFooter className="flex-col sm:flex-row gap-2">
            <Button
              variant="outline"
              onClick={() => setShowApplicationDialog(false)}
              disabled={isApplying}
              className="w-full sm:w-auto"
            >
              Annuler
            </Button>
            <Button
              onClick={handleConfirmApplication}
              disabled={isApplying}
              className="w-full sm:w-auto bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 text-white"
            >
              {isApplying ? (
                <>
                  <span className="animate-spin mr-2">⏳</span>
                  Candidature en cours...
                </>
              ) : (
                <>
                  <ExternalLink className="w-4 h-4 mr-2" />
                  Confirmer la candidature
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Dialog de résultat de candidature */}
      <Dialog open={applicationResult !== null} onOpenChange={() => setApplicationResult(null)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className={applicationResult?.success ? "text-green-600" : "text-red-600"}>
              {applicationResult?.success ? "✅ Candidature envoyée !" : "❌ Erreur de candidature"}
            </DialogTitle>
            <DialogDescription>
              {applicationResult?.message}
            </DialogDescription>
          </DialogHeader>
          
          {applicationResult?.success && (
            <div className="py-4 text-center bg-green-50 rounded-lg border border-green-200">
              <div className="text-6xl mb-3">🎉</div>
              <p className="text-sm text-green-800 font-medium">
                Votre candidature a été envoyée avec succès !
              </p>
              <p className="text-xs text-green-600 mt-2">
                L'employeur vous contactera prochainement.
              </p>
            </div>
          )}

          {!applicationResult?.success && (
            <div className="py-4 text-center bg-red-50 rounded-lg border border-red-200">
              <div className="text-6xl mb-3">😞</div>
              <p className="text-sm text-red-800 font-medium">
                Une erreur s'est produite lors de la candidature.
              </p>
              <p className="text-xs text-red-600 mt-2">
                Veuillez réessayer plus tard ou contacter le support.
              </p>
            </div>
          )}

          <DialogFooter>
            <Button
              onClick={() => setApplicationResult(null)}
              className={applicationResult?.success 
                ? "w-full bg-green-600 hover:bg-green-700 text-white" 
                : "w-full bg-red-600 hover:bg-red-700 text-white"
              }
            >
              {applicationResult?.success ? "Parfait !" : "Fermer"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
