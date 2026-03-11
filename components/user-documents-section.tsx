"use client"

import { useEffect, useState } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { getUserDocuments } from "@/lib/api"
import { config } from "@/lib/config"
import { FileText, Download, Calendar, Lock } from "lucide-react"

interface UserDocumentsSectionProps {
  userId: string
  isOwner?: boolean
}

export function UserDocumentsSection({ userId, isOwner = false }: UserDocumentsSectionProps) {
  const [documents, setDocuments] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchDocuments = async () => {
      setLoading(true)
      console.log("📄 Récupération des documents pour userId:", userId, "- Est propriétaire:", isOwner)
      const result = await getUserDocuments(userId)
      console.log("📄 Résultat getUserDocuments:", result)
      console.log("📄 Documents récupérés:", result.documents)
      if (result.success) {
        if (isOwner) {
          // Si c'est le propriétaire, afficher tous les documents
          console.log("✅ Tous les documents (propriétaire):", result.documents.length)
          setDocuments(result.documents)
        } else {
          // Sinon, filtrer uniquement les documents publics
          const publicDocuments = result.documents.filter((doc: any) => doc.show_public === true)
          console.log("✅ Documents publics:", publicDocuments.length, "sur", result.documents.length)
          setDocuments(publicDocuments)
        }
      } else {
        console.log("❌ Échec du chargement des documents")
      }
      setLoading(false)
    }

    if (userId) {
      fetchDocuments()
      
      // Rafraîchir les documents toutes les 5 secondes si c'est le propriétaire
      if (isOwner) {
        const interval = setInterval(() => {
          fetchDocuments()
        }, 5000)
        
        return () => clearInterval(interval)
      }
    }
  }, [userId, isOwner])

  // Regrouper les documents par catégorie
  const groupedDocuments = documents.reduce((acc: any, doc: any) => {
    const category = doc.category || "other"
    if (!acc[category]) {
      acc[category] = []
    }
    acc[category].push(doc)
    return acc
  }, {})

  const formatDate = (dateString: string) => {
    if (!dateString) return "Date non disponible"
    try {
      return new Date(dateString).toLocaleDateString("fr-FR", {
        day: "2-digit",
        month: "long",
        year: "numeric",
      })
    } catch {
      return "Date non disponible"
    }
  }

  const getDocumentTypeLabel = (type: string) => {
    const types: Record<string, string> = {
      cv: "CV",
      motivation_letter: "Lettre de motivation",
      diploma: "Diplôme",
      certificate: "Certificat",
      portfolio: "Portfolio",
      other: "Autre",
    }
    return types[type] || type
  }

  const handleDownload = (documentUrl: string, fileName: string) => {
    // Si l'URL commence par http, c'est un lien externe
    if (documentUrl.startsWith("http")) {
      window.open(documentUrl, "_blank")
      return
    }
    
    // Sinon, c'est un fichier sur le serveur
    const fullUrl = documentUrl.startsWith("/") 
      ? `${config.API_URL}${documentUrl}`
      : `${config.API_URL}/${documentUrl}`
    
    const link = document.createElement("a")
    link.href = fullUrl
    link.download = fileName
    link.target = "_blank"
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  if (loading) {
    return (
      <Card className="p-6">
        <div className="text-center py-8 text-gray-500">
          Chargement des documents...
        </div>
      </Card>
    )
  }

  if (documents.length === 0) {
    return (
      <Card className="p-6">
        <div className="text-center py-12">
          <Lock className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            Aucun document disponible
          </h3>
          <p className="text-gray-600">
            Cet utilisateur n'a pas encore ajouté de documents à son profil.
          </p>
        </div>
      </Card>
    )
  }

  return (
    <Card className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">
          Documents ({documents.length})
        </h2>
        <Badge variant="secondary" className="bg-teal-100 text-teal-700">
          Accès Premium
        </Badge>
      </div>

      <div className="space-y-6">
        {Object.entries(groupedDocuments).map(([category, docs]: [string, any]) => (
          <div key={category} className="space-y-3">
            <h3 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
              <FileText className="h-5 w-5 text-teal-600" />
              {getDocumentTypeLabel(category)}
              <Badge variant="secondary" className="ml-2">
                {docs.length}
              </Badge>
            </h3>
            
            <div className="space-y-3">
              {docs.map((doc: any, index: number) => (
                <div
                  key={doc.id || index}
                  className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border hover:border-teal-500 hover:shadow-md transition-all"
                >
                  <div className="flex items-center gap-4 flex-1">
                    <div className="w-10 h-10 bg-teal-100 rounded-lg flex items-center justify-center flex-shrink-0">
                      <FileText className="h-5 w-5 text-teal-600" />
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <h4 className="font-medium text-gray-900 truncate">
                          {doc.name || "Document"}
                        </h4>
                        {isOwner && (
                          <Badge 
                            variant={doc.show_public ? "default" : "secondary"}
                            className={doc.show_public ? "bg-green-100 text-green-700 text-xs" : "bg-gray-100 text-gray-700 text-xs"}
                          >
                            {doc.show_public ? "Public" : "Privé"}
                          </Badge>
                        )}
                      </div>
                      {doc.created_at && (
                        <span className="flex items-center gap-1 mt-1 text-xs text-gray-600">
                          <Calendar className="h-3 w-3" />
                          {formatDate(doc.created_at)}
                        </span>
                      )}
                    </div>
                  </div>

                  <Button
                    size="sm"
                    className="bg-teal-600 hover:bg-teal-700 text-white gap-2"
                    onClick={() => handleDownload(doc.url, doc.name)}
                  >
                    <Download className="h-4 w-4" />
                    {doc.url.startsWith("http") ? "Ouvrir" : "Télécharger"}
                  </Button>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <p className="text-sm text-blue-800">
          <strong>Note :</strong> Ces documents sont confidentiels et accessibles uniquement aux entreprises avec un abonnement actif.
        </p>
      </div>
    </Card>
  )
}
