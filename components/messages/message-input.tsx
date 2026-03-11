"use client"

import type React from "react"

import { useState, useRef } from "react"
import { Send, Smile, Camera, Paperclip, X, Loader2 } from "lucide-react"
import dynamic from "next/dynamic"
import type { EmojiClickData } from "emoji-picker-react"
import { sendMessage } from "@/lib/api/messages"
import type { Attachments } from "@/lib/stores/message-store"
import Image from "next/image"
import CameraModal from "./camera-modal"

const EmojiPicker = dynamic(() => import("emoji-picker-react"), { ssr: false })

interface MessageInputProps {
  conversationId: string
  interlocutorId: string
  announcementStatus: string
  onMessageSent: () => void
}

const MessageInput: React.FC<MessageInputProps> = ({
  announcementStatus,
  conversationId,
  interlocutorId,
  onMessageSent,
}) => {
  const [message, setMessage] = useState("")
  const [attachments, setAttachments] = useState<Attachments[]>([])
  const [showEmojiPicker, setShowEmojiPicker] = useState(false)
  const [showCameraOptions, setShowCameraOptions] = useState(false)
  const [isCameraActive, setIsCameraActive] = useState(false)
  const [isSending, setIsSending] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const allowedFileTypes = [
    "image/jpeg",
    "image/png",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  ]

  const handleSendMessage = async () => {
    if (!message.trim() && attachments.length === 0) return

    setIsSending(true)
    try {
      const response = await sendMessage(conversationId, interlocutorId, message, attachments)
      if (response.success) {
        setMessage("")
        setAttachments([])
        onMessageSent()
      }
    } catch (error) {
      console.error("Erreur lors de l'envoi :", error)
    } finally {
      setIsSending(false)
    }
  }

  const handleEmojiClick = (emojiObject: EmojiClickData) => {
    setMessage((prev) => prev + emojiObject.emoji)
    setShowEmojiPicker(false)
  }

  const fileToBase64 = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.readAsDataURL(file)
      reader.onload = () => resolve(reader.result as string)
      reader.onerror = (error) => reject(error)
    })
  }

  const handleFileUpload = async (file: File) => {
    if (!allowedFileTypes.includes(file.type)) {
      alert("Type de fichier non autorisé")
      return
    }

    if (file.size > 10 * 1024 * 1024) {
      alert("Fichier trop volumineux (max 10 Mo)")
      return
    }

    try {
      const base64 = await fileToBase64(file)
      const file_type = file.type
      setAttachments((prev) => [...prev, { file_url: base64, file_type, file_name: file.name }])
    } catch (error) {
      console.error("Erreur lors de l'upload :", error)
    }
  }

  const handleFileInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      handleFileUpload(file)
    }
  }

  const handleCapturePhoto = (photoUrl: string) => {
    fetch(photoUrl)
      .then((res) => res.blob())
      .then((blob) => {
        const file_name = `photo_${Date.now()}.jpg`
        setAttachments((prev) => [...prev, { file_url: photoUrl, file_type: blob.type, file_name }])
      })
  }

  const limiterTexte = (texte: string, limite = 20): string => {
    if (texte.length > limite) {
      return texte.substring(0, limite) + "..."
    }
    return texte
  }

  if (announcementStatus !== "valid") {
    return (
      <div className="px-6 py-4 border-t border-border bg-muted/30">
        <div className="flex items-center justify-center gap-2 text-muted-foreground">
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <span className="text-sm">Cette annonce n'est plus disponible</span>
        </div>
      </div>
    )
  }

  return (
    <div className="border-t border-border bg-muted/30">
      {/* Attachments preview */}
      {attachments.length > 0 && (
        <div className="flex gap-3 p-4 overflow-x-auto">
          {attachments.map((attachment, index) => (
            <div key={index} className="relative group flex-shrink-0">
              <button
                className="absolute -top-2 -right-2 p-1 bg-destructive text-destructive-foreground rounded-full opacity-0 group-hover:opacity-100 transition-opacity z-10"
                onClick={() => setAttachments((prev) => prev.filter((_, i) => i !== index))}
              >
                <X className="w-3 h-3" />
              </button>
              {attachment.file_type.startsWith("image") ? (
                <Image
                  alt="Preview"
                  className="w-20 h-20 object-cover rounded-xl border border-border"
                  src={attachment.file_url || "/placeholder.svg"}
                  width={80}
                  height={80}
                />
              ) : (
                <div className="w-20 h-20 flex flex-col items-center justify-center bg-muted rounded-xl border border-border">
                  <p className="text-xs font-semibold uppercase">
                    {limiterTexte(attachment.file_type?.split("/")[1] || "File", 5)}
                  </p>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Input area */}
      <div className="flex items-end gap-3 p-4">
        {/* Attachment options */}
        <div className="relative">
          <button
            className="p-2 hover:bg-muted rounded-full transition-colors"
            onClick={() => setShowCameraOptions(!showCameraOptions)}
          >
            <Camera className="w-5 h-5 text-muted-foreground" />
          </button>

          {showCameraOptions && (
            <div className="absolute bottom-12 left-0 bg-card border border-border rounded-xl shadow-xl overflow-hidden z-20 min-w-[180px] animate-in fade-in slide-in-from-bottom-2 duration-200">
              <button
                className="w-full flex items-center gap-3 px-4 py-3 hover:bg-muted transition-colors text-left text-sm"
                onClick={() => {
                  fileInputRef.current?.click()
                  setShowCameraOptions(false)
                }}
              >
                <Paperclip className="w-4 h-4" />
                Charger un fichier
              </button>
              <button
                className="w-full flex items-center gap-3 px-4 py-3 hover:bg-muted transition-colors text-left text-sm"
                onClick={() => {
                  setIsCameraActive(true)
                  setShowCameraOptions(false)
                }}
              >
                <Camera className="w-4 h-4" />
                Prendre une photo
              </button>
            </div>
          )}

          <input
            type="file"
            accept=".jpg,.jpeg,.png,.pdf,.doc,.docx"
            ref={fileInputRef}
            className="hidden"
            onChange={handleFileInputChange}
          />
        </div>

        {/* Message input */}
        <div className="flex-1 relative">
          <textarea
            placeholder="Écrire un message..."
            className="w-full bg-muted/50 rounded-2xl px-4 py-3 pr-12 text-sm resize-none outline-none focus:ring-2 focus:ring-primary/50 transition-all"
            rows={1}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault()
                handleSendMessage()
              }
            }}
          />

          {/* Emoji picker button */}
          <div className="absolute right-3 top-3">
            <button
              className="p-1 hover:bg-muted rounded-full transition-colors"
              onClick={() => setShowEmojiPicker(!showEmojiPicker)}
            >
              <Smile className="w-5 h-5 text-muted-foreground" />
            </button>

            {showEmojiPicker && (
              <div className="absolute bottom-12 right-0 z-20 animate-in fade-in slide-in-from-bottom-2 duration-200">
                <EmojiPicker onEmojiClick={handleEmojiClick} previewConfig={{ showPreview: false }} />
              </div>
            )}
          </div>
        </div>

        {/* Send button */}
        <button
          onClick={handleSendMessage}
          disabled={isSending || (!message.trim() && attachments.length === 0)}
          className="p-3 bg-primary text-primary-foreground rounded-full hover:bg-primary/90 transition-all disabled:opacity-50 disabled:cursor-not-allowed hover:scale-105 active:scale-95"
        >
          {isSending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
        </button>
      </div>

      <CameraModal isOpen={isCameraActive} onClose={() => setIsCameraActive(false)} onCapture={handleCapturePhoto} />
    </div>
  )
}

export default MessageInput
