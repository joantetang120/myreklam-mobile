"use client"

import { useEffect, useState, useMemo } from "react"
import { useUserData } from "@/hooks/use-user-data"
import axios from "axios"
import { config } from "@/lib/config"

export interface UserLimits {
  commentsPerMonth: number
  adsPerMonth: number
  maxComments: number
  maxAds: number
  canAccessContacts: boolean
  canAccessDocuments: boolean
  canAccessMessaging: boolean
  canConvertCoins: boolean
  canShareContacts: boolean
  canDownloadPrograms: boolean
  canReplyToReviews: boolean
  hasVerifiedBadge: boolean
}

const FREE_LIMITS: UserLimits = {
  commentsPerMonth: 0,
  adsPerMonth: 0,
  maxComments: 1,
  maxAds: 1,
  canAccessContacts: false,
  canAccessDocuments: false,
  canAccessMessaging: false,
  canConvertCoins: false,
  canShareContacts: false,
  canDownloadPrograms: false,
  canReplyToReviews: false,
  hasVerifiedBadge: false,
}

const PREMIUM_LIMITS: UserLimits = {
  commentsPerMonth: 0,
  adsPerMonth: 0,
  maxComments: -1, // illimité
  maxAds: -1, // illimité
  canAccessContacts: true,
  canAccessDocuments: true,
  canAccessMessaging: true,
  canConvertCoins: true,
  canShareContacts: true,
  canDownloadPrograms: true,
  canReplyToReviews: true,
  hasVerifiedBadge: true,
}

