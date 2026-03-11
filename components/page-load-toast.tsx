'use client'

import { useEffect, useRef } from 'react'
import { toastSuccess } from '@/lib/utils/toast'

export function PageLoadToast() {
  const hasShownToast = useRef(false)

  useEffect(() => {
    if (typeof window === 'undefined') return

    // Fonction pour afficher le toast
    const showToast = () => {
      if (!hasShownToast.current) {
        hasShownToast.current = true
        console.log('[PageLoadToast] Page chargée avec succès - Affichage du toast')
        // toastSuccess('La page a bien été chargée')
      }
    }

    // Vérifier le type de navigation
    const navigationEntry = window.performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming | undefined
    const navigationType = navigationEntry?.type || 'navigate'
    
    console.log('[PageLoadToast] Type de navigation:', navigationType)
    console.log('[PageLoadToast] État du document:', document.readyState)
    console.log('[PageLoadToast] Performance navigation type:', (window.performance.navigation as any)?.type)

    // Si la page est déjà complètement chargée
    if (document.readyState === 'complete') {
      // Petit délai pour s'assurer que tout est bien initialisé
      setTimeout(showToast, 100)
    } else {
      // Attendre le chargement complet de la page
      window.addEventListener('load', () => {
        setTimeout(showToast, 100)
      }, { once: true })
    }

    // Nettoyage
    return () => {
      window.removeEventListener('load', showToast)
    }
  }, [])

  return null
}

