"use client"

import { useState, useEffect } from "react"
import axios from "axios"
import { config } from "@/lib/config"
const API_URL = config.API_URL;
// const API_URL = "https://test.myreklam.fr"

export function useUserData() {
  const [companyData, setCompanyData] = useState<any>(null)
  const [email, setEmail] = useState<string>("")
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchData = async () => {
    const profileId = localStorage.getItem("profileId")
    const userEmail = localStorage.getItem("userEmail")
    
    console.log("[useUserData] ProfileId:", profileId)
    console.log("[useUserData] UserEmail from localStorage:", userEmail)
    
    if (!profileId) {
      setLoading(false)
      return
    }

    try {
      // Récupérer les informations utilisateur
      const response = await axios.post(
        `${API_URL}/UserInfo.php`,
        {
          userid: profileId,
          Method: "readAdsByCriteria",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      console.log("[useUserData] UserInfo response:", response.data)

      if (response.data.status === "success" && response.data.userInfo?.[0]) {
        setCompanyData(response.data.userInfo[0])
      }

      // Récupérer l'email depuis localStorage ou API
      if (userEmail) {
        console.log("[useUserData] Using email from localStorage:", userEmail)
        setEmail(userEmail)
      } else {
        // Si pas dans localStorage, récupérer depuis l'API
        console.log("[useUserData] Fetching email from API...")
        try {
          const emailResponse = await axios.post(
            `${API_URL}/LoginUser.php`,
            {
              Id: profileId,
              Method: "readAllByUserId",
            },
            {
              headers: {
                "Content-Type": "application/x-www-form-urlencoded",
              },
            },
          )

          console.log("[useUserData] Email API response:", emailResponse.data)

          if (emailResponse.data.status === "success" && emailResponse.data.profile?.[0]?.Email) {
            const fetchedEmail = emailResponse.data.profile[0].Email
            console.log("[useUserData] Email fetched from API:", fetchedEmail)
            setEmail(fetchedEmail)
            // Sauvegarder dans localStorage pour les prochaines fois
            localStorage.setItem("userEmail", fetchedEmail)
          } else {
            console.log("[useUserData] No email found in API response")
          }
        } catch (emailErr) {
          console.error("[useUserData] Error fetching email:", emailErr)
        }
      }
    } catch (err) {
      console.error("[useUserData] Error fetching user data:", err)
      setError("Erreur lors du chargement des données")
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  const refreshData = async () => {
    await fetchData()
  }

  return { companyData, email, loading, error, refreshData }
}
