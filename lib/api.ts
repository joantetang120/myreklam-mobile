import axios from "axios"
import { startConversation } from "./api/messages"
import { config } from "@/lib/config"

// const API_URL = "https://test.myreklam.fr"

// const config = {
//   API_URL: "https://test.myreklam.fr",
// }

export interface SignUpPayload {
  userEmail: string
  userPassword: string
  Name: string
  Link: string
  Method: "create"
  refParrain?: string | null
}

export interface SignInPayload {
  userEmail: string
  userPassword: string
  Method: "login"
}

export interface VerifyEmailPayload {
  userEmail: string
  token: string
  Method: "verify"
}

export interface CreateUserInfoPayload {
  userid: string
  profiletype: "particulier" | "professionnel"
  Method: "create"
  // Particulier fields
  pseudo?: string
  telephone?: string
  photoProfil?: File
  // Professionnel fields
  siret?: string
  nomsociete?: string
  activite?: string
  adresse?: string
  ville?: string
  codepostal?: string
  pays?: string
}

export interface VerifySiretPayload {
  Siret: string
  Method: "insee"
}

export interface CreateCheckoutSessionPayload {
  priceId: string
  isAnnual: boolean
  price: number
  successUrl: string
  cancelUrl: string
  customerEmail: string
  userId?: string
  commercialCode?: string
}

export interface CompanyAddress {
  numeroVoie: string
  typeVoie: string
  libelleVoie: string
  commune: string
  codePostal: string
  country?: string
}

export interface CompanyData {
  name: string
  activity: string
  address: CompanyAddress
}

export interface ApiResponse {
  status: "success" | "error"
  message: string
  data?: any
  id?: string
  token?: string
  email?: string
  emailSent?: boolean
  companyData?: CompanyData
}

export interface DocumentFile {
  id: string
  user_id: string
  name: string
  category: "cv" | "motivation_letter" | "portfolio"
  url: string
  show_public: boolean
  is_external_link?: boolean
  created_at?: string
}

export interface AffiliateItem {
  id: string
  user_id: string
  referred_id: string
  commission: number
  desciption: string
  referred_profile_type: string
  referred_pseudo: string
  referred_nomsociete: string
  status: boolean
  created_at: string
}

export interface Reward {
  hexcolor: string
  valuemys: number
  valueeuro: number
  isspecial?: boolean
}

export interface AmbassadorStatus {
  raise: boolean
  title: string
  valuemys: number
  star: number
  hexprimarycolor: string
  hexsecondarcolor: string
  hexlightcolor: string
  mincoins: number
  maxcoins: number
  status?: number
  id?: string
  showrank?: number
}

export interface UserCoins {
  id: string
  userid: string
  value: number
  updateat: string
  lastconversionat: string
}

export interface HistoryCoin {
  history_id: string
  userid: string
  eventname: string
  createdat: string
  event_id: string
  slug: string
  title: string
  description: string
  coins: number
  status: boolean
  icon: string
  rank: number
}

export interface EventCoin {
  id: string
  slug: string
  title: string
  description: string
  coins: number
  status: number
}

export const sponsorshipCodeParam = "ref-parrain"

export const signUpUser = async (payload: SignUpPayload): Promise<ApiResponse> => {
  try {
    const params = new URLSearchParams()
    Object.entries(payload).forEach(([key, value]) => {
      if (value !== null && value !== undefined) {
        params.append(key, String(value))
      }
    })
    
    const response = await axios.post(`${config.API_URL}/LoginUser.php`, params, {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    })
    return response.data
  } catch (error) {
    console.error("[API] Error during signup:", error)
    throw error
  }
}

export const signInUser = async (payload: SignInPayload): Promise<ApiResponse> => {
  try {
    const params = new URLSearchParams()
    Object.entries(payload).forEach(([key, value]) => {
      if (value !== null && value !== undefined) {
        params.append(key, String(value))
      }
    })
    
    const response = await axios.post(`${config.API_URL}/LoginUser.php`, params, {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    })
    return response.data
  } catch (error) {
    console.error("[API] Error during signin:", error)
    throw error
  }
}

export const verifyEmail = async (payload: VerifyEmailPayload): Promise<ApiResponse> => {
  try {
    const params = new URLSearchParams()
    Object.entries(payload).forEach(([key, value]) => {
      if (value !== null && value !== undefined) {
        params.append(key, String(value))
      }
    })
    
    const response = await axios.post(`${config.API_URL}/LoginUser.php`, params, {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    })
    return response.data
  } catch (error) {
    console.error("[API] Error during email verification:", error)
    throw error
  }
}

export const getUserIdFromToken = async (email: string, token: string): Promise<ApiResponse> => {
  try {
    const params = new URLSearchParams()
    params.append("userEmail", email)
    params.append("token", token)
    params.append("Method", "getUserIdFromToken")
    
    const response = await axios.post(
      `${config.API_URL}/LoginUser.php`,
      params,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )
    return response.data
  } catch (error) {
    console.error("[API] Error getting user ID from token:", error)
    throw error
  }
}

export const createUserInfo = async (payload: CreateUserInfoPayload): Promise<ApiResponse> => {
  try {
    const formData = new FormData()
    Object.entries(payload).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        formData.append(key, value)
      }
    })

    const response = await axios.post(`${config.API_URL}/UserInfo.php`, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    })
    return response.data
  } catch (error) {
    console.error("[API] Error creating user info:", error)
    throw error
  }
}

export const verifySiret = async (payload: VerifySiretPayload): Promise<ApiResponse> => {
  try {
    const response = await axios.post(`${config.API_URL}/Insee.php`, payload, {
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    })
    return response.data
  } catch (error) {
    console.error("[API] Error verifying SIRET:", error)
    throw error
  }
}

