"use client"

import { useState, useEffect } from "react"
import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { ArrowRight, Loader2 } from "lucide-react"
import Image from "next/image"
import Link from "next/link"
import axios from "axios"
import { config } from "@/lib/config"

interface Article {
  id: string
  title: string
  slug: string
  excerpt: string
  media: {
    featured_image: {
      url: string
      alt: string
    } | null
  }
  urls: {
    view: string
  }
}

export function FeaturedSection() {
  const [articles, setArticles] = useState<Article[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchArticles = async () => {
      try {
        const response = await axios.get(`${config.API_URL}/api/latest-articles.php`)
        
        if (response.data.success && response.data.data.articles) {
          setArticles(response.data.data.articles.slice(0, 3))
        }
      } catch (error) {
        console.error("Erreur lors du chargement des articles:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchArticles()
  }, [])
  const getImageUrl = (url: string) => {
    if (!url) return ""
    if (url.startsWith("http")) return url
    
    // Utiliser admin.myreklam.fr pour les images des articles
    const baseUrl = "https://admin.myreklam.fr"
    const path = url.startsWith("/") ? url : `/${url}`
    
    return `${baseUrl}${path}`
  }

  return (
    <section className="py-16 bg-background">
      <div className="container mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="text-2xl sm:text-3xl lg:text-4xl font-bold mb-3">
            Nos dernières <span className="text-primary">actualités</span>
          </h2>
          <p className="text-base text-muted-foreground max-w-2xl mx-auto">
            Restez informé des dernières nouvelles, conseils et guides pour optimiser votre expérience sur Myreklam
          </p>
        </motion.div>

        {loading ? (
          <div className="flex justify-center items-center py-12">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : articles.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-muted-foreground">Aucun article disponible pour le moment.</p>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4 max-w-5xl mx-auto">
            {articles.map((article, index) => (
              <motion.div
                key={article.id}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
                className="flex justify-center"
              >
                <Card className="flex flex-col w-full max-w-sm overflow-hidden hover:shadow-2xl transition-all duration-300 hover:-translate-y-1 bg-white border-0 rounded-lg p-0 m-0">
                  <div className="relative h-56 w-full overflow-hidden bg-gradient-to-br from-gray-50 to-gray-100">
                    {article.media?.featured_image?.url ? (
                      <Image
                        src={getImageUrl(article.media.featured_image.url)}
                        alt={article.media.featured_image.alt || article.title}
                        fill
                        className="object-cover"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-gray-100 to-gray-200">
                        <span className="text-gray-400 text-sm">Image non disponible</span>
                      </div>
                    )}
                  </div>
                  <div className="p-4 flex flex-col h-44">
                    <h3 className="text-base font-bold mb-2 line-clamp-2 h-12 text-gray-900">
                      {article.title}
                    </h3>
                    <p className="text-gray-600 text-xs leading-relaxed line-clamp-3 mb-3 h-14">
                      {article.excerpt}
                    </p>
                  </div>
                  <CardFooter className="pt-0 pb-6">
                    <Link href={`/article/${article.id}`} className="w-full">
                      <Button variant="outline" className="w-full group hover:bg-primary hover:text-primary-foreground transition-colors">
                        Lire la suite
                        <ArrowRight className="ml-1 h-3 w-3" />
                      </Button>
                    </Link>
                  </CardFooter>
                </Card>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    </section>
  )
}
