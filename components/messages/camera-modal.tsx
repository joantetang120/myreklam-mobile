"use client"

import type React from "react"

import { useEffect, useRef } from "react"
import { Camera, X } from "lucide-react"

interface CameraModalProps {
  isOpen: boolean
  onClose: () => void
  onCapture: (photoUrl: string) => void
}

const CameraModal: React.FC<CameraModalProps> = ({ isOpen, onClose, onCapture }) => {
  const videoRef = useRef<HTMLVideoElement>(null)

  useEffect(() => {
    if (isOpen) {
      startCamera()
    } else {
      stopCamera()
    }
  }, [isOpen])

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true })
      if (videoRef.current) {
        videoRef.current.srcObject = stream
      }
    } catch (error) {
      console.error("Erreur d'accès à la caméra :", error)
    }
  }

  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const stream = videoRef.current.srcObject as MediaStream
      stream.getTracks().forEach((track) => track.stop())
    }
  }

  const capturePhoto = () => {
    if (videoRef.current) {
      const canvas = document.createElement("canvas")
      canvas.width = videoRef.current.videoWidth
      canvas.height = videoRef.current.videoHeight
      const context = canvas.getContext("2d")
      if (context) {
        context.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height)
        const photoUrl = canvas.toDataURL("image/png")
        onCapture(photoUrl)
        onClose()
      }
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-background/95 backdrop-blur-sm flex items-center justify-center z-50 animate-in fade-in duration-300">
      <div className="bg-card border border-border rounded-3xl p-6 w-full max-w-2xl mx-4 shadow-2xl animate-in zoom-in duration-300">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold">Prendre une photo</h3>
          <button onClick={onClose} className="p-2 hover:bg-muted rounded-full transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>

        <video ref={videoRef} autoPlay className="w-full h-auto rounded-2xl bg-black" />

        <div className="flex justify-center gap-4 mt-6">
          <button
            className="flex items-center gap-2 px-6 py-3 bg-primary text-primary-foreground rounded-full hover:bg-primary/90 transition-all hover:scale-105"
            onClick={capturePhoto}
          >
            <Camera className="w-5 h-5" />
            Capturer
          </button>
          <button className="px-6 py-3 bg-muted hover:bg-muted/80 rounded-full transition-colors" onClick={onClose}>
            Annuler
          </button>
        </div>
      </div>
    </div>
  )
}

export default CameraModal