export const createCheckoutSession = async (payload: CreateCheckoutSessionPayload): Promise<ApiResponse> => {
  try {
    const response = await axios.post(`${config.API_URL}/create-checkout-session.php`, payload, {
      headers: {
        "Content-Type": "application/json",
      },
    })
    console.log("[API] Checkout session response:", response.data)
    // Le backend retourne directement {id, customerId}, on le wrappe dans data
    return { status: "success", message: "Session créée avec succès", data: response.data }
  } catch (error) {
    console.error("[API] Error creating checkout session:", error)
    throw error
  }
}

export const contactSupport = async (data: any): Promise<ApiResponse> => {
  try {
    const response = await axios.post(`${config.API_URL}/ContactSupport.php`, data, {
      headers: {
        "Content-Type": "application/json",
      },
    })
    return response.data
  } catch (error) {
    console.error("[API] Error contacting support:", error)
    throw error
  }
}

export const getUserSubscriptions = async (userId: string): Promise<any[]> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Abonnement.php`,
      {
        userid: userId,
        Method: "readAllByUserId",
      },
      {
        timeout: 10000,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return response.data.subscriptions || []
    }
    return []
  } catch (error) {
    console.error("[API] Error fetching subscriptions:", error)
    return []
  }
}

export const hasActiveSubscription = (subscriptions: any[]): boolean => {
  if (!subscriptions || subscriptions.length === 0) return false

  const now = new Date()
  return subscriptions.some((sub) => {
    if (!sub.endDate) return false
    const endDate = new Date(sub.endDate)
    return endDate > now && sub.status === "active"
  })
}

export const getUserDocumentFiles = async (userId: string): Promise<DocumentFile[]> => {
  try {
    console.log("[API] Fetching documents for userId:", userId)
    
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        user_id: userId,
        Method: "get_document_files",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    
    console.log("[API] Get documents response:", response.data)
    
    if (response.data.status === "success") {
      // L'API retourne "document_files" et non "documents"
      const documents = response.data.document_files || response.data.documents || []
      console.log("[API] Returning documents:", documents)
      return documents
    }
    console.log("[API] No documents found or error status")
    return []
  } catch (error) {
    console.error("[API] Error fetching documents:", error)
    return []
  }
}

export const createDocumentFile = async (data: Partial<DocumentFile>): Promise<ApiResponse> => {
  try {
    const payload = {
      ...data,
      Method: "create_document_file",
    }
    
    console.log("[API] Creating document with payload:", payload)
    
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      payload,
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    
    console.log("[API] Create document response:", response.data)
    return response.data
  } catch (error) {
    console.error("[API] Error creating document:", error)
    throw error
  }
}

export const updateDocumentFile = async (data: DocumentFile): Promise<ApiResponse> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        ...data,
        Method: "update_document_file",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return response.data
  } catch (error) {
    console.error("[API] Error updating document:", error)
    throw error
  }
}

export const deleteDocumentFile = async (documentId: string, userId: string): Promise<ApiResponse> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        id: documentId,
        user_id: userId,
        Method: "delete_document_file",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return response.data
  } catch (error) {
    console.error("[API] Error deleting document:", error)
    throw error
  }
}

export const uploadFile = async (file: File): Promise<any> => {
  try {
    const formData = new FormData()
    formData.append("file", file)
    formData.append("Method", "upload")

    console.log("[API] Uploading file:", file.name, "Size:", file.size)

    const response = await axios.post(`${config.API_URL}/UploadFiles.php`, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    })
    
    console.log("[API] Upload response:", response.data)
    return response.data
  } catch (error) {
    console.error("[API] Error uploading file:", error)
    throw error
  }
}

export const getApplicationAdsByInterestedUserId = async (userId: string): Promise<any[]> => {
  try {
    console.log("[API] Fetching applications for userId:", userId)

    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        Method: "get_application_ads_by_interested_user_id",
        interested_user_id: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    console.log("[API] Applications response:", response.data)

    if (response.data.status === "success") {
      return response.data.applications || []
    }
    return []
  } catch (error: any) {
    // Improved error handling for 404
    if (error.response?.status === 404) {
      console.log("[API] Applications endpoint returned 404 - user may have no applications or endpoint not available")
      return []
    }
    console.error("[API] Error fetching applications:", error)
    return []
  }
}

export const getApplicationDocuments = async (applicationId: string): Promise<any> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        Method: "get_documents_by_application_id",
        application_id: applicationId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    
    if (response.data.status === "success") {
      return { success: true, documents: response.data.documents || [] }
    }
    return { success: false, documents: [] }
  } catch (error) {
    console.error("[API] Error fetching application documents:", error)
    return { success: false, documents: [] }
  }
}

export const checkUserSubscription = async (userId: string): Promise<boolean> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Abonnement.php`,
      {
        Method: "readAllByUserId",
        Id: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    
    console.log("[API] Abonnement response:", response.data)
    
    if (response.data.status === "success" && response.data.subscriptions) {
      // S'il y a au moins un abonnement, on considère que l'utilisateur a un abonnement actif
      const hasSubscription = response.data.subscriptions.length > 0
      console.log("[API] A un abonnement actif:", hasSubscription, "- Nombre d'abonnements:", response.data.subscriptions.length)
      return hasSubscription
    }
    return false
  } catch (error) {
    console.error("[API] Error checking subscription:", error)
    return false
  }
}

export const getUserDocuments = async (userId: string): Promise<any> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        Method: "get_document_files",
        user_id: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    
    console.log("[API] User documents response:", response.data)
    
    if (response.data.status === "success") {
      return { success: true, documents: response.data.document_files || [] }
    }
    return { success: false, documents: [] }
  } catch (error) {
    console.error("[API] Error fetching user documents:", error)
    return { success: false, documents: [] }
  }
}

