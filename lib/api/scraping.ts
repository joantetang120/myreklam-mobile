export interface Scraping {
  title: string
  description: string
  price: number
  images: string[]
  duration?: string
  training_date?: string
  event_date?: string
}

export const getScraping = async (url: string): Promise<{ success: boolean; scraping: Scraping }> => {
  try {
    const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/Scraping.php`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({ url }),
    })

    if (!response.ok) {
      throw new Error("Scraping failed")
    }

    const data = await response.json()
    const scraping = data?.data || {}

    // Format dates if they exist
    let training_date = scraping.training_date
    let event_date = scraping.event_date

    if (training_date) {
      training_date = new Date(training_date).toISOString()
    }

    if (event_date) {
      event_date = new Date(event_date).toISOString()
    }

    const images = []

    if (Array.isArray(scraping.images)) {
      images.push(...scraping.images)
      images.slice(0, 9)
    }

    const formattedScraping: Scraping = {
      title: scraping.title || "",
      price: scraping.price || 0,
      description: scraping.description || "",
      images: images,
      duration: scraping.duration,
      training_date: training_date,
      event_date: event_date,
    }

    return { success: true, scraping: formattedScraping }
  } catch (error) {
    console.error("[v0] Scraping error:", error)
    return {
      success: false,
      scraping: {
        title: "",
        price: 0,
        description: "",
        images: [],
        duration: "",
        training_date: "",
        event_date: "",
      },
    }
  }
}
