"use client"

import { useEffect, useState } from "react"
import { useAuthStore } from "@/lib/auth-store"
import axios from "axios"
import { config } from "@/lib/config"

const API_URL = config.API_URL

interface UserData {
  id?: string
  userid?: string
  localUserId?: string
  email?: string
  pseudo?: string
  telephone?: string
  nomsociete?: string
  activite?: string
  adresse?: string
  ville?: string
  codepostal?: string
  pays?: string
  presentation?: string
  photoprofilurl?: string
  bannerUrl?: string
  profiletype?: string
  facebook?: string
  instagram?: string
  x?: string
  linkedin?: string
  youtube?: string
  tiktok?: string
  snapchat?: string
  publishtelephone?: boolean | string
  publishemail?: boolean | string
  publishname?: boolean | string
  publishactivity?: boolean | string
  publishadresse?: boolean | string
  active_nofification_mobile_message?: boolean
  active_nofification_mobile_alert?: boolean
  active_nofification_mobile_comment?: boolean
  active_nofification_mobile_notice?: boolean
  active_nofification_mobile_newsletter?: boolean
  active_nofification_email_message?: boolean
  active_nofification_email_alert?: boolean
  active_nofification_email_comment?: boolean
  active_nofification_email_notice?: boolean
  active_nofification_email_newsletter?: boolean
  [key: string]: any
}

export function useUserData() {
  const { userId, isAuthenticated } = useAuthStore()
  const [companyData, setCompanyData] = useState<UserData | null>(null)
  const [email, setEmail] = useState<string>("")
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadUserData = async () => {
      if (!isAuthenticated) {
        setLoading(false)
        return
      }

      const profileId = userId || localStorage.getItem("profileId")
      const userEmail = localStorage.getItem("userEmail")
      
      console.log("[useUserData] profileId:", profileId)
      console.log("[useUserData] userEmail from localStorage:", userEmail)
      
      if (!profileId) {
        setLoading(false)
        return
      }

      try {
        setLoading(true)
        const response = await axios.post(
          `${API_URL}/UserInfo.php`,
          { userid: profileId, Method: "readAdsByCriteria" },
          { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
        )
        console.log("[useUserData] User data response:", response.data)
        if (response.data.status === "success" && response.data.userInfo?.[0]) {
          const data = response.data.userInfo[0]
          setCompanyData(data)
          setError(null)
        } else {
          setError("Failed to load user data")
        }

        // Récupérer l'email
        if (userEmail) {
          console.log("[useUserData] Using email from localStorage:", userEmail)
          setEmail(userEmail)
        } else {
          // Récupérer depuis l'API
          console.log("[useUserData] Fetching email from API...")
          try {
            const emailResponse = await axios.post(
              `${API_URL}/LoginUser.php`,
              { Id: profileId, Method: "readAllByUserId" },
              { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
            )
            console.log("[useUserData] Email API response:", emailResponse.data)
            if (emailResponse.data.status === "success" && emailResponse.data.profile?.[0]?.Email) {
              const fetchedEmail = emailResponse.data.profile[0].Email
              console.log("[useUserData] Email fetched:", fetchedEmail)
              setEmail(fetchedEmail)
              localStorage.setItem("userEmail", fetchedEmail)
            }
          } catch (emailErr) {
            console.error("[useUserData] Error fetching email:", emailErr)
          }
        }
      } catch (err) {
        console.error("Error loading user data:", err)
        setError("Error loading user data")
      } finally {
        setLoading(false)
      }
    }

    loadUserData()
  }, [userId, isAuthenticated])

  const refetch = async () => {
    const profileId = userId || localStorage.getItem("profileId")
    if (!profileId) return

    try {
      setLoading(true)
      const response = await axios.post(
        `${API_URL}/UserInfo.php`,
        { userid: profileId, Method: "readAdsByCriteria" },
        { headers: { "Content-Type": "application/x-www-form-urlencoded" } },
      )

      if (response.data.status === "success" && response.data.userInfo?.[0]) {
        const data = response.data.userInfo[0]
        setCompanyData(data)
        setError(null)
      }
    } catch (err) {
      console.error("Error loading user data:", err)
      setError("Error loading user data")
    } finally {
      setLoading(false)
    }
  }

  return { companyData, email, loading, error, refetch }
}
