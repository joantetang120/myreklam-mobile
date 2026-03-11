import axios from "axios"
import { config } from "@/lib/config"

export async function fetchAnnouncementDetail(id: string) {
  try {
    const response = await axios.post(
      `${config.API_URL}/Ads.php`,
      {
        id,
        Method: "readAdsByCriteria",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success" && response.data.ads && response.data.ads.length > 0) {
      return response.data.ads[0]
    }
    return null
  } catch (error) {
    console.error("[v0] Error fetching announcement:", error)
    return null
  }
}

export type DealImageRecord = {
  id: string
  url: string
}

export async function fetchDealImages(annonceId: string) {
  try {
    const response = await axios.post(
      `${config.API_URL}/ImageAnnonce.php`,
      {
        Id: annonceId,
        Method: "readAllByAnnonceId",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    if (response.data.status === "success" && response.data.images) {
      const imageRecords: DealImageRecord[] = response.data.images
        .filter((img: any) => img.urlimg && (img.isdeleted === 0 || img.isdeleted === false || img.isdeleted === null))
        .map((img: any) => {
          const rawUrl: string = img.urlimg
          const hasProtocol = rawUrl.startsWith("http://") || rawUrl.startsWith("https://")
          const normalizedPath = hasProtocol
            ? rawUrl
            : rawUrl.startsWith("/")
              ? rawUrl
              : `/${rawUrl}`

          return {
            id: img.id || img.Id || img.imageId || img.imageid || "",
            url: normalizedPath,
          }
        })

      const imageUrls = imageRecords.map((record) => record.url)

      return {
        success: true,
        images: imageUrls,
        records: imageRecords,
      }
    }
    
    return { success: false, images: [], records: [] }
  } catch (error: any) {
    if (error.response?.status === 404) {
      return { success: false, images: [], records: [] }
    }
    // Only log non-404 errors
    console.error("[v0] Error fetching deal images:", error)
    return { success: false, images: [], records: [] }
  }
}

export async function uploadImages(imageUrls: string[]) {
  try {
    const uploadPromises = imageUrls.map(async (url) => {
      const response = await axios.post(
        `${config.API_URL}/UploadFile.php`,
        {
          imageUrl: url,
          Method: "uploadFromUrl",
        },
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        },
      )
      return response.data
    })

    return await Promise.all(uploadPromises)
  } catch (error) {
    console.error("[v0] Error uploading images:", error)
    return []
  }
}

export async function createImageAnnouncementByUrlsAndAnnouncementId(urls: string[], annonceId: string) {
  try {
    const response = await axios.post(
      `${config.API_URL}/ImageAnnonce.php`,
      {
        annonceId,
        urls,
        Method: "createByUrls",
      },
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      },
    )

    return response.data
  } catch (error) {
    console.error("[v0] Error creating image announcements:", error)
    return { success: false }
  }
}
