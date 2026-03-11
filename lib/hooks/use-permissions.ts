import axios from "axios"
import { config } from "@/lib/config"

export function usePermissions() {
  const checkAdPermission = async (userId: string) => {
    try {
      const response = await axios.post(
        `${config.API_URL}/Ads.php`,
        {
          userId,
          Method: "checkAdLimit",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )

      if (response.data.status === "success") {
        return {
          canCreateAd: response.data.canCreateAd,
          currentCount: response.data.currentCount,
          limit: response.data.limit,
        }
      }

      return { canCreateAd: true, currentCount: 0, limit: 0 }
    } catch (error) {
      console.error("[v0] Error checking ad permission:", error)
      return { canCreateAd: true, currentCount: 0, limit: 0 }
    }
  }

  return { checkAdPermission }
}