export const useSubscriptionLimits = () => {
  const { userData } = useUserData()
  const [limits, setLimits] = useState<UserLimits>(FREE_LIMITS)
  const [loading, setLoading] = useState(true)

  const [subscriptions, setSubscriptions] = useState<any[]>([])

  interface Subscription {
    id: string
    userid?: string
    typeabo?: string
    dateabo?: string
    customerid?: string
  }

  const fetchSubscriptions = async () => {
    try {
      const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : ""
      if (!userId) {
        console.log("[useSubscriptionLimits] No userId found, skipping subscription fetch")
        return
      }

      console.log("[useSubscriptionLimits] Fetching subscriptions for userId:", userId)

      const response = await axios.post(
        `${config.API_URL}/Abonnement.php`,
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

      console.log("[useSubscriptionLimits] Subscription API response:", response.data)

      if (response.data.status === "success") {
        const subs: Subscription[] = response.data.subscriptions || []
        console.log("[useSubscriptionLimits] Raw subscriptions:", subs)
        
        const validSubs = subs.filter((sub) => sub.dateabo && sub.customerid)
        console.log("[useSubscriptionLimits] Valid subscriptions (with dateabo and customerid):", validSubs)
        
        const sortedSubs = [...validSubs].sort((a, b) => {
          const dateA = new Date(a.dateabo!).getTime()
          const dateB = new Date(b.dateabo!).getTime()
          return dateB - dateA
        })
        console.log("[useSubscriptionLimits] Sorted subscriptions:", sortedSubs)
        
        setSubscriptions(sortedSubs)
      }
    } catch (error) {
      console.error("[useSubscriptionLimits] Error fetching subscriptions:", error)
    }
  }

  const getCurrentSubscriptionType = () => {
    if (!subscriptions || subscriptions.length === 0) {
      return "gratuit"
    }

    const activeSubscription = subscriptions.find((sub) => {
      if (!sub.dateabo || !sub.typeabo) return false

      const subscriptionDate = new Date(sub.dateabo)
      const now = new Date()
      const expirationDate = new Date(subscriptionDate)

      if (sub.typeabo === "annuel") {
        expirationDate.setFullYear(expirationDate.getFullYear() + 1)
      } else if (sub.typeabo === "mensuel") {
        expirationDate.setMonth(expirationDate.getMonth() + 1)
      }

      return now <= expirationDate
    })

    return activeSubscription ? activeSubscription.typeabo : "gratuit"
  }

  useEffect(() => {
    fetchSubscriptions()
  }, [])

  const isPremium = useMemo(() => {
    const subscriptionType = getCurrentSubscriptionType()
    const result = subscriptionType === "mensuel" || subscriptionType === "annuel"
    console.log("[useSubscriptionLimits] isPremium recalculated:", {
      subscriptionType,
      isPremium: result,
      subscriptionsCount: subscriptions.length
    })
    return result
  }, [subscriptions])

  const profileType = typeof window !== "undefined" ? localStorage.getItem("profiletype") : null
  const userId = typeof window !== "undefined" ? localStorage.getItem("profileId") : null

  console.log("[useSubscriptionLimits] Initial state:", {
    isPremium,
    profileType,
    userId,
    userData: userData?.abonnements
  })

  const fetchCurrentUsage = async () => {
    console.log("[useSubscriptionLimits] fetchCurrentUsage called", { userId, profileType })
    
    if (!userId || profileType !== "professionnel") {
      console.log("[useSubscriptionLimits] Skipping fetch - conditions not met")
      return
    }

    try {
      console.log("[useSubscriptionLimits] Making API calls...")
      
      let commentsCount = 0
      let adsCount = 0

      try {
        const [commentsResponse, adsResponse] = await Promise.all([
          axios.post(`${config.API_URL}/getUserStats.php`, {
            userId,
            type: "comments",
            period: "current_month",
          }),
          axios.post(`${config.API_URL}/getUserStats.php`, {
            userId,
            type: "ads",
            period: "current_month",
          }),
        ])

        commentsCount = commentsResponse.data?.count || 0
        adsCount = adsResponse.data?.count || 0

        console.log("[useSubscriptionLimits] API responses:", {
          commentsCount,
          adsCount,
          commentsData: commentsResponse.data,
          adsData: adsResponse.data
        })
      } catch (apiError: any) {
        // Si l'API n'existe pas (404), utiliser des valeurs par défaut
        if (apiError.response?.status === 404) {
          console.warn("[useSubscriptionLimits] getUserStats.php not found (404), using default values")
        } else {
          console.error("[useSubscriptionLimits] API error:", apiError)
        }
      }

      const currentLimits = isPremium ? { ...PREMIUM_LIMITS } : { ...FREE_LIMITS }
      currentLimits.commentsPerMonth = commentsCount
      currentLimits.adsPerMonth = adsCount

      console.log("[useSubscriptionLimits] Setting limits:", currentLimits)
      setLimits(currentLimits)
    } catch (error) {
      console.error("[useSubscriptionLimits] Erreur lors de la récupération des statistiques:", error)
      const fallbackLimits = isPremium ? PREMIUM_LIMITS : FREE_LIMITS
      console.log("[useSubscriptionLimits] Using fallback limits:", fallbackLimits)
      setLimits(fallbackLimits)
    } finally {
      console.log("[useSubscriptionLimits] fetchCurrentUsage completed")
      setLoading(false)
    }
  }

  useEffect(() => {
    console.log("[useSubscriptionLimits] useEffect triggered:", { profileType, isPremium, userId })
    
    if (profileType === "professionnel") {
      console.log("[useSubscriptionLimits] Professional profile - fetching usage")
      fetchCurrentUsage()
    } else {
      const defaultLimits = isPremium ? { ...PREMIUM_LIMITS } : { ...FREE_LIMITS }
      
      if (profileType === "particulier") {
        defaultLimits.canAccessDocuments = true
        console.log("[useSubscriptionLimits] Particulier profile - enabling document access")
      }
      
      console.log("[useSubscriptionLimits] Non-professional profile - using default limits:", defaultLimits)
      setLimits(defaultLimits)
      setLoading(false)
    }
  }, [isPremium, profileType, userId])

  useEffect(() => {
    const handleAdCreated = () => {
      console.log("[useSubscriptionLimits] Ad created event detected - refreshing usage")
      if (profileType === "professionnel") {
        fetchCurrentUsage()
      }
    }

    const handleCommentCreated = () => {
      console.log("[useSubscriptionLimits] Comment created event detected - refreshing usage")
      if (profileType === "professionnel") {
        fetchCurrentUsage()
      }
    }

    window.addEventListener('adCreated', handleAdCreated)
    window.addEventListener('commentCreated', handleCommentCreated)
    return () => {
      window.removeEventListener('adCreated', handleAdCreated)
      window.removeEventListener('commentCreated', handleCommentCreated)
    }
  }, [profileType, fetchCurrentUsage])

  const canComment = () => {
    // CORRECTION : Seuls les professionnels sans abonnement sont limités
    const isLimitedUser = profileType === "professionnel" && !isPremium
    const result = !isLimitedUser || limits.maxComments === -1 || limits.commentsPerMonth < limits.maxComments
    
    console.log("[useSubscriptionLimits] canComment:", {
      result,
      profileType,
      isPremium,
      isLimitedUser,
      maxComments: limits.maxComments,
      currentComments: limits.commentsPerMonth
    })
    return result
  }

  // const canCreateAd = () => {
  //   const result = profileType !== "professionnel" || limits.maxAds === -1 || limits.adsPerMonth < limits.maxAds
  //   console.log("[useSubscriptionLimits] canCreateAd:", { result, profileType, maxAds: limits.maxAds, currentAds: limits.adsPerMonth })
  //   return result
  // }

   const canCreateAd = () => {
    // CORRECTION : Seuls les professionnels sans abonnement sont limités
    const isLimitedUser = profileType === "professionnel" && !isPremium
    const result = !isLimitedUser || limits.maxAds === -1 || limits.adsPerMonth < limits.maxAds
    
    console.log("[useSubscriptionLimits] canCreateAd:", {
      result,
      profileType,
      isPremium,
      isLimitedUser,
      maxAds: limits.maxAds,
      currentAds: limits.adsPerMonth
    })
    return result
  }


  // const getRemainingComments = () => {
  //   const remaining = limits.maxComments === -1 ? -1 : Math.max(0, limits.maxComments - limits.commentsPerMonth)
  //   console.log("[useSubscriptionLimits] getRemainingComments:", remaining)
  //   return remaining
  // }
   const getRemainingComments = () => {
    if (profileType !== "professionnel" || isPremium) return -1 // Illimité
    const remaining = limits.maxComments === -1 ? -1 : Math.max(0, limits.maxComments - limits.commentsPerMonth)
    console.log("[useSubscriptionLimits] getRemainingComments:", remaining)
    return remaining
  }

  const getRemainingAds = () => {
    if (profileType !== "professionnel" || isPremium) return -1 // Illimité
    const remaining = limits.maxAds === -1 ? -1 : Math.max(0, limits.maxAds - limits.adsPerMonth)
    console.log("[useSubscriptionLimits] getRemainingAds:", remaining)
    return remaining
  }

  return {
    limits,
    loading,
    isPremium,
    canComment: canComment(),
    canCreateAds: canCreateAd(),
    getRemainingComments: getRemainingComments(),
    remainingAds: getRemainingAds(),
    refresh: fetchCurrentUsage,
  }
}