export const fetchUserAnnoncesWithApplications = async (userId: string): Promise<any> => {
  try {
    console.log("[v0] Fetching user annonces for userId:", userId)

    const response = await axios.post(
      `${config.API_URL}/Ads.php`,
      {
        userId: userId,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    console.log("[v0] Annonces response:", response.data)

    if (response.data.status === "success") {
      const annonces = response.data.ads || []
      
      // Récupérer les candidatures pour chaque annonce
      const annoncesWithApplications = await Promise.all(
        annonces.map(async (annonce: any) => {
          try {
            const applicationsResponse = await axios.post(
              `${config.API_URL}/DocumentFiles.php`,
              {
                Method: "get_application_ads_by_ad_id",
                ad_id: annonce.id,
              },
              {
                headers: {
                  "Content-Type": "application/x-www-form-urlencoded",
                },
              },
            )
            
            console.log(`[v0] Applications pour annonce ${annonce.id}:`, applicationsResponse.data)
            
            if (applicationsResponse.data.status === "success") {
              const applications = applicationsResponse.data.applications || []
              
              // Récupérer les documents pour chaque candidature
              const applicationsWithDocs = await Promise.all(
                applications.map(async (app: any) => {
                  try {
                    // Récupérer les documents publics du candidat
                    const userId = app.userInfo?.userid || app.application?.interested_user_id
                    if (userId) {
                      const userDocsResponse = await axios.post(
                        `${config.API_URL}/DocumentFiles.php`,
                        {
                          Method: "get_document_files",
                          user_id: userId,
                        },
                        {
                          headers: {
                            "Content-Type": "application/x-www-form-urlencoded",
                          },
                        },
                      )
                      
                      if (userDocsResponse.data.status === "success") {
                        // Filtrer uniquement les documents publics
                        const publicDocs = (userDocsResponse.data.document_files || []).filter(
                          (doc: any) => doc.show_public === true
                        )
                        return {
                          ...app,
                          documents: publicDocs,
                        }
                      }
                    }
                  } catch (error) {
                    console.error(`[API] Error fetching documents for user:`, error)
                  }
                  
                  return {
                    ...app,
                    documents: [],
                  }
                })
              )
              
              return {
                ...annonce,
                applications: applicationsWithDocs,
              }
            }
          } catch (error) {
            console.error(`[API] Error fetching applications for ad ${annonce.id}:`, error)
          }
          
          return {
            ...annonce,
            applications: [],
          }
        })
      )
      
      return { success: true, annonces: annoncesWithApplications }
    }

    return { success: false, annonces: [] }
  } catch (error) {
    console.error("[API] Error fetching user annonces:", error)
    return { success: false, annonces: [] }
  }
}

export const fetchUserAnnonces = async (userId: string) => {
  try {
    const annoncesPromise = axios.post(
      `${config.API_URL}/Ads.php`,
      {
        userId: userId,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const favorisPromise = axios.post(
      `${config.API_URL}/Favoris.php`,
      {
        userid: userId,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const [annoncesResponse, favorisResponse] = await Promise.all([annoncesPromise, favorisPromise])

    if (annoncesResponse.data.status === "success") {
      let annoncesData = annoncesResponse.data.ads

      if (favorisResponse.data.status === "success") {
        const favorisIds = favorisResponse.data.favoris.map((favori: any) => favori.annonceid)

        annoncesData = await Promise.all(
          annoncesData.map(async (annonce: any) => {
            const companyData = await fetchCompanyData(annonce.userId)
            const imageResult = await fetchDealImages(annonce.id)

            return {
              ...annonce,
              views: annonce.views || annonce.number_view || 0,
              isFavorite: favorisIds.includes(annonce.id),
              images: imageResult.success ? imageResult.images : [],
              companyData: companyData.success
                ? {
                    ...companyData.companyData,
                    photoprofilurl: companyData.companyData.photoprofilurl
                      ? `${config.API_URL}${companyData.companyData.photoprofilurl}`
                      : "",
                  }
                : null,
            }
          }),
        )
      }

      return { success: true, annonces: annoncesData }
    } else {
      return { success: false, error: "Erreur lors de la récupération des annonces." }
    }
  } catch (error) {
    console.error("Error fetching annonces:", error)
    return { success: false, error: "Erreur lors de la récupération des annonces." }
  }
}

export const fetchUserFavorites = async (userId: string) => {
  try {
    const responseFav = await axios.post(
      `${config.API_URL}/Favoris.php`,
      {
        userid: userId,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (responseFav.data.status === "success") {
      const annonceIds = responseFav.data.favoris.map((favori: any) => favori.annonceid)

      if (annonceIds.length === 0) {
        return { success: true, annonces: [] }
      }

      const adsPromises = annonceIds.map(async (annonceId: string) => {
        const response = await axios.post(
          `${config.API_URL}/Ads.php`,
          {
            id: annonceId,
            Method: "readAdsByCriteria",
          },
          {
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
            },
          },
        )

        if (response.data.status === "success" && response.data.ads && response.data.ads[0]) {
          return { ...response.data.ads[0], isFavorite: true }
        }
        return null
      })

      const ads = (await Promise.all(adsPromises)).filter((ad) => ad !== null)

      const annoncesWithCompanyData = await Promise.all(
        ads.map(async (deal: any) => {
          const companyData = await fetchCompanyData(deal.userId)
          return {
            ...deal,
            companyData: companyData.success
              ? {
                  ...companyData.companyData,
                  photoprofilurl: companyData.companyData.photoprofilurl
                    ? `${config.API_URL}${companyData.companyData.photoprofilurl}`
                    : "",
                }
              : null,
          }
        }),
      )

      return { success: true, annonces: annoncesWithCompanyData }
    } else {
      return { success: false, error: "Erreur lors de la récupération des favoris." }
    }
  } catch (error) {
    console.error("Error fetching favorites:", error)
    return { success: false, error: "Erreur lors de la récupération des favoris." }
  }
}

export const fetchDealImages = async (dealId: string) => {
  try {
    const imageResponse = await axios.post(
      `${config.API_URL}/ImageAnnonce.php`,
      {
        Method: "readAllByAnnonceId",
        Id: dealId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (imageResponse.status === 200 && imageResponse.data.status === "success") {
      const imageUrls = imageResponse.data.images?.map((image: any) => image.urlimg) || []
      return { success: true, images: imageUrls }
    } else {
      return { success: false, images: [], error: "Erreur lors de la récupération des images." }
    }
  } catch (error) {
    console.error("Error fetching image for deal:", dealId, error)
    return { success: false, images: [], error: "Erreur lors de la récupération des images." }
  }
}

export const toggleFavorite = async (userId: string, dealId: string, isFavorite: boolean) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Favoris.php`,
      {
        Method: isFavorite ? "create" : "delete",
        userid: userId,
        annonceid: dealId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.status === 200 && response.data.status === "success") {
      return {
        success: true,
        message: isFavorite ? "Annonce ajoutée aux favoris" : "Annonce retirée des favoris",
      }
    } else {
      return {
        success: false,
        error: "Erreur lors de la mise à jour des favoris.",
      }
    }
  } catch (error) {
    console.error("Error updating favorite status for deal:", dealId, error)
    return {
      success: false,
      error: "Erreur lors de la mise à jour des favoris.",
    }
  }
}

export const deleteAnnouncement = async (userId: string, dealId: string) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Ads.php`,
      {
        id: dealId,
        Method: "delete",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return { success: true, message: "Annonce supprimée avec succès" }
    } else {
      return { success: false, error: "Échec de la suppression de l'annonce" }
    }
  } catch (error) {
    console.error("Erreur lors de la suppression de l'annonce:", error)
    return { success: false, error: "Une erreur est survenue lors de la suppression de l'annonce" }
  }
}

export const fetchCommentsByAnnouncementId = async (announcementId: string) => {
  try {
    const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""

    const response = await axios.post(
      `${config.API_URL}/Commentaires.php`,
      {
        Method: "getCommentairesByAnnonceId",
        annonceid: announcementId,
        userid: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      const comments = response.data.commentaires || []

      for (let i = 0; i < comments.length; i++) {
        const comment = comments[i]

        const userResult = await fetchUserInfo(comment.userid)

        let isLiked = false
        let likesCount = Number(comment.likesCount || 0)

        try {
          const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""

          const params = new URLSearchParams()
          params.append("Method", "isLiked")
          params.append("commentid", comment.id)
          params.append("userid", userId || "")

          const res = await axios.post(`${config.API_URL}/LikeComment.php`, params.toString(), {
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
          })

          if (res.data?.status === "success") {
            isLiked = !!res.data.isLiked
            likesCount = Number(res.data.likesCount ?? likesCount)

            comments[i].isLiked = !!res.data.isLiked
            comments[i].likesCount = Number(res.data.likesCount ?? likesCount)
          }
        } catch (e) {
          console.error("Erreur Like API", e)
        }
      }

      return { success: true, comments: response.data.commentaires || [] }
    } else {
      return { success: false, comments: [], error: "Erreur lors de la récupération des commentaires." }
    }
  } catch (error) {
    console.error("Error fetching comments:", error)
    return { success: false, comments: [], error: "Erreur lors de la récupération des commentaires." }
  }
}

export const addComment = async (announcementId: string, userId: string, commentText: string) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Commentaires.php`,
      {
        Method: "create",
        annonceid: announcementId,
        userid: userId,
        commentaire: commentText,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      // Déclencher l'événement pour rafraîchir les limites de commentaires
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new Event('commentCreated'))
      }
      return { success: true, comment: response.data.commentaires }
    } else {
      return { success: false, error: "Erreur lors de l'ajout du commentaire." }
    }
  } catch (error) {
    console.error("Error adding comment:", error)
    return { success: false, error: "Erreur lors de l'ajout du commentaire." }
  }
}

export const fetchUserInfo = async (userId: string) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/UserInfo.php`,
      {
        Method: "readAdsByCriteria",
        userid: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      if (!response.data.userInfo || !Array.isArray(response.data.userInfo) || response.data.userInfo.length === 0) {
        return {
          success: false,
          error: "Aucune information utilisateur trouvée.",
        }
      }
      const userInfo = response.data.userInfo[0]
      return {
        success: true,
        userName: userInfo.pseudo || userInfo.nomsociete,
        userInfo,
      }
    } else {
      return { success: false, error: "Erreur lors de la récupération des informations utilisateur." }
    }
  } catch (error) {
    console.error("Error fetching user info:", error)
    return { success: false, error: "Erreur lors de la récupération des informations utilisateur." }
  }
}

export const fetchPublisherData = async (userId: string) => {
  try {
    const userInfoResponse = await axios.post(
      `${config.API_URL}/UserInfo.php`,
      {
        userid: userId,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const userEmailResponse = await axios.post(
      `${config.API_URL}/LoginUser.php`,
      {
        Id: userId,
        Method: "readAllByUserId",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const imageDiapoResponse = await axios.post(
      `${config.API_URL}/ImageDiapo.php`,
      {
        Id: userId,
        Method: "readAllByUserId",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const bannerResponse = await axios
      .post(
        `${config.API_URL}/bannerEntreprise.php`,
        {
          userId: userId,
          Method: "READ",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )
      .catch(() => ({ data: { status: "error", banner: null } }))

    const newsResponse = await axios
      .post(
        `${config.API_URL}/actualiteEntreprise.php`,
        {
          userId: userId,
          Method: "READ",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )
      .catch(() => ({ data: [] }))

    return {
      success: true,
      userData: {
        companyData: userInfoResponse.data.status === "success" ? userInfoResponse.data.userInfo[0] : null,
        email: userEmailResponse.data.status === "success" ? userEmailResponse.data.profile[0].Email : "",
        imageDiapoData: imageDiapoResponse.data.status === "success" ? { media: imageDiapoResponse.data.images } : null,
        bannerData: bannerResponse.data.status === "success" ? bannerResponse.data.banner : null,
        newsData: Array.isArray(newsResponse.data) ? newsResponse.data : [],
      },
    }
  } catch (error) {
    console.error("Error fetching publisher data:", error)
    return {
      success: false,
      error: "Erreur lors de la récupération des données de l'annonceur.",
      userData: {
        companyData: null,
        email: "",
        imageDiapoData: null,
        bannerData: null,
        newsData: [],
      },
    }
  }
}

export const participateEvent = async (userId: string, announcementId: string | undefined) => {
  if (!userId || !announcementId) {
    return {
      success: false,
      error: "Identifiant utilisateur ou annonce manquant",
    }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Participate.php`,
      {
        userid: userId,
        annonceid: announcementId,
        Method: "create",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Participation enregistrée avec succès",
      }
    } else {
      return {
        success: false,
        error: response.data.message || "Erreur lors de l'enregistrement de la participation",
      }
    }
  } catch (error) {
    console.error("Error during participation:", error)
    return {
      success: false,
      error: "Une erreur est survenue lors de la participation",
    }
  }
}

export const checkParticipationStatus = async (userId: string, announcementId: string) => {
  if (!userId || !announcementId) {
    return {
      success: false,
      isParticipating: false,
      error: "Identifiant utilisateur ou annonce manquant",
    }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Participate.php`,
      {
        Method: "readAdsByCriteria",
        userid: userId,
        annonceid: announcementId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      const participations = response.data.partipate || []
      const isParticipating = participations.length > 0
      return {
        success: true,
        isParticipating,
      }
    } else {
      return {
        success: false,
        isParticipating: false,
        error: "Erreur lors de la vérification de la participation",
      }
    }
  } catch (error) {
    console.error("Error checking participation status:", error)
    return {
      success: false,
      isParticipating: false,
      error: "Une erreur est survenue lors de la vérification",
    }
  }
}

export const getParticipationCount = async (announcementId: string) => {
  if (!announcementId) {
    return {
      success: false,
      count: 0,
      error: "Identifiant annonce manquant",
    }
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Participate.php`,
      {
        Method: "readAdsByCriteria",
        annonceid: announcementId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      const participations = response.data.partipate || []
      return {
        success: true,
        count: participations.length,
      }
    } else {
      return {
        success: false,
        count: 0,
        error: "Erreur lors de la récupération du nombre de participants",
      }
    }
  } catch (error) {
    console.error("Error getting participation count:", error)
    return {
      success: false,
      count: 0,
      error: "Une erreur est survenue lors de la récupération",
    }
  }
}

export const unsubscribeFromEvent = async (userId: string, announcementId: string) => {
  if (!userId || !announcementId) {
    return {
      success: false,
      error: "Identifiant utilisateur ou annonce manquant",
    }
  }

  try {
    // First, get the participation ID
    const participationResponse = await axios.post(
      `${config.API_URL}/Participate.php`,
      {
        Method: "readAdsByCriteria",
        userid: userId,
        annonceid: announcementId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (participationResponse.data.status === "success") {
      const participations = participationResponse.data.partipate || []
      if (participations.length === 0) {
        return {
          success: false,
          error: "Vous n'êtes pas inscrit à cet événement",
        }
      }

      const participationId = participations[0].id

      // Delete the participation
      const deleteResponse = await axios.post(
        `${config.API_URL}/Participate.php`,
        {
          Method: "delete",
          id: participationId,
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      if (deleteResponse.data.status === "success") {
        return {
          success: true,
          message: "Désinscription réussie",
        }
      } else {
        return {
          success: false,
          error: deleteResponse.data.message || "Erreur lors de la désinscription",
        }
      }
    } else {
      return {
        success: false,
        error: "Erreur lors de la vérification de la participation",
      }
    }
  } catch (error) {
    console.error("Error unsubscribing from event:", error)
    return {
      success: false,
      error: "Une erreur est survenue lors de la désinscription",
    }
  }
}

export const addReplyToComment = async (
  commentId: string,
  userId: string,
  replyText: string,
  announcementId: string,
) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Commentaires.php`,
      {
        Method: "create",
        parentid: commentId,
        userid: userId,
        commentaire: replyText,
        annonceid: announcementId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        reply: response.data.reply,
        message: "Réponse ajoutée avec succès",
      }
    } else {
      return {
        success: false,
        error: "Erreur lors de l'ajout de la réponse",
      }
    }
  } catch (error) {
    console.error("Error adding reply to comment:", error)
    return {
      success: false,
      error: "Une erreur est survenue lors de l'ajout de la réponse",
    }
  }
}

export const toggleLikeComment = async (commentId: string, userId: string, isLiked: boolean) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/LikeComment.php`,
      {
        Method: isLiked ? "unlike" : "like",
        commentid: commentId,
        userid: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return response.data
  } catch (error) {
    return { status: "error", message: "Erreur lors du like" }
  }
}

export const fetchDeals = async (criteria: {
  category?: string
  dealType?: string
  dealCategory?: string
  subCategory?: string
  address?: string
  title?: string
  description?: string
}) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Ads.php`,
      {
        Method: "readAdsByCriteria",
        category: criteria.category || "bons_plans",
        dealType: criteria.dealType || "",
        dealCategory: criteria.dealCategory || "",
        subCategory: criteria.subCategory || "",
        address: criteria.address || "",
        title: criteria.title || "",
        description: criteria.description || "",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.status === 200 && response.data.status === "success" && response.data.ads) {
      const ads = response.data.ads
      let dealsWithImages = await Promise.all(
        ads.map(async (deal: any) => {
          const imageResult = await fetchDealImages(deal.id)
          return {
            ...deal,
            images: imageResult.success ? imageResult.images : [],
          }
        }),
      )

      dealsWithImages = dealsWithImages.sort(
        (a, b) => new Date(b.createdat).getTime() - new Date(a.createdat).getTime(),
      )

      return { success: true, deals: dealsWithImages }
    } else {
      return { success: false, deals: [], error: "Erreur lors de la récupération des annonces." }
    }
  } catch (error) {
    console.error("Error fetching deals:", error)
    return { success: false, deals: [], error: "Erreur lors de la récupération des annonces." }
  }
}

export const fetchAnnoncements = async (criteria: {
  category?: string
  dealType?: string
  dealCategory?: string
  inquiryTypeCategory?: string
  inquiryTrainingCategory?: string
  realEstateType?: string
  subCategory?: string | null
  address?: string
  title?: string
  inquiryType?: string
  description?: string
}) => {
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
  try {
    const [adsResponse, favorisResponse] = await Promise.all([
      axios.post(
        `${config.API_URL}/Ads.php`,
        {
          Method: "readAdsByCriteria",
          category: criteria.category || "bons_plans",
          dealType: criteria.dealType || "",
          dealCategory: criteria.dealCategory || "",
          inquiryType: criteria.inquiryType || "",
          inquiryTypeCategory: criteria.inquiryTypeCategory || "",
          inquiryTrainingCategory: criteria.inquiryTrainingCategory || "",
          realEstateType: criteria.realEstateType || "",
          subCategory: criteria.subCategory || "",
          address: criteria.address || "",
          title: criteria.title || "",
          description: criteria.description || "",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      ),
      userId
        ? axios.post(
            `${config.API_URL}/Favoris.php`,
            {
              userid: userId,
              Method: "readAdsByCriteria",
            },
            {
              headers: {
                "Content-Type": "application/x-www-form-urlencoded",
              },
            },
          )
        : Promise.resolve(null),
    ])

    if (adsResponse.status === 200 && adsResponse.data.status === "success" && adsResponse.data.ads) {
      const ads = adsResponse.data.ads
      let dealsWithImages = await Promise.all(
        ads.map(async (deal: any) => {
          const imageResult = await fetchDealImages(deal.id)
          const companyData = await fetchCompanyData(deal.userId)
          return {
            ...deal,
            images: imageResult.success ? imageResult.images : [],
            companyData: companyData.success
              ? {
                  ...companyData.companyData,
                  photoprofilurl: companyData.companyData.photoprofilurl
                    ? `${config.API_URL}${companyData.companyData.photoprofilurl}`
                    : "",
                }
              : null,
          }
        }),
      )

      dealsWithImages = dealsWithImages.sort(
        (a, b) => new Date(b.createdat).getTime() - new Date(a.createdat).getTime(),
      )

      if (userId && favorisResponse && favorisResponse.data.status === "success") {
        const favorisIds = favorisResponse.data.favoris.map((favori: any) => favori.annonceid)

        dealsWithImages = dealsWithImages.map((deal: any) => ({
          ...deal,
          isFavorite: favorisIds.includes(deal.id),
        }))
      }

      return { success: true, deals: dealsWithImages }
    } else {
      return { success: false, deals: [], error: "Erreur lors de la récupération des annonces." }
    }
  } catch (error) {
    console.error("Error fetching announcements:", error)
    return { success: false, deals: [], error: "Erreur lors de la récupération des annonces." }
  }
}
export const fetchUserInfoById = async (userId: string) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/UserInfo.php`,
      {
        Method: "readAdsByCriteria",
        userid: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )

    if (response.data.status === "success" && response.data.userInfo && response.data.userInfo.length > 0) {
      return {
        success: true,
        userInfo: response.data.userInfo[0]
      }
    }

    return {
      success: false,
      userInfo: null
    }
  } catch (error) {
    console.error("Error fetching user info:", error)
    return {
      success: false,
      userInfo: null
    }
  }
}

export const fetchCompanyData = async (userId: string) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/UserInfo.php`,
      {
        userid: userId,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        companyData: response.data.userInfo[0],
        userProfile: response.data.userInfo[0].profiletype,
      }
    } else {
      return {
        success: false,
        error: "Erreur lors de la récupération des données de l'entreprise.",
      }
    }
  } catch (error) {
    console.error("Error fetching company data:", error)
    return {
      success: false,
      error: "Erreur lors de la récupération des données de l'entreprise.",
    }
  }
}

export const updateCompanyData = async (companyData: any) => {
  try {
    const urlRequeteAddress = `${config.API_URL}/UserInfo.php`
    const formDataToSend = new FormData()

    formDataToSend.append("userid", companyData?.id || "")
    formDataToSend.append("name", companyData?.nomsociete || "")
    formDataToSend.append("activity", companyData?.activite || "")
    formDataToSend.append("tel", companyData?.telephone || "")
    formDataToSend.append("address", companyData?.adresse || "")
    formDataToSend.append("ville", companyData?.ville || "")
    formDataToSend.append("codePostal", companyData?.codepostal || "")
    formDataToSend.append("pays", companyData?.pays || "")
    formDataToSend.append("facebook", companyData?.facebook || "")
    formDataToSend.append("instagram", companyData?.instagram || "")
    formDataToSend.append("x", companyData?.x || "")
    formDataToSend.append("linkedin", companyData?.linkedin || "")
    formDataToSend.append("youtube", companyData?.youtube || "")
    formDataToSend.append("tiktok", companyData?.tiktok || "")
    formDataToSend.append("snapchat", companyData?.snapchat || "")
    formDataToSend.append("publishadresse", companyData?.publishadresse || "")
    formDataToSend.append("publishname", companyData?.publishname || "")
    formDataToSend.append("publishactivity", companyData?.publishactivity || "")
    formDataToSend.append("publishtelephone", companyData?.publishtelephone || "")

    formDataToSend.append("Method", "updateUserInfo")

    const response = await axios.post(urlRequeteAddress, formDataToSend, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    })

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Les données ont été mises à jour avec succès !",
        updatedData: { ...companyData, ...response.data.userInfo[0] },
      }
    } else {
      return {
        success: false,
        error: "Erreur lors de la mise à jour des données.",
      }
    }
  } catch (error) {
    console.error("Error updating company data:", error)
    return {
      success: false,
      error: "Erreur lors de la mise à jour des données.",
    }
  }
}

export const updateSetting = async (companyData: any) => {
  try {
    const urlRequeteAddress = `${config.API_URL}/UserInfo.php`
    const formDataToSend = new FormData()

    formDataToSend.append("id", companyData?.id || "")

    formDataToSend.append("active_nofification_mobile_message", companyData.active_nofification_mobile_message)
    formDataToSend.append("active_nofification_mobile_alert", companyData.active_nofification_mobile_alert)
    formDataToSend.append("active_nofification_mobile_comment", companyData.active_nofification_mobile_comment)
    formDataToSend.append("active_nofification_mobile_notice", companyData.active_nofification_mobile_notice)
    formDataToSend.append("active_nofification_mobile_newsletter", companyData.active_nofification_mobile_newsletter)
    formDataToSend.append("active_nofification_email_message", companyData.active_nofification_email_message)
    formDataToSend.append("active_nofification_email_alert", companyData.active_nofification_email_alert)
    formDataToSend.append("active_nofification_email_comment", companyData.active_nofification_email_comment)
    formDataToSend.append("active_nofification_email_notice", companyData.active_nofification_email_notice)
    formDataToSend.append("active_nofification_email_newsletter", companyData.active_nofification_email_newsletter)

    formDataToSend.append("Method", "updateUserInfo")

    const response = await axios.post(urlRequeteAddress, formDataToSend, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    })

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Les données ont été mises à jour avec succès !",
      }
    } else {
      return {
        success: false,
        error: "Erreur lors de la mise à jour des données.",
      }
    }
  } catch (error) {
    console.error("Error updating company data:", error)
    return {
      success: false,
      error: "Erreur lors de la mise à jour des données.",
    }
  }
}

export const deleteAccount = async (userId: string) => {
  try {
    const urlRequeteAddress = `${config.API_URL}/LoginUser.php`

    const response = await axios.post(
      urlRequeteAddress,
      {
        userId: userId,
        Method: "deleteAccount",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return {
        success: true,
        message: "Votre compte a été supprimer avec succès !",
      }
    } else {
      return {
        success: false,
        error: "Erreur la suppression des données.",
      }
    }
  } catch (error) {
    console.error("Error deleting data:", error)
    return {
      success: false,
      error: "Erreur la suppression des données.",
    }
  }
}

export const cancelStripeSubscription = async (customerId: string): Promise<ApiResponse> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/CancelStripeSubscription.php`,
      {
        customerId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return response.data
  } catch (error) {
    console.error("[API] Error canceling subscription:", error)
    throw error
  }
}

export const createBillingPortalSession = async (customerId: string, returnUrl: string): Promise<ApiResponse> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/createBillingPortalSession.php`,
      {
        method: "createBillingPortalSession",
        customerId,
        returnUrl,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )
    return response.data
  } catch (error) {
    console.error("[API] Error creating billing portal session:", error)
    throw error
  }
}

export const createAffiliateCode = async (): Promise<string | null> => {
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null

  if (!userId) {
    return null
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Affiliates.php`,
      {
        Method: "create_user_affiliate_code",
        user_id: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return response.data.affiliate_code
    }

    return null
  } catch (error) {
    console.error("Erreur lors de la création du code affilié :", error)
    return null
  }
}

export const createChildAffiliate = async (): Promise<string | null> => {
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null
  const refParrain = typeof window !== "undefined" ? localStorage.getItem("refParrain") : null

  if (!userId || !refParrain) return null

  try {
    const response = await axios.post(
      `${config.API_URL}/Affiliates.php`,
      {
        Method: "create_affiliate",
        user_id: userId,
        refParrain: refParrain,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      if (typeof window !== "undefined") {
        localStorage.removeItem("refParrain")
      }
      return response.data.affiliate_code
    }

    return null
  } catch (error) {
    console.error("Erreur lors de la création de l'affilié enfant :", error)
    return null
  }
}

export const getAffiliateCode = async (): Promise<string | null> => {
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null

  if (!userId) {
    console.log("[v0] getAffiliateCode - Pas de userId")
    return null
  }

  try {
    console.log("[v0] getAffiliateCode - Appel API pour userId:", userId)
    const response = await axios.post(
      `${config.API_URL}/Affiliates.php`,
      {
        Method: "get_affiliate_code",
        user_id: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    console.log("[v0] getAffiliateCode - Réponse API:", response.data)

    if (response.data.status === "success") {
      console.log("[v0] getAffiliateCode - Code retourné:", response.data.affiliate_code)
      return response.data.affiliate_code
    }

    console.log("[v0] getAffiliateCode - Pas de succès, status:", response.data.status, "message:", response.data.message)
    return null
  } catch (error) {
    console.error("Erreur lors de la récupération du code affilié :", error)
    return null
  }
}

export const getAffiliateList = async (): Promise<AffiliateItem[]> => {
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null

  if (!userId) {
    return []
  }

  try {
    const response = await axios.post(
      `${config.API_URL}/Affiliates.php`,
      {
        Method: "get_referred_ids",
        user_id: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const affiliates = response.data.referred_ids || []

    return affiliates.map((affiliate: AffiliateItem) => ({
      id: affiliate.id,
      user_id: affiliate.user_id,
      referred_id: affiliate.referred_id,
      referred_profile_type: affiliate.referred_profile_type,
      referred_pseudo: affiliate.referred_pseudo,
      referred_nomsociete: affiliate.referred_nomsociete,
      desciption: affiliate.desciption,
      commission: affiliate.commission,
      status: affiliate.status,
      created_at: affiliate.created_at,
    }))
  } catch (error) {
    console.error("Erreur lors de la récupération de la liste des affiliés :", error)
    return []
  }
}

export const getRewardsList = async (): Promise<Reward[]> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Reward.php`,
      { Method: "get_rewards" },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const data = response.data?.rewards ?? []
    return data.map((item: any) => ({
      hexcolor: item.hexcolor,
      valuemys: item.valuemys,
      valueeuro: item.valueeuro,
      isspecial: item.isspecial,
    }))
  } catch (error) {
    console.error("Erreur lors de la récupération des récompenses :", error)
    return []
  }
}

export const getAmbassadorStatuses = async (): Promise<AmbassadorStatus[]> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/AmbassadorStatus.php`,
      { Method: "get_ambassador_status" },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    const data = response.data?.ambassador_status ?? []
    return data.map((item: any, index: number) => ({
      raise: item.raise,
      title: item.title,
      valuemys: item.valuemys,
      star: item.star,
      hexprimarycolor: item.hexprimarycolor,
      hexsecondarcolor: item.hexsecondarcolor,
      hexlightcolor: item.hexlightcolor,
      mincoins: item.mincoins,
      maxcoins: item.maxcoins,
      status: item.status,
      id: item.id,
      showrank: index + 1,
    }))
  } catch (error) {
    console.error("Erreur lors de la récupération des statuts ambassadeurs :", error)
    return []
  }
}

export const getUserCoin = async (userId: string): Promise<number | null> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/HistoryCoins.php`,
      {
        Method: "get_sum_history_coins_by_userId",
        userid: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success" && response.data.total_coins !== undefined) {
      return response.data.total_coins
    }

    return null
  } catch (error) {
    console.error("Erreur lors de la récupération des coins de l'utilisateur :", error)
    return null
  }
}

