"use client"

import { useState } from "react"
import { motion } from "framer-motion"
import { Check } from "lucide-react"
import Image from "next/image"

interface ScrappingImagesSelectorProps {
  images: string[]
  onImagesChange: (selectedImages: string[]) => void
}

export function ScrappingImagesSelector({ images, onImagesChange }: ScrappingImagesSelectorProps) {
  const [selectedImages, setSelectedImages] = useState<string[]>(images)

  const toggleImage = (image: string) => {
    const newSelection = selectedImages.includes(image)
      ? selectedImages.filter((img) => img !== image)
      : [...selectedImages, image]

    setSelectedImages(newSelection)
    onImagesChange(newSelection)
  }

  if (!images || images.length === 0) return null

  return (
    <div className="space-y-4">
      <h3 className="text-sm font-bold">Images récupérées automatiquement</h3>
      <p className="text-xs text-gray-600">Sélectionnez les images que vous souhaitez utiliser</p>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {images.map((image, index) => {
          const isSelected = selectedImages.includes(image)
          return (
            <motion.div
              key={index}
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: index * 0.05 }}
              className={`relative rounded-lg overflow-hidden border-2 cursor-pointer transition-all ${
                isSelected ? "border-green-500 ring-4 ring-green-100" : "border-gray-200 hover:border-green-300"
              }`}
              onClick={() => toggleImage(image)}
            >
              <Image
                src={image || "/placeholder.svg"}
                alt={`Scrapped image ${index + 1}`}
                width={200}
                height={150}
                className="w-full h-40 object-cover"
              />
              <div
                className={`absolute top-2 right-2 w-8 h-8 rounded-full flex items-center justify-center transition-all ${
                  isSelected ? "bg-green-500" : "bg-white/80"
                }`}
              >
                {isSelected ? (
                  <Check className="w-5 h-5 text-white" />
                ) : (
                  <div className="w-5 h-5 border-2 border-gray-400 rounded-full" />
                )}
              </div>
              {index === 0 && (
                <div className="absolute bottom-2 left-2 px-2 py-1 bg-red-500 text-white text-xs rounded font-semibold">
                  Photo de couverture
                </div>
              )}
            </motion.div>
          )
        })}
      </div>
    </div>
  )
}
