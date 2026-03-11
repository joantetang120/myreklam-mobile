import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function sanitizeHtml(html: string): string {
  if (!html) return ""

  // Create a temporary div to parse HTML
  const temp = document.createElement("div")
  temp.innerHTML = html

  // Remove script tags and event handlers
  const scripts = temp.querySelectorAll("script")
  scripts.forEach((script) => script.remove())

  // Remove event handler attributes
  const allElements = temp.querySelectorAll("*")
  allElements.forEach((element) => {
    Array.from(element.attributes).forEach((attr) => {
      if (attr.name.startsWith("on")) {
        element.removeAttribute(attr.name)
      }
    })
  })

  return temp.innerHTML
}

export function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return "Date non disponible"

  try {
    const date = new Date(dateString)

    // Check if date is valid
    if (isNaN(date.getTime())) {
      return "Date invalide"
    }

    return date.toLocaleDateString("fr-FR", {
      day: "2-digit",
      month: "long",
      year: "numeric",
    })
  } catch (error) {
    return "Date invalide"
  }
}

export function formatDateTime(dateString: string | null | undefined): string {
  if (!dateString) return "Date non disponible"

  try {
    const date = new Date(dateString)

    // Check if date is valid
    if (isNaN(date.getTime())) {
      return "Date invalide"
    }

    return date.toLocaleDateString("fr-FR", {
      day: "2-digit",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })
  } catch (error) {
    return "Date invalide"
  }
}

export function formatRelativeDate(dateString: string | null | undefined): string {
  if (!dateString) return "Date non disponible"

  try {
    const date = new Date(dateString)

    // Check if date is valid
    if (isNaN(date.getTime())) {
      return "Date invalide"
    }

    const now = new Date()
    const diffInMs = now.getTime() - date.getTime()
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))

    if (diffInDays === 0) {
      const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
      if (diffInHours === 0) {
        const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
        return diffInMinutes <= 1 ? "À l'instant" : `Il y a ${diffInMinutes} minutes`
      }
      return diffInHours === 1 ? "Il y a 1 heure" : `Il y a ${diffInHours} heures`
    } else if (diffInDays === 1) {
      return "Hier"
    } else if (diffInDays < 7) {
      return `Il y a ${diffInDays} jours`
    } else if (diffInDays < 30) {
      const weeks = Math.floor(diffInDays / 7)
      return weeks === 1 ? "Il y a 1 semaine" : `Il y a ${weeks} semaines`
    } else if (diffInDays < 365) {
      const months = Math.floor(diffInDays / 30)
      return months === 1 ? "Il y a 1 mois" : `Il y a ${months} mois`
    } else {
      const years = Math.floor(diffInDays / 365)
      return years === 1 ? "Il y a 1 an" : `Il y a ${years} ans`
    }
  } catch (error) {
    return "Date invalide"
  }
}

export function formatDateRelative(dateString: string | null | undefined): string {
  return formatRelativeDate(dateString)
}