export const conversionCoins = async (): Promise<{ success: boolean; message?: string }> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/ConversionCoins.php`,
      {
        Method: "start_conversion",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return {
      success: response.data.status === "success",
      message: "Conversion des coins en cours...",
    }
  } catch (error) {
    console.error("Erreur lors de la conversion des coins :", error)
    return {
      success: false,
      message: "Une erreur est survenue lors de la conversion",
    }
  }
}

export const getHistoryCoins = async (userId: string): Promise<HistoryCoin[]> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/HistoryCoins.php`,
      {
        Method: "get_history_coins",
        userid: userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    console.log("[API] History coins response:", response.data)

    if (response.data.status === "success") {
      return response.data.history_coins || []
    }

    return []
  } catch (error) {
    console.error("Erreur lors de la récupération de l'historique des coins :", error)
    return []
  }
}

export const getEventCoins = async (): Promise<EventCoin[]> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/EventCoins.php`,
      {
        Method: "get_event_coins",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success") {
      return response.data.event_coins || []
    }

    return []
  } catch (error) {
    console.error("Erreur lors de la récupération des événements coins :", error)
    return []
  }
}

// Créer une candidature pour une formation/offre
export const createApplication = async (adId: string, interestedUserId: string, interestedParticipant: number = 1) => {
  try {
    const response = await axios.post(
      `${config.API_URL}/DocumentFiles.php`,
      {
        Method: "create_application",
        ad_id: adId,
        interested_user_id: interestedUserId,
        interested_participant: interestedParticipant,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return response.data
  } catch (error) {
    console.error("Erreur lors de la création de la candidature:", error)
    return { status: "error", message: "Erreur lors de la création de la candidature" }
  }
}

export const createUserReview = async (
  userId: string,
  authorId: string,
  rating: number,
  comment: string
): Promise<ApiResponse> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/UserR.php`,
      {
        Method: "create_user_reviews",
        userId,
        authorId,
        rating,
        comment,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )

    return response.data
  } catch (error) {
    console.error("Erreur lors de la création de l'avis:", error)
    return { status: "error", message: "Erreur lors de la création de l'avis" }
  }
}

export const getUserReviews = async (userId: string): Promise<any> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/UserR.php`,
      {
        Method: "get_user_reviews",
        userId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )

    return response.data
  } catch (error) {
    console.error("Erreur lors de la récupération des avis:", error)
    return { status: "error", message: "Erreur lors de la récupération des avis", reviews: [] }
  }
}

export const sendNotification = async (
  receiverId: string,
  senderId: string,
  type: string,
  message: string,
  announcementId: string | null = null,
  conversationId: string | null = null
): Promise<ApiResponse> => {
  try {
    const response = await axios.post(
      `${config.API_URL}/Notifications.php`,
      {
        Method: "create_notification",
        receiverId,
        senderId,
        type,
        message,
        announcementId,
        conversationId,
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    )

    return response.data
  } catch (error) {
    console.error("Erreur lors de l'envoi de la notification:", error)
    return { status: "error", message: "Erreur lors de l'envoi de la notification" }
  }
}

export { startConversation }
