"use client"

import { useState, useEffect } from "react"
import { FileText, Plus, X } from "lucide-react"
import { toast } from "sonner"
import ReactSwitch from "react-switch"
import { useUserData } from "@/hooks/use-user-data"
import { config } from "@/lib/config"
import {
  getUserDocumentFiles,
  createDocumentFile,
  updateDocumentFile,
  deleteDocumentFile,
  uploadFile,
  type DocumentFile,
} from "@/lib/api"
import { MediaUploadModal } from "./media-upload-modal"

type DocumentCollection = {
  cv: DocumentFile[]
  motivationLetter: DocumentFile[]
  portfolio: DocumentFile[]
}

export function DocumentsSection() {
  const { companyData, loading } = useUserData()
  const userId = companyData?.userid || companyData?.localUserId || (typeof window !== "undefined" ? localStorage.getItem("profileId") : "") || ""
  
  console.log("[DocumentsSection] companyData:", companyData)
  console.log("[DocumentsSection] userId:", userId)

  const [documents, setDocuments] = useState<DocumentCollection>({
    cv: [],
    motivationLetter: [],
    portfolio: [],
  })

  const [showAll, setShowAll] = useState(true)
  const [uploadModalOpen, setUploadModalOpen] = useState(false)
  const [currentSection, setCurrentSection] = useState<keyof DocumentCollection>("cv")
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    if (userId) {
      loadDocuments()
    }
  }, [userId])

  const loadDocuments = async () => {
    setIsLoading(true)
    try {
      console.log("[DocumentsSection] Loading documents for userId:", userId)
      const allDocuments = await getUserDocumentFiles(userId)
      console.log("[DocumentsSection] Loaded documents:", allDocuments)

      const organizedDocs: DocumentCollection = {
        cv: [],
        motivationLetter: [],
        portfolio: [],
      }

      allDocuments.forEach((doc) => {
        if (doc.category === "cv") organizedDocs.cv.push(doc)
        else if (doc.category === "motivation_letter") organizedDocs.motivationLetter.push(doc)
        else if (doc.category === "portfolio") organizedDocs.portfolio.push(doc)
      })

      console.log("[DocumentsSection] Organized documents:", organizedDocs)
      setDocuments(organizedDocs)

      const allShown = allDocuments.every((doc) => doc.show_public)
      setShowAll(allShown)
    } catch (error) {
      console.error("[DocumentsSection] Erreur lors du chargement des documents:", error)
      toast.error("Erreur lors du chargement des documents")
    } finally {
      setIsLoading(false)
    }
  }

  const addDocument = (section: keyof DocumentCollection) => {
    setCurrentSection(section)
    setUploadModalOpen(true)
  }

  const handleSaveDocument = async (file: File | null, link?: string) => {
    try {
      console.log("[DocumentsSection] Saving document - userId:", userId, "section:", currentSection)
      
      let apiCategory: string = currentSection
      if (currentSection === "motivationLetter") {
        apiCategory = "motivation_letter"
      }

      console.log("[DocumentsSection] API Category:", apiCategory)

      if (file) {
        console.log("[DocumentsSection] Uploading file:", file.name)
        const uploadResult = await uploadFile(file)
        console.log("[DocumentsSection] Upload result:", uploadResult)

        if (uploadResult && uploadResult.success) {
          const docData = {
            user_id: userId,
            name: uploadResult.original_name,
            category: apiCategory as any,
            url: uploadResult.url,
            show_public: showAll,
          }
          console.log("[DocumentsSection] Creating document with data:", docData)
          
          const createResult = await createDocumentFile(docData)
          console.log("[DocumentsSection] Create result:", createResult)
        } else {
          toast.error("Erreur lors de l'upload du fichier")
          return
        }
      } else if (link) {
        if (!link.startsWith("http://") && !link.startsWith("https://")) {
          toast.error("URL invalide, doit commencer par http:// ou https://")
          return
        }

        let fileName
        try {
          const url = new URL(link)
          fileName = url.pathname.split("/").pop() || ""
          if (!fileName || fileName.length < 3) {
            fileName = `Lien externe - ${new Date().toLocaleDateString()}`
          }
        } catch (e) {
          toast.error("URL malformée")
          return
        }

        const docData = {
          user_id: userId,
          name: fileName,
          category: apiCategory as any,
          url: link,
          show_public: showAll,
          is_external_link: true,
        }
        console.log("[DocumentsSection] Creating external link document:", docData)
        
        await createDocumentFile(docData)
      }

      await loadDocuments()
      setUploadModalOpen(false)
      toast.success("Document ajouté avec succès")
    } catch (error) {
      console.error("[DocumentsSection] Erreur lors de la sauvegarde du document:", error)
      toast.error("Erreur lors de la sauvegarde du document")
    }
  }

  const removeDocument = async (section: keyof DocumentCollection, index: number) => {
    const documentToDelete = documents[section][index]

    try {
      await deleteDocumentFile(documentToDelete.id, userId)

      const updatedDocuments = { ...documents }
      updatedDocuments[section].splice(index, 1)
      setDocuments(updatedDocuments)
      toast.success("Document supprimé avec succès")
    } catch (error) {
      console.error("Erreur lors de la suppression du document:", error)
      toast.error("Erreur lors de la suppression du document")
    }
  }

  const toggleDocumentVisibility = async (section: keyof DocumentCollection, index: number) => {
    const documentToUpdate = documents[section][index]
    const newVisibility = !documentToUpdate.show_public

    try {
      await updateDocumentFile({
        ...documentToUpdate,
        show_public: newVisibility,
      })

      const updatedDocuments = { ...documents }
      updatedDocuments[section][index].show_public = newVisibility
      setDocuments(updatedDocuments)

      let allVisible = true
      Object.keys(updatedDocuments).forEach((section) => {
        const sectionKey = section as keyof DocumentCollection
        updatedDocuments[sectionKey].forEach((doc) => {
          if (!doc.show_public) allVisible = false
        })
      })

      setShowAll(allVisible)
    } catch (error) {
      console.error("Erreur lors de la mise à jour de la visibilité:", error)
      toast.error("Erreur lors de la mise à jour")
    }
  }

  const toggleAllVisibility = async () => {
    const newVisibility = !showAll
    setShowAll(newVisibility)

    try {
      const updatedDocuments = { ...documents }

      for (const section of Object.keys(documents) as Array<keyof DocumentCollection>) {
        for (const doc of documents[section]) {
          await updateDocumentFile({
            ...doc,
            show_public: newVisibility,
          })

          const docIndex = updatedDocuments[section].findIndex((d) => d.id === doc.id)
          if (docIndex !== -1) {
            updatedDocuments[section][docIndex].show_public = newVisibility
          }
        }
      }

      setDocuments(updatedDocuments)
      toast.success("Visibilité mise à jour")
    } catch (error) {
      console.error("Erreur lors de la mise à jour de toutes les visibilités:", error)
      toast.error("Erreur lors de la mise à jour")
    }
  }

  const getFileType = (fileName: string, isExternalLink?: boolean) => {
    if (isExternalLink) return "link"

    const extension = fileName.split(".").pop()?.toLowerCase()
    if (extension === "pdf") return "pdf"
    if (["doc", "docx"].includes(extension || "")) return "word"
    return "other"
  }

  const handleViewDocument = (file: any) => {
    if (file.is_external_link) {
      window.open(file.url, "_blank")
    } else {
      window.open(`${config.API_URL}${file.url}`, "_blank")
    }
  }

  const openPreview = (file: any) => {
    handleViewDocument(file)
  }

  const renderDocumentSection = (
    title: string,
    section: keyof DocumentCollection,
    textAddDocument = "Ajouter un document",
  ) => {
    return (
      <div className="text-sm flex flex-col gap-4 mt-6">
        <h3 className="text-base sm:text-lg font-semibold mb-2">{title} :</h3>
        {documents[section].map((doc, index) => (
          <div key={index} className="flex flex-col sm:flex-row items-start sm:items-center gap-2 sm:gap-0 mb-3 p-3 sm:p-0 bg-gray-50 sm:bg-transparent rounded-lg sm:rounded-none">
            <div className="flex-1 flex items-center w-full sm:w-auto min-w-0">
              <FileText
                strokeWidth={2}
                size={28}
                className={`flex-shrink-0 ${
                  doc.is_external_link
                    ? "bg-purple-700"
                    : getFileType(doc.name) === "pdf"
                      ? "bg-red-700"
                      : "bg-blue-700"
                } text-white rounded-full p-2 mr-2`}
              />
              <div className="flex-1 min-w-0">
                <i className="font-semibold cursor-pointer hover:underline text-xs sm:text-sm truncate block" onClick={() => openPreview(doc)}>
                  {doc.name.length > 25 ? doc.name.substring(0, 25) + "..." : doc.name}
                </i>
                <span className="text-xs text-gray-500">
                  {new Date(doc.created_at || Date.now()).toLocaleDateString('fr-FR')}
                </span>
              </div>
              <button onClick={() => removeDocument(section, index)} className="ml-2 text-gray-500 hover:text-gray-700 flex-shrink-0">
                <X size={18} />
              </button>
            </div>
            <div className="ml-auto sm:ml-4 flex items-center gap-2 flex-shrink-0">
              <span className={`text-xs font-medium ${doc.show_public ? 'text-green-600' : 'text-gray-500'}`}>
                {doc.show_public ? 'Public' : 'Privé'}
              </span>
              <ReactSwitch
                checked={doc.show_public}
                onChange={() => toggleDocumentVisibility(section, index)}
                offColor="#D1D5DB"
                onColor="#4CAF50"
                checkedIcon={false}
                uncheckedIcon={false}
                height={22}
                width={45}
              />
            </div>
          </div>
        ))}
        <button onClick={() => addDocument(section)} className="flex items-center text-sm sm:text-base hover:text-emerald-700 transition-colors">
          <span className="text-white bg-emerald-600 p-1 rounded-full mr-2">
            <Plus size={20} />
          </span>
          <span>{textAddDocument}</span>
        </button>
      </div>
    )
  }

  if (loading || isLoading) {
    return (
      <div className="w-full bg-white p-4 sm:p-6 rounded-lg">
        <div className="animate-pulse">Chargement des documents...</div>
      </div>
    )
  }

  return (
    <div className="w-full bg-white p-4 sm:p-6 rounded-lg">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-0 mb-6">
        <h2 className="text-lg sm:text-xl font-bold">Tout afficher sur le profil</h2>
        <ReactSwitch
          checked={showAll}
          onChange={toggleAllVisibility}
          offColor="#D1D5DB"
          onColor="#4CAF50"
          checkedIcon={false}
          uncheckedIcon={false}
          height={22}
          width={45}
        />
      </div>

      {renderDocumentSection("CV", "cv")}
      {renderDocumentSection("Lettre de motivation", "motivationLetter")}
      {renderDocumentSection("Portfolio / Site web", "portfolio", "Ajouter un document / lien")}

      <MediaUploadModal
        title={`Ajouter un document - ${
          currentSection === "cv"
            ? "CV"
            : currentSection === "motivationLetter"
              ? "Lettre de motivation"
              : "Portfolio / Site web"
        }`}
        isOpen={uploadModalOpen}
        onClose={() => setUploadModalOpen(false)}
        onSave={handleSaveDocument}
        imageAccept=".pdf,.doc,.docx"
        allowLinks={["portfolio"].includes(currentSection)}
      />
    </div>
  )
}
