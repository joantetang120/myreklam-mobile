"use client"

/**
 * Système de sécurité pour protéger contre les injections XSS
 * Détecte et bloque les scripts malveillants dans les entrées utilisateur
 */

// Patterns dangereux à détecter
const DANGEROUS_PATTERNS = [
  // Scripts JavaScript
  /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
  /javascript:/gi,
  /on\w+\s*=/gi, // onclick, onload, onerror, etc.

  // Balises HTML dangereuses
  /<iframe/gi,
  /<object/gi,
  /<embed/gi,
  /<applet/gi,
  /<meta/gi,
  /<link/gi,
  /<style/gi,

  // Encodages dangereux
  /&#/gi, // HTML entities
  /\\x/gi, // Hex encoding
  /\\u/gi, // Unicode encoding

  // Data URIs
  /data:text\/html/gi,
  /data:application/gi,

  // Expressions eval
  /eval\s*\(/gi,
  /expression\s*\(/gi,

  // Import/require
  /import\s+/gi,
  /require\s*\(/gi,

  // SQL injection patterns
  /(\bor\b|\band\b)\s+\d+\s*=\s*\d+/gi,
  /union\s+select/gi,
  /drop\s+table/gi,
  /insert\s+into/gi,
  /delete\s+from/gi,
  /update\s+\w+\s+set/gi,
]

/**
 * Vérifie si une chaîne contient des patterns dangereux
 */
export function containsDangerousContent(value: string): boolean {
  if (!value || typeof value !== "string") return false

  return DANGEROUS_PATTERNS.some((pattern) => pattern.test(value))
}

/**
 * Nettoie une chaîne en supprimant les caractères dangereux
 */
export function sanitizeInput(value: string): string {
  if (!value || typeof value !== "string") return value

  let sanitized = value

  // Supprimer les balises script
  sanitized = sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "")

  // Supprimer les attributs d'événements
  sanitized = sanitized.replace(/on\w+\s*=\s*["'][^"']*["']/gi, "")
  sanitized = sanitized.replace(/on\w+\s*=\s*[^\s>]*/gi, "")

  // Supprimer javascript: dans les URLs
  sanitized = sanitized.replace(/javascript:/gi, "")

  // Supprimer les balises dangereuses
  sanitized = sanitized.replace(/<(iframe|object|embed|applet|meta|link|style)[^>]*>/gi, "")

  // Encoder les caractères spéciaux HTML
  sanitized = sanitized.replace(/</g, "&lt;").replace(/>/g, "&gt;")

  return sanitized
}

/**
 * Valide une entrée utilisateur et retourne un message d'erreur si invalide
 */
export function validateInput(value: string): { isValid: boolean; error?: string } {
  if (!value || typeof value !== "string") {
    return { isValid: true }
  }

  if (containsDangerousContent(value)) {
    return {
      isValid: false,
      error: "Contenu non autorisé détecté. Veuillez ne pas inclure de code ou de scripts.",
    }
  }

  return { isValid: true }
}

/**
 * Hook React pour valider les entrées en temps réel
 */
export function useSanitizedInput(initialValue = "") {
  const [value, setValue] = React.useState(initialValue)
  const [error, setError] = React.useState<string | undefined>()

  const handleChange = (newValue: string) => {
    const validation = validateInput(newValue)

    if (!validation.isValid) {
      setError(validation.error)
      return false
    }

    setError(undefined)
    setValue(newValue)
    return true
  }

  return {
    value,
    error,
    handleChange,
    isValid: !error,
  }
}

import React from "react"
