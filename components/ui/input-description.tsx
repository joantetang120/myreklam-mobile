"use client"

import type React from "react"

import { motion } from "framer-motion"
import { RichTextEditor } from "./rich-text-editor"

interface InputDescriptionProps {
  value: string
  onChange: (value: string) => void
  label: string
  required?: boolean
  placeholder?: string
}

export function InputDescription({ value, onChange, label, required, placeholder }: InputDescriptionProps) {
  return (
    <motion.div
      className="mb-6"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
    >
      <label htmlFor="description-input" className="block text-sm font-semibold text-gray-700 mb-2">
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>

      <RichTextEditor
        value={value}
        onChange={onChange}
        placeholder={placeholder || "Décrivez votre offre en détail..."}
      />
    </motion.div>
  )
}
