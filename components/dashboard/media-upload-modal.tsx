"use client"

import type React from "react"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Upload, LinkIcon } from "lucide-react"
import Image from "next/image"

interface MediaUploadModalProps {
  title: string
  imageAccept: string
  isOpen: boolean
  onClose: () => void
  onSave: (file: File | null, link?: string) => Promise<void>
  allowLinks?: boolean
}

export function MediaUploadModal({
  title,
  imageAccept,
  isOpen,
  onClose,
  onSave,
  allowLinks = false,
}: MediaUploadModalProps) {
  const [file, setFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<string | null>(null)
  const [isSaving, setIsSaving] = useState(false)
  const [link, setLink] = useState<string>("")
  const [uploadMode, setUploadMode] = useState<"file" | "link">("file")

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0]
    if (selectedFile) {
      setFile(selectedFile)
      if (selectedFile.type.startsWith("image/")) {
        setPreview(URL.createObjectURL(selectedFile))
      } else {
        setPreview(null)
      }
    }
  }

  const handleSave = async () => {
    if (uploadMode === "file" && !file) return
    if (uploadMode === "link" && !link) return

    setIsSaving(true)
    try {
      if (uploadMode === "file") {
        await onSave(file, undefined)
      } else {
        await onSave(null, link)
      }
      setFile(null)
      setPreview(null)
      setLink("")
      onClose()
    } catch (error) {
      console.error("Error saving media:", error)
    } finally {
      setIsSaving(false)
    }
  }

  const handleClose = () => {
    setFile(null)
    setPreview(null)
    setLink("")
    onClose()
  }

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          {allowLinks && (
            <div className="flex gap-2 mb-4">
              <Button
                type="button"
                variant={uploadMode === "file" ? "default" : "outline"}
                onClick={() => setUploadMode("file")}
                className="flex-1"
              >
                <Upload className="h-4 w-4 mr-2" />
                Fichier
              </Button>
              <Button
                type="button"
                variant={uploadMode === "link" ? "default" : "outline"}
                onClick={() => setUploadMode("link")}
                className="flex-1"
              >
                <LinkIcon className="h-4 w-4 mr-2" />
                Lien
              </Button>
            </div>
          )}

          {uploadMode === "file" ? (
            <>
              {preview && (
                <div className="flex justify-center">
                  <Image
                    src={preview || "/placeholder.svg"}
                    alt="Prévisualisation"
                    width={200}
                    height={200}
                    className="rounded-lg object-cover"
                  />
                </div>
              )}
              <div className="flex items-center gap-2">
                <Input type="file" accept={imageAccept} onChange={handleFileChange} />
                <Upload className="h-5 w-5 text-gray-400" />
              </div>
            </>
          ) : (
            <div className="space-y-2">
              <label className="text-sm font-medium">URL du lien</label>
              <Input
                type="url"
                placeholder="https://example.com/mon-portfolio"
                value={link}
                onChange={(e) => setLink(e.target.value)}
              />
              <p className="text-xs text-gray-500">Entrez l'URL complète de votre portfolio ou site web</p>
            </div>
          )}

          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={handleClose}>
              Annuler
            </Button>
            <Button
              onClick={handleSave}
              disabled={(uploadMode === "file" && !file) || (uploadMode === "link" && !link) || isSaving}
            >
              {isSaving ? "Enregistrement..." : "Enregistrer"}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
