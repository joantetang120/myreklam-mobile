import axios from "axios"
import { config } from "@/lib/config"

export interface SavedSearch {
  id: string
  user_id: string
  name: string
  search_term?: string
  category?: string
  city?: string
  postal_code?: string
  distance?: number
  use_geolocation: boolean
  all_france: boolean
  user_position?: any
  created_at: string
}

export interface SaveSearchPayload {
  user_id: string
  name: string
  search_term?: string
  category?: string
  city?: string
  postal_code?: string
  distance?: number
  use_geolocation?: boolean
  all_france?: boolean
  user_position?: any
}

export const saveSearch = async (payload: SaveSearchPayload) => {
  try {
    console.log(" [SaveSearch] Payload reçu:", payload)
    
    const formData = new URLSearchParams()
    
    // Paramètres obligatoires selon le backend PHP
    formData.append('Method', 'saveSavedSearch')
    formData.append('userId', payload.user_id)
    formData.append('name', payload.name || '')
    
    // Paramètres optionnels
    if (payload.search_term) {
      formData.append('searchTerm', payload.search_term || '')
    }
    
    if (payload.category) {
      formData.append('category', payload.category || 'bons_plans')
    }
    
    if (payload.city) {
      formData.append('city', payload.city)
    }
    
    if (payload.postal_code) {
      formData.append('postalCode', payload.postal_code)
    }
    
    if (payload.distance !== undefined) {
      formData.append('distance', payload.distance.toString())
    }
    
    formData.append('useGeolocation', payload.use_geolocation ? 'true' : 'false')
    formData.append('allFrance', payload.all_france ? 'true' : 'false')
    
    if (payload.user_position) {
      formData.append('userPosition', JSON.stringify(payload.user_position))
    }

    console.log(" [SaveSearch] Données envoyées:", Object.fromEntries(formData))
    console.log(" [SaveSearch] URL:", `${config.API_URL}/SavedSearches.php`)

    const response = await axios.post(
      `${config.API_URL}/SavedSearches.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    console.log(" [SaveSearch] Réponse API:", response.data)

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Recherche sauvegardée avec succès",
        search: response.data.search,
      }
    }

    console.error(" [SaveSearch] Erreur API:", response.data)
    return {
      success: false,
      error: response.data.message || "Erreur lors de la sauvegarde de la recherche",
    }
  } catch (error: any) {
    console.error(" [SaveSearch] Exception:", error)
    console.error(" [SaveSearch] Response data:", error.response?.data)
    console.error(" [SaveSearch] Response status:", error.response?.status)
    
    return {
      success: false,
      error: error.response?.data?.message || error.message || "Erreur lors de la sauvegarde de la recherche",
    }
  }
}

export const getUserSavedSearches = async (userId: string): Promise<SavedSearch[]> => {
  try {
    const formData = new URLSearchParams()
    formData.append('Method', 'getSavedSearches')
    formData.append('userId', userId)

    const response = await axios.post(
      `${config.API_URL}/SavedSearches.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return response.data.searches || []
    }

    return []
  } catch (error) {
    console.error("Error fetching saved searches:", error)
    return []
  }
}

export const deleteSavedSearch = async (searchId: string, userId: string) => {
  try {
    const formData = new URLSearchParams()
    formData.append('Method', 'deleteSavedSearch')
    formData.append('id', searchId)
    formData.append('userId', userId)

    const response = await axios.post(
      `${config.API_URL}/SavedSearches.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Recherche supprimée avec succès",
      }
    }

    return {
      success: false,
      error: "Erreur lors de la suppression de la recherche",
    }
  } catch (error) {
    console.error("Error deleting saved search:", error)
    return {
      success: false,
      error: "Erreur lors de la suppression de la recherche",
    }
  }
}

export const toggleSearchNotification = async (searchId: string, userId: string, enabled: boolean) => {
  try {
    const formData = new URLSearchParams()
    formData.append('Method', 'toggleNotification')
    formData.append('id', searchId)
    formData.append('userId', userId)
    formData.append('notificationEnabled', enabled ? 'true' : 'false')

    const response = await axios.post(
      `${config.API_URL}/SavedSearches.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        message: enabled ? "Notifications activées" : "Notifications désactivées",
      }
    }

    return {
      success: false,
      error: "Erreur lors de la mise à jour des notifications",
    }
  } catch (error) {
    console.error("Error toggling search notification:", error)
    return {
      success: false,
      error: "Erreur lors de la mise à jour des notifications",
    }
  }
}

export const updateSavedSearch = async (searchId: string, userId: string, searchName: string) => {
  try {
    const formData = new URLSearchParams()
    formData.append('Method', 'update')
    formData.append('id', searchId)
    formData.append('userId', userId)
    formData.append('name', searchName)

    const response = await axios.post(
      `${config.API_URL}/SavedSearches.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Recherche mise à jour avec succès",
      }
    }

    return {
      success: false,
      error: "Erreur lors de la mise à jour de la recherche",
    }
  } catch (error) {
    console.error("Error updating saved search:", error)
    return {
      success: false,
      error: "Erreur lors de la mise à jour de la recherche",
    }
  }
}

export const resetNewMatchesCount = async (searchId: string, userId: string) => {
  try {
    const formData = new URLSearchParams()
    formData.append('Method', 'resetNewMatches')
    formData.append('id', searchId)
    formData.append('userId', userId)

    const response = await axios.post(
      `${config.API_URL}/SavedSearches.php`,
      formData,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return response.data.status === "success"
  } catch (error) {
    console.error("Error resetting new matches count:", error)
    return false
  }
}

export const fetchSavedSearches = getUserSavedSearches
export const toggleSearchNotifications = toggleSearchNotification