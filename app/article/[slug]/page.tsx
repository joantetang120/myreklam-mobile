"use client"

import { useState, useEffect } from "react"
import { useParams, useRouter } from "next/navigation"
import axios from "axios"
import { config } from "@/lib/config"
import { ArrowLeft, Calendar, Eye, Heart, Share2, Tag } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import Image from "next/image"
import Link from "next/link"

interface Article {
  id: string
  title: string
  slug: string
  excerpt: string
  content: string
  status: string
  is_featured: boolean
  media: {
    featured_image: {
      url: string
      alt: string
    }
    gallery: Array<{
      id: number
      filename: string
      file_path: string
    }>
  }
  meta: {
    title: string
    description: string
    tags: string[]
  }
  stats: {
    views: number
    likes: number
  }
  category: {
    id: string
    name: string
    description: string
    color: string
  }
  dates: {
    published: string
    created: string
    updated: string
  }
  related_articles: any[]
  urls: {
    view: string
    api: string
  }
}

export default function ArticleDetailPage() {
  const params = useParams()
  const router = useRouter()
  const [article, setArticle] = useState<Article | null>(null)
  const [otherArticles, setOtherArticles] = useState<Article[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchArticle = async () => {
      try {
        setLoading(true)
        setError(null)
        
        // Appel GET avec l'ID dans l'URL
        const response = await axios.get(
          `${config.API_URL}/api/article.php?id=${params.slug}`
        )

        if (response.data.success && response.data.data) {
          setArticle(response.data.data)
        } else {
          setError("Article non trouvé")
        }
      } catch (error) {
        console.error("Erreur lors du chargement de l'article:", error)
        setError("Erreur lors du chargement de l'article")
      } finally {
        setLoading(false)
      }
    }

    const fetchOtherArticles = async () => {
      try {
        const response = await axios.get(`${config.API_URL}/api/latest-articles.php`)
        
        if (response.data.success && response.data.data.articles) {
          // Filtrer l'article actuel et prendre les 3 premiers
          const filtered = response.data.data.articles
            .filter((art: Article) => art.id !== params.slug)
            .slice(0, 3)
          setOtherArticles(filtered)
        }
      } catch (error) {
        console.error("Erreur lors du chargement des autres articles:", error)
      }
    }

    if (params.slug) {
      fetchArticle()
      fetchOtherArticles()
    }
  }, [params.slug])

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString("fr-FR", {
      year: "numeric",
      month: "long",
      day: "numeric",
    })
  }

  const getImageUrl = (url: string) => {
    if (!url) return ""
    if (url.startsWith("http")) return url
    
    // Utiliser admin.myreklam.fr pour les images des articles
    const baseUrl = "https://admin.myreklam.fr"
    const path = url.startsWith("/") ? url : `/${url}`
    
    return `${baseUrl}${path}`
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    )
  }

  if (error || !article) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center">
        <h1 className="text-2xl font-bold mb-4">Article non trouvé</h1>
        <Button onClick={() => router.push("/")}>
          <ArrowLeft className="mr-2 h-4 w-4" />
          Retour à l'accueil
        </Button>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header avec image */}
      <div className="relative h-96 w-full bg-gradient-to-b from-gray-900 to-gray-800">
        {article.media.featured_image && (
          <Image
            src={getImageUrl(article.media.featured_image.url)}
            alt={article.media.featured_image.alt}
            fill
            className="object-cover opacity-40"
          />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
        
        {/* Contenu du header */}
        <div className="absolute bottom-0 left-0 right-0 p-8">
          <div className="container mx-auto max-w-4xl">
            <Button
              variant="ghost"
              className="text-white hover:text-white/80 mb-4"
              onClick={() => router.back()}
            >
              <ArrowLeft className="mr-2 h-4 w-4" />
              Retour
            </Button>
            
            <Badge
              style={{ backgroundColor: article.category.color }}
              className="mb-4"
            >
              {article.category.name}
            </Badge>
            
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
              {article.title}
            </h1>
            
            <p className="text-xl text-gray-200 mb-6">
              {article.excerpt}
            </p>
            
            <div className="flex flex-wrap gap-4 text-gray-300">
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4" />
                <span>{formatDate(article.dates.published)}</span>
              </div>
              <div className="flex items-center gap-2">
                <Eye className="h-4 w-4" />
                <span>{article.stats.views} vues</span>
              </div>
              <div className="flex items-center gap-2">
                <Heart className="h-4 w-4" />
                <span>{article.stats.likes} j'aime</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Contenu principal */}
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Article principal */}
          <div className="lg:col-span-8">
            <div className="bg-white rounded-lg shadow-lg p-8 md:p-12">
          {/* Actions */}
          <div className="flex justify-end gap-2 mb-8">
            <Button variant="outline" size="sm">
              <Heart className="h-4 w-4 mr-2" />
              J'aime
            </Button>
            <Button variant="outline" size="sm">
              <Share2 className="h-4 w-4 mr-2" />
              Partager
            </Button>
          </div>

          <Separator className="mb-8" />

          {/* Contenu de l'article */}
          <div
            className="prose prose-lg max-w-none"
            dangerouslySetInnerHTML={{ __html: article.content }}
          />

          {/* Tags */}
          {article.meta.tags && article.meta.tags.length > 0 && (
            <>
              <Separator className="my-8" />
              <div className="flex flex-wrap gap-2 items-center">
                <Tag className="h-4 w-4 text-gray-500" />
                {article.meta.tags.map((tag, index) => (
                  <Badge key={index} variant="secondary">
                    {tag}
                  </Badge>
                ))}
              </div>
            </>
          )}

          {/* Galerie d'images */}
          {article.media.gallery && article.media.gallery.length > 0 && (
            <>
              <Separator className="my-8" />
              <h2 className="text-2xl font-bold mb-4">Galerie</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {article.media.gallery.map((image) => (
                  <div key={image.id} className="relative h-48 rounded-lg overflow-hidden">
                    <Image
                      src={getImageUrl(image.file_path)}
                      alt={`Galerie ${image.id}`}
                      fill
                      className="object-cover hover:scale-110 transition-transform duration-300"
                    />
                  </div>
                ))}
              </div>
            </>
          )}
            </div>
          </div>

          {/* Sidebar - Autres actualités */}
          <div className="lg:col-span-4">
            <div className="sticky top-4">
              <div className="bg-white rounded-lg shadow-lg p-6">
                <h2 className="text-2xl font-bold mb-6">Autres actualités</h2>
                
                {otherArticles.length > 0 ? (
                  <div className="space-y-6">
                    {otherArticles.map((otherArticle) => (
                      <Link
                        key={otherArticle.id}
                        href={`/article/${otherArticle.id}`}
                        className="block group"
                      >
                        <div className="flex gap-4">
                          <div className="relative w-24 h-24 flex-shrink-0 rounded-lg overflow-hidden bg-gradient-to-br from-gray-50 to-gray-100">
                            {otherArticle.media?.featured_image?.url ? (
                              <Image
                                src={getImageUrl(otherArticle.media.featured_image.url)}
                                alt={otherArticle.media.featured_image.alt || otherArticle.title}
                                fill
                                className="object-cover group-hover:scale-110 transition-transform duration-300"
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center bg-gray-200">
                                <span className="text-gray-400 text-xs">Pas d'image</span>
                              </div>
                            )}
                          </div>
                          <div className="flex-1 min-w-0">
                            <Badge
                              style={{ backgroundColor: otherArticle.category.color }}
                              className="mb-2 text-xs"
                            >
                              {otherArticle.category.name}
                            </Badge>
                            <h3 className="font-bold text-sm line-clamp-2 text-gray-900 group-hover:text-primary transition-colors mb-2">
                              {otherArticle.title}
                            </h3>
                            <div className="flex items-center gap-3 text-xs text-gray-500">
                              <div className="flex items-center gap-1">
                                <Calendar className="h-3 w-3" />
                                <span>{formatDate(otherArticle.dates.published)}</span>
                              </div>
                              <div className="flex items-center gap-1">
                                <Eye className="h-3 w-3" />
                                <span>{otherArticle.stats.views}</span>
                              </div>
                            </div>
                          </div>
                        </div>
                        <Separator className="mt-6" />
                      </Link>
                    ))}
                  </div>
                ) : (
                  <p className="text-gray-500 text-sm">Aucune autre actualité disponible</p>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
