import { create } from "zustand"
import axios from "axios"
import { config } from "@/lib/config"
const API_URL = config.API_URL;

interface UserState {
  userId: string | null
  profileType: string | null
  urlPhotoProfil: string | null
  isAuthenticated: boolean
  isLoading: boolean
  fetchUserInfo: () => Promise<void>
  login: (email: string, password: string) => Promise<{ success: boolean; message?: string }>
  logout: () => void
  setUser: (userId: string | null) => void
  loginWithGoogle: (googleData: { idToken?: string; email: string; name?: string; picture?: string; googleId?: string }) => Promise<{ success: boolean; message?: string; isNewUser?: boolean; requiresVerification?: boolean; token?: string; email?: string }>
}

export const useAuthStore = create<UserState>((set, get) => ({
  userId: null,
  profileType: null,
  urlPhotoProfil: null,
  isAuthenticated: false,
  isLoading: false,

  fetchUserInfo: async () => {
    const id = localStorage.getItem("profileId")
    if (!id) {
      set({ userId: null, isAuthenticated: false })
      return
    }

    set({ userId: id })

    document.cookie = `myreklam_user=${id}; path=/; max-age=${60 * 60 * 24 * 30}` // 30 days

    try {
      console.log("[v0] AuthStore - Fetching user info for ID:", id)
      const response = await axios.post(
        `${API_URL}/UserInfo.php`,
        {
          userid: id,
          Method: "readAdsByCriteria",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      console.log("[v0] AuthStore - User info response:", response.data)

      if (response.data.status === "success") {
        const { profiletype, photoprofilurl } = response.data.userInfo[0]
        set({
          profileType: profiletype,
          urlPhotoProfil: photoprofilurl,
          isAuthenticated: true,
        })
        localStorage.setItem("profiletype", profiletype)
      }
    } catch (error) {
      console.error("[v0] AuthStore - Error fetching user info:", error)
    }
  },

  login: async (email, password) => {
    set({ isLoading: true })

    try {
      const domain = "myreklam.fr"
      console.log("[v0] AuthStore - Login attempt for:", email)

      const response = await axios.post(
        `${API_URL}/LoginUser.php`,
        {
          userEmail: email,
          userPassword: password,
          Method: "read",
          Email: email,
          Name: "",
          Link: domain + "/dashboard?via=",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      console.log("[v0] AuthStore - Login response:", response.data)

      if (response.data.status === "success") {
        const profileId = response.data.id

        if (response.data.isVerified == 1 || response.data.isVerified == "1") {
          localStorage.setItem("profileId", profileId)
          localStorage.setItem("userEmail", email) // Sauvegarder l'email
          document.cookie = `myreklam_user=${profileId}; path=/; max-age=${60 * 60 * 24 * 30}` // 30 days
          set({ userId: profileId })
          await get().fetchUserInfo()
          set({ isLoading: false })
          return { success: true }
        } else {
          set({ isLoading: false })
          return {
            success: false,
            message: "Veuillez vérifier votre email pour activer votre compte",
          }
        }
      } else {
        set({ isLoading: false })
        return {
          success: false,
          message: response.data.message || "Identifiants incorrects",
        }
      }
    } catch (error) {
      console.error("[v0] AuthStore - Login error:", error)
      set({ isLoading: false })
      return {
        success: false,
        message: "Une erreur s'est produite lors de la connexion",
      }
    }
  },

  logout: () => {
    console.log("[v0] AuthStore - Logging out")
    localStorage.removeItem("profileId")
    localStorage.removeItem("profiletype")
    localStorage.removeItem("userEmail")
    document.cookie = "myreklam_user=; path=/; max-age=0"
    set({ userId: null, profileType: null, urlPhotoProfil: null, isAuthenticated: false })
    window.location.href = "/"
  },

  setUser: (userId) => {
    set({ userId })
    if (userId) {
      get().fetchUserInfo()
    }
  },

  loginWithGoogle: async (googleData) => {
    set({ isLoading: true })
    try {
      const { idToken, email, name, picture, googleId } = googleData
      console.log("[v0] AuthStore - Google login for:", email)

      const response = await axios.post(
        `${API_URL}/LoginGoogle.php`,
        {
          idToken: idToken || "",
          email: email,
          name: name || "",
          picture: picture || "",
          googleId: googleId || "",
          Link: typeof window !== "undefined" ? window.location.origin : "",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      console.log("[v0] AuthStore - Google login response:", response.data)

      if (response.data.status === "success") {
        const profileId = response.data.id
        const isNewUser = response.data.isNewUser === true || response.data.isNewUser === "true" || response.data.isNewUser === 1
        const isVerified = response.data.isVerified == 1 || response.data.isVerified === "1" || response.data.isVerified === true
        const requiresVerification = response.data.requiresVerification === true || response.data.requiresVerification === "true" || response.data.requiresVerification === 1

        console.log("[v0] AuthStore - Parsed values:", {
          isNewUser,
          isVerified,
          requiresVerification,
          hasToken: !!response.data.token,
          hasEmail: !!response.data.email,
          rawIsNewUser: response.data.isNewUser,
          rawRequiresVerification: response.data.requiresVerification
        })

        // Si c'est un nouvel utilisateur qui nécessite une vérification, retourner success: true avec id et email
        // Le frontend redirigera vers /welcome pour choisir le type de compte
        if (isNewUser && requiresVerification) {
          console.log("[v0] AuthStore - Nouvel utilisateur détecté, retour de success: true avec id et email pour redirection vers /welcome")
          set({ isLoading: false })
          return {
            success: true,
            message: response.data.message || "Compte créé avec succès. Veuillez compléter votre profil.",
            isNewUser: true,
            requiresVerification: true,
            id: profileId,
            email: response.data.email,
          }
        }

        // Si l'utilisateur n'est pas vérifié (mais pas un nouvel utilisateur), retourner success: true avec token et email
        // Le frontend redirigera vers /verify pour vérifier l'email
        if (!isVerified && !isNewUser) {
          console.log("[v0] AuthStore - Utilisateur existant non vérifié, retour de success: true avec token et email")
          set({ isLoading: false })
          return {
            success: true,
            message: response.data.message || "Veuillez vérifier votre email pour activer votre compte.",
            isNewUser: false,
            requiresVerification: true,
            token: response.data.token,
            email: response.data.email,
          }
        }

        // Utilisateur vérifié et existant - connexion (redirection vers dashboard)
        console.log("[v0] AuthStore - Utilisateur existant vérifié, connexion et redirection vers dashboard")
        localStorage.setItem("profileId", profileId)
        localStorage.setItem("userEmail", email) // Sauvegarder l'email
        document.cookie = `myreklam_user=${profileId}; path=/; max-age=${60 * 60 * 24 * 30}` // 30 days
        set({ userId: profileId })
        await get().fetchUserInfo()
        set({ isLoading: false })
        return { success: true, isNewUser: false }
      } else {
        set({ isLoading: false })
        return { success: false, message: response.data.message || "Erreur lors de la connexion avec Google" }
      }
    } catch (error: any) {
      console.error("[v0] AuthStore - Google login error:", error)
      set({ isLoading: false })
      return {
        success: false,
        message: error.response?.data?.message || "Erreur lors de la connexion avec Google",
      }
    }
  },
}))
