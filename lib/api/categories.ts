import axios from "axios"
import { config } from "@/lib/config"

export interface Category {
  id: string
  type: string
  parentId: string | null
  code: string
  label: string
  order: number
  isActive: boolean
  createdAt?: string
  updatedAt?: string
}

export interface CategoriesResponse {
  status: string
  data: {
    main: Category[]
    subs: { [parentId: string]: Category[] }
  }
}

export interface AllCategoriesResponse {
  status: string
  data: {
    [type: string]: {
      main: Category[]
      subs: { [parentId: string]: Category[] }
    }
  }
}

/**
 * Récupère toutes les catégories d'un type donné depuis l'API
 * @param type - Le type de catégorie (ex: "bons_plans", "evenements", "formations")
 * @returns Les catégories principales et sous-catégories organisées
 */
export async function getCategoriesByType(type: string): Promise<CategoriesResponse | null> {
  try {
    const params = new URLSearchParams()
    params.append("Method", "getByType")
    params.append("type", type)

    const response = await axios.post(
      `${config.API_URL}/Categorie.php`,
      params.toString(),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      // S'assurer que la structure de données est correcte
      const data = response.data.data || {}
      return {
        status: "success",
        data: {
          main: Array.isArray(data.main) ? data.main : [],
          subs: data.subs && typeof data.subs === "object" ? data.subs : {},
        },
      }
    }
    
    // Si le statut n'est pas success, logger l'erreur
    console.error("[v0] API returned error:", response.data)
    return null
  } catch (error: any) {
    console.error("[v0] Error fetching categories:", error)
    if (error.response) {
      console.error("[v0] Response status:", error.response.status)
      console.error("[v0] Response data:", error.response.data)
    }
    return null
  }
}

/**
 * Récupère toutes les catégories depuis l'API
 * @returns Toutes les catégories organisées par type
 */
export async function getAllCategories(): Promise<AllCategoriesResponse | null> {
  try {
    const params = new URLSearchParams()
    params.append("Method", "getAll")

    const response = await axios.post(
      `${config.API_URL}/Categorie.php`,
      params.toString(),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return response.data
    }
    return null
  } catch (error) {
    console.error("[v0] Error fetching all categories:", error)
    return null
  }
}

/**
 * Récupère une catégorie par son code
 * @param type - Le type de catégorie
 * @param code - Le code de la catégorie
 * @returns La catégorie avec ses sous-catégories si applicable
 */
export async function getCategoryByCode(
  type: string,
  code: string,
): Promise<{ status: string; data: Category } | null> {
  try {
    const params = new URLSearchParams()
    params.append("Method", "getByCode")
    params.append("type", type)
    params.append("code", code)

    const response = await axios.post(
      `${config.API_URL}/Categorie.php`,
      params.toString(),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return response.data
    }
    return null
  } catch (error) {
    console.error("[v0] Error fetching category by code:", error)
    return null
  }
}